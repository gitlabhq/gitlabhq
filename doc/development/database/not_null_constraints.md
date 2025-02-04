---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: '`NOT NULL` constraints'
---

All attributes that should not have `NULL` as a value, should be defined as `NOT NULL`
columns in the database.

Depending on the application logic, `NOT NULL` columns should either have a `presence: true`
validation defined in their Model or have a default value as part of their database definition.
As an example, the latter can be true for boolean attributes that should always have a non-`NULL`
value, but have a well defined default value that the application does not need to enforce each
time (for example, `active=true`).

## Create a new table with `NOT NULL` columns

When adding a new table, all `NOT NULL` columns should be defined as such directly inside `create_table`.

For example, consider a migration that creates a table with two `NOT NULL` columns,
`db/migrate/20200401000001_create_db_guides.rb`:

```ruby
class CreateDbGuides < Gitlab::Database::Migration[2.1]
  def change
    create_table :db_guides do |t|
      t.bigint :stars, default: 0, null: false
      t.bigint :guide, null: false
    end
  end
end
```

## Add a `NOT NULL` column to an existing table

With PostgreSQL 11 being the minimum version in GitLab, adding columns with `NULL` and/or
default values has become much easier and the standard `add_column` helper should be used in all cases.

For example, consider a migration that adds a new `NOT NULL` column `active` to table `db_guides`,
`db/migrate/20200501000001_add_active_to_db_guides.rb`:

```ruby
class AddExtendedTitleToSprints < Gitlab::Database::Migration[2.1]
  def change
    add_column :db_guides, :active, :boolean, default: true, null: false
  end
end
```

## Add a `NOT NULL` constraint to an existing column

Adding `NOT NULL` to existing database columns usually requires multiple steps split into at least two
different releases. If your table is small enough that you don't need to
use a background migration, you can include all these in the same merge
request. We recommend to use separate migrations to reduce
transaction durations.

The steps required are:

