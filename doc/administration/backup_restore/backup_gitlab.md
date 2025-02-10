---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Back up GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The exact procedure for backing up GitLab depends on many factors. Your particular deployment's usage and configuration determine what kind of data exists, where it is located, and how much there is. These factors influence your options for how to perform a back up, how to store it, and how to restore it.

## Simple back up procedure

As a rough guideline, if you are using a [1k reference architecture](../reference_architectures/1k_users.md) with less than 100 GB of data, then follow these steps:

1. Run the [backup command](#backup-command).
1. Back up [object storage](#object-storage), if applicable.
1. Manually back up [configuration files](#storing-configuration-files).

## Scaling backups

As the volume of GitLab data grows, the [backup command](#backup-command) takes longer to execute. [Backup options](#backup-options) such as [back up Git repositories concurrently](#back-up-git-repositories-concurrently) and [incremental repository backups](#incremental-repository-backups) can help to reduce execution time. At some point, the backup command becomes impractical by itself. For example, it can take 24 hours or more.

In some cases, architecture changes may be warranted to allow backups to scale. If you are using a GitLab reference architecture, see [Back up and restore large reference architectures](backup_large_reference_architectures.md).

For more information, see [alternative backup strategies](#alternative-backup-strategies).

## What data needs to be backed up?

- [PostgreSQL databases](#postgresql-databases)
- [Git repositories](#git-repositories)
- [Blobs](#blobs)
- [Container registry](#container-registry)
- [Configuration files](#storing-configuration-files)
- [Other data](#other-data)

### PostgreSQL databases

In the simplest case, GitLab has one PostgreSQL database in one PostgreSQL server on the same VM as all other GitLab services. But depending on configuration, GitLab may use multiple PostgreSQL databases in multiple PostgreSQL servers.

In general, this data is the single source of truth for most user-generated content in the Web interface, such as issue and merge request content, comments, permissions, and credentials.

PostgreSQL also holds some cached data like HTML-rendered Markdown, and by default, merge request diffs.
However, merge request diffs can also be configured to be offloaded to the file system or object storage, see [Blobs](#blobs).

Gitaly Cluster's Praefect service uses a PostgreSQL database as a single source of truth to manage its Gitaly nodes.

A common PostgreSQL utility, [`pg_dump`](https://www.postgresql.org/docs/current/app-pgdump.html), produces a backup file which can be used to restore a PostgreSQL database. The [backup command](#backup-command) uses this utility under the hood.

Unfortunately, the larger the database, the longer it takes `pg_dump` to execute. Depending on your situation, the duration becomes impractical at some point (days, for example). If your database is over 100 GB, `pg_dump`, and by extension the [backup command](#backup-command), is likely not usable. For more information, see [alternative backup strategies](#alternative-backup-strategies).

### Git repositories

A GitLab instance can have one or more repository shards. Each shard is a Gitaly instance or Gitaly Cluster that
is responsible for allowing access and operations on the locally stored Git repositories. Gitaly can run
on a machine:

- With a single disk.
- With multiple disks mounted as a single mount-point (like with a RAID array).
- Using LVM.

Each project can have up to 3 different repositories:

- A project repository, where the source code is stored.
- A wiki repository, where the wiki content is stored.
- A design repository, where design artifacts are indexed (assets are actually in LFS).

They all live in the same shard and share the same base name with a `-wiki` and `-design` suffix
for Wiki and Design Repository cases.

Personal and project snippets, and group wiki content, are stored in Git repositories.

Project forks are deduplicated in live a GitLab site using pool repositories.

The [backup command](#backup-command) produces a Git bundle for each repository and tars them all up. This duplicates pool repository data into every fork. In [our testing](https://gitlab.com/gitlab-org/gitlab/-/issues/396343), 100 GB of Git repositories took a little over 2 hours to back up and upload to S3. At around 400 GB of Git data, the backup command is likely not viable for regular backups. For more information, see [alternative backup strategies](#alternative-backup-strategies).

### Blobs

GitLab stores blobs (or files) such as issue attachments or LFS objects into either:

- The file system in a specific location.
- An [Object Storage](../object_storage.md) solution. Object Storage solutions can be:
  - Cloud based like Amazon S3 and Google Cloud Storage.
  - Hosted by you (like MinIO).
  - A Storage Appliance that exposes an Object Storage-compatible API.

#### Object storage

The [backup command](#backup-command) doesn't back up blobs that aren't stored on the file system. If you're using [object storage](../object_storage.md), be sure to enable backups with your object storage provider. For example, see:

- [Amazon S3 backups](https://docs.aws.amazon.com/aws-backup/latest/devguide/s3-backups.html)
- [Google Cloud Storage Transfer Service](https://cloud.google.com/storage-transfer-service) and [Google Cloud Storage Object Versioning](https://cloud.google.com/storage/docs/object-versioning)

### Container registry

[GitLab container registry](../packages/container_registry.md) storage can be configured in either:

- The file system in a specific location.
- An [Object Storage](../object_storage.md) solution. Object Storage solutions can be:
  - Cloud based like Amazon S3 and Google Cloud Storage.
  - Hosted by you (like MinIO).
  - A Storage Appliance that exposes an Object Storage-compatible API.

The backup command does not back up registry data when they are stored in Object Storage.

### Storing configuration files

WARNING:
The backup Rake task GitLab provides does _not_ store your configuration files. The primary reason for this is that your database contains items including encrypted information for two-factor authentication and the CI/CD _secure variables_. Storing encrypted information in the same location as its key defeats the purpose of using encryption in the first place. For example, the secrets file contains your database encryption key. If you lose it, then the GitLab application will not be able to decrypt any encrypted values in the database.

WARNING:
The secrets file may change after upgrades.

You should back up the configuration directory. At the very **minimum**, you must back up:

::Tabs

:::TabTitle Linux package

- `/etc/gitlab/gitlab-secrets.json`
- `/etc/gitlab/gitlab.rb`

For more information, see [Backup and restore Linux package (Omnibus) configuration](https://docs.gitlab.com/omnibus/settings/backups.html#backup-and-restore-omnibus-gitlab-configuration).

:::TabTitle Self-compiled

- `/home/git/gitlab/config/secrets.yml`
- `/home/git/gitlab/config/gitlab.yml`

:::TabTitle Docker

- Back up the volume where the configuration files are stored. If you created
  the GitLab container according to the documentation, it should be in the
  `/srv/gitlab/config` directory.

:::TabTitle GitLab Helm chart

- Follow the [Back up the secrets](https://docs.gitlab.com/charts/backup-restore/backup.html#back-up-the-secrets)
  instructions.

::EndTabs

You may also want to back up any TLS keys and certificates (`/etc/gitlab/ssl`, `/etc/gitlab/trusted-certs`), and your
[SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)
to avoid man-in-the-middle attack warnings if you have to perform a full machine restore.

In the unlikely event that the secrets file is lost, see
[When the secrets file is lost](../backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost).

### Other data

GitLab uses Redis both as a cache store and to hold persistent data for our background jobs system, Sidekiq. The provided [backup command](#backup-command) does _not_ back up Redis data. This means that in order to take a consistent backup with the [backup command](#backup-command), there must be no pending or running background jobs. It is possible to [manually back up Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data).

Elasticsearch is an optional database for advanced search. It can improve search
in both source-code level, and user generated content in issues, merge requests, and discussions. The [backup command](#backup-command) does _not_ back up Elasticsearch data. Elasticsearch data can be regenerated from PostgreSQL data after a restore. It is possible to [manually back up Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html).

## Command-line interface

GitLab provides a command-line interface to back up your entire instance,
including:

- Database
- Attachments
- Git repositories data
- CI/CD job output logs
- CI/CD job artifacts
- LFS objects
- Terraform states
- Container registry images
- GitLab Pages content
- Packages
- Snippets
- [Group wikis](../../user/project/wiki/group.md)
- Project-level Secure Files ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121142) in GitLab 16.1)
- External merge request diffs ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154914) in GitLab 17.1)

Backups do not include:

- [Mattermost data](../../integration/mattermost/_index.md#back-up-gitlab-mattermost)
- Redis (and thus Sidekiq jobs)
- [Object storage](#object-storage) on Linux package (Omnibus) / Docker / Self-compiled installations
- [Global server hooks](../server_hooks.md#create-global-server-hooks-for-all-repositories)
- [File hooks](../file_hooks.md)

WARNING:
GitLab does not back up any configuration files (`/etc/gitlab`), TLS keys and certificates, or system
files. You are highly advised to read about [storing configuration files](#storing-configuration-files).

### Requirements

To be able to back up and restore, ensure that Rsync is installed on your
system. If you installed GitLab:

- Using the Linux package, Rsync is already installed.
- Using self-compiled, check if `rsync` is installed. If Rsync is not installed, install it. For example:

  ```shell
  # Debian/Ubuntu
  sudo apt-get install rsync

  # RHEL/CentOS
  sudo yum install rsync
  ```

### Backup command

WARNING:
The backup command does not back up items in [object storage](#object-storage) on Linux package (Omnibus) / Docker / Self-compiled installations.

WARNING:
The backup command requires [additional parameters](#back-up-and-restore-for-installations-using-pgbouncer) when
your installation is using PgBouncer, for either performance reasons or when using it with a Patroni cluster.

WARNING:
Before GitLab 15.5.0, the backup command doesn't verify if another backup is already running, as described in
[issue 362593](https://gitlab.com/gitlab-org/gitlab/-/issues/362593). We strongly recommend
you make sure that all backups are complete before starting a new one.

NOTE:
You can only restore a backup to **exactly the same version and type (CE/EE)**
of GitLab on which it was created.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create
```

:::TabTitle Helm chart (Kubernetes)

Run the backup task by using `kubectl` to run the `backup-utility` script on the GitLab toolbox pod. For more details, see the [charts backup documentation](https://docs.gitlab.com/charts/backup-restore/backup.html).

:::TabTitle Docker

Run the backup from the host.

```shell
docker exec -t <container name> gitlab-backup create
```

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

::EndTabs

If your GitLab deployment has multiple nodes, you need to pick a node for running the backup command. You must ensure that the designated node:

- is persistent, and not subject to auto-scaling.
- has the GitLab Rails application already installed. If Puma or Sidekiq is running, then Rails is installed.
- has sufficient storage and memory to produce the backup file.

Example output:

```plaintext
Dumping database tables:
- Dumping table events... [DONE]
- Dumping table issues... [DONE]
- Dumping table keys... [DONE]
- Dumping table merge_requests... [DONE]
- Dumping table milestones... [DONE]
- Dumping table namespaces... [DONE]
- Dumping table notes... [DONE]
- Dumping table projects... [DONE]
- Dumping table protected_branches... [DONE]
- Dumping table schema_migrations... [DONE]
- Dumping table services... [DONE]
- Dumping table snippets... [DONE]
- Dumping table taggings... [DONE]
- Dumping table tags... [DONE]
- Dumping table users... [DONE]
- Dumping table users_projects... [DONE]
- Dumping table web_hooks... [DONE]
- Dumping table wikis... [DONE]
Dumping repositories:
- Dumping repository abcd... [DONE]
Creating backup archive: <backup-id>_gitlab_backup.tar [DONE]
Deleting tmp directories...[DONE]
Deleting old backups... [SKIPPING]
```

For detailed information about the backup process, see [Backup archive process](backup_archive_process.md).

### Backup options

The command-line tool GitLab provides to back up your instance can accept more
options.

#### Backup strategy option

The default backup strategy is to essentially stream data from the respective
data locations to the backup using the Linux command `tar` and `gzip`. This works
fine in most cases, but can cause problems when data is rapidly changing.

When data changes while `tar` is reading it, the error `file changed as we read it`
may occur, and causes the backup process to fail. In that case, you can use
the backup strategy called `copy`. The strategy copies data files
to a temporary location before calling `tar` and `gzip`, avoiding the error.

A side-effect is that the backup process takes up to an additional 1X disk
space. The process does its best to clean up the temporary files at each stage
so the problem doesn't compound, but it could be a considerable change for large
installations.

To use the `copy` strategy instead of the default streaming strategy, specify
`STRATEGY=copy` in the Rake task command. For example:

```shell
sudo gitlab-backup create STRATEGY=copy
```

#### Backup filename

WARNING:
If you use a custom backup filename, you can't
[limit the lifetime of the backups](#limit-backup-lifetime-for-local-files-prune-old-backups).

Backup files are created with filenames according to [specific defaults](backup_archive_process.md#backup-id). However, you can
override the `<backup-id>` portion of the filename by setting the `BACKUP`
environment variable. For example:

```shell
sudo gitlab-backup create BACKUP=dump
```

The resulting file is named `dump_gitlab_backup.tar`. This is useful for
systems that make use of rsync and incremental backups, and results in
considerably faster transfer speeds.

#### Backup compression

By default, Gzip fast compression is applied during backup of:

- [PostgreSQL database](#postgresql-databases) dumps.
- [blobs](#blobs), for example uploads, job artifacts, external merge request diffs.

The default command is `gzip -c -1`. You can override this command with `COMPRESS_CMD`. Similarly, you can override the decompression command with `DECOMPRESS_CMD`.

Caveats:

- The compression command is used in a pipeline, so your custom command must output to `stdout`.
- If you specify a command that is not packaged with GitLab, then you must install it yourself.
- The resultant filenames will still end in `.gz`.
- The default decompression command, used during restore, is `gzip -cd`. Therefore if you override the compression command to use a format that cannot be decompressed by `gzip -cd`, you must override the decompression command during restore.
- [Do not place environment variables after the backup command](https://gitlab.com/gitlab-org/gitlab/-/issues/433227). For example, `gitlab-backup create COMPRESS_CMD="pigz -c --best"` doesn't work as intended.

##### Default compression: Gzip with fastest method

```shell
gitlab-backup create
```

##### Gzip with slowest method

```shell
COMPRESS_CMD="gzip -c --best" gitlab-backup create
```

If `gzip` was used for backup, then restore does not require any options:

```shell
gitlab-backup restore
```

##### No compression

If your backup destination has built-in automatic compression, then you may wish to skip compression.

The `tee` command pipes `stdin` to `stdout`.

```shell
COMPRESS_CMD=tee gitlab-backup create
```

And on restore:

```shell
DECOMPRESS_CMD=tee gitlab-backup restore
```

##### Parallel compression with `pigz`

WARNING:
While we support using `COMPRESS_CMD` and `DECOMPRESS_CMD` to override the default Gzip compression library, we only test the default Gzip library with default options on a routine basis. You are responsible for testing and validating the viability of your backups. We strongly recommend this as best practice in general for backups, whether overriding the compression command or not. If you encounter issues with another compression library, you should revert back to the default. Troubleshooting and fixing errors with alternative libraries are a lower priority for GitLab.

NOTE:
`pigz` is not included in the GitLab Linux package. You must install it yourself.

An example of compressing backups with `pigz` using 4 processes:

```shell
COMPRESS_CMD="pigz --compress --stdout --fast --processes=4" sudo gitlab-backup create
```

Because `pigz` compresses to the `gzip` format, it is not required to use `pigz` to decompress backups which were compressed by `pigz`. However, it can still have a performance benefit over `gzip`. An example of decompressing backups with `pigz`:

```shell
DECOMPRESS_CMD="pigz --decompress --stdout" sudo gitlab-backup restore
```

##### Parallel compression with `zstd`

WARNING:
While we support using `COMPRESS_CMD` and `DECOMPRESS_CMD` to override the default Gzip compression library, we only test the default Gzip library with default options on a routine basis. You are responsible for testing and validating the viability of your backups. We strongly recommend this as best practice in general for backups, whether overriding the compression command or not. If you encounter issues with another compression library, you should revert back to the default. Troubleshooting and fixing errors with alternative libraries are a lower priority for GitLab.

NOTE:
`zstd` is not included in the GitLab Linux package. You must install it yourself.

An example of compressing backups with `zstd` using 4 threads:

```shell
COMPRESS_CMD="zstd --compress --stdout --fast --threads=4" sudo gitlab-backup create
```

An example of decompressing backups with `zstd`:

```shell
DECOMPRESS_CMD="zstd --decompress --stdout" sudo gitlab-backup restore
```

#### Confirm archive can be transferred

To ensure the generated archive is transferable by rsync, you can set the `GZIP_RSYNCABLE=yes`
option. This sets the `--rsyncable` option to `gzip`, which is useful only in
combination with setting [the Backup filename option](#backup-filename).

The `--rsyncable` option in `gzip` isn't guaranteed to be available
on all distributions. To verify that it's available in your distribution, run
`gzip --help` or consult the man pages.

```shell
sudo gitlab-backup create BACKUP=dump GZIP_RSYNCABLE=yes
```

#### Excluding specific data from the backup

Depending on your installation type, slightly different components can be skipped on backup creation.

::Tabs

:::TabTitle Linux package (Omnibus) / Docker / Self-compiled

<!-- source: https://gitlab.com/gitlab-org/gitlab/-/blob/d693aa7f894c7306a0d20ab6d138a7b95785f2ff/lib/backup/manager.rb#L117-133 -->

- `db` (database)
- `repositories` (Git repositories data, including wikis)
- `uploads` (attachments)
- `builds` (CI job output logs)
- `artifacts` (CI job artifacts)
- `pages` (Pages content)
- `lfs` (LFS objects)
- `terraform_state` (Terraform states)
- `registry` (Container registry images)
- `packages` (Packages)
- `ci_secure_files` (Project-level secure files)
- `external_diffs` (External merge request diffs)

:::TabTitle Helm chart (Kubernetes)

<!-- source: https://gitlab.com/gitlab-org/build/CNG/-/blob/068e146db915efcd875414e04403410b71a2e70c/gitlab-toolbox/scripts/bin/backup-utility#L19 -->

- `db` (database)
- `repositories` (Git repositories data, including wikis)
- `uploads` (attachments)
- `artifacts` (CI job artifacts and output logs)
- `pages` (Pages content)
- `lfs` (LFS objects)
- `terraform_state` (Terraform states)
- `registry` (Container registry images)
- `packages` (Package registry)
- `ci_secure_files` (Project-level Secure Files)
- `external_diffs` (Merge request diffs)

::EndTabs

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create SKIP=db,uploads
```

:::TabTitle Helm chart (Kubernetes)

See [Skipping components](https://docs.gitlab.com/charts/backup-restore/backup.html#skipping-components) in charts backup documentation.

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=db,uploads RAILS_ENV=production
```

::EndTabs

`SKIP=` is also used to:

- [Skip creation of the tar file](#skipping-tar-creation) (`SKIP=tar`).
- [Skip uploading the backup to remote storage](#skip-uploading-backups-to-remote-storage) (`SKIP=remote`).

#### Skipping tar creation

NOTE:
It is not possible to skip the tar creation when using [object storage](#upload-backups-to-a-remote-cloud-storage) for backups.

The last part of creating a backup is generation of a `.tar` file containing all the parts. In some cases, creating a `.tar` file might be wasted effort or even directly harmful, so you can skip this step by adding `tar` to the `SKIP` environment variable. Example use-cases:

- When the backup is picked up by other backup software.
- To speed up incremental backups by avoiding having to extract the backup every time. (In this case, `PREVIOUS_BACKUP` and `BACKUP` must not be specified, otherwise the specified backup is extracted, but no `.tar` file is generated at the end.)

Adding `tar` to the `SKIP` variable leaves the files and directories containing the
backup in the directory used for the intermediate files. These files are
overwritten when a new backup is created, so you should make sure they are copied
elsewhere, because you can only have one backup on the system.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create SKIP=tar
```

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=tar RAILS_ENV=production
```

::EndTabs

#### Create server-side repository backups

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/4941) in `gitlab-backup` in GitLab 16.3.
> - Server-side support in `gitlab-backup` for restoring a specified backup instead of the latest backup [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188) in GitLab 16.6.
> - Server-side support in `gitlab-backup` for creating incremental backups [introduced](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475) in GitLab 16.6.
> - Server-side support in `backup-utility` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438393) in GitLab 17.0.

Instead of storing large repository backups in the backup archive, repository
backups can be configured so that the Gitaly node that hosts each repository is
responsible for creating the backup and streaming it to object storage. This
helps reduce the network resources required to create and restore a backup.

1. [Configure a server-side backup destination in Gitaly](../gitaly/configure_gitaly.md#configure-server-side-backups).
1. Create a back up using the repositories server-side option. See the following examples.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true
```

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_SERVER_SIDE=true
```

:::TabTitle Helm chart (Kubernetes)

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --repositories-server-side
```

When you are using [cron-based backups](https://docs.gitlab.com/charts/backup-restore/backup.html#cron-based-backup),
add the `--repositories-server-side` flag to the extra arguments.

::EndTabs

#### Back up Git repositories concurrently

When using [multiple repository storages](../repository_storage_paths.md),
repositories can be backed up or restored concurrently to help fully use CPU time. The
following variables are available to modify the default behavior of the Rake
task:

- `GITLAB_BACKUP_MAX_CONCURRENCY`: The maximum number of projects to back up at
  the same time. Defaults to the number of logical CPUs.
- `GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY`: The maximum number of projects to
  back up at the same time on each storage. This allows the repository backups
  to be spread across storages. Defaults to `2`.

For example, with 4 repository storages:

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

:::TabTitle Helm chart (Kubernetes)

```yaml
toolbox:
#...
    extra: {}
    extraEnv:
      GITLAB_BACKUP_MAX_CONCURRENCY: 4
      GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY: 1

```

::EndTabs

#### Incremental repository backups

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/351383) in GitLab 14.10 [with a flag](../feature_flags.md) named `incremental_repository_backup`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/355945) in GitLab 15.3. Feature flag `incremental_repository_backup` removed.
> - Server-side support for creating incremental backups [introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/5461) in GitLab 16.6.

NOTE:
Only repositories support incremental backups. Therefore, if you use `INCREMENTAL=yes`, the task
creates a self-contained backup tar archive. This is because all subtasks except repositories are
still creating full backups (they overwrite the existing full backup).
See [issue 19256](https://gitlab.com/gitlab-org/gitlab/-/issues/19256) for a feature request to
support incremental backups for all subtasks.

Incremental repository backups can be faster than full repository backups because they only pack changes since the last backup into the backup bundle for each repository.
The incremental backup archives are not linked to each other: each archive is a self-contained backup of the instance. There must be an existing backup
to create an incremental backup from.

Use the `PREVIOUS_BACKUP=<backup-id>` option to choose the backup to use. By default, a backup file is created
as documented in the [Backup ID](backup_archive_process.md#backup-id) section. You can override the `<backup-id>` portion of the filename by setting the
[`BACKUP` environment variable](#backup-filename).

To create an incremental backup, run:

```shell
sudo gitlab-backup create INCREMENTAL=yes PREVIOUS_BACKUP=<backup-id>
```

To create an [untarred](#skipping-tar-creation) incremental backup from a tarred backup, use `SKIP=tar`:

```shell
sudo gitlab-backup create INCREMENTAL=yes SKIP=tar
```

#### Back up specific repository storages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896) in GitLab 15.0.

When using [multiple repository storages](../repository_storage_paths.md),
repositories from specific repository storages can be backed up separately
using the `REPOSITORIES_STORAGES` option. The option accepts a comma-separated list of
storage names.

For example:

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create REPOSITORIES_STORAGES=storage1,storage2
```

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_STORAGES=storage1,storage2
```

::EndTabs

#### Back up specific repositories

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094) in GitLab 15.1.
> - [Skipping specific repositories added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121865) in GitLab 16.1.

You can back up specific repositories using the `REPOSITORIES_PATHS` option.
Similarly, you can use `SKIP_REPOSITORIES_PATHS` to skip certain repositories.
Both options accept a comma-separated list of project or group paths. If you
specify a group path, all repositories in all projects in the group and
descendent groups are included or skipped, depending on which option you used.

For example, to back up all repositories for all projects in **Group A** (`group-a`), the repository for **Project C** in **Group B** (`group-b/project-c`),
and skip the **Project D** in **Group A** (`group-a/project-d`):

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
```

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
```

:::TabTitle Helm chart (Kubernetes)

```shell
REPOSITORIES_PATHS=group-a SKIP_REPOSITORIES_PATHS=group-a/project_a2 backup-utility --skip db,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,ci_secure_files,pages
```

::EndTabs

#### Upload backups to a remote (cloud) storage

NOTE:
It is not possible to [skip the tar creation](#skipping-tar-creation) when using object storage for backups.

You can let the backup script upload (using the [Fog library](https://fog.io/))
the `.tar` file it creates. In the following example, we use Amazon S3 for
storage, but Fog also lets you use [other storage providers](https://fog.io/storage/).
GitLab also [imports cloud drivers](https://gitlab.com/gitlab-org/gitlab/-/blob/da46c9655962df7d49caef0e2b9f6bbe88462a02/Gemfile#L113)
for AWS, Google, and Aliyun. A local driver is
[also available](#upload-to-locally-mounted-shares).

[Read more about using object storage with GitLab](../object_storage.md).

##### Using Amazon S3

For Linux package (Omnibus):

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-west-1',
     # Choose one authentication method
     # IAM Profile
     'use_iam_profile' => true
     # OR AWS Access and Secret key
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   # Consider using multipart uploads when file size reaches 100MB. Enter a number in bytes.
   # gitlab_rails['backup_multipart_chunk_size'] = 104857600
   ```

1. If you're using the IAM Profile authentication method, ensure the instance where `backup-utility` is to be run has the following policy set (replace `<backups-bucket>` with the correct bucket name):

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::<backups-bucket>/*"
           }
       ]
   }
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect

##### S3 Encrypted Buckets

AWS supports these [modes for server side encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html):

- Amazon S3-Managed Keys (SSE-S3)
- Customer Master Keys (CMKs) Stored in AWS Key Management Service (SSE-KMS)
- Customer-Provided Keys (SSE-C)

Use your mode of choice with GitLab. Each mode has similar, but slightly
different, configuration methods.

###### SSE-S3

To enable SSE-S3, in the backup storage options set the `server_side_encryption`
field to `AES256`. For example, in the Linux package (Omnibus):

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'AES256'
}
```

###### SSE-KMS

To enable SSE-KMS, you need the
[KMS key via its Amazon Resource Name (ARN) in the `arn:aws:kms:region:acct-id:key/key-id` format](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html).
Under the `backup_upload_storage_options` configuration setting, set:

- `server_side_encryption` to `aws:kms`.
- `server_side_encryption_kms_key_id` to the ARN of the key.

For example, in the Linux package (Omnibus):

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'aws:kms',
  'server_side_encryption_kms_key_id' => 'arn:aws:<YOUR KMS KEY ID>:'
}
```

###### SSE-C

SSE-C requires you to set these encryption options:

- `backup_encryption`: AES256.
- `backup_encryption_key`: Unencoded, 32-byte (256 bits) key. The upload fails if this isn't exactly 32 bytes.

For example, in the Linux package (Omnibus):

```ruby
gitlab_rails['backup_encryption'] = 'AES256'
gitlab_rails['backup_encryption_key'] = '<YOUR 32-BYTE KEY HERE>'
```

If the key contains binary characters and cannot be encoded in UTF-8,
instead, specify the key with the `GITLAB_BACKUP_ENCRYPTION_KEY` environment variable.
For example:

```ruby
gitlab_rails['env'] = { 'GITLAB_BACKUP_ENCRYPTION_KEY' => "\xDE\xAD\xBE\xEF" * 8 }
```

##### Digital Ocean Spaces

This example can be used for a bucket in Amsterdam (AMS3):

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'ams3',
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123',
     'endpoint'              => 'https://ams3.digitaloceanspaces.com'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect

If you see a `400 Bad Request` error message when using Digital Ocean Spaces,
the cause may be the use of backup encryption. Because Digital Ocean Spaces
doesn't support encryption, remove or comment the line that contains
`gitlab_rails['backup_encryption']`.

##### Other S3 Providers

Not all S3 providers are fully compatible with the Fog library. For example,
if you see a `411 Length Required` error message after attempting to upload,
you may need to downgrade the `aws_signature_version` value from the default
value to `2`, [due to this issue](https://github.com/fog/fog-aws/issues/428).

For self-compiled installations:

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
     backup:
       # snip
       upload:
         # Fog storage connection settings, see https://fog.io/storage/ .
         connection:
           provider: AWS
           region: eu-west-1
           aws_access_key_id: AKIAKIAKI
           aws_secret_access_key: 'secret123'
           # If using an IAM Profile, leave aws_access_key_id & aws_secret_access_key empty
           # ie. aws_access_key_id: ''
           # use_iam_profile: 'true'
         # The remote 'directory' to store your backups. For S3, this would be the bucket name.
         remote_directory: 'my.s3.bucket'
         # Specifies Amazon S3 storage class to use for backups, this is optional
         # storage_class: 'STANDARD'
         #
         # Turns on AWS Server-Side Encryption with Amazon Customer-Provided Encryption Keys for backups, this is optional
         #   'encryption' must be set in order for this to have any effect.
         #   'encryption_key' should be set to the 256-bit encryption key for Amazon S3 to use to encrypt or decrypt.
         #   To avoid storing the key on disk, the key can also be specified via the `GITLAB_BACKUP_ENCRYPTION_KEY` your data.
         # encryption: 'AES256'
         # encryption_key: '<key>'
         #
         #
         # Turns on AWS Server-Side Encryption with Amazon S3-Managed keys (optional)
         # https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html
         # For SSE-S3, set 'server_side_encryption' to 'AES256'.
         # For SS3-KMS, set 'server_side_encryption' to 'aws:kms'. Set
         # 'server_side_encryption_kms_key_id' to the ARN of customer master key.
         # storage_options:
         #   server_side_encryption: 'aws:kms'
         #   server_side_encryption_kms_key_id: 'arn:aws:kms:YOUR-KEY-ID-HERE'
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect

##### Using Google Cloud Storage

To use Google Cloud Storage to save backups, you must first create an
access key from the Google console:

1. Go to the [Google storage settings page](https://console.cloud.google.com/storage/settings).
1. Select **Interoperability**, and then create an access key.
1. Make note of the **Access Key** and **Secret** and replace them in the
   following configurations.
1. In the buckets advanced settings ensure the Access Control option
   **Set object-level and bucket-level permissions** is selected.
1. Ensure you have already created a bucket.

For the Linux package (Omnibus):

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'Google',
     'google_storage_access_key_id' => 'Access Key',
     'google_storage_secret_access_key' => 'Secret',

     ## If you have CNAME buckets (foo.example.com), you might run into SSL issues
     ## when uploading backups ("hostname foo.example.com.storage.googleapis.com
     ## does not match the server certificate"). In that case, uncomment the following
     ## setting. See: https://github.com/fog/fog/issues/2834
     #'path_style' => true
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.google.bucket'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect

For self-compiled installations:

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
     backup:
       upload:
         connection:
           provider: 'Google'
           google_storage_access_key_id: 'Access Key'
           google_storage_secret_access_key: 'Secret'
         remote_directory: 'my.google.bucket'
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect

##### Using Azure Blob storage

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
    'provider' => 'AzureRM',
    'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
    'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
    'azure_storage_domain' => 'blob.core.windows.net', # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

   If you are using [a managed identity](../object_storage.md#azure-workload-and-managed-identities), omit `azure_storage_access_key`:

   ```ruby
   gitlab_rails['object_store']['connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>' # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect

:::TabTitle Self-compiled

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
     backup:
       upload:
         connection:
           provider: 'AzureRM'
           azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
           azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
         remote_directory: '<AZURE BLOB CONTAINER>'
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect

::EndTabs

For more details, see the [table of Azure parameters](../object_storage.md#azure-blob-storage).

##### Specifying a custom directory for backups

This option works only for remote storage. If you want to group your backups,
you can pass a `DIRECTORY` environment variable:

```shell
sudo gitlab-backup create DIRECTORY=daily
sudo gitlab-backup create DIRECTORY=weekly
```

#### Skip uploading backups to remote storage

If you have configured GitLab to [upload backups in a remote storage](#upload-backups-to-a-remote-cloud-storage),
you can use the `SKIP=remote` option to skip uploading your backups to the remote storage.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create SKIP=remote
```

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=remote RAILS_ENV=production
```

::EndTabs

#### Upload to locally-mounted shares

You can send backups to a locally-mounted share (for example, `NFS`,`CIFS`, or `SMB`) using the Fog
[`Local`](https://github.com/fog/fog-local#usage) storage provider.

To do this, you must set the following configuration keys:

- `backup_upload_connection.local_root`: mounted directory that backups are copied to.
- `backup_upload_remote_directory`: subdirectory of the `backup_upload_connection.local_root` directory. It is created if it doesn't exist.
  If you want to copy the tarballs to the root of your mounted directory, use `.`.

When mounted, the directory set in the `local_root` key must be owned by either:

- The `git` user. So, mounting with the `uid=` of the `git` user for `CIFS` and `SMB`.
- The user that you are executing the backup tasks as. For the Linux package (Omnibus), this is the `git` user.

Because file system performance may affect overall GitLab performance,
[we don't recommend using cloud-based file systems for storage](../nfs.md#avoid-using-cloud-based-file-systems).

##### Avoid conflicting configuration

Don't set the following configuration keys to the same path:

- `gitlab_rails['backup_path']` (`backup.path` for self-compiled installations).
- `gitlab_rails['backup_upload_connection'].local_root` (`backup.upload.connection.local_root` for self-compiled installations).

The `backup_path` configuration key sets the local location of the backup file. The `upload` configuration key is
intended for use when the backup file is uploaded to a separate server, perhaps for archival purposes.

If these configuration keys are set to the same location, the upload feature fails because a backup already exists at
the upload location. This failure causes the upload feature to delete the backup because it assumes it's a residual file
remaining after the failed upload attempt.

##### Configure uploads to locally-mounted shares

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     :provider => 'Local',
     :local_root => '/mnt/backups'
   }

   # The directory inside the mounted folder to copy backups to
   # Use '.' to store them in the root directory
   gitlab_rails['backup_upload_remote_directory'] = 'gitlab_backups'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

:::TabTitle Self-compiled

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
   backup:
     upload:
       # Fog storage connection settings, see https://fog.io/storage/ .
       connection:
         provider: Local
         local_root: '/mnt/backups'
       # The directory inside the mounted folder to copy backups to
       # Use '.' to store them in the root directory
       remote_directory: 'gitlab_backups'
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

::EndTabs

#### Backup archive permissions

The backup archives created by GitLab (`1393513186_2014_02_27_gitlab_backup.tar`)
have the owner/group `git`/`git` and 0600 permissions by default. This is
meant to avoid other system users reading GitLab data. If you need the backup
archives to have different permissions, you can use the `archive_permissions`
setting.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_archive_permissions'] = 0644 # Makes the backup archives world-readable
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

:::TabTitle Self-compiled

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   backup:
     archive_permissions: 0644 # Makes the backup archives world-readable
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

::EndTabs

#### Configuring cron to make daily backups

WARNING:
The following cron jobs do not [back up your GitLab configuration files](#storing-configuration-files)
or [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

You can schedule a cron job that backs up your repositories and GitLab metadata.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit the crontab for the `root` user:

   ```shell
   sudo su -
   crontab -e
   ```

1. There, add the following line to schedule the backup for everyday at 2 AM:

   ```plaintext
   0 2 * * * /opt/gitlab/bin/gitlab-backup create CRON=1
   ```

:::TabTitle Self-compiled

1. Edit the crontab for the `git` user:

   ```shell
   sudo -u git crontab -e
   ```

1. Add the following lines at the bottom:

   ```plaintext
   # Create a full backup of the GitLab repositories and SQL database every day at 2am
   0 2 * * * cd /home/git/gitlab && PATH=/usr/local/bin:/usr/bin:/bin bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1
   ```

::EndTabs

The `CRON=1` environment setting directs the backup script to hide all progress
output if there aren't any errors. This is recommended to reduce cron spam.
When troubleshooting backup problems, however, replace `CRON=1` with `--trace` to log verbosely.

#### Limit backup lifetime for local files (prune old backups)

WARNING:
The process described in this section doesn't work if you used a [custom filename](#backup-filename)
for your backups.

To prevent regular backups from using all your disk space, you may want to set a limited lifetime
for backups. The next time the backup task runs, backups older than the `backup_keep_time` are
pruned.

This configuration option manages only local files. GitLab doesn't prune old
files stored in a third-party [object storage](#upload-backups-to-a-remote-cloud-storage)
because the user may not have permission to list and delete files. It's
recommended that you configure the appropriate retention policy for your object
storage (for example, [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-lifecycle.html)).

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

:::TabTitle Self-compiled

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   backup:
     ## Limit backup lifetime to 7 days - 604800 seconds
     keep_time: 604800
   ```

1. [Restart GitLab](../restart_gitlab.md#self-compiled-installations)
   for the changes to take effect.

::EndTabs

#### Back up and restore for installations using PgBouncer

Do not back up or restore GitLab through a PgBouncer connection. These
tasks must [bypass PgBouncer and connect directly to the PostgreSQL primary database node](#bypassing-pgbouncer),
or they cause a GitLab outage.

When the GitLab backup or restore task is used with PgBouncer, the
following error message is shown:

```ruby
ActiveRecord::StatementInvalid: PG::UndefinedTable
```

Each time the GitLab backup runs, GitLab starts generating 500 errors and errors about missing
tables will [be logged by PostgreSQL](../logs/_index.md#postgresql-logs):

```plaintext
ERROR: relation "tablename" does not exist at character 123
```

This happens because the task uses `pg_dump`, which
[sets a null search path and explicitly includes the schema in every SQL query](https://gitlab.com/gitlab-org/gitlab/-/issues/23211)
to address [CVE-2018-1058](https://www.postgresql.org/about/news/postgresql-103-968-9512-9417-and-9322-released-1834/).

Because connections are reused with PgBouncer in transaction pooling mode,
PostgreSQL fails to search the default `public` schema. As a result,
this clearing of the search path causes tables and columns to appear
missing.

##### Bypassing PgBouncer

There are two ways to fix this:

1. [Use environment variables to override the database settings](#environment-variable-overrides) for the backup task.
1. Reconfigure a node to [connect directly to the PostgreSQL primary database node](../postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer).

###### Environment variable overrides

> - Multiple databases support was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133177) in GitLab 16.5.

By default, GitLab uses the database configuration stored in a
configuration file (`database.yml`). However, you can override the database settings
for the backup and restore task by setting environment
variables that are prefixed with `GITLAB_BACKUP_`:

- `GITLAB_BACKUP_PGHOST`
- `GITLAB_BACKUP_PGUSER`
- `GITLAB_BACKUP_PGPORT`
- `GITLAB_BACKUP_PGPASSWORD`
- `GITLAB_BACKUP_PGSSLMODE`
- `GITLAB_BACKUP_PGSSLKEY`
- `GITLAB_BACKUP_PGSSLCERT`
- `GITLAB_BACKUP_PGSSLROOTCERT`
- `GITLAB_BACKUP_PGSSLCRL`
- `GITLAB_BACKUP_PGSSLCOMPRESSION`

For example, to override the database host and port to use 192.168.1.10
and port 5432 with the Linux package (Omnibus):

```shell
sudo GITLAB_BACKUP_PGHOST=192.168.1.10 GITLAB_BACKUP_PGPORT=5432 /opt/gitlab/bin/gitlab-backup create
```

If you run GitLab on [multiple databases](../postgresql/multiple_databases.md), you can override database settings by including
the database name in the environment variable. For example if your `main` and `ci` databases are
hosted on different database servers, you would append their name after the `GITLAB_BACKUP_` prefix,
leaving the `PG*` names as is:

```shell
sudo GITLAB_BACKUP_MAIN_PGHOST=192.168.1.10 GITLAB_BACKUP_CI_PGHOST=192.168.1.12 /opt/gitlab/bin/gitlab-backup create
```

See the [PostgreSQL documentation](https://www.postgresql.org/docs/12/libpq-envars.html)
for more details on what these parameters do.

#### `gitaly-backup` for repository backup and restore

The `gitaly-backup` binary is used by the backup Rake task to create and restore repository backups from Gitaly.
`gitaly-backup` replaces the previous backup method that directly calls RPCs on Gitaly from GitLab.

The backup Rake task must be able to find this executable. In most cases, you don't need to change
the path to the binary as it should work fine with the default path `/opt/gitlab/embedded/bin/gitaly-backup`.
If you have a specific reason to change the path, it can be configured in the Linux package (Omnibus):

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_gitaly_backup_path'] = '/path/to/gitaly-backup'
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

## Alternative backup strategies

Because every deployment may have different capabilities, you should first review [what data needs to be backed up](#what-data-needs-to-be-backed-up) to better understand if, and how, you can leverage them.

For example, if you use Amazon RDS, you might choose to use its built-in backup and restore features to handle your GitLab [PostgreSQL data](#postgresql-databases), and [exclude PostgreSQL data](#excluding-specific-data-from-the-backup) when using the [backup command](#backup-command).

In the following cases, consider using file system data transfer or snapshots as part of your backup strategy:

- Your GitLab instance contains a lot of Git repository data and the GitLab backup script is too slow.
- Your GitLab instance has a lot of forked projects and the regular backup task duplicates the Git data for all of them.
- Your GitLab instance has a problem and using the regular backup and import Rake tasks isn't possible.

WARNING:
Gitaly Cluster [does not support snapshot backups](../gitaly/_index.md#snapshot-backup-and-recovery).

When considering using file system data transfer or snapshots:

- Don't use these methods to migrate from one operating system to another. The operating systems of the source and destination should be as similar as possible. For example,
  don't use these methods to migrate from Ubuntu to RHEL.
- Data consistency is very important. You should stop GitLab (`sudo gitlab-ctl stop`) before
  doing a file system transfer (with `rsync`, for example) or taking a snapshot to ensure all data in memory is flushed to disk. GitLab consists of multiple subsystems (Gitaly, database, file storage) that have their own buffers, queues, and storage layers. GitLab transactions can span these subsystems, which results in parts of a transaction taking different paths to disk. On live systems, file system transfers and snapshot runs fail to capture parts of the transaction still in memory.

Example: Amazon Elastic Block Store (EBS)

- A GitLab server using the Linux package (Omnibus) hosted on Amazon AWS.
- An EBS drive containing an ext4 file system is mounted at `/var/opt/gitlab`.
- In this case you could make an application backup by taking an EBS snapshot.
- The backup includes all repositories, uploads and PostgreSQL data.

Example: Logical Volume Manager (LVM) snapshots + rsync

- A GitLab server using the Linux package (Omnibus), with an LVM logical volume mounted at `/var/opt/gitlab`.
- Replicating the `/var/opt/gitlab` directory using rsync would not be reliable because too many files would change while rsync is running.
- Instead of rsync-ing `/var/opt/gitlab`, we create a temporary LVM snapshot, which we mount as a read-only file system at `/mnt/gitlab_backup`.
- Now we can have a longer running rsync job which creates a consistent replica on the remote server.
- The replica includes all repositories, uploads and PostgreSQL data.

If you're running GitLab on a virtualized server, you can possibly also create
VM snapshots of the entire GitLab server. It's not uncommon however for a VM
snapshot to require you to power down the server, which limits this solution's
practical use.

### Back up repository data separately

First, ensure you back up existing GitLab data while [skipping repositories](#excluding-specific-data-from-the-backup):

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-backup create SKIP=repositories
```

:::TabTitle Self-compiled

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=repositories RAILS_ENV=production
```

::EndTabs

For manually backing up the Git repository data on disk, there are multiple possible strategies:

- Use snapshots, such as the previous examples of Amazon EBS drive snapshots, or LVM snapshots + rsync.
- Use [GitLab Geo](../geo/_index.md) and rely on the repository data on a Geo secondary site.
- [Prevent writes and copy the Git repository data](#prevent-writes-and-copy-the-git-repository-data).
- [Create an online backup by marking repositories as read-only (experimental)](#online-backup-through-marking-repositories-as-read-only-experimental).

#### Prevent writes and copy the Git repository data

Git repositories must be copied in a consistent way. They should not be copied during concurrent write
operations, as this can lead to inconsistencies or corruption issues. For more details,
[issue #270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422 "Provide documentation on preferred method of migrating Gitaly servers")
has a longer discussion explaining the potential problems.

To prevent writes to the Git repository data, there are two possible approaches:

- Use [maintenance mode](../maintenance_mode/_index.md) to place GitLab in a read-only state.
- Create explicit downtime by stopping all Gitaly services before backing up the repositories:

  ```shell
  sudo gitlab-ctl stop gitaly
  # execute git data copy step
  sudo gitlab-ctl start gitaly
  ```

You can copy Git repository data using any method, as long as writes are prevented on the data being copied
(to prevent inconsistencies and corruption issues). In order of preference and safety, the recommended methods are:

1. Use `rsync` with archive-mode, delete, and checksum options, for example:

   ```shell
   rsync -aR --delete --checksum source destination # be extra safe with the order as it will delete existing data if inverted
   ```

1. Use a [`tar` pipe to copy the entire repository's directory to another server or location](../operations/moving_repositories.md#tar-pipe-to-another-server).

1. Use `sftp`, `scp`, `cp`, or any other copying method.

#### Online backup through marking repositories as read-only (experimental)

One way of backing up repositories without requiring instance-wide downtime
is to programmatically mark projects as read-only while copying the underlying data.

There are a few possible downsides to this:

- Repositories are read-only for a period of time that scales with the size of the repository.
- Backups take a longer time to complete due to marking each project as read-only, potentially leading to inconsistencies. For example,
  a possible date discrepancy between the last data available for the first project that gets backed up compared to
  the last project that gets backed up.
- Fork networks should be entirely read-only while the projects inside get backed up to prevent potential changes to the pool repository.

There is an **experimental** script that attempts to automate this process in
[the Geo team Runbooks project](https://gitlab.com/gitlab-org/geo-team/runbooks/-/tree/main/experimental-online-backup-through-rsync).
