---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Date range partitioning
---

## Description

The scheme best supported by the GitLab migration helpers is date-range partitioning,
where each partition in the table contains data for a single month. In this case,
the partitioning key must be a timestamp or date column. For this type of
partitioning to work well, most queries must access data in a
certain date range.

For a more concrete example, consider using the `audit_events` table.
It was the first table to be partitioned in the application database. This
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

## Example

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

This step [queues a batched background migration](../batched_background_migrations.md#enqueue-a-batched-background-migration) internally with BATCH_SIZE and SUB_BATCH_SIZE as `50,000` and `2,500`. Refer [Batched Background migrations guide](../batched_background_migrations.md) for more details.

### Step 3: Post-backfill cleanup (Release N+1)

This step must occur at least one release after the release that
includes step (2). This gives time for the background
migration to execute properly in GitLab Self-Managed instances. In this step,
add another post-deployment migration that cleans up after the
background migration. This includes forcing any remaining jobs to
execute, and copying data that may have been missed, due to dropped or
failed jobs.

WARNING:
A required stop must occur between steps 2 and 3 to allow the background migration from step 2 to complete successfully.

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
