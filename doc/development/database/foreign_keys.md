---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Foreign keys and associations
---

When adding an association to a model you must also add a foreign key. For
example, say you have the following model:

```ruby
class User < ActiveRecord::Base
  has_many :posts
end
```

Add a foreign key here on column `posts.user_id`. This ensures
that data consistency is enforced on database level. Foreign keys also mean that
the database can very quickly remove associated data (for example, when removing a
user), instead of Rails having to do this.

## Adding foreign keys in migrations

Foreign keys can be added concurrently using `add_concurrent_foreign_key` as
defined in `Gitlab::Database::MigrationHelpers`. See the
[Migration Style Guide](../migration_style_guide.md) for more information.

Keep in mind that you can only safely add foreign keys to existing tables after
you have removed any orphaned rows. The method `add_concurrent_foreign_key`
does not take care of this so you must do so manually. See
[adding foreign key constraint to an existing column](add_foreign_key_to_existing_column.md).

## Use `bigint` for foreign keys

When adding a new foreign key, you should define it as `bigint`.
Even if the referenced table has an `integer` primary key type,
you must reference the new foreign key as `bigint`. As we are
migrating all primary keys to `bigint`, using `bigint` foreign keys
saves time, and requires fewer steps, when migrating the parent table
to `bigint` primary keys.

## Consider `reverse_lock_order`

