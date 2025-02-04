---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Adding Database Indexes
---

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

In some situations, an index might not be required:

- The table is small (less than `1,000` records) and it's not expected to exponentially grow in size.
- Any existing indexes filter out enough rows.
- The reduction in query timings after the index is added is not significant.

Additionally, wide indexes are not required to match all filter criteria of queries. We just need
to cover enough columns so that the index lookup has a small enough selectivity.

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

### Index limitations

GitLab enforces a limit of **15 indexes** per table. This limitation:

- Helps maintain optimal database performance
- Reduces maintenance overhead
- Prevents excessive disk space usage

NOTE:
If you need to add an index to a table that already has 15 indexes, consider:

- Removing unused indexes
- Combining existing indexes
- Using a composite index that can serve multiple query patterns

### Some tables should not have any more indexes

We have RuboCop checks (`PreventIndexCreation`) against further new indexes on selected tables
that are frequently accessed.
This is due to [LockManager LWLock contention](https://gitlab.com/groups/gitlab-org/-/epics/11543).

For the same reason, there are also RuboCop checks (`AddColumnsToWideTables`) against adding
new columns to these tables.

### Add index and make application code change together if possible

To minimize the risk of creating unnecessary indexes, do these in the same merge request if possible:

- Make application code changes.
- Create or remove indexes.

The migrations that create indexes are usually short, and do not significantly increase a merge request's size.
Doing so allows backend and database reviewers to review more efficiently without
switching contexts between merge requests or commits.

## Migration type to use

The authoritative guide is [the migration style guide](../migration_style_guide.md#choose-an-appropriate-migration-type).
When in doubt, consult the guide.

Here are some common scenarios with a recommended choice as a quick reference.

### Add an index to improve existing queries

Use a post-deployment migration.
Existing queries already work without the added indexes, and
would not critical to operating the application.

If indexing takes a long time to finish
(a post-deployment migration should take less than [10 minutes](../migration_style_guide.md#how-long-a-migration-should-take))
consider [indexing asynchronously](#create-indexes-asynchronously).

### Add an index to support new or updated queries

Always examine the query plans for new or updated queries. First, confirm they do not time-out
or significantly exceed [the recommended query timings](query_performance.md)
without a dedicated index.

If the queries don't time-out or breach the query timings:

- Any index added to improve the performance of the new queries is non-critical
  to operating the application.
- Use a post-deployment migration to create the index.
- In the same merge request, ship the application code changes that generate and use the new queries.

Queries that time-out or breach query timings require different actions, depending on
whether they do so only on GitLab.com, or for all GitLab instances.
Most features require a dedicated index only for GitLab.com, one of the largest GitLab installations.

#### New or updated queries perform slowly on GitLab.com

Use two MRs to create the index in a post-deployment migration and make the application code change:

- The first MR uses a post-deployment migration to create the index.
- The second MR makes application code changes. It should merge only after the first MR's
  post-deployment migrations are executed on GitLab.com.

NOTE:
If you can use a feature flag, you might be able to use a single MR
to make the code changes behind the feature flag. Include the post-deployment migration at the same time.
After the post-deployment migration executes, you can enable the feature flag.

For GitLab.com, we execute post-deployment migrations throughout a single release through continuous integration:

- At some time `t`, a group of merge requests are merged and ready to deploy.
- At `t+1`, the regular migrations from the group are executed on GitLab.com's staging and production database.
- At `t+2`, the application code changes from the group start deploying in a rolling manner

After the application code changes are fully deployed,
The release manager can choose to execute post-deployment migrations at their discretion at a much later time.
The post-deployment migration executes one time per day pending GitLab.com availability.
For this reason, you need a [confirmation](https://gitlab.com/gitlab-org/release/docs/-/tree/master/general/post_deploy_migration#how-to-determine-if-a-post-deploy-migration-has-been-executed-on-gitlabcom)
the post-deployment migrations included in the first MR were executed before merging the second MR.

#### New or updated queries might be slow on a large GitLab instance

It's not possible to check query performance directly on self-managed instances.
PostgreSQL produces an execution plan based on the data distribution, so
guessing query performance is a hard task.

If you are concerned about the performance of a query on self-managed instances
and decide that self-managed instances must have an index, follow these recommendations:

- For self-managed instances following [zero-downtime](../../update/zero_downtime.md)
  upgrades, post-deploy migrations execute when performing an upgrade after the application code deploys.
- For self-managed instances that do not follow a zero-downtime upgrade,
  the administrator might choose to execute the post-deployment migrations for a release later,
  at the time of their choosing, after the regular migrations execute. The application code deploys when they upgrade.

For this reason, an application must not assume a database schema applied by the
post-deployment migrations has shipped in the same release. The application code
should continue to work without the indexes added in the post-deployment migrations
in the same release.

You have two options depending on [how long it takes to create the index](../migration_style_guide.md#how-long-a-migration-should-take):

1. Single release: if a regular migration can create the required index very fast
   (usually because the table is new or very small) you can create the index in a
   regular migration, and ship the application code change in the same MR and milestone.

1. At least two releases: if the required index takes time to create,
   you must create it in a PDM in one release then wait for the next release to
   make the application code changes that rely on the index.

### Add a unique index acting as a constraint to an existing table

PostgreSQL's unique index acts as a constraint. Adding one to an existing table can be tricky.

Unless the table is absolutely guaranteed to be tiny for GitLab.com and self-managed instances,
you must use multiple post-deployment migrations over multiple releases to:

- Remove and(or) fix the duplicate records.
- Introduce a unique index constraining existing columns.

Refer to the multi-release approach outlined in
[the section for adding a NOT NULL constraint](not_null_constraints.md#add-a-not-null-constraint-to-an-existing-column).

PostgreSQL's unique index, unlike the regular constraints, cannot be introduced in a non-validated state.
You must use PostgreSQL's partial unique index and the application validation to enforce the desired uniqueness
for new and updated records while the removal and fix are in progress.

The details of the work might vary and require different approaches.
Consult the Database team, reviewers, or maintainers to plan the work.

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

To determine if an index is still being used on production, use [Grafana](https://dashboards.gitlab.net/explore?schemaVersion=1&panes=%7B%22pum%22%3A%7B%22datasource%22%3A%22mimir-gitlab-gprd%22%2C%22queries%22%3A%5B%7B%22refId%22%3A%22A%22%2C%22expr%22%3A%22sum+by+%28type%29%28rate%28pg_stat_user_indexes_idx_scan%7Benv%3D%5C%22gprd%5C%22%2C+indexrelname%3D%5C%22INSERT+INDEX+NAME+HERE%5C%22%7D%5B30d%5D%29%29%22%2C%22range%22%3Atrue%2C%22instant%22%3Atrue%2C%22datasource%22%3A%7B%22type%22%3A%22prometheus%22%2C%22uid%22%3A%22mimir-gitlab-gprd%22%7D%2C%22editorMode%22%3A%22code%22%2C%22legendFormat%22%3A%22__auto%22%7D%5D%2C%22range%22%3A%7B%22from%22%3A%22now-1h%22%2C%22to%22%3A%22now%22%7D%7D%7D&orgId=1):

```sql
sum by (type)(rate(pg_stat_user_indexes_idx_scan{env="gprd", indexrelname="INSERT INDEX NAME HERE"}[30d]))
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

Check our [Constraints naming conventions](constraint_naming_convention.md) page.

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

## Testing for existence of indexes

The easiest way to test for existence of an index by name is to use the `index_name_exists?` method, but the `index_exists?` method can also be used with a name option. For example:

```ruby
class MyMigration < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_name'

  def up
    # an index must be conditionally created due to schema inconsistency
    unless index_exists?(:table_name, :column_name, name: INDEX_NAME)
      add_index :table_name, :column_name, name: INDEX_NAME
    end
  end

  def down
    # no op
  end
end
```

Keep in mind that concurrent index helpers like `add_concurrent_index`, `remove_concurrent_index`, and `remove_concurrent_index_by_name` already perform existence checks internally.

## Temporary indexes

There may be times when an index is only needed temporarily.

For example, in a migration, a column of a table might be conditionally
updated. To query which columns must be updated in the
[query performance guidelines](query_performance.md), an index is needed
that would otherwise not be used.

In these cases, consider a temporary index. To specify a
temporary index:

1. Prefix the index name with `tmp_` and follow the [naming conventions](constraint_naming_convention.md).
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

## Analyzing a new index before a batched background migration

Sometimes it is necessary to add an index to support a [batched background migration](batched_background_migrations.md).
It is commonly done by creating two [post deployment migrations](post_deployment_migrations.md):

1. Add the new index, often a [temporary index](#temporary-indexes).
1. [Queue the batched background migration](batched_background_migrations.md#enqueue-a-batched-background-migration).

In most cases, no additional work is needed. The new index is created and is used
as expected when queuing and executing the batched background migration.

[Expression indexes](https://www.postgresql.org/docs/current/indexes-expressional.html),
however, do not generate statistics for the new index on creation. Autovacuum
eventually runs `ANALYZE`, and updates the statistics so the new index is used.
Run `ANALYZE` explicitly only if it is needed right after the index
is created, such as in the background migration scenario described above.

To trigger `ANALYZE` after the index is created, update the index creation migration
to analyze the table:

```ruby
# in db/post_migrate/

INDEX_NAME = 'tmp_index_projects_on_owner_and_lower_name_where_emails_disabled'
TABLE = :projects

disable_ddl_transaction!

def up
  add_concurrent_index TABLE, '(creator_id, lower(name))', where: 'emails_disabled = false', name: INDEX_NAME

  connection.execute("ANALYZE #{TABLE}")
end
```

`ANALYZE` should only be run in post deployment migrations and should not target
[large tables](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/rubocop-migrations.yml#L3).
If this behavior is needed on a larger table, ask for assistance in the `#database` Slack channel.

## Indexes for partitioned tables

You [cannot create indexes](https://www.postgresql.org/docs/15/ddl-partitioning.html#DDL-PARTITIONING-DECLARATIVE-MAINTENANCE)
concurrently on partitioned tables.
However, creating indexes non-concurrently holds a write lock on the table being indexed.
Therefore, you must use `CONCURRENTLY` when you create indexes to avoid service disruption in a hot system.

As a workaround, the Database team has provided `add_concurrent_partitioned_index`.
This helper creates indexes on partitioned tables without holding a write lock.

Under the hood, `add_concurrent_partitioned_index`:

1. Creates indexes on each partition using `CONCURRENTLY`.
1. Creates an index on the parent table.

A Rails migration example:

```ruby
# in db/post_migrate/

class AddIndexToPartitionedTable < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = :table_name
  COLUMN_NAMES = [:partition_id, :id]
  INDEX_NAME = :index_name

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
```

## Create indexes asynchronously

For very large tables, index creation can be a challenge to manage.
While `add_concurrent_index` creates indexes in a way that does not block
ordinary traffic, it can still be problematic when index creation runs for
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

1. Create a merge request containing a post-deployment migration, which prepares
   the index for asynchronous creation.
1. [Create a follow-up issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Synchronous%20Database%20Index)
   to add a migration that creates the index synchronously.
1. In the merge request that prepares the asynchronous index, add a comment mentioning the follow-up issue.

An example of creating an index using
the asynchronous index helpers can be seen in the block below. This migration
enters the index name and definition into the `postgres_async_indexes`
table. The process that runs on weekends pulls indexes from this
table and attempt to create them.

```ruby
# in db/post_migrate/

INDEX_NAME = 'index_ci_builds_on_some_column'

# TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/XXXXX
def up
  prepare_async_index :ci_builds, :some_column, name: INDEX_NAME
end

def down
  unprepare_async_index :ci_builds, :some_column, name: INDEX_NAME
end
```

For partitioned table, use:

```ruby
# in db/post_migrate/

include Gitlab::Database::PartitioningMigrationHelpers

PARTITIONED_INDEX_NAME = 'index_p_ci_builds_on_some_column'

# TODO: Partitioned index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/XXXXX
def up
  prepare_partitioned_async_index :p_ci_builds, :some_column, name: PARTITIONED_INDEX_NAME
end

def down
  unprepare_partitioned_async_index :p_ci_builds, :some_column, name: PARTITIONED_INDEX_NAME
end
```

NOTE:
`prepare_partitioned_async_index` only creates the indexes for partitions asynchronously. It doesn't attach the partition indexes to the partitioned table.
In the [next step for the partitioned table](#create-the-index-synchronously-for-partitioned-table), `add_concurrent_partitioned_index` will not only add the index synchronously but also attach the partition indexes to the partitioned table.

### Verify the MR was deployed and the index exists in production

1. Verify that the post-deploy migration was executed on GitLab.com using ChatOps with
   `/chatops run auto_deploy status <merge_sha>`. If the output returns `db/gprd`,
   the post-deploy migration has been executed in the production database. For more information, see
   [How to determine if a post-deploy migration has been executed on GitLab.com](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/post_deploy_migration/readme.md#how-to-determine-if-a-post-deploy-migration-has-been-executed-on-gitlabcom).
1. In the case of an [index created asynchronously](#schedule-the-index-to-be-created), wait
   until the next week so that the index can be created over a weekend.
1. Use [Database Lab](database_lab.md) to check [if creation was successful](database_lab.md#checking-indexes).
   Ensure the output does not indicate the index is `invalid`.

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

#### Create the index synchronously for partitioned table

```ruby
# in db/post_migrate/

include Gitlab::Database::PartitioningMigrationHelpers

PARTITIONED_INDEX_NAME = 'index_p_ci_builds_on_some_column'

disable_ddl_transaction!

def up
  add_concurrent_partitioned_index :p_ci_builds, :some_column, name: PARTITIONED_INDEX_NAME
end

def down
  remove_concurrent_partitioned_index_by_name :p_ci_builds, PARTITIONED_INDEX_NAME
end
```

## Test database index changes locally

You must test the database index changes locally before creating a merge request.

### Verify indexes created asynchronously

Use the asynchronous index helpers on your local environment to test changes for creating an index:

1. Enable the feature flags by running `Feature.enable(:database_async_index_creation)` and `Feature.enable(:database_reindexing)` in the Rails console.
1. Run `bundle exec rails db:migrate` so that it creates an entry in the `postgres_async_indexes` table.
<!-- markdownlint-disable MD044 -->
1. Run `bundle exec rails gitlab:db:execute_async_index_operations:all` so that the index is created asynchronously on all databases.
<!-- markdownlint-enable MD044 -->
1. To verify the index, open the PostgreSQL console using the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md) command `gdk psql` and run the command `\d <index_name>` to check that your newly created index exists.
      - For indexes created on partitions, check that a unique name has been autogenerated for that table `\d gitlab_partitions_dynamic.<table_name>`

## Drop indexes asynchronously

For very large tables, index destruction can be a challenge to manage.
While `remove_concurrent_index` removes indexes in a way that does not block
ordinary traffic, it can still be problematic if index destruction runs for
many hours. Necessary database operations like `autovacuum` cannot run, and
the deployment process on GitLab.com is blocked while waiting for index
destruction to finish.

To limit the impact on GitLab.com, use the following process to remove indexes
asynchronously during weekend hours. Due to generally lower traffic and fewer deployments,
index destruction can proceed at a lower level of risk.

1. [Schedule the index to be removed](#schedule-the-index-to-be-removed).
1. [Verify the MR was deployed and the index exists in production](#verify-the-mr-was-deployed-and-the-index-no-longer-exists-in-production).
1. [Add a migration to destroy the index synchronously](#add-a-migration-to-destroy-the-index-synchronously).

### Schedule the index to be removed

1. Create a merge request containing a post-deployment migration, which prepares
   the index for asynchronous destruction.
1. [Create a follow-up issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Synchronous%20Database%20Index)
   to add a migration that destroys the index synchronously.
1. In the merge request that prepares the asynchronous index removal, add a comment mentioning the follow-up issue.

For example, to destroy an index using
the asynchronous index helpers:

```ruby
# in db/post_migrate/

INDEX_NAME = 'index_ci_builds_on_some_column'

# TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/XXXXX
def up
  prepare_async_index_removal :ci_builds, :some_column, name: INDEX_NAME
end

def down
  unprepare_async_index :ci_builds, :some_column, name: INDEX_NAME
end
```

This migration enters the index name and definition into the `postgres_async_indexes`
table. The process that runs on weekends pulls indexes from this table and attempt
to remove them.

You must [test the database index changes locally](#verify-indexes-removed-asynchronously) before creating a merge request.
Include the output of the test in the merge request description.

### Verify the MR was deployed and the index no longer exists in production

1. Verify that the post-deploy migration was executed on GitLab.com using ChatOps with
   `/chatops run auto_deploy status <merge_sha>`. If the output returns `db/gprd`,
   the post-deploy migration has been executed in the production database. For more information, see
   [How to determine if a post-deploy migration has been executed on GitLab.com](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/post_deploy_migration/readme.md#how-to-determine-if-a-post-deploy-migration-has-been-executed-on-gitlabcom).
1. In the case of an [index removed asynchronously](#schedule-the-index-to-be-removed), wait
   until the next week so that the index can be removed over a weekend.
1. Use Database Lab [to check if removal was successful](database_lab.md#checking-indexes).
   [Database Lab](database_lab.md)
   should report an error when trying to find the removed index. If not, the index may still exist.

### Add a migration to destroy the index synchronously

After you verify the index no longer exists in the production database, create a second
merge request that removes the index synchronously. The schema changes must be
updated and committed to `structure.sql` in this second merge request.
The synchronous migration results in a no-op on GitLab.com, but you should still add the
migration as expected for other installations. For example, to
create the second migration for the previous asynchronous example:

**WARNING:**
Verify that the index no longer exists in production before merging a second migration with `remove_concurrent_index_by_name`.
If the second migration is deployed before the index has been destroyed,
the index is destroyed synchronously when the second migration executes.

```ruby
# in db/post_migrate/

INDEX_NAME = 'index_ci_builds_on_some_column'

disable_ddl_transaction!

def up
  remove_concurrent_index_by_name :ci_builds, name: INDEX_NAME
end

def down
  add_concurrent_index :ci_builds, :some_column, name: INDEX_NAME
end
```

### Verify indexes removed asynchronously

To test changes for removing an index, use the asynchronous index helpers on your local environment:

1. Enable the feature flags by running `Feature.enable(:database_reindexing)` in the Rails console.
1. Run `bundle exec rails db:migrate` which should create an entry in the `postgres_async_indexes` table.
1. Run `bundle exec rails gitlab:db:reindex` destroy the index asynchronously.
1. To verify the index, open the PostgreSQL console by using the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md)
   command `gdk psql` and run `\d <index_name>` to check that the destroyed index no longer exists.
