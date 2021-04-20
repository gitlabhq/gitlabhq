---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Adding foreign key constraint to an existing column

Foreign keys help ensure consistency between related database tables. The current database review process **always** encourages you to add [foreign keys](../foreign_keys.md) when creating tables that reference records from other tables.

Starting with Rails version 4, Rails includes migration helpers to add foreign key constraints to database tables. Before Rails 4, the only way for ensuring some level of consistency was the [`dependent`](https://guides.rubyonrails.org/association_basics.html#options-for-belongs-to-dependent) option within the association definition. Ensuring data consistency on the application level could fail in some unfortunate cases, so we might end up with inconsistent data in the table. This is mostly affecting older tables, where we simply didn't have the framework support to ensure consistency on the database level. These data inconsistencies can easily cause unexpected application behavior or bugs.

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

Problem: when the user is removed, the email records related to the removed user will stay in the `emails` table:

```ruby
user = User.find(1)
user.destroy

emails = Email.where(user_id: 1) # returns emails for the deleted user
```

### Prevent invalid records

Add a `NOT VALID` foreign key constraint to the table, which enforces consistency on the record changes.

[Using the `with_lock_retries` helper method is advised when performing operations on high-traffic tables](../migration_style_guide.md#when-to-use-the-helper-method),
in this case, if the table or the foreign table is a high-traffic table, we should use the helper method.

In the example above, you'd be still able to update records in the `emails` table. However, when you'd try to update the `user_id` with non-existent value, the constraint causes a database error.

Migration file for adding `NOT VALID` foreign key:

```ruby
class AddNotValidForeignKeyToEmailsUser < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  def up
    # safe to use: it requires short lock on the table since we don't validate the foreign key
    add_foreign_key :emails, :users, on_delete: :cascade, validate: false
  end

  def down
    remove_foreign_key_if_exists :emails, column: :user_id
  end
end
```

WARNING:
Avoid using the `add_foreign_key` constraint more than once per migration file, unless the source and target tables are identical.

#### Data migration to fix existing records

The approach here depends on the data volume and the cleanup strategy. If we can easily find "invalid" records by doing a simple database query and the record count is not that high, then the data migration can be executed within a Rails migration.

In case the data volume is higher (>1000 records), it's better to create a background migration. If unsure, please contact the database team for advice.

Example for cleaning up records in the `emails` table within a database migration:

```ruby
class RemoveRecordsWithoutUserFromEmailsTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

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

Validating the foreign key will scan the whole table and make sure that each relation is correct.

NOTE:
When using [background migrations](../background_migrations.md), foreign key validation should happen in the next GitLab release.

Migration file for validating the foreign key:

```ruby
# frozen_string_literal: true

class ValidateForeignKeyOnEmailUsers < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  def up
    validate_foreign_key :emails, :user_id
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
```
