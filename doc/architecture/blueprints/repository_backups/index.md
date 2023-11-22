---
status: proposed
creation-date: "2023-04-26"
authors: [ "@proglottis" ]
coach: "@DylanGriffith"
approvers: []
owning-stage: "~devops::systems"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# Repository Backups

<!-- For long pages, consider creating a table of contents.  The `[_TOC_]`
function is not supported on docs.gitlab.com.  -->

## Summary

This proposal seeks to provide an out-of-a-box repository backup solution to
GitLab that gives more opportunities to apply Gitaly specific optimisations. It
will do this by moving repository backups out of `backup.rake` into a
coordination worker that enumerates repositories and makes per-repository
decisions to trigger repository backups that are streamed directly from Gitaly
to object-storage.

The advantages of this approach are:

- The backups are only transferred once, from the Gitaly hosting the physical
  repository to object-storage.
- Smarter decisions can be made by leveraging specific repository access
  patterns.
- Distributes backup and restore load.
- Since the entire process is run within Gitaly existing monitoring can be
  used.
- Provides architecture for future WAL archiving and other optimisations.

This should relieve the major pain points of the existing two strategies:

- `backup.rake` - Repository backups are streamed from outside of Gitaly using
  RPCs and stored in a single large tar file. Due to the amount of data
  transferred these backups are limited to small installations.
- Snapshots - Cloud providers allow taking physical storage snapshots. These
  are not an out-of-a-box solution as they are specific to the cloud provider.

## Motivation

### Goals

- Improve time to create and restore repository backups.
- Improve monitoring of repository backups.

### Non-Goals

- Improving filesystem based snapshots.

### Filesystem based Snapshots

Snapshots rely on cloud platforms to be able to take physical snapshots of the
disks that Gitaly and Praefect use to store data. While never officially
recommended, this strategy tends to be used once creating or restoring backups
using `backup.rake` takes too long.

Gitaly and Git use lock files and fsync in order to prevent repository
corruption from concurrent processes and partial writes from a crash. This
generally means that if a file is written, then it will be valid. However,
because Git repositories are composed of many files and many write operations
may be taking place, it would be impossible to schedule a snapshot while no
file operations are ongoing. This means the consistency of a snapshot cannot be
guaranteed and restoring from a snapshot backup may require manual
intervention.

