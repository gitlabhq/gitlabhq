---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Sliding List partitioning
---

## Description

The sliding list partitioning strategy is a dynamic partitioning approach that creates sequential numeric partitions
and automatically manages their lifecycle.

Unlike other partitioning strategies, sliding list partitioning uses a simple incrementing integer as the partition key
and provides custom logic to determine when to create new partitions and when to drop old ones.

This strategy is particularly useful for tables that need to maintain a rolling window of data where old partitions
can be safely removed once their data has been processed or is no longer needed (for example, after 'X' days or size > 'X' bytes).

## Workflow

### Register the Model for partition management

On `Gitlab.com` partitions are not created on application startup, they are created by the _PartitionManagementWorker_,
which executes several times per day. The model that uses sliding list partitioning should also be added in
`Gitlab::Database::Partitioning.register_models` for the PartitionManagementWorker to handle them.

### Define partitioning blocks

[PartitionManager](https://gitlab.com/gitlab-org/gitlab/blob/b3f6a67dbcd01509128f5c21a8f6d4f69b7776f5/lib/gitlab/database/partitioning/partition_manager.rb#L40)
uses `next_partition_if` and `detach_partition_if` to determine `missing_partitions` and `extra_partitions` respectively.
Define blocks for them, so that it can be dynamically decided when to add new partition and drop the old ones.

{{< alert type="note" >}}

Make sure proper indexes are used for filter conditions used within the partitioning blocks.

{{< /alert >}}

**Example:**

```ruby
class LooseForeignKeys::DeletedRecord < Gitlab::Database::SharedModel
  include PartitionedTable

  PARTITION_DURATION = 1.day

  partitioned_by :partition, strategy: :sliding_list,
    next_partition_if: ->(active_partition) do
      oldest_record_in_partition = LooseForeignKeys::DeletedRecord
        .select(:id, :created_at)
        .for_partition(active_partition.value)
        .order(:id)
        .limit(1)
        .take

      oldest_record_in_partition.present? &&
        oldest_record_in_partition.created_at < PARTITION_DURATION.ago
    end,
    detach_partition_if: ->(partition) do
      !LooseForeignKeys::DeletedRecord
        .for_partition(partition.value)
        .status_pending
        .exists?
    end
end
```

This ensures that:

- New partitions are created daily.
- Old partitions are only removed after all records have been processed.
- The system maintains a rolling window of data based on the retention logic.

## When not to use

Avoid sliding list partitioning when:

- Data needs to be retained permanently: Use time-based or range partitioning instead.
- Simple time-based archival: Use `daily` or `monthly` strategies with `retain_for` option.
- Even data distribution is priority: Use hash-based partitioning.
