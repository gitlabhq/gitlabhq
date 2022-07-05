---
stage: Data Stores
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

While in certain cases indexing columns using the above approach may make sense,
it can actually have a negative impact. Whenever you write data to a table, any
existing indexes must also be updated. The more indexes there are, the slower this
can potentially become. Indexes can also take up significant disk space, depending
on the amount of data indexed and the index type. For example, PostgreSQL offers
`GIN` indexes which can be used to index certain data types that cannot be
indexed by regular B-tree indexes. These indexes, however, generally take up more
data and are slower to update compared to B-tree indexes.

Because of all this, it's important make the following considerations
when adding a new index:

1. Do the new queries re-use as many existing indexes as possible?
1. Is there enough data that using an index is faster than iterating over
   rows in the table?
1. Is the overhead of maintaining the index worth the reduction in query
   timings?

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
`state` column. One may think this query performs badly due to `state` being
unindexed. In reality the query may perform just fine given the index on
`user_id` can filter out enough rows.

The best way to determine if indexes are re-used is to run your query using
`EXPLAIN ANALYZE`. Depending on the joined tables and the columns being used for filtering,
you may find an extra index doesn't make much, if any, difference.

In short:

1. Try to write your query in such a way that it re-uses as many existing
   indexes as possible.
1. Run the query using `EXPLAIN ANALYZE` and study the output to find the most
   ideal query.

## Data Size

A database may not use an index even when a regular sequence scan
(iterating over all rows) is faster, especially for small tables.

Consider adding an index if a table is expected to grow, and your query has to filter a lot of rows.
You may _not_ want to add an index if the table size is small (<`1,000` records),
or if existing indexes already filter out enough rows.

## Maintenance Overhead

Indexes have to be updated on every table write. In the case of PostgreSQL, _all_
existing indexes are updated whenever data is written to a table. As a
result, having many indexes on the same table slows down writes. It's therefore important
to balance query performance with the overhead of maintaining an extra index.

Let's say that adding an index reduces SELECT timings by 5 milliseconds but increases
INSERT/UPDATE/DELETE timings by 10 milliseconds. In this case, the new index may not be worth
it. A new index is more valuable when SELECT timings are reduced and INSERT/UPDATE/DELETE
timings are unaffected.

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
them by indexes sizes in descending order. This query helps in
determining whether existing indexes are still required. More information on
the meaning of the various columns can be found at
<https://www.postgresql.org/docs/current/monitoring-stats.html>.

To determine if an index is still being used on production, use the following
Thanos query with your index name:

```sql
sum(rate(pg_stat_user_indexes_idx_tup_read{env="gprd", indexrelname="index_ci_name", type="patroni-ci"}[5m]))
```

Because the query output relies on the actual usage of your database, it
may be affected by factors such as:

- Certain queries never being executed, thus not being able to use certain
  indexes.
- Certain tables having little data, resulting in PostgreSQL using sequence
  scans instead of index scans.

This data is only reliable for a frequently used database with
plenty of data, and using as many GitLab features as possible.

## Requirements for naming indexes

Indexes with complex definitions must be explicitly named rather than
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
from the required options of all indexes: table name and column names.
For example, imagine the following two indexes are created in a migration:

```ruby
def up
  add_index :my_table, :my_column

  add_index :my_table, :my_column, where: 'my_column IS NOT NULL'
end
```

Creation of the second index would fail, because Rails would generate
the same name for both indexes.

This naming issue is further complicated by the behavior of the `index_exists?` method.
It considers only the table name, column names, and uniqueness specification
of the index when making a comparison. Consider:

```ruby
def up
  unless index_exists?(:my_table, :my_column, where: 'my_column IS NOT NULL')
    add_index :my_table, :my_column, where: 'my_column IS NOT NULL'
  end
end
```

The call to `index_exists?` returns true if **any** index exists on
`:my_table` and `:my_column`, and index creation is bypassed.

The `add_concurrent_index` helper is a requirement for creating indexes
on populated tables. Because it cannot be used inside a transactional
migration, it has a built-in check that detects if the index already
exists. In the event a match is found, index creation is skipped.
Without an explicit name argument, Rails can return a false positive
for `index_exists?`, causing a required index to not be created
properly. By always requiring a name for certain types of indexes, the
chance of error is greatly reduced.

## Temporary indexes

There may be times when an index is only needed temporarily.

For example, in a migration, a column of a table might be conditionally
updated. To query which columns must be updated in the
[query performance guidelines](query_performance.md), an index is needed
that would otherwise not be used.

