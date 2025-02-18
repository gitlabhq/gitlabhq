---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Offset pagination optimization
---

In many REST APIs endpoints, we use [offset-based pagination](pagination_guidelines.md#offset-pagination) which uses the `page` URL parameter to paginate through the results. Offset pagination [scales linearly](pagination_guidelines.md#offset-on-a-large-dataset), the higher the page number, the slower the database query gets. This means that for large page numbers, the database query can time out. This usually happens when third-party integrations and scripts interact with the system as users are unlikely to deliberately visit a high page number.

The ideal way of dealing with scalability problems related to offset pagination is switching to [keyset pagination](pagination_guidelines.md#keyset-pagination) however, this is means a breaking API change. To provide a temporary, stop-gap measure, you can use the [`Gitlab::Pagination::Offset::PaginationWithIndexOnlyScan`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/pagination/offset/pagination_with_index_only_scan.rb) class. The optimization can help in certain cases to improve the performance of offset-paginated queries when high `OFFSET` value is present. The performance improvement means that the queries will continue to scale linearly with improved query timings, which means that reaching database timeout will happen at a much higher `page` number if it happens at all.

## Requirements for using the optimization

The optimization avoids calling `SELECT *` when determining the records based on the `ORDER BY`, `OFFSET`, and `LIMIT` clauses and attempts to use an index only scan to reduce database I/O. To use the optimization, the same requirements must be met as for keyset pagination:

- `ORDER BY` clause is present.
- The `ORDER BY` clause uniquely identifies one database column.
  - Good, uses the primary key: `ORDER BY id`
  - Bad, `created_at` not unique: `ORDER BY created_at`
  - Good, there is a [tie-breaker](pagination_performance_guidelines.md#tie-breaker-column): `ORDER BY created_at, id`
- The query is well-covered with a database index.

## How to use the optimizator class

The optimizator class can be used with `ActiveRecord::Relation` objects, as a result, it will return an optimized, [kaminari-paginated](https://github.com/kaminari/kaminari) `ActiveRecord::Relation` object. In case the optimization cannot be applied, the original `ActiveRecord::Relation` object will be used for the pagination.

Basic usage:

```ruby
scope = Issue.where(project_id: 1).order(:id)
records = Gitlab::Pagination::Offset::PaginationWithIndexOnlyScan.new(scope: scope, page: 5, per_page: 100).paginate_with_kaminari
puts records.to_a
```

Optimizations should be always rolled out with feature flags, you can also target the usage of the optimization when certain conditions are met.

```ruby
# - Only apply optimization for large page number lookups
# - When label_names filter parameter is given, the optimziation will not have effect (complex JOIN).
if params[:page] > 100 && params[:label_names].blank? && Feature.enabled?(:my_optimized_offet_query)
  Gitlab::Pagination::Offset::PaginationWithIndexOnlyScan.new(scope: scope, page: params[:page], per_page: params[:per_page]).paginate_with_kaminari
else
  scope.page(params[:page]).per(params[:per_page])
end
```

## How does the optimization work

The optimization takes the passed `ActiveRecord::Relation` object and moves it into a CTE. Within the CTE, the original query is altered to only
select the `ORDER BY` columns. This will make it possible for the database to use index only scan.

When the query is executed, the query within the CTE is evaluated first, the CTE will contain `LIMIT` number of rows with the selected columns.
Using the `ORDER BY` values, a `LATERAL` query will locate the full rows one by one. `LATERAL` query is used here in order to force out
a nested loop: for each row in the CTE, look up a full row in the table.

Original query:

- Reads `OFFSET + LIMIT` number of entries from the index.
- Reads `OFFSET + LIMIT` number of rows from the table.

Optimized query:

- Reads `OFFSET + LIMIT` number of entries from the index.
- Reads `LIMIT` number of rows from the table.

## Determine if the optimization helps

By running `EXPLAIN (buffers, analyze)` on the database query with a high (100_000) `OFFSET` value, we can clearly see if the optimization helps.

Look for the following:

- The optimized query plan must have an index only scan node.
- Comparing the cached buffer count and timing should be lower.
  - This can be done when executing the same query 2 or 3 times.

Consider the following query:

```sql
SELECT issues.*
FROM issues
ORDER BY id
OFFSET 100000
LIMIT 100
```

It produces an execution plan which uses an index scan:

```plaintext
 Limit  (cost=27800.96..27828.77 rows=100 width=1491) (actual time=138.305..138.470 rows=100 loops=1)
   Buffers: shared hit=73212
   I/O Timings: read=0.000 write=0.000
   ->  Index Scan using issues_pkey on public.issues  (cost=0.57..26077453.90 rows=93802448 width=1491) (actual time=0.063..133.688 rows=100100 loops=1)
         Buffers: shared hit=73212
         I/O Timings: read=0.000 write=0.000

 
Time: 143.779 ms
  - planning: 5.222 ms
  - execution: 138.557 ms
    - I/O read: 0.000 ms
    - I/O write: 0.000 ms

Shared buffers:
  - hits: 73212 (~572.00 MiB) from the buffer pool
  - reads: 0 from the OS file cache, including disk I/O
  - dirtied: 0
  - writes: 0
```

The optimized query:

```sql
WITH index_only_scan_pagination_cte AS MATERIALIZED
  (SELECT id
   FROM issues
   ORDER BY id ASC
   LIMIT 100
   OFFSET 100000)
SELECT issues.*
FROM
  (SELECT id
   FROM index_only_scan_pagination_cte) index_only_scan_subquery,
     LATERAL
  (SELECT issues.*
   FROM issues
   WHERE issues.id = index_only_scan_subquery.id
   LIMIT 1) issues
```

Execution plan:

```plaintext
 Nested Loop  (cost=2453.51..2815.44 rows=100 width=1491) (actual time=23.614..23.973 rows=100 loops=1)
   Buffers: shared hit=56167
   I/O Timings: read=0.000 write=0.000
   CTE index_only_scan_pagination_cte
     ->  Limit  (cost=2450.49..2452.94 rows=100 width=4) (actual time=23.590..23.621 rows=100 loops=1)
           Buffers: shared hit=55667
           I/O Timings: read=0.000 write=0.000
           ->  Index Only Scan using issues_pkey on public.issues issues_1  (cost=0.57..2298090.72 rows=93802448 width=4) (actual time=0.070..20.412 rows=100100 loops=1)
                 Heap Fetches: 1063
                 Buffers: shared hit=55667
                 I/O Timings: read=0.000 write=0.000
   ->  CTE Scan on index_only_scan_pagination_cte  (cost=0.00..2.00 rows=100 width=4) (actual time=23.593..23.641 rows=100 loops=1)
         Buffers: shared hit=55667
         I/O Timings: read=0.000 write=0.000
   ->  Limit  (cost=0.57..3.58 rows=1 width=1491) (actual time=0.003..0.003 rows=1 loops=100)
         Buffers: shared hit=500
         I/O Timings: read=0.000 write=0.000
         ->  Index Scan using issues_pkey on public.issues  (cost=0.57..3.58 rows=1 width=1491) (actual time=0.003..0.003 rows=1 loops=100)
               Index Cond: (issues.id = index_only_scan_pagination_cte.id)
               Buffers: shared hit=500
               I/O Timings: read=0.000 write=0.000


Time: 29.562 ms
  - planning: 5.506 ms
  - execution: 24.056 ms
    - I/O read: 0.000 ms
    - I/O write: 0.000 ms

Shared buffers:
  - hits: 56167 (~438.80 MiB) from the buffer pool
  - reads: 0 from the OS file cache, including disk I/O
  - dirtied: 0
  - writes: 0
```
