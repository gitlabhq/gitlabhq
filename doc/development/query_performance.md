---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Query performance guidelines

This document describes various guidelines to follow when optimizing SQL queries.

When you are optimizing your SQL queries, there are two dimensions to pay attention to:

1. The query execution time. This is paramount as it reflects how the user experiences GitLab.
1. The query plan. Optimizing the query plan is important in allowing queries to independently scale over time. Realizing that an index will keep a query performing well as the table grows before the query degrades is an example of why we analyze these plans.

## Timing guidelines for queries

| Query Type | Maximum Query Time | Notes |
|----|----|---|
| General queries | `100ms` | This is not a hard limit, but if a query is getting above it, it is important to spend time understanding why it can or cannot be optimized. |
| Queries in a migration | `100ms` | This is different than the total [migration time](database_review.md#timing-guidelines-for-migrations). |
| Concurrent operations in a migration | `5min` | Concurrent operations do not block the database, but they block the GitLab update. This includes operations such as `add_concurrent_index` and `add_concurrent_foreign_key`. |
| Background migrations | `1s` |  |
| Service Ping | `1s` | See the [Service Ping docs](usage_ping/index.md#developing-and-testing-service-ping) for more details. |

- When analyzing your query's performance, pay attention to if the time you are seeing is on a [cold or warm cache](#cold-and-warm-cache). These guidelines apply for both cache types.
- When working with batched queries, change the range and batch size to see how it effects the query timing and caching.
- If an existing query is not performing well, make an effort to improve it. If it is too complex or would stall development, create a follow-up so it can be addressed in a timely manner. You can always ask the database reviewer or maintainer for help and guidance.

## Cold and warm cache

When evaluating query performance it is important to understand the difference between
cold and warm cached queries.

The first time a query is made, it is made on a "cold cache". Meaning it needs
to read from disk. If you run the query again, the data can be read from the
cache, or what PostgreSQL calls shared buffers. This is the "warm cache" query.

When analyzing an [`EXPLAIN` plan](understanding_explain_plans.md), you can see
the difference not only in the timing, but by looking at the output for `Buffers`
by running your explain with `EXPLAIN(analyze, buffers)`. [Database Lab](understanding_explain_plans.md#database-lab-engine)
will automatically include these options.

If you are making a warm cache query, you will only see the `shared hits`.

For example in #database-lab:

```plaintext
Shared buffers:
  - hits: 36467 (~284.90 MiB) from the buffer pool
  - reads: 0 from the OS file cache, including disk I/O
```

Or in the explain plan from `psql`:

```sql
Buffers: shared hit=7323
```

If the cache is cold, you will also see `reads`.

In #database-lab:

```plaintext
Shared buffers:
  - hits: 17204 (~134.40 MiB) from the buffer pool
  - reads: 15229 (~119.00 MiB) from the OS file cache, including disk I/O
```

In `psql`:

```sql
Buffers: shared hit=7202 read=121
```
