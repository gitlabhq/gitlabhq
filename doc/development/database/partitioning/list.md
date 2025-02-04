---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: List partition
---

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96815) in GitLab 15.4.

## Description

Add the partitioning key column to the table you are partitioning.
Include the partitioning key in the following constraints:

- The primary key.
- All foreign keys referencing the table to be partitioned.
- All unique constraints.

## Example

### Step 1 - Add partition key

Add the partitioning key column. For example, in a rails migration:

```ruby
class AddPartitionNumberForPartitioning < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  TABLE_NAME = :table_name
  COLUMN_NAME = :partition_id
  DEFAULT_VALUE = 100

  def change
    add_column(TABLE_NAME, COLUMN_NAME, :bigint, default: 100)
  end
end
```

### Step 2 - Create required indexes

Add indexes including the partitioning key column. For example, in a rails migration:

```ruby
class PrepareIndexesForPartitioning < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :table_name
  INDEX_NAME = :index_name

  def up
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
```

### Step 3 - Enforce unique constraint

Change all unique indexes to include the partitioning key column,
including the primary key index. You can start by adding an unique
index on `[primary_key_column, :partition_id]`, which will be
required for the next two steps. For example, in a rails migration:

```ruby
class PrepareUniqueContraintForPartitioning < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :table_name
  OLD_UNIQUE_INDEX_NAME = :index_name_unique
  NEW_UNIQUE_INDEX_NAME = :new_index_name

  def up
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_UNIQUE_INDEX_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, OLD_UNIQUE_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_UNIQUE_INDEX_NAME)

    remove_concurrent_index_by_name(TABLE_NAME, NEW_UNIQUE_INDEX_NAME)
  end
end
```

### Step 4 - Enforce foreign key constraint

Enforce foreign keys including the partitioning key column. For example, in a rails migration:

```ruby
class PrepareForeignKeyForPartitioning < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :source_table_name
  TARGET_TABLE_NAME = :target_table_name
  COLUMN = :foreign_key_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_365d1db505_p
  PARTITION_COLUMN = :partition_id

  def up
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: [PARTITION_COLUMN, COLUMN],
      target_column: [PARTITION_COLUMN, TARGET_COLUMN],
      validate: false,
      on_update: :cascade,
      name: FK_NAME
    )

    # This should be done in a separate post migration when dealing with a high traffic table
    validate_foreign_key(TABLE_NAME, [PARTITION_COLUMN, COLUMN], name: FK_NAME)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE_NAME, name: FK_NAME)
    end
  end
end
```

The `on_update: :cascade` option is mandatory if we want the partitioning column
to be updated. This will cascade the update to all dependent rows. Without
specifying it, updating the partition column on the target table we would
result in a `Key is still referenced from table ...` error and updating the
partition column on the source table would raise a
`Key is not present in table ...` error.

### Step 5 - Swap primary key

Swap the primary key including the partitioning key column. This can be done only after
including the partition key for all references foreign keys. For example, in a rails migration:

```ruby
class PreparePrimaryKeyForPartitioning < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :table_name
  PRIMARY_KEY = :primary_key
  OLD_INDEX_NAME = :old_index_name
  NEW_INDEX_NAME = :new_index_name

  def up
    swap_primary_key(TABLE_NAME, PRIMARY_KEY, NEW_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_INDEX_NAME)
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_INDEX_NAME)

    unswap_primary_key(TABLE_NAME, PRIMARY_KEY, OLD_INDEX_NAME)

    # We need to add back referenced FKs if any, eg: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113725/diffs
  end
end
```

NOTE:
Do not forget to set the primary key explicitly in your model as `ActiveRecord` does not support composite primary keys.

```ruby
class Model < ApplicationRecord
  self.primary_key = :id
end
```

### Step 6 - Create parent table and attach existing table as the initial partition

You can now create the parent table attaching the existing table as the initial
partition by using the following helpers provided by the database team.

For example, using list partitioning in Rails post migrations:

```ruby
class PrepareTableConstraintsForListPartitioning < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  TABLE_NAME = :table_name
  PARENT_TABLE_NAME = :p_table_name
  FIRST_PARTITION = 100
  PARTITION_COLUMN = :partition_id

  def up
    prepare_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  def down
    revert_preparing_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end
end
```