Consider using `reverse_lock_order` for [high traffic tables](../migration_style_guide.md#high-traffic-tables)
Both `add_concurrent_foreign_key` and `remove_foreign_key_if_exists` take a
boolean option `reverse_lock_order` which defaults to false.

You can read more about the context for this in the
[the original issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67448).

This can be useful where we have known queries that are also acquiring locks
(usually row locks) on the same tables at a high frequency.

Consider, for example, the scenario where you want to add a foreign key like:

```sql
ALTER TABLE ONLY todos
    ADD CONSTRAINT fk_91d1f47b13 FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE;
```

And consider the following hypothetical application code:

```ruby
Todo.transaction do
   note = Note.create(...)
   # Observe what happens if foreign key is added here!
   todo = Todo.create!(note_id: note.id)
end
```

If you try to create the foreign key in between the 2 insert statements we can
end up with a deadlock on both transactions in Postgres. Here is how it happens:

1. `Note.create`: acquires a row lock on `notes`
1. `ALTER TABLE ...` acquires a table lock on `todos`
1. `ALTER TABLE ... FOREIGN KEY` attempts to acquire a table lock on `notes` but this blocks on the other transaction which has a row lock
1. `Todo.create` attempts to acquire a row lock on `todos` but this blocks on the other transaction which has a table lock on `todos`

This illustrates how both transactions can be stuck waiting for each other to
finish and they will both timeout. We normally have transaction retries in our
migrations so it is usually OK but the application code might also timeout and
there might be an error for that user. If this application code is running very
frequently it's possible that we will be constantly timing out the migration
and users may also be regularly getting errors.

The deadlock case with removing a foreign key is similar because it also
acquires locks on both tables but a more common scenario, using the example
above, would be a `DELETE FROM notes WHERE id = ...`. This query will acquire a
lock on `notes` followed by a lock on `todos` and the exact same deadlock
described above can happen. For this reason it's almost always best to use
`reverse_lock_order` for removing a foreign key.

## Updating foreign keys in migrations

Sometimes a foreign key constraint must be changed, preserving the column
but updating the constraint condition. For example, moving from
`ON DELETE CASCADE` to `ON DELETE SET NULL` or vice-versa.

PostgreSQL does not prevent you from adding overlapping foreign keys. It
honors the most recently added constraint. This allows us to replace foreign keys without
ever losing foreign key protection on a column.

To replace a foreign key:

1. Add the new foreign key:

   ```ruby
   class ReplaceFkOnPackagesPackagesProjectId < Gitlab::Database::Migration[2.1]
     disable_ddl_transaction!

     NEW_CONSTRAINT_NAME = 'fk_new'

     def up
       add_concurrent_foreign_key(:packages_packages, :projects, column: :project_id, on_delete: :nullify, name: NEW_CONSTRAINT_NAME)
     end

     def down
       with_lock_retries do
         remove_foreign_key_if_exists(:packages_packages, column: :project_id, on_delete: :nullify, name: NEW_CONSTRAINT_NAME)
       end
     end
   end
   ```

1. Remove the old foreign key:

   ```ruby
   class RemoveFkOld < Gitlab::Database::Migration[2.1]
     disable_ddl_transaction!

     OLD_CONSTRAINT_NAME = 'fk_old'

     def up
       with_lock_retries do
         remove_foreign_key_if_exists(:packages_packages, column: :project_id, on_delete: :cascade, name: OLD_CONSTRAINT_NAME)
       end
     end

     def down
       add_concurrent_foreign_key(:packages_packages, :projects, column: :project_id, on_delete: :cascade, name: OLD_CONSTRAINT_NAME)
     end
   end
   ```

## Cascading deletes

Every foreign key must define an `ON DELETE` clause, and in 99% of the cases
this should be set to `CASCADE`.

## Indexes

When adding a foreign key in PostgreSQL the column is not indexed automatically,
thus you must also add a concurrent index. Not doing so results in cascading
deletes being very slow.

## Naming foreign keys

By default Ruby on Rails uses the `_id` suffix for foreign keys. So we should
only use this suffix for associations between two tables. If you want to
reference an ID on a third party platform the `_xid` suffix is recommended.

The spec `spec/db/schema_spec.rb` tests if all columns with the `_id` suffix
have a foreign key constraint. So if that spec fails, don't add the column to
`IGNORED_FK_COLUMNS`, but instead add the FK constraint, or consider naming it
differently.

## Dependent removals

Don't define options such as `dependent: :destroy` or `dependent: :delete` when
defining an association. Defining these options means Rails handles the
removal of data, instead of letting the database handle this in the most
efficient way possible.

In other words, this is bad and should be avoided at all costs:

```ruby
class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
end
```

Should you truly have a need for this it should be approved by a database
specialist first.

You should also not define any `before_destroy` or `after_destroy` callbacks on
your models _unless_ absolutely required and only when approved by database
specialists. For example, if each row in a table has a corresponding file on a
file system it may be tempting to add a `after_destroy` hook. This however
introduces non database logic to a model, and means we can no longer rely on
foreign keys to remove the data as this would result in the file system data
being left behind. In such a case you should use a service class instead that
takes care of removing non database data.

In cases where the relation spans multiple databases you have even
further problems using `dependent: :destroy` or the above hooks. You can
read more about alternatives at
[Avoid `dependent: :nullify` and `dependent: :destroy` across databases](multiple_databases.md#avoid-dependent-nullify-and-dependent-destroy-across-databases).

## Alternative primary keys with `has_one` associations

Sometimes a `has_one` association is used to create a one-to-one relationship:

```ruby
class User < ActiveRecord::Base
  has_one :user_config
end

class UserConfig < ActiveRecord::Base
  belongs_to :user
end
```

In these cases, there may be an opportunity to remove the unnecessary `id`
column on the associated table, `user_config.id` in this example. Instead,
the originating table ID can be used as the primary key for the associated
table:

```ruby
create_table :user_configs, id: false do |t|
  t.references :users, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
  ...
end
```

Setting `default: nil` ensures a primary key sequence is not created, and because the primary key
automatically gets an index, we set `index: false` to avoid creating a duplicate.
You must also add the new primary key to the model:

```ruby
class UserConfig < ActiveRecord::Base
  self.primary_key = :user_id

  belongs_to :user
end
```

Using a foreign key as primary key saves space but can make
[batch counting](../internal_analytics/metrics/metrics_instrumentation.md#batch-counters-example) in [Service Ping](../internal_analytics/service_ping/_index.md) less efficient.
Consider using a regular `id` column if the table is relevant for Service Ping.
