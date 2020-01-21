# Migration Style Guide

When writing migrations for GitLab, you have to take into account that
these will be run by hundreds of thousands of organizations of all sizes, some with
many years of data in their database.

In addition, having to take a server offline for an upgrade small or big is a
big burden for most organizations. For this reason, it is important that your
migrations are written carefully, can be applied online, and adhere to the style
guide below.

Migrations are **not** allowed to require GitLab installations to be taken
offline unless _absolutely necessary_.

When downtime is necessary the migration has to be approved by:

1. The VP of Engineering
1. A Backend Lead
1. A Database Specialist

An up-to-date list of people holding these titles can be found at
<https://about.gitlab.com/company/team/>.

When writing your migrations, also consider that databases might have stale data
or inconsistencies and guard for that. Try to make as few assumptions as
possible about the state of the database.

Please don't depend on GitLab-specific code since it can change in future
versions. If needed copy-paste GitLab code into the migration to make it forward
compatible.

## Schema Changes

Migrations that make changes to the database schema (e.g. adding a column) can
only be added in the monthly release, patch releases may only contain data
migrations _unless_ schema changes are absolutely required to solve a problem.

## What Requires Downtime?

The document ["What Requires Downtime?"](what_requires_downtime.md) specifies
various database operations, such as

- [adding, dropping, and renaming columns](what_requires_downtime.md#adding-columns)
- [changing column constraints and types](what_requires_downtime.md#changing-column-constraints)
- [adding and dropping indexes, tables, and foreign keys](what_requires_downtime.md#adding-indexes)

and whether they require downtime and how to work around that whenever possible.

## Downtime Tagging

Every migration must specify if it requires downtime or not, and if it should
require downtime it must also specify a reason for this. This is required even
if 99% of the migrations won't require downtime as this makes it easier to find
the migrations that _do_ require downtime.

To tag a migration, add the following two constants to the migration class'
body:

- `DOWNTIME`: a boolean that when set to `true` indicates the migration requires
  downtime.
- `DOWNTIME_REASON`: a String containing the reason for the migration requiring
  downtime. This constant **must** be set when `DOWNTIME` is set to `true`.

For example:

```ruby
class MyMigration < ActiveRecord::Migration[4.2]
  DOWNTIME = true
  DOWNTIME_REASON = 'This migration requires downtime because ...'

  def change
    ...
  end
end
```

It is an error (that is, CI will fail) if the `DOWNTIME` constant is missing
from a migration class.

## Reversibility

Your migration **must be** reversible. This is very important, as it should
be possible to downgrade in case of a vulnerability or bugs.

In your migration, add a comment describing how the reversibility of the
migration was tested.

## Atomicity

By default, migrations are single transaction. That is, a transaction is opened
at the beginning of the migration, and committed after all steps are processed.

Running migrations in a single transaction makes sure that if one of the steps fails,
none of the steps will be executed, leaving the database in valid state.
Therefore, either:

- Put all migrations in one single-transaction migration.
- If necessary, put most actions in one migration and create a separate migration
  for the steps that cannot be done in a single transaction.

For example, if you create an empty table and need to build an index for it,
it is recommended to use a regular single-transaction migration and the default
rails schema statement: [`add_index`](https://api.rubyonrails.org/v5.2/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_index).
This is a blocking operation, but it won't cause problems because the table is not yet used,
and therefore it does not have any records yet.

## Heavy operations in a single transaction

When using a single-transaction migration, a transaction will hold on a database connection
for the duration of the migration, so you must make sure the actions in the migration
do not take too much time: In general, queries executed in a migration need to fit comfortably
within `15s` on GitLab.com.

In case you need to insert, update, or delete a significant amount of data, you:

- Must disable the single transaction with `disable_ddl_transaction!`.
- Should consider doing it in a [Background Migration](background_migrations.md).

## Multi-Threading

Sometimes a migration might need to use multiple Ruby threads to speed up a
migration. For this to work your migration needs to include the module
`Gitlab::Database::MultiThreadedMigration`:

```ruby
class MyMigration < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::MultiThreadedMigration
end
```

You can then use the method `with_multiple_threads` to perform work in separate
threads. For example:

```ruby
class MyMigration < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::MultiThreadedMigration

  def up
    with_multiple_threads(4) do
      disable_statement_timeout

      # ...
    end
  end
end
```

Here the call to `disable_statement_timeout` will use the connection local to
the `with_multiple_threads` block, instead of re-using the global connection
pool.  This ensures each thread has its own connection object, and won't time
out when trying to obtain one.

**NOTE:** PostgreSQL has a maximum amount of connections that it allows. This
limit can vary from installation to installation. As a result, it's recommended
you do not use more than 32 threads in a single migration. Usually, 4-8 threads
should be more than enough.

## Removing indexes

If the table is not empty when removing an index, make sure to use the method
`remove_concurrent_index` instead of the regular `remove_index` method.
The `remove_concurrent_index` method drops indexes concurrently, so no locking is required,
and there is no need for downtime. To use this method, you must disable single-transaction mode
by calling the method `disable_ddl_transaction!` in the body of your migration
class like so:

```ruby
class MyMigration < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    remove_concurrent_index :table_name, :column_name
  end
end
```

Note that it is not necessary to check if the index exists prior to
removing it.

For a small table (such as an empty one or one with less than `1,000` records),
it is recommended to use `remove_index` in a single-transaction migration,
combining it with other operations that don't require `disable_ddl_transaction!`.

## Adding indexes

If you need to add a unique index, please keep in mind there is the possibility
of existing duplicates being present in the database. This means that should
always _first_ add a migration that removes any duplicates, before adding the
unique index.

When adding an index to a non-empty table make sure to use the method
`add_concurrent_index` instead of the regular `add_index` method.
The `add_concurrent_index` method automatically creates concurrent indexes
when using PostgreSQL, removing the need for downtime.

To use this method, you must disable single-transactions mode
by calling the method `disable_ddl_transaction!` in the body of your migration
class like so:

```ruby
class MyMigration < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_index :table, :column
  end

  def down
    remove_concurrent_index :table, :column
  end
end
```

For a small table (such as an empty one or one with less than `1,000` records),
it is recommended to use `add_index` in a single-transaction migration, combining it with other
operations that don't require `disable_ddl_transaction!`.

## Adding foreign-key constraints

When adding a foreign-key constraint to either an existing or a new column also
remember to add an index on the column.

This is **required** for all foreign-keys, e.g., to support efficient cascading
deleting: when a lot of rows in a table get deleted, the referenced records need
to be deleted too. The database has to look for corresponding records in the
referenced table. Without an index, this will result in a sequential scan on the
table, which can take a long time.

Here's an example where we add a new column with a foreign key
constraint. Note it includes `index: true` to create an index for it.

```ruby
class Migration < ActiveRecord::Migration[4.2]

  def change
    add_reference :model, :other_model, index: true, foreign_key: { on_delete: :cascade }
  end
end
```

When adding a foreign-key constraint to an existing column in a non-empty table,
we have to employ `add_concurrent_foreign_key` and `add_concurrent_index`
instead of `add_reference`.

For an empty table (such as a fresh one), it is recommended to use
`add_reference` in a single-transaction migration, combining it with other
operations that don't require `disable_ddl_transaction!`.

## Adding Columns With Default Values

When adding columns with default values to non-empty tables, you must use
`add_column_with_default`. This method ensures the table is updated without
requiring downtime. This method is not reversible so you must manually define
the `up` and `down` methods in your migration class.

For example, to add the column `foo` to the `projects` table with a default
value of `10` you'd write the following:

```ruby
class MyMigration < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    add_column_with_default(:projects, :foo, :integer, default: 10)
  end

  def down
    remove_column(:projects, :foo)
  end
end
```

Keep in mind that this operation can easily take 10-15 minutes to complete on
larger installations (e.g. GitLab.com). As a result, you should only add
default values if absolutely necessary. There is a RuboCop cop that will fail if
this method is used on some tables that are very large on GitLab.com, which
would cause other issues.

For a small table (such as an empty one or one with less than `1,000` records),
use `add_column` and `change_column_default` in a single-transaction migration,
combining it with other operations that don't require `disable_ddl_transaction!`.

## Changing the column default

One might think that changing a default column with `change_column_default` is an
expensive and disruptive operation for larger tables, but in reality it's not.

Take the following migration as an example:

```ruby
class DefaultRequestAccessGroups < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :namespaces, :request_access_enabled, true
  end

  def down
    change_column_default :namespaces, :request_access_enabled, false
  end
end
```

Migration above changes the default column value of one of our largest
tables: `namespaces`. This can be translated to:

```sql
ALTER TABLE namespaces
ALTER COLUMN request_access_enabled
DEFAULT false
```

In this particular case, the default value exists and we're just changing the metadata for
`request_access_enabled` column, which does not imply a rewrite of all the existing records
in the `namespaces` table. Only when creating a new column with a default, all the records are going be rewritten.

NOTE: **Note:**  A faster [ALTER TABLE ADD COLUMN with a non-null default](https://www.depesz.com/2018/04/04/waiting-for-postgresql-11-fast-alter-table-add-column-with-a-non-null-default/)
was introduced on PostgresSQL 11.0, removing the need of rewriting the table when a new column with a default value is added.

For the reasons mentioned above, it's safe to use `change_column_default` in a single-transaction migration
without requiring `disable_ddl_transaction!`.

## Updating an existing column

To update an existing column to a particular value, you can use
`update_column_in_batches` (`add_column_with_default` uses this internally to
fill in the default value). This will split the updates into batches, so we
don't update too many rows at in a single statement.

This updates the column `foo` in the `projects` table to 10, where `some_column`
is `'hello'`:

```ruby
update_column_in_batches(:projects, :foo, 10) do |table, query|
  query.where(table[:some_column].eq('hello'))
end
```

If a computed update is needed, the value can be wrapped in `Arel.sql`, so Arel
treats it as an SQL literal. It's also a required deprecation for [Rails 6](https://gitlab.com/gitlab-org/gitlab-foss/issues/61451).

The below example is the same as the one above, but
the value is set to the product of the `bar` and `baz` columns:

```ruby
update_value = Arel.sql('bar * baz')

update_column_in_batches(:projects, :foo, update_value) do |table, query|
  query.where(table[:some_column].eq('hello'))
end
```

Like `add_column_with_default`, there is a RuboCop cop to detect usage of this
on large tables. In the case of `update_column_in_batches`, it may be acceptable
to run on a large table, as long as it is only updating a small subset of the
rows in the table, but do not ignore that without validating on the GitLab.com
staging environment - or asking someone else to do so for you - beforehand.

## Integer column type

By default, an integer column can hold up to a 4-byte (32-bit) number. That is
a max value of 2,147,483,647. Be aware of this when creating a column that will
hold file sizes in byte units. If you are tracking file size in bytes, this
restricts the maximum file size to just over 2GB.

To allow an integer column to hold up to an 8-byte (64-bit) number, explicitly
set the limit to 8-bytes. This will allow the column to hold a value up to
`9,223,372,036,854,775,807`.

Rails migration example:

```ruby
add_column_with_default(:projects, :foo, :integer, default: 10, limit: 8)

# or

add_column(:projects, :foo, :integer, default: 10, limit: 8)
```

## Timestamp column type

By default, Rails uses the `timestamp` data type that stores timestamp data
without timezone information. The `timestamp` data type is used by calling
either the `add_timestamps` or the `timestamps` method.

Also, Rails converts the `:datetime` data type to the `timestamp` one.

Example:

```ruby
# timestamps
create_table :users do |t|
  t.timestamps
end

# add_timestamps
def up
  add_timestamps :users
end

# :datetime
def up
  add_column :users, :last_sign_in, :datetime
end
```

Instead of using these methods, one should use the following methods to store
timestamps with timezones:

- `add_timestamps_with_timezone`
- `timestamps_with_timezone`
- `datetime_with_timezone`

This ensures all timestamps have a time zone specified. This, in turn, means
existing timestamps won't suddenly use a different timezone when the system's
timezone changes. It also makes it very clear which timezone was used in the
first place.

## Storing JSON in database

The Rails 5 natively supports `JSONB` (binary JSON) column type.
Example migration adding this column:

```ruby
class AddOptionsToBuildMetadata < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :ci_builds_metadata, :config_options, :jsonb
  end
end
```

You have to use a serializer to provide a translation layer:

```ruby
class BuildMetadata
  serialize :config_options, Serializers::JSON # rubocop:disable Cop/ActiveRecordSerialize
end
```

## Testing

See the [Testing Rails migrations](testing_guide/testing_migrations_guide.md) style guide.

## Data migration

Please prefer Arel and plain SQL over usual ActiveRecord syntax. In case of
using plain SQL, you need to quote all input manually with `quote_string` helper.

Example with Arel:

```ruby
users = Arel::Table.new(:users)
users.group(users[:user_id]).having(users[:id].count.gt(5))

#update other tables with these results
```

Example with plain SQL and `quote_string` helper:

```ruby
select_all("SELECT name, COUNT(id) as cnt FROM tags GROUP BY name HAVING COUNT(id) > 1").each do |tag|
  tag_name = quote_string(tag["name"])
  duplicate_ids = select_all("SELECT id FROM tags WHERE name = '#{tag_name}'").map{|tag| tag["id"]}
  origin_tag_id = duplicate_ids.first
  duplicate_ids.delete origin_tag_id

  execute("UPDATE taggings SET tag_id = #{origin_tag_id} WHERE tag_id IN(#{duplicate_ids.join(",")})")
  execute("DELETE FROM tags WHERE id IN(#{duplicate_ids.join(",")})")
end
```

If you need more complex logic, you can define and use models local to a
migration. For example:

```ruby
class MyMigration < ActiveRecord::Migration[4.2]
  class Project < ActiveRecord::Base
    self.table_name = 'projects'
  end
end
```

When doing so be sure to explicitly set the model's table name, so it's not
derived from the class name or namespace.

### Renaming reserved paths

When a new route for projects is introduced, it could conflict with any
existing records. The path for these records should be renamed, and the
related data should be moved on disk.

Since we had to do this a few times already, there are now some helpers to help
with this.

To use this you can include `Gitlab::Database::RenameReservedPathsMigration::V1`
in your migration. This will provide 3 methods which you can pass one or more
paths that need to be rejected.

**`rename_root_paths`**: This will rename the path of all _namespaces_ with the
given name that don't have a `parent_id`.

**`rename_child_paths`**: This will rename the path of all _namespaces_ with the
given name that have a `parent_id`.

**`rename_wildcard_paths`**: This will rename the path of all _projects_, and all
_namespaces_ that have a `project_id`.

The `path` column for these rows will be renamed to their previous value followed
by an integer. For example: `users` would turn into `users0`
