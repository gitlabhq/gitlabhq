---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate to a new server
---

<!-- some details borrowed from GitLab.com move from Azure to GCP detailed at https://gitlab.com/gitlab-com/migration/-/blob/master/.gitlab/issue_templates/failover.md -->

You can use GitLab backup and restore to migrate your instance to a new server. This section outlines a typical procedure for a GitLab deployment running on a single server.
If you're running GitLab Geo, an alternative option is [Geo disaster recovery for planned failover](../geo/disaster_recovery/planned_failover.md). You must make sure all sites meet the [Geo requirements](../geo/_index.md#requirements-for-running-geo) before selecting Geo for the migration.

WARNING:
Avoid uncoordinated data processing by both the new and old servers, where multiple
servers could connect concurrently and process the same data. For example, when using
[incoming email](../incoming_email.md), if both GitLab instances are
processing email at the same time, then both instances miss some data.
This type of problem can occur with other services as well, such as a
[non-packaged database](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server),
a non-packaged Redis instance, or non-packaged Sidekiq.

Prerequisites:

- Some time before your migration, consider notifying your users of upcoming
  scheduled maintenance with a [broadcast message banner](../broadcast_messages.md).
- Ensure your backups are complete and current. Create a complete system-level backup, or
  take a snapshot of all servers involved in the migration, in case destructive commands
  (like `rm`) are run incorrectly.

## Prepare the new server

To prepare the new server:

1. Copy the
   [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)
   from the old server to avoid man-in-the-middle attack warnings.
   See [Manually replicate the primary site's SSH host keys](../geo/replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys) for example steps.
1. [Install and configure GitLab](https://about.gitlab.com/install/) except
   [incoming email](../incoming_email.md):
   1. Install GitLab.
   1. Configure by copying `/etc/gitlab` files from the old server to the new server, and update as necessary.
      Read the
      [Linux package installation backup and restore instructions](https://docs.gitlab.com/omnibus/settings/backups.html) for more detail.
   1. If applicable, disable [incoming email](../incoming_email.md).
   1. Block new CI/CD jobs from starting upon initial startup after the backup and restore.
      Edit `/etc/gitlab/gitlab.rb` and set the following:

      ```ruby
      nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
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

## Prepare and transfer content from the old server

1. Ensure you have an up-to-date system-level backup or snapshot of the old server.
1. Enable [maintenance mode](../maintenance_mode/_index.md),
   if supported by your GitLab edition.
1. Block new CI/CD jobs from starting:
   1. Edit `/etc/gitlab/gitlab.rb`, and set the following:

      ```ruby
      nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
      ```

   1. Reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Disable periodic background jobs:
   1. On the left sidebar, at the bottom, select **Admin**.
   1. On the left sidebar, select **Monitoring > Background jobs**.
   1. Under the Sidekiq dashboard, select **Cron** tab and then
      **Disable All**.
1. Wait for the running CI/CD jobs to finish, or accept that jobs that have not completed may be lost.
   To view jobs running, on the left sidebar, select **Overviews > Jobs**,
   and then select **Running**.
1. Wait for Sidekiq jobs to finish:
   1. On the left sidebar, select **Monitoring > Background jobs**.
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

1. Stop Redis on the **new server** before transferring the Redis database backup:

   ```shell
   sudo gitlab-ctl stop redis
   ```

1. Transfer the Redis database and GitLab backups to the new server:

   ```shell
   sudo scp /var/opt/gitlab/redis/dump.rdb <your-linux-username>@new-server:/var/opt/gitlab/redis
   sudo scp /var/opt/gitlab/backups/your-backup.tar <your-linux-username>@new-server:/var/opt/gitlab/backups
   ```

### For instances with a large volume of Git and object data

If your GitLab instance has a large amount of data on local volumes, for example greater than 1 TB,
backups may take a long time. In that case, you may find it easier to transfer the data to the appropriate volumes on the new instance.

The main volumes that you might need to migrate manually are:

- The `/var/opt/gitlab/git-data` directory which contains all the Git data.
  Be sure to read [the moving repositories documentation section](../operations/moving_repositories.md#migrating-to-another-gitlab-instance) to eliminate the chance of Git data corruption.
- The `/var/opt/gitlab/gitlab-rails/shared` directory which contains object data, like artifacts.
- If you are using the bundled PostgreSQL included with the Linux package,
  you also need to migrate the [PostgreSQL data directory](https://docs.gitlab.com/omnibus/settings/database.html#store-postgresql-data-in-a-different-directory)
  under `/var/opt/gitlab/postgresql/data`.

After all GitLab services have been stopped, you can use tools like `rsync` or mounting volume snapshots to move the data
to the new environment.

## Restore data on the new server

1. Restore appropriate file system permissions:

   ```shell
   sudo chown gitlab-redis /var/opt/gitlab/redis
   sudo chown gitlab-redis:gitlab-redis /var/opt/gitlab/redis/dump.rdb
   sudo chown git:root /var/opt/gitlab/backups
   sudo chown git:git /var/opt/gitlab/backups/your-backup.tar
   ```

1. Start Redis:

   ```shell
   sudo gitlab-ctl start redis
   ```

   Redis picks up and restores `dump.rdb` automatically.

1. [Restore the GitLab backup](restore_gitlab.md).
1. Verify that the Redis database restored correctly:
   1. On the left sidebar, at the bottom, select **Admin**.
   1. On the left sidebar, select **Monitoring > Background jobs**.
   1. Under the Sidekiq dashboard, verify that the numbers
      match with what was shown on the old server.
   1. While still under the Sidekiq dashboard, select **Cron** and then **Enable All**
      to re-enable periodic background jobs.
1. Test that read-only operations on the GitLab instance work as expected. For example, browse through project repository files, merge requests, and issues.
1. Disable [Maintenance Mode](../maintenance_mode/_index.md), if previously enabled.
1. Test that the GitLab instance is working as expected.
1. If applicable, re-enable [incoming email](../incoming_email.md) and test it is working as expected.
1. Update your DNS or load balancer to point at the new server.
1. Unblock new CI/CD jobs from starting by removing the custom NGINX configuration
   you added previously:

   ```ruby
   # The following line must be removed
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Remove the scheduled maintenance [broadcast message banner](../broadcast_messages.md).
