---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: ClickHouse reviewer guidelines
---

This page provides introductory material and guidance for ClickHouse reviewers.

## Scope of a ClickHouse Reviewer's Work

ClickHouse reviewers are domain experts with experience in the ClickHouse OLAP database.
A ClickHouse database review is required whenever application code that interacts with ClickHouse is modified. Examples include:

- Adding a new ClickHouse migration.
- Changing a service class that executes ClickHouse queries.
- Introducing a new ClickHouse query.

The reviewer's responsibility is to verify ClickHouse-specific changes and ensure they work correctly in all GitLab environments where ClickHouse might be configured.

## Resources for ClickHouse Reviewers

- [ClickHouse within GitLab](clickhouse_within_gitlab.md): overview of ClickHouse usage in GitLab.
- [GitLab Database Reviewer Guidelines](../database_reviewer_guidelines.md): general principles that also apply to ClickHouse, especially regarding database migrations.
  ClickHouse follows the same **pre-deployment** and **post-deployment** migration strategy as our relational databases.

## General Guidelines

### Ensuring Database Schema Consistency

The current ClickHouse database schema is stored in a single [`main.sql`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/click_house/main.sql?ref_type=heads) file. This file is automatically updated when migrations are executed, similar to ActiveRecord migrations.

Sometimes, the `main.sql` file is not updated or committed in a merge request, leading to inconsistencies between the schema built from migrations and the committed schema file.
To detect this issue, a CI job (`clickhouse:check-schema`) runs during the **test** stage. This job compares the newly built schema with `main.sql` and fails if discrepancies are found.

- The job is currently allowed to fail due to possible false positives between ClickHouse versions and our schema dump logic.
- As a reviewer, always check the job logs. If it fails, inspect the differences carefully. Non-whitespace related differences should be discussed with the MR author.

To resolve legitimate schema differences, the author may try to ensure that all migrations are executed and dump the schema:

```shell
bundle exec rake gitlab:clickhouse:migrate; bundle exec rake gitlab:clickhouse:schema:dump
```

## Database Query Review

ClickHouse queries in GitLab can be written in two ways:

