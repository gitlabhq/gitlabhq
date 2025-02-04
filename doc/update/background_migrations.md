---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrations for upgrades
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

When upgrading GitLab, there are two types of migrations to check:

- Database migrations.
- Advanced search migrations.

Read below for detailed information about the two types of migrations.

## Database background migrations

> - Feature [flag](../user/feature_flags.md) `execute_batched_migrations_on_schedule` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/329511) in GitLab 13.12.
> - For GitLab Self-Managed, administrators can opt to [disable it](../development/database/batched_background_migrations.md#enable-or-disable-background-migrations).

Certain releases may require different migrations to be finished before you
update to the newer version. Two kinds of migrations exist. They differ, and you
should check that both are complete before upgrading GitLab:

- [Batched background migrations](#batched-background-migrations) were introduced
  in GitLab 14.0. All migrations in GitLab 15.1 and later use this format exclusively.
- [Background migrations](#background-migrations) that are not batched.
  Used in GitLab 15.0 and earlier.

To decrease the time required to complete these migrations, increase the number of
[Sidekiq workers](../administration/sidekiq/extra_sidekiq_processes.md)
that can process jobs in the `background_migration` queue.

### Batched background migrations

To update database tables in batches, GitLab can use batched background migrations. These migrations
are created by GitLab developers and run automatically on upgrade. However, such migrations are
limited in scope to help with migrating some `integer` database columns to `bigint`. This is needed to
prevent integer overflow for some tables.

Batched background migrations are handled by Sidekiq and
[run in isolation](../development/database/batched_background_migrations.md#isolation),
so an instance can remain operational while the migrations are processed. However,
performance might degrade on larger instances that are heavily used while
batched background migrations are run. You should
[Actively monitor the Sidekiq status](../administration/admin_area.md#background-jobs)
until all migrations are completed.

#### Check the status of batched background migrations

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
[review the options](background_migrations_troubleshooting.md#database-migrations-failing-because-of-batched-background-migration-not-finished) for
how to complete the batched background migrations needed for the GitLab upgrade.

##### From the GitLab UI

Prerequisites:

- You must have administrator access to the instance.

To check the status of batched background migrations:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Background migrations**.
1. Select **Queued** or **Finalizing** to see incomplete migrations,
   and **Failed** for failed migrations.

##### From the database

Prerequisites:

- You must have administrator access to the instance.

To query the database directly for the status of batched background migrations:

1. Sign in to a `psql` prompt, according to the directions for your instance's
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
   WHERE status NOT IN(3, 6);
   ```

Alternatively, you can wrap the query with `gitlab-psql -c "<QUERY>"` to check the status of
batched background migrations:

```shell
gitlab-psql -c "SELECT job_class_name, table_name, column_name, job_arguments FROM batched_background_migrations WHERE status NOT IN(3, 6);"
```

If the query returns zero rows, all batched background migrations are complete.

#### Enable or disable advanced features

Batched background migrations provide feature flags that enable you to customize
migrations or pause them entirely. These feature flags should only be disabled by
advanced users who understand the risks of doing so.

##### Pause batched background migrations

WARNING:
There can be [risks when disabling released features](../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to each feature's history for more details.

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
   WHERE status NOT IN(3, 6);
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

##### Automatic batch size optimization

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60133) in GitLab 13.2 [with a flag](../administration/feature_flags.md) named `optimize_batched_migrations`. Enabled by default.

WARNING:
There can be [risks when disabling released features](../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's history for more details.

FLAG:
On GitLab Self-Managed, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../administration/feature_flags.md) named `optimize_batched_migrations`.
On GitLab.com, this feature is available. On GitLab Dedicated, this feature is not available.

To maximize throughput of batched background migrations (in terms of the number of tuples updated per time unit), batch sizes are automatically adjusted based on how long the previous batches took to complete.

##### Parallel execution

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104027) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `batched_migrations_parallel_execution`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/372316) in GitLab 15.11.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120808) in GitLab 16.1. Feature flag `batched_migrations_parallel_execution` removed.

WARNING:
There can be [risks when disabling released features](../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's history for more details.

To speed up the execution of batched background migrations, two migrations are executed at the same time.

[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md) can change
the number of batched background migrations executed in parallel:

```ruby
ApplicationSetting.update_all(database_max_running_batched_background_migrations: 4)
```

#### Resolve failed batched background migrations

If a batched background migration fails, [fix and retry](#fix-and-retry-the-migration) it.
If the migration continues to fail with an error, either:

- [Finish the failed migration manually](#finish-a-failed-migration-manually)
- [Mark the failed migration finished](#mark-a-failed-migration-finished)

##### Fix and retry the migration

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

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Background migrations**.
1. Select the **Failed** tab. This displays a list of failed batched background migrations.
1. Select the failed **Migration** to see the migration parameters and the jobs that failed.
1. Under **Failed jobs**, select each **ID** to see why the job failed.

If you are a GitLab customer, consider opening a [Support Request](https://support.gitlab.com/hc/en-us/requests/new)
to debug why the batched background migrations failed.

To correct the problem, you can retry the failed migration.

Prerequisites:

- You must have administrator access to the instance.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Background migrations**.
1. Select the **Failed** tab. This displays a list of failed batched background migrations.
1. Select a failed batched background migration to retry by clicking on the retry button (**{retry}**).

To monitor the retried batched background migrations, you can
[check the status of batched background migrations](#check-the-status-of-batched-background-migrations)
on a regular interval.

##### Finish a failed migration manually

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
   Every comma in the `job_arguments` parameter value must be escaped with a backslash.

   For example:

   ```shell
   sudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,ci_builds,id,'[["id"\, "stage_id"]\,["id_convert_to_bigint"\,"stage_id_convert_to_bigint"]]']
   ```

::EndTabs

##### Mark a failed migration finished

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

<!--- start_remove The following content will be removed on remove_date: '2025-05-10' -->
<!-- This page needs significant revision after 15.0 becomes unsupported -->
<!--- end_remove -->

### Background migrations

Non-batched migrations are superseded by batched background migrations. Non-batched
migrations were gradually phased out during GitLab 14, with the last one
used in GitLab 15.0.

#### Check for pending background migrations

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

#### Check for failed background migrations

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

## Check for pending advanced search migrations

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

This section is only applicable if you have enabled the [Elasticsearch integration](../integration/advanced_search/elasticsearch.md).
Major releases require all [advanced search migrations](../integration/advanced_search/elasticsearch.md#advanced-search-migrations)
to be finished from the most recent minor release in your current version
before the major version upgrade. You can find pending migrations by
running the following command.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-rake gitlab:elastic:list_pending_migrations
```

:::TabTitle Self-compiled (source)

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:list_pending_migrations
```

::EndTabs
