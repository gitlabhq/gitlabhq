---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Merge request analytics with ClickHouse
---

The [merge request analytics feature](../../../user/analytics/merge_request_analytics.md)
shows statistics about the merged merge requests in the project and also exposes record-level metadata.
Aggregations include:

- **Average time to merge**: The duration between the creation time and the merge time.
- **Monthly aggregations**: A chart of 12 months of the merged merge requests.

Under the chart, the user can see the paginated list of merge requests, 12 months per page.

You can filter by:

- Author
- Assignee
- Labels
- Milestone
- Source branch
- Target branch

## Current performance problems

- The aggregation queries require specialized indexes, which cost additional
  disk space (index-only scans).
- Querying the whole 12 months is slow (statement timeout). Instead, the frontend
  requests data per month (12 database queries).
- Even with specialized indexes, making the feature available on the group level
  would not be feasible due to the large volume of merge requests.

## Example queries

Get the number of merge requests merged in a given month:

```sql
SELECT COUNT(*)
FROM "merge_requests"
INNER JOIN "merge_request_metrics" ON "merge_request_metrics"."merge_request_id" = "merge_requests"."id"
WHERE (NOT EXISTS
         (SELECT 1
          FROM "banned_users"
          WHERE (merge_requests.author_id = banned_users.user_id)))
  AND "merge_request_metrics"."target_project_id" = 278964
  AND "merge_request_metrics"."merged_at" >= '2022-12-01 00:00:00'
  AND "merge_request_metrics"."merged_at" <= '2023-01-01 00:00:00'
```

The `merge_request_metrics` table was de-normalized (by adding `target_project_id`)
to improve the first-page load time. The query itself works well for smaller date ranges,
however, it can time out as the date range increases.

After an extra filter is added, the query becomes more complex because it must also
filter the `merge_requests` table:

```sql
SELECT COUNT(*)
FROM "merge_requests"
INNER JOIN "merge_request_metrics" ON "merge_request_metrics"."merge_request_id" = "merge_requests"."id"
WHERE (NOT EXISTS
         (SELECT 1
          FROM "banned_users"
          WHERE (merge_requests.author_id = banned_users.user_id)))
  AND "merge_requests"."author_id" IN
    (SELECT "users"."id"
     FROM "users"
     WHERE (LOWER("users"."username") IN (LOWER('ahegyi'))))
  AND "merge_request_metrics"."target_project_id" = 278964
  AND "merge_request_metrics"."merged_at" >= '2022-12-01 00:00:00'
  AND "merge_request_metrics"."merged_at" <= '2023-01-01 00:00:00'
```

To calculate mean time to merge, we also query the total time between the
merge request creation time and merge time.

```sql
SELECT EXTRACT(epoch
               FROM SUM(AGE(merge_request_metrics.merged_at, merge_request_metrics.created_at)))
FROM "merge_requests"
INNER JOIN "merge_request_metrics" ON "merge_request_metrics"."merge_request_id" = "merge_requests"."id"
WHERE (NOT EXISTS
         (SELECT 1
          FROM "banned_users"
          WHERE (merge_requests.author_id = banned_users.user_id)))
  AND "merge_requests"."author_id" IN
    (SELECT "users"."id"
     FROM "users"
     WHERE (LOWER("users"."username") IN (LOWER('ahegyi'))))
  AND "merge_request_metrics"."target_project_id" = 278964
  AND "merge_request_metrics"."merged_at" >= '2022-08-01 00:00:00'
  AND "merge_request_metrics"."merged_at" <= '2022-09-01 00:00:00'
  AND "merge_request_metrics"."merged_at" > "merge_request_metrics"."created_at"
LIMIT 1
```

## Store merge request data in ClickHouse

Several other use cases exist for storing and querying merge request data in
[ClickHouse](../../../integration/clickhouse.md). In this document, we focus on this particular feature.

The core data exists in the `merge_request_metrics` and in the `merge_requests`
database tables. Some filters require extra tables to be joined:

- `banned_users`: Filter out merge requests created by banned users.
- `labels`: A merge request can have one or more assigned labels.
- `assignees`: A merge request can have one or more assignees.
- `merged_at`: The `merged_at` column is located in the `merge_request_metrics` table.

