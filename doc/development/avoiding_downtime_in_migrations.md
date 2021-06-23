---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Avoiding downtime in migrations

When working with a database certain operations may require downtime. Since we
cannot have downtime in migrations we need to use a set of steps to get the
same end result without downtime. This guide describes various operations that
may appear to need downtime, their impact, and how to perform them without
requiring downtime.

## Dropping Columns

Removing columns is tricky because running GitLab processes may still be using
the columns. To work around this safely, you will need three steps in three releases:

1. Ignoring the column (release M)
1. Dropping the column (release M+1)
1. Removing the ignore rule (release M+2)

The reason we spread this out across three releases is that dropping a column is
a destructive operation that can't be rolled back easily.

Following this procedure helps us to make sure there are no deployments to GitLab.com
and upgrade processes for self-managed installations that lump together any of these steps.

### Step 1: Ignoring the column (release M)

The first step is to ignore the column in the application code. This is
necessary because Rails caches the columns and re-uses this cache in various
places. This can be done by defining the columns to ignore. For example, to ignore
`updated_at` in the User model you'd use the following:

```ruby
class User < ApplicationRecord
  include IgnorableColumns
  ignore_column :updated_at, remove_with: '12.7', remove_after: '2020-01-22'
end
```

Multiple columns can be ignored, too:

```ruby
ignore_columns %i[updated_at created_at], remove_with: '12.7', remove_after: '2020-01-22'
```

We require indication of when it is safe to remove the column ignore with:

- `remove_with`: set to a GitLab release typically two releases (M+2) after adding the
  column ignore.
- `remove_after`: set to a date after which we consider it safe to remove the column
  ignore, typically after the M+1 release date, during the M+2 development cycle.

This information allows us to reason better about column ignores and makes sure we
don't remove column ignores too early for both regular releases and deployments to GitLab.com. For
example, this avoids a situation where we deploy a bulk of changes that include both changes
to ignore the column and subsequently remove the column ignore (which would result in a downtime).

In this example, the change to ignore the column went into release 12.5.

### Step 2: Dropping the column (release M+1)

Continuing our example, dropping the column goes into a _post-deployment_ migration in release 12.6:

```ruby
 remove_column :user, :updated_at
```

### Step 3: Removing the ignore rule (release M+2)

With the next release, in this example 12.7, we set up another merge request to remove the ignore rule.
This removes the `ignore_column` line and - if not needed anymore - also the inclusion of `IgnoreableColumns`.

This should only get merged with the release indicated with `remove_with` and once
the `remove_after` date has passed.

## Renaming Columns

Renaming columns the normal way requires downtime as an application may continue
using the old column name during/after a database migration. To rename a column
without requiring downtime we need two migrations: a regular migration, and a
post-deployment migration. Both these migration can go in the same release.

### Step 1: Add The Regular Migration

First we need to create the regular migration. This migration should use
`Gitlab::Database::MigrationHelpers#rename_column_concurrently` to perform the
renaming. For example

```ruby
# A regular migration in db/migrate
class RenameUsersUpdatedAtToUpdatedAtTimestamp < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    rename_column_concurrently :users, :updated_at, :updated_at_timestamp
  end

  def down
    undo_rename_column_concurrently :users, :updated_at, :updated_at_timestamp
  end
end
```

This will take care of renaming the column, ensuring data stays in sync, and
copying over indexes and foreign keys.

If a column contains one or more indexes that don't contain the name of the
original column, the previously described procedure will fail. In that case,
you'll first need to rename these indexes.

### Step 2: Add A Post-Deployment Migration

The renaming procedure requires some cleaning up in a post-deployment migration.
We can perform this cleanup using
`Gitlab::Database::MigrationHelpers#cleanup_concurrent_column_rename`:

```ruby
# A post-deployment migration in db/post_migrate
class CleanupUsersUpdatedAtRename < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :users, :updated_at, :updated_at_timestamp
  end

  def down
    undo_cleanup_concurrent_column_rename :users, :updated_at, :updated_at_timestamp
  end
end
```

