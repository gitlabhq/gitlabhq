# What requires downtime?

When working with a database certain operations can be performed without taking
GitLab offline, others do require a downtime period. This guide describes
various operations, their impact, and how to perform them without requiring
downtime.

## Adding Columns

You can safely add a new column to an existing table as long as it does **not**
have a default value. For example, this query would not require downtime:

```sql
ALTER TABLE projects ADD COLUMN random_value int;
```

Add a column _with_ a default however does require downtime. For example,
consider this query:

```sql
ALTER TABLE projects ADD COLUMN random_value int DEFAULT 42;
```

This requires updating every single row in the `projects` table so that
`random_value` is set to `42` by default. This requires updating all rows and
indexes in a table. This in turn acquires enough locks on the table for it to
effectively block any other queries.

Adding a column with a default value _can_ be done without requiring downtime
when using the migration helper method
`Gitlab::Database::MigrationHelpers#add_column_with_default`. This method works
similar to `add_column` except it updates existing rows in batches without
blocking access to the table being modified. See ["Adding Columns With Default
Values"](migration_style_guide.md#adding-columns-with-default-values) for more
information on how to use this method.

## Dropping Columns

Removing columns is tricky because running GitLab processes may still be using
the columns. To work around this safely, you will need three steps in three releases:

1. Ignoring the column (release M)
1. Dropping the column (release M+1)
1. Removing the ignore rule (release M+2)

The reason we spread this out across three releases is that dropping a column is
a destructive operation that can't be rolled back easily.

Following this procedure helps us to make sure there are no deployments to GitLab.com
and upgrade processes for self-hosted installations that lump together any of these steps.

### Step 1: Ignoring the column (release M)

The first step is to ignore the column in the application code. This is
necessary because Rails caches the columns and re-uses this cache in various
places. This can be done by defining the columns to ignore. For example, to ignore
`updated_at` in the User model you'd use the following:

```ruby
class User < ApplicationRecord
  include IgnorableColumns
  ignore_column :updated_at, remove_with: '12.7', remove_after: '2019-12-22'
end
```

Multiple columns can be ignored, too:

```ruby
ignore_columns %i[updated_at created_at], remove_with: '12.7', remove_after: '2019-12-22'
```

We require indication of when it is safe to remove the column ignore with:

- `remove_with`: set to a GitLab release typically two releases (M+2) after adding the
  column ignore.
- `remove_after`: set to a date after which we consider it safe to remove the column
  ignore, typically within the development cycle of release M+2.

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

This will take care of renaming the column, ensuring data stays in sync, copying
over indexes and foreign keys, etc.

**NOTE:** if a column contains 1 or more indexes that do not contain the name of
the original column, the above procedure will fail. In this case you will first
need to rename these indexes.

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

## Changing Column Constraints

Adding or removing a NOT NULL clause (or another constraint) can typically be
done without requiring downtime. However, this does require that any application
changes are deployed _first_. Thus, changing the constraints of a column should
happen in a post-deployment migration.
NOTE: Avoid using `change_column` as it produces inefficient query because it re-defines
the whole column type. For example, to add a NOT NULL constraint, prefer `change_column_null`

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
    cleanup_concurrent_column_type_change :users, :username
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
    cleanup_concurrent_column_type_change :users
  end

  def down
    change_column_type_concurrently :users, :username, :string
  end
end
```

And that's it, we're done!

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

  DOWNTIME = false

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

Adding indexes is an expensive process that blocks INSERT and UPDATE queries for
the duration. You can work around this by using the `CONCURRENTLY` option:

```sql
CREATE INDEX CONCURRENTLY index_name ON projects (column_name);
```

Migrations can take advantage of this by using the method
`add_concurrent_index`. For example:

```ruby
class MyMigration < ActiveRecord::Migration[4.2]
  def up
    add_concurrent_index :projects, :column_name
  end

  def down
    remove_index(:projects, :column_name) if index_exists?(:projects, :column_name)
  end
end
```

Note that `add_concurrent_index` can not be reversed automatically, thus you
need to manually define `up` and `down`.

## Dropping Indexes

Dropping an index does not require downtime.

## Adding Tables

This operation is safe as there's no code using the table just yet.

## Dropping Tables

Dropping tables can be done safely using a post-deployment migration, but only
if the application no longer uses the table.

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
