# What requires downtime?

When working with a database certain operations can be performed without taking
GitLab offline, others do require a downtime period. This guide describes
various operations and their impact.

## Adding Columns

On PostgreSQL you can safely add a new column to an existing table as long as it
does **not** have a default value. For example, this query would not require
downtime:

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

As of MySQL 5.6 adding a column to a table is still quite an expensive
operation, even when using `ALGORITHM=INPLACE` and `LOCK=NONE`. This means
downtime _may_ be required when modifying large tables as otherwise the
operation could potentially take hours to complete.

Adding a column with a default value _can_ be done without requiring downtime
when using the migration helper method
`Gitlab::Database::MigrationHelpers#add_column_with_default`. This method works
similar to `add_column` except it updates existing rows in batches without
blocking access to the table being modified. See ["Adding Columns With Default
Values"](migration_style_guide.html#adding-columns-with-default-values) for more
information on how to use this method.

## Dropping Columns

On PostgreSQL you can safely remove an existing column without the need for
downtime. When you drop a column in PostgreSQL it's not immediately removed,
instead it is simply disabled. The data is removed on the next vacuum run.

On MySQL this operation requires downtime.

While database wise dropping a column may be fine on PostgreSQL this operation
still requires downtime because the application code may still be using the
column that was removed. For example, consider the following migration:

```ruby
class MyMigration < ActiveRecord::Migration
  def change
    remove_column :projects, :dummy
  end
end
```

Now imagine that the GitLab instance is running and actively uses the `dummy`
column. If we were to run the migration this would result in the GitLab instance
producing errors whenever it tries to use the `dummy` column.

As a result of the above downtime _is_ required when removing a column, even
when using PostgreSQL.

## Changing Column Constraints

Generally changing column constraints requires checking all rows in the table to
see if they meet the new constraint, unless a constraint is _removed_. For
example, changing a column that previously allowed NULL values to not allow NULL
values requires the database to verify all existing rows.

The specific behaviour varies a bit between databases but in general the safest
approach is to assume changing constraints requires downtime.

## Changing Column Types

This operation requires downtime.

## Adding Indexes

Adding indexes is an expensive process that blocks INSERT and UPDATE queries for
the duration. When using PostgreSQL one can work arounds this by using the
`CONCURRENTLY` option:

```sql
CREATE INDEX CONCURRENTLY index_name ON projects (column_name);
```

Migrations can take advantage of this by using the method
`add_concurrent_index`. For example:

```ruby
class MyMigration < ActiveRecord::Migration
  def change
    add_concurrent_index :projects, :column_name
  end
end
```

When running this on PostgreSQL the `CONCURRENTLY` option mentioned above is
used. On MySQL this method produces a regular `CREATE INDEX` query.

MySQL doesn't really have a workaround for this. Supposedly it _can_ create
indexes without the need for downtime but only for variable width columns. The
details on this are a bit sketchy. Since it's better to be safe than sorry one
should assume that adding indexes requires downtime on MySQL.

## Dropping Indexes

Dropping an index does not require downtime on both PostgreSQL and MySQL.

## Adding Tables

This operation is safe as there's no code using the table just yet.

## Dropping Tables

This operation requires downtime as application code may still be using the
table.

## Adding Foreign Keys

Adding foreign keys acquires an exclusive lock on both the source and target
tables in PostgreSQL. This requires downtime as otherwise the entire application
grinds to a halt for the duration of the operation.

On MySQL this operation also requires downtime _unless_ foreign key checks are
disabled. Because this means checks aren't enforced this is not ideal, as such
one should assume MySQL also requires downtime.

## Removing Foreign Keys

This operation should not require downtime on both PostgreSQL and MySQL.

## Updating Data

Updating data should generally be safe. The exception to this is data that's
being migrated from one version to another while the application still produces
data in the old version.

For example, imagine the application writes the string `'dog'` to a column but
it really is meant to write `'cat'` instead. One might think that the following
migration is all that is needed to solve this problem:

```ruby
class MyMigration < ActiveRecord::Migration
  def up
    execute("UPDATE some_table SET column = 'cat' WHERE column = 'dog';")
  end
end
```

Unfortunately this is not enough. Because the application is still running and
using the old value this may result in the table still containing rows where
`column` is set to `dog`, even after the migration finished.

In these cases downtime _is_ required, even for rarely updated tables.
