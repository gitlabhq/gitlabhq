---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Background migrations and upgrades **(FREE SELF)**

> - Batched background migrations [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51332) in GitLab 13.11 [with a flag](../user/feature_flags.md) named `execute_batched_migrations_on_schedule`. Disabled by default.
> - Feature flag `execute_batched_migrations_on_schedule` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/329511) in GitLab 13.12.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](../development/database/batched_background_migrations.md#enable-or-disable-background-migrations).

Certain releases may require different migrations to be finished before you
update to the newer version. Two kinds of migrations exist. They differ, and you
should check that both are complete before upgrading GitLab:

- [Batched background migrations](#batched-background-migrations), most
  commonly used in GitLab 14.0 and later.
- [Background migrations](#background-migrations) that are not batched.
  Most commonly used in GitLab 13.11 and earlier.

To decrease the time required to complete these migrations, increase the number of
[Sidekiq workers](../administration/sidekiq/extra_sidekiq_processes.md)
that can process jobs in the `background_migration` queue.

## Batched background migrations

To update database tables in batches, GitLab can use batched background migrations. These migrations
are created by GitLab developers and run automatically on upgrade. However, such migrations are
limited in scope to help with migrating some `integer` database columns to `bigint`. This is needed to
prevent integer overflow for some tables.

Some installations [may need to run GitLab 14.0 for at least a day](versions/gitlab_14_changes.md#1400)
to complete the database changes introduced by that upgrade.

Batched background migrations are handled by Sidekiq and
[run in isolation](../development/database/batched_background_migrations.md#isolation),
so an instance can remain operational while the migrations are processed. However,
performance might degrade on larger instances that are heavily used while
batched background migrations are run. You should
[Actively monitor the Sidekiq status](../administration/admin_area.md#background-jobs)
until all migrations are completed.

### Check the status of batched background migrations

You can check the status of batched background migrations in the GitLab UI, or
by querying the database directly. Before you upgrade GitLab, all migrations must
have a `Finished` status.

If the migrations are not finished and you try to upgrade GitLab, you might
see this error:

```plaintext
Expected batched background migration for the given configuration to be marked
as 'finished', but it is 'active':
```

If you get this error,
[review the options](#database-migrations-failing-because-of-batched-background-migration-not-finished) for
how to complete the batched background migrations needed for the GitLab upgrade.

#### From the GitLab UI

Prerequisites:

- You must have administrator access to the instance.

To check the status of batched background migrations:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. Select **Monitoring > Background Migrations**.
1. Select **Queued** or **Finalizing** to see incomplete migrations,
   and **Failed** for failed migrations.

#### From the database

Prerequisites:

- You must have administrator access to the instance.

To query the database directly for the status of batched background migrations:

1. Log into a `psql` prompt, according to the directions for your instance's
   installation method. For example, `sudo gitlab-psql` for Linux package installations.
1. To see details on incomplete batched background migrations, run this query in
   the `psql` session:

   ```sql
   SELECT
     job_class_name,
     table_name,
     column_name,
     job_arguments
   FROM batched_background_migrations
   WHERE status <> 3;
   ```

Alternatively, you can wrap the query with `gitlab-psql -c "<QUERY>"` to check the status of
batched background migrations:

```shell
gitlab-psql -c "SELECT job_class_name, table_name, column_name, job_arguments FROM batched_background_migrations WHERE status <> 3;"
```

If the query returns zero rows, all batched background migrations are complete.

### Enable or disable advanced features

Batched background migrations provide feature flags that enable you to customize
migrations or pause them entirely. These feature flags should only be disabled by
advanced users who understand the risks of doing so.

#### Pause batched background migrations in GitLab 14.x

WARNING:
There can be [risks when disabling released features](../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to each feature's version history for more details.

To pause an ongoing batched background migration,
[disable the batched background migrations feature](../development/database/batched_background_migrations.md#enable-or-disable-background-migrations).
Disabling the feature completes the current batch of migrations, then waits to start
the next batch until after the feature is enabled again.

Prerequisites:

- You must have administrator access to the instance.

Use the following database queries to see the state of the current batched background migration:

1. Obtain the ID of the running migration:

   ```sql
   SELECT
    id,
    job_class_name,
    table_name,
    column_name,
    job_arguments
   FROM batched_background_migrations
   WHERE status <> 3;
   ```

1. Run this query, replacing `XX` with the ID you obtained in the previous step,
   to see the status of the migration:

   ```sql
   SELECT
    started_at,
    finished_at,
    finished_at - started_at AS duration,
    min_value,
    max_value,
    batch_size,
    sub_batch_size
   FROM batched_background_migration_jobs
   WHERE batched_background_migration_id = XX
   ORDER BY id DESC
   limit 10;
   ```

1. Run the query multiple times within a few minutes to ensure no new row has been added.
   If no new row has been added, the migration has been paused.

1. After confirming the migration has paused, restart the migration (using the `enable`
   command above) to proceed with the batch when ready. On larger instances,
   background migrations can take as long as 48 hours to complete each batch.

#### Automatic batch size optimization

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60133) in GitLab 13.2 [with a flag](../administration/feature_flags.md) named `optimize_batched_migrations`. Enabled by default.

WARNING:
There can be [risks when disabling released features](../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's version history for more details.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../administration/feature_flags.md) named `optimize_batched_migrations`.
On GitLab.com, this feature is available.

To maximize throughput of batched background migrations (in terms of the number of tuples updated per time unit), batch sizes are automatically adjusted based on how long the previous batches took to complete.

#### Parallel execution

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104027) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `batched_migrations_parallel_execution`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/372316) in GitLab 15.11.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120808) in GitLab 16.1. Feature flag `batched_migrations_parallel_execution` removed.

WARNING:
There can be [risks when disabling released features](../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's version history for more details.

To speed up the execution of batched background migrations, two migrations are executed at the same time.

[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md) can change
the number of batched background migrations executed in parallel:

```ruby
ApplicationSetting.update_all(database_max_running_batched_background_migrations: 4)
```

### Resolve failed batched background migrations

If a batched background migration fails, [fix and retry](#fix-and-retry-the-migration) it.
If the migration continues to fail with an error, either:

- [Finish the failed migration manually](#finish-a-failed-migration-manually)
- [Mark the failed migration finished](#mark-a-failed-migration-finished)

#### Fix and retry the migration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67504) in GitLab 14.3.

All failed batched background migrations must be resolved to upgrade to a newer
version of GitLab. If you [check the status](#check-the-status-of-batched-background-migrations)
of batched background migrations, some migrations might display in the **Failed** tab
with a **failed** status:

![failed batched background migrations table](img/batched_background_migrations_failed_v14_3.png)

To determine why the batched background migration failed,
[view the failure error logs](../development/database/batched_background_migrations.md#viewing-failure-error-logs)
or view error information in the UI.

Prerequisites:

- You must have administrator access to the instance.

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. Select **Monitoring > Background Migrations**.
1. Select the **Failed** tab. This displays a list of failed batched background migrations.
1. Select the failed **Migration** to see the migration parameters and the jobs that failed.
1. Under **Failed jobs**, select each **ID** to see why the job failed.

If you are a GitLab customer, consider opening a [Support Request](https://support.gitlab.com/hc/en-us/requests/new)
to debug why the batched background migrations failed.

To correct the problem, you can retry the failed migration.

Prerequisites:

- You must have administrator access to the instance.

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. Select **Monitoring > Background Migrations**.
1. Select the **Failed** tab. This displays a list of failed batched background migrations.
1. Select a failed batched background migration to retry by clicking on the retry button (**{retry}**).

To monitor the retried batched background migrations, you can
[check the status of batched background migrations](#check-the-status-of-batched-background-migrations)
on a regular interval.

#### Finish a failed migration manually

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62634) in GitLab 14.1.

To manually finish a batched background migration that failed with an error,
use the information in the failure error logs or the database:

::Tabs

:::TabTitle From the failure error logs

1. [View the failure error logs](../development/database/batched_background_migrations.md#viewing-failure-error-logs)
   and look for an `An error has occurred, all later migrations canceled` error message, like this:

   ```plaintext
   StandardError: An error has occurred, all later migrations canceled:

   Expected batched background migration for the given configuration to be marked as
   'finished', but it is 'active':
     {:job_class_name=>"CopyColumnUsingBackgroundMigrationJob",
      :table_name=>"push_event_payloads",
      :column_name=>"event_id",
      :job_arguments=>[["event_id"],
      ["event_id_convert_to_bigint"]]
     }
   ```

1. Run the following command, replacing the values in angle brackets with the correct arguments:

   ```shell
   sudo gitlab-rake gitlab:background_migrations:finalize[<job_class_name>,<table_name>,<column_name>,'<job_arguments>']
   ```

   When dealing with multiple arguments, such as `[["id"],["id_convert_to_bigint"]]`, escape the
   comma between each argument with a backslash <code>&#92;</code> to prevent an invalid character error.
   For example, to finish the migration from the previous step:

   ```shell
   sudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,push_event_payloads,event_id,'[["event_id"]\, ["event_id_convert_to_bigint"]]']
   ```

:::TabTitle From the database

  1. [Check the status](#check-the-status-of-batched-background-migrations) of the
     migration in the database.
  1. Use the query results to construct a migration command, replacing the values
     in angle brackets with the correct arguments:

     ```shell
     sudo gitlab-rake gitlab:background_migrations:finalize[<job_class_name>,<table_name>,<column_name>,'<job_arguments>']
     ```

     For example, if the query returns this data:

     - `job_class_name`: `CopyColumnUsingBackgroundMigrationJob`
     - `table_name`: `events`
     - `column_name`: `id`
     - `job_arguments`: `[["id"], ["id_convert_to_bigint"]]`

   When dealing with multiple arguments, such as `[["id"],["id_convert_to_bigint"]]`, escape the
   comma between each argument with a backslash <code>&#92;</code> to prevent an invalid character error.
   The command should be:

   ```shell
   sudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,events,id,'[["id"]\, ["id_convert_to_bigint"]]']
   ```

::EndTabs

#### Mark a failed migration finished

WARNING:
[Contact GitLab Support](https://about.gitlab.com/support/#contact-support) before using
these instructions. This action can cause data loss, and make your instance fail
in ways that are difficult to recover from.

There can be cases where the background migration fails: when jumping too many version upgrades,
or backward-incompatible database schema changes. (For an example, see [issue 393216](https://gitlab.com/gitlab-org/gitlab/-/issues/393216)).
Failed background migrations prevent further application upgrades.

When the background migration is determined to be "safe" to skip, the migration can be manually marked finished:

WARNING:
Make sure you create a backup before proceeding.

```ruby
# Start the rails console

connection = ApplicationRecord.connection # or Ci::ApplicationRecord.connection, depending on which DB was the migration scheduled

Gitlab::Database::SharedModel.using_connection(connection) do
  migration = Gitlab::Database::BackgroundMigration::BatchedMigration.find_for_configuration(
    Gitlab::Database.gitlab_schemas_for_connection(connection),
    'BackfillUserDetailsFields',
    :users,
    :id,
    []
  )

  # mark all jobs completed
  migration.batched_jobs.update_all(status: Gitlab::Database::BackgroundMigration::BatchedJob.state_machine.states['succeeded'].value)
  migration.update_attribute(:status, Gitlab::Database::BackgroundMigration::BatchedMigration.state_machine.states[:finished].value)
end
```

## Background migrations

In GitLab 13, background migrations were not batched. In GitLab 14 and later, this
type of migration was superseded by batched background migrations.

### Check for pending background migrations

To check for pending non-batched background migrations:

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'
sudo gitlab-rails runner -e production 'puts Gitlab::Database::BackgroundMigration::BatchedMigration.queued.count'
```

:::TabTitle Self-compiled (source)

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::Database::BackgroundMigration::BatchedMigration.queued.count'
```

::EndTabs

### Check for failed background migrations

To check for non-batched background migrations that have failed:

::Tabs

:::TabTitle Linux package (Omnibus)

For GitLab versions 14.10 and later:

```shell
sudo gitlab-rails runner -e production 'puts Gitlab::Database::BackgroundMigration::BatchedMigration.with_status(:failed).count'
```

For GitLab versions 14.0-14.9:

```shell
sudo gitlab-rails runner -e production 'puts Gitlab::Database::BackgroundMigration::BatchedMigration.failed.count'
```

:::TabTitle Self-compiled (source)

For GitLab versions 14.10 and later:

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::Database::BackgroundMigration::BatchedMigration.with_status(:failed).count'
```

For GitLab versions 14.0-14.9:

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::Database::BackgroundMigration::BatchedMigration.failed.count'
```

::EndTabs

## Troubleshooting

<!-- Linked from lib/gitlab/database/migrations/batched_background_migration_helpers.rb -->

### Database migrations failing because of batched background migration not finished

When updating to GitLab version 14.2 or later, database migrations might fail with a message like:

```plaintext
StandardError: An error has occurred, all later migrations canceled:

Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':
  {:job_class_name=>"CopyColumnUsingBackgroundMigrationJob",
   :table_name=>"push_event_payloads",
   :column_name=>"event_id",
   :job_arguments=>[["event_id"],
   ["event_id_convert_to_bigint"]]
  }
```

First, check if you have followed the [version-specific upgrade instructions for 14.2](../update/versions/gitlab_14_changes.md#1420).
If you have, you can [manually finish the batched background migration](#finish-a-failed-migration-manually)).
If you haven't, choose one of the following methods:

1. [Rollback and upgrade](#roll-back-and-follow-the-required-upgrade-path) through one of the required
versions before updating to 14.2+.
1. [Roll forward](#roll-forward-and-finish-the-migrations-on-the-upgraded-version), staying on the current
version and manually ensuring that the batched migrations complete successfully.

#### Roll back and follow the required upgrade path

1. [Rollback and restore the previously installed version](../administration/backup_restore/index.md)
1. Update to either 14.0.5 or 14.1 **before** updating to 14.2+
1. [Check the status](#check-the-status-of-batched-background-migrations) of the batched background migrations and
make sure they are all marked as finished before attempting to upgrade again. If any remain marked as active,
you can [manually finish them](#finish-a-failed-migration-manually).

#### Roll forward and finish the migrations on the upgraded version

##### For a deployment with downtime

To run all the batched background migrations, it can take a significant amount of time
depending on the size of your GitLab installation.

1. [Check the status](#check-the-status-of-batched-background-migrations) of the batched background migrations in the
database, and [manually run them](#finish-a-failed-migration-manually) with the appropriate
arguments until the status query returns no rows.
1. When the status of all of all them is marked as complete, re-run migrations for your installation.
1. [Complete the database migrations](../administration/raketasks/maintenance.md#run-incomplete-database-migrations) from your GitLab upgrade:

   ```plaintext
   sudo gitlab-rake db:migrate
   ```

1. Run a reconfigure:

   ```plaintext
   sudo gitlab-ctl reconfigure
   ```

1. Finish the upgrade for your installation.

##### For a no-downtime deployment

As the failing migrations are post-deployment migrations, you can remain on a running instance of the upgraded
version and wait for the batched background migrations to finish.

1. [Check the status](#check-the-status-of-batched-background-migrations) of the batched background migration from
the error message, and make sure it is listed as finished. If it is still active, either wait until it is done,
or [manually finish it](#finish-a-failed-migration-manually).
1. Re-run migrations for your installation, so the remaining post-deployment migrations finish.

### The `BackfillNamespaceIdForNamespaceRoute` batched migration job fails

In GitLab 14.8, the `BackfillNamespaceIdForNamespaceRoute` batched background migration job
may fail to complete. When retried, a `500 Server Error` is returned. This issue was
[resolved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82387) in GitLab 14.9.

To resolve this issue, [upgrade GitLab](../update/index.md) from 14.8 to 14.9.
You can ignore the failed batch migration until after you update to GitLab 14.9.

### Background migrations remain in the Sidekiq queue

WARNING:
The following operations can disrupt your GitLab performance. They run a number of Sidekiq jobs that perform various database or file updates.

Run the following check. If it returns non-zero and the count does not decrease over time, follow the rest of the steps in this section.

```shell
# For Linux package installations:
sudo gitlab-rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'

# For self-compiled installations:
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'
```

It is safe to re-execute the following commands, especially if you have 1000+ pending jobs which would likely overflow your runtime memory.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
# Start the rails console
sudo gitlab-rails c

# Execute the following in the rails console
scheduled_queue = Sidekiq::ScheduledSet.new
pending_job_classes = scheduled_queue.select { |job| job["class"] == "BackgroundMigrationWorker" }.map { |job| job["args"].first }.uniq
pending_job_classes.each { |job_class| Gitlab::BackgroundMigration.steal(job_class) }
```

:::TabTitle Self-compiled (source)

```shell
# Start the rails console
sudo -u git -H bundle exec rails RAILS_ENV=production

# Execute the following in the rails console
scheduled_queue = Sidekiq::ScheduledSet.new
pending_job_classes = scheduled_queue.select { |job| job["class"] == "BackgroundMigrationWorker" }.map { |job| job["args"].first }.uniq
pending_job_classes.each { |job_class| Gitlab::BackgroundMigration.steal(job_class) }
```

::EndTabs

### Background migrations stuck in 'pending' state

WARNING:
The following operations can disrupt your GitLab performance. They run a number
of Sidekiq jobs that perform various database or file updates.

- GitLab 14.2 introduced an issue where a background migration named
  `BackfillDraftStatusOnMergeRequests` can be permanently stuck in a
  **pending** state across upgrades when the instance lacks records that match
  the migration's target. To clean up this stuck migration, see the
  [14.2.0 version-specific instructions](versions/gitlab_14_changes.md#1420).
- GitLab 14.4 introduced an issue where a background migration named
  `PopulateTopicsTotalProjectsCountCache` can be permanently stuck in a
  **pending** state across upgrades when the instance lacks records that match
  the migration's target. To clean up this stuck migration, see the
  [14.4.0 version-specific instructions](versions/gitlab_14_changes.md#1440).
- GitLab 14.5 introduced an issue where a background migration named
  `UpdateVulnerabilityOccurrencesLocation` can be permanently stuck in a
  **pending** state across upgrades when the instance lacks records that match
  the migration's target. To clean up this stuck migration, see the
  [14.5.0 version-specific instructions](versions/gitlab_14_changes.md#1450).
- GitLab 14.8 introduced an issue where a background migration named
  `PopulateTopicsNonPrivateProjectsCount` can be permanently stuck in a
  **pending** state across upgrades. To clean up this stuck migration, see the
  [14.8.0 version-specific instructions](versions/gitlab_14_changes.md#1480).
- GitLab 14.9 introduced an issue where a background migration named
  `ResetDuplicateCiRunnersTokenValuesOnProjects` can be permanently stuck in a
  **pending** state across upgrades when the instance lacks records that match
  the migration's target. To clean up this stuck migration, see the
  [14.9.0 version-specific instructions](versions/gitlab_14_changes.md#1490).

For other background migrations stuck in pending, run the following check. If
it returns non-zero and the count does not decrease over time, follow the rest
of the steps in this section.

```shell
# For Linux package installations:
sudo gitlab-rails runner -e production 'puts Gitlab::Database::BackgroundMigrationJob.pending.count'

# For self-compiled installations:
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::Database::BackgroundMigrationJob.pending.count'
```

It is safe to re-attempt these migrations to clear them out from a pending status:

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
# Start the rails console
sudo gitlab-rails c

# Execute the following in the rails console
Gitlab::Database::BackgroundMigrationJob.pending.find_each do |job|
  puts "Running pending job '#{job.class_name}' with arguments #{job.arguments}"
  result = Gitlab::BackgroundMigration.perform(job.class_name, job.arguments)
  puts "Result: #{result}"
end
```

:::TabTitle Self-compiled (source)

```shell
# Start the rails console
sudo -u git -H bundle exec rails RAILS_ENV=production

# Execute the following in the rails console
Gitlab::Database::BackgroundMigrationJob.pending.find_each do |job|
  puts "Running pending job '#{job.class_name}' with arguments #{job.arguments}"
  result = Gitlab::BackgroundMigration.perform(job.class_name, job.arguments)
  puts "Result: #{result}"
end
```

::EndTabs
