---
stage: Data Access
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Efficient `IN` operator queries
---

This document describes a technique for building efficient ordered database queries with the `IN`
SQL operator and the usage of a GitLab utility module to help apply the technique.

NOTE:
The described technique makes heavy use of
[keyset pagination](pagination_guidelines.md#keyset-pagination).
It's advised to get familiar with the topic first.

## Motivation

In GitLab, many domain objects like `Issue` live under nested hierarchies of projects and groups.
To fetch nested database records for domain objects at the group-level,
we often perform queries with the `IN` SQL operator.
We are usually interested in ordering the records by some attributes
and limiting the number of records using `ORDER BY` and `LIMIT` clauses for performance.
Pagination may be used to fetch subsequent records.

Example tasks requiring querying nested domain objects from the group level:

- Show first 20 issues by creation date or due date from the group `gitlab-org`.
- Show first 20 merge requests by merged at date from the group `gitlab-com`.

Unfortunately, ordered group-level queries typically perform badly
as their executions require heavy I/O, memory, and computations.
Let's do an in-depth examination of executing one such query.

### Performance problems with `IN` queries

Consider the task of fetching the twenty oldest created issues
from the group `gitlab-org` with the following query:

```sql
SELECT "issues".*
FROM "issues"
WHERE "issues"."project_id" IN
    (SELECT "projects"."id"
     FROM "projects"
     WHERE "projects"."namespace_id" IN
         (SELECT traversal_ids[array_length(traversal_ids, 1)] AS id
          FROM "namespaces"
          WHERE (traversal_ids @> ('{9970}'))))
ORDER BY "issues"."created_at" ASC,
         "issues"."id" ASC
LIMIT 20
```

NOTE:
For pagination, ordering by the `created_at` column is not enough,
we must add the `id` column as a
[tie-breaker](pagination_performance_guidelines.md#tie-breaker-column).

The execution of the query can be largely broken down into three steps:

1. The database accesses both `namespaces` and `projects` tables
   to find all projects from all groups in the group hierarchy.
1. The database retrieves `issues` records for each project causing heavy disk I/O.
   Ideally, an appropriate index configuration should optimize this process.
1. The database sorts the `issues` rows in memory by `created_at` and returns `LIMIT 20` rows to
   the end-user. For large groups, this final step requires both large memory and CPU resources.

Execution plan for this DB query:

```sql
 Limit  (cost=90170.07..90170.12 rows=20 width=1329) (actual time=967.597..967.607 rows=20 loops=1)
   Buffers: shared hit=239127 read=3060
   I/O Timings: read=336.879
   ->  Sort  (cost=90170.07..90224.02 rows=21578 width=1329) (actual time=967.596..967.603 rows=20 loops=1)
         Sort Key: issues.created_at, issues.id
         Sort Method: top-N heapsort  Memory: 74kB
         Buffers: shared hit=239127 read=3060
         I/O Timings: read=336.879
         ->  Nested Loop  (cost=1305.66..89595.89 rows=21578 width=1329) (actual time=4.709..797.659 rows=241534 loops=1)
               Buffers: shared hit=239121 read=3060
               I/O Timings: read=336.879
               ->  HashAggregate  (cost=1305.10..1360.22 rows=5512 width=4) (actual time=4.657..5.370 rows=1528 loops=1)
                     Group Key: projects.id
                     Buffers: shared hit=2597
                     ->  Nested Loop  (cost=576.76..1291.32 rows=5512 width=4) (actual time=2.427..4.244 rows=1528 loops=1)
                           Buffers: shared hit=2597
                           ->  HashAggregate  (cost=576.32..579.06 rows=274 width=25) (actual time=2.406..2.447 rows=265 loops=1)
                                 Group Key: namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)]
                                 Buffers: shared hit=334
                                 ->  Bitmap Heap Scan on namespaces  (cost=141.62..575.63 rows=274 width=25) (actual time=1.933..2.330 rows=265 loops=1)
                                       Recheck Cond: (traversal_ids @> '{9970}'::integer[])
                                       Heap Blocks: exact=243
                                       Buffers: shared hit=334
                                       ->  Bitmap Index Scan on index_namespaces_on_traversal_ids  (cost=0.00..141.55 rows=274 width=0) (actual time=1.897..1.898 rows=265 loops=1)
                                             Index Cond: (traversal_ids @> '{9970}'::integer[])
                                             Buffers: shared hit=91
                           ->  Index Only Scan using index_projects_on_namespace_id_and_id on projects  (cost=0.44..2.40 rows=20 width=8) (actual time=0.004..0.006 rows=6 loops=265)
                                 Index Cond: (namespace_id = (namespaces.traversal_ids)[array_length(namespaces.traversal_ids, 1)])
                                 Heap Fetches: 51
                                 Buffers: shared hit=2263
               ->  Index Scan using index_issues_on_project_id_and_iid on issues  (cost=0.57..10.57 rows=544 width=1329) (actual time=0.114..0.484 rows=158 loops=1528)
                     Index Cond: (project_id = projects.id)
                     Buffers: shared hit=236524 read=3060
                     I/O Timings: read=336.879
 Planning Time: 7.750 ms
 Execution Time: 967.973 ms
(36 rows)
```

The performance of the query depends on the number of rows in the database.
On average, we can say the following:

- Number of groups in the group-hierarchy: less than 1 000
- Number of projects: less than 5 000
- Number of issues: less than 100 000

From the list, it's apparent that the number of `issues` records has
the largest impact on the performance.
As per typical usage, we can say that the number of issue records grows
at a faster rate than the `namespaces` and the `projects` records.

This problem affects most of our group-level features where records are listed
in a specific order, such as group-level issues, merge requests pages, and APIs.
For very large groups the database queries can easily time out, causing HTTP 500 errors.

## Optimizing ordered `IN` queries

In the talk ["How to teach an elephant to dance rock and roll"](https://www.youtube.com/watch?v=Ha38lcjVyhQ),
Maxim Boguk demonstrated a technique to optimize a special class of ordered `IN` queries,
such as our ordered group-level queries.

A typical ordered `IN` query may look like this:

```sql
SELECT t.* FROM t
WHERE t.fkey IN (value_set)
ORDER BY t.pkey
LIMIT N;
```

Here's the key insight used in the technique: we need at most `|value_set| + N` record lookups,
rather than retrieving all records satisfying the condition `t.fkey IN value_set` (`|value_set|`
is the number of values in `value_set`).

We adopted and generalized the technique for use in GitLab by implementing utilities in the
`Gitlab::Pagination::Keyset::InOperatorOptimization` class to facilitate building efficient `IN`
queries.

### Requirements

The technique is not a drop-in replacement for the existing group-level queries using `IN` operator.
The technique can only optimize `IN` queries that satisfy the following requirements:

- `LIMIT` is present, which usually means that the query is paginated
  (offset or keyset pagination).
- The column used with the `IN` query and the columns in the `ORDER BY`
  clause are covered with a database index. The columns in the index must be
  in the following order: `column_for_the_in_query`, `order by column 1`, and
  `order by column 2`.
- The columns in the `ORDER BY` clause are distinct
  (the combination of the columns uniquely identifies one particular row in the table).

WARNING:
This technique does not improve the performance of the `COUNT(*)` queries.

## The `InOperatorOptimization` module

The `Gitlab::Pagination::Keyset::InOperatorOptimization` module implements utilities for applying a generalized version of
the efficient `IN` query technique described in the previous section.

To build optimized, ordered `IN` queries that meet [the requirements](#requirements),
use the utility class `QueryBuilder` from the module.

NOTE:
The generic keyset pagination module introduced in the merge request
[51481](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51481)
plays a fundamental role in the generalized implementation of the technique
in `Gitlab::Pagination::Keyset::InOperatorOptimization`.

### Basic usage of `QueryBuilder`

To illustrate a basic usage, we build a query that
fetches 20 issues with the oldest `created_at` from the group `gitlab-org`.

The following ActiveRecord query would produce a query similar to
[the unoptimized query](#performance-problems-with-in-queries) that we examined earlier:

```ruby
scope = Issue
  .where(project_id: Group.find(9970).all_projects.select(:id)) # `gitlab-org` group and its subgroups
  .order(:created_at, :id)
  .limit(20)
```

Instead, use the query builder `InOperatorOptimization::QueryBuilder` to produce an optimized
version:

```ruby
scope = Issue.order(:created_at, :id)
array_scope = Group.find(9970).all_projects.select(:id)
array_mapping_scope = -> (id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) }
finder_query = -> (created_at_expression, id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }

Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
  scope: scope,
  array_scope: array_scope,
  array_mapping_scope: array_mapping_scope,
  finder_query: finder_query
).execute.limit(20)
```

- `scope` represents the original `ActiveRecord::Relation` object without the `IN` query. The
  relation should define an order which must be supported by the
  [keyset pagination library](keyset_pagination.md#usage).
- `array_scope` contains the `ActiveRecord::Relation` object, which represents the original
  `IN (subquery)`. The select values must contain the columns by which the subquery is "connected"
  to the main query: the `id` of the project record.
- `array_mapping_scope` defines a lambda returning an `ActiveRecord::Relation` object. The lambda
  matches (`=`) single select values from the `array_scope`. The lambda yields as many
  arguments as the select values defined in the `array_scope`. The arguments are Arel SQL expressions.
- `finder_query` loads the actual record row from the database. It must also be a lambda, where
  the order by column expressions is available for locating the record. In this example, the
  yielded values are `created_at` and `id` SQL expressions. Finding a record is very fast via the
  primary key, so we don't use the `created_at` value. Providing the `finder_query` lambda is optional.
  If it's not given, the `IN` operator optimization only makes the `ORDER BY` columns available to
  the end-user and not the full database row.

The following database index on the `issues` table must be present
to make the query execute efficiently:

```sql
"idx_issues_on_project_id_and_created_at_and_id" btree (project_id, created_at, id)
```

The SQL query:

```sql
SELECT "issues".*
FROM
  (WITH RECURSIVE "array_cte" AS MATERIALIZED
     (SELECT "projects"."id"
 FROM "projects"
 WHERE "projects"."namespace_id" IN
     (SELECT traversal_ids[array_length(traversal_ids, 1)] AS id
      FROM "namespaces"
      WHERE (traversal_ids @> ('{9970}')))),
                  "recursive_keyset_cte" AS (  -- initializer row start
                                               (SELECT NULL::issues AS records,
                                                       array_cte_id_array,
                                                       issues_created_at_array,
                                                       issues_id_array,
                                                       0::bigint AS COUNT
                                                FROM
                                                  (SELECT ARRAY_AGG("array_cte"."id") AS array_cte_id_array,
                                                          ARRAY_AGG("issues"."created_at") AS issues_created_at_array,
                                                          ARRAY_AGG("issues"."id") AS issues_id_array
                                                   FROM
                                                     (SELECT "array_cte"."id"
                                                      FROM array_cte) array_cte
                                                   LEFT JOIN LATERAL
                                                     (SELECT "issues"."created_at",
                                                             "issues"."id"
                                                      FROM "issues"
                                                      WHERE "issues"."project_id" = "array_cte"."id"
                                                      ORDER BY "issues"."created_at" ASC, "issues"."id" ASC
                                                      LIMIT 1) issues ON TRUE
                                                   WHERE "issues"."created_at" IS NOT NULL
                                                     AND "issues"."id" IS NOT NULL) array_scope_lateral_query
                                                LIMIT 1)
                                                -- initializer row finished
                                             UNION ALL
                                               (SELECT
                                                  -- result row start
                                                  (SELECT issues -- record finder query as the first column
                                                   FROM "issues"
                                                   WHERE "issues"."id" = recursive_keyset_cte.issues_id_array[position]
                                                   LIMIT 1),
                                                   array_cte_id_array,
                                                   recursive_keyset_cte.issues_created_at_array[:position_query.position-1]||next_cursor_values.created_at||recursive_keyset_cte.issues_created_at_array[position_query.position+1:],
                                                   recursive_keyset_cte.issues_id_array[:position_query.position-1]||next_cursor_values.id||recursive_keyset_cte.issues_id_array[position_query.position+1:],
                                                   recursive_keyset_cte.count + 1
                                                -- result row finished
                                                FROM recursive_keyset_cte,
                                                     LATERAL
                                                  -- finding the cursor values of the next record start
                                                  (SELECT created_at,
                                                          id,
                                                          position
                                                   FROM UNNEST(issues_created_at_array, issues_id_array) WITH
                                                   ORDINALITY AS u(created_at, id, position)
                                                   WHERE created_at IS NOT NULL
                                                     AND id IS NOT NULL
                                                   ORDER BY "created_at" ASC, "id" ASC
                                                   LIMIT 1) AS position_query,
                                                  -- finding the cursor values of the next record end
                                                  -- finding the next cursor values (next_cursor_values_query) start
                                                             LATERAL
                                                  (SELECT "record"."created_at",
                                                          "record"."id"
                                                   FROM (
                                                         VALUES (NULL,
                                                                 NULL)) AS nulls
                                                   LEFT JOIN
                                                     (SELECT "issues"."created_at",
                                                             "issues"."id"
                                                      FROM (
                                                              (SELECT "issues"."created_at",
                                                                      "issues"."id"
                                                               FROM "issues"
                                                               WHERE "issues"."project_id" = recursive_keyset_cte.array_cte_id_array[position]
                                                                 AND recursive_keyset_cte.issues_created_at_array[position] IS NULL
                                                                 AND "issues"."created_at" IS NULL
                                                                 AND "issues"."id" > recursive_keyset_cte.issues_id_array[position]
                                                               ORDER BY "issues"."created_at" ASC, "issues"."id" ASC)
                                                            UNION ALL
                                                              (SELECT "issues"."created_at",
                                                                      "issues"."id"
                                                               FROM "issues"
                                                               WHERE "issues"."project_id" = recursive_keyset_cte.array_cte_id_array[position]
                                                                 AND recursive_keyset_cte.issues_created_at_array[position] IS NOT NULL
                                                                 AND "issues"."created_at" IS NULL
                                                               ORDER BY "issues"."created_at" ASC, "issues"."id" ASC)
                                                            UNION ALL
                                                              (SELECT "issues"."created_at",
                                                                      "issues"."id"
                                                               FROM "issues"
                                                               WHERE "issues"."project_id" = recursive_keyset_cte.array_cte_id_array[position]
                                                                 AND recursive_keyset_cte.issues_created_at_array[position] IS NOT NULL
                                                                 AND "issues"."created_at" > recursive_keyset_cte.issues_created_at_array[position]
                                                               ORDER BY "issues"."created_at" ASC, "issues"."id" ASC)
                                                            UNION ALL
                                                              (SELECT "issues"."created_at",
                                                                      "issues"."id"
                                                               FROM "issues"
                                                               WHERE "issues"."project_id" = recursive_keyset_cte.array_cte_id_array[position]
                                                                 AND recursive_keyset_cte.issues_created_at_array[position] IS NOT NULL
                                                                 AND "issues"."created_at" = recursive_keyset_cte.issues_created_at_array[position]
                                                                 AND "issues"."id" > recursive_keyset_cte.issues_id_array[position]
                                                               ORDER BY "issues"."created_at" ASC, "issues"."id" ASC)) issues
                                                      ORDER BY "issues"."created_at" ASC, "issues"."id" ASC
                                                      LIMIT 1) record ON TRUE
                                                   LIMIT 1) AS next_cursor_values))
                                                  -- finding the next cursor values (next_cursor_values_query) END
SELECT (records).*
   FROM "recursive_keyset_cte" AS "issues"
   WHERE (COUNT <> 0)) issues -- filtering out the initializer row
LIMIT 20
```

### Using the `IN` query optimization

#### Adding more filters

In this example, let's add an extra filter by `milestone_id`.

Be careful when adding extra filters to the query. If the column is not covered by the same index,
then the query might perform worse than the non-optimized query. The `milestone_id` column in the
`issues` table is currently covered by a different index:

```sql
"index_issues_on_milestone_id" btree (milestone_id)
```

Adding the `milestone_id = X` filter to the `scope` argument or to the optimized scope causes bad performance.

Example (bad):

```ruby
Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
  scope: scope,
  array_scope: array_scope,
  array_mapping_scope: array_mapping_scope,
  finder_query: finder_query
).execute
  .where(milestone_id: 5)
  .limit(20)
```

To address this concern, we could define another index:

```sql
"idx_issues_on_project_id_and_milestone_id_and_created_at_and_id" btree (project_id, milestone_id, created_at, id)
```

Adding more indexes to the `issues` table could significantly affect the performance of
the `UPDATE` queries. In this case, it's better to rely on the original query. It means that if we
want to use the optimization for the unfiltered page we need to add extra logic in the application code:

```ruby
if optimization_possible? # no extra params or params covered with the same index as the ORDER BY clause
  run_optimized_query
else
  run_normal_in_query
end
```

#### Multiple `IN` queries

Let's assume that we want to extend the group-level queries to include only incident and test case
issue types.

The original ActiveRecord query would look like this:

```ruby
scope = Issue
  .where(project_id: Group.find(9970).all_projects.select(:id)) # `gitlab-org` group and its subgroups
  .where(issue_type: [:incident, :test_case]) # 1, 2
  .order(:created_at, :id)
  .limit(20)
```

To construct the array scope, we need to take the Cartesian product of the `project_id IN` and
the `issue_type IN` queries. `issue_type` is an ActiveRecord enum, so we need to
construct the following table:

| `project_id` | `issue_type_value` |
| ------------ | ------------------ |
| 2            | 1                  |
| 2            | 2                  |
| 5            | 1                  |
| 5            | 2                  |
| 10           | 1                  |
| 10           | 2                  |
| 9            | 1                  |
| 9            | 2                  |

For the `issue_types` query we can construct a value list without querying a table:

```ruby
value_list = Arel::Nodes::ValuesList.new([[WorkItems::Type.base_types[:incident]],[WorkItems::Type.base_types[:test_case]]])
issue_type_values = Arel::Nodes::Grouping.new(value_list).as('issue_type_values (value)').to_sql

array_scope = Group
  .find(9970)
  .all_projects
  .from("#{Project.table_name}, #{issue_type_values}")
  .select(:id, :value)
```

Building the `array_mapping_scope` query requires two arguments: `id` and `issue_type_value`:

```ruby
array_mapping_scope = -> (id_expression, issue_type_value_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)).where(Issue.arel_table[:issue_type].eq(issue_type_value_expression)) }
```

The `scope` and the `finder` queries don't change:

```ruby
scope = Issue.order(:created_at, :id)
finder_query = -> (created_at_expression, id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }

Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
  scope: scope,
  array_scope: array_scope,
  array_mapping_scope: array_mapping_scope,
  finder_query: finder_query
).execute.limit(20)
```

The SQL query:

```sql
SELECT "issues".*
FROM
  (WITH RECURSIVE "array_cte" AS MATERIALIZED
     (SELECT "projects"."id", "value"
      FROM projects, (
                      VALUES (1), (2)) AS issue_type_values (value)
      WHERE "projects"."namespace_id" IN
          (WITH RECURSIVE "base_and_descendants" AS (
                                                       (SELECT "namespaces".*
                                                        FROM "namespaces"
                                                        WHERE "namespaces"."type" = 'Group'
                                                          AND "namespaces"."id" = 9970)
                                                     UNION
                                                       (SELECT "namespaces".*
                                                        FROM "namespaces", "base_and_descendants"
                                                        WHERE "namespaces"."type" = 'Group'
                                                          AND "namespaces"."parent_id" = "base_and_descendants"."id")) SELECT "id"
           FROM "base_and_descendants" AS "namespaces")),
                  "recursive_keyset_cte" AS (
                                               (SELECT NULL::issues AS records,
                                                       array_cte_id_array,
                                                       array_cte_value_array,
                                                       issues_created_at_array,
                                                       issues_id_array,
                                                       0::bigint AS COUNT
                                                FROM
                                                  (SELECT ARRAY_AGG("array_cte"."id") AS array_cte_id_array,
                                                          ARRAY_AGG("array_cte"."value") AS array_cte_value_array,
                                                          ARRAY_AGG("issues"."created_at") AS issues_created_at_array,
                                                          ARRAY_AGG("issues"."id") AS issues_id_array
                                                   FROM
                                                     (SELECT "array_cte"."id",
                                                             "array_cte"."value"
                                                      FROM array_cte) array_cte
                                                   LEFT JOIN LATERAL
                                                     (SELECT "issues"."created_at",
                                                             "issues"."id"
                                                      FROM "issues"
                                                      WHERE "issues"."project_id" = "array_cte"."id"
                                                        AND "issues"."issue_type" = "array_cte"."value"
                                                      ORDER BY "issues"."created_at" ASC, "issues"."id" ASC
                                                      LIMIT 1) issues ON TRUE
                                                   WHERE "issues"."created_at" IS NOT NULL
                                                     AND "issues"."id" IS NOT NULL) array_scope_lateral_query
                                                LIMIT 1)
                                             UNION ALL
                                               (SELECT
                                                  (SELECT issues
                                                   FROM "issues"
                                                   WHERE "issues"."id" = recursive_keyset_cte.issues_id_array[POSITION]
                                                   LIMIT 1), array_cte_id_array,
                                                             array_cte_value_array,
                                                             recursive_keyset_cte.issues_created_at_array[:position_query.position-1]||next_cursor_values.created_at||recursive_keyset_cte.issues_created_at_array[position_query.position+1:], recursive_keyset_cte.issues_id_array[:position_query.position-1]||next_cursor_values.id||recursive_keyset_cte.issues_id_array[position_query.position+1:], recursive_keyset_cte.count + 1
                                                FROM recursive_keyset_cte,
                                                     LATERAL
                                                  (SELECT created_at,
                                                          id,
                                                          POSITION
                                                   FROM UNNEST(issues_created_at_array, issues_id_array) WITH
                                                   ORDINALITY AS u(created_at, id, POSITION)
                                                   WHERE created_at IS NOT NULL
                                                     AND id IS NOT NULL
                                                   ORDER BY "created_at" ASC, "id" ASC
                                                   LIMIT 1) AS position_query,
                                                             LATERAL
                                                  (SELECT "record"."created_at",
                                                          "record"."id"
                                                   FROM (
                                                         VALUES (NULL,
                                                                 NULL)) AS nulls
                                                   LEFT JOIN
                                                     (SELECT "issues"."created_at",
                                                             "issues"."id"
                                                      FROM (
                                                              (SELECT "issues"."created_at",
                                                                      "issues"."id"
                                                               FROM "issues"
                                                               WHERE "issues"."project_id" = recursive_keyset_cte.array_cte_id_array[POSITION]
                                                                 AND "issues"."issue_type" = recursive_keyset_cte.array_cte_value_array[POSITION]
                                                                 AND recursive_keyset_cte.issues_created_at_array[POSITION] IS NULL
                                                                 AND "issues"."created_at" IS NULL
                                                                 AND "issues"."id" > recursive_keyset_cte.issues_id_array[POSITION]
                                                               ORDER BY "issues"."created_at" ASC, "issues"."id" ASC)
                                                            UNION ALL
                                                              (SELECT "issues"."created_at",
                                                                      "issues"."id"
                                                               FROM "issues"
                                                               WHERE "issues"."project_id" = recursive_keyset_cte.array_cte_id_array[POSITION]
                                                                 AND "issues"."issue_type" = recursive_keyset_cte.array_cte_value_array[POSITION]
                                                                 AND recursive_keyset_cte.issues_created_at_array[POSITION] IS NOT NULL
                                                                 AND "issues"."created_at" IS NULL
                                                               ORDER BY "issues"."created_at" ASC, "issues"."id" ASC)
                                                            UNION ALL
                                                              (SELECT "issues"."created_at",
                                                                      "issues"."id"
                                                               FROM "issues"
                                                               WHERE "issues"."project_id" = recursive_keyset_cte.array_cte_id_array[POSITION]
                                                                 AND "issues"."issue_type" = recursive_keyset_cte.array_cte_value_array[POSITION]
                                                                 AND recursive_keyset_cte.issues_created_at_array[POSITION] IS NOT NULL
                                                                 AND "issues"."created_at" > recursive_keyset_cte.issues_created_at_array[POSITION]
                                                               ORDER BY "issues"."created_at" ASC, "issues"."id" ASC)
                                                            UNION ALL
                                                              (SELECT "issues"."created_at",
                                                                      "issues"."id"
                                                               FROM "issues"
                                                               WHERE "issues"."project_id" = recursive_keyset_cte.array_cte_id_array[POSITION]
                                                                 AND "issues"."issue_type" = recursive_keyset_cte.array_cte_value_array[POSITION]
                                                                 AND recursive_keyset_cte.issues_created_at_array[POSITION] IS NOT NULL
                                                                 AND "issues"."created_at" = recursive_keyset_cte.issues_created_at_array[POSITION]
                                                                 AND "issues"."id" > recursive_keyset_cte.issues_id_array[POSITION]
                                                               ORDER BY "issues"."created_at" ASC, "issues"."id" ASC)) issues
                                                      ORDER BY "issues"."created_at" ASC, "issues"."id" ASC
                                                      LIMIT 1) record ON TRUE
                                                   LIMIT 1) AS next_cursor_values)) SELECT (records).*
   FROM "recursive_keyset_cte" AS "issues"
   WHERE (COUNT <> 0)) issues
LIMIT 20
```

NOTE:
To make the query efficient, the following columns need to be covered with an index: `project_id`, `issue_type`, `created_at`, and `id`.

#### Using calculated `ORDER BY` expression

The following example orders epic records by the duration between the creation time and closed
time. It is calculated with the following formula:

```sql
SELECT EXTRACT('epoch' FROM epics.closed_at - epics.created_at) FROM epics
```

The query above returns the duration in seconds (`double precision`) between the two timestamp
columns in seconds. To order the records by this expression, you must reference it
in the `ORDER BY` clause:

```sql
SELECT EXTRACT('epoch' FROM epics.closed_at - epics.created_at)
FROM epics
ORDER BY EXTRACT('epoch' FROM epics.closed_at - epics.created_at) DESC
```

To make this ordering efficient on the group-level with the in-operator optimization, use a
custom `ORDER BY` configuration. Since the duration is not a distinct value (no unique index
present), you must add a tie-breaker column (`id`).

The following example shows the final `ORDER BY` clause:

```sql
ORDER BY extract('epoch' FROM epics.closed_at - epics.created_at) DESC, epics.id DESC
```

Snippet for loading records ordered by the calculated duration:

```ruby
arel_table =  Epic.arel_table
order = Gitlab::Pagination::Keyset::Order.build([
  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
    attribute_name: 'duration_in_seconds',
    order_expression: Arel.sql('EXTRACT(EPOCH FROM epics.closed_at - epics.created_at)').desc,
    sql_type: 'double precision' # important for calculated SQL expressions
  ),
  Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
    attribute_name: 'id',
    order_expression: arel_table[:id].desc
  )
])

records = Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
  scope: Epic.where.not(closed_at: nil).reorder(order), # filter out NULL values
  array_scope: Group.find(9970).self_and_descendants.select(:id),
  array_mapping_scope: -> (id_expression) { Epic.where(Epic.arel_table[:group_id].eq(id_expression)) }
).execute.limit(20)

puts records.pluck(:duration_in_seconds, :id) # other columns are not available
```

Building the query requires quite a bit of configuration. For the order configuration you
can find more information within the
[complex order configuration](keyset_pagination.md#complex-order-configuration)
section for keyset paginated database queries.

The query requires a specialized database index:

```sql
CREATE INDEX index_epics_on_duration ON epics USING btree (group_id, EXTRACT(EPOCH FROM epics.closed_at - epics.created_at) DESC, id DESC) WHERE (closed_at IS NOT NULL);
```

Notice that the `finder_query` parameter is not used. The query only returns the `ORDER BY` columns
which are the `duration_in_seconds` (calculated column) and the `id` columns. This is a limitation
of the feature, defining the `finder_query` with calculated `ORDER BY` expressions is not supported.
To get the complete database records, an extra query can be invoked by the returned `id` column:

```ruby
records_by_id = records.index_by(&:id)
complete_records = Epic.where(id: records_by_id.keys).index_by(&:id)

# Printing the complete records according to the `ORDER BY` clause
records_by_id.each do |id, _|
  puts complete_records[id].attributes
end
```

#### Ordering by `JOIN` columns

Ordering records by mixed columns where one or more columns are coming from `JOIN` tables
works with limitations. It requires extra configuration via Common Table Expression (CTE). The trick is to use a
non-materialized CTE to act as a "fake" table which exposes all required columns.

NOTE:
The query performance might not improve compared to the standard `IN` query. Always
check the query plan.

Example: order issues by `projects.name, issues.id` within the group hierarchy

The first step is to create a CTE, where all required columns are collected in the `SELECT`
clause.

```ruby
cte_query = Issue
  .select('issues.id AS id', 'issues.project_id AS project_id', 'projects.name AS projects_name')
  .joins(:project)

cte = Gitlab::SQL::CTE.new(:issue_with_projects, cte_query, materialized: false)
```

Custom order object configuration:

```ruby
order = Gitlab::Pagination::Keyset::Order.build([
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: 'projects_name',
            order_expression: Issue.arel_table[:projects_name].asc,
            sql_type: 'character varying',
            nullable: :nulls_last
          ),
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: :id,
            order_expression: Issue.arel_table[:id].asc
          )
        ])
```

Generate the query:

```ruby
scope = cte.apply_to(Issue.where({}).reorder(order))

opts = {
  scope: scope,
  array_scope: Project.where(namespace_id: top_level_group.self_and_descendants.select(:id)).select(:id),
  array_mapping_scope: -> (id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) }
}

records = Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder
  .new(**opts)
  .execute
  .limit(20)
```

#### Batch iteration

Batch iteration over the records is possible via the keyset `Iterator` class.

```ruby
scope = Issue.order(:created_at, :id)
array_scope = Group.find(9970).all_projects.select(:id)
array_mapping_scope = -> (id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) }
finder_query = -> (created_at_expression, id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }

opts = {
  in_operator_optimization_options: {
    array_scope: array_scope,
    array_mapping_scope: array_mapping_scope,
    finder_query: finder_query
  }
}

Gitlab::Pagination::Keyset::Iterator.new(scope: scope, **opts).each_batch(of: 100) do |records|
  puts records.select(:id).map { |r| [r.id] }
end
```

NOTE:
The query loads complete database rows from the disk. This may cause increased I/O and slower
database queries. Depending on the use case, the primary key is often only
needed for the batch query to invoke additional statements. For example, `UPDATE` or `DELETE`. The
`id` column is included in the `ORDER BY` columns (`created_at` and `id`) and is already
loaded. In this case, you can omit the `finder_query` parameter.

Example for loading the `ORDER BY` columns only:

```ruby
scope = Issue.order(:created_at, :id)
array_scope = Group.find(9970).all_projects.select(:id)
array_mapping_scope = -> (id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) }

opts = {
  in_operator_optimization_options: {
    array_scope: array_scope,
    array_mapping_scope: array_mapping_scope
  }
}

Gitlab::Pagination::Keyset::Iterator.new(scope: scope, **opts).each_batch(of: 100) do |records|
  puts records.select(:id).map { |r| [r.id] } # only id and created_at are available
end
```

#### Keyset pagination

The optimization works out of the box with GraphQL and the `keyset_paginate` helper method.
Read more about [keyset pagination](keyset_pagination.md).

```ruby
array_scope = Group.find(9970).all_projects.select(:id)
array_mapping_scope = -> (id_expression) { Issue.where(Issue.arel_table[:project_id].eq(id_expression)) }
finder_query = -> (created_at_expression, id_expression) { Issue.where(Issue.arel_table[:id].eq(id_expression)) }

opts = {
  in_operator_optimization_options: {
    array_scope: array_scope,
    array_mapping_scope: array_mapping_scope,
    finder_query: finder_query
  }
}

issues = Issue
  .order(:created_at, :id)
  .keyset_paginate(per_page: 20, keyset_order_options: opts)
  .records
```

#### Offset pagination with Kaminari

The `ActiveRecord` scope produced by the `InOperatorOptimization` class can be used in
[offset-paginated](pagination_guidelines.md#offset-pagination)
queries.

```ruby
Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder
  .new(...)
  .execute
  .page(1)
  .per(20)
  .without_count
```

## Generalized `IN` optimization technique

Let's dive into how `QueryBuilder` builds the optimized query
to fetch the twenty oldest created issues from the group `gitlab-org`
using the generalized `IN` optimization technique.

### Array CTE

As the first step, we use a Common Table Expression (CTE) for collecting the `projects.id` values.
This is done by wrapping the incoming `array_scope` ActiveRecord relation parameter with a CTE.

```sql
WITH array_cte AS MATERIALIZED (
  SELECT "projects"."id"
   FROM "projects"
   WHERE "projects"."namespace_id" IN
       (SELECT traversal_ids[array_length(traversal_ids, 1)] AS id
        FROM "namespaces"
        WHERE (traversal_ids @> ('{9970}')))
)
```

This query produces the following result set with only one column (`projects.id`):

| ID  |
| --- |
| 9   |
| 2   |
| 5   |
| 10  |

### Array mapping

For each project (that is, each record storing a project ID in `array_cte`),
we fetch the cursor value identifying the first issue respecting the `ORDER BY` clause.

As an example, let's pick the first record `ID=9` from `array_cte`.
The following query should fetch the cursor value `(created_at, id)` identifying
the first issue record respecting the `ORDER BY` clause for the project with `ID=9`:

```sql
SELECT "issues"."created_at", "issues"."id"
FROM "issues"."project_id"=9
ORDER BY "issues"."created_at" ASC, "issues"."id" ASC
LIMIT 1;
```

We use `LATERAL JOIN` to loop over the records in the `array_cte` and find the
cursor value for each project. The query would be built using the `array_mapping_scope` lambda
function.

```sql
SELECT ARRAY_AGG("array_cte"."id") AS array_cte_id_array,
  ARRAY_AGG("issues"."created_at") AS issues_created_at_array,
  ARRAY_AGG("issues"."id") AS issues_id_array
FROM (
  SELECT "array_cte"."id" FROM array_cte
) array_cte
LEFT JOIN LATERAL
(
  SELECT "issues"."created_at", "issues"."id"
  FROM "issues"
  WHERE "issues"."project_id" = "array_cte"."id"
  ORDER BY "issues"."created_at" ASC, "issues"."id" ASC
  LIMIT 1
) issues ON TRUE
```

Since we have an index on `project_id`, `created_at`, and `id`,
index-only scans should quickly locate all the cursor values.

This is how the query could be translated to Ruby:

```ruby
created_at_values = []
id_values = []
project_ids.map do |project_id|
  created_at, id = Issue.select(:created_at, :id).where(project_id: project_id).order(:created_at, :id).limit(1).first # N+1 but it's fast
  created_at_values << created_at
  id_values << id
end
```

This is what the result set would look like:

| `project_ids` | `created_at_values` | `id_values` |
| ------------- | ------------------- | ----------- |
| 2             | 2020-01-10          | 5           |
| 5             | 2020-01-05          | 4           |
| 10            | 2020-01-15          | 7           |
| 9             | 2020-01-05          | 3           |

The table shows the cursor values (`created_at, id`) of the first record for each project
respecting the `ORDER BY` clause.

At this point, we have the initial data. To start collecting the actual records from the database,
we use a recursive CTE query where each recursion locates one row until
the `LIMIT` is reached or no more data can be found.

Here's an outline of the steps we take in the recursive CTE query
(expressing the steps in SQL is non-trivial but is explained next):

1. Sort the initial `resultset` according to the `ORDER BY` clause.
1. Pick the top cursor to fetch the record, this is our first record. In the example,
   this cursor would be (`2020-01-05`, `3`) for `project_id=9`.
1. We can use (`2020-01-05`, `3`) to fetch the next issue respecting the `ORDER BY` clause
   `project_id=9` filter. This produces an updated `resultset`.

   | `project_ids` | `created_at_values` | `id_values` |
   | ------------- | ------------------- | ----------- |
   | 2             | 2020-01-10          | 5           |
   | 5             | 2020-01-05          | 4           |
   | 10            | 2020-01-15          | 7           |
   | **9**         | **2020-01-06**      | **6**       |

1. Repeat 1 to 3 with the updated `resultset` until we have fetched `N=20` records.

### Initializing the recursive CTE query

For the initial recursive query, we need to produce exactly one row, we call this the
initializer query (`initializer_query`).

Use `ARRAY_AGG` function to compact the initial result set into a single row
and use the row as the initial value for the recursive CTE query:

Example initializer row:

| `records`      | `project_ids`   | `created_at_values` | `id_values` | `Count` | `Position` |
| -------------- | --------------- | ------------------- | ----------- | ------- | ---------- |
| `NULL::issues` | `[9, 2, 5, 10]` | `[...]`             | `[...]`     | `0`     | `NULL`     |

- The `records` column contains our sorted database records, and the initializer query sets the
  first value to `NULL`, which is filtered out later.
- The `count` column tracks the number of records found. We use this column to filter out the
  initializer row from the result set.

### Recursive portion of the CTE query

The result row is produced with the following steps:

1. [Order the keyset arrays.](#order-the-keyset-arrays)
1. [Find the next cursor.](#find-the-next-cursor)
1. [Produce a new row.](#produce-a-new-row)

#### Order the keyset arrays

Order the keyset arrays according to the original `ORDER BY` clause with `LIMIT 1` using the
`UNNEST [] WITH ORDINALITY` table function. The function locates the "lowest" keyset cursor
values and gives us the array position. These cursor values are used to locate the record.

NOTE:
At this point, we haven't read anything from the database tables, because we relied on
fast index-only scans.

| `project_ids` | `created_at_values` | `id_values` |
| ------------- | ------------------- | ----------- |
| 2             | 2020-01-10          | 5           |
| 5             | 2020-01-05          | 4           |
| 10            | 2020-01-15          | 7           |
| 9             | 2020-01-05          | 3           |

The first row is the 4th one (`position = 4`), because it has the lowest `created_at` and
`id` values. The `UNNEST` function also exposes the position using an extra column (note:
PostgreSQL uses 1-based index).

Demonstration of the `UNNEST [] WITH ORDINALITY` table function:

```sql
SELECT position FROM unnest('{2020-01-10, 2020-01-05, 2020-01-15, 2020-01-05}'::timestamp[], '{5, 4, 7, 3}'::int[])
  WITH ORDINALITY AS t(created_at, id, position) ORDER BY created_at ASC, id ASC LIMIT 1;
```

Result:

```sql
position
----------
         4
(1 row)
```

#### Find the next cursor

Now, let's find the next cursor values (`next_cursor_values_query`) for the project with `id = 9`.
To do that, we build a keyset pagination SQL query. Find the next row after
`created_at = 2020-01-05` and `id = 3`. Because we order by two database columns, there can be two
cases:

- There are rows with `created_at = 2020-01-05` and `id > 3`.
- There are rows with `created_at > 2020-01-05`.

Generating this query is done by the generic keyset pagination library. After the query is done,
we have a temporary table with the next cursor values:

| `created_at` | ID  |
| ------------ | --- |
| 2020-01-06   | 6   |

#### Produce a new row

As the final step, we need to produce a new row by manipulating the initializer row
(`data_collector_query` method). Two things happen here:

- Read the full row from the DB and return it in the `records` columns. (`result_collector_columns`
  method)
- Replace the cursor values at the current position with the results from the keyset query.

Reading the full row from the database is only one index scan by the primary key. We use the
ActiveRecord query passed as the `finder_query`:

```sql
(SELECT "issues".* FROM issues WHERE id = id_values[position] LIMIT 1)
```

By adding parentheses, the result row can be put into the `records` column.

Replacing the cursor values at `position` can be done via standard PostgreSQL array operators:

```sql
-- created_at_values column value
created_at_values[:position-1]||next_cursor_values.created_at||created_at_values[position+1:]

-- id_values column value
id_values[:position-1]||next_cursor_values.id||id_values[position+1:]
```

The Ruby equivalent would be the following:

```ruby
id_values[0..(position - 1)] + [next_cursor_values.id] + id_values[(position + 1)..-1]
```

After this, the recursion starts again by finding the next lowest cursor value.

### Finalizing the query

For producing the final `issues` rows, we wrap the query with another `SELECT` statement:

```sql
SELECT "issues".*
FROM (
  SELECT (records).* -- similar to ruby splat operator
  FROM recursive_keyset_cte
  WHERE recursive_keyset_cte.count <> 0 -- filter out the initializer row
) AS issues
```

### Performance comparison

Assuming that we have the correct database index in place, we can compare the query performance by
looking at the number of database rows accessed by the query.

- Number of groups: 100
- Number of projects: 500
- Number of issues (in the group hierarchy): 50 000

Standard `IN` query:

| Query                    | Entries read from index | Rows read from the table | Rows sorted in memory |
| ------------------------ | ----------------------- | ------------------------ | --------------------- |
| group hierarchy subquery | 100                     | 0                        | 0                     |
| project lookup query     | 500                     | 0                        | 0                     |
| issue lookup query       | 50 000                  | 20                       | 50 000                |

Optimized `IN` query:

| Query                    | Entries read from index | Rows read from the table | Rows sorted in memory |
| ------------------------ | ----------------------- | ------------------------ | --------------------- |
| group hierarchy subquery | 100                     | 0                        | 0                     |
| project lookup query     | 500                     | 0                        | 0                     |
| issue lookup query       | 519                     | 20                       | 10 000                |

The group and project queries are not using sorting, the necessary columns are read from database
indexes. These values are accessed frequently so it's very likely that most of the data is
in the PostgreSQL's buffer cache.

The optimized `IN` query reads maximum 519 entries (cursor values) from the index:

- 500 index-only scans for populating the arrays for each project. The cursor values of the first
  record is here.
- Maximum 19 additional index-only scans for the consecutive records.

The optimized `IN` query sorts the array (cursor values per project array) 20 times, which
means we sort 20 x 500 rows. However, this might be a less memory-intensive task than
sorting 10 000 rows at once.

Performance comparison for the `gitlab-org` group:

| Query                | Number of 8K Buffers involved | Uncached execution time | Cached execution time |
| -------------------- | ----------------------------- | ----------------------- | --------------------- |
| `IN` query           | 240833                        | 1.2s                    | 660ms                 |
| Optimized `IN` query | 9783                          | 450ms                   | 22ms                  |

NOTE:
Before taking measurements, the group lookup query was executed separately to make
the group data available in the buffer cache. Since it's a frequently called query, it
hits many shared buffers during the query execution in the production environment.