The `merge_requests` table contains data that can be filtered directly:

- **Author**: via the `author_id` column.
- **Milestone**: via the `milestone_id` column.
- **Source branch**.
- **Target branch**.
- **Project**: via the `project_id` column.

### Keep ClickHouse data up to date

Replicating or syncing the `merge_requests` table is unfortunately not enough.
Separate queries to associated tables are required to insert one de-normalized
`merge_requests` row into the ClickHouse database.

Change detection is non-trivial to implement. A few corners we could cut:

- The feature is available for GitLab Premium and GitLab Ultimate customers.
  We don't have to sync all the data, but instead sync only the `merge_requests` records
  which are part of licensed groups.
- Data changes (often) happen via the `MergeRequest` services, where bumping the
  `updated_at` timestamp column is mostly consistent. Some sort of incremental
  synchronization process could be implemented.
- We only need to query the merged merge requests. After the merge, the record rarely changes.

### Database table structure

The database table structure uses de-normalization to make all required columns
available in one database table. This eliminates the need for `JOINs`.

```sql
CREATE TABLE merge_requests
(
    `id` UInt64,
    `project_id` UInt64 DEFAULT 0 NOT NULL,
    `author_id` UInt64 DEFAULT 0 NOT NULL,
    `milestone_id` UInt64 DEFAULT 0 NOT NULL,
    `label_ids` Array(UInt64) DEFAULT [] NOT NULL,
    `assignee_ids` Array(UInt64) DEFAULT [] NOT NULL,
    `source_branch` String DEFAULT '' NOT NULL,
    `target_branch` String DEFAULT '' NOT NULL,
    `merged_at` DateTime64(6, 'UTC') NOT NULL,
    `created_at` DateTime64(6, 'UTC') DEFAULT now() NOT NULL,
    `updated_at` DateTime64(6, 'UTC') DEFAULT now() NOT NULL
)
ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (project_id, merged_at, id);
```

Similarly to the [activity data example](gitlab_activity_data.md), we use the
`ReplacingMergeTree` engine. Several columns of the merge request record may change,
so keeping the table up-to-date is important.

The database table is ordered by the `project_id, merged_at, id` columns. This ordering
optimizes the table data for our use case: querying the `merged_at` column in a project.

## Rewrite the count query

First, let's generate some data for the table.

```sql
INSERT INTO merge_requests (id, project_id, author_id, milestone_id, label_ids, merged_at, created_at)
SELECT id, project_id, author_id, milestone_id, label_ids, merged_at, created_at
FROM generateRandom('id UInt64, project_id UInt8, author_id UInt8, milestone_id UInt8, label_ids Array(UInt8), merged_at DateTime64(6, \'UTC\'), created_at DateTime64(6, \'UTC\')')
LIMIT 1000000;
```

NOTE:
Some integer data types were cast as `UInt8` so it is highly probable that they
have same values across different rows.

The original count query only aggregated data for one month. With ClickHouse, we can
attempt aggregating the data for the whole year.

PostgreSQL-based count query:

```sql
SELECT COUNT(*)
FROM "merge_requests"
INNER JOIN "merge_request_metrics" ON "merge_request_metrics"."merge_request_id" = "merge_requests"."id"
WHERE (NOT EXISTS
         (SELECT 1
          FROM "banned_users"
          WHERE (merge_requests.author_id = banned_users.user_id)))
  AND "merge_request_metrics"."target_project_id" = 278964
  AND "merge_request_metrics"."merged_at" >= '2022-12-01 00:00:00'
  AND "merge_request_metrics"."merged_at" <= '2023-01-01 00:00:00'
```

ClickHouse query:

```sql
SELECT
  toYear(merged_at) AS year,
  toMonth(merged_at) AS month,
  COUNT(*)
FROM merge_requests
WHERE
  project_id = 200
  AND merged_at BETWEEN '2022-01-01 00:00:00'
  AND '2023-01-01 00:00:00'
GROUP BY year, month
```

The query processed a significantly lower number of rows compared to the generated data.
The `ORDER BY` clause (primary key) is helping the query execution:

```plaintext
11 rows in set. Elapsed: 0.010 sec.
Processed 8.19 thousand rows, 131.07 KB (783.45 thousand rows/s., 12.54 MB/s.)
```

## Rewrite the Mean time to merge query

The query calculates the mean time to merge as:
`duration(created_at, merged_at) / merge_request_count`. The calculation is done in
two separate steps:

1. Request the monthly counts and the monthly duration values.
1. Sum the counts to get the yearly count.
1. Sum the durations to get the yearly duration.
1. Divide the durations by the count.

In ClickHouse, we can calculate the mean time to merge with one query:

```sql
SELECT
  SUM(
    dateDiff('second', merged_at, created_at) / 3600 / 24
  ) / COUNT(*) AS mean_time_to_merge -- mean_time_to_merge is in days
FROM merge_requests
WHERE
  project_id = 200
  AND merged_at BETWEEN '2022-01-01 00:00:00'
  AND '2023-01-01 00:00:00'
```

## Filtering

The database queries above can be used as base queries. You can add more filters.
For example, filtering for a label and a milestone:

```sql
SELECT
  toYear(merged_at) AS year,
  toMonth(merged_at) AS month,
  COUNT(*)
FROM merge_requests
WHERE
  project_id = 200
  AND milestone_id = 15
  AND has(label_ids, 118)
  AND -- array includes 118
  merged_at BETWEEN '2022-01-01 00:00:00'
  AND '2023-01-01 00:00:00'
GROUP BY year, month
```

Optimizing a particular filter is usually done with a database index. This particular
query reads 8000 rows:

```plaintext
1 row in set. Elapsed: 0.016 sec.
Processed 8.19 thousand rows, 589.99 KB (505.38 thousand rows/s., 36.40 MB/s.)
```

Adding an index on `milestone_id`:

```sql
ALTER TABLE merge_requests
ADD
  INDEX milestone_id_index milestone_id TYPE minmax GRANULARITY 10;
ALTER TABLE
  merge_requests MATERIALIZE INDEX milestone_id_index;
```

On the generated data, adding the index didn't improve the performance.

### Banned users filter

A recently added feature in GitLab filters out merge requests where the author is
banned by the admins. The banned users are tracked on the instance level in the
`banned_users` database table.

#### Idea 1: Enumerate the banned user IDs

This would require no structural changes to the ClickHouse database schema.
We could query the banned users in the project and filter the values out in query time.

Get the banned users (in PostgreSQL):

```sql
SELECT user_id FROM banned_users
```

In ClickHouse

```sql
SELECT
  toYear(merged_at) AS year,
  toMonth(merged_at) AS month,
  COUNT(*)
FROM merge_requests
WHERE
  author_id NOT IN (1, 2, 3, 4) AND -- banned users
  project_id = 200
  AND milestone_id = 15
  AND has(label_ids, 118) AND -- array includes 118
  merged_at BETWEEN '2022-01-01 00:00:00'
  AND '2023-01-01 00:00:00'
GROUP BY year, month
```

The problem with this approach is that the number of banned users could increase significantly which would make the query bigger and slower.

#### Idea 2: replicate the `banned_users` table

Assuming that the `banned_users table` doesn't grow to millions of rows, we could
attempt to periodically sync the whole table to ClickHouse. With this approach,
a mostly consistent `banned_users` table could be used in the ClickHouse database query:

```sql
SELECT
  toYear(merged_at) AS year,
  toMonth(merged_at) AS month,
  COUNT(*)
FROM merge_requests
WHERE
  author_id NOT IN (SELECT user_id FROM banned_users) AND
  project_id = 200 AND
  milestone_id = 15 AND
  has(label_ids, 118) AND -- array includes 118
  merged_at BETWEEN '2022-01-01 00:00:00' AND '2023-01-01 00:00:00'
GROUP BY year, month
```

Alternatively, the `banned_users` table could be stored as a
[dictionary](https://clickhouse.com/docs/en/sql-reference/dictionaries/external-dictionaries/external-dicts)
to further improve the query performance.

#### Idea 3: Alter the feature

For analytical calculations, it might be acceptable to drop this particular filter.
This approach assumes that including the merge requests of banned users doesn't skew the statistics significantly.