1. Release `N.M` (current release)

   1. Ensure $ATTRIBUTE value is being set at the application level.
      1. If the attribute has a default value, add the default value to the model so the default value is set for new records.
      1. Update all places in the code where the attribute would be set to `nil`, if any, for new and existing records. Note that
         using ActiveRecord callbacks such as `before_save` and `before_validation` may not be sufficient, as some processes
         skip these callbacks. `update_column`, `update_columns`, and bulk operations such as `insert_all` and `update_all` are some
         examples of methods to look out for.
   1. Add a post-deployment migration to fix the existing records.

     NOTE:
     Depending on the size of the table, a background migration for cleanup could be required in the next release.
     See the [`NOT NULL` constraints on large tables](not_null_constraints.md#not-null-constraints-on-large-tables) section for more information.

1. Release `N.M+1` (next release)

   1. Make sure all existing records on GitLab.com have attribute set. If not, go back to step 1 from Release `N.M`.
   1. If step 1 seems fine and the backfill from Release `N.M` was done via a batched background migration then add a
      post-deployment migration to
      [finalize the background migration](batched_background_migrations.md#depending-on-migrated-data).
   1. Add a validation for the attribute in the model to prevent records with `nil` attribute as now all existing and new records should be valid.
   1. Add a post-deployment migration to add the `NOT NULL` constraint.

### Example

Considering a given release milestone, such as 13.0.

After checking our production database, we know that there are `epics` with `NULL` descriptions,
so we cannot add and validate the constraint in one step.

NOTE:
Even if we did not have any epic with a `NULL` description, another instance of GitLab could have
such records, so we would follow the same process either way.

#### Prevent new invalid records (current release)

Update all the code paths where the attribute is being set to `nil`, if any, to set the attribute to non-nil value
for new and existing records.

An attribute with default using the
[Rails attributes API](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html) has been added in
`epic.rb` so that default value is set for new records:

```ruby
class Epic < ApplicationRecord
  attribute :description, default: 'No description'
end
```

#### Data migration to fix existing records (current release)

The approach here depends on the data volume and the cleanup strategy. The number of records that
must be fixed on GitLab.com is a nice indicator that helps us decide whether to use a
post-deployment migration or a background data migration:

- If the data volume is less than `1000` records, then the data migration can be executed within the post-migration.
- If the data volume is higher than `1000` records, it's advised to create a background migration.

When unsure about which option to use, contact the Database team for advice.

Back to our example, the epics table is not considerably large nor frequently accessed,
so we add a post-deployment migration for the 13.0 milestone (current),
`db/post_migrate/20200501000002_cleanup_epics_with_null_description.rb`:

```ruby
class CleanupEpicsWithNullDescription < Gitlab::Database::Migration[2.1]
  # With BATCH_SIZE=1000 and epics.count=29500 on GitLab.com
  # - 30 iterations will be run
  # - each requires on average ~150ms
  # Expected total run time: ~5 seconds
  BATCH_SIZE = 1000

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
    include EachBatch

    self.table_name = 'epics'
  end

  def up
    Epic.each_batch(of: BATCH_SIZE) do |relation|
      relation.
        where('description IS NULL').
        update_all(description: 'No description')
    end
  end

  def down
    # no-op : can't go back to `NULL` without first dropping the `NOT NULL` constraint
  end
end
```

#### Check if all records are fixed (next release)

Use postgres.ai to [create a thin clone](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/data_stores/database/doc/gitlab-com-database/#use-postgresai-to-work-with-a-thin-clone-of-the-database-includes-direct-psql-access-to-the-thin-clone)
of the production database and check if all records on GitLab.com have the attribute set.
If not go back to [Prevent new invalid records](#prevent-new-invalid-records-current-release) step and figure out where
in the code the attribute is explicitly set to `nil`. Fix the code path then reschedule the migration to fix the existing
records and wait for the next release to do the following steps.

#### Finalize the background migration (next release)

If the migration was done using a background migration then [finalize the migration](batched_background_migrations.md#depending-on-migrated-data).

#### Add validation to the model (next release)

Add a validation for the attribute to the model to prevent records with `nil` attribute as now all existing and new records should be valid.

```ruby
class Epic < ApplicationRecord
  validates :description, presence: true
end
```

#### Add the `NOT NULL` constraint (next release)

Adding the `NOT NULL` constraint scans the whole table and make sure that each record is correct.

Still in our example, for the 13.1 milestone (next), we run the `add_not_null_constraint`
migration helper in a final post-deployment migration:

```ruby
class AddNotNullConstraintToEpicsDescription < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # This will add the `NOT NULL` constraint and validate it
    add_not_null_constraint :epics, :description
  end

  def down
    # Down is required as `add_not_null_constraint` is not reversible
    remove_not_null_constraint :epics, :description
  end
end
```

## `NOT NULL` constraints on large tables

If you have to clean up a nullable column for a [high-traffic table](../migration_style_guide.md#high-traffic-tables)
(for example, the `artifacts` in `ci_builds`), your background migration goes on for a while and
it needs an additional [batched background migration cleaning up](batched_background_migrations.md#cleaning-up-a-batched-background-migration)
in the release after adding the data migration.

In this case the number of releases depends on the amount of time needed to migrate existing records. The cleanup is
scheduled after the background migration has completed, which could be several releases after the constraint was added.

1. Release `N.M`:
   - Add the background-migration to fix the existing records:

     ```ruby
     # db/post_migrate/
     class QueueBackfillMergeRequestDiffsProjectId < Gitlab::Database::Migration[2.2]
       milestone '16.7'
       restrict_gitlab_migration gitlab_schema: :gitlab_main

       MIGRATION = 'BackfillMergeRequestDiffsProjectId'
       DELAY_INTERVAL = 2.minutes

       def up
         queue_batched_background_migration(
           MIGRATION,
           :merge_request_diffs,
           :id,
           job_interval: DELAY_INTERVAL
         )
       end

       def down
         delete_batched_background_migration(MIGRATION, :merge_request_diffs, :id, [])
       end
     end
     ```

1. Release `N.M+X`, where `X` is the number of releases the migration was running:
   - [Verify that all existing records are fixed](#check-if-all-records-are-fixed-next-release).

   - Cleanup the background migration:

     ```ruby
     # db/post_migrate/
     class FinalizeMergeRequestDiffsProjectIdBackfill < Gitlab::Database::Migration[2.2]
       disable_ddl_transaction!
       milestone '16.10'
       restrict_gitlab_migration gitlab_schema: :gitlab_main

       MIGRATION = 'BackfillMergeRequestDiffsProjectId'

       def up
         ensure_batched_background_migration_is_finished(
           job_class_name: MIGRATION,
           table_name: :merge_request_diffs,
           column_name: :id,
           job_arguments: [],
           finalize: true
         )
       end

       def down
         # no-op
       end
     end
     ```

   - Add the `NOT NULL` constraint:

     ```ruby
     # db/post_migrate/
     class AddMergeRequestDiffsProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
       disable_ddl_transaction!
       milestone '16.7'

       def up
         add_not_null_constraint :merge_request_diffs, :project_id
       end

       def down
         remove_not_null_constraint :merge_request_diffs, :project_id
       end
     end
     ```

   - **Optional.** For very large tables, add an invalid `NOT NULL` constraint and schedule asynchronous validation:

     ```ruby
     # db/post_migrate/
     class AddMergeRequestDiffsProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
       disable_ddl_transaction!
       milestone '16.7'

       def up
         add_not_null_constraint :merge_request_diffs, :project_id, validate: false
       end

       def down
         remove_not_null_constraint :merge_request_diffs, :project_id
       end
     end
     ```

     ```ruby
     # db/post_migrate/
     class PrepareMergeRequestDiffsProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
       milestone '16.10'

       CONSTRAINT_NAME = 'check_11c5f029ad'

       def up
         prepare_async_check_constraint_validation :merge_request_diffs, name: CONSTRAINT_NAME
       end

       def down
         unprepare_async_check_constraint_validation :merge_request_diffs, name: CONSTRAINT_NAME
       end
     end
     ```

   - **Optional.** For partitioned table, use:

     ```ruby
     # db/post_migrate/

     PARTITIONED_TABLE_NAME = :p_ci_builds
     CONSTRAINT_NAME = 'check_9aa9432137'

     # Partitioned check constraint to be validated in https://gitlab.com/gitlab-org/gitlab/-/issues/XXXXX
     def up
       prepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
     end

     def down
       unprepare_partitioned_async_check_constraint_validation PARTITIONED_TABLE_NAME, name: CONSTRAINT_NAME
     end
     ```

     NOTE:
     `prepare_partitioned_async_check_constraint_validation` only validates the existing `NOT VALID` check constraint asynchronously for all the partitions.
     It doesn't create or validate the check constraint for the partitioned table.

1. **Optional.** If the constraint was validated asynchronously, validate the `NOT NULL` constraint once validation is complete:
   - Use [Database Lab](database_lab.md) to check if the validation was successful.
   Run the command `\d+ table_name` and ensure that `NOT VALID` has been removed from the check constraint definition.
   - Add the migration to validate the `NOT NULL` constraint:

      ```ruby
      # db/post_migrate/
      class ValidateMergeRequestDiffsProjectIdNullConstraint < Gitlab::Database::Migration[2.2]
        milestone '16.10'

        def up
          validate_not_null_constraint :merge_request_diffs, :project_id
        end

        def down
          # no-op
        end
      end
      ```

For these cases, consult the database team early in the update cycle. The `NOT NULL`
constraint may not be required or other options could exist that do not affect really large
or frequently accessed tables.

## `NOT NULL` constraints for multiple columns

Sometimes we want to ensure a set of columns contains a specific number of `NOT NULL` values. A common example
is a table that can belong to either a project or a group, and therefore `project_id` or `group_id` must
be present. To enforce this, follow the steps for your use case above, but instead use the
`add_multi_column_not_null_constraint` helper.

In this example, `labels` must belong to either a project or a group, but not both. We can add
a check constraint to enforce this:

```ruby
class AddLabelsNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_multi_column_not_null_constraint(:labels, :group_id, :project_id)
  end

  def down
    remove_multi_column_not_null_constraint(:labels, :group_id, :project_id)
  end
end
```

This will add the following constraint to `labels`:

```sql
CREATE TABLE labels (
    ...
    CONSTRAINT check_45e873b2a8 CHECK ((num_nonnulls(group_id, project_id) = 1))
);
```

`num_nonnulls` returns the number of supplied arguments that are non-null. Checking this value
equals `1` in the constraint means that only one of `group_id` and `project_id` should contain
a non-null value in a row, but not both.

### Custom limits and operators

If we want to customize the number of non-nulls required, we can use a different `limit` and/or `operator`:

```ruby
class AddLabelsNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_multi_column_not_null_constraint(:labels, :group_id, :project_id, limit: 0, operator: '>')
  end

  def down
    remove_multi_column_not_null_constraint(:labels, :group_id, :project_id)
  end
end
```

This is then reflected in the constraint, allowing both `project_id` and `group_id` to be present:

```sql
CREATE TABLE labels (
    ...
    CONSTRAINT check_45e873b2a8 CHECK ((num_nonnulls(group_id, project_id) > 0))
);
```

## Dropping a `NOT NULL` constraint on a column in an existing table

### Dropping a `NOT NULL` constraint with a check constraint on the column

First, please verify there's a constraint in place on the column. You can do this in several ways:

- Query the [`Gitlab::Database::PostgresConstraint`](https://gitlab.com/gitlab-org/gitlab/-/blob/71892a3c97f52ddcef819dd210ab32864e90c85c/lib/gitlab/database/postgres_constraint.rb) view in rails console
- Use `psql` to check the table itself: `\d+ table_name`
- Check `structure.sql`:

```sql
CREATE TABLE labels (
    ...
   CONSTRAINT check_061f6f1c91 CHECK ((project_view IS NOT NULL))
);
```

#### Example

```ruby
# frozen_string_literal: true
class DropNotNullConstraintFromTableColumn< Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  def up
    remove_not_null_constraint :table_name, :column_name
  end

  def down
    add_not_null_constraint :table_name, :column_name
  end
end
```

<b>NOTE:</b> The milestone number is just an example. Please use the correct version.

### Dropping a `NOT NULL` constraint without a check constraint on the column

If `NOT NULL` is just defined on the column and without a check constraint then we can use `change_column_null`.

Example in `structure.sql`:

```sql
CREATE TABLE labels (
    ...
   projects_limit integer NOT NULL
);
```

#### Example

```ruby
# frozen_string_literal: true
class DropNotNullConstraintFromTableColumn < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def up
    change_column_null :table_name, :column_name, true
  end

  def down
    change_column_null :table_name, :column_name, false
  end
end
```

<b>NOTE:</b> The milestone number is just an example. Please use the correct version.

### Dropping a `NOT NULL` constraint on a partition table

Important note: we cannot drop the `NOT NULL` constraint from an individual partition if it exists on the parent table because all the partitions inherit the constraint from the parent table. For this reason, we need to drop the constraint from the parent table instead which cascades to all the child partitions.
