---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Group hierarchy query optimization
---

This document describes the hierarchy cache optimization strategy that helps with loading all descendants (subgroups or projects) from large group hierarchies with minimal overhead. The optimization was implemented within this GitLab [epic](https://gitlab.com/groups/gitlab-org/-/epics/11469).

The optimization is enabled automatically via the [`Namespaces::EnableDescendantsCacheCronWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/namespaces/enable_descendants_cache_cron_worker.rb?ref_type=heads) worker for group hierarchies with descendant counts above 700 (projects and groups). Enabling the optimization manually for smaller groups will likely not have noticeable effects.

## Performance comparison

Loading all group IDs for the `gitlab-org` group, including itself and its descendants.

{{< tabs >}}

{{< tab title="Optimized cached query" >}}

**42 buffers** (~336.00 KiB) from the buffer pool

```sql
SELECT "namespaces"."id" FROM UNNEST(
  COALESCE(
    (
      SELECT ids FROM (
        SELECT "namespace_descendants"."self_and_descendant_group_ids" AS ids
        FROM "namespace_descendants"
        WHERE "namespace_descendants"."outdated_at" IS NULL AND
        "namespace_descendants"."namespace_id" = 22
      ) cached_query
    ),
    (
      SELECT ids
      FROM (
        SELECT ARRAY_AGG("namespaces"."id") AS ids
        FROM (
          SELECT namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)] AS id
          FROM "namespaces"
          WHERE "namespaces"."type" = 'Group' AND
          (traversal_ids @> ('{22}'))
        ) namespaces
      ) consistent_query
    )
  )
) AS namespaces(id)
```

```plaintext
 Function Scan on unnest namespaces  (cost=1296.82..1296.92 rows=10 width=8) (actual time=0.193..0.236 rows=GROUP_COUNT loops=1)
   Buffers: shared hit=42
   I/O Timings: read=0.000 write=0.000
   InitPlan 1 (returns $0)
     ->  Index Scan using namespace_descendants_12_pkey on gitlab_partitions_static.namespace_descendants_12 namespace_descendants  (cost=0.14..3.16 rows=1 width=769) (actual time=0.022..0.023 rows=1 loops=1)
           Index Cond: (namespace_descendants.namespace_id = 9970)
           Filter: (namespace_descendants.outdated_at IS NULL)
           Rows Removed by Filter: 0
           Buffers: shared hit=5
           I/O Timings: read=0.000 write=0.000
   InitPlan 2 (returns $1)
     ->  Aggregate  (cost=1293.62..1293.63 rows=1 width=32) (actual time=0.000..0.000 rows=0 loops=0)
           I/O Timings: read=0.000 write=0.000
           ->  Bitmap Heap Scan on public.namespaces namespaces_1  (cost=62.00..1289.72 rows=781 width=28) (actual time=0.000..0.000 rows=0 loops=0)
                 I/O Timings: read=0.000 write=0.000
                 ->  Bitmap Index Scan using index_namespaces_on_traversal_ids_for_groups  (cost=0.00..61.81 rows=781 width=0) (actual time=0.000..0.000 rows=0 loops=0)
                       Index Cond: (namespaces_1.traversal_ids @> '{9970}'::integer[])
                       I/O Timings: read=0.000 write=0.000
Settings: seq_page_cost = '4', effective_cache_size = '472585MB', jit = 'off', work_mem = '100MB', random_page_cost = '1.5'
```

{{< /tab >}}

{{< tab title="Traversal ids based lookup query" >}}

**1037 buffers** (~8.10 MiB) from the buffer pool

```sql
SELECT namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)] AS id
FROM "namespaces"
WHERE "namespaces"."type" = 'Group' AND
(traversal_ids @> ('{22}'))
```

```plaintext
 Bitmap Heap Scan on public.namespaces  (cost=62.00..1291.67 rows=781 width=4) (actual time=0.670..2.273 rows=GROUP_COUNT loops=1)
   Buffers: shared hit=1037
   I/O Timings: read=0.000 write=0.000
   ->  Bitmap Index Scan using index_namespaces_on_traversal_ids_for_groups  (cost=0.00..61.81 rows=781 width=0) (actual time=0.561..0.561 rows=1154 loops=1)
         Index Cond: (namespaces.traversal_ids @> '{9970}'::integer[])
         Buffers: shared hit=34
         I/O Timings: read=0.000 write=0.000