If you're renaming a [large table](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml#L3), please carefully consider the state when the first migration has run but the second cleanup migration hasn't been run yet.
With [Canary](https://gitlab.com/gitlab-com/gl-infra/readiness/-/tree/master/library/canary/) it is possible that the system runs in this state for a significant amount of time.

## Changing Column Constraints

Adding or removing a `NOT NULL` clause (or another constraint) can typically be
done without requiring downtime. However, this does require that any application
changes are deployed _first_. Thus, changing the constraints of a column should
happen in a post-deployment migration.

Avoid using `change_column` as it produces an inefficient query because it re-defines
the whole column type.

You can check the following guides for each specific use case:

- [Adding foreign-key constraints](migration_style_guide.md#adding-foreign-key-constraints)
- [Adding `NOT NULL` constraints](database/not_null_constraints.md)
- [Adding limits to text columns](database/strings_and_the_text_data_type.md)

## Changing Column Types

Changing the type of a column can be done using
`Gitlab::Database::MigrationHelpers#change_column_type_concurrently`. This
method works similarly to `rename_column_concurrently`. For example, let's say
we want to change the type of `users.username` from `string` to `text`.

### Step 1: Create A Regular Migration

A regular migration is used to create a new column with a temporary name along
with setting up some triggers to keep data in sync. Such a migration would look
as follows:

```ruby
# A regular migration in db/migrate
class ChangeUsersUsernameStringToText < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    change_column_type_concurrently :users, :username, :text
  end

  def down
    undo_change_column_type_concurrently :users, :username
  end
end
```

### Step 2: Create A Post Deployment Migration

Next we need to clean up our changes using a post-deployment migration:

```ruby
# A post-deployment migration in db/post_migrate
class ChangeUsersUsernameStringToTextCleanup < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

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
Make sure there is no bad data and the cast will always succeed. You can also provide a custom function that handles
casting errors.

Example migration:

```ruby
  def up
    change_column_type_concurrently :users, :settings, :jsonb, type_cast_function: 'jsonb'
  end
```

## Changing The Schema For Large Tables

While `change_column_type_concurrently` and `rename_column_concurrently` can be
used for changing the schema of a table without downtime, it doesn't work very
well for large tables. Because all of the work happens in sequence the migration
can take a very long time to complete, preventing a deployment from proceeding.
They can also produce a lot of pressure on the database due to it rapidly
updating many rows in sequence.

To reduce database pressure you should instead use
`change_column_type_using_background_migration` or `rename_column_using_background_migration`
when migrating a column in a large table (e.g. `issues`). These methods work
similarly to the concurrent counterparts but uses background migration to spread
the work / load over a longer time period, without slowing down deployments.

For example, to change the column type using a background migration:

```ruby
class ExampleMigration < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'

    include EachBatch

    def self.to_migrate
      where('closed_at IS NOT NULL')
    end
  end

  def up
    change_column_type_using_background_migration(
      Issue.to_migrate,
      :closed_at,
      :datetime_with_timezone
    )
  end

  def down
    change_column_type_using_background_migration(
      Issue.to_migrate,
      :closed_at,
      :datetime
    )
  end
end
```

This would change the type of `issues.closed_at` to `timestamp with time zone`.

Keep in mind that the relation passed to
`change_column_type_using_background_migration` _must_ include `EachBatch`,
otherwise it will raise a `TypeError`.

This migration then needs to be followed in a separate release (_not_ a patch
release) by a cleanup migration, which should steal from the queue and handle
any remaining rows. For example:

```ruby
class MigrateRemainingIssuesClosedAt < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'
    include EachBatch
  end

  def up
    Gitlab::BackgroundMigration.steal('CopyColumn')
    Gitlab::BackgroundMigration.steal('CleanupConcurrentTypeChange')

    migrate_remaining_rows if migrate_column_type?
  end

  def down
    # Previous migrations already revert the changes made here.
  end

  def migrate_remaining_rows
    Issue.where('closed_at_for_type_change IS NULL AND closed_at IS NOT NULL').each_batch do |batch|
      batch.update_all('closed_at_for_type_change = closed_at')
    end

    cleanup_concurrent_column_type_change(:issues, :closed_at)
  end

  def migrate_column_type?
    # Some environments may have already executed the previous version of this
    # migration, thus we don't need to migrate those environments again.
    column_for('issues', 'closed_at').type == :datetime # rubocop:disable Migration/Datetime
  end
end
```

The same applies to `rename_column_using_background_migration`:

1. Create a migration using the helper, which will schedule background
   migrations to spread the writes over a longer period of time.
1. In the next monthly release, create a clean-up migration to steal from the
   Sidekiq queues, migrate any missing rows, and cleanup the rename. This
   migration should skip the steps after stealing from the Sidekiq queues if the
   column has already been renamed.

For more information, see [the documentation on cleaning up background
migrations](background_migrations.md#cleaning-up).

## Adding Indexes

Adding indexes does not require downtime when `add_concurrent_index`
is used.

See also [Migration Style Guide](migration_style_guide.md#adding-indexes)
for more information.

## Dropping Indexes

Dropping an index does not require downtime.

## Adding Tables

This operation is safe as there's no code using the table just yet.

## Dropping Tables

Dropping tables can be done safely using a post-deployment migration, but only
if the application no longer uses the table.

## Renaming Tables

Renaming tables requires downtime as an application may continue
using the old table name during/after a database migration.

If the table and the ActiveRecord model is not in use yet, removing the old
table and creating a new one is the preferred way to "rename" the table.

Renaming a table is possible without downtime by following our multi-release
[rename table process](database/rename_database_tables.md#rename-table-without-downtime).

## Adding Foreign Keys

Adding foreign keys usually works in 3 steps:

1. Start a transaction
1. Run `ALTER TABLE` to add the constraint(s)
1. Check all existing data

Because `ALTER TABLE` typically acquires an exclusive lock until the end of a
transaction this means this approach would require downtime.

GitLab allows you to work around this by using
`Gitlab::Database::MigrationHelpers#add_concurrent_foreign_key`. This method
ensures that no downtime is needed.

## Removing Foreign Keys

This operation does not require downtime.

## Data Migrations

Data migrations can be tricky. The usual approach to migrate data is to take a 3
step approach:

1. Migrate the initial batch of data
1. Deploy the application code
1. Migrate any remaining data

Usually this works, but not always. For example, if a field's format is to be
changed from JSON to something else we have a bit of a problem. If we were to
change existing data before deploying application code we'll most likely run
into errors. On the other hand, if we were to migrate after deploying the
application code we could run into the same problems.

If you merely need to correct some invalid data, then a post-deployment
migration is usually enough. If you need to change the format of data (e.g. from
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
