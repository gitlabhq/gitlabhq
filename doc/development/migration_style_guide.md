# Migration Style Guide

When writing migrations for GitLab, you have to take into account that
these will be ran by hundreds of thousands of organizations of all sizes, some with
many years of data in their database.

In addition, having to take a server offline for a an upgrade small or big is
a big burden for most organizations. For this reason it is important that your
migrations are written carefully, can be applied online and adhere to the style guide below.

Migrations should not require GitLab installations to be taken offline unless
_absolutely_ necessary. If a migration requires downtime this should be
clearly mentioned during the review process as well as being documented in the
monthly release post.

When writing your migrations, also consider that databases might have stale data
or inconsistencies and guard for that. Try to make as little assumptions as possible
about the state of the database.

Please don't depend on GitLab specific code since it can change in future versions.
If needed copy-paste GitLab code into the migration to make it forward compatible.

## Comments in the migration

Each migration you write needs to have the two following pieces of information
as comments.

### Online, Offline, errors?

First, you need to provide information on whether the migration can be applied:

1. online without errors (works on previous version and new one)
2. online with errors on old instances after migrating
3. online with errors on new instances while migrating
4. offline (needs to happen without app servers to prevent db corruption)

For example: 

```
# Migration type: online without errors (works on previous version and new one)
class MyMigration < ActiveRecord::Migration
...
```

It is always preferable to have a migration run online. If you expect the migration
to take particularly long (for instance, if it loops through all notes),
this is valuable information to add.

If you don't provide the information it means that a migration is safe to run online.

### Reversibility

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
