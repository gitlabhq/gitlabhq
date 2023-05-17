---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Database table partitioning

WARNING:
If you have questions not answered below, check for and add them
to [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/398650).
Tag `@gitlab-org/database-team/triage` and we'll get back to you with an
answer as soon as possible. If you get an answer in Slack, document
it on the issue as well so we can update this document in the future.

Table partitioning is a powerful database feature that allows a table's
data to be split into smaller physical tables that act as a single large
table. If the application is designed to work with partitioning in mind,
there can be multiple benefits, such as:

- Query performance can be improved greatly, because the database can
cheaply eliminate much of the data from the search space, while still
providing full SQL capabilities.

- Bulk deletes can be achieved with minimal impact on the database by
dropping entire partitions. This is a natural fit for features that need
to periodically delete data that falls outside the retention window.

- Administrative tasks like `VACUUM` and index rebuilds can operate on
individual partitions, rather than across a single massive table.

Unfortunately, not all models fit a partitioning scheme, and there are
significant drawbacks if implemented incorrectly. Additionally, tables
can only be partitioned at their creation, making it nontrivial to apply
partitioning to a busy database. A suite of migration tools are available
to enable backend developers to partition existing tables, but the
migration process is rather heavy, taking multiple steps split across
several releases. Due to the limitations of partitioning and the related
migrations, you should understand how partitioning fits your use case
before attempting to leverage this feature.

## Determine when to use partitioning

While partitioning can be very useful when properly applied, it's
imperative to identify if the data and workload of a table naturally fit a
partitioning scheme. Understand a few details to decide if partitioning
is a good fit for your particular problem:

- **Table partitioning**. A table is partitioned on a partition key, which is a
  column or set of columns which determine how the data is split across the
  partitions. The partition key is used by the database when reading or
  writing data, to decide which partitions must be accessed. The
  partition key should be a column that would be included in a `WHERE`
  clause on almost all queries accessing that table.

- **How the data is split**. What strategy does the database use
  to split the data across the partitions? The available choices are `range`,
  `hash`, and `list`.

## Determine the appropriate partitioning strategy

The available partitioning strategy choices are `range`, `hash`, and `list`.

### Range partitioning

The scheme best supported by the GitLab migration helpers is date-range partitioning,
where each partition in the table contains data for a single month. In this case,
the partitioning key must be a timestamp or date column. For this type of
partitioning to work well, most queries must access data in a
certain date range.

For a more concrete example, consider using the `audit_events` table.
It was the first table to be partitioned in the application database
(scheduled for deployment with the GitLab 13.5 release). This
table tracks audit entries of security events that happen in the
application. In almost all cases, users want to see audit activity that
occurs in a certain time frame. As a result, date-range partitioning
was a natural fit for how the data would be accessed.

To look at this in more detail, imagine a simplified `audit_events` schema:

```sql
CREATE TABLE audit_events (
  id SERIAL NOT NULL PRIMARY KEY,
  author_id INT NOT NULL,
  details jsonb NOT NULL,
  created_at timestamptz NOT NULL);
```

Now imagine typical queries in the UI would display the data in a
certain date range, like a single week:

```sql
SELECT *
FROM audit_events
WHERE created_at >= '2020-01-01 00:00:00'
  AND created_at < '2020-01-08 00:00:00'
ORDER BY created_at DESC
LIMIT 100
```

If the table is partitioned on the `created_at` column the base table would
look like:

```sql
CREATE TABLE audit_events (
  id SERIAL NOT NULL,
  author_id INT NOT NULL,
  details jsonb NOT NULL,
  created_at timestamptz NOT NULL,
  PRIMARY KEY (id, created_at))
PARTITION BY RANGE(created_at);
```

NOTE:
The primary key of a partitioned table must include the partition key as
part of the primary key definition.

And we might have a list of partitions for the table, such as:

```sql
audit_events_202001 FOR VALUES FROM ('2020-01-01') TO ('2020-02-01')
audit_events_202002 FOR VALUES FROM ('2020-02-01') TO ('2020-03-01')
audit_events_202003 FOR VALUES FROM ('2020-03-01') TO ('2020-04-01')
```

Each partition is a separate physical table, with the same structure as
the base `audit_events` table, but contains only data for rows where the
partition key falls in the specified range. For example, the partition
`audit_events_202001` contains rows where the `created_at` column is
greater than or equal to `2020-01-01` and less than `2020-02-01`.

Now, if we look at the previous example query again, the database can
use the `WHERE` to recognize that all matching rows are in the
`audit_events_202001` partition. Rather than searching all of the data
in all of the partitions, it can search only the single month's worth
of data in the appropriate partition. In a large table, this can
dramatically reduce the amount of data the database needs to access.
However, imagine a query that does not filter based on the partitioning
key, such as:

```sql
SELECT *
FROM audit_events
WHERE author_id = 123
ORDER BY created_at DESC
LIMIT 100
```

In this example, the database can't prune any partitions from the search,
because matching data could exist in any of them. As a result, it has to
query each partition individually, and aggregate the rows into a single result
set. Because `author_id` would be indexed, the performance impact could
likely be acceptable, but on more complex queries the overhead can be
substantial. Partitioning should only be leveraged if the access patterns
of the data support the partitioning strategy, otherwise performance
suffers.

### Hash Partitioning

Hash partitioning splits a logical table into a series of partitioned
tables. Each partition corresponds to the ID range that matches
a hash and remainder. For example, if partitioning `BY HASH(id)`, rows
with `hash(id) % 64 == 1` would end up in the partition
`WITH (MODULUS 64, REMAINDER 1)`.

When hash partitioning, you must include a `WHERE hashed_column = ?` condition in
every performance-sensitive query issued by the application. If this is not possible,
hash partitioning may not be the correct fit for your use case.

