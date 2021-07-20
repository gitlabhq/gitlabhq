---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
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
class CreateDbGuides < ActiveRecord::Migration[6.0]
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
class AddExtendedTitleToSprints < ActiveRecord::Migration[6.0]
  def change
    add_column :db_guides, :active, :boolean, default: true, null: false
  end
end
```

## Add a `NOT NULL` constraint to an existing column

Adding `NOT NULL` to existing database columns requires multiple steps split into at least two
different releases:

1. Release `N.M` (current release)

   - Ensure the constraint is enforced at the application level (i.e. add a model validation).
   - Add a post-deployment migration to add the `NOT NULL` constraint with `validate: false`.
   - Add a post-deployment migration to fix the existing records.

     NOTE:
     Depending on the size of the table, a background migration for cleanup could be required in the next release.
     See the [`NOT NULL` constraints on large tables](not_null_constraints.md#not-null-constraints-on-large-tables) section for more information.

   - Create an issue for the next milestone to validate the `NOT NULL` constraint.

1. Release `N.M+1` (next release)

   - Validate the `NOT NULL` constraint using a post-deployment migration.

### Example

Considering a given release milestone, such as 13.0, a model validation has been added into `epic.rb`
to require a description:

```ruby
class Epic < ApplicationRecord
  validates :description, presence: true
end
```

The same constraint should be added at the database level for consistency purposes.
We only want to enforce the `NOT NULL` constraint without setting a default, as we have decided
that all epics should have a user-generated description.

After checking our production database, we know that there are `epics` with `NULL` descriptions,
so we can not add and validate the constraint in one step.

NOTE:
Even if we did not have any epic with a `NULL` description, another instance of GitLab could have
such records, so we would follow the same process either way.

#### Prevent new invalid records (current release)

We first add the `NOT NULL` constraint with a `NOT VALID` parameter, which enforces consistency
when new records are inserted or current records are updated.

In the example above, the existing epics with a `NULL` description will not be affected and you'll
still be able to update records in the `epics` table. However, when you try to update or insert
an epic without providing a description, the constraint causes a database error.

Adding or removing a `NOT NULL` clause requires that any application changes are deployed _first_.
Thus, adding a `NOT NULL` constraint to an existing column should happen in a post-deployment migration.

Still in our example, for the 13.0 milestone example (current), we add the `NOT NULL` constraint
with `validate: false` in a post-deployment migration,
`db/post_migrate/20200501000001_add_not_null_constraint_to_epics_description.rb`:

```ruby
class AddNotNullConstraintToEpicsDescription < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    # This will add the `NOT NULL` constraint WITHOUT validating it
    add_not_null_constraint :epics, :description, validate: false
  end

  def down
    # Down is required as `add_not_null_constraint` is not reversible
    remove_not_null_constraint :epics, :description
  end
end
```

#### Data migration to fix existing records (current release)

The approach here depends on the data volume and the cleanup strategy. The number of records that
must be fixed on GitLab.com is a nice indicator that will help us decide whether to use a
post-deployment migration or a background data migration:

- If the data volume is less than `1000` records, then the data migration can be executed within the post-migration.
- If the data volume is higher than `1000` records, it's advised to create a background migration.

When unsure about which option to use, please contact the Database team for advice.

Back to our example, the epics table is not considerably large nor frequently accessed,
so we are going to add a post-deployment migration for the 13.0 milestone (current),
`db/post_migrate/20200501000002_cleanup_epics_with_null_description.rb`:

```ruby
class CleanupEpicsWithNullDescription < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

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

#### Validate the `NOT NULL` constraint (next release)

Validating the `NOT NULL` constraint will scan the whole table and make sure that each record is correct.

Still in our example, for the 13.1 milestone (next), we run the `validate_not_null_constraint`
migration helper in a final post-deployment migration,
`db/post_migrate/20200601000001_validate_not_null_constraint_on_epics_description.rb`:

```ruby
class ValidateNotNullConstraintOnEpicsDescription < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    validate_not_null_constraint :epics, :description
  end

  def down
    # no-op
  end
end
```

## `NOT NULL` constraints on large tables

If you have to clean up a nullable column for a [high-traffic table](../migration_style_guide.md#high-traffic-tables)
(for example, the `artifacts` in `ci_builds`), your background migration will go on for a while and
it will need an additional [background migration cleaning up](../background_migrations.md#cleaning-up)
in the release after adding the data migration.

In that rare case you will need 3 releases end-to-end:

1. Release `N.M` - Add the `NOT NULL` constraint and the background-migration to fix the existing records.
1. Release `N.M+1` - Cleanup the background migration.
1. Release `N.M+2` - Validate the `NOT NULL` constraint.

For these cases, please consult the database team early in the update cycle. The `NOT NULL`
constraint may not be required or other options could exist that do not affect really large
or frequently accessed tables.
