---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Batched background migrations **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51332) in GitLab 13.11.
> - [Deployed behind a feature flag](../../../user/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/329511) in GitLab 13.12.
> - Enabled on GitLab.com.
> - Recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-batched-background-migrations).

There can be [risks when disabling released features](../../../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's version history for more details.

To update database tables in batches, GitLab can use batched background migrations. These migrations
are created by GitLab developers and run automatically on upgrade. However, such migrations are
limited in scope to help with migrating some `integer` database columns to `bigint`. This is needed to
prevent integer overflow for some tables.

## Check the status of background migrations

All migrations must have a `Finished` status before you [upgrade GitLab](../../../update/index.md).
You can [check the status of existing migrations](../../../update/index.md#batched-background-migrations).

## Enable or disable batched background migrations

WARNING:
If you disable this feature flag, GitLab upgrades may fail.

Batched background migrations are under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:execute_batched_migrations_on_schedule)
```

To disable it:

```ruby
Feature.disable(:execute_batched_migrations_on_schedule)
```

### Pause batched background migrations in GitLab 14.x

To pause an ongoing batched background migration, use the `disable` command above.
This command causes the migration to complete the current batch, and then wait to start the next batch.

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

## Automatic batch size optimization

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60133) in GitLab 13.12.
> - [Deployed behind a feature flag](../../../user/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/329511) in GitLab 13.12.
> - Enabled on GitLab.com.
> - Recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-automatic-batch-size-optimization).

There can be [risks when disabling released features](../../../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's version history for more details.

To maximize throughput of batched background migrations (in terms of the number of tuples updated per time unit), batch sizes are automatically adjusted based on how long the previous batches took to complete.

## Enable or disable automatic batch size optimization

Automatic batch size optimization for batched background migrations is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:optimize_batched_migrations)
```

To disable it:

```ruby
Feature.disable(:optimize_batched_migrations)
```

## Troubleshooting

### Database migrations failing because of batched background migration not finished

When updating to GitLab 14.2 or later there might be a database migration failing with a message like:

```plaintext
StandardError: An error has occurred, all later migrations canceled:

Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':
  {:job_class_name=>"CopyColumnUsingBackgroundMigrationJob", :table_name=>"push_event_payloads", :column_name=>"event_id", :job_arguments=>[["event_id"], ["event_id_convert_to_bigint"]]}
```

First, check if you have followed the [version-specific upgrade instructions for 14.2](../../../update/index.md#1420).
If you have, you can [manually finish the batched background migration](#manually-finishing-a-batched-background-migration).
If you haven't, choose one of the following methods:

1. [Rollback and upgrade](#roll-back-and-follow-the-required-upgrade-path) through one of the required
versions before updating to 14.2+.
1. [Roll forward](#roll-forward-and-finish-the-migrations-on-the-upgraded-version), staying on the current
version and manually ensuring that the batched migrations complete successfully.

#### Roll back and follow the required upgrade path

1. [Rollback and restore the previously installed version](../../../raketasks/backup_restore.md)
1. Update to either 14.0.5 or 14.1 **before** updating to 14.2+
1. [Check the status](#check-the-status-of-background-migrations) of the batched background migrations and
make sure they are all marked as finished before attempting to upgrade again. If any remain marked as active,
you can [manually finish them](#manually-finishing-a-batched-background-migration).

#### Roll forward and finish the migrations on the upgraded version

##### For a deployment with downtime

To run all the batched background migrations, it can take a significant amount of time
depending on the size of your GitLab installation.

1. [Check the status](#check-the-status-of-background-migrations) of the batched background migrations in the
database, and [manually run them](#manually-finishing-a-batched-background-migration) with the appropriate
arguments until the status query returns no rows.
1. When the status of all of all them is marked as complete, re-run migrations for your installation.
1. [Complete the database migrations](../../../administration/raketasks/maintenance.md#run-incomplete-database-migrations) from your GitLab upgrade:

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
version and wait for the batched background migrations to finish normally.

1. [Check the status](#check-the-status-of-background-migrations) of the batched background migration from
the error message, and make sure it is listed as finished. If it is still active, either wait until it is done,
or [manually finish it](#manually-finishing-a-batched-background-migration).
1. Re-run migrations for your installation, so the remaining post-deployment migrations finish.

### Manually finishing a batched background migration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62634) in GitLab 14.1

If you need to manually finish a batched background migration due to an
error, you can run:

```shell
sudo gitlab-rake gitlab:background_migrations:finalize[<job_class_name>,<table_name>,<column_name>,'<job_arguments>']
```

Replace the values in angle brackets with the correct
arguments. For example, if you receive an error similar to this:

```plaintext
StandardError: An error has occurred, all later migrations canceled:

Expected batched background migration for the given configuration to be marked as 'finished', but it is 'active':
  {:job_class_name=>"CopyColumnUsingBackgroundMigrationJob", :table_name=>"push_event_payloads", :column_name=>"event_id", :job_arguments=>[["event_id"], ["event_id_convert_to_bigint"]]}
```

Plug the arguments from the error message into the command:

```shell
sudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,push_event_payloads,event_id,'[["event_id"]\, ["event_id_convert_to_bigint"]]']
```

If you need to manually run a batched background migration to continue an upgrade, you can
[check the status](#check-the-status-of-background-migrations) in the database and get the
arguments from the query results. For example, if the query returns this:

```plaintext
            job_class_name             | table_name | column_name |           job_arguments
---------------------------------------+------------+-------------+------------------------------------
 CopyColumnUsingBackgroundMigrationJob | events     | id          | [["id"], ["id_convert_to_bigint"]]
 ```

The results from the query can be plugged into the command:

```shell
sudo gitlab-rake gitlab:background_migrations:finalize[CopyColumnUsingBackgroundMigrationJob,events,id,'[["id"]\, ["id_convert_to_bigint"]]']
```

### The `BackfillNamespaceIdForNamespaceRoute` batched migration job fails

In GitLab 14.8, the `BackfillNamespaceIdForNamespaceRoute` batched background migration job
may fail to complete. When retried, a `500 Server Error` is returned. This issue was
[resolved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82387) in GitLab 14.9.

To resolve this issue, [upgrade GitLab](../../../update/index.md) from 14.8 to 14.9.
You can ignore the failed batch migration until after you update to GitLab 14.9.
