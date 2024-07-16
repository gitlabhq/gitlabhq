---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Geo replication

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

## Fixing PostgreSQL database replication errors

The following sections outline troubleshooting steps for fixing replication error messages (indicated by `Database replication working? ... no` in the
[`geo:check` output](common.md#health-check-rake-task).
The instructions present here mostly assume a single-node Geo Linux package deployment, and might need to be adapted to different environments.

### Removing an inactive replication slot

Replication slots are marked as 'inactive' when the replication client (a secondary site) connected to the slot disconnects.
Inactive replication slots cause WAL files to be retained, because they are sent to the client when it reconnects and the slot becomes active once more.
If the secondary site is not able to reconnect, use the following steps to remove its corresponding inactive replication slot:

1. [Start a PostgreSQL console session](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-postgresql-database) on the Geo primary site's database node:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

   NOTE:
   Using `gitlab-rails dbconsole` does not work, because managing replication slots requires superuser permissions.

1. View the replication slots and remove them if they are inactive:

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

   Slots where `active` is `f` are inactive.

   - When this slot should be active, because you have a **secondary** site configured using that slot,
     look for the [PostgreSQL logs](../../../logs/index.md#postgresql-logs) for the **secondary** site,
     to view why the replication is not running.
   - If you are no longer using the slot (for example, you no longer have Geo enabled), or the secondary site is no longer able to reconnect,
     you should remove it using the PostgreSQL console session:

     ```sql
     SELECT pg_drop_replication_slot('<name_of_inactive_slot>');
     ```

1. Follow either the steps [to remove that Geo site](../remove_geo_site.md) if it's no longer required,
   or [re-initiate the replication process](../../setup/database.md#step-3-initiate-the-replication-process), which recreates the replication slot correctly.

### Message: `WARNING: oldest xmin is far in the past` and `pg_wal` size growing

If a replication slot is inactive,
the `pg_wal` logs corresponding to the slot are reserved forever
(or until the slot is active again). This causes continuous disk usage growth
and the following messages appear repeatedly in the
[PostgreSQL logs](../../../logs/index.md#postgresql-logs):

```plaintext
WARNING: oldest xmin is far in the past
HINT: Close open transactions soon to avoid wraparound problems.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
```

To fix this, you should [remove the inactive replication slot](#removing-an-inactive-replication-slot) and re-initiate the replication.

### Message: `ERROR:  replication slots can only be used if max_replication_slots > 0`?

This means that the `max_replication_slots` PostgreSQL variable needs to
be set on the **primary** database. This setting defaults to 1. You may need to
increase this value if you have more **secondary** sites.

Be sure to restart PostgreSQL for this to take effect. See the
[PostgreSQL replication setup](../../setup/database.md#postgresql-replication) guide for more details.

### Message: `replication slot "geo_secondary_my_domain_com" does not exist`

This error occurs when PostgreSQL does not have a replication slot for the
**secondary** site by that name:

```plaintext
FATAL:  could not start WAL streaming: ERROR:  replication slot "geo_secondary_my_domain_com" does not exist
```

You may want to rerun the [replication process](../../setup/database.md) on the **secondary** site .

### Message: "Command exceeded allowed execution time" when setting up replication?

This may happen while [initiating the replication process](../../setup/database.md#step-3-initiate-the-replication-process) on the **secondary** site,
and indicates your initial dataset is too large to be replicated in the default timeout (30 minutes).

Re-run `gitlab-ctl replicate-geo-database`, but include a larger value for
`--backup-timeout`:

```shell
sudo gitlab-ctl \
   replicate-geo-database \
   --host=<primary_node_hostname> \
   --slot-name=<secondary_slot_name> \
   --backup-timeout=21600
```

This gives the initial replication up to six hours to complete, rather than
the default 30 minutes. Adjust as required for your installation.

### Message: "PANIC: could not write to file `pg_xlog/xlogtemp.123`: No space left on device"

Determine if you have any unused replication slots in the **primary** database. This can cause large amounts of
log data to build up in `pg_xlog`.

[Removing the inactive slots](#removing-an-inactive-replication-slot) can reduce the amount of space used in the `pg_xlog`.

### Message: "ERROR: canceling statement due to conflict with recovery"

This error message occurs infrequently under typical usage, and the system is resilient
enough to recover.

However, under certain conditions, some database queries on secondaries may run
excessively long, which increases the frequency of this error message. This can lead to a situation
where some queries never complete due to being canceled on every replication.

These long-running queries are
[planned to be removed in the future](https://gitlab.com/gitlab-org/gitlab/-/issues/34269),
but as a workaround, we recommend enabling
[`hot_standby_feedback`](https://www.postgresql.org/docs/10/hot-standby.html#HOT-STANDBY-CONFLICT).
This increases the likelihood of bloat on the **primary** site as it prevents
`VACUUM` from removing recently-dead rows. However, it has been used
successfully in production on GitLab.com.

To enable `hot_standby_feedback`, add the following to `/etc/gitlab/gitlab.rb`
on the **secondary** site:

```ruby
postgresql['hot_standby_feedback'] = 'on'
```

Then reconfigure GitLab:

```shell
sudo gitlab-ctl reconfigure
```

To help us resolve this problem, consider commenting on
[the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/4489).

### Message: `server certificate for "PostgreSQL" does not match host name`

If you see this error:

```plaintext
FATAL:  could not connect to the primary server: server certificate for "PostgreSQL" does not match host name
```

This happens because the PostgreSQL certificate that the Linux package automatically creates contains
the Common Name `PostgreSQL`, but the replication is connecting to a different host and GitLab attempts to use
the `verify-full` SSL mode by default.

To fix this issue, you can either:

- Use the `--sslmode=verify-ca` argument with the `replicate-geo-database` command.
- For an already replicated database, change `sslmode=verify-full` to `sslmode=verify-ca`
  in `/var/opt/gitlab/postgresql/data/gitlab-geo.conf` and run `gitlab-ctl restart postgresql`.
- [Configure SSL for PostgreSQL](https://docs.gitlab.com/omnibus/settings/database.html#configuring-ssl)
  with a custom certificate (including the host name that's used to connect to the database in the CN or SAN)
  instead of using the automatically generated certificate.

### Message: `LOG:  invalid CIDR mask in address`

This happens on wrongly-formatted addresses in `postgresql['md5_auth_cidr_addresses']`.

```plaintext
2020-03-20_23:59:57.60499 LOG:  invalid CIDR mask in address "***"
2020-03-20_23:59:57.60501 CONTEXT:  line 74 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

To fix this, update the IP addresses in `/etc/gitlab/gitlab.rb` under `postgresql['md5_auth_cidr_addresses']`
to respect the CIDR format (for example, `10.0.0.1/32`).

### Message: `LOG:  invalid IP mask "md5": Name or service not known`

This happens when you have added IP addresses without a subnet mask in `postgresql['md5_auth_cidr_addresses']`.

```plaintext
2020-03-21_00:23:01.97353 LOG:  invalid IP mask "md5": Name or service not known
2020-03-21_00:23:01.97354 CONTEXT:  line 75 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

To fix this, add the subnet mask in `/etc/gitlab/gitlab.rb` under `postgresql['md5_auth_cidr_addresses']`
to respect the CIDR format (for example, `10.0.0.1/32`).

### Message: `Found data in the gitlabhq_production database`

If you receive the error `Found data in the gitlabhq_production database!` when running
`gitlab-ctl replicate-geo-database`, data was detected in the `projects` table. When one or more projects are detected, the operation
is aborted to prevent accidental data loss. To bypass this message, pass the `--force` option to the command.

### Message: `FATAL:  could not map anonymous shared memory: Cannot allocate memory`

If you see this message, it means that the secondary site's PostgreSQL tries to request memory that is higher than the available memory. There is an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/381585) that tracks this problem.

Example error message in Patroni logs (located at `/var/log/gitlab/patroni/current` for Linux package installations):

```plaintext
2023-11-21_23:55:18.63727 FATAL:  could not map anonymous shared memory: Cannot allocate memory
2023-11-21_23:55:18.63729 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory, swap space, or huge pages. To reduce the request size (currently 17035526144 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
```

The workaround is to increase the memory available to the secondary site's PostgreSQL nodes to match the memory requirements of the primary site's PostgreSQL nodes.

## Fixing non-PostgreSQL replication failures

If you notice replication failures in `Admin > Geo > Sites` or the [Sync status Rake task](common.md#sync-status-rake-task), you can try to resolve the failures with the following general steps:

1. Geo automatically retries failures. If the failures are new and few in number, or if you suspect the root cause is already resolved, then you can wait to see if the failures go away.
1. If failures were present for a long time, then many retries have already occurred, and the interval between automatic retries has increased to up to 4 hours depending on the type of failure. If you suspect the root cause is already resolved, you can [manually retry replication or verification](#manually-retry-replication-or-verification).
1. If the failures persist, use the following sections to try to resolve them.

### Manually retry replication or verification

A Geo data type is a specific class of data that is required by one or more GitLab features to store relevant information and is replicated by Geo to secondary sites.

The following Geo data types exist:

- **Blob types:**
  - `Ci::JobArtifact`
  - `Ci::PipelineArtifact`
  - `Ci::SecureFile`
  - `LfsObject`
  - `MergeRequestDiff`
  - `Packages::PackageFile`
  - `PagesDeployment`
  - `Terraform::StateVersion`
  - `Upload`
  - `DependencyProxy::Manifest`
  - `DependencyProxy::Blob`
- **Repository types:**
  - `ContainerRepositoryRegistry`
  - `DesignManagement::Repository`
  - `ProjectRepository`
  - `ProjectWikiRepository`
  - `SnippetRepository`
  - `GroupWikiRepository`

The main kinds of classes are Registry, Model, and Replicator. If you have an instance of one of these classes, you can get the others. The Registry and Model mostly manage PostgreSQL DB state. The Replicator knows how to replicate/verify (or it can call a service to do it):

```ruby
model_record = Packages::PackageFile.last
model_record.replicator.registry.replicator.model_record # just showing that these methods exist
```

With all this information, you can:

- [Manually resync and reverify individual components](#resync-and-reverify-individual-components)
- [Manually resync and reverify multiple components](#resync-and-reverify-multiple-components)

#### Resync and reverify individual components

[You can force a resync and reverify individual items](https://gitlab.com/gitlab-org/gitlab/-/issues/364727)
for all component types managed by the [self-service framework](../../../../development/geo/framework.md) using the UI.
On the secondary site, visit **Admin > Geo > Replication**.

However, if this doesn't work, you can perform the same action using the Rails
console. The following sections describe how to use internal application
commands in the Rails console to cause replication or verification for
individual records synchronously or asynchronously.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

[Start a Rails console session](../../../../administration/operations/rails_console.md#starting-a-rails-console-session)
to enact the following, basic troubleshooting steps:

- **For Blob types** (using the `Packages::PackageFile` component as an example)

  - Find registry records that failed to sync:

    ```ruby
    Geo::PackageFileRegistry.failed
    ```

  - Find registry records that are missing on the primary site:

    ```ruby
    Geo::PackageFileRegistry.where(last_sync_failure: 'The file is missing on the Geo primary site')
    ```

  - Resync a package file, synchronously, given an ID:

    ```ruby
    model_record = Packages::PackageFile.find(id)
    model_record.replicator.sync
    ```

  - Resync a package file, synchronously, given a registry ID:

    ```ruby
    registry = Geo::PackageFileRegistry.find(registry_id)
    registry.replicator.sync
    ```

  - Resync a package file, asynchronously, given a registry ID.
    Since GitLab 16.2, a component can be asynchronously replicated as follows:

    ```ruby
    registry = Geo::PackageFileRegistry.find(registry_id)
    registry.replicator.enqueue_sync
    ```

  - Reverify a package file, asynchronously, given a registry ID.
    Since GitLab 16.2, a component can be asynchronously reverified as follows:

    ```ruby
    registry = Geo::PackageFileRegistry.find(registry_id)
    registry.replicator.verify_async
    ```

- **For Repository types** (using the `SnippetRepository` component as an example)

  - Resync a snippet repository, synchronously, given an ID:

    ```ruby
    model_record = Geo::SnippetRepositoryRegistry.find(id)
    model_record.replicator.sync
    ```

  - Resync a snippet repository, synchronously, given a registry ID

    ```ruby
    registry = Geo::SnippetRepositoryRegistry.find(registry_id)
    registry.replicator.sync
    ```

  - Resync a snippet repository, asynchronously, given a registry ID.
    Since GitLab 16.2, a component can be asynchronously replicated as follows:

    ```ruby
    registry = Geo::SnippetRepositoryRegistry.find(registry_id)
    registry.replicator.enqueue_sync
    ```

  - Reverify a snippet repository, asynchronously, given a registry ID.
    Since GitLab 16.2, a component can be asynchronously reverified as follows:

    ```ruby
    registry = Geo::SnippetRepositoryRegistry.find(registry_id)
    registry.replicator.verify_async
    ```

#### Resync and reverify multiple components

NOTE:
There is an [issue to implement this functionality in the Admin area UI](https://gitlab.com/gitlab-org/gitlab/-/issues/364729).

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

The following sections describe how to use internal application commands in the [Rails console](../../../../administration/operations/rails_console.md#starting-a-rails-console-session)
to cause bulk replication or verification.

##### Reverify all components (or any SSF data type which supports verification)

For GitLab 16.4 and earlier:

1. SSH into a GitLab Rails node in the primary Geo site.
1. Open the [Rails console](../../../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Mark all uploads as `pending verification`:

   ```ruby
   Upload.verification_state_table_class.each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

1. This causes the primary to start checksumming all Uploads.
1. When a primary successfully checksums a record, then all secondaries recalculate the checksum as well, and they compare the values.

For other SSF data types replace `Upload` in the command above with the desired model class.

##### Verify blob files on the secondary manually

This iterates over all package files on the secondary, looking at the
`verification_checksum` stored in the database (which came from the primary)
and then calculate this value on the secondary to check if they match. This
does not change anything in the UI.

```ruby
# Run on secondary
status = {}

Packages::PackageFile.find_each do |package_file|
  primary_checksum = package_file.verification_checksum
  secondary_checksum = Packages::PackageFile.sha256_hexdigest(package_file.file.path)
  verification_status = (primary_checksum == secondary_checksum)

  status[verification_status.to_s] ||= []
  status[verification_status.to_s] << package_file.id
end

# Count how many of each value we get
status.keys.each {|key| puts "#{key} count: #{status[key].count}"}

# See the output in its entirety
status
```

### Failed verification of Uploads on the primary Geo site

If verification of some uploads is failing on the primary Geo site with `verification_checksum = nil` and with the ``verification_failure = Error during verification: undefined method `underscore' for NilClass:Class``, this can be due to orphaned Uploads. The parent record owning the Upload (the upload's model) has somehow been deleted, but the Upload record still exists. These verification failures are false.

You can find these errors in the `geo.log` file on the primary Geo site.

To confirm that model records are missing, you can run a Rake task on the primary Geo site:

```shell
sudo gitlab-rake gitlab:uploads:check
```

You can delete these Upload records on the primary Geo site to get rid of these failures by running the following script from the [Rails console](../../../operations/rails_console.md):

```ruby
# Look for uploads with the verification error
# or edit with your own affected IDs
uploads = Geo::UploadState.where(
  verification_checksum: nil,
  verification_state: 3,
  verification_failure: "Error during verification: undefined method  `underscore' for NilClass:Class"
).pluck(:upload_id)

uploads_deleted = 0
begin
    uploads.each do |upload|
    u = Upload.find upload
    rescue => e
        puts "checking upload #{u.id} failed with #{e.message}"
      else
        uploads_deleted=uploads_deleted + 1
        p u                            ### allow verification before destroy
        # p u.destroy!                 ### uncomment to actually destroy
  end
end
p "#{uploads_deleted} remote objects were destroyed."
```

## Investigate causes of database replication lag

If the output of `sudo gitlab-rake geo:status` shows that `Database replication lag` remains significantly high over time, the primary node in database replication can be checked to determine the status of lag for
different parts of the database replication process. These values are known as `write_lag`, `flush_lag`, and `replay_lag`. For more information, see
[the official PostgreSQL documentation](https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-REPLICATION-VIEW).

Run the following command from the primary Geo node's database to provide relevant output:

```shell
gitlab-psql -xc 'SELECT write_lag,flush_lag,replay_lag FROM pg_stat_replication;'

-[ RECORD 1 ]---------------
write_lag  | 00:00:00.072392
flush_lag  | 00:00:00.108168
replay_lag | 00:00:00.108283
```

If one or more of these values is significantly high, this could indicate a problem and should be investigated further. When determining the cause, consider that:

- `write_lag` indicates the time since when WAL bytes have been sent by the primary, then received to the secondary, but not yet flushed or applied.
- A high `write_lag` value may indicate degraded network performance or insufficient network speed between the primary and secondary nodes.
- A high `flush_lag` value may indicate degraded or sub-optimal disk I/O performance with the secondary node's storage device.
- A high `replay_lag` value may indicate long running transactions in PostgreSQL, or the saturation of a needed resource like the CPU.
- The difference in time between `write_lag` and `flush_lag` indicates that WAL bytes have been sent to the underlying storage system, but it has not reported that they were flushed.
  This data is most likely not fully written to a persistent storage, and likely held in some kind of volatile write cache.
- The difference between `flush_lag` and `replay_lag` indicates WAL bytes that have been successfully persisted to storage, but could not be replayed by the database system.

## Resetting Geo **secondary** site replication

If you get a **secondary** site in a broken state and want to reset the replication state,
to start again from scratch, there are a few steps that can help you:

1. Stop Sidekiq and the Geo LogCursor.

   It's possible to make Sidekiq stop gracefully, but making it stop getting new jobs and
   wait until the current jobs to finish processing.

   You need to send a **SIGTSTP** kill signal for the first phase and them a **SIGTERM**
   when all jobs have finished. Otherwise just use the `gitlab-ctl stop` commands.

   ```shell
   gitlab-ctl status sidekiq
   # run: sidekiq: (pid 10180) <- this is the PID you will use
   kill -TSTP 10180 # change to the correct PID

   gitlab-ctl stop sidekiq
   gitlab-ctl stop geo-logcursor
   ```

   You can watch the [Sidekiq logs](../../../logs/index.md#sidekiq-logs) to know when Sidekiq jobs processing has finished:

   ```shell
   gitlab-ctl tail sidekiq
   ```

1. Clear Gitaly/Gitaly Cluster data.

   ::Tabs

   :::TabTitle Gitaly

   ```shell
   mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
   sudo gitlab-ctl reconfigure
   ```

   :::TabTitle Gitaly Cluster

   1. Optional. Disable the Praefect internal load balancer.
   1. Stop Praefect on each Praefect server:

      ```shell
      sudo gitlab-ctl stop praefect
      ```

   1. Reset the Praefect database:

      ```shell
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "DROP DATABASE praefect_production WITH (FORCE);"
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "CREATE DATABASE praefect_production WITH OWNER=praefect ENCODING=UTF8;"
      ```

   1. Rename/delete repository data from each Gitaly node:

      ```shell
      sudo mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
      sudo gitlab-ctl reconfigure
      ```

   1. On your Praefect deploy node run reconfigure to set up the database:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Start Praefect on each Praefect server:

      ```shell
      sudo gitlab-ctl start praefect
      ```

   1. Optional. If you disabled it, reactivate the Praefect internal load balancer.

   ::EndTabs

   NOTE:
   You may want to remove the `/var/opt/gitlab/git-data/repositories.old` in the future
   as soon as you confirmed that you don't need it anymore, to save disk space.

1. Optional. Rename other data folders and create new ones.

   WARNING:
   You may still have files on the **secondary** site that have been removed from the **primary** site, but this
   removal has not been reflected. If you skip this step, these files are not removed from the Geo **secondary** site.

   Any uploaded content (like file attachments, avatars, or LFS objects) is stored in a
   subfolder in one of these paths:

   - `/var/opt/gitlab/gitlab-rails/shared`
   - `/var/opt/gitlab/gitlab-rails/uploads`

   To rename all of them:

   ```shell
   gitlab-ctl stop

   mv /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared.old
   mkdir -p /var/opt/gitlab/gitlab-rails/shared

   mv /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads.old
   mkdir -p /var/opt/gitlab/gitlab-rails/uploads

   gitlab-ctl start postgresql
   gitlab-ctl start geo-postgresql
   ```

   Reconfigure to recreate the folders and make sure permissions and ownership
   are correct:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Reset the Tracking Database.

   WARNING:
   If you skipped the optional step 3, be sure both `geo-postgresql` and `postgresql` services are running.

   ```shell
   gitlab-rake db:drop:geo DISABLE_DATABASE_ENVIRONMENT_CHECK=1   # on a secondary app node
   gitlab-ctl reconfigure     # on the tracking database node
   gitlab-rake db:migrate:geo # on a secondary app node
   ```

1. Restart previously stopped services.

   ```shell
   gitlab-ctl start
   ```
