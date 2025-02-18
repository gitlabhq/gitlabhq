---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Understanding EXPLAIN plans
---

PostgreSQL allows you to obtain query plans using the `EXPLAIN` command. This
command can be invaluable when trying to determine how a query performs.
You can use this command directly in your SQL query, as long as the query starts
with it:

```sql
EXPLAIN
SELECT COUNT(*)
FROM projects
WHERE visibility_level IN (0, 20);
```

When running this on GitLab.com, we are presented with the following output:

```sql
Aggregate  (cost=922411.76..922411.77 rows=1 width=8)
  ->  Seq Scan on projects  (cost=0.00..908044.47 rows=5746914 width=0)
        Filter: (visibility_level = ANY ('{0,20}'::integer[]))
```

When using _just_ `EXPLAIN`, PostgreSQL does not actually execute our query,
instead it produces an _estimated_ execution plan based on the available
statistics. This means the actual plan can differ quite a bit. Fortunately,
PostgreSQL provides us with the option to execute the query as well. To do so,
we need to use `EXPLAIN ANALYZE` instead of just `EXPLAIN`:

```sql
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM projects
WHERE visibility_level IN (0, 20);
```

This produces:

```sql
Aggregate  (cost=922420.60..922420.61 rows=1 width=8) (actual time=3428.535..3428.535 rows=1 loops=1)
  ->  Seq Scan on projects  (cost=0.00..908053.18 rows=5746969 width=0) (actual time=0.041..2987.606 rows=5746940 loops=1)
        Filter: (visibility_level = ANY ('{0,20}'::integer[]))
        Rows Removed by Filter: 65677
Planning time: 2.861 ms
Execution time: 3428.596 ms
```

As we can see this plan is quite different, and includes a lot more data. Let's
discuss this step by step.

Because `EXPLAIN ANALYZE` executes the query, care should be taken when using a
query that writes data or might time out. If the query modifies data,
consider wrapping it in a transaction that rolls back automatically like so:

```sql
BEGIN;
EXPLAIN ANALYZE
DELETE FROM users WHERE id = 1;
ROLLBACK;
```

The `EXPLAIN` command also takes additional options, such as `BUFFERS`:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM projects
WHERE visibility_level IN (0, 20);
```

This then produces:

```sql
Aggregate  (cost=922420.60..922420.61 rows=1 width=8) (actual time=3428.535..3428.535 rows=1 loops=1)
  Buffers: shared hit=208846
  ->  Seq Scan on projects  (cost=0.00..908053.18 rows=5746969 width=0) (actual time=0.041..2987.606 rows=5746940 loops=1)
        Filter: (visibility_level = ANY ('{0,20}'::integer[]))
        Rows Removed by Filter: 65677
        Buffers: shared hit=208846
Planning time: 2.861 ms
Execution time: 3428.596 ms
```

For more information, refer to the official
[`EXPLAIN` documentation](https://www.postgresql.org/docs/current/sql-explain.html)
and [using `EXPLAIN` guide](https://www.postgresql.org/docs/current/using-explain.html).

## Nodes

Every query plan consists of nodes. Nodes can be nested, and are executed from
the inside out. This means that the innermost node is executed before an outer
node. This can be best thought of as nested function calls, returning their
results as they unwind. For example, a plan starting with an `Aggregate`
followed by a `Nested Loop`, followed by an `Index Only scan` can be thought of
as the following Ruby code:

```ruby
aggregate(
  nested_loop(
    index_only_scan()
    index_only_scan()
  )
)
```

Nodes are indicated using a `->` followed by the type of node taken. For
example:

```sql
Aggregate  (cost=922411.76..922411.77 rows=1 width=8)
  ->  Seq Scan on projects  (cost=0.00..908044.47 rows=5746914 width=0)
        Filter: (visibility_level = ANY ('{0,20}'::integer[]))
