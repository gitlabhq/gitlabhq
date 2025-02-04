---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Int range partitioning
---

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132148) in GitLab 16.8.

## Description

Int range partitioning is a technique for dividing a large table into smaller,
more manageable chunks based on an integer column.
This can be particularly useful for tables with large numbers of rows,
as it can significantly improve query performance, reduce storage requirements, and simplify maintenance tasks.
For this type of partitioning to work well, most queries must access data in a
certain int range.

To look at this in more detail, imagine a simplified `merge_request_diff_files` schema:

```sql
CREATE TABLE merge_request_diff_files (
  merge_request_diff_id INT NOT NULL,
  relative_order INT NOT NULL,
  PRIMARY KEY (merge_request_diff_id, relative_order));
```

Now imagine typical queries in the UI would display the data in a certain int range:

```sql
SELECT *
FROM merge_request_diff_files
WHERE merge_request_diff_id > 1 AND merge_request_diff_id < 10
LIMIT 100
```

If the table is partitioned on the `merge_request_diff_id` column the base table would look like:

```sql
CREATE TABLE merge_request_diff_files (
  merge_request_diff_id INT NOT NULL,
  relative_order INT NOT NULL,
  PRIMARY KEY (merge_request_diff_id, relative_order))
PARTITION BY RANGE(merge_request_diff_id);
```

NOTE:
The primary key of a partitioned table must include the partition key as
part of the primary key definition.

And we might have a list of partitions for the table, such as:

```sql
merge_request_diff_files_1 FOR VALUES FROM (1) TO (20)
merge_request_diff_files_20 FOR VALUES FROM (20) TO (40)
merge_request_diff_files_40 FOR VALUES FROM (40) TO (60)
```

Each partition is a separate physical table, with the same structure as
the base `merge_request_diff_files` table, but contains only data for rows where the
partition key falls in the specified range. For example, the partition
`merge_request_diff_files_1` contains rows where the `merge_request_diff_id` column is
greater than or equal to `1` and less than `20`.

Now, if we look at the previous example query again, the database can
use the `WHERE` to recognize that all matching rows are in the
`merge_request_diff_files_1` partition. Rather than searching all of the data
in all of the partitions. In a large table, this can
dramatically reduce the amount of data the database needs to access.

## Example

### Step 1: Creating the partitioned copy (Release N)

The first step is to add a migration to create the partitioned copy of
the original table. This migration creates the appropriate
partitions based on the data in the original table, and install a
trigger that syncs writes from the original table into the
partitioned copy.

An example migration of partitioning the `merge_request_diff_commits` table by its
`merge_request_diff_id` column would look like:

```ruby
class PartitionMergeRequestDiffCommits < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  def up
    partition_table_by_int_range(
      'merge_request_diff_commits', 
      'merge_request_diff_id', 
      partition_size: 10_000_000,
      primary_key: %w[merge_request_diff_id relative_order]
    )
  end

  def down
    drop_partitioned_table_for('merge_request_diff_commits')
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
class BackfillPartitionMergeRequestDiffCommits < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    enqueue_partitioning_data_migration :merge_request_diff_commits
  end

  def down
    cleanup_partitioning_data_migration :merge_request_diff_commits
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
class CleanupPartitionMergeRequestDiffCommitsBackfill < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    finalize_backfilling_partitioned_table :merge_request_diff_commits
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

class SwapPartitionMergeRequestDiffCommits < ActiveRecord::Migration[6.0]
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