[WAL](https://gitlab.com/groups/gitlab-org/-/epics/8911) may improve crash
resistance and so improve automatic recovery from snapshots, but each
repository will likely still require a majority of voting replicas in sync.

Since each node in a Gitaly Cluster is not homogeneous, depending on
replication factor, in order to create a complete snapshot backup all nodes
would need to have snapshots taken. This means that snapshot backups have a lot
of repository data duplication.

Snapshots are heavily dependent on the cloud provider and so they would not
provide an out-of-a-box experience.

### Downtime

An ideal repository backup solution would allow both backup and restore
operations to be done online. Specifically we would not want to shutdown or
pause writes to ensure that each node/repository is consistent.

### Consistency

Consistency in repository backups means:

- That the Git repositories are valid after restore. There are no partially
  applied operations.
- That all repositories in a cluster are healthy after restore, or are made
  healthy automatically.

Backups without consistency may result in data-loss or require manual
intervention on restore.

Both types of consistency are difficult to achieve using snapshots as this
requires that snapshots of the filesystems on multiple hosts are taken
synchronously and without repositories on any of those hosts currently being
mutated.

### Distribute Work

We want to distribute the backup/restore work such that it isn't bottlenecked
on the machine running `backup.rake`, a single Gitaly node, or a single network
connection.

On backup, `backup.rake` aggregates all repository backups onto its local
filesystem. This means that all repository data needs to be streamed from
Gitaly (possibly via Praefect) to where the Rake task is being run. If this is
CNG then it also requires a large volume on Kubernetes. The resulting backup
tar file then gets transferred to object storage. A similar process happens on
restore, the entire tar file needs to be downloaded and extracted on the local
filesystem, even for a partial restore when restoring a subset of repositories.
Effectively all repository data gets transferred, in full, multiple times
between multiple hosts.

If each Gitaly could directly upload backups it would mean only transferring
repository data a single time, reducing the number of hosts and so the amount
of data transferred over all.

### Gitaly Controlled

Gitaly is looking to become self-contained and so should own its backups.

`backup.rake` currently determines which repositories to backup and where those
backups are stored. This restricts the kind of optimisations that Gitaly could
apply and adds development/testing complexity.

### Monitoring

`backup.rake` is run in a variety of different environments. Historically
backups from Gitaly's perspective are a series of disconnected RPC calls. This
has resulted in backups having almost zero monitoring. Ideally the process
would run within Gitaly such that the process could be monitored using existing
metrics and log scraping.

### Automatic Backups

When `backup.rake` is set up on cron it can be difficult to tell if it has been
running successfully, if it is still running, how long it took, and how much
space it has taken. It is difficult to ensure that cron always has access to
the previous backup to allow for incremental backups or to determine if
updating the backup is required at all.

Having a coordination process running continuously will allow moving from a
single-shot backup strategy to one where each repository determines its own
backup schedule based on usage patterns and priority. This way each repository
should be able to have a reasonably up-to-date backup without adding excess
load to any Gitaly node.

### Updated Repositories Only

`backup.rake` packages all repository backups into a tar file and generally has
no access to the previous backup. This makes it difficult to determine if the
repository has changed since last backup.

Having access to previous backups on object-storage would mean that Gitaly
could more easily determine if a backup needs to be taken at all. This allows
us to waste less time backing up repositories that are no longer being
modified.

### Point-in-time Restores

There should be a mechanism by which a set of repositories can be restored to a
specific point in time. The identifier (backup ID) used should be able to be
determined by an admin and apply to all repositories.

### WAL (write ahead log)

We want to be able to provide infrastructure to allow continuous archiving of
the WAL. This means providing a central place to stream the archives to and
being able to match any full backup to a place in the log such that
repositories can be restored from the full backup, and the WAL applied up to a
specific point in time.

### WORM

Any Gitaly accessible storage should be WORM (write once, read many) in order
to prevent existing backups being modified in the case an attacker gains access
to a nodes object-storage credentials.

[The pointer layout](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/gitaly-backup.md#pointer-layout)
currently used by repository backups relies on being able to overwrite the
pointer files, and as such would not be suitable for use on a WORM file store.

WORM is likely object-storage provider specific:

- [AWS object lock](https://aws.amazon.com/blogs/storage/protecting-data-with-amazon-s3-object-lock/)
- [Google Cloud WORM retention policy](https://cloud.google.com/blog/products/storage-data-transfer/protecting-cloud-storage-with-worm-key-management-and-more-updates).
- [MinIO object lock](https://min.io/docs/minio/linux/administration/object-management/object-retention.html)

### `bundle-uri`

Having direct access backup data may open the door for clone/fetch transfer
optimisations using bundle-uri. This allows us to point Git clients directly to
a bundle file instead of transferring packs from the repository itself. The
bulk repository transfer can then be faster and is offloaded to a plain http
server, rather than the Gitaly servers.

## Proposal

The proposal is broken down into an initial MVP and per-repository coordinator.

### MVP

The goal of the MVP is to validate that moving backup processing server-side
will improve the worst case, total-loss, scenario. That is, reduce the total
time to create and restore a full backup.

The MVP will introduce backup and restore repository RPCs. There will be no
coordination worker. The RPCs will stream a backup directly from the
called Gitaly node to object storage. These RPCs will be called from
`backup.rake` via the `gitaly-backup` tool. `backup.rake` will no longer
package repository backups into the backup archive.

This work is already underway, tracked by the [Server-side Backups MVP epic](https://gitlab.com/groups/gitlab-org/-/epics/10077).

### Per-Repository Coordinator

Instead of taking a backup of all repositories at once via `backup.rake`, a
backup coordination worker will be created. This worker will periodically
enumerate all repositories to decide if a backup needs to be taken. These
decisions could be determined by usage patterns or priority of the repository.

When restoring, since each repository will have a different backup state, a
timestamp will be provided by the user. This timestamp will be used to
determine which backup to restore for each repository. Once WAL archiving is
implemented, the WAL could then be replayed up to the given timestamp.

This wider effort is tracked in the [Server-side Backups epic](https://gitlab.com/groups/gitlab-org/-/epics/10826).

## Design and implementation details

### MVP

There will be a pair of RPCs `BackupRepository` and `RestoreRepository`. These
RPCs will synchronously create/restore backups directly onto object storage.
`backup.rake` will continue to use `gitaly-backup` with a new `--server-side`
flag. Each Gitaly will need a backup configuration to specify the
object-storage service to use.

Initially the structure of the backups in object-storage will be the same as
the existing [pointer layout](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/gitaly-backup.md#pointer-layout).

For MVP the backup ID must match an exact backup ID on object-storage.

The configuration of object-storage will be controlled by a new config
`config.backup.go_cloud_url`. The [Go Cloud Development Kit](https://gocloud.dev)
tries to use a provider specific way to configure authentication. This can be
inferred from the VM or from environment variables.
See [Supported Storage Services](https://gocloud.dev/howto/blob/#services).

## Alternative Solutions

<!--
It might be a good idea to include a list of alternative solutions or paths considered, although it is not required. Include pros and cons for
each alternative solution/path.

"Do nothing" and its pros and cons could be included in the list too.
-->