```ruby
class ConvertTableToListPartitioning < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  TABLE_NAME = :table_name
  PARENT_TABLE_NAME = :p_table_name
  FIRST_PARTITION = 100
  PARTITION_COLUMN = :partition_id

  def up
    convert_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  def down
    revert_converting_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end
end
```

NOTE:
Do not forget to set the sequence name explicitly in your model because it will
be owned by the routing table and `ActiveRecord` can't determine it. This can
be cleaned up after the `table_name` is changed to the routing table.

```ruby
class Model < ApplicationRecord
  self.sequence_name = 'model_id_seq'
end
```

If the partitioning constraint migration takes [more than 10 minutes](../../migration_style_guide.md#how-long-a-migration-should-take) to finish,
it can be made to run asynchronously to avoid running the post-migration during busy hours.

Prepend the following migration `AsyncPrepareTableConstraintsForListPartitioning`
and use `async: true` option. This change marks the partitioning constraint as `NOT VALID`
and enqueues a scheduled job to validate the existing data in the table during the weekend.

Then the second post-migration `PrepareTableConstraintsForListPartitioning` only
marks the partitioning constraint as validated, because the existing data is already
tested during the previous weekend.

For example:

```ruby
class AsyncPrepareTableConstraintsForListPartitioning < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  TABLE_NAME = :table_name
  PARENT_TABLE_NAME = :p_table_name
  FIRST_PARTITION = 100
  PARTITION_COLUMN = :partition_id

  def up
    prepare_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION,
      async: true
    )
  end

  def down
    revert_preparing_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end
end
```

### Step 7 - Re-point foreign keys to parent table

The tables that reference the initial partition must be updated to point to the
parent table now. Without this change, the records from those tables
will not be able to locate the rows in the next partitions because they will look
for them in the initial partition.

Steps:

- Add the foreign key to the partitioned table and validate it asynchronously,
  [for example](https://gitlab.com/gitlab-org/gitlab/-/blob/65d63f6a00196c3a7d59f15191920f271ab2b145/db/post_migrate/20230524135543_replace_ci_build_pending_states_foreign_key.rb).
- Validate it synchronously after the asynchronously validation was completed on GitLab.com,
  [for example](https://gitlab.com/gitlab-org/gitlab/-/blob/65d63f6a00196c3a7d59f15191920f271ab2b145/db/post_migrate/20230530140456_validate_fk_ci_build_pending_states_p_ci_builds.rb).
- Remove the old foreign key and rename the new one to the old name,
  [for example](https://gitlab.com/gitlab-org/gitlab/-/blob/65d63f6a00196c3a7d59f15191920f271ab2b145/db/post_migrate/20230615083713_replace_old_fk_ci_build_pending_states_to_builds.rb#L9).

### Step 8 - Ensure ID uniqueness across partitions

All uniqueness constraints must include the partitioning key, so we can have
duplicate IDs across partitions. To solve this we enforce that only the database
can set the ID values and use a sequence to generate them because sequences are
guaranteed to generate unique values.

For example:

```ruby
class EnsureIdUniquenessForPCiBuilds < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  enable_lock_retries!

  TABLE_NAME = :p_ci_builds
  SEQ_NAME = :ci_builds_id_seq

  def up
    ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end

  def down
    revert_ensure_unique_id(TABLE_NAME, seq: SEQ_NAME)
  end
end
```

### Step 9 - Analyze the partitioned table and create new partitions

The autovacuum daemon does not process partitioned tables. It is necessary to
periodically run a manual `ANALYZE` to keep the statistics of the table hierarchy
up to date.

Models that implement `Ci::Partitionable` with `partitioned: true` option are
analyzed by default on a weekly basis. To enable this and create new partitions
you need to register the model in the [PostgreSQL initializer](https://gitlab.com/gitlab-org/gitlab/-/blob/b7f0e3f1bcd2ffc220768bbc373364151775ca8e/config/initializers/postgres_partitioning.rb).

### Step 10 - Update the application to use the partitioned table

Now that the parent table is ready, we can update the application to use it:

```ruby
class Model < ApplicationRecord
  self.table_name = :partitioned_table
end
```

Depending on the model, it might be safer to use a [change management issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16387).
