---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Int range partitioning
---

> [!warning]
> Do not introduce new usages of int range partitioning. It is deprecated due to incompatibility with cells.
>
> When migrating data between cells, the partition for a given key range must already exist on
> the target cell.
> More fundamentally, partition topology is a cell-local implementation detail, not part of the
> cross-cell migration contract, so migrating data between cells must be possible without the
> destination cell knowing the source cell's partitioning scheme.
> For more information, see [work item 604729](https://gitlab.com/gitlab-org/gitlab/-/work_items/604729).

## Description

Int range partitioning is a technique for dividing a large table into smaller,
more manageable chunks based on an integer column, such that each partition
contains a range of integers.
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

> [!note]
> The primary key of a partitioned table must include the partition key as
> part of the primary key definition.

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
`merge_request_diff_files_1` partition. Rather than searching all the data
in all the partitions, it can search only the data in the appropriate partition. In a large table, this can
dramatically reduce the amount of data the database needs to access.

## ActiveRecord model

An ActiveRecord model that uses the int range partitioning strategy will have a
`partitioned_by` call similar to the example below.
This is necessary for the `PartitionManager` to know how to create partitions dynamically.

```ruby
  PARTITION_SIZE = 2_000_000
  partitioned_by :namespace_id, strategy: :int_range, partition_size: PARTITION_SIZE
```

The partition size can be decided based on the anticipated growth of the table.

Do not forget to register your model on the partition manager, in the file `config/initializers/postgres_partitioning.rb`.

If a table is partitioned by a column that is not backed by a sequence on the partitioned table, define the
`sequence_name` of the column. This is needed so the partition manager can get the correct `min_id` when
creating new partitions.

```ruby
partitioned_by :project_id, strategy: :int_range, partition_size: 2_000_000, sequence_name: 'projects_id_seq'
```
