---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Back up and restore GitLab **(FREE SELF)**

GitLab provides Rake tasks for backing up and restoring GitLab instances.

An application data backup creates an archive file that contains the database,
all repositories and all attachments.

You can only restore a backup to **exactly the same version and type (CE/EE)**
of GitLab on which it was created. The best way to
[migrate your projects from one server to another](#migrate-to-a-new-server) is through a backup and restore.

WARNING:
GitLab doesn't back up items that aren't stored on the file system. If you're
using [object storage](../administration/object_storage.md), be sure to enable
backups with your object storage provider, if desired.

## Requirements

To be able to back up and restore, ensure that Rsync is installed on your
system. If you installed GitLab:

- _Using the Omnibus package_, Rsync is already installed.
- _From source_, check if `rsync` is installed. If Rsync is not installed, install it. For example:

  ```shell
  # Debian/Ubuntu
  sudo apt-get install rsync

  # RHEL/CentOS
  sudo yum install rsync
  ```

### `gitaly-backup` for repository backup and restore

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333034) in GitLab 14.2.
> - [Deployed behind a feature flag](../user/feature_flags.md), enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/333034) in GitLab 14.10. [Feature flag `gitaly_backup`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83254) removed.

The `gitaly-backup` binary is used by the backup Rake task to create and restore repository backups from Gitaly.
`gitaly-backup` replaces the previous backup method that directly calls RPCs on Gitaly from GitLab.

The backup Rake task must be able to find this executable. In most cases, you don't need to change
the path to the binary as it should work fine with the default path `/opt/gitlab/embedded/bin/gitaly-backup`.
If you have a specific reason to change the path, it can be configured in Omnibus GitLab packages:

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_gitaly_backup_path'] = '/path/to/gitaly-backup'
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

## Backup timestamp

The backup archive is saved in `backup_path`, which is specified in the
`config/gitlab.yml` file. The filename is `[TIMESTAMP]_gitlab_backup.tar`,
where `TIMESTAMP` identifies the time at which each backup was created, plus
the GitLab version. The timestamp is needed if you need to restore GitLab and
multiple backups are available.

For example, if the backup name is `1493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar`,
the timestamp is `1493107454_2018_04_25_10.6.4-ce`.

## Back up GitLab

For detailed information on backing up GitLab, see [Backup GitLab](backup_gitlab.md).

## Restore GitLab

For detailed information on restoring GitLab, see [Restore GitLab](restore_gitlab.md).

## Alternative backup strategies

In the following cases, consider using file system data transfer or snapshots as part of your backup strategy:

- Your GitLab instance contains a lot of Git repository data and the GitLab backup script is too slow.
- Your GitLab instance has a lot of forked projects and the regular backup task duplicates the Git data for all of them.
- Your GitLab instance has a problem and using the regular backup and import Rake tasks isn't possible.

