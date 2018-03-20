# Migration Style Guide

When writing migrations for GitLab, you have to take into account that
these will be ran by hundreds of thousands of organizations of all sizes, some with
many years of data in their database.

In addition, having to take a server offline for an upgrade small or big is a
big burden for most organizations. For this reason it is important that your
migrations are written carefully, can be applied online and adhere to the style
guide below.

Migrations are **not** allowed to require GitLab installations to be taken
offline unless _absolutely necessary_. Downtime assumptions should be based on
the behaviour of a migration when performed using PostgreSQL, as various
operations in MySQL may require downtime without there being alternatives.

When downtime is necessary the migration has to be approved by:

1. The VP of Engineering
1. A Backend Lead
1. A Database Specialist

An up-to-date list of people holding these titles can be found at
<https://about.gitlab.com/team/>.

The document ["What Requires Downtime?"](what_requires_downtime.md) specifies
various database operations, whether they require downtime and how to
work around that whenever possible.

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

## Downtime Tagging

Every migration must specify if it requires downtime or not, and if it should
require downtime it must also specify a reason for this. This is required even
if 99% of the migrations won't require downtime as this makes it easier to find
the migrations that _do_ require downtime.

To tag a migration, add the following two constants to the migration class'
body:

* `DOWNTIME`: a boolean that when set to `true` indicates the migration requires
  downtime.
* `DOWNTIME_REASON`: a String containing the reason for the migration requiring
  downtime. This constant **must** be set when `DOWNTIME` is set to `true`.

For example:

```ruby
class MyMigration < ActiveRecord::Migration
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

## Multi Threading

Sometimes a migration might need to use multiple Ruby threads to speed up a
migration. For this to work your migration needs to include the module
`Gitlab::Database::MultiThreadedMigration`:

```ruby
class MyMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::MultiThreadedMigration
end
```

You can then use the method `with_multiple_threads` to perform work in separate
threads. For example:

```ruby
class MyMigration < ActiveRecord::Migration
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
limit can vary from installation to installation. As a result it's recommended
you do not use more than 32 threads in a single migration. Usually 4-8 threads
should be more than enough.

## Removing indexes

When removing an index make sure to use the method `remove_concurrent_index` instead
of the regular `remove_index` method. The `remove_concurrent_index` method
automatically drops concurrent indexes when using PostgreSQL, removing the
need for downtime. To use this method you must disable transactions by calling
the method `disable_ddl_transaction!` in the body of your migration class like
so:

```ruby
class MyMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def up
    remove_concurrent_index :table_name, :column_name
  end
end
```

Note that it is not necessary to check if the index exists prior to
removing it.

## Adding indexes

If you need to add a unique index please keep in mind there is the possibility
of existing duplicates being present in the database. This means that should
always _first_ add a migration that removes any duplicates, before adding the
unique index.

When adding an index make sure to use the method `add_concurrent_index` instead
of the regular `add_index` method. The `add_concurrent_index` method
automatically creates concurrent indexes when using PostgreSQL, removing the
need for downtime. To use this method you must disable transactions by calling
the method `disable_ddl_transaction!` in the body of your migration class like
so:

```ruby
class MyMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_index :table, :column
  end

  def down
    remove_index :table, :column if index_exists?(:table, :column)
  end
end
```

## Adding Columns With Default Values

When adding columns with default values you must use the method
`add_column_with_default`. This method ensures the table is updated without
requiring downtime. This method is not reversible so you must manually define
the `up` and `down` methods in your migration class.

For example, to add the column `foo` to the `projects` table with a default
value of `10` you'd write the following:

```ruby
class MyMigration < ActiveRecord::Migration
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
larger installations (e.g. GitLab.com). As a result you should only add default
values if absolutely necessary. There is a RuboCop cop that will fail if this
method is used on some tables that are very large on GitLab.com, which would
cause other issues.

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

To perform a computed update, the value can be wrapped in `Arel.sql`, so Arel
treats it as an SQL literal. The below example is the same as the one above, but
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
hold file sizes in byte units. If you are tracking file size in bytes this
restricts the maximum file size to just over 2GB.

To allow an integer column to hold up to an 8-byte (64-bit) number, explicitly
set the limit to 8-bytes. This will allow the column to hold a value up to
9,223,372,036,854,775,807.

Rails migration example:

```ruby
add_column_with_default(:projects, :foo, :integer, default: 10, limit: 8)

# or

add_column(:projects, :foo, :integer, default: 10, limit: 8)
```

## Timestamp column type

By default, Rails uses the `timestamp` data type that stores timestamp data without timezone information.
The `timestamp` data type is used by calling either the `add_timestamps` or the `timestamps` method.
Also Rails converts the `:datetime` data type to the `timestamp` one.

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

Instead of using these methods one should use the following methods to store timestamps with timezones:

* `add_timestamps_with_timezone`
* `timestamps_with_timezone`

This ensures all timestamps have a time zone specified. This in turn means existing timestamps won't
suddenly use a different timezone when the system's timezone changes. It also makes it very clear which
timezone was used in the first place.


## Testing

Make sure that your migration works with MySQL and PostgreSQL with data. An
empty database does not guarantee that your migration is correct.

Make sure your migration can be reversed.

## Data migration

Please prefer Arel and plain SQL over usual ActiveRecord syntax. In case of
using plain SQL you need to quote all input manually with `quote_string` helper.

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

If you need more complex logic you can define and use models local to a
migration. For example:

```ruby
class MyMigration < ActiveRecord::Migration
  class Project < ActiveRecord::Base
    self.table_name = 'projects'
  end
end
```

When doing so be sure to explicitly set the model's table name so it's not
derived from the class name or namespace.

### Renaming reserved paths

When a new route for projects is introduced that could conflict with any
existing records. The path for this records should be renamed, and the
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