In these cases, consider a temporary index. To specify a
temporary index:

1. Prefix the index name with `tmp_` and follow the [naming conventions](database/constraint_naming_convention.md)
   and [requirements for naming indexes](#requirements-for-naming-indexes) for the rest of the name.
1. Create a follow-up issue to remove the index in the next (or future) milestone.
1. Add a comment in the migration mentioning the removal issue.

A temporary migration would look like:

```ruby
INDEX_NAME = 'tmp_index_projects_on_owner_where_emails_disabled'

def up
  # Temporary index to be removed in 13.9 https://gitlab.com/gitlab-org/gitlab/-/issues/1234
  add_concurrent_index :projects, :creator_id, where: 'emails_disabled = false', name: INDEX_NAME
end

def down
  remove_concurrent_index_by_name :projects, INDEX_NAME
end
```

## Create indexes asynchronously

For very large tables, index creation can be a challenge to manage.
While `add_concurrent_index` creates indexes in a way that does not block
normal traffic, it can still be problematic when index creation runs for
many hours. Necessary database operations like `autovacuum` cannot run, and
on GitLab.com, the deployment process is blocked waiting for index
creation to finish.

To limit impact on GitLab.com, a process exists to create indexes
asynchronously during weekend hours. Due to generally lower traffic and fewer deployments,
index creation can proceed at a lower level of risk.

### Schedule index creation for a low-impact time

1. [Schedule the index to be created](#schedule-the-index-to-be-created).
1. [Verify the MR was deployed and the index exists in production](#verify-the-mr-was-deployed-and-the-index-exists-in-production).
1. [Add a migration to create the index synchronously](#add-a-migration-to-create-the-index-synchronously).

### Schedule the index to be created

Create an MR with a post-deployment migration which prepares the index
for asynchronous creation. An example of creating an index using
the asynchronous index helpers can be seen in the block below. This migration
enters the index name and definition into the `postgres_async_indexes`
table. The process that runs on weekends pulls indexes from this
table and attempt to create them.

```ruby
# in db/post_migrate/

INDEX_NAME = 'index_ci_builds_on_some_column'

def up
  prepare_async_index :ci_builds, :some_column, name: INDEX_NAME
end

def down
  unprepare_async_index :ci_builds, :some_column, name: INDEX_NAME
end
```

### Verify the MR was deployed and the index exists in production

You can verify if the MR was deployed to GitLab.com by executing
`/chatops run auto_deploy status <merge_sha>`. To verify existence of
the index, you can:

- Use a meta-command in #database-lab, such as: `\d <index_name>`.
  - Ensure that the index is not [`invalid`](https://www.postgresql.org/docs/12/sql-createindex.html#:~:text=The%20psql%20%5Cd%20command%20will%20report%20such%20an%20index%20as%20INVALID).
- Ask someone in #database to check if the index exists.
- With proper access, you can also verify directly on production or in a
production clone.

### Add a migration to create the index synchronously

After the index is verified to exist on the production database, create a second
merge request that adds the index synchronously. The schema changes must be
updated and committed to `structure.sql` in this second merge request.
The synchronous migration results in a no-op on GitLab.com, but you should still add the
migration as expected for other installations. The below block
demonstrates how to create the second migration for the previous
asynchronous example.

**WARNING:**
Verify that the index exists in production before merging a second migration with `add_concurrent_index`.
If the second migration is deployed before the index has been created,
the index is created synchronously when the second migration executes.

```ruby
# in db/post_migrate/

INDEX_NAME = 'index_ci_builds_on_some_column'

disable_ddl_transaction!

def up
  add_concurrent_index :ci_builds, :some_column, name: INDEX_NAME
end

def down
  remove_concurrent_index_by_name :ci_builds, INDEX_NAME
end
```

## Test database index changes locally

You must test the database index changes locally before creating a merge request.

### Verify indexes created asynchronously

Use the asynchronous index helpers on your local environment to test changes for creating an index:

1. Enable the feature flags by running `Feature.enable(:database_async_index_creation)` and `Feature.enable(:database_reindexing)` in the Rails console.
1. Run `bundle exec rails db:migrate` so that it creates an entry in the `postgres_async_indexes` table.
1. Run `bundle exec rails gitlab:db:reindex` so that the index is created asynchronously.
1. To verify the index, open the PostgreSQL console using the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md) command `gdk psql` and run the command `\d <index_name>` to check that your newly created index exists.