WARNING:
Gitaly Cluster [does not support snapshot backups](../administration/gitaly/index.md#snapshot-backup-and-recovery-limitations).

When considering using file system data transfer or snapshots:

- Don't use these methods to migrate from one operating system to another. The operating systems of the source and destination should be as similar as possible. For example,
  don't use these methods to migrate from Ubuntu to Fedora.
- Data consistency is very important. We recommend stopping GitLab with `sudo gitlab-ctl stop` before taking doing a file system transfer (with rsync, for example) or taking a
  snapshot.

Example: Amazon Elastic Block Store (EBS)

> A GitLab server using Omnibus GitLab hosted on Amazon AWS.
> An EBS drive containing an ext4 file system is mounted at `/var/opt/gitlab`.
> In this case you could make an application backup by taking an EBS snapshot.
> The backup includes all repositories, uploads and PostgreSQL data.

Example: Logical Volume Manager (LVM) snapshots + rsync

> A GitLab server using Omnibus GitLab, with an LVM logical volume mounted at `/var/opt/gitlab`.
> Replicating the `/var/opt/gitlab` directory using rsync would not be reliable because too many files would change while rsync is running.
> Instead of rsync-ing `/var/opt/gitlab`, we create a temporary LVM snapshot, which we mount as a read-only file system at `/mnt/gitlab_backup`.
> Now we can have a longer running rsync job which creates a consistent replica on the remote server.
> The replica includes all repositories, uploads and PostgreSQL data.

If you're running GitLab on a virtualized server, you can possibly also create
VM snapshots of the entire GitLab server. It's not uncommon however for a VM
snapshot to require you to power down the server, which limits this solution's
practical use.

### Back up repository data separately

First, ensure you back up existing GitLab data while [skipping repositories](backup_gitlab.md#excluding-specific-directories-from-the-backup):

```shell
# for Omnibus GitLab package installations
sudo gitlab-backup create SKIP=repositories

# for installations from source:
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=repositories RAILS_ENV=production
```

For manually backing up the Git repository data on disk, there are multiple possible strategies:

- Use snapshots, such as the previous examples of Amazon EBS drive snapshots, or LVM snapshots + rsync.
- Use [GitLab Geo](../administration/geo/index.md) and rely on the repository data on a Geo secondary site.
- [Prevent writes and copy the Git repository data](#prevent-writes-and-copy-the-git-repository-data).
- [Create an online backup by marking repositories as read-only (experimental)](#online-backup-through-marking-repositories-as-read-only-experimental).

#### Prevent writes and copy the Git repository data

Git repositories must be copied in a consistent way. They should not be copied during concurrent write
operations, as this can lead to inconsistencies or corruption issues. For more details,
[issue #270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422 "Provide documentation on preferred method of migrating Gitaly servers")
has a longer discussion explaining the potential problems.

To prevent writes to the Git repository data, there are two possible approaches:

- Use [maintenance mode](../administration/maintenance_mode/index.md) to place GitLab in a read-only state.
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

1. Use a [`tar` pipe to copy the entire repository's directory to another server or location](../administration/operations/moving_repositories.md#tar-pipe-to-another-server).

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

## Back up and restore for installations using PgBouncer

Do not back up or restore GitLab through a PgBouncer connection. These
tasks must [bypass PgBouncer and connect directly to the PostgreSQL primary database node](#bypassing-pgbouncer),
or they cause a GitLab outage.

When the GitLab backup or restore task is used with PgBouncer, the
following error message is shown:

```ruby
ActiveRecord::StatementInvalid: PG::UndefinedTable
```

Each time the GitLab backup runs, GitLab starts generating 500 errors and errors about missing
tables will [be logged by PostgreSQL](../administration/logs/index.md#postgresql-logs):

```plaintext
ERROR: relation "tablename" does not exist at character 123
```

This happens because the task uses `pg_dump`, which
[sets a null search path and explicitly includes the schema in every SQL query](https://gitlab.com/gitlab-org/gitlab/-/issues/23211)
to address [CVE-2018-1058](https://www.postgresql.org/about/news/postgresql-103-968-9512-9417-and-9322-released-1834/).

Since connections are reused with PgBouncer in transaction pooling mode,
PostgreSQL fails to search the default `public` schema. As a result,
this clearing of the search path causes tables and columns to appear
missing.

### Bypassing PgBouncer

There are two ways to fix this:

1. [Use environment variables to override the database settings](#environment-variable-overrides) for the backup task.
1. Reconfigure a node to [connect directly to the PostgreSQL primary database node](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer).

#### Environment variable overrides

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
and port 5432 with the Omnibus package:

```shell
sudo GITLAB_BACKUP_PGHOST=192.168.1.10 GITLAB_BACKUP_PGPORT=5432 /opt/gitlab/bin/gitlab-backup create
```

See the [PostgreSQL documentation](https://www.postgresql.org/docs/12/libpq-envars.html)
for more details on what these parameters do.

## Migrate to a new server

<!-- some details borrowed from GitLab.com move from Azure to GCP detailed at https://gitlab.com/gitlab-com/migration/-/blob/master/.gitlab/issue_templates/failover.md -->

You can use GitLab backup and restore to migrate your instance to a new server. This section outlines a typical procedure for a GitLab deployment running on a single server.
If you're running GitLab Geo, an alternative option is [Geo disaster recovery for planned failover](../administration/geo/disaster_recovery/planned_failover.md).

WARNING:
Avoid uncoordinated data processing by both the new and old servers, where multiple
servers could connect concurrently and process the same data. For example, when using
[incoming email](../administration/incoming_email.md), if both GitLab instances are
processing email at the same time, then both instances miss some data.
This type of problem can occur with other services as well, such as a
[non-packaged database](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server),
a non-packaged Redis instance, or non-packaged Sidekiq.

Prerequisites:

- Some time before your migration, consider notifying your users of upcoming
  scheduled maintenance with a [broadcast message banner](../user/admin_area/broadcast_messages.md).
- Ensure your backups are complete and current. Create a complete system-level backup, or
  take a snapshot of all servers involved in the migration, in case destructive commands
  (like `rm`) are run incorrectly.

### Prepare the new server

To prepare the new server:

1. Copy the
   [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)
   from the old server to avoid man-in-the-middle attack warnings.
   See [Manually replicate the primary site's SSH host keys](../administration/geo/replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys) for example steps.
1. [Install and configure GitLab](https://about.gitlab.com/install/) except
   [incoming email](../administration/incoming_email.md):
   1. Install GitLab.
   1. Configure by copying `/etc/gitlab` files from the old server to the new server, and update as necessary.
      Read the
      [Omnibus configuration backup and restore instructions](https://docs.gitlab.com/omnibus/settings/backups.html) for more detail.
   1. If applicable, disable [incoming email](../administration/incoming_email.md).
   1. Block new CI/CD jobs from starting upon initial startup after the backup and restore.
      Edit `/etc/gitlab/gitlab.rb` and set the following:

      ```ruby
      nginx['custom_gitlab_server_config'] = "location /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
      ```

   1. Reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Stop GitLab to avoid any potential unnecessary and unintentional data processing:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Configure the new server to allow receiving the Redis database and GitLab backup files:

   ```shell
   sudo rm -f /var/opt/gitlab/redis/dump.rdb
   sudo chown <your-linux-username> /var/opt/gitlab/redis /var/opt/gitlab/backups
   ```

### Prepare and transfer content from the old server

1. Ensure you have an up-to-date system-level backup or snapshot of the old server.
1. Enable [maintenance mode](../administration/maintenance_mode/index.md),
   if supported by your GitLab edition.
1. Block new CI/CD jobs from starting:
   1. Edit `/etc/gitlab/gitlab.rb`, and set the following:

      ```ruby
      nginx['custom_gitlab_server_config'] = "location /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
      ```

   1. Reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Disable periodic background jobs:
   1. On the top bar, select **Main menu > Admin**.
   1. On the left sidebar, select **Monitoring > Background Jobs**.
   1. Under the Sidekiq dashboard, select **Cron** tab and then
      **Disable All**.
1. Wait for the currently running CI/CD jobs to finish, or accept that jobs that have not completed may be lost.
   To view jobs currently running, on the left sidebar, select **Overviews > Jobs**,
   and then select **Running**.
1. Wait for Sidekiq jobs to finish:
   1. On the left sidebar, select **Monitoring > Background Jobs**.
   1. Under the Sidekiq dashboard, select **Queues** and then **Live Poll**.
      Wait for **Busy** and **Enqueued** to drop to 0.
      These queues contain work that has been submitted by your users;
      shutting down before these jobs complete may cause the work to be lost.
      Make note of the numbers shown in the Sidekiq dashboard for post-migration verification.
1. Flush the Redis database to disk, and stop GitLab other than the services needed for migration:

   ```shell
   sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket save && sudo gitlab-ctl stop && sudo gitlab-ctl start postgresql && sudo gitlab-ctl start gitaly
   ```

1. Create a GitLab backup:

   ```shell
   sudo gitlab-backup create
   ```

1. Disable the following GitLab services and prevent unintentional restarts by adding the following to the bottom of `/etc/gitlab/gitlab.rb`:

   ```ruby
   alertmanager['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_pages['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false
   logrotate['enable'] = false
   gitlab_rails['incoming_email_enabled'] = false
   nginx['enable'] = false
   node_exporter['enable'] = false
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   prometheus['enable'] = false
   puma['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   registry['enable'] = false
   sidekiq['enable'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Verify everything is stopped, and confirm no services are running:

   ```shell
   sudo gitlab-ctl status
   ```

1. Transfer the Redis database and GitLab backups to the new server:

   ```shell
   sudo scp /var/opt/gitlab/redis/dump.rdb <your-linux-username>@new-server:/var/opt/gitlab/redis
   sudo scp /var/opt/gitlab/backups/your-backup.tar <your-linux-username>@new-server:/var/opt/gitlab/backups
   ```

### Restore data on the new server

1. Restore appropriate file system permissions:

   ```shell
   sudo chown gitlab-redis /var/opt/gitlab/redis
   sudo chown gitlab-redis:gitlab-redis /var/opt/gitlab/redis/dump.rdb
   sudo chown git:root /var/opt/gitlab/backups
   sudo chown git:git /var/opt/gitlab/backups/your-backup.tar
   ```

1. [Restore the GitLab backup](#restore-gitlab).
1. Verify that the Redis database restored correctly:
   1. On the top bar, select **Main menu > Admin**.
   1. On the left sidebar, select **Monitoring > Background Jobs**.
   1. Under the Sidekiq dashboard, verify that the numbers
      match with what was shown on the old server.
   1. While still under the Sidekiq dashboard, select **Cron** and then **Enable All**
      to re-enable periodic background jobs.
1. Test that read-only operations on the GitLab instance work as expected. For example, browse through project repository files, merge requests, and issues.
1. Disable [Maintenance Mode](../administration/maintenance_mode/index.md), if previously enabled.
1. Test that the GitLab instance is working as expected.
1. If applicable, re-enable [incoming email](../administration/incoming_email.md) and test it is working as expected.
1. Update your DNS or load balancer to point at the new server.
1. Unblock new CI/CD jobs from starting by removing the custom NGINX configuration
   you added previously:

   ```ruby
   # The following line must be removed
   nginx['custom_gitlab_server_config'] = "location /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Remove the scheduled maintenance [broadcast message banner](../user/admin_area/broadcast_messages.md).

## Additional notes

This documentation is for GitLab Community and Enterprise Edition. We back up
GitLab.com and ensure your data is secure. You can't, however, use these
methods to export or back up your data yourself from GitLab.com.

Issues are stored in the database, and can't be stored in Git itself.

To migrate your repositories from one server to another with an up-to-date
version of GitLab, use the [import Rake task](import.md) to do a mass import of
the repository. If you do an import Rake task rather than a backup restore,
you get all of your repositories, but no other data.

## Troubleshooting

The following are possible problems you might encounter, along with potential
solutions.

### Restoring database backup using Omnibus packages outputs warnings

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

### When the secrets file is lost

If you didn't [back up the secrets file](backup_gitlab.md#storing-configuration-files), you
must complete several steps to get GitLab working properly again.

The secrets file is responsible for storing the encryption key for the columns
that contain required, sensitive information. If the key is lost, GitLab can't
decrypt those columns, preventing access to the following items:

- [CI/CD variables](../ci/variables/index.md)
- [Kubernetes / GCP integration](../user/infrastructure/clusters/index.md)
- [Custom Pages domains](../user/project/pages/custom_domains_ssl_tls_certification/index.md)
- [Project error tracking](../operations/error_tracking.md)
- [Runner authentication](../ci/runners/index.md)
- [Project mirroring](../user/project/repository/mirror/index.md)
- [Integrations](../user/project/integrations/index.md)
- [Web hooks](../user/project/integrations/webhooks.md)

In cases like CI/CD variables and runner authentication, you can experience
unexpected behaviors, such as:

- Stuck jobs.
- 500 errors.

In this case, you must reset all the tokens for CI/CD variables and
runner authentication, which is described in more detail in the following
sections. After resetting the tokens, you should be able to visit your project
and the jobs begin running again.

Use the information in the following sections at your own risk.

#### Verify that all values can be decrypted

You can determine if your database contains values that can't be decrypted by using a
[Rake task](../administration/raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

#### Take a backup

You must directly modify GitLab data to work around your lost secrets file.

WARNING:
Be sure to create a full database backup before attempting any changes.

#### Disable user two-factor authentication (2FA)

Users with 2FA enabled can't sign in to GitLab. In that case, you must
[disable 2FA for everyone](../security/two_factor_authentication.md#for-all-users),
after which users must reactivate 2FA.

#### Reset CI/CD variables

1. Enter the database console:

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Examine the `ci_group_variables` and `ci_variables` tables:

   ```sql
   SELECT * FROM public."ci_group_variables";
   SELECT * FROM public."ci_variables";
   ```

   These are the variables that you need to delete.

1. Drop the table:

   ```sql
   DELETE FROM ci_group_variables;
   DELETE FROM ci_variables;
   ```

1. If you know the specific group or project from which you wish to delete variables, you can include a `WHERE` statement to specify that in your `DELETE`:

   ```sql
   DELETE FROM ci_group_variables WHERE group_id = <GROUPID>;
   DELETE FROM ci_variables WHERE project_id = <PROJECTID>;
   ```

You may need to reconfigure or restart GitLab for the changes to take effect.

#### Reset runner registration tokens

1. Enter the database console:

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Clear all tokens for projects, groups, and the entire instance:

   WARNING:
   The final `UPDATE` operation stops the runners from being able to pick
   up new jobs. You must register new runners.

   ```sql
   -- Clear project tokens
   UPDATE projects SET runners_token = null, runners_token_encrypted = null;
   -- Clear group tokens
   UPDATE namespaces SET runners_token = null, runners_token_encrypted = null;
   -- Clear instance tokens
   UPDATE application_settings SET runners_registration_token_encrypted = null;
   -- Clear key used for JWT authentication
   -- This may break the $CI_JWT_TOKEN job variable:
   -- https://gitlab.com/gitlab-org/gitlab/-/issues/325965
   UPDATE application_settings SET encrypted_ci_jwt_signing_key = null;
   -- Clear runner tokens
   UPDATE ci_runners SET token = null, token_encrypted = null;
   ```

#### Reset pending pipeline jobs

1. Enter the database console:

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Clear all the tokens for pending jobs:

   For GitLab 15.3 and earlier:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token = null, token_encrypted = null;
   ```

   For GitLab 15.4 and later:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token_encrypted = null;
   ```

A similar strategy can be employed for the remaining features. By removing the
data that can't be decrypted, GitLab can be returned to operation, and the
lost data can be manually replaced.

#### Fix integrations and webhooks

If you've lost your secrets, the [integrations settings pages](../user/project/integrations/index.md)
and [webhooks settings pages](../user/project/integrations/webhooks.md) are probably displaying `500` error messages.

The fix is to truncate the affected tables (those containing encrypted columns).
This deletes all your configured integrations, webhooks, and related metadata.
You should verify that the secrets are the root cause before deleting any data.

1. Enter the database console:

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Truncate the following tables:

   ```sql
   -- truncate web_hooks table
   TRUNCATE integrations, chat_names, issue_tracker_data, jira_tracker_data, slack_integrations, web_hooks, zentao_tracker_data, web_hook_logs;
   ```

### Container Registry push failures after restoring from a backup

If you use the [Container Registry](../user/packages/container_registry/index.md),
pushes to the registry may fail after restoring your backup on an Omnibus GitLab
instance after restoring the registry data.

These failures mention permission issues in the registry logs, similar to:

```plaintext
level=error
msg="response completed with error"
err.code=unknown
err.detail="filesystem: mkdir /var/opt/gitlab/gitlab-rails/shared/registry/docker/registry/v2/repositories/...: permission denied"
err.message="unknown error"
```

This issue is caused by the restore running as the unprivileged user `git`,
which is unable to assign the correct ownership to the registry files during
the restore process ([issue #62759](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62759 "Incorrect permissions on registry filesystem after restore")).

To get your registry working again:

```shell
sudo chown -R registry:registry /var/opt/gitlab/gitlab-rails/shared/registry/docker
```

If you changed the default file system location for the registry, run `chown`
against your custom location, instead of `/var/opt/gitlab/gitlab-rails/shared/registry/docker`.

### Backup fails to complete with Gzip error

When running the backup, you may receive a Gzip error message:

```shell
sudo /opt/gitlab/bin/gitlab-backup create
...
Dumping ...
...
gzip: stdout: Input/output error

Backup failed
```

If this happens, examine the following:

- Confirm there is sufficient disk space for the Gzip operation. It's not uncommon for backups that
  use the [default strategy](backup_gitlab.md#backup-strategy-option) to require half the instance size
  in free disk space during backup creation.
- If NFS is being used, check if the mount option `timeout` is set. The
  default is `600`, and changing this to smaller values results in this error.

### Backup fails with `File name too long` error

During backup, you can get the `File name too long` error ([issue #354984](https://gitlab.com/gitlab-org/gitlab/-/issues/354984)). For example:

```plaintext
Problem: <class 'OSError: [Errno 36] File name too long:
```

This problem stops the backup script from completing. To fix this problem, you must truncate the filenames causing the problem. A maximum of 246 characters, including the file extension, is permitted.

WARNING:
The steps in this section can potentially lead to **data loss**. All steps must be followed strictly in the order given.

Truncating filenames to resolve the error involves:

- Cleaning up remote uploaded files that aren't tracked in the database.
- Truncating the filenames in the database.
- Rerunning the backup task.

#### Clean up remote uploaded files

A [known issue](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45425) caused object store uploads to remain after a parent resource was deleted. This issue was [resolved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18698).

To fix these files, you must clean up all remote uploaded files that are in the storage but not tracked in the `uploads` database table.

1. List all the object store upload files that can be moved to a lost and found directory if they don't exist in the GitLab database:

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
   ```

1. If you are sure you want to delete these files and remove all non-referenced uploaded files, run:

   WARNING:
   The following action is **irreversible**.

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production DRY_RUN=false
   ```

#### Truncate the filenames referenced by the database

You must truncate the files referenced by the database that are causing the problem. The filenames referenced by the database are stored:

- In the `uploads` table.
- In the references found. Any reference found from other database tables and columns.
- On the file system.

Truncate the filenames in the `uploads` table:

1. Enter the database console:

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

1. Search the `uploads` table for filenames longer than 246 characters:

   The following query selects the `uploads` records with filenames longer than 246 characters in batches of 0 to 10000. This improves the performance on large GitLab instances with tables having thousand of records.

      ```sql
      CREATE TEMP TABLE uploads_with_long_filenames AS
      SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, id, path
      FROM uploads AS u
      WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

      CREATE INDEX ON uploads_with_long_filenames(row_id);

      SELECT
         u.id,
         u.path,
         -- Current filename
         (regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] AS current_filename,
         -- New filename
         CONCAT(
            LEFT(SPLIT_PART((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
            COALESCE(SUBSTRING((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
         ) AS new_filename,
         -- New path
         CONCAT(
            COALESCE((regexp_match(u.path, '(.*\/).*'))[1], ''),
            CONCAT(
               LEFT(SPLIT_PART((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
               COALESCE(SUBSTRING((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
            )
         ) AS new_path
      FROM uploads_with_long_filenames AS u
      WHERE u.row_id > 0 AND u.row_id <= 10000;
      ```

      Output example:

      ```postgresql
      -[ RECORD 1 ]----+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      id               | 34
      path             | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
      current_filename | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
      new_filename     | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
      new_path         | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
      ```

      Where:

      - `current_filename`: a filename that is currently more than 246 characters long.
      - `new_filename`: a filename that has been truncated to 246 characters maximum.
      - `new_path`: new path considering the `new_filename` (truncated).

   Once you validate the batch results, you must change the batch size (`row_id`) using the following sequence of numbers (10000 to 20000). Repeat this process until you reach the last record in the `uploads` table.

1. Rename the files found in the `uploads` table from long filenames to new truncated filenames. The following query rolls back the update so you can check the results safely within a transaction wrapper:

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, path, id
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   BEGIN;
   WITH updated_uploads AS (
      UPDATE uploads
      SET
         path =
         CONCAT(
            COALESCE((regexp_match(updatable_uploads.path, '(.*\/).*'))[1], ''),
            CONCAT(
               LEFT(SPLIT_PART((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
               COALESCE(SUBSTRING((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
            )
         )
      FROM
         uploads_with_long_filenames AS updatable_uploads
      WHERE
         uploads.id = updatable_uploads.id
      AND updatable_uploads.row_id > 0 AND updatable_uploads.row_id  <= 10000
      RETURNING uploads.*
   )
   SELECT id, path FROM updated_uploads;
   ROLLBACK;
   ```

   Once you validate the batch update results, you must change the batch size (`row_id`) using the following sequence of numbers (10000 to 20000). Repeat this process until you reach the last record in the `uploads` table.

1. Validate that the new filenames from the previous query are the expected ones. If you are sure you want to truncate the records found in the previous step to 246 characters, run the following:

   WARNING:
   The following action is **irreversible**.

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, path, id
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   UPDATE uploads
   SET
   path =
      CONCAT(
         COALESCE((regexp_match(updatable_uploads.path, '(.*\/).*'))[1], ''),
         CONCAT(
            LEFT(SPLIT_PART((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
            COALESCE(SUBSTRING((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
         )
      )
   FROM
   uploads_with_long_filenames AS updatable_uploads
   WHERE
   uploads.id = updatable_uploads.id
   AND updatable_uploads.row_id > 0 AND updatable_uploads.row_id  <= 10000;
   ```

   Once you finish the batch update, you must change the batch size (`updatable_uploads.row_id`) using the following sequence of numbers (10000 to 20000). Repeat this process until you reach the last record in the `uploads` table.

Truncate the filenames in the references found:

1. Check if those records are referenced somewhere. One way to do this is to dump the database and search for the parent directory name and filename:

   1. To dump your database, you can use the following command as an example:

      ```shell
      pg_dump -h /var/opt/gitlab/postgresql/ -d gitlabhq_production > gitlab-dump.tmp
      ```

   1. Then you can search for the references using the `grep` command. Combining the parent directory and the filename can be a good idea. For example:

      ```shell
      grep public/alongfilenamehere.txt gitlab-dump.tmp
      ```

1. Replace those long filenames using the new filenames obtained from querying the `uploads` table.

Truncate the filenames on the file system. You must manually rename the files in your file system to the new filenames obtained from querying the `uploads` table.

#### Re-run the backup task

After following all the previous steps, re-run the backup task.

### Restoring database backup fails when `pg_stat_statements` was previously enabled

The GitLab backup of the PostgreSQL database includes all SQL statements required to enable extensions that were
previously enabled in the database.

The `pg_stat_statements` extension can only be enabled or disabled by a PostgreSQL user with `superuser` role.
As the restore process uses a database user with limited permissions, it can't execute the following SQL statements:

```sql
DROP EXTENSION IF EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
```

When trying to restore the backup in a PostgreSQL instance that doesn't have the `pg_stats_statements` extension,
the following error message is displayed:

```plaintext
ERROR: permission denied to create extension "pg_stat_statements"
HINT: Must be superuser to create this extension.
ERROR: extension "pg_stat_statements" does not exist
```

When trying to restore in an instance that has the `pg_stats_statements` extension enabled, the cleaning up step
fails with an error message similar to the following:

```plaintext
rake aborted!
ActiveRecord::StatementInvalid: PG::InsufficientPrivilege: ERROR: must be owner of view pg_stat_statements
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:42:in `block (4 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `each'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/backup.rake:71:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Caused by:
PG::InsufficientPrivilege: ERROR: must be owner of view pg_stat_statements
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:42:in `block (4 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `each'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/backup.rake:71:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => gitlab:db:drop_tables
(See full trace by running task with --trace)
```

#### Prevent the dump file to include `pg_stat_statements`

To prevent the inclusion of the extension in the PostgreSQL dump file that is part of the backup bundle,
enable the extension in any schema except the `public` schema:

```sql
CREATE SCHEMA adm;
CREATE EXTENSION pg_stat_statements SCHEMA adm;
```

If the extension was previously enabled in the `public` schema, move it to a new one:

```sql
CREATE SCHEMA adm;
ALTER EXTENSION pg_stat_statements SET SCHEMA adm;
```

To query the `pg_stat_statements` data after changing the schema, prefix the view name with the new schema:

```sql
SELECT * FROM adm.pg_stat_statements limit 0;
```

To make it compatible with third-party monitoring solutions that expect it to be enabled in the `public` schema,
you need to include it in the `search_path`:

```sql
set search_path to public,adm;
```

#### Fix an existing dump file to remove references to `pg_stat_statements`

To fix an existing backup file, do the following changes:

1. Extract from the backup the following file: `db/database.sql.gz`.
1. Decompress the file or use an editor that is capable of handling it compressed.
1. Remove the following lines, or similar ones:

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
   ```

   ```sql
   COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';
   ```

1. Save the changes and recompress the file.
1. Update the backup file with the modified `db/database.sql.gz`.