Hash partitioning has one main advantage: it is the only type of partitioning that
can enforce uniqueness on a single numeric `id` column. (While also possible with
range partitioning, it's rarely the correct choice).

Hash partitioning has downsides:

- The number of partitions must be known up-front.
- It's difficult to move new data to an extra partition if current partitions become too large.
- Range queries, such as `WHERE id BETWEEN ? and ?`, are unsupported.
- Lookups by other keys, such as `WHERE other_id = ?`, are unsupported.

For this reason, it's often best to choose a large number of hash partitions to accommodate future table growth.

## Partitioning a table (Range)

Unfortunately, tables can only be partitioned at their creation, making
it nontrivial to apply to a busy database. A suite of migration
tools have been developed to enable backend developers to partition
existing tables. This migration process takes multiple steps which must
be split across several releases.

### Caveats

The partitioning migration helpers work by creating a partitioned duplicate
of the original table and using a combination of a trigger and a background
migration to copy data into the new table. Changes to the original table
schema can be made in parallel with the partitioning migration, but they
must take care to not break the underlying mechanism that makes the migration
work. For example, if a column is added to the table that is being
partitioned, both the partitioned table and the trigger definition must
be updated to match.

### Step 1: Creating the partitioned copy (Release N)

The first step is to add a migration to create the partitioned copy of
the original table. This migration creates the appropriate
partitions based on the data in the original table, and install a
trigger that syncs writes from the original table into the
partitioned copy.

An example migration of partitioning the `audit_events` table by its
`created_at` column would look like:

```ruby
class PartitionAuditEvents < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  def up
    partition_table_by_date :audit_events, :created_at
  end

  def down
    drop_partitioned_table_for :audit_events
  end
end
```

After this has executed, any inserts, updates, or deletes in the
original table are also duplicated in the new table. For updates and
deletes, the operation only has an effect if the corresponding row
exists in the partitioned table.

### Step 2: Backfill the partitioned copy (Release N)

The second step is to add a post-deployment migration that schedules
the background jobs that backfill existing data from the original table
into the partitioned copy.

Continuing the above example, the migration would look like:

```ruby
class BackfillPartitionAuditEvents < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    enqueue_partitioning_data_migration :audit_events
  end

  def down
    cleanup_partitioning_data_migration :audit_events
  end
end
```

This step [queues a batched background migration](batched_background_migrations.md#queueing) internally with BATCH_SIZE and SUB_BATCH_SIZE as `50,000` and `2,500`. Refer [Batched Background migrations guide](batched_background_migrations.md) for more details.

### Step 3: Post-backfill cleanup (Release N+1)

This step must occur at least one release after the release that
includes step (2). This gives time for the background
migration to execute properly in self-managed installations. In this step,
add another post-deployment migration that cleans up after the
background migration. This includes forcing any remaining jobs to
execute, and copying data that may have been missed, due to dropped or
failed jobs.

Once again, continuing the example, this migration would look like:

```ruby
class CleanupPartitionedAuditEventsBackfill < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    finalize_backfilling_partitioned_table :audit_events
  end

  def down
    # no op
  end
end
```

After this migration completes, the original table and partitioned
table should contain identical data. The trigger installed on the
original table guarantees that the data remains in sync going forward.

### Step 4: Swap the partitioned and non-partitioned tables (Release N+1)

This step replaces the non-partitioned table with its partitioned copy, this should be used only after all other migration steps have completed successfully.

Some limitations to this method MUST be handled before, or during, the swap migration:

- Secondary indexes and foreign keys are not automatically recreated on the partitioned table.
- Some types of constraints (UNIQUE and EXCLUDE) which rely on indexes, are not automatically recreated
  on the partitioned table, since the underlying index will not be present.
- Foreign keys referencing the original non-partitioned table should be updated to reference the
  partitioned table. This is not supported in PostgreSQL 11.
- Views referencing the original table are not automatically updated to reference the partitioned table.

```ruby
# frozen_string_literal: true

class SwapPartitionedAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  def up
    replace_with_partitioned_table :audit_events
  end

  def down
    rollback_replace_with_partitioned_table :audit_events
  end
end
```

After this migration completes:

- The partitioned table replaces the non-partitioned (original) table.
- The sync trigger created earlier is dropped.

The partitioned table is now ready for use by the application.

## Partitioning a table (Hash)

Hash partitioning divides data into partitions based on a hash of their ID.
It works well only if most queries against the table include a clause like `WHERE id = ?`,
so that PostgreSQL can decide which partition to look in based on the ID or ids being requested.

Another key downside is that hash partitioning does not allow adding additional partitions after table creation.
The correct number of partitions must be chosen up-front.

Hash partitioning is the only type of partitioning (aside from some complex uses of list partitioning) that can guarantee
uniqueness of an ID across multiple partitions at the database level.

## Partitioning a table (List)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96815) in GitLab 15.4.

Add the partitioning key column to the table you are partitioning.
Include the partitioning key in the following constraints:

- The primary key.
- All foreign keys referencing the table to be partitioned.
- All unique constraints.

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

This migration can be automatically generated using:

```shell
./scripts/partitioning/generate-fk --source source_table_name --target target_table_name
```

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
  TABLE_FK = :table_references_by_fk
  PARENT_TABLE_NAME = :p_table_name
  FIRST_PARTITION = 100
  PARTITION_COLUMN = :partition_id

  def up
    convert_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION,
      lock_tables: [TABLE_FK, TABLE_NAME]
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

If the partitioning constraint migration takes [more than 10 minutes](../migration_style_guide.md#how-long-a-migration-should-take) to finish,
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