1. **Raw SQL queries**
1. **QueryBuilder** – an ActiveRecord-like abstraction ([documentation](clickhouse_within_gitlab.md#writing-query-conditions))

When reviewing raw SQL queries, pay close attention to variable interpolation:

- Prefer: Variables must use ClickHouse's placeholder syntax to prevent sensitive data from being logged:

  ```ruby
  sql = 'SELECT * FROM events WHERE id > {min_id:UInt64}'
  ```

- Fixed string interpolation (e.g., when the string is assigned to a Ruby constant) should always use proper quoting to prevent SQL injection or malformed queries:

  ```ruby
  SQL = "SELECT * FROM events WHERE type = #{ClickHouse::Client::Quoting.quote('Issue')}"
  ```

## Database Query Performance Review

While ClickHouse can handle large datasets efficiently, we aim to keep query execution under **10 seconds** even for complex aggregations.
Performance expectations vary based on feature usage and dataset size.

When reviewing a query:

1. Ask the author to provide the raw SQL if it's not clearly visible in the code.
1. Review the table structure (`SHOW CREATE TABLE table_name FORMAT raw`) to understand partitioning and primary keys.
1. Confirm that query filters align with the table's primary key or partitioning columns.

**Example Query:**

```sql
SELECT count(DISTINCT contributions.author_id) AS contributor_count
FROM (
  SELECT argMax(author_id, contributions.updated_at) AS author_id
  FROM contributions
  WHERE
    startsWith(contributions.path, {namespace_path:String})
    AND contributions.created_at BETWEEN {from:Date} AND {to:Date}
  GROUP BY id
) contributions
```

This query performs well if its filter columns (`path`, `created_at`) are included in the primary key:

```sql
CREATE TABLE contributions (
  id UInt64,
  path String,
  author_id UInt64,
  target_type LowCardinality(String),
  action UInt8,
  created_at Date,
  updated_at DateTime64(6, 'UTC')
) ENGINE = ReplacingMergeTree
PARTITION BY toYear(created_at)
ORDER BY (path, created_at, author_id, id);
```

**Performance validation steps:**

- Test with representative parameters (e.g., `namespace_path='9970/'`, date range for one month).
- Run the query and note elapsed time and rows read:

  ```plaintext
  Elapsed: 0.062s
  Read: 1,111,111 rows (15.55 MB)
  ```

- Compare scanned rows to total table rows (`SELECT COUNT(*) FROM contributions`). A well-constrained query should read only a fraction of total rows.

**Inspecting the query plan:**

Use `EXPLAIN indexes=1` to verify that filters use primary key indexes:

```sql
EXPLAIN indexes=1
SELECT count(DISTINCT author_id) FROM contributions ...
FORMAT raw
```

Excerpt from the plan:

```plaintext
PrimaryKey
  Keys:
    path
    created_at
  Condition: and((created_at in (-Inf, 20361]), and((created_at in [20332, +Inf)), (path in ['9970/', '99700'))))
  Parts: 11/11
  Granules: 185/72937
  Search Algorithm: generic exclusion search
```

In the output, look for the `PrimaryKey` section and check the **Granules** ratio.
For example: `185/72937` granules means only a small subset of the table was scanned - ideal for performance.

**When to raise a discussion about performance:**

- The query scans more than **10 million rows**.
- The query consistently exceeds **5–10 seconds** execution time.
- The query will be frequently executed.

Ensure performance validation uses real-world (or synthetic) data from large namespaces (e.g., `gitlab-org` or `gitlab-org/gitlab`).

## Table Engine Specific Behavior

With the **MergeTree** family, the *primary key* (i.e., `ORDER BY`) defines the sort/index, **not** a uniqueness constraint. Rows with the same primary-key values can coexist. If your ingestion pipeline may produce duplicates or updates, you must handle them at read time (or pick an engine that collapses versions).

### `MergeTree` engine

- **No automatic deduplication.**
- Use when data is strictly append-only and duplicates cannot occur (e.g., immutable event logs).

```sql
CREATE TABLE events
(
  event_id  UInt64,
  timestamp DateTime,
  user_id   UInt64,
  payload   String
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(timestamp)
ORDER BY (event_id, timestamp);
```

### `ReplacingMergeTree`

`ReplacingMergeTree` can collapse duplicate primary keys during background merges (non-deterministic timing). Reads can still see multiple versions until merges occur, so query-time deduplication is recommended.

Best practice:

- Provide a version column (monotonic, typically a `DateTime64`).
- Optional deleted flag (`Bool` type) for soft deletes.

{{< alert type="note" >}}

If you omit the version parameter, the deduplicated row after a merge is arbitrary.

{{< /alert >}}

```sql
CREATE TABLE items
(
  id         UInt64,
  name       String,
  status     LowCardinality(String),
  updated_at DateTime64(6), -- acts as the version
  deleted    Bool DEFAULT 0 -- deleted flag for marking a record deleted
)
ENGINE = ReplacingMergeTree(updated_at, deleted)
ORDER BY id
```

To deduplicate the rows, use `argMax` by the version column and `GROUP BY` the primary key:

```sql
SELECT *
FROM (
  SELECT
    id,
    argMax(name,       updated_at) AS name,
    argMax(status,     updated_at) AS status,
    argMax(deleted,    updated_at) AS deleted
  FROM items
  GROUP BY id
) AS items
WHERE deleted = false
```

In the clickhouse console or in the test cases you may use the `FINAL` modifier.

```sql
SELECT * FROM items FINAL;
```

{{< alert type="note" >}}

Avoid FINAL in production queries. FINAL forces on-the-fly collapsing/merging and can be very expensive I/O-wise. Prefer the query-time dedup pattern mentioned above.

{{< /alert >}}
