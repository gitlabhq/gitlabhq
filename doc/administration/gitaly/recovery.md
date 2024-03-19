---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Gitaly Cluster recovery options and tools

Gitaly Cluster can recover from primary-node failure and unavailable repositories. Gitaly Cluster can perform data
recovery and has Praefect tracking database tools.

## Manage Gitaly nodes on a Gitaly Cluster

You can add and replace Gitaly nodes on a Gitaly Cluster.

### Add new Gitaly nodes

The steps to add a new Gitaly node to a Gitaly Cluster depend on whether a [custom replication factor](praefect.md#configure-replication-factor) is set.

#### Custom replication factor

If a custom replication factor is set, set the [replication factor](praefect.md#configure-replication-factor) for each repository using the
`set-replication-factor` Praefect command. New repositories are replicated based on the [replication factor](praefect.md#configure-replication-factor). Praefect doesn't automatically replicate existing repositories to the new Gitaly node.

#### Default replication factor

If the default replication factor is used, add the new node in your [Praefect configuration](praefect.md#praefect) under `praefect['virtual_storages']`.
Praefect automatically replicates all data to any new Gitaly node added to the configuration.

### Replace an existing Gitaly node

You can replace an existing Gitaly node with a new node with either the same name or a different name.

#### With a node with the same name

To use the same name for the replacement node, use [repository verifier](praefect.md#enable-deletions) to scan the storage and remove dangling metadata records.
[Manually prioritize verification](praefect.md#prioritize-verification-manually) of the replaced storage to speed up the process.

#### With a node with a different name

The steps use a different name for the replacement node for a Gitaly Cluster depend on if a [custom replication factor](praefect.md#configure-replication-factor)
is set.

##### Custom replication factor set

If a custom replication factor is set, use [`praefect set-replication-factor`](praefect.md#configure-replication-factor) to set the replication factor per repository again to get new storage assigned. For example:

```shell
$ sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml set-replication-factor -virtual-storage default -relative-path @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git -replication-factor 2

current assignments: gitaly-1, gitaly-2
```

To reassign all repositories from the old storage to the new one, after configuring the new Gitaly node:

1. Connect to Praefect database:

   ```shell
   /opt/gitlab/embedded/bin/psql -h <psql host> -U <user> -d <database name>
   ```

1. Update the `repository_assignments` table to replace the old Gitaly node name (for example, `old-gitaly`) with the new Gitaly node name
   (for example, `new-gitaly`):

   ```sql
   UPDATE repository_assignments SET storage='new-gitaly' WHERE storage='old-gitaly';
   ```

##### Default replication factor

If the default replication factor is used, replace the node in the configuration. The old node's state remains in the Praefect database but it is ignored.

## Primary node failure

> - Introduced in GitLab 13.0, Gitaly Cluster, elects the secondary with the least unreplicated writes from the primary to be the new primary. There can still be some unreplicated writes, so [data loss can occur](#check-for-data-loss).
> - Primary node failure recovery support added in GitLab 14.1.

Gitaly Cluster recovers from a failing primary Gitaly node by promoting a healthy secondary as the new primary. Gitaly
Cluster:

- Elects a healthy secondary with a fully up to date copy of the repository as the new primary.
- Repository becomes unavailable if there are no fully up to date copies of it on healthy secondaries.

### Unavailable repositories

> - From GitLab 13.0 through 14.0, repositories became read-only if they were outdated on the primary but fully up to date on a healthy secondary. `dataloss` sub-command displays read-only repositories by default through these versions.
> - From GitLab 14.1, Praefect contains more responsive failover logic which immediately fails over to one of the fully up to date secondaries rather than placing the repository in read-only mode. From GitLab 14.1, the `dataloss` sub-command displays repositories which are unavailable due to having no fully up to date copies on healthy Gitaly nodes.

A repository is unavailable if all of its up to date replicas are unavailable. Unavailable repositories are
not accessible through Praefect to prevent serving stale data that may break automated tooling.

### Check for data loss

The Praefect `dataloss` subcommand identifies:

- Copies of repositories in GitLab 13.0 to GitLab 14.0 that at are likely to be outdated.
  This can help identify potential data loss after a failover.
- Repositories in GitLab 14.1 and later that are unavailable. This helps identify potential
  data loss and repositories which are no longer accessible because all of their up-to-date
  replicas copies are unavailable.

The following parameters are available:

- `-virtual-storage` that specifies which virtual storage to check. Because they might require
  an administrator to intervene, the default behavior is to display:
  - In GitLab 13.0 to 14.0, copies of read-only repositories.
  - In GitLab 14.1 and later, unavailable repositories.
- In GitLab 14.1 and later, [`-partially-unavailable`](#unavailable-replicas-of-available-repositories)
  that specifies whether to include in the output repositories that are available but have
  some assigned copies that are not available.

NOTE:
`dataloss` is still in [Beta](../../policy/experiment-beta-support.md#beta) and the output format is subject to change.

To check for repositories with outdated primaries or for unavailable repositories, run:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>]
```

Every configured virtual storage is checked if none is specified:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss
```

Repositories are listed in the output that have either:

- An outdated copy of the repository on the primary, in GitLab 13.0 to GitLab 14.0.
- No healthy and fully up-to-date copies available, in GitLab 14.1 and later.

The following information is printed for each repository:

- A repository's relative path to the storage directory identifies each repository and groups the related
  information.
- The repository's current status is printed in parentheses next to the disk path:
  - In GitLab 13.0 to 14.0, either `(read-only)` if the repository's primary node is outdated
    and can't accept writes. Otherwise, `(writable)`.
  - In GitLab 14.1 and later, `(unavailable)` is printed next to the disk path if the
    repository is unavailable.
- The primary field lists the repository's current primary. If the repository has no primary, the field shows
  `No Primary`.
- The In-Sync Storages lists replicas which have replicated the latest successful write and all writes
  preceding it.
- The Outdated Storages lists replicas which contain an outdated copy of the repository. Replicas which have no copy
  of the repository but should contain it are also listed here. The maximum number of changes the replica is missing
  is listed next to replica. It's important to notice that the outdated replicas may be fully up to date or contain
  later changes but Praefect can't guarantee it.

Additional information includes:

- Whether a node is assigned to host the repository is listed with each node's status.
  `assigned host` is printed next to nodes that are assigned to store the repository. The
  text is omitted if the node contains a copy of the repository but is not assigned to store
  the repository. Such copies aren't kept in sync by Praefect, but may act as replication
  sources to bring assigned copies up to date.
- In GitLab 14.1 and later, `unhealthy` is printed next to the copies that are located
  on unhealthy Gitaly nodes.

Example output:

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git (unavailable):
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-2, assigned host, unhealthy
      Outdated Storages:
        gitaly-1 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

A confirmation is printed out when every repository is available. For example:

```shell
Virtual storage: default
  All repositories are available!
```

#### Unavailable replicas of available repositories

> - Introduced in GitLab 14.0, flag renamed from `-partially-replicated` and behavior changed.

To also list information of repositories which are available but are unavailable from some of the assigned nodes,
use the `-partially-unavailable` flag.

A repository is available if there is a healthy, up to date replica available. Some of the assigned secondary
replicas may be temporarily unavailable for access while they are waiting to replicate the latest changes.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>] [-partially-unavailable]
```

Example output:

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git:
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-1, assigned host
      Outdated Storages:
        gitaly-2 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

With the `-partially-unavailable` flag set, a confirmation is printed out if every assigned replica is fully up to
date and healthy.

For example:

```shell
Virtual storage: default
  All repositories are fully available on all assigned storages!
```

### Check repository checksums

To check a project's repository checksums across on all Gitaly nodes, run the
[replicas Rake task](../raketasks/praefect.md#replica-checksums) on the main GitLab node.

### Accept data loss

WARNING:
`accept-dataloss` causes permanent data loss by overwriting other versions of the repository. Data
[recovery efforts](#data-recovery) must be performed before using it.

If it is not possible to bring one of the up to date replicas back online, you may have to accept data
loss. When accepting data loss, Praefect marks the chosen replica of the repository as the latest version
and replicates it to the other assigned Gitaly nodes. This process overwrites any other version of the
repository so care must be taken.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss
-virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

### Enable writes or accept data loss

WARNING:
`accept-dataloss` causes permanent data loss by overwriting other versions of the repository.
Data [recovery efforts](#data-recovery) must be performed before using it.

Praefect provides the following subcommands to re-enable writes or accept data loss. If it is not possible to bring one
of the up-to-date nodes back online, you might have to accept data loss:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss -virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

When accepting data loss, Praefect:

1. Marks the chosen copy of the repository as the latest version.
1. Replicates the copy to the other assigned Gitaly nodes.

  This process overwrites any other copy of the repository so care must be taken.

## Data recovery

If a Gitaly node fails replication jobs for any reason, it ends up hosting outdated versions of the
affected repositories. Praefect provides tools for:

- [Automatic](#automatic-reconciliation) reconciliation, for GitLab 13.4 and later.
- [Manual](#manual-reconciliation) reconciliation, for:
  - GitLab 13.3 and earlier.
  - Repositories upgraded to GitLab 13.4 and later without entries in the `repositories` table. In
    GitLab 13.6 and later, [a migration is run](https://gitlab.com/gitlab-org/gitaly/-/issues/3033)
    when Praefect starts for these repositories.

These tools reconcile the outdated repositories to bring them fully up to date again.

### Automatic reconciliation

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/2717) in GitLab 13.4.

Praefect automatically reconciles repositories that are not up to date. By default, this is done every
five minutes. For each outdated repository on a healthy Gitaly node, Praefect picks a
random, fully up-to-date replica of the repository on another healthy Gitaly node to replicate from. A
replication job is scheduled only if there are no other replication jobs pending for the target
repository.

The reconciliation frequency can be changed via the configuration. The value can be any valid
[Go duration value](https://pkg.go.dev/time#ParseDuration). Values below 0 disable the feature.

Examples:

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '5m', # the default value
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '30s', # reconcile every 30 seconds
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '0', # disable the feature
   },
}
```

### Manual reconciliation

WARNING:
The `reconcile` sub-command was removed in GitLab 14.1. Use [automatic reconciliation](#automatic-reconciliation) instead.
Manual reconciliation may produce excess replication jobs and is limited in functionality. Manual reconciliation does not
work when [repository-specific primary nodes](praefect.md#repository-specific-primary-nodes) are enabled.

The Praefect `reconcile` sub-command allows for the manual reconciliation between two Gitaly nodes. The
command replicates every repository on a later version on the reference storage to the target storage.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml reconcile -virtual <virtual-storage> -reference <up-to-date-storage> -target <outdated-storage> -f
```

- Replace the placeholder `<virtual-storage>` with the virtual storage containing the Gitaly node storage to be checked.
- Replace the placeholder `<up-to-date-storage>` with the Gitaly storage name containing up to date repositories.
- Replace the placeholder `<outdated-storage>` with the Gitaly storage name containing outdated repositories.

### Manually remove repositories

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/3767) in GitLab 14.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/4054) in GitLab 14.6, support for dry-run mode.
> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/4715) in GitLab 15.3, support for removing repositories from the Praefect tracking database.

The `remove-repository` Praefect sub-command removes a repository from a Gitaly Cluster, and all state associated with a given repository including:

- On-disk repositories on all relevant Gitaly nodes.
- Any database state tracked by Praefect.

In GitLab 14.6 and later, by default, the command operates in dry-run mode. In earlier versions, the command didn't support dry-run mode. For example:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository>
```

- Replace `<virtual-storage>` with the name of the virtual storage containing the repository.
- Replace `<repository>` with the relative path of the repository to remove.
- In GitLab 15.3 and later, add `-db-only` to remove the Praefect tracking database entry without removing the on-disk repository. Use this option to remove orphaned database entries and to
  protect on-disk repository data from deletion when a valid repository is accidentally specified. If the database entry is accidentally deleted, re-track the repository with the
  [`track-repository` command](#manually-add-a-single-repository-to-the-tracking-database).
- In GitLab 14.6 and later, add `-apply` to run the command outside of dry-run mode and remove the repository. For example:

  ```shell
  sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository> -apply
  ```

- `-virtual-storage` is the virtual storage the repository is located in. Virtual storages are configured in `/etc/gitlab/gitlab.rb` under `praefect['configuration']['virtual_storage]` and looks like the following:

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  In this example, the virtual storage to specify is `default` or `storage-1`.

- `-repository` is the repository's relative path in the storage [beginning with `@hashed`](../repository_storage_paths.md#hashed-storage).
  For example:

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

Parts of the repository can continue to exist after running `remove-repository`. This can be because of:

- A deletion error.
- An in-flight RPC call targeting the repository.

If this occurs, run `remove-repository` again.

## Praefect tracking database maintenance

Common maintenance tasks on the Praefect tracking database are documented in this section.

### List untracked repositories

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/3926) in GitLab 14.4.
> - `older-than` option added in GitLab 15.0.

The `list-untracked-repositories` Praefect sub-command lists repositories of the Gitaly Cluster that both:

- Exist for at least one Gitaly storage.
- Aren't tracked in the Praefect tracking database.

Add the `-older-than` option to avoid showing repositories that:

- Are in the process of being created.
- For which a record doesn't yet exist in the Praefect tracking database.

Replace `<duration>` with a time duration (for example, `5s`, `10m`, or `1h`). Defaults to `6h`.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories -older-than <duration>
```

Only repositories with a creation time before the specified duration are considered.

The command outputs:

- Result to `STDOUT` and the command's logs.
- Errors to `STDERR`.

Each entry is a complete JSON string with a newline at the end (configurable using the
`-delimiter` flag). For example:

```plaintext
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567890.git"}
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567891.git"}
```

### Manually add a single repository to the tracking database

> - [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5658) in GitLab 14.4.
> - [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5789) in GitLab 14.6, support for immediate replication.

WARNING:
Because of a [known issue](https://gitlab.com/gitlab-org/gitaly/-/issues/5402), you can't add repositories to the
Praefect tracking database with Praefect-generated replica paths (`@cluster`). These repositories are not associated with the repository path used by GitLab and are
inaccessible.

The `track-repository` Praefect sub-command adds repositories on disk to the Praefect tracking database to be tracked.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage <virtual-storage> -authoritative-storage <storage-name> -relative-path <repository> -replica-path <disk_path> -replicate-immediately
```

- `-virtual-storage` is the virtual storage the repository is located in. Virtual storages are configured in `/etc/gitlab/gitlab.rb` under `praefect['configuration'][:virtual_storage]` and looks like the following:

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  In this example, the virtual storage to specify is `default` or `storage-1`.

- `-relative-path` is the relative path in the virtual storage. Usually [beginning with `@hashed`](../repository_storage_paths.md#hashed-storage).
  For example:

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

- `-replica-path` is the relative path on physical storage. Can start with [`@cluster` or match `relative_path`](../repository_storage_paths.md#gitaly-cluster-storage).
- `-authoritative-storage` is the storage we want Praefect to treat as the primary. Required if
  [per-repository replication](praefect.md#configure-replication-factor) is set as the replication strategy.
- `-replicate-immediately`, available in GitLab 14.6 and later, causes the command to replicate the repository to its secondaries immediately.
  Otherwise, replication jobs are scheduled for execution in the database and are picked up by a Praefect background process.

The command outputs:

- Results to `STDOUT` and the command's logs.
- Errors to `STDERR`.

This command fails if:

- The repository is already being tracked by the Praefect tracking database.
- The repository does not exist on disk.

### Manually add many repositories to the tracking database

> - [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6319) in GitLab 15.4.

WARNING:
Because of a [known issue](https://gitlab.com/gitlab-org/gitaly/-/issues/5402), you can't add repositories to the
Praefect tracking database with Praefect-generated replica paths (`@cluster`). These repositories are not associated with the repository path used by GitLab and are
inaccessible.

Migrations using the API automatically add repositories to the Praefect tracking database.

If you are instead manually copying repositories over from existing infrastructure, you can use the `track-repositories`
Praefect subcommand. This subcommand adds large batches of on-disk repositories to the Praefect tracking database.

```shell
# Omnibus GitLab install
sudo gitlab-ctl praefect track-repositories --input-path /path/to/input.json

# Source install
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repositories -input-path /path/to/input.json
```

The command validates that all entries:

- Are formatted correctly and contain required fields.
- Correspond to a valid Git repository on disk.
- Are not tracked in the Praefect tracking database.

If any entry fails these checks, the command aborts prior to attempting to track a repository.

- `input-path` is the path to a file containing a list of repositories formatted as newline-delimited JSON objects. Objects must contain the following keys:
  - `relative_path`: corresponds with `repository` in [`track-repository`](#manually-add-a-single-repository-to-the-tracking-database).
  - `authoritative-storage`: the storage Praefect is to treat as the primary.
  - `virtual-storage`: the virtual storage the repository is located in.

    For example:

    ```json
    {"relative_path":"@hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git","replica_path":"@cluster/fe/d3/1","authoritative_storage":"gitaly-1","virtual_storage":"default"}
    {"relative_path":"@hashed/f8/9f/f89f8d0e735a91c5269ab08d72fa27670d000e7561698d6e664e7b603f5c4e40.git","replica_path":"@cluster/7b/28/2","authoritative_storage":"gitaly-2","virtual_storage":"default"}
    ```

- `-replicate-immediately`, causes the command to replicate the repository to its secondaries immediately.
  Otherwise, replication jobs are scheduled for execution in the database and are picked up by a Praefect background process.

### List virtual storage details

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/4609) in GitLab 15.1.

The `list-storages` Praefect sub-command lists virtual storages and their associated storage nodes. If a virtual storage is:

- Specified using `-virtual-storage`, it lists only storage nodes for the specified virtual storage.
- Not specified, all virtual storages and their associated storage nodes are listed in tabular format.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-storages -virtual-storage <virtual_storage_name>
```

The command outputs:

- Result to `STDOUT` and the command's logs.
- Errors to `STDERR`.
