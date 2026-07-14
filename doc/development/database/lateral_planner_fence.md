---
stage: Database Excellence
group: Database Health
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Forcing index seeks with LATERAL joins
---

When a query filters a table by an `IN (...)` list of values, the PostgreSQL planner estimates how many rows the
predicate matches and chooses a plan from that estimate. When the estimate is wrong, the planner can choose a
sequential scan or hash join over an index scan and degrade the query by orders of magnitude. Rewriting the query as a
`LATERAL` join removes the planner's option to make that choice, forcing one index seek per value regardless of the
row-count estimate.

[Efficient `IN` operator queries](efficient_in_operator_queries.md). The pattern described here covers a narrower case: a single
filtered lookup where the planner mis-costs the `IN` predicate itself. It also requires a specific
sorting which in is not needed in some cases like `DELETE` queries.

## Symptoms

Reach for this pattern when all of the following hold:

- A query filters a table on a column using `WHERE col IN (<list>)` or `WHERE col IN (SELECT ... LIMIT n)`, where the
  list of values is supplied at runtime (for example, a batch of parent IDs).
- The filtered column has moderate cardinality: values that are common enough that the planner over-estimates how
  many rows match, but not so common that they appear in the most-common-values (MCV) statistics.
- `EXPLAIN (ANALYZE, BUFFERS)` shows a `Seq Scan` or `Hash Join` where you expected an `Index Scan`,
  often returning far fewer rows than the planner's estimated row count.
- The query is intermittently slow: fast for some value sets, multi-second for others, because the plan flips with the
  estimate.

A useful tell: the query reads many buffers and returns few (or zero) rows.

## Why `MATERIALIZED` does not help

A common first attempt is to wrap the inner query in a CTE with `MATERIALIZED` to fence off the planner. This does not
help here, because the sequential scan is on the subquery's own table access, not on a join the CTE boundary would
separate. Materializing the result of a seq scan still runs the seq scan.

## Rewrite the query as a LATERAL join

Restructure the query so each value drives its own index seek through a `LATERAL` join over a `VALUES` list:

### Before: `IN (...)` subquery

```sql
DELETE FROM "issues"
WHERE ("issues"."id") IN (
  SELECT "issues"."id" FROM "issues"
  WHERE "issues"."project_id" IN (1, 2, 3, ...)
  LIMIT 1000
)
```

The planner is free to satisfy the inner `SELECT` with a sequential scan when it mis-estimates the `project_id IN (...)`
selectivity.

### After: `LATERAL` join

```sql
DELETE FROM "issues"
WHERE ("issues"."id") IN (
  SELECT "lateral_rows"."id"
  FROM (VALUES (1), (2), (3), ...) AS parent("project_id"),
  LATERAL (
    SELECT "issues"."id" FROM "issues"
    WHERE "issues"."project_id" = "parent"."project_id"
    LIMIT 1000
  ) lateral_rows
  LIMIT 1000
)
```

Because the inner `SELECT` now filters on a single `project_id` value (`= "parent"."project_id"`), the planner has no
multi-value estimate to get wrong: an equality predicate on an indexed column resolves to an index seek. The list is
evaluated once per value through the `LATERAL` join.

### Preserving limits

- The outer `LIMIT` preserves the original cap on the total number of rows processed across all values.
- An inner `LIMIT` bounds the work done per value, so a single hot value cannot dominate the batch.

## When not to use this pattern

This is a targeted fix, not a default. Prefer the plain `IN` form when:

- The list is small. With a handful of values, the per-value `LATERAL` invocation can cost more than a single
  set-based scan. The pattern pays off when the value list is large enough that a misestimated `IN` predicate flips to
  a seq scan.
- The `IN` form already produces a stable index-scan plan. Verify with `EXPLAIN` on real data
  ([using Database Lab](database_lab.md)) before rewriting. Do not apply it speculatively.
- The column is genuinely low-selectivity, so most rows match. If a seq scan is actually the right plan, forcing
  per-value seeks is slower.

Forcing a plan removes the planner's ability to adapt, so confirm the rewrite wins on representative data and at the
batch sizes you use in production.

## Examples

- `LooseForeignKeys::CleanerService` rewrote its child-row lookup from an `IN (...)` predicate to a `LATERAL` join to
  stop the loose-foreign-keys cleaner from regressing to sequential scans on high-traffic child tables
  (for example `ci_build_names`). See merge request
  [!235721](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235721) and the example plans linked from it.
- The same structural fix was applied earlier to the `commit_shas_from_metadata` lookup. See merge request
  [!239187](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239187).
