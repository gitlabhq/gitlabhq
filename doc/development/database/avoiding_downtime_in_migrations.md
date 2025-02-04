---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Avoiding downtime in migrations
---

When working with a database certain operations may require downtime. As we
cannot have downtime in migrations we need to use a set of steps to get the
same end result without downtime. This guide describes various operations that
may appear to need downtime, their impact, and how to perform them without
requiring downtime.

## Dropping columns

Removing columns is tricky because running GitLab processes expect these columns to exist, as ActiveRecord caches the tables schema, even if the columns are not referenced. This happens if the columns are not explicitly marked as ignored. To work around this safely, you need three steps in three releases:

1. [Ignoring the column](#ignoring-the-column-release-m) (release M)
1. [Dropping the column](#dropping-the-column-release-m1) (release M+1)
1. [Removing the ignore rule](#removing-the-ignore-rule-release-m2) (release M+2)

The reason we spread this out across three releases is that dropping a column is
a destructive operation that can't be rolled back easily.

Following this procedure helps us to make sure there are no deployments to GitLab.com
and upgrade processes for GitLab Self-Managed instances that lump together any of these steps.

### Ignoring the column (release M)

The first step is to ignore the column in the application code and remove all code references to it including
model validations.
This step is necessary because Rails caches the columns and re-uses this cache in various
places. This can be done by defining the columns to ignore. For example, in release `12.5`, to ignore
`updated_at` in the User model you'd use the following:

```ruby
class User < ApplicationRecord
  ignore_column :updated_at, remove_with: '12.7', remove_after: '2019-12-22'
end
```

Multiple columns can be ignored, too:

```ruby
ignore_columns %i[updated_at created_at], remove_with: '12.7', remove_after: '2019-12-22'
```

If the model exists in CE and EE, the column has to be ignored in the CE model. If the
model only exists in EE, then it has to be added there.

We require indication of when it is safe to remove the column ignore rule with:

- `remove_with`: set to a GitLab release typically two releases (M+2) (`12.7` in our example) after adding the
  column ignore.
- `remove_after`: set to a date after which we consider it safe to remove the column
  ignore, typically after the M+1 release date, during the M+2 development cycle. For example, since the development cycle of `12.7` is between `2019-12-18` and `2020-01-17`, and `12.6` is the release to [drop the column](#dropping-the-column-release-m1), it's safe to set the date to the release date of `12.6` as `2019-12-22`.

This information allows us to reason better about column ignores and makes sure we
don't remove column ignores too early for both regular releases and deployments to GitLab.com. For
example, this avoids a situation where we deploy a bulk of changes that include both changes
to ignore the column and subsequently remove the column ignore (which would result in a downtime).

In this example, the change to ignore the column went into release `12.5`.

NOTE:
Ignoring and dropping columns should not occur simultaneously in the same release. Dropping a column before proper ignoring it in the model can cause problems with zero-downtime migrations,
where the running instances can fail trying to look up for the removed column until the Rails schema cache expires. This can be an issue for self-managed customers whom attempt to follow zero-downtime upgrades,
forcing them to explicit restart all running GitLab instances to re-load the updated schema. To avoid this scenario, first, ignore the column (release M), then, drop it in the next release (release M+1).

### Dropping the column (release M+1)

Continuing our example, dropping the column goes into a _post-deployment_ migration in release `12.6`:

Start by creating the **post-deployment migration**:

```shell
bundle exec rails g post_deployment_migration remove_users_updated_at_column
```

You must consider these scenarios when you write a migration that removes a column:

- [The removed column has no indexes or constraints that belong to it](#the-removed-column-has-no-indexes-or-constraints-that-belong-to-it)
- [The removed column has an index or constraint that belongs to it](#the-removed-column-has-an-index-or-constraint-that-belongs-to-it)

#### The removed column has no indexes or constraints that belong to it

In this case, a **transactional migration** can be used:

```ruby
class RemoveUsersUpdatedAtColumn < Gitlab::Database::Migration[2.1]
  def up
    remove_column :users, :updated_at
  end

  def down
    add_column :users, :updated_at, :datetime
  end
end
```

#### The removed column has an index or constraint that belongs to it

If the `down` method requires adding back any dropped indexes or constraints, that cannot
be done in a transactional migration. The migration would look like this:

```ruby
class RemoveUsersUpdatedAtColumn < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    remove_column :users, :updated_at
  end

  def down
    add_column(:users, :updated_at, :datetime, if_not_exists: true)

    # Make sure to add back any indexes or constraints,
    # that were dropped in the `up` method. For example:
    add_concurrent_index(:users, :updated_at)
  end
end
```

In the `down` method, we check to see if the column already exists before adding it again.
We do this because the migration is non-transactional and might have failed while it was running.

The [`disable_ddl_transaction!`](../migration_style_guide.md#usage-with-non-transactional-migrations)
is used to disable the transaction that wraps the whole migration.

You can refer to the page [Migration Style Guide](../migration_style_guide.md)
for more information about database migrations.

### Removing the ignore rule (release M+2)

With the next release, in this example `12.7`, we set up another merge request to remove the ignore rule.
This removes the `ignore_column` line and - if not needed anymore - also the inclusion of `IgnoreableColumns`.

This should only get merged with the release indicated with `remove_with` and once
the `remove_after` date has passed.

## Renaming columns

Renaming columns the standard way requires downtime as an application may continue
to use the old column names during or after a database migration. To rename a column
without requiring downtime, we need two migrations: a regular migration and a
post-deployment migration. Both these migrations can go in the same release.
The steps:

1. [Add the regular migration](#add-the-regular-migration-release-m) (release M)
1. [Ignore the column](#ignore-the-column-release-m) (release M)
1. [Add a post-deployment migration](#add-a-post-deployment-migration-release-m) (release M)
1. [Remove the ignore rule](#remove-the-ignore-rule-release-m1) (release M+1)

### Add the regular migration (release M)

First we need to create the regular migration. This migration should use
`Gitlab::Database::MigrationHelpers#rename_column_concurrently` to perform the
renaming. For example

```ruby
# A regular migration in db/migrate
class RenameUsersUpdatedAtToUpdatedAtTimestamp < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :users, :updated_at, :updated_at_timestamp
  end

  def down
    undo_rename_column_concurrently :users, :updated_at, :updated_at_timestamp
  end
end
```

This takes care of renaming the column, ensuring data stays in sync, and
copying over indexes and foreign keys.

If a column contains one or more indexes that don't contain the name of the
original column, the previously described procedure fails. In that case,
you need to rename these indexes.

### Ignore the column (release M)

The next step is to ignore the column in the application code, and make sure it is not used. This step is
necessary because Rails caches the columns and re-uses this cache in various places.
This step is similar to [the first step when column is dropped](#ignoring-the-column-release-m), and the same requirements apply.

```ruby
class User < ApplicationRecord
  ignore_column :updated_at, remove_with: '12.7', remove_after: '2019-12-22'
end
```

### Add a post-deployment migration (release M)

The renaming procedure requires some cleaning up in a post-deployment migration.
We can perform this cleanup using
`Gitlab::Database::MigrationHelpers#cleanup_concurrent_column_rename`:

```ruby
# A post-deployment migration in db/post_migrate
class CleanupUsersUpdatedAtRename < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :users, :updated_at, :updated_at_timestamp
  end

  def down
    undo_cleanup_concurrent_column_rename :users, :updated_at, :updated_at_timestamp
  end
end
```

If you're renaming a [large table](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml#L3), carefully consider the state when the first migration has run but the second cleanup migration hasn't been run yet.
With [Canary](https://gitlab.com/gitlab-com/gl-infra/readiness/-/tree/master/library/canary/) it is possible that the system runs in this state for a significant amount of time.

### Remove the ignore rule (release M+1)

Same as when column is dropped, after the rename is completed, we need to [remove the ignore rule](#removing-the-ignore-rule-release-m2) in a subsequent release.

## Changing column constraints

Adding or removing a `NOT NULL` clause (or another constraint) can typically be
done without requiring downtime. Adding a `NOT NULL` constraint requires that any application
changes are deployed _first_, so it should happen in a post-deployment migration.
In contrary removing a `NOT NULL` constraint should be done in a regular migration.
This way any code which inserts `NULL` values can safely run for the column.

Avoid using `change_column` as it produces an inefficient query because it re-defines
the whole column type.

You can check the following guides for each specific use case:

- [Adding foreign-key constraints](../migration_style_guide.md#adding-foreign-key-constraints)
- [Adding `NOT NULL` constraints](not_null_constraints.md)
- [Adding limits to text columns](strings_and_the_text_data_type.md)

## Changing column types

Changing the type of a column can be done using
`Gitlab::Database::MigrationHelpers#change_column_type_concurrently`. This
method works similarly to `rename_column_concurrently`. For example, let's say
we want to change the type of `users.username` from `string` to `text`:

1. [Create a regular migration](#create-a-regular-migration)
1. [Create a post-deployment migration](#create-a-post-deployment-migration)
1. [Casting data to a new type](#casting-data-to-a-new-type)

### Create a regular migration

A regular migration is used to create a new column with a temporary name along
with setting up some triggers to keep data in sync. Such a migration would look
as follows:

```ruby
# A regular migration in db/migrate
class ChangeUsersUsernameStringToText < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    change_column_type_concurrently :users, :username, :text
  end

  def down
    undo_change_column_type_concurrently :users, :username
  end
end
```

### Create a post-deployment migration

Next we need to clean up our changes using a post-deployment migration:

```ruby
# A post-deployment migration in db/post_migrate
class ChangeUsersUsernameStringToTextCleanup < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_type_change :users, :username
  end

  def down
    undo_cleanup_concurrent_column_type_change :users, :username, :string
  end
end
```

And that's it, we're done!

### Casting data to a new type

Some type changes require casting data to a new type. For example when changing from `text` to `jsonb`.
In this case, use the `type_cast_function` option.
Make sure there is no bad data and the cast always succeeds. You can also provide a custom function that handles
casting errors.

Example migration:

```ruby
  def up
    change_column_type_concurrently :users, :settings, :jsonb, type_cast_function: 'jsonb'
  end
```

## Changing column defaults

Changing column defaults is difficult because of how Rails handles values
that are equal to the default.

NOTE:
Rails ignores sending the default values to PostgreSQL when inserting records, if the [partial_inserts](https://gitlab.com/gitlab-org/gitlab/-/blob/55ac06c9083434e6c18e0a2aaf8be5f189ef34eb/config/application.rb#L40) config has been enabled. It leaves this task to
the database. When migrations change the default values of the columns, the running application is unaware
of this change due to the schema cache. The application is then under the risk of accidentally writing
wrong data to the database, especially when deploying the new version of the code
long after we run database migrations.

If running code ever explicitly writes the old default value of a column, you must follow a multi-step
process to prevent Rails replacing the old default with the new default in INSERT queries that explicitly
specify the old default.

Doing this requires steps in two minor releases:

1. [Add the `SafelyChangeColumnDefault` concern to the model](#add-the-safelychangecolumndefault-concern-to-the-model-and-change-the-default-in-a-post-migration) and change the default in a post-migration.
1. [Clean up the `SafelyChangeColumnDefault` concern](#clean-up-the-safelychangecolumndefault-concern-in-the-next-minor-release) in the next minor release.

We must wait a minor release before cleaning up the `SafelyChangeColumnDefault` because self-managed
releases bundle an entire minor release into a single zero-downtime deployment.

### Add the `SafelyChangeColumnDefault` concern to the model and change the default in a post-migration

The first step is to mark the column as safe to change in application code.

```ruby
class Ci::Build < ApplicationRecord
  include SafelyChangeColumnDefault

  columns_changing_default :partition_id
end
```

Then create a **post-deployment migration** to change the default:

```shell
bundle exec rails g post_deployment_migration change_ci_builds_default
```

```ruby
class ChangeCiBuildsDefault < Gitlab::Database::Migration[2.1]
  def change
    change_column_default('ci_builds', 'partition_id', from: 100, to: 101)
  end
end
```

### Clean up the `SafelyChangeColumnDefault` concern in the next minor release

In the next minor release, create a new merge request to remove the `columns_changing_default` call. Also remove the `SafelyChangeColumnDefault` include
if it is not needed for a different column.

## Changing the schema for large tables

While `change_column_type_concurrently` and `rename_column_concurrently` can be
used for changing the schema of a table without downtime, it doesn't work very
well for large tables. Because all of the work happens in sequence the migration
can take a very long time to complete, preventing a deployment from proceeding.
They can also produce a lot of pressure on the database due to it rapidly
updating many rows in sequence.

To reduce database pressure you should instead use a background migration
when migrating a column in a large table (for example, `issues`). Background
migrations spread the work / load over a longer time period, without slowing
down deployments.

For more information, see [the documentation on cleaning up batched background migrations](batched_background_migrations.md#cleaning-up-a-batched-background-migration).

## Adding indexes

Adding indexes does not require downtime when `add_concurrent_index`
is used.

See also [Migration Style Guide](../migration_style_guide.md#adding-indexes)
for more information.

## Dropping indexes

Dropping an index does not require downtime.

## Adding tables

This operation is safe as there's no code using the table just yet.

## Dropping tables

Dropping tables can be done safely using a post-deployment migration, but only
if the application no longer uses the table.

Add the table to [`db/docs/deleted_tables`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/db/docs/deleted_tables) using the process described in [database dictionary](database_dictionary.md#dropping-tables).
Even though the table is deleted, it is still referenced in database migrations.

## Renaming tables

Renaming tables requires downtime as an application may continue
using the old table name during/after a database migration.

If the table and the ActiveRecord model is not in use yet, removing the old
table and creating a new one is the preferred way to "rename" the table.

Renaming a table is possible without downtime by following our multi-release
[rename table process](rename_database_tables.md).

## Adding foreign keys

Adding foreign keys usually works in 3 steps:

1. Start a transaction
1. Run `ALTER TABLE` to add the constraints
1. Check all existing data

Because `ALTER TABLE` typically acquires an exclusive lock until the end of a
transaction this means this approach would require downtime.

GitLab allows you to work around this by using
`Gitlab::Database::MigrationHelpers#add_concurrent_foreign_key`. This method
ensures that no downtime is needed.

## Removing foreign keys

This operation does not require downtime.

## Migrating `integer` primary keys to `bigint`

To [prevent the overflow risk](https://gitlab.com/groups/gitlab-org/-/epics/4785) for some tables
with `integer` primary key (PK), we have to migrate their PK to `bigint`. The process to do this
without downtime and causing too much load on the database is described below.

### Initialize the conversion and start migrating existing data (release N)

To start the process, add a regular migration to create the new `bigint` columns. Use the provided
`initialize_conversion_of_integer_to_bigint` helper. The helper also creates a database trigger
to keep in sync both columns for any new records ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/97aee76c4bfc2043dc0a1ef9ffbb71c58e0e2857/db/migrate/20230127093353_initialize_conversion_of_merge_request_metrics_to_bigint.rb)):

```ruby
# frozen_string_literal: true

class InitializeConversionOfMergeRequestMetricsToBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE = :merge_request_metrics
  COLUMNS = %i[id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
```

Ignore the new `bigint` columns:

```ruby
# frozen_string_literal: true

class MergeRequest::Metrics < ApplicationRecord
  ignore_column :id_convert_to_bigint, remove_with: '16.0', remove_after: '2023-05-22'
end
```

Enqueue batched background migration ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/97aee76c4bfc2043dc0a1ef9ffbb71c58e0e2857/db/post_migrate/20230127101834_backfill_merge_request_metrics_for_bigint_conversion.rb))
to migrate the existing data:

```ruby
# frozen_string_literal: true

class BackfillMergeRequestMetricsForBigintConversion < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE = :merge_request_metrics
  COLUMNS = %i[id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: 200)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
```

NOTES:

- With [Issue#438124](https://gitlab.com/gitlab-org/gitlab/-/issues/438124) new instances have all ID columns in bigint.
  The list of IDs yet to be converted to bigint in old instances (includes `Gitlab.com` SaaS) is maintained in `db/integer_ids_not_yet_initialized_to_bigint.yml`.
- Since the schema file already has all IDs in `bigint`, don't push any changes to `db/structure.sql`.

### Monitor the background migration

Check how the migration is performing while it's running. Multiple ways to do this are described below.

#### High-level status of batched background migrations

See how to [check the status of batched background migrations](../../update/background_migrations.md).

#### Query the database

We can query the related database tables directly. Requires access to read-only replica.
Example queries:

```sql
-- Get details for batched background migration for given table
SELECT * FROM batched_background_migrations WHERE table_name = 'namespaces'\gx

-- Get count of batched background migration jobs by status for given table
SELECT
  batched_background_migrations.id, batched_background_migration_jobs.status, COUNT(*)
FROM
  batched_background_migrations
  JOIN batched_background_migration_jobs ON batched_background_migrations.id = batched_background_migration_jobs.batched_background_migration_id
WHERE
  table_name = 'namespaces'
GROUP BY
  batched_background_migrations.id, batched_background_migration_jobs.status;

-- Batched background migration progress for given table (based on estimated total number of tuples)
SELECT
  m.table_name,
  LEAST(100 * sum(j.batch_size) / pg_class.reltuples, 100) AS percentage_complete
FROM
  batched_background_migrations m
  JOIN batched_background_migration_jobs j ON j.batched_background_migration_id = m.id
  JOIN pg_class ON pg_class.relname = m.table_name
WHERE
  j.status = 3 AND m.table_name = 'namespaces'
GROUP BY m.id, pg_class.reltuples;
```

#### Sidekiq logs

We can also use the Sidekiq logs to monitor the worker that executes the batched background
migrations:

1. Sign in to [Kibana](https://log.gprd.gitlab.net) with a `@gitlab.com` email address.
1. Change the index pattern to `pubsub-sidekiq-inf-gprd*`.
1. Add filter for `json.queue: cronjob:database_batched_background_migration`.

#### PostgreSQL slow queries log

Slow queries log keeps track of low queries that took above 1 second to execute. To see them
for batched background migration:

1. Sign in to [Kibana](https://log.gprd.gitlab.net) with a `@gitlab.com` email address.
1. Change the index pattern to `pubsub-postgres-inf-gprd*`.
1. Add filter for `json.endpoint_id.keyword: Database::BatchedBackgroundMigrationWorker`.
1. Optional. To see only updates, add a filter for `json.command_tag.keyword: UPDATE`.
1. Optional. To see only failed statements, add a filter for `json.error_severity.keyword: ERROR`.
1. Optional. Add a filter by table name.

#### Grafana dashboards

To monitor the health of the database, use these additional metrics:

- [PostgreSQL Tuple Statistics](https://dashboards.gitlab.net/d/000000167/postgresql-tuple-statistics?orgId=1&refresh=1m): if you see high rate of updates for the tables being actively converted, or increasing percentage of dead tuples for this table, it might mean that `autovacuum` cannot keep up.
- [PostgreSQL Overview](https://dashboards.gitlab.net/d/000000144/postgresql-overview?orgId=1): if you see high system usage or transactions per second (TPS) on the primary database server, it might mean that the migration is causing problems.

### Prometheus metrics

Number of [metrics](https://gitlab.com/gitlab-org/gitlab/-/blob/294a92484ce4611f660439aa48eee4dfec2230b5/lib/gitlab/database/background_migration/batched_migration_wrapper.rb#L90-128)
for each batched background migration are published to Prometheus. These metrics can be searched for and
visualized in Grafana ([see an example](https://dashboards.gitlab.net/explore?schemaVersion=1&panes=%7B%22m95%22:%7B%22datasource%22:%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22sum%20%28rate%28batched_migration_job_updated_tuples_total%7Benv%3D%5C%22gprd%5C%22%7D%5B5m%5D%29%29%20by%20%28migration_id%29%20%22,%22range%22:true,%22instant%22:true,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22%7D,%22editorMode%22:%22code%22,%22legendFormat%22:%22__auto%22%7D%5D,%22range%22:%7B%22from%22:%22now-3d%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)).

### Swap the columns (release N + 1)

After the background migration is complete and the new `bigint` columns are populated for all records, we can
swap the columns. Swapping is done with post-deployment migration. The exact process depends on the
table being converted, but in general it's done in the following steps:

1. Using the provided `ensure_backfill_conversion_of_integer_to_bigint_is_finished` helper, make sure the batched
   migration has finished.
   If the migration has not completed, the subsequent steps fail anyway. By checking in advance we
   aim to have more helpful error message.

   ```ruby
   disable_ddl_transaction!

   restrict_gitlab_migration gitlab_schema: :gitlab_ci

   def up
     ensure_backfill_conversion_of_integer_to_bigint_is_finished(
       :ci_builds,
       %i[
         project_id
         runner_id
         user_id
       ],
       # optional. Only needed when there is no primary key e.g. like schema_migrations
       primary_key: :id
     )
   end

   def down; end
   ```

1. Use the `add_bigint_column_indexes` helper method from `Gitlab::Database::MigrationHelpers::ConvertToBigint` module
   to create indexes with the `bigint` columns that match the existing indexes using the `integer` column.
   - The helper method is expected to create all required `bigint` indexes, but it's advised to recheck to make sure
     we are not missing any of the existing indexes. More information about the helper can be
     found in merge request [135781](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135781).
1. Create foreign keys (FK) using the `bigint` columns that match the existing FK using the
   `integer` column. Do this both for FK referencing other tables, and FK that reference the table
   that is being migrated ([see an example](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb#L36-43)).
1. Inside a transaction, swap the columns:
   1. Lock the tables involved. To reduce the chance of hitting a deadlock, we recommended to do this in parent to child order ([see an example](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb#L47)).
   1. Rename the columns to swap names ([see an example](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb#L49-54))
   1. Reset the trigger function ([see an example](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb#L56-57)).
   1. Swap the defaults ([see an example](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb#L59-62)).
   1. Swap the PK constraint (if any) ([see an example](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb#L64-68)).
   1. Remove old indexes and rename new ones ([see an example](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb#L70-72)).
      - Names of the `bigint` indexes created using `add_bigint_column_indexes` helper can be retrieved by calling
        `bigint_index_name` from `Gitlab::Database::MigrationHelpers::ConvertToBigint` module.
   1. Remove old foreign keys (if still present) and rename new ones ([see an example](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb#L74)).

See example [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66088), and [migration](https://gitlab.com/gitlab-org/gitlab/-/blob/41fbe34a4725a4e357a83fda66afb382828767b2/db/post_migrate/20210707210916_finalize_ci_stages_bigint_conversion.rb).

### Remove the trigger and old `integer` columns (release N + 2)

Using post-deployment migration and the provided `cleanup_conversion_of_integer_to_bigint` helper,
drop the database trigger and the old `integer` columns ([see an example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/70351)).

### Remove ignore rules (release N + 3)

In the next release after the columns were dropped, remove the ignore rules as we do not need them
anymore ([see an example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71161)).

## Data migrations

Data migrations can be tricky. The usual approach to migrate data is to take a 3
step approach:

1. Migrate the initial batch of data
1. Deploy the application code
1. Migrate any remaining data

Usually this works, but not always. For example, if a field's format is to be
changed from JSON to something else we have a bit of a problem. If we were to
change existing data before deploying application code we would most likely run
into errors. On the other hand, if we were to migrate after deploying the
application code we could run into the same problems.

If you merely need to correct some invalid data, then a post-deployment
migration is usually enough. If you need to change the format of data (for example, from
JSON to something else) it's typically best to add a new column for the new data
format, and have the application use that. In such a case the procedure would
be:

1. Add a new column in the new format
1. Copy over existing data to this new column
1. Deploy the application code
1. In a post-deployment migration, copy over any remaining data

In general there is no one-size-fits-all solution, therefore it's best to
discuss these kind of migrations in a merge request to make sure they are
implemented in the best way possible.
