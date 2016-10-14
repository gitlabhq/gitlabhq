# Migration Style Guide

When writing migrations for GitLab, you have to take into account that
these will be ran by hundreds of thousands of organizations of all sizes, some with
many years of data in their database.

In addition, having to take a server offline for a an upgrade small or big is
a big burden for most organizations. For this reason it is important that your
migrations are written carefully, can be applied online and adhere to the style guide below.

Migrations should not require GitLab installations to be taken offline unless
_absolutely_ necessary - see the ["What Requires Downtime?"](what_requires_downtime.md)
page. If a migration requires downtime, this should be clearly mentioned during
the review process, as well as being documented in the monthly release post. For
more information, see the "Downtime Tagging" section below.

When writing your migrations, also consider that databases might have stale data
or inconsistencies and guard for that. Try to make as little assumptions as possible
about the state of the database.

Please don't depend on GitLab specific code since it can change in future versions.
If needed copy-paste GitLab code into the migration to make it forward compatible.

## Downtime Tagging

Every migration must specify if it requires downtime or not, and if it should
require downtime it must also specify a reason for this. To do so, add the
following two constants to the migration class' body:

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

Your migration should be reversible. This is very important, as it should
be possible to downgrade in case of a vulnerability or bugs.

In your migration, add a comment describing how the reversibility of the
migration was tested.

## Removing indices

If you need to remove index, please add a condition like in following example:

```
remove_index :namespaces, column: :name if index_exists?(:namespaces, :name)
```

## Adding indices

If you need to add an unique index please keep in mind there is possibility of existing duplicates. If it is possible write a separate migration for handling this situation. It can be just removing or removing with overwriting all references to these duplicates depend on situation.

When adding an index make sure to use the method `add_concurrent_index` instead
of the regular `add_index` method. The `add_concurrent_index` method
automatically creates concurrent indexes when using PostgreSQL, removing the
need for downtime. To use this method you must disable transactions by calling
the method `disable_ddl_transaction!` in the body of your migration class like
so:

```
class MyMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  def change

  end
end
```

## Adding Columns With Default Values

When adding columns with default values you should use the method
`add_column_with_default`. This method ensures the table is updated without
requiring downtime. This method is not reversible so you must manually define
the `up` and `down` methods in your migration class.

For example, to add the column `foo` to the `projects` table with a default
value of `10` you'd write the following:

```
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


## Integer column type

By default, an integer column can hold up to a 4-byte (32-bit) number. That is
a max value of 2,147,483,647. Be aware of this when creating a column that will
hold file sizes in byte units. If you are tracking file size in bytes this
restricts the maximum file size to just over 2GB.

To allow an integer column to hold up to an 8-byte (64-bit) number, explicitly
set the limit to 8-bytes. This will allow the column to hold a value up to
9,223,372,036,854,775,807.

Rails migration example:

```
add_column_with_default(:projects, :foo, :integer, default: 10, limit: 8)

# or

add_column(:projects, :foo, :integer, default: 10, limit: 8)
```

## Testing

Make sure that your migration works with MySQL and PostgreSQL with data. An empty database does not guarantee that your migration is correct.

Make sure your migration can be reversed.

## Data migration

Please prefer Arel and plain SQL over usual ActiveRecord syntax. In case of using plain SQL you need to quote all input manually with `quote_string` helper.

Example with Arel:

```
users = Arel::Table.new(:users)
users.group(users[:user_id]).having(users[:id].count.gt(5))

#update other tables with these results
```

Example with plain SQL and `quote_string` helper:

```
select_all("SELECT name, COUNT(id) as cnt FROM tags GROUP BY name HAVING COUNT(id) > 1").each do |tag|
  tag_name = quote_string(tag["name"])
  duplicate_ids = select_all("SELECT id FROM tags WHERE name = '#{tag_name}'").map{|tag| tag["id"]}
  origin_tag_id = duplicate_ids.first
  duplicate_ids.delete origin_tag_id

  execute("UPDATE taggings SET tag_id = #{origin_tag_id} WHERE tag_id IN(#{duplicate_ids.join(",")})")
  execute("DELETE FROM tags WHERE id IN(#{duplicate_ids.join(",")})")
end
```
