---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Add a foreign key constraint to an existing column
---

Foreign keys ensure consistency between related database tables. The current database review process **always** encourages you to add [foreign keys](foreign_keys.md) when creating tables that reference records from other tables.

Starting with Rails version 4, Rails includes migration helpers to add foreign key constraints
to database tables. Before Rails 4, the only way for ensuring some level of consistency was the
[`dependent`](https://guides.rubyonrails.org/association_basics.html#options-for-belongs-to-dependent)
option in the association definition. Ensuring data consistency on the application level could fail
in some unfortunate cases, so we might end up with inconsistent data in the table. This mostly affects
older tables, where we didn't have the framework support to ensure consistency on the database level.
These data inconsistencies can cause unexpected application behavior or bugs.

Adding a foreign key to an existing database column requires database structure changes and potential data changes. In case the table is in use, we should always assume that there is inconsistent data.

To add a foreign key constraint to an existing column:

1. GitLab version `N.M`: Add a `NOT VALID` foreign key constraint to the column to ensure GitLab doesn't create inconsistent records.
1. GitLab version `N.M`: Add a data migration, to fix or clean up existing records.
1. GitLab version `N.M+1`: Validate the whole table by making the foreign key `VALID`.

## Example

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

### Prevent invalid records

Add a `NOT VALID` foreign key constraint to the table, which enforces consistency on the record changes.

In the example above, you'd be still able to update records in the `emails` table. However, when you'd try to update the `user_id` with non-existent value, the constraint causes a database error.

Migration file for adding `NOT VALID` foreign key:

```ruby
class AddNotValidForeignKeyToEmailsUser < Gitlab::Database::Migration[2.1]
  def up
    add_concurrent_foreign_key :emails, :users, column: :user_id, on_delete: :cascade, validate: false
  end

  def down
    remove_foreign_key_if_exists :emails, column: :user_id
  end
end
```

Adding a foreign key without validating it is a fast operation. It only requires a
short lock on the table before being able to enforce the constraint on new data.
We do still want to enable lock retries for high traffic and large tables.
`add_concurrent_foreign_key` does this for us, and also checks if the foreign key already exists.

WARNING:
Avoid using `add_foreign_key` or `add_concurrent_foreign_key` constraints more than
once per migration file, unless the source and target tables are identical.

#### Data migration to fix existing records

The approach here depends on the data volume and the cleanup strategy. If we can find "invalid"
records by doing a database query and the record count is not high, then the data migration can
be executed in a Rails migration.

In case the data volume is higher (>1000 records), it's better to create a background migration. If unsure, contact the database team for advice.

Example for cleaning up records in the `emails` table in a database migration:

```ruby
class RemoveRecordsWithoutUserFromEmailsTable < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  class Email < ActiveRecord::Base
    include EachBatch
  end

  def up
    Email.where('user_id NOT IN (SELECT id FROM users)').each_batch do |relation|
      relation.delete_all
    end
  end

  def down
    # Can be a no-op when data inconsistency is not affecting the pre and post deployment version of the application.
    # In this case we might have records in the `emails` table where the associated record in the `users` table is not there anymore.
  end
end
```

### Validate the foreign key

Validating the foreign key scans the whole table and makes sure that each relation is correct.
Fortunately, this does not lock the source table (`users`) while running.

NOTE:
When using [batched background migrations](batched_background_migrations.md), foreign key validation should happen in the next GitLab release.

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

### Validate the foreign key asynchronously

For very large tables, foreign key validation can be a challenge to manage when
it runs for many hours. Necessary database operations like `autovacuum` cannot
run, and on GitLab.com, the deployment process is blocked waiting for the
migrations to finish.

To limit impact on GitLab.com, a process exists to validate them asynchronously
during weekend hours. Due to generally lower traffic and fewer deployments,
FK validation can proceed at a lower level of risk.

#### Schedule foreign key validation for a low-impact time

1. [Schedule the FK to be validated](#schedule-the-fk-to-be-validated).
1. [Verify the MR was deployed and the FK is valid in production](#verify-the-mr-was-deployed-and-the-fk-is-valid-in-production).
1. [Add a migration to validate the FK synchronously](#add-a-migration-to-validate-the-fk-synchronously).

#### Schedule the FK to be validated

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

#### Verify the MR was deployed and the FK is valid in production

1. Verify that the post-deploy migration was executed on GitLab.com using ChatOps with
   `/chatops run auto_deploy status <merge_sha>`. If the output returns `db/gprd`,
   the post-deploy migration has been executed in the production database. For more information, see
   [How to determine if a post-deploy migration has been executed on GitLab.com](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/post_deploy_migration/readme.md#how-to-determine-if-a-post-deploy-migration-has-been-executed-on-gitlabcom).
1. Wait until the next week so that the FK can be validated over a weekend.
1. Use [Database Lab](database_lab.md) to check if validation was successful.
   Ensure the output does not indicate the foreign key is `NOT VALID`.

#### Add a migration to validate the FK synchronously

After the foreign key is valid on the production database, create a second
merge request that validates the foreign key synchronously. The schema changes
must be updated and committed to `structure.sql` in this second merge request.
The synchronous migration results in a no-op on GitLab.com, but you should still
add the migration as expected for other installations. The below block
demonstrates how to create the second migration for the previous
asynchronous example.

WARNING:
Verify that the foreign key is valid in production before merging a second
migration with `validate_foreign_key`. If the second migration is deployed
before the validation has been executed, the foreign key is validated
synchronously when the second migration executes.

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

### Test database FK changes locally

You must test the database foreign key changes locally before creating a merge request.

#### Verify the foreign keys validated asynchronously

Use the asynchronous helpers on your local environment to test changes for
validating a foreign key:

1. Enable the feature flag by running `Feature.enable(:database_async_foreign_key_validation)`
   in the Rails console.
1. Run `bundle exec rails db:migrate` so that it creates an entry in the async validation table.
1. Run `bundle exec rails gitlab:db:validate_async_constraints:all` so that the FK is validated
   asynchronously on all databases.
1. To verify the foreign key, open the PostgreSQL console using the
   [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md)
   command `gdk psql` and run the command `\d+ table_name` to check that your
   foreign key is valid. A successful validation removes `NOT VALID` from
   the foreign key definition.
