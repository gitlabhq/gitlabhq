---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Database table partitioning

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

## Determining when to use partitioning

While partitioning can be very useful when properly applied, it's
imperative to identify if the data and workload of a table naturally fit a
partitioning scheme. There are a few details you'll have to understand
in order to decide if partitioning is a good fit for your particular
problem.

First, a table is partitioned on a partition key, which is a column or
set of columns which determine how the data will be split across the
partitions. The partition key is used by the database when reading or
writing data, to decide which partition(s) need to be accessed. The
partition key should be a column that would be included in a `WHERE`
clause on almost all queries accessing that table.

Second, it's necessary to understand the strategy the database will
use to split the data across the partitions. The scheme supported by the
GitLab migration helpers is date-range partitioning, where each partition
in the table contains data for a single month. In this case, the partitioning
key would need to be a timestamp or date column. In order for this type of
partitioning to work well, most queries would need to access data within a
certain date range.

For a more concrete example, the `audit_events` table can be used, which
was the first table to be partitioned in the application database
(scheduled for deployment with the GitLab 13.5 release). This
table tracks audit entries of security events that happen in the
application. In almost all cases, users want to see audit activity that
occurs in a certain timeframe. As a result, date-range partitioning
was a natural fit for how the data would be accessed.

To look at this in more detail, imagine a simplified `audit_events` schema:

```sql
CREATE TABLE audit_events (
  id SERIAL NOT NULL PRIMARY KEY,
  author_id INT NOT NULL,
  details jsonb NOT NULL,
  created_at timestamptz NOT NULL);
```

Now imagine typical queries in the UI would display the data within a
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

NOTE: **Note:**
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
use the `WHERE` to recognize that all matching rows will be in the
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
set. Since `author_id` would be indexed, the performance impact could
likely be acceptable, but on more complex queries the overhead can be
substantial. Partitioning should only be leveraged if the access patterns
of the data support the partitioning strategy, otherwise performance will
suffer.

## Partitioning a table

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
partitioned, both the partitioned table and the trigger definition need to
be updated to match.

### Step 1: Creating the partitioned copy (Release N)

The first step is to add a migration to create the partitioned copy of
the original table. This migration will also create the appropriate
partitions based on the data in the original table, and install a
trigger that will sync writes from the original table into the
partitioned copy.

An example migration of partitioning the `audit_events` table by its
`created_at` column would look like:

```ruby
class PartitionAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  def up
    partition_table_by_date :audit_events, :created_at
  end

  def down
    drop_partitioned_table_for :audit_events
  end
end
```

Once this has executed, any inserts, updates or deletes in the
original table will also be duplicated in the new table. For updates and
deletes, the operation will only have an effect if the corresponding row
exists in the partitioned table.

### Step 2: Backfill the partitioned copy (Release N)

The second step is to add a post-deployment migration that will schedule
the background jobs that will backfill existing data from the original table
into the partitioned copy.

Continuing the above example, the migration would look like:

```ruby
class BackfillPartitionAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  def up
    enqueue_partitioning_data_migration :audit_events
  end

  def down
    cleanup_partitioning_data_migration :audit_events
  end
end
```

This step uses the same mechanism as any background migration, so you
may want to read the [Background Migration](../background_migrations.md)
guide for details on that process. Background jobs are scheduled every
2 minutes and copy `50_000` records at a time, which can be used to
estimate the timing of the background migration portion of the
partitioning migration.

### Step 3: Post-backfill cleanup (Release N+1)

The third step must occur at least one release after the release that
includes the background migration. This gives time for the background
migration to execute properly in self-managed installations. In this step,
add another post-deployment migration that will cleanup after the
background migration. This includes forcing any remaining jobs to
execute, and copying data that may have been missed, due to dropped or
failed jobs.

Once again, continuing the example, this migration would look like:

```ruby
class CleanupPartitionedAuditEventsBackfill < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  def up
    finalize_backfilling_partitioned_table :audit_events
  end

  def down
    # no op
  end
end
```

After this migration has completed, the original table and partitioned
table should contain identical data. The trigger installed on the
original table guarantees that the data will remain in sync going
forward.

### Step 4: Swap the partitioned and non-partitioned tables (Release N+1)

The final step of the migration will make the partitioned table ready
for use by the application. This section will be updated when the
migration helper is ready, for now development can be followed in the
[Tracking Issue](https://gitlab.com/gitlab-org/gitlab/-/issues/241267).
