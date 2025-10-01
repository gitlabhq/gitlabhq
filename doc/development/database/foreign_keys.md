---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Foreign keys and associations
---

Foreign keys ensure consistency between related database tables. Starting with Rails version 4, Rails includes migration helpers to add foreign key constraints
to database tables. Before Rails 4, the only way for ensuring some level of consistency was the
[`dependent`](https://guides.rubyonrails.org/association_basics.html#options-for-belongs-to-dependent)
option in the association definition.

Ensuring data consistency on the application level could fail
in some unfortunate cases, so we might end up with inconsistent data in the table. This mostly affects
older tables, where we didn't have the framework support to ensure consistency on the database level.
These data inconsistencies can cause unexpected application behavior or bugs.

When creating tables that reference records from other tables, a FK should be added to maintain data integrity.
And when adding an association to a model you must also add a foreign key. Also on
adding a foreign key you must always add an [index](#indexes) first.

For example, say you have the following model:

```ruby
class User < ActiveRecord::Base
  has_many :posts
end
```

Add a foreign key here on column `posts.user_id`. This ensures
that data consistency is enforced on database level. Foreign keys also mean that
the database can remove associated data (for example, when removing a
user), instead of Rails having to do this.

## Avoiding downtime and migration failures

Adding a foreign key has two parts to it

1. Adding the FK column and the constraint.
1. Validating the added constraint to maintain data integrity.

(1) uses ALTER TABLE statements which takes the most strict lock (ACCESS EXCLUSIVE) and validating the constraint has to
traverse the entire table which will be time consuming for large/high-traffic tables.

So in almost all cases we have to run them in separate transactions to avoid holding the
stricter lock and blocking other operations on the tables for a longer time.

### On a new column

If the FK is added while creating the table, it is straight forward and
`create_table (t.references, ..., foreign_key: true)` can be used.

If you have a new (without much records) or empty table that doesn't reference a
[high-traffic table](../migration_style_guide.md#high-traffic-tables), either of below approaches can be used.

1. add_reference(... foreign_key: true)
1. add_column(...) and add_foreign_key(...) in the same transaction.

For all other cases, adding the column, adding FK constraint and validating the constraint should be done in
separate transactions.

### On an existing column

Adding a foreign key to an existing database column requires database structure changes and potential data changes.

{{< alert type="note" >}}

In case the table is in use, we should always assume that there is inconsistent data.

{{< /alert >}}

Adding a FK constraint to an existing column is a multi-milestone process:

1. `N.M`: Add a `NOT VALID` FK constraint to the column, it will also ensure there are no inconsistent records created or updated.
1. `N.M`: Add a data migration, to fix or clean up existing records.
   2. This can be a regular or post deployment migration if the migration queries lie within the [timing guidelines](query_performance.md).
   3. If not, this has to be done in a [batched background migration](batched_background_migrations.md).
1. Validate the FK constraint
   2. If the data migration was a regular or a post deployment migration, the constraint can be validated in the same milestone.
   3. If it was a background migration, then the FK can be validated only after the BBM is finalized.
      This is required so that the FK validation won't happen while the data migration is still running in background.

{{< alert type="note" >}}

Adding a foreign-key constraint to either an existing or a new column
needs an index on the column.

If the index was added [asynchronously](adding_database_indexes.md#create-indexes-asynchronously), we should wait till
the index gets added in the `structure.sql`.

{{< /alert >}}

This is **required** for all foreign-keys, for example, to support efficient cascading
deleting: when a lot of rows in a table get deleted, the referenced records need
to be deleted too. The database has to look for corresponding records in the
referenced table. Without an index, this results in a sequential scan on the
table, which can take a long time.

#### Example

Consider the following table structures:

`users` table:

- `id` (integer, primary key)
- `name` (string)

`emails` table:

- `id` (integer, primary key)
- `user_id` (integer)
- `email` (string)

Express the relationship in `ActiveRecord`:

```ruby
class User < ActiveRecord::Base
  has_many :emails
end

class Email < ActiveRecord::Base
  belongs_to :user
end
```

Problem: when the user is removed, the email records related to the removed user stays in the `emails` table:

```ruby
user = User.find(1)
user.destroy

emails = Email.where(user_id: 1) # returns emails for the deleted user
```

#### Adding the FK constraint (NOT VALID)

Add a `NOT VALID` foreign key constraint to the table, which enforces consistency on adding or updating records.

In the example above, you will still be able to update records in the `emails` table. However, when you try to update `user_id` with non-existent value, the constraint will throw an error.

Migration file for adding `NOT VALID` foreign key:

```ruby
class AddNotValidForeignKeyToEmailsUser < Gitlab::Database::Migration[2.1]
  milestone '17.10'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :emails,
      :users,
      column: :user_id,
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :emails, column: :user_id
  end
end
```

INFO:
By default `add_concurrent_foreign_key` method validates the foreign key, so explicitly pass `validate: false`.

Adding a foreign key without validating it is a fast operation. It only requires a
short lock on the table before being able to enforce the constraint on new data.

Also `add_concurrent_foreign_key` will add the constraint only if it's not existing.

{{< alert type="warning" >}}

Avoid using `add_foreign_key` or `add_concurrent_foreign_key` constraints more than
once per migration file, unless the source and target tables are identical.

{{< /alert >}}

#### Data migration to fix existing records

The approach here depends on the data volume and the cleanup strategy. If we can find "invalid"
records by doing a database query and the record count is not high, then the data migration can
be executed in regular or post deployment rails migration.

In case the data volume is higher (>1000 records), it's better to create a background migration. If unsure, refer to our [query guidelines](query_performance.md) or contact the database frameworks team for advice.

Example for cleaning up records in the `emails` table in a database migration:

```ruby
class RemoveRecordsWithoutUserFromEmailsTable < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  class Email < ActiveRecord::Base
    include EachBatch
  end

  def up
    Email.each_batch do |batch|
      batch.joins('LEFT JOIN users ON emails.user_id = users.id')
           .where('users.id IS NULL')
           .delete_all
    end
  end

  def down
    # Can be a no-op when data inconsistency is not affecting the pre and post deployment version of the application.
    # In this case we might have records in the `emails` table where the associated record in the `users` table is not there anymore.
  end
end
```

{{< alert type="note" >}}

The MR that adds this data migration should have ~data-deletion label applied.
Refer [preparation-when-adding-data-migrations](../database_review.md#preparation-when-adding-data-migrations) for more information.

{{< /alert >}}

#### Validate the foreign key

Validating the foreign key scans the whole table and makes sure that each relation is correct.
Fortunately, this does not lock the source table (`users`) while running.

As aforementioned when using [batched background migrations](batched_background_migrations.md), foreign key validation should happen only after the BBM is finalized.

Migration file for validating the foreign key:

```ruby
# frozen_string_literal: true

class ValidateForeignKeyOnEmailUsers < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :emails, :user_id
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
```

#### Validate the foreign key asynchronously

For very large tables, foreign key validation can be a challenge to manage when
it runs for many hours. Necessary database operations like `autovacuum` cannot
run, and on GitLab.com, the deployment process is blocked waiting for the
migrations to finish.

To limit impact on GitLab.com, a process exists to validate them asynchronously
during weekend hours. Due to generally lower traffic and fewer deployments,
FK validation can proceed at a lower level of risk.

##### Schedule foreign key validation for a low-impact time

1. [Schedule the FK to be validated](#schedule-the-fk-to-be-validated).
1. [Verify the MR was deployed and the FK is valid in production](#verify-the-mr-was-deployed-and-the-fk-is-valid-in-production).
1. [Add a migration to validate the FK synchronously](#add-a-migration-to-validate-the-fk-synchronously).

##### Schedule the FK to be validated

1. Create a merge request containing a post-deployment migration, which prepares
   the foreign key for asynchronous validation.
1. Create a follow-up issue to add a migration that validates the foreign key
   synchronously.
1. In the merge request that prepares the asynchronous foreign key, add a
   comment mentioning the follow-up issue.

An example of validating the foreign key using the asynchronous helpers can be
seen in the block below. This migration enters the foreign key name into the
`postgres_async_foreign_key_validations` table. The process that runs on
weekends pulls foreign keys from this table and attempts to validate them.

```ruby
# in db/post_migrate/

FK_NAME = :fk_be5624bf37

# TODO: FK to be validated synchronously in issue or merge request
def up
  # `some_column` can be an array of columns, and is not mandatory if `name` is supplied.
  # `name` takes precedence over other arguments.
  prepare_async_foreign_key_validation :ci_builds, :some_column, name: FK_NAME

  # Or in case of partitioned tables, use:
  prepare_partitioned_async_foreign_key_validation :p_ci_builds, :some_column, name: FK_NAME
end

def down
  unprepare_async_foreign_key_validation :ci_builds, :some_column, name: FK_NAME

  # Or in case of partitioned tables, use:
  unprepare_partitioned_async_foreign_key_validation :p_ci_builds, :some_column, name: FK_NAME
end
```

##### Verify the MR was deployed and the FK is valid in production

1. Verify that the post-deploy migration was executed on GitLab.com using ChatOps with
   `/chatops run auto_deploy status <merge_sha>`. If the output returns `db/gprd`,
   the post-deploy migration has been executed in the production database. For more information, see
   [How to determine if a post-deploy migration has been executed on GitLab.com](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/post_deploy_migration/readme.md#how-to-determine-if-a-post-deploy-migration-has-been-executed-on-gitlabcom).
1. Wait until the next week so that the FK can be validated over a weekend.
1. Use [Database Lab](database_lab.md) to check if validation was successful.
   Ensure the output does not indicate the foreign key is `NOT VALID`.

##### Add a migration to validate the FK synchronously

After the foreign key is valid on the production database, create a second
merge request that validates the foreign key synchronously. The schema changes
must be updated and committed to `structure.sql` in this second merge request.
The synchronous migration results in a no-op on GitLab.com, but you should still
add the migration as expected for other installations. The below block
demonstrates how to create the second migration for the previous
asynchronous example.

{{< alert type="warning" >}}

Verify that the foreign key is valid in production before merging a second
migration with `validate_foreign_key`. If the second migration is deployed
before the validation has been executed, the foreign key is validated
synchronously when the second migration executes.

{{< /alert >}}

```ruby
# in db/post_migrate/

  FK_NAME = :fk_be5624bf37

  def up
    validate_foreign_key :ci_builds, :some_column, name: FK_NAME
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end

```

#### Test database FK changes locally

You must test the database foreign key changes locally before creating a merge request.

##### Verify the foreign keys validated asynchronously

Use the asynchronous helpers on your local environment to test changes for
validating a foreign key:

1. Enable the feature flag by running `Feature.enable(:database_async_foreign_key_validation)`
   in the Rails console.
1. Run `bundle exec rails db:migrate` so that it creates an entry in the async validation table.
1. Run `bundle exec rails gitlab:db:validate_async_constraints:all` so that the FK is validated
   asynchronously on all databases.
1. To verify the foreign key, open the PostgreSQL console using the
   [GDK](https://gitlab-org.gitlab.io/gitlab-development-kit/howto/postgresql/)
   command `gdk psql` and run the command `\d+ table_name` to check that your
   foreign key is valid. A successful validation removes `NOT VALID` from
   the foreign key definition.

### Removing foreign keys

This operation does not require downtime.

#### Removing foreign keys from partitioned tables

When working with partitioned tables, use the `remove_partitioned_foreign_key` helper method instead of the regular `remove_foreign_key` method. This is necessary because `remove_foreign_key` doesn't remove foreign keys on partitions when the partitioned table doesn't have the validated foreign key yet. That happens when the `validate: false` option was set during the foreign key creation on partitioned table.

The `remove_partitioned_foreign_key` method removes foreign keys from both the partitioned table and all its partitions:

```ruby
# Remove by column name
remove_partitioned_foreign_key :partitioned_table, :referenced_table, column: :referenced_table_id

# Remove by foreign key name
remove_partitioned_foreign_key :partitioned_table, name: 'fk_rails_123456'
```

This method:

- Removes the foreign key from the partitioned table which also removes inherited constraints on each partition
- Then removes the foreign key from each partition individually (in case they have non-inherited constraints)
- Uses `remove_foreign_key_if_exists` internally, so it won't raise errors if the foreign key doesn't exist
- Supports the same options as the regular `remove_foreign_key` method

Example migration:

```ruby
class RemovePartitionedForeignKey < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  def up
    # Add partitioned foreign key
    add_concurrent_partitioned_foreign_key :partitioned_table, :projects, column: :project_id
  end

  def down
    # Remove partitioned foreign key
    remove_partitioned_foreign_key :partitioned_table, :projects, column: :project_id
  end
end
```

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
finish and they will both timeout. We usually have transaction retries in our
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
thus you must also add a concurrent index. Indexes are required for all foreign
keys and they must be added before the foreign key. This can mean that they are
an earlier step in the same migration or they are added in an earlier migration
than the migration adding the foreign key. For the same reasons, foreign keys
must be removed before removing indexes supporting these foreign keys.

Without an index on the foreign key it forces Postgres to do a full table scan
every time a record is deleted from the referenced table. In the past this has
led to incidents where deleting `projects` and `namespaces` times out.

It is also ok to have a composite index which covers this foreign key so long
as the foreign key is in the first position of the composite index. For example
if you have a foreign key `project_id` then it is OK to have a composite index
like `BTREE (project_id, user_id)` but it is not OK to have an index like
`BTREE (user_id, project_id)`. The latter does not allow efficient lookups by
`project_id` alone and therefore would not prevent the cascade deletes from
timing out. Partial indexes like `BTREE (project_id) WHERE user_id IS NULL`
can never be used for cascading deletes and are not OK for serving as an index
for the foreign key.

## Naming foreign keys

By default Ruby on Rails uses the `_id` suffix for foreign keys. So we should
only use this suffix for associations between two tables. If you want to
reference an ID on a third party platform the `_xid` suffix is recommended.

The spec `spec/db/schema_spec.rb` tests if all columns with the `_id` suffix
have a foreign key constraint. If that spec fails, add the column to
`ignored_fk_columns_map` if the column fits any of the two criteria:

1. The column references another table, such as the two tables belong to
[GitLab schemas](multiple_databases.md#gitlab-schema) that don't
allow Foreign Keys between them.
1. The foreign key is replaced by a [Loose Foreign Key](loose_foreign_keys.md) for performance reasons.
1. The column represents a [polymorphic relationship](polymorphic_associations.md). Note that polymorphic associations should not be used.
1. The column is not meant to reference another table. For example, it's common to have `partition_id`
for partitioned tables.

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
your models unless absolutely required and only when approved by database
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
