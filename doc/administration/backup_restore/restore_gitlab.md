---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Restore GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab provides a command-line interface to restore your entire installation,
and is flexible enough to fit your needs.

The [restore prerequisites section](#restore-prerequisites) includes crucial
information. Be sure to read and test the complete restore process at least
once before attempting to perform it in a production environment.

## Restore prerequisites

### The destination GitLab instance must already be working

You need to have a working GitLab installation before you can perform a
restore. This is because the system user performing the restore actions (`git`)
is usually not allowed to create or delete the SQL database needed to import
data into (`gitlabhq_production`). All existing data is either erased
(SQL) or moved to a separate directory (such as repositories and uploads).
Restoring SQL data skips views owned by PostgreSQL extensions.

### The destination GitLab instance must have the exact same version

You can only restore a backup to **exactly the same version and type (CE or EE)**
of GitLab on which it was created. For example, CE 15.1.4.

If your backup is a different version than the current installation, you must
[downgrade](../../update/package/downgrade.md) or [upgrade](../../update/package/_index.md#upgrade-to-a-specific-version) your GitLab installation
before restoring the backup.

### GitLab secrets must be restored

To restore a backup, **you must also restore the GitLab secrets**.
These include the database encryption key, [CI/CD variables](../../ci/variables/_index.md), and
variables used for [two-factor authentication](../../user/profile/account/two_factor_authentication.md).
Without the keys, [multiple issues occur](../backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost), including loss of access by users with [two-factor authentication enabled](../../user/profile/account/two_factor_authentication.md),
and GitLab Runners cannot sign in.

Restore:

- `/etc/gitlab/gitlab-secrets.json` (Linux package installations)
- `/home/git/gitlab/.secret` (self-compiled installations)
- [Restoring the secrets](https://docs.gitlab.com/charts/backup-restore/restore.html#restoring-the-secrets) (cloud-native GitLab)
  - [GitLab Helm chart secrets can be converted to the Linux package format](https://docs.gitlab.com/charts/installation/migration/helm_to_package.html), if required.

### Certain GitLab configuration must match the original backed up environment

You likely also want to restore your previous `/etc/gitlab/gitlab.rb` (for Linux package installations)
or `/home/git/gitlab/config/gitlab.yml` (for self-compiled installations) and
any TLS keys, certificates (`/etc/gitlab/ssl`, `/etc/gitlab/trusted-certs`), or
[SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

Certain configuration is coupled to data in PostgreSQL. For example:

- If the original environment has three repository storages (for example, `default`, `my-storage-1`, and `my-storage-2`), then the target environment must also have at least those storage names defined in configuration.
- Restoring a backup from an environment using local storage restores to local storage even if the target environment uses object storage. Migrations to object storage must be done before or after restoration.

### Restoring directories that are mount points

If you're restoring into directories that are mount points, you must ensure these directories are
empty before attempting a restore. Otherwise, GitLab attempts to move these directories before
restoring the new data, which causes an error.

Read more about [configuring NFS mounts](../nfs.md).

## Restore for Linux package installations

This procedure assumes that:

- You have installed the **exact same version and type (CE/EE)** of GitLab
  with which the backup was created.
- You have run `sudo gitlab-ctl reconfigure` at least once.
- GitLab is running. If not, start it using `sudo gitlab-ctl start`.

First ensure your backup tar file is in the backup directory described in the
`gitlab.rb` configuration `gitlab_rails['backup_path']`. The default is
`/var/opt/gitlab/backups`. The backup file needs to be owned by the `git` user.

```shell
sudo cp 11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar /var/opt/gitlab/backups/
sudo chown git:git /var/opt/gitlab/backups/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar
```

Stop the processes that are connected to the database. Leave the rest of GitLab
running:

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status
```

Next, ensure you have completed the [restore prerequisites](#restore-prerequisites) steps and have run `gitlab-ctl reconfigure`
after copying over the GitLab secrets file from the original installation.

Next, restore the backup, specifying the ID of the backup you wish to
restore:

WARNING:
The following command overwrites the contents of your GitLab database!

```shell
# NOTE: "_gitlab_backup.tar" is omitted from the name
sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

If there's a GitLab version mismatch between your backup tar file and the
installed version of GitLab, the restore command aborts with an error
message:

```plaintext
GitLab version mismatch:
  Your current GitLab version (16.5.0-ee) differs from the GitLab version in the backup!
  Please switch to the following version and try again:
  version: 16.4.3-ee
```

Install the [correct GitLab version](https://packages.gitlab.com/gitlab/),
and then try again.

WARNING:
The restore command requires [additional parameters](backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer) when
your installation is using PgBouncer, for either performance reasons or when using it with a Patroni cluster.

Next, restart and [check](../raketasks/maintenance.md#check-gitlab-configuration) GitLab:

```shell
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true
```

Verify that the [database values can be decrypted](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)
especially if `/etc/gitlab/gitlab-secrets.json` was restored, or if a different server is
the target for the restore.

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

For added assurance, you can perform [an integrity check on the uploaded files](../raketasks/check.md#uploaded-files-integrity):

```shell
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

After the restore is completed, it's recommended to generate database statistics to improve the database performance and avoid inconsistencies in the UI:

1. Enter the [database console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-postgresql-database).
1. Run the following:

   ```sql
   SET STATEMENT_TIMEOUT=0 ; ANALYZE VERBOSE;
   ```

There are ongoing discussions about integrating the command into the restore command, see [issue 276184](https://gitlab.com/gitlab-org/gitlab/-/issues/276184) for more details.

## Restore for Docker image and GitLab Helm chart installations

For GitLab installations using the Docker image or the GitLab Helm chart on a
Kubernetes cluster, the restore task expects the restore directories to be
empty. However, with Docker and Kubernetes volume mounts, some system level
directories may be created at the volume roots, such as the `lost+found`
directory found in Linux operating systems. These directories are usually owned
by `root`, which can cause access permission errors since the restore Rake task
runs as the `git` user. To restore a GitLab installation, users have to confirm
the restore target directories are empty.

For both these installation types, the backup tarball has to be available in
the backup location (default location is `/var/opt/gitlab/backups`).

### Restore for Helm chart installations

The GitLab Helm chart uses the process documented in
[restoring a GitLab Helm chart installation](https://docs.gitlab.com/charts/backup-restore/restore.html#restoring-a-gitlab-installation)

### Restore for Docker image installations

If you're using [Docker Swarm](../../install/docker/installation.md#install-gitlab-by-using-docker-swarm-mode),
the container might restart during the restore process because Puma is shut down,
and so the container health check fails. To work around this problem,
temporarily disable the health check mechanism.

1. Edit `docker-compose.yml`:

   ```yaml
   healthcheck:
     disable: true
   ```

1. Deploy the stack:

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

For more information, see [issue 6846](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6846 "GitLab restore can fail owing to `gitlab-healthcheck`").

The restore task can be run from the host:

```shell
# Stop the processes that are connected to the database
docker exec -it <name of container> gitlab-ctl stop puma
docker exec -it <name of container> gitlab-ctl stop sidekiq

# Verify that the processes are all down before continuing
docker exec -it <name of container> gitlab-ctl status

# Run the restore. NOTE: "_gitlab_backup.tar" is omitted from the name
docker exec -it <name of container> gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce

# Restart the GitLab container
docker restart <name of container>

# Check GitLab
docker exec -it <name of container> gitlab-rake gitlab:check SANITIZE=true
```

## Restore for self-compiled installations

First, ensure your backup tar file is in the backup directory described in the
`gitlab.yml` configuration:

```yaml
## Backup settings
backup:
  path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
```

The default is `/home/git/gitlab/tmp/backups`, and it needs to be owned by the `git` user. Now, you can begin the backup procedure:

```shell
# Stop processes that are connected to the database
sudo service gitlab stop

sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

Example output:

```plaintext
Unpacking backup... [DONE]
Restoring database tables:
-- create_table("events", {:force=>true})
   -> 0.2231s
[...]
- Loading fixture events...[DONE]
- Loading fixture issues...[DONE]
- Loading fixture keys...[SKIPPING]
- Loading fixture merge_requests...[DONE]
- Loading fixture milestones...[DONE]
- Loading fixture namespaces...[DONE]
- Loading fixture notes...[DONE]
- Loading fixture projects...[DONE]
- Loading fixture protected_branches...[SKIPPING]
- Loading fixture schema_migrations...[DONE]
- Loading fixture services...[SKIPPING]
- Loading fixture snippets...[SKIPPING]
- Loading fixture taggings...[SKIPPING]
- Loading fixture tags...[SKIPPING]
- Loading fixture users...[DONE]
- Loading fixture users_projects...[DONE]
- Loading fixture web_hooks...[SKIPPING]
- Loading fixture wikis...[SKIPPING]
Restoring repositories:
- Restoring repository abcd... [DONE]
- Object pool 1 ...
Deleting tmp directories...[DONE]
```

Next, restore `/home/git/gitlab/.secret` if necessary, [as previously mentioned](#restore-prerequisites).

Restart GitLab:

```shell
sudo service gitlab restart
```

## Restoring only one or a few projects or groups from a backup

Although the Rake task used to restore a GitLab instance doesn't support
restoring a single project or group, you can use a workaround by restoring
your backup to a separate, temporary GitLab instance, and then export your
project or group from there:

1. [Install a new GitLab](../../install/_index.md) instance at the same version as
   the backed-up instance from which you want to restore.
1. Restore the backup into this new instance, then
   export your [project](../../user/project/settings/import_export.md)
   or [group](../../user/project/settings/import_export.md#migrate-groups-by-uploading-an-export-file-deprecated). For
   more information about what is and isn't exported, see the export feature's documentation.
1. After the export is complete, go to the old instance and then import it.
1. After importing the projects or groups that you wanted is complete, you may
   delete the new, temporary GitLab instance.

A feature request to provide direct restore of individual projects or groups
is being discussed in [issue #17517](https://gitlab.com/gitlab-org/gitlab/-/issues/17517).

## Restoring an incremental repository backup

Each backup archive contains a full self-contained backup, including those created through the [incremental repository backup procedure](backup_gitlab.md#incremental-repository-backups). To restore an incremental repository backup, use the same instructions as restoring any other regular backup archive.

## Restore options

The command-line tool GitLab provides to restore from backup can accept more
options.

### Specify backup to restore when there are more than one

Backup files use a naming scheme [starting with a backup ID](backup_archive_process.md#backup-id). When more than one backup exists, you must specify which
`<backup-id>_gitlab_backup.tar` file to restore by setting the environment variable `BACKUP=<backup-id>`.

### Disable prompts during restore

During a restore from backup, the restore script prompts for confirmation:

- If the **Write to authorized_keys** setting is enabled, before the restore script deletes and rebuilds the `authorized_keys` file.
- When restoring the database, before the restore script removes all existing tables.
- After restoring the database, if there were errors in restoring the schema, before continuing because further problems are likely.

To disable these prompts, set the `GITLAB_ASSUME_YES` environment variable to `1`.

- Linux package installations:

  ```shell
  sudo GITLAB_ASSUME_YES=1 gitlab-backup restore
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H GITLAB_ASSUME_YES=1 bundle exec rake gitlab:backup:restore RAILS_ENV=production
  ```

The `force=yes` environment variable also disables these prompts.

### Excluding tasks on restore

You can exclude specific tasks on restore by adding the environment variable `SKIP`, whose values are a comma-separated list of the following options:

- `db` (database)
- `uploads` (attachments)
- `builds` (CI job output logs)
- `artifacts` (CI job artifacts)
- `lfs` (LFS objects)
- `terraform_state` (Terraform states)
- `registry` (Container registry images)
- `pages` (Pages content)
- `repositories` (Git repositories data)
- `packages` (Packages)

To exclude specific tasks:

- Linux package installations:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> SKIP=db,uploads
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> SKIP=db,uploads RAILS_ENV=production
  ```

### Restore specific repository storages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896) in GitLab 15.0.

WARNING:
GitLab 17.1 and earlier are [affected by a race condition](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158412) that can cause data loss. The problem affects
repositories that have been forked and use GitLab [object pools](../repository_storage_paths.md#hashed-object-pools). To avoid data loss, **only restore backups by using GitLab
17.2 or later**.

When using [multiple repository storages](../repository_storage_paths.md),
repositories from specific repository storages can be restored separately
using the `REPOSITORIES_STORAGES` option. The option accepts a comma-separated list of
storage names.

For example:

- Linux package installations:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> REPOSITORIES_STORAGES=storage1,storage2
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> REPOSITORIES_STORAGES=storage1,storage2
  ```

### Restore specific repositories

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094) in GitLab 15.1.

WARNING:
GitLab 17.1 and earlier are [affected by a race condition](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158412) that can cause data loss. The problem affects
repositories that have been forked and use GitLab [object pools](../repository_storage_paths.md#hashed-object-pools). To avoid data loss, **only restore backups by using GitLab
17.2 or later**.

You can restore specific repositories using the `REPOSITORIES_PATHS` and the `SKIP_REPOSITORIES_PATHS` options.
Both options accept a comma-separated list of project and group paths. If you
specify a group path, all repositories in all projects in the group and
descendent groups are included or skipped, depending on which option you used.
Both the groups and projects must exist in the specified backup or on the target instance.

NOTE:
The `REPOSITORIES_PATHS` and `SKIP_REPOSITORIES_PATHS` options apply only to Git repositories.
They do not apply to project or group database entries. If you created a repositories backup
with `SKIP=db`, by itself it cannot be used to restore specific repositories to a new instance.

For example, to restore all repositories for all projects in **Group A** (`group-a`), the repository for **Project C** in **Group B** (`group-b/project-c`),
and skip the **Project D** in **Group A** (`group-a/project-d`):

- Linux package installations:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
  ```

### Restore untarred backups

If an [untarred backup](backup_gitlab.md#skipping-tar-creation) (made with `SKIP=tar`) is found,
and no backup is chosen with `BACKUP=<backup-id>`, the untarred backup is used.

For example:

- Linux package installations:

  ```shell
  sudo gitlab-backup restore
  ```

- Self-compiled installations:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore
  ```

## Troubleshooting

The following are possible problems you might encounter, along with potential
solutions.

### Restoring database backup using output warnings from a Linux package installation

If you're using backup restore procedures, you may encounter the following
warning messages:

```plaintext
ERROR: must be owner of extension pg_trgm
ERROR: must be owner of extension btree_gist
ERROR: must be owner of extension plpgsql
WARNING:  no privileges could be revoked for "public" (two occurrences)
WARNING:  no privileges were granted for "public" (two occurrences)
```

Be advised that the backup is successfully restored in spite of these warning
messages.

The Rake task runs this as the `gitlab` user, which doesn't have superuser
access to the database. When restore is initiated, it also runs as the `gitlab`
user, but it also tries to alter the objects it doesn't have access to.
Those objects have no influence on the database backup or restore, but display
a warning message.

For more information, see:

- PostgreSQL issue tracker:
  - [Not being a superuser](https://www.postgresql.org/message-id/201110220712.30886.adrian.klaver@gmail.com).
  - [Having different owners](https://www.postgresql.org/message-id/2039.1177339749@sss.pgh.pa.us).

- Stack Overflow: [Resulting errors](https://stackoverflow.com/questions/4368789/error-must-be-owner-of-language-plpgsql).

### Restoring fails due to Git server hook

While restoring from backup, you can encounter an error when the following are true:

- A Git Server Hook (`custom_hook`) is configured using the method for [GitLab version 15.10 and earlier](../server_hooks.md)
- Your GitLab version is on version 15.11 and later
- You created symlinks to a directory outside of the GitLab-managed locations

The error looks like:

```plaintext
{"level":"fatal","msg":"restore: pipeline: 1 failures encountered:\n - @hashed/path/to/hashed_repository.git (path/to_project): manager: restore custom hooks, \"@hashed/path/to/hashed_repository/<BackupID>_<GitLabVersion>-ee/001.custom_hooks.tar\": rpc error: code = Internal desc = setting custom hooks: generating prepared vote: walking directory: copying file to hash: read /mnt/gitlab-app/git-data/repositories/+gitaly/tmp/default-repositories.old.<timestamp>.<temporaryfolder>/custom_hooks/compliance-triggers.d: is a directory\n","pid":3256017,"time":"2023-08-10T20:09:44.395Z"}
```

To resolve this, you can update the Git [server hooks](../server_hooks.md) for GitLab version 15.11 and later, and create a new backup.

### Successful restore with repositories showing as empty when using `fapolicyd`

When using `fapolicyd` for increased security, GitLab can report that a restore was successful but repositories show as empty. For more troubleshooting help, see
[Gitaly Troubleshooting documentation](../gitaly/troubleshooting.md#repositories-are-shown-as-empty-after-a-gitlab-restore).
