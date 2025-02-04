---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: How GitLab backups work?
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab provides recommendations for how to create application backups across different installation types and different hosting architectures. We provide simple tools to create a point-in-time application backup, as well as specialized documentation for how to handle complex Cloud-based installation backups.

Backup and Restore relies primarily on the `gitlab-backup` tool that is shipped with the Linux Package and Docker installation methods.

There is an additional tool shipped only for Kubernetes installations: `backup-utility` that has a different implementation.

## The `gitlab-backup` Tool

Current GitLab documentation on performing backup [creation](../../administration/backup_restore/backup_gitlab.md#backup-command) and [restoration](../../administration/backup_restore/restore_gitlab.md#restore-for-linux-package-installations) points to using a special command we ship inside the system packages created with Omnibus: `gitlab-backup`. This command has a very simple interface with two subcommand options:

```shell
# To create a backup
sudo gitlab-backup create
# This corresponds to gitlab-rake gitlab:backup:create

# To restore a previously-captured backup
sudo gitlab-backup restore BACKUP=<backup_id>
# This corresponds to gitlab-rake gitlab:backup:restore BACKUP=<backup_id>
```

This command is actually a shell script that serves to wrap the core backup and restore Rake tasks defined in the GitLab Rails application. Rake tasks are generally invoked with environmental variables to define parameters and runtime configuration, and these commands will pass any significant environmental settings to the Rake process when invoked. However, the main backup creation and restoration work is defined inside the Rake tasks, which we will discuss in greater depth in the next section.

## Rake Tasks

Today, the GitLab Rails application provides several Rake tasks that are the primary means for administrators to capture a backup of application data and then to subsequently restore it.

### Creating a Point-In-Time Backup Archive

```shell
sudo gitlab-rake gitlab:backup:create [env-overrides]
```

The backup creation Rake task has the goal of capturing the state of all families of GitLab application data at the time of execution. In general, when successfully invoked, the creation task will build a backup archive tarball file.

The content and format of the archive tarball may be significantly altered by both system-wide configuration settings in `/etc/gitlab/gitlab.rb` or through environmental variables set at the time of invocation. Furthermore, these different settings can determine where backups are stored after creation, or where they can be discovered upon restoration. There are options to tweak performance while doing these operations on installations that have a much larger data burden than a typical 1K install.

#### Default Backup Creation Procedure

When a user executes the backup creation Rake task, the following sequence of high level steps will be executed:

1. Create a temporary directory to store all application backup data and metadata.
1. Dump each PostgreSQL database used by the application in a SQL file in the `db` subdirectory of the archive. This is generally done by invoking `pg_dump` on each significant database. Each `.sql` file created is further compressed with `gzip`.
1. Request a bundle export of each Git repository in the application through Gitaly. All of this data is retained in the `repositories` directory of the archive. Note that this includes any "wiki" or "design" data associated with projects, as those features are stored as associated Git repositories.
1. For each remaining "blob"-oriented data feature, each blob corresponds to a file in a directory. So, for each binary data feature, copy each of its blob entries to a named file in a temporary directory in the archive. Once all data has been copied over, compress and serialize the directory into a `.tar.gz` file that is itself embedded in the archive. This is done for each of the following features:

   - `artifacts`
   - `builds`
   - `ci_secure_files`
   - `external_diffs`
   - `lfs`
   - `packages`
   - `pages`
   - `registry`
   - `uploads`
   - `terraform_state`

1. Record the parameters and status of the backup operation in a YAML file named `backup_information.yml` in the top level of the archive directory.
1. Serialize the temporary archive directory into a single `.tar` tarball file.
1. Move the tarball file to its final storage place. Depending on system configuration and parameters, this may be a directory on the machine running the creation task, or this may be a storage bucket on a cloud storage service like S3 or Google Storage.

Take note that there are a number of configuration and environmental parameters that may alter this general procedure. These parameters are covered in the next sections.

#### Customizing Backup Creation

The system-wide GitLab configuration file, typically located at `/etc/gitlab/gitlab.rb`, allows setting a number of standard parameters for any backup creation or restoration invocation. In particular, the following table shows keys that may be set on the `gitlab_rails` configuration object which impact the execution of backup operations:

| Configuration Key                |
|----------------------------------|
| `backup_archive_permissions`     |
| `backup_encryption`              |
| `backup_encryption_key`          |
| `backup_gitaly_backup_path`      |
| `backup_keep_time`               |
| `backup_path`                    |
| `backup_upload_connection`       |
| `backup_upload_remote_directory` |
| `backup_upload_storage_class`    |
| `backup_upload_storage_options`  |

Furthermore, each execution of a backup creation or restoration operation may set environmental variables to modify the backup algorithm, data access locations, or archive storage formatting. For the act of creating a backup archive, the Rake task supports the following environmental variable settings:

| Environmental Variable                  |
|-----------------------------------------|
| `BACKUP`                                |
| `COMPRESS_CMD`                          |
| `CRON`                                  |
| `GITLAB_BACKUP_ENCRYPTION_KEY`          |
| `GITLAB_BACKUP_MAX_CONCURRENCY`         |
| `GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY` |
| `GZIP_RSYNCABLE`                        |
| `INCREMENTAL`                           |
| `PREVIOUS_BACKUP`                       |
| `REPOSITORIES_PATHS`                    |
| `REPOSITORIES_SERVER_SIDE`              |
| `REPOSITORIES_STORAGES`                 |
| `SKIP_REPOSITORIES_PATHS`               |
| `STRATEGY`                              |

##### Restoring a Point-In-Time Backup Archive

```shell
sudo gitlab-rake gitlab:backup:restore BACKUP=<backup_id> [env-overrides]
```

Once a user has run the backup creation task successfully at some prior time, they will have access to an archive tarball file that may be used to restore the application data state to roughly that point in time. These archive files will be stored either on the local system in a specific directory, or in a cloud object storage bucket, depending on the system configuration. But once an administrator is sure that backups have been captured, they can request restoration of a particular backup using the `gitlab-rake` command shown above, where `<backup_id>` indicates the base file name of the backup tarball.

Running a restore operation will obliterate the current state of application data. Thus, the Rake task will pause to confirm the destructive action with the user before proceeding.

#### Default Backup Restoration Procedure

When a user executes the backup restoration Rake task, a sequence of steps are carried out that mirror the steps performed during the creation process. This sequence is outlined as follows:

1. Create a temporary directory to serve as a working directory during restoration
1. Fetch a copy of the target archive tarball and unpack its content inside the work directory
1. Validate that the archive data is able to be restored:

   1. Read its backup metadata from the `backup_information.yml` file if exists.
   1. Verify the GitLab application version at the time of backup matches the current application version.
   1. Fail out of the whole restore process if any of these files do not exist, are malformed, or if the version does not match.

1. Confirm the user wishes to destroy all current GitLab data before proceeding with restoration.
1. Read and decompress each `.sql.gz` file corresponding to a known application database. Run the SQL content to overwrite the full state of each database.
1. Fetch all repository bundle data stored in the `repositories` archive directory. Work with the Gitaly service to restore each repository to its expected storage location using the saved bundle data. find a `.tar.gz` file in the top archive directory that corresponds to the target feature. Decompress each feature tarball and read its binary file contents, copying to the appropriate blob storage configured for the system. This action is performed for each of the following features:

   - `uploads`
   - `builds`
   - `artifacts`
   - `pages`
   - `lfs`
   - `terraform_state`
   - `registry`
   - `packages`
   - `ci_secure_files`

1. Reconfigure SSH access and rebuild an `authorized_keys` file by running GitLab Shell setup task.
1. Clear any cache data.

As with the backup creation operation, there are numerous configuration file values and environmental variables that may alter how the restoration task is performed.
