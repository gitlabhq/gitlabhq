---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# `NOT NULL` constraints

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38358) in GitLab 13.0.

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

With PostgreSQL 11 being the minimum version in GitLab 13.0 and later, adding columns with `NULL` and/or
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
      1. Update all places in the code where the attribute is being set to `nil`, if any, for new and existing records.
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

Use postgres.ai to [create a thin clone](https://about.gitlab.com/handbook/engineering/development/enablement/data_stores/database/doc/gitlab-com-database.html#use-postgresai-to-work-with-a-thin-clone-of-the-database-includes-direct-psql-access-to-the-thin-clone)
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

In that rare case you need 3 releases end-to-end:

1. Release `N.M` - Add the `NOT NULL` constraint and the background-migration to fix the existing records.
1. Release `N.M+1` - Cleanup the background migration.
1. Release `N.M+2` - Validate the `NOT NULL` constraint.

For these cases, consult the database team early in the update cycle. The `NOT NULL`
constraint may not be required or other options could exist that do not affect really large
or frequently accessed tables.