```

Here the first node executed is `Seq scan on projects`. The `Filter:` is an
additional filter applied to the results of the node. A filter is very similar
to Ruby's `Array#select`: it takes the input rows, applies the filter, and
produces a new list of rows. After the node is done, we perform the `Aggregate`
above it.

Nested nodes look like this:

```sql
Aggregate  (cost=176.97..176.98 rows=1 width=8) (actual time=0.252..0.252 rows=1 loops=1)
  Buffers: shared hit=155
  ->  Nested Loop  (cost=0.86..176.75 rows=87 width=0) (actual time=0.035..0.249 rows=36 loops=1)
        Buffers: shared hit=155
        ->  Index Only Scan using users_pkey on users users_1  (cost=0.43..4.95 rows=87 width=4) (actual time=0.029..0.123 rows=36 loops=1)
              Index Cond: (id < 100)
              Heap Fetches: 0
        ->  Index Only Scan using users_pkey on users  (cost=0.43..1.96 rows=1 width=4) (actual time=0.003..0.003 rows=1 loops=36)
              Index Cond: (id = users_1.id)
              Heap Fetches: 0
Planning time: 2.585 ms
Execution time: 0.310 ms
```

Here we first perform two separate "Index Only" scans, followed by performing a
"Nested Loop" on the result of these two scans.

## Node statistics

Each node in a plan has a set of associated statistics, such as the cost, the
number of rows produced, the number of loops performed, and more. For example:

```sql
Seq Scan on projects  (cost=0.00..908044.47 rows=5746914 width=0)
```

