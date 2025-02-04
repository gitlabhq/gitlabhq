---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Query performance guidelines
---

This document describes various guidelines to follow when optimizing SQL queries.

When you are optimizing your SQL queries, there are two dimensions to pay attention to:

1. The query execution time. This is paramount as it reflects how the user experiences GitLab.
1. The query plan. Optimizing the query plan is important in allowing queries to independently scale over time. Realizing that an index keeps a query performing well as the table grows before the query degrades is an example of why we analyze these plans.

## Timing guidelines for queries

| Query Type                                | Maximum Query Time | Notes                                                                                                                                                                                                                                                                                                                      |
|-------------------------------------------|--------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| General queries                           | `100ms`            | This is not a hard limit, but if a query is getting above it, it is important to spend time understanding why it can or cannot be optimized.                                                                                                                                                                               |
| Queries in a migration                    | `100ms`            | This is different than the total [migration time](../migration_style_guide.md#how-long-a-migration-should-take).                                                                                                                                                                                                           |
| Concurrent operations in a migration      | `5min`             | Concurrent operations do not block the database, but they block the GitLab update. This includes operations such as `add_concurrent_index` and `add_concurrent_foreign_key`.                                                                                                                                               |
| Concurrent operations in a post migration | `20min`            | Concurrent operations do not block the database, but they block the GitLab post update process. This includes operations such as `add_concurrent_index` and `add_concurrent_foreign_key`. If index creation exceeds 20 minutes, consider [async index creation](adding_database_indexes.md#create-indexes-asynchronously). |
| Background migrations                     | `1s`               |                                                                                                                                                                                                                                                                                                                            |
| Service Ping                              | `1s`               | See the [Metrics Instrumentation docs](../internal_analytics/metrics/metrics_instrumentation.md#database-metrics) for more details.                                                                                                                                                                                                                                                |

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
automatically includes these options.

If you are making a warm cache query, you see only the `shared hits`.

For example, using [Database Lab](database_lab.md):

```plaintext
Shared buffers:
  - hits: 36467 (~284.90 MiB) from the buffer pool
  - reads: 0 from the OS file cache, including disk I/O
```

Or in the explain plan from `psql`:

```sql
Buffers: shared hit=7323
```

If the cache is cold, you also see `reads`.

Using [Database Lab](database_lab.md):

```plaintext
Shared buffers:
  - hits: 17204 (~134.40 MiB) from the buffer pool
  - reads: 15229 (~119.00 MiB) from the OS file cache, including disk I/O
```

In `psql`:

```sql
Buffers: shared hit=7202 read=121
```

## Slow list views and APIs

We often build filtered list views and APIs in GitLab which need to have many
different filter and sorting options. All these options are usually
encapsulated in finders and exposed by API/GraphQL arguments. While we have many possible
[pagination performance optimizations](pagination_performance_guidelines.md)
, there is
often no way to make all combinations of sorting and filtering performant.
Attempts to make many options performant might involve
[adding too many indexes](adding_database_indexes.md)
which sacrifices performance of our primary database. This is only justified
for common use cases and should not be considered as a way to make all
permutations of filter and sort performant. What this means practically is that
there will likely be filtered views and API requests that timeout when certain
sorting or filtering options are applied. We still allow them to be added by
teams where they benefit certain customers with specific combinations of
filtering/sorting, but we need to accept that they will timeout for some users.
