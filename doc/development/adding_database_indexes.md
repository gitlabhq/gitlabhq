# Adding Database Indexes

Indexes can be used to speed up database queries, but when should you add a new
index? Traditionally the answer to this question has been to add an index for
every column used for filtering or joining data. For example, consider the
following query:

```sql
SELECT *
FROM projects
WHERE user_id = 2;
```

Here we are filtering by the `user_id` column and as such a developer may decide
to index this column.

While in certain cases indexing columns using the above approach may make sense
it can actually have a negative impact. Whenever you write data to a table any
existing indexes need to be updated. The more indexes there are the slower this
can potentially become. Indexes can also take up quite some disk space depending
on the amount of data indexed and the index type. For example, PostgreSQL offers
"GIN" indexes which can be used to index certain data types that can not be
indexed by regular B-tree indexes. These indexes however generally take up more
data and are slower to update compared to B-tree indexes.

Because of all this one should not blindly add a new index for every column used
to filter data by. Instead one should ask themselves the following questions:

1. Can I write my query in such a way that it re-uses as many existing indexes
   as possible?
1. Is the data going to be large enough that using an index will actually be
   faster than just iterating over the rows in the table?
1. Is the overhead of maintaining the index worth the reduction in query
   timings?

We'll explore every question in detail below.

## Re-using Queries

The first step is to make sure your query re-uses as many existing indexes as
possible. For example, consider the following query:

```sql
SELECT *
FROM todos
WHERE user_id = 123
AND state = 'open';
```

Now imagine we already have an index on the `user_id` column but not on the
`state` column. One may think this query will perform badly due to `state` being
unindexed. In reality the query may perform just fine given the index on
`user_id` can filter out enough rows.

The best way to determine if indexes are re-used is to run your query using
`EXPLAIN ANALYZE`. Depending on any extra tables that may be joined and
other columns being used for filtering you may find an extra index is not going
to make much (if any) difference. On the other hand you may determine that the
index _may_ make a difference.

In short:

1. Try to write your query in such a way that it re-uses as many existing
   indexes as possible.
1. Run the query using `EXPLAIN ANALYZE` and study the output to find the most
   ideal query.

## Data Size

A database may decide not to use an index despite it existing in case a regular
sequence scan (= simply iterating over all existing rows) is faster. This is
especially the case for small tables.

If a table is expected to grow in size and you expect your query has to filter
out a lot of rows you may want to consider adding an index. If the table size is
very small (e.g. less than `1,000` records) or any existing indexes filter out
enough rows you may _not_ want to add a new index.

## Maintenance Overhead

Indexes have to be updated on every table write. In case of PostgreSQL _all_
existing indexes will be updated whenever data is written to a table. As a
result of this having many indexes on the same table will slow down writes.

Because of this one should ask themselves: is the reduction in query performance
worth the overhead of maintaining an extra index?

If adding an index reduces SELECT timings by 5 milliseconds but increases
INSERT/UPDATE/DELETE timings by 10 milliseconds then the index may not be worth
it. On the other hand, if SELECT timings are reduced but INSERT/UPDATE/DELETE
timings are not affected you may want to add the index after all.

## Finding Unused Indexes

To see which indexes are unused you can run the following query:

```sql
SELECT relname as table_name, indexrelname as index_name, idx_scan, idx_tup_read, idx_tup_fetch, pg_size_pretty(pg_relation_size(indexrelname::regclass))
FROM pg_stat_all_indexes
WHERE schemaname = 'public'
AND idx_scan = 0
AND idx_tup_read = 0
AND idx_tup_fetch = 0
ORDER BY pg_relation_size(indexrelname::regclass) desc;
```

This query outputs a list containing all indexes that are never used and sorts
them by indexes sizes in descending order. This query can be useful to
determine if any previously indexes are useful after all. More information on
the meaning of the various columns can be found at
<https://www.postgresql.org/docs/current/monitoring-stats.html>.

Because the output of this query relies on the actual usage of your database it
may be affected by factors such as (but not limited to):

- Certain queries never being executed, thus not being able to use certain
  indexes.
- Certain tables having little data, resulting in PostgreSQL using sequence
  scans instead of index scans.

In other words, this data is only reliable for a frequently used database with
plenty of data and with as many GitLab features enabled (and being used) as
possible.