Here we can see that our cost ranges from `0.00..908044.47` (we cover this in
a moment), and we estimate (since we're using `EXPLAIN` and not `EXPLAIN
ANALYZE`) a total of 5,746,914 rows to be produced by this node. The `width`
statistics describes the estimated width of each row, in bytes.

The `costs` field specifies how expensive a node was. The cost is measured in
arbitrary units determined by the query planner's cost parameters. What
influences the costs depends on a variety of settings, such as `seq_page_cost`,
`cpu_tuple_cost`, and various others.
The format of the costs field is as follows:

```sql
STARTUP COST..TOTAL COST
```

The startup cost states how expensive it was to start the node, with the total
cost describing how expensive the entire node was. In general: the greater the
values, the more expensive the node.

When using `EXPLAIN ANALYZE`, these statistics also include the actual time
(in milliseconds) spent, and other runtime statistics (for example, the actual number of
produced rows):

```sql
Seq Scan on projects  (cost=0.00..908053.18 rows=5746969 width=0) (actual time=0.041..2987.606 rows=5746940 loops=1)
```

Here we can see we estimated 5,746,969 rows to be returned, but in reality we
returned 5,746,940 rows. We can also see that _just_ this sequential scan took
2.98 seconds to run.

Using `EXPLAIN (ANALYZE, BUFFERS)` also gives us information about the
number of rows removed by a filter, the number of buffers used, and more. For
example:

```sql
Seq Scan on projects  (cost=0.00..908053.18 rows=5746969 width=0) (actual time=0.041..2987.606 rows=5746940 loops=1)
  Filter: (visibility_level = ANY ('{0,20}'::integer[]))
  Rows Removed by Filter: 65677
  Buffers: shared hit=208846
```

Here we can see that our filter has to remove 65,677 rows, and that we use
208,846 buffers. Each buffer in PostgreSQL is 8 KB (8192 bytes), meaning our
above node uses *1.6 GB of buffers*. That's a lot!

Keep in mind that some statistics are per-loop averages, while others are total values:

| Field name             | Value type       |
| ---                    | ---              |
| Actual Total Time      | per-loop average |
| Actual Rows            | per-loop average |
| Buffers Shared Hit     | total value      |
| Buffers Shared Read    | total value      |
| Buffers Shared Dirtied | total value      |
| Buffers Shared Written | total value      |
| I/O Read Time          | total value      |
| I/O Read Write         | total value      |

For example:

```sql
 ->  Index Scan using users_pkey on public.users  (cost=0.43..3.44 rows=1 width=1318) (actual time=0.025..0.025 rows=1 loops=888)
       Index Cond: (users.id = issues.author_id)
       Buffers: shared hit=3543 read=9
       I/O Timings: read=17.760 write=0.000
```

Here we can see that this node used 3552 buffers (3543 + 9), returned 888 rows (`888 * 1`), and the actual duration was 22.2 milliseconds (`888 * 0.025`).
17.76 milliseconds of the total duration was spent in reading from disk, to retrieve data that was not in the cache.

## Node types

There are quite a few different types of nodes, so we only cover some of the
more common ones here.

A full list of all the available nodes and their descriptions can be found in
the [PostgreSQL source file `plannodes.h`](https://gitlab.com/postgres/postgres/blob/master/src/include/nodes/plannodes.h).
The `pgMustard` [EXPLAIN documentation](https://www.pgmustard.com/docs/explain) also offers detailed look into nodes and their fields.

### Seq Scan

A sequential scan over (a chunk of) a database table. This is like using
`Array#each`, but on a database table. Sequential scans can be quite slow when
retrieving lots of rows, so it's best to avoid these for large tables.

### Index Only Scan

A scan on an index that did not require fetching anything from the table. In
certain cases an index only scan may still fetch data from the table, in this
case the node includes a `Heap Fetches:` statistic.

### Index Scan

A scan on an index that required retrieving some data from the table.

### Bitmap Index Scan and Bitmap Heap scan

Bitmap scans fall between sequential scans and index scans. These are typically
used when we would read too much data from an index scan, but too little to
perform a sequential scan. A bitmap scan uses what is known as a
[bitmap index](https://en.wikipedia.org/wiki/Bitmap_index) to perform its work.

The [source code of PostgreSQL](https://gitlab.com/postgres/postgres/blob/REL_11_STABLE/src/include/nodes/plannodes.h#L441)
states the following on bitmap scans:

> Bitmap Index Scan delivers a bitmap of potential tuple locations; it does not
> access the heap itself. The bitmap is used by an ancestor Bitmap Heap Scan
> node, possibly after passing through intermediate Bitmap Or and/or Bitmap And
> nodes to combine it with the results of other Bitmap Index Scans.

### Limit

Applies a `LIMIT` on the input rows.

### Sort

Sorts the input rows as specified using an `ORDER BY` statement.

### Nested Loop

A nested loop executes its child nodes for every row produced by a node that
precedes it. For example:

```sql
->  Nested Loop  (cost=0.86..176.75 rows=87 width=0) (actual time=0.035..0.249 rows=36 loops=1)
      Buffers: shared hit=155
      ->  Index Only Scan using users_pkey on users users_1  (cost=0.43..4.95 rows=87 width=4) (actual time=0.029..0.123 rows=36 loops=1)
            Index Cond: (id < 100)
            Heap Fetches: 0
      ->  Index Only Scan using users_pkey on users  (cost=0.43..1.96 rows=1 width=4) (actual time=0.003..0.003 rows=1 loops=36)
            Index Cond: (id = users_1.id)
            Heap Fetches: 0
```

Here the first child node (`Index Only Scan using users_pkey on users users_1`)
produces 36 rows, and is executed once (`rows=36 loops=1`). The next node
produces 1 row (`rows=1`), but is repeated 36 times (`loops=36`). This is
because the previous node produced 36 rows.

This means that nested loops can quickly slow the query down if the various
child nodes keep producing many rows.

## Optimizing queries

With that out of the way, let's see how we can optimize a query. Let's use the
following query as an example:

```sql
SELECT COUNT(*)
FROM users
WHERE twitter != '';
```

This query counts the number of users that have a Twitter profile set.
Let's run this using `EXPLAIN (ANALYZE, BUFFERS)`:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM users
WHERE twitter != '';
```

This produces the following plan:

```sql
Aggregate  (cost=845110.21..845110.22 rows=1 width=8) (actual time=1271.157..1271.158 rows=1 loops=1)
  Buffers: shared hit=202662
  ->  Seq Scan on users  (cost=0.00..844969.99 rows=56087 width=0) (actual time=0.019..1265.883 rows=51833 loops=1)
        Filter: ((twitter)::text <> ''::text)
        Rows Removed by Filter: 2487813
        Buffers: shared hit=202662
Planning time: 0.390 ms
Execution time: 1271.180 ms
```

From this query plan we can see the following:

1. We need to perform a sequential scan on the `users` table.
1. This sequential scan filters out 2,487,813 rows using a `Filter`.
1. We use 202,622 buffers, which equals 1.58 GB of memory.
1. It takes us 1.2 seconds to do all of this.

Considering we are just counting users, that's quite expensive!

Before we start making any changes, let's see if there are any existing indexes
on the `users` table that we might be able to use. We can obtain this
information by running `\d users` in a `psql` console, then scrolling down to
the `Indexes:` section:

```sql
Indexes:
    "users_pkey" PRIMARY KEY, btree (id)
    "index_users_on_confirmation_token" UNIQUE, btree (confirmation_token)
    "index_users_on_email" UNIQUE, btree (email)
    "index_users_on_reset_password_token" UNIQUE, btree (reset_password_token)
    "index_users_on_static_object_token" UNIQUE, btree (static_object_token)
    "index_users_on_unlock_token" UNIQUE, btree (unlock_token)
    "index_on_users_name_lower" btree (lower(name::text))
    "index_users_on_admin" btree (admin)
    "index_users_on_created_at" btree (created_at)
    "index_users_on_email_trigram" gin (email gin_trgm_ops)
    "index_users_on_feed_token" btree (feed_token)
    "index_users_on_group_view" btree (group_view)
    "index_users_on_incoming_email_token" btree (incoming_email_token)
    "index_users_on_managing_group_id" btree (managing_group_id)
    "index_users_on_name" btree (name)
    "index_users_on_name_trigram" gin (name gin_trgm_ops)
    "index_users_on_public_email" btree (public_email) WHERE public_email::text <> ''::text
    "index_users_on_state" btree (state)
    "index_users_on_state_and_user_type" btree (state, user_type)
    "index_users_on_unconfirmed_email" btree (unconfirmed_email) WHERE unconfirmed_email IS NOT NULL
    "index_users_on_user_type" btree (user_type)
    "index_users_on_username" btree (username)
    "index_users_on_username_trigram" gin (username gin_trgm_ops)
    "tmp_idx_on_user_id_where_bio_is_filled" btree (id) WHERE COALESCE(bio, ''::character varying)::text IS DISTINCT FROM ''::text
```

Here we can see there is no index on the `twitter` column, which means
PostgreSQL has to perform a sequential scan in this case. Let's try to fix this
by adding the following index:

```sql
CREATE INDEX CONCURRENTLY twitter_test ON users (twitter);
```

If we now re-run our query using `EXPLAIN (ANALYZE, BUFFERS)` we get the
following plan:

```sql
Aggregate  (cost=61002.82..61002.83 rows=1 width=8) (actual time=297.311..297.312 rows=1 loops=1)
  Buffers: shared hit=51854 dirtied=19
  ->  Index Only Scan using twitter_test on users  (cost=0.43..60873.13 rows=51877 width=0) (actual time=279.184..293.532 rows=51833 loops=1)
        Filter: ((twitter)::text <> ''::text)
        Rows Removed by Filter: 2487830
        Heap Fetches: 26037
        Buffers: shared hit=51854 dirtied=19
Planning time: 0.191 ms
Execution time: 297.334 ms
```

Now it takes just under 300 milliseconds to get our data, instead of 1.2
seconds. However, we still use 51,854 buffers, which is about 400 MB of memory.
300 milliseconds is also quite slow for such a simple query. To understand why
this query is still expensive, let's take a look at the following:

```sql
Index Only Scan using twitter_test on users  (cost=0.43..60873.13 rows=51877 width=0) (actual time=279.184..293.532 rows=51833 loops=1)
  Filter: ((twitter)::text <> ''::text)
  Rows Removed by Filter: 2487830
```

We start with an index only scan on our index, but we somehow still apply a
`Filter` that filters out 2,487,830 rows. Why is that? Well, let's look at how
we created the index:

```sql
CREATE INDEX CONCURRENTLY twitter_test ON users (twitter);
```

We told PostgreSQL to index all possible values of the `twitter` column,
even empty strings. Our query in turn uses `WHERE twitter != ''`. This means
that the index does improve things, as we don't need to do a sequential scan,
but we may still encounter empty strings. This means PostgreSQL _has_ to apply a
Filter on the index results to get rid of those values.

Fortunately, we can improve this even further using "partial indexes". Partial
indexes are indexes with a `WHERE` condition that is applied when indexing data.
For example:

```sql
CREATE INDEX CONCURRENTLY some_index ON users (email) WHERE id < 100
```

This index would only index the `email` value of rows that match `WHERE id < 100`.
We can use partial indexes to change our Twitter index to the following:

```sql
CREATE INDEX CONCURRENTLY twitter_test ON users (twitter) WHERE twitter != '';
```

After being created, if we run our query again we are given the following plan:

```sql
Aggregate  (cost=1608.26..1608.27 rows=1 width=8) (actual time=19.821..19.821 rows=1 loops=1)
  Buffers: shared hit=44036
  ->  Index Only Scan using twitter_test on users  (cost=0.41..1479.71 rows=51420 width=0) (actual time=0.023..15.514 rows=51833 loops=1)
        Heap Fetches: 1208
        Buffers: shared hit=44036
Planning time: 0.123 ms
Execution time: 19.848 ms
```

That's _a lot_ better! Now it only takes 20 milliseconds to get the data, and we
only use about 344 MB of buffers (instead of the original 1.58 GB). The reason
this works is that now PostgreSQL no longer needs to apply a `Filter`, as the
index only contains `twitter` values that are not empty.

Keep in mind that you shouldn't just add partial indexes every time you want to
optimize a query. Every index has to be updated for every write, and they may
require quite a bit of space, depending on the amount of indexed data. As a
result, first check if there are any existing indexes you may be able to reuse.
If there aren't any, check if you can perhaps slightly change an existing one to
fit both the existing and new queries. Only add a new index if none of the
existing indexes can be used in any way.

When comparing execution plans, don't take timing as the only important metric.
Good timing is the main goal of any optimization, but it can be too volatile to
be used for comparison (for example, it depends a lot on the state of cache).
When optimizing a query, we usually need to reduce the amount of data we're
dealing with. Indexes are the way to work with fewer pages (buffers) to get the
result, so, during optimization, look at the number of buffers used (read and hit),
and work on reducing these numbers. Reduced timing is the consequence of reduced
buffer numbers. [Database Lab Engine](#database-lab-engine) guarantees that the plan is structurally
identical to production (and overall number of buffers is the same as on production),
but difference in cache state and I/O speed may lead to different timings.

## Queries that can't be optimized

Now that we have seen how to optimize a query, let's look at another query that
we might not be able to optimize:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM projects
WHERE visibility_level IN (0, 20);
```

The output of `EXPLAIN (ANALYZE, BUFFERS)` is as follows:

```sql
Aggregate  (cost=922420.60..922420.61 rows=1 width=8) (actual time=3428.535..3428.535 rows=1 loops=1)
  Buffers: shared hit=208846
  ->  Seq Scan on projects  (cost=0.00..908053.18 rows=5746969 width=0) (actual time=0.041..2987.606 rows=5746940 loops=1)
        Filter: (visibility_level = ANY ('{0,20}'::integer[]))
        Rows Removed by Filter: 65677
        Buffers: shared hit=208846
Planning time: 2.861 ms
Execution time: 3428.596 ms
```

Looking at the output we see the following Filter:

```sql
Filter: (visibility_level = ANY ('{0,20}'::integer[]))
Rows Removed by Filter: 65677
```

Looking at the number of rows removed by the filter, we may be tempted to add an
index on `projects.visibility_level` to somehow turn this Sequential scan +
filter into an index-only scan.

Unfortunately, doing so is unlikely to improve anything. Contrary to what some
might believe, an index being present _does not guarantee_ that PostgreSQL
actually uses it. For example, when doing a `SELECT * FROM projects` it is much
cheaper to just scan the entire table, instead of using an index and then
fetching data from the table. In such cases PostgreSQL may decide to not use an
index.

Second, let's think for a moment what our query does: it gets all projects with
visibility level 0 or 20. In the above plan we can see this produces quite a lot
of rows (5,745,940), but how much is that relative to the total? Let's find out
by running the following query:

```sql
SELECT visibility_level, count(*) AS amount
FROM projects
GROUP BY visibility_level
ORDER BY visibility_level ASC;
```

For GitLab.com this produces:

```sql
 visibility_level | amount
------------------+---------
                0 | 5071325
               10 |   65678
               20 |  674801
```

Here the total number of projects is 5,811,804, and 5,746,126 of those are of
level 0 or 20. That's 98% of the entire table!

So no matter what we do, this query retrieves 98% of the entire table. Since
most time is spent doing exactly that, there isn't really much we can do to
improve this query, other than _not_ running it at all.

What is important here is that while some may recommend to straight up add an
index the moment you see a sequential scan, it is _much more important_ to first
understand what your query does, how much data it retrieves, and so on. After
all, you cannot optimize something you do not understand.

### Cardinality and selectivity

Earlier we saw that our query had to retrieve 98% of the rows in the table.
There are two terms commonly used for databases: cardinality, and selectivity.
Cardinality refers to the number of unique values in a particular column in a
table.

Selectivity is the number of unique values produced by an operation (for example, an
index scan or filter), relative to the total number of rows. The higher the
selectivity, the more likely PostgreSQL is able to use an index.

In the above example, there are only 3 unique values: 0, 10, and 20. This means
the cardinality is 3. The selectivity in turn is also very low: 0.0000003% (2 /
5,811,804), because our `Filter` only filters using two values (`0` and `20`).
With such a low selectivity value it's not surprising that PostgreSQL decides
using an index is not worth it, because it would produce almost no unique rows.

## Rewriting queries

So the above query can't really be optimized as-is, or at least not much. But
what if we slightly change the purpose of it? What if instead of retrieving all
projects with `visibility_level` 0 or 20, we retrieve those that a user
interacted with somehow?

Prior to GitLab 16.7, GitLab used a table named `user_interacted_projects` to track user interactions with projects.
This table had the following schema:

```sql
Table "public.user_interacted_projects"
   Column   |  Type   | Modifiers
------------+---------+-----------
 user_id    | integer | not null
 project_id | integer | not null
Indexes:
    "index_user_interacted_projects_on_project_id_and_user_id" UNIQUE, btree (project_id, user_id)
    "index_user_interacted_projects_on_user_id" btree (user_id)
Foreign-key constraints:
    "fk_rails_0894651f08" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    "fk_rails_722ceba4f7" FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
```

Let's rewrite our query to `JOIN` this table onto our projects, and get the
projects for a specific user:

```sql
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM projects
INNER JOIN user_interacted_projects ON user_interacted_projects.project_id = projects.id
WHERE projects.visibility_level IN (0, 20)
AND user_interacted_projects.user_id = 1;
```

What we do here is the following:

1. Get our projects.
1. `INNER JOIN` `user_interacted_projects`, meaning we're only left with rows in
   `projects` that have a corresponding row in `user_interacted_projects`.
1. Limit this to the projects with `visibility_level` of 0 or 20, and to
   projects that the user with ID 1 interacted with.

If we run this query we get the following plan:

```sql
 Aggregate  (cost=871.03..871.04 rows=1 width=8) (actual time=9.763..9.763 rows=1 loops=1)
   ->  Nested Loop  (cost=0.86..870.52 rows=203 width=0) (actual time=1.072..9.748 rows=143 loops=1)
         ->  Index Scan using index_user_interacted_projects_on_user_id on user_interacted_projects  (cost=0.43..160.71 rows=205 width=4) (actual time=0.939..2.508 rows=145 loops=1)
               Index Cond: (user_id = 1)
         ->  Index Scan using projects_pkey on projects  (cost=0.43..3.45 rows=1 width=4) (actual time=0.049..0.050 rows=1 loops=145)
               Index Cond: (id = user_interacted_projects.project_id)
               Filter: (visibility_level = ANY ('{0,20}'::integer[]))
               Rows Removed by Filter: 0
 Planning time: 2.614 ms
 Execution time: 9.809 ms
```

Here it only took us just under 10 milliseconds to get the data. We can also see
we're retrieving far fewer projects:

```sql
Index Scan using projects_pkey on projects  (cost=0.43..3.45 rows=1 width=4) (actual time=0.049..0.050 rows=1 loops=145)
  Index Cond: (id = user_interacted_projects.project_id)
  Filter: (visibility_level = ANY ('{0,20}'::integer[]))
  Rows Removed by Filter: 0
```

Here we see we perform 145 loops (`loops=145`), with every loop producing 1 row
(`rows=1`). This is much less than before, and our query performs much better!

If we look at the plan we also see our costs are very low:

```sql
Index Scan using projects_pkey on projects  (cost=0.43..3.45 rows=1 width=4) (actual time=0.049..0.050 rows=1 loops=145)
```

Here our cost is only 3.45, and it takes us 7.25 milliseconds to do so (0.05 * 145).
The next index scan is a bit more expensive:

```sql
Index Scan using index_user_interacted_projects_on_user_id on user_interacted_projects  (cost=0.43..160.71 rows=205 width=4) (actual time=0.939..2.508 rows=145 loops=1)
```

Here the cost is 160.71 (`cost=0.43..160.71`), taking about 2.5 milliseconds
(based on the output of `actual time=....`).

The most expensive part here is the "Nested Loop" that acts upon the result of
these two index scans:

```sql
Nested Loop  (cost=0.86..870.52 rows=203 width=0) (actual time=1.072..9.748 rows=143 loops=1)
```

Here we had to perform 870.52 disk page fetches for 203 rows, 9.748
milliseconds, producing 143 rows in a single loop.

The key takeaway here is that sometimes you have to rewrite (parts of) a query
to make it better. Sometimes that means having to slightly change your feature
to accommodate for better performance.

## What makes a bad plan

This is a bit of a difficult question to answer, because the definition of "bad"
is relative to the problem you are trying to solve. However, some patterns are
best avoided in most cases, such as:

- Sequential scans on large tables
- Filters that remove a lot of rows
- Performing a certain step that requires _a lot_ of
  buffers (for example, an index scan for GitLab.com that requires more than 512 MB).

As a general guideline, aim for a query that:

1. Takes no more than 10 milliseconds. Our target time spent in SQL per request
   is around 100 milliseconds, so every query should be as fast as possible.
1. Does not use an excessive number of buffers, relative to the workload. For
   example, retrieving ten rows shouldn't require 1 GB of buffers.
1. Does not spend a long amount of time performing disk IO operations. The
   setting `track_io_timing` must be enabled for this data to be included in the
   output of `EXPLAIN ANALYZE`.
1. Applies a `LIMIT` when retrieving rows without aggregating them, such as
   `SELECT * FROM users`.
1. Doesn't use a `Filter` to filter out too many rows, especially if the query
   does not use a `LIMIT` to limit the number of returned rows. Filters can
   usually be removed by adding a (partial) index.

These are _guidelines_ and not hard requirements, as different needs may require
different queries. The only _rule_ is that you _must always measure_ your query
(preferably using a production-like database) using `EXPLAIN (ANALYZE, BUFFERS)`
and related tools such as:

- [`explain.depesz.com`](https://explain.depesz.com/).
- [`explain.dalibo.com/`](https://explain.dalibo.com/).

## Producing query plans

There are a few ways to get the output of a query plan. Of course you
can directly run the `EXPLAIN` query in the `psql` console, or you can
follow one of the other options below.

### Database Lab Engine

GitLab team members can use [Database Lab Engine](https://gitlab.com/postgres-ai/database-lab), and the companion
SQL optimization tool - [Joe Bot](https://gitlab.com/postgres-ai/joe).

Database Lab Engine provides developers with their own clone of the production database, while Joe Bot helps with exploring execution plans.

Joe Bot is available through its [web interface](https://console.postgres.ai/gitlab/joe-instances).

With Joe Bot you can execute DDL statements (like creating indexes, tables, and columns) and get query plans for `SELECT`, `UPDATE`, and `DELETE` statements.

For example, to test new index on a column that is not existing on production yet, you can do the following:

Create the column:

```sql
exec ALTER TABLE projects ADD COLUMN last_at timestamp without time zone
```

Create the index:

```sql
exec CREATE INDEX index_projects_last_activity ON projects (last_activity_at) WHERE last_activity_at IS NOT NULL
```

Analyze the table to update its statistics:

```sql
exec ANALYZE projects
```

Get the query plan:

```sql
explain SELECT * FROM projects WHERE last_activity_at < CURRENT_DATE
```

Once done you can rollback your changes:

```sql
reset
```

For more information about the available options, run:

```sql
help
```

The web interface comes with the following execution plan visualizers included:

- [Depesz](https://explain.depesz.com/)
- [PEV2](https://github.com/dalibo/pev2)
- [FlameGraph](https://github.com/mgartner/pg_flame)

#### Tips & Tricks

The database connection is now maintained during your whole session, so you can use `exec set ...` for any session variables (such as `enable_seqscan` or `work_mem`). These settings are applied to all subsequent commands until you reset them. For example you can disable parallel queries with

```sql
exec SET max_parallel_workers_per_gather = 0
```

### Rails console

Using the [`activerecord-explain-analyze`](https://github.com/6/activerecord-explain-analyze)
you can directly generate the query plan from the Rails console:

```ruby
pry(main)> require 'activerecord-explain-analyze'
=> true
pry(main)> Project.where('build_timeout > ?', 3600).explain(analyze: true)
  Project Load (1.9ms)  SELECT "projects".* FROM "projects" WHERE (build_timeout > 3600)
  ↳ (pry):12
=> EXPLAIN for: SELECT "projects".* FROM "projects" WHERE (build_timeout > 3600)
Seq Scan on public.projects  (cost=0.00..2.17 rows=1 width=742) (actual time=0.040..0.041 rows=0 loops=1)
  Output: id, name, path, description, created_at, updated_at, creator_id, namespace_id, ...
  Filter: (projects.build_timeout > 3600)
  Rows Removed by Filter: 14
  Buffers: shared hit=2
Planning time: 0.411 ms
Execution time: 0.113 ms
```

## Further reading

A more extensive guide on understanding query plans can be found in
the [presentation](https://public.dalibo.com/exports/conferences/_archives/_2012/201211_explain/understanding_explain.pdf)
from [Dalibo.org](https://www.dalibo.com/en/).

The Depesz blog also has a good [section](https://www.depesz.com/tag/unexplainable/) dedicated to query plans.
