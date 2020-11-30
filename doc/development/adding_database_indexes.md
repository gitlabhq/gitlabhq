---
stage: Enablement
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

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

## Requirements for naming indexes

Indexes with complex definitions need to be explicitly named rather than
relying on the implicit naming behavior of migration methods. In short,
that means you **must** provide an explicit name argument for an index
created with one or more of the following options:

- `where`
- `using`
- `order`
- `length`
- `type`
- `opclass`

### Considerations for index names

Index names don't have any significance in the database, so they should
attempt to communicate intent to others. The most important rule to
remember is that generic names are more likely to conflict or be duplicated,
and should not be used. Some other points to consider:

- For general indexes, use a template, like: `index_{table}_{column}_{options}`.
- For indexes added to solve a very specific problem, it may make sense
  for the name to reflect their use.
- Identifiers in PostgreSQL have a maximum length of 63 bytes.
- Check `db/structure.sql` for conflicts and ideas.

### Why explicit names are required

As Rails is database agnostic, it generates an index name only
from the required options of all indexes: table name and column name(s).
For example, imagine the following two indexes are created in a migration:

```ruby
def up
  add_index :my_table, :my_column

  add_index :my_table, :my_column, where: 'my_column IS NOT NULL'
end
```

Creation of the second index would fail, because Rails would generate
the same name for both indexes.

This is further complicated by the behavior of the `index_exists?` method.
It considers only the table name, column name(s) and uniqueness specification
of the index when making a comparison. Consider:

```ruby
def up
  unless index_exists?(:my_table, :my_column, where: 'my_column IS NOT NULL')
    add_index :my_table, :my_column, where: 'my_column IS NOT NULL'
  end
end
```

The call to `index_exists?` will return true if **any** index exists on
`:my_table` and `:my_column`, and index creation will be bypassed.

The `add_concurrent_index` helper is a requirement for creating indexes
on populated tables. Since it cannot be used inside a transactional
migration, it has a built-in check that detects if the index already
exists. In the event a match is found, index creation is skipped.
Without an explicit name argument, Rails can return a false positive
for `index_exists?`, causing a required index to not be created
properly. By always requiring a name for certain types of indexes, the
chance of error is greatly reduced.