Settings: work_mem = '100MB', random_page_cost = '1.5', seq_page_cost = '4', effective_cache_size = '472585MB', jit = 'off'
```

{{< /tab >}}

{{< /tabs >}}

## How to use the optimization

The optimization will be automatically used if you use one of these ActiveRecord scopes:

```ruby
# Loading all groups:
group.self_and_descendants

# Using the IDs in subqueries:
group.self_and_descendant_ids

NamespaceSetting.where(namespace_id: group.self_and_descendant_ids)

# Loading all projects:
group.all_projects

# Using the IDs in subqueries
MergeRequest.where(target_project_id: group.all_project_ids)
```

## Cache invalidation

When the group hierarchy changes, for example when a new project or subgroup is added, the cache is invalidated within the same transaction. A periodic worker called [`Namespaces::ProcessOutdatedNamespaceDescendantsCronWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/namespaces/process_outdated_namespace_descendants_cron_worker.rb?ref_type=heads) will update the cache with a slight delay. The invalidation is implemented using ActiveRecord callbacks.

While the cache is invalidated, the hierarchical database queries will continue returning consistent values using the uncached (unoptimized) `traversal_ids` based query query.

## Consistent queries

The lookup queries implement an `||` (or) functionality in SQL which allows us to check for the cached values first. If those are not present, we fall back to a full lookup of all groups or projects in the hierarchy.

For simplification, this is how we would implement the lookup in Ruby:

```ruby
if cached? && cache_up_to_date?
  return cached_project_ids
else
  return Project.where(...).pluck(:id)
end
```

In `SQL`, we leverage the `COALESCE` function, which returns the first non-NULL expression from a list of expressions. If the first expression is not NULL, the subsequent expressions are not evaluated.

```sql
SELECT COALESCE(
  (SELECT 1), -- cached query
  (SELECT 2 FROM pg_sleep(5)) -- non-cached query
)
```

The query above returns immediately however, if the first subquery returns null, the DB will execute the second query:

```sql
SELECT COALESCE(
  (SELECT NULL), -- cached query
  (SELECT 2 FROM pg_sleep(5)) -- non-cached query
)
```

## The `namespace_descendants` database table

The cached subgroup and project ids are stored in the `namespace_descendants` database table as arrays, the most important columns:

- `namespace_id`: primary key, this can be a top-level group ID or a subgroup ID.
- `self_and_descendant_group_ids`: all group IDs as an array
- `all_project_ids`: all project IDs as an array
- `outdated_at`: signals that the cache is outdated

## Cached database query

The query consists of three parts:

- cached query
- fallback, non-cached query
- outer query where additional filtering and data loading (`JOIN`) can be done

Cached query:

```sql
SELECT ids -- One row, array of ids
FROM (
  SELECT "namespace_descendants"."self_and_descendant_group_ids" AS ids
  FROM "namespace_descendants"
  WHERE "namespace_descendants"."outdated_at" IS NULL AND
  "namespace_descendants"."namespace_id" = 22
) cached_query
```

The query returns `NULL` when the cache is outdated or the cache record does not exist.

Fallback query, based on the `traversal_ids` lookup:

```sql
SELECT ids -- One row, array of ids
FROM (
  SELECT ARRAY_AGG("namespaces"."id") AS ids
  FROM (
    SELECT namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)] AS id
    FROM "namespaces"
    WHERE "namespaces"."type" = 'Group' AND
    (traversal_ids @> ('{22}'))
  ) namespaces
)
```

Final query, combining the queries into one:

```sql
SELECT "namespaces"."id" FROM UNNEST(
  COALESCE(
    (
      SELECT ids FROM (
        SELECT "namespace_descendants"."self_and_descendant_group_ids" AS ids
        FROM "namespace_descendants"
        WHERE "namespace_descendants"."outdated_at" IS NULL AND
        "namespace_descendants"."namespace_id" = 22
      ) cached_query
    ),
    (
      SELECT ids
      FROM (
        SELECT ARRAY_AGG("namespaces"."id") AS ids
        FROM (
          SELECT namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)] AS id
          FROM "namespaces"
          WHERE "namespaces"."type" = 'Group' AND
          (traversal_ids @> ('{22}'))
        ) namespaces
      ) consistent_query
    )
  )
) AS namespaces(id)
```
