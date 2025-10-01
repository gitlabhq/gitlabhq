---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
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

## Partial Indexes

Partial indexes are indexes with a `WHERE` clause that limits them to a subset of matching rows.
They can offer several advantages over full indexes, including:

- Reduced index size and memory usage
- Less write and vacuum overhead
- Improved query performance for selective conditions

Partial indexes work best for queries that always filter on known conditions and target a specific subset of data.
Common use cases include:

- Nullable columns: `WHERE column IS NOT NULL`
- Boolean flags: `WHERE feature_enabled = true`
- Soft deletes: `WHERE deleted_at IS NULL`
- Status filters: `WHERE status IN ('queued', 'running')`

Before creating any new partial index, first examine existing indexes for potential reuse or modification.
Since each index incurs maintenance overhead, prioritize adapting current indexes over adding new ones.

### Example

Consider the following application code which introduces a new count query:

```ruby
def namespace_count
  NamespaceSetting.where(duo_features_enabled: duo_settings_value).count
end

def duo_settings_value
  params['duo_settings_value'] == 'default_on'
end
```

where `namespace_settings` is a table with 1 million records,
and `duo_features_enabled` is a nullable Boolean column.

Let's assume that we recently introduced this column and it was not backfilled.
This means we know that the majority of the records in the `namespace_settings` table have a `NULL`
value for `duo_features_enabled`. We can also see that `duo_settings_value` will only either yield
`true` or `false`.

Indexing all rows would be inefficient as we mostly have `NULL` values. Instead,
we can introduce a partial index that targets only the data of interest:

```sql
CREATE INDEX index_namespace_settings_on_duo_features_enabled_not_null
ON namespace_settings (duo_features_enabled)
WHERE duo_features_enabled IS NOT NULL;
```

Now we have an index that is just a small fraction of the full index size and the
query planner can effectively skip over hundreds of thousands of irrelevant records.

## Data Size

A database may not use an index even when a regular sequence scan
(iterating over all rows) is faster, especially for small tables.

Consider adding an index if a table is expected to grow, and your query has to filter a lot of rows.
You may not want to add an index if the table size is small (<`1,000` records),
or if existing indexes already filter out enough rows.

## Maintenance Overhead

Indexes have to be updated on every table write. In the case of PostgreSQL, _all_
existing indexes are updated whenever data is written to a table. As a
result, having many indexes on the same table slows down writes. It's therefore important
to balance query performance with the overhead of maintaining an extra index.

For example, if adding an index reduces SELECT timings by 5 milliseconds but increases
INSERT/UPDATE/DELETE timings by 10 milliseconds, the new index may not be worth
it. A new index is more valuable when SELECT timings are reduced and INSERT/UPDATE/DELETE
timings are unaffected.

### Index limitations

GitLab enforces a limit of **15 indexes** per table. This limitation:

- Helps maintain optimal database performance
- Reduces maintenance overhead
- Prevents excessive disk space usage

{{< alert type="note" >}}

If you need to add an index to a table that already has 15 indexes, consider:

{{< /alert >}}

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

{{< alert type="note" >}}

If you can use a feature flag, you might be able to use a single MR
to make the code changes behind the feature flag. Include the post-deployment migration at the same time.
After the post-deployment migration executes, you can enable the feature flag.

{{< /alert >}}

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

It's not possible to check query performance directly on GitLab Self-Managed instances.
PostgreSQL produces an execution plan based on the data distribution, so
guessing query performance is a hard task.

If you are concerned about the performance of a query on GitLab Self-Managed instances
and decide that GitLab Self-Managed instances must have an index, follow these recommendations:

- For GitLab Self-Managed instances following [zero-downtime](../../update/zero_downtime.md)
  upgrades, post-deploy migrations execute when performing an upgrade after the application code deploys.
- For GitLab Self-Managed instances that do not follow a zero-downtime upgrade,
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

Unless the table is absolutely guaranteed to be tiny for GitLab.com and GitLab Self-Managed instances,
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

### All unique indexes needs to be scoped

For more information, see [Unique constraints in Cells](../../development/cells/_index.md#unique-constraints).

## Dropping unused indexes

Unused indexes should be dropped because they increase [maintenance overhead](#maintenance-overhead), consume
disk space, and can degrade query planning efficiency without providing any performance benefit.
However, dropping an index that's still used could result in query performance degradation or timeouts,
potentially leading to incidents. It's important to [verify the index is unused](#verifying-that-an-index-is-unused)
on both on GitLab.com and GitLab Self-Managed instances prior to removal.

- For large tables, consider [dropping the index asynchronously](#drop-indexes-asynchronously).
- For partitioned tables, only the parent index can be dropped. PostgreSQL does not permit child indexes
  (i.e. the corresponding indexes on its partitions) to be independently removed.

### Finding possible unused indexes

To see which indexes are candidates for removal, you can run the following query:

```sql
SELECT relname as table_name, indexrelname as index_name, idx_scan, idx_tup_read, idx_tup_fetch, pg_size_pretty(pg_relation_size(indexrelname::regclass))
FROM pg_stat_all_indexes
WHERE schemaname = 'public'
AND idx_scan = 0
AND idx_tup_read = 0
AND idx_tup_fetch = 0
ORDER BY pg_relation_size(indexrelname::regclass) desc;
```

This query outputs a list containing all indexes that have not been used since the stats were last reset and sorts
them by index size in descending order. More information on the meaning of the various columns can be found at
<https://www.postgresql.org/docs/16/monitoring-stats.html>.

For GitLab.com, you can check the latest generated [production reports](https://console.postgres.ai/gitlab/reports/)
on postgres.ai and inspect the `H002 Unused Indexes` file.

{{< alert type="warning" >}}

These reports only show indexes that have no recorded usage **since the last statistics reset.**
They do not guarantee that the indexes are never used.

{{< /alert >}}

### Verifying that an index is unused

This section contains resources to help you evaluate an index and confirm that it's safe to remove. Note that
this is only a suggested guide and is not exhaustive. Ultimately, the goal is to gather enough data to justify
dropping the index.

Be aware that certain factors can give the false impression that an index is unused, such as:

- There may be queries that run on GitLab Self-Managed but not on GitLab.com.
- The index may be used for very infrequent processes such as periodic cron jobs.
- On tables that have little data, PostgreSQL may initially prefer a sequential scan over an index scan
  until the table is large enough.

#### Investigating index usage

1. Start by gathering all the metadata available for the index, verifying its name and definition.
   - The index name in the development environment may not match production. It's important to correlate the indexes
    based on definition rather than name. To check its definition, you can:
      - Manually inspect [db/structure.sql](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/structure.sql)
         (This file does **not** include data on dynamically generated partitions.)
      - [Use Database Lab to check the status of an index.](database_lab.md#checking-indexes)
   - For partitioned tables, child indexes are often named differently than the parent index.
     To list all child indexes, you can:
      - Run `\d+ <PARENT_INDEX_NAME>` in [Database Lab](database_lab.md).
      - Run the following query to see the full parent-child index structure in more detail:

        ```sql
        SELECT
          parent_idx.relname AS parent_index,
          child_tbl.relname AS child_table,
          child_idx.relname AS child_index,
          dep.deptype,
          pg_get_indexdef(child_idx.oid) AS child_index_def
        FROM
          pg_class parent_idx
        JOIN pg_depend dep ON dep.refobjid = parent_idx.oid
        JOIN pg_class child_idx ON child_idx.oid = dep.objid
        JOIN pg_index i ON i.indexrelid = child_idx.oid
        JOIN pg_class child_tbl ON i.indrelid = child_tbl.oid
        WHERE
          parent_idx.relname = '<PARENT_INDEX_NAME>';
        ```

1. For GitLab.com, you can view index usage data in [Grafana](https://dashboards.gitlab.net/goto/TsYVxcBHR?orgId=1).
   - Query the metric `pg_stat_user_indexes_idx_scan` filtered by the relevant index(s) for at least the last 6 months.
     The query below shows index usage rate across all database instances combined.

     ```sql
     sum by (indexrelname) (rate(pg_stat_user_indexes_idx_scan{env="gprd", relname=~"<TABLE_NAME_REGEX>", indexrelname=~"<INDEX_NAME_REGEX>"}[30d]))
     ```

   - For partitioned tables, we must check that **all child indexes are unused** prior to dropping the parent.

If the data shows that an index has zero or negligible usage, it's a strong candidate for removal. However, keep in mind that
this is limited to usage on GitLab.com. We should still [investigate all related queries](#investigating-related-queries) to
ensure it can be safely removed for GitLab Self-Managed instances.

An index that shows low usage may still be dropped **if** we can confirm that other existing indexes would sufficiently
support the queries using it. PostgreSQL decides which index to use based on data distribution statistics, so in certain
situations it may slightly prefer one index over another even if both indexes adequately support the query, which may
account for the occasional usage.

#### Investigating related queries

The following are ways to find all queries that may utilize the index. It's important to understand the context in
which the queries are or may be executed so that we can determine if the index either:

- Has no queries on GitLab.com nor on GitLab Self-Managed that depend on it.
- Can be sufficiently supported by other existing indexes.

1. Investigate the origins of the index.
   - Dig through the commit history, related merge requests, and issues that introduced the index.
   - Try to find answers to questions such as:
      - Why was the index added in the first place? What query was it meant to support?
      - Does that query still exist and get executed?
      - Is it only applicable to GitLab Self-Managed instances?

1. Examine queries outputted from running the [`rspec:merge-auto-explain-logs`](https://gitlab.com/gitlab-org/gitlab/-/jobs/9805995367) CI job.
   - This job collects and analyzes queries executed through tests. The output is saved as an artifact: `auto_explain/auto_explain.ndjson.gz`
   - Since we don't always have 100% test coverage, this job may not capture all possible queries and variations.

1. Examine queries recorded in [postgres logs](https://log.gprd.gitlab.net/app/r/s/A55hK) on Kibana.
   - Generally, you can filter for `json.sql` values that contain the table name and key column(s) from the index definition. Example KQL:

     ```plaintext
     json.sql: <TABLE_NAME> AND json.sql: *<COLUMN_NAME>*
     ```

   - While there are many factors that affect index usage, the query's filtering and ordering clauses often have the most influence.
     A general guideline is to find queries whose conditions align with the index structure. For example, PostgreSQL is more likely
     to utilize a B-Tree index for queries that filter on the index's leading column(s) and satisfy its partial predicate (if any).
   - Caveat: We only keep the last 7 days of logs and this data does not apply to GitLab Self-Managed usage.

1. Manually search through the GitLab codebase.
   - This process may be tedious but it's the most reliable way to ensure there are no other queries we missed from the previous actions,
     especially ones that are infrequent or only apply to GitLab Self-Managed instances.
   - It's possible there are queries that were introduced some time after the index was initially added,
     so we can't always depend on the index origins; we must also examine the current state of the codebase.
   - To help direct your search, try to gather context about how the table is used and what features access it. Look for queries
     that involve key columns from the index definition, particularly those that are part of the filtering or ordering clauses.
   - Another approach is to conduct a keyword search for the model/table name and any relevant columns. However, this could be a
     trickier and long-winded process since some queries may be dynamically compiled from code across multiple files.

After collecting the relevant queries, you can then obtain [EXPLAIN plans](understanding_explain_plans.md) to help you assess if a query
relies on the index in question. For this process, it's necessary to have a good understanding of how indexes support queries and how
their usage is affected by data distribution changes. We recommend seeking guidance from a database domain expert to help with your assessment.

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

[Expression indexes](https://www.postgresql.org/docs/16/indexes-expressional.html),
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

{{< alert type="note" >}}

Async indexes are only supported for GitLab.com environments,
so `prepare_async_index` and `prepare_partitioned_async_index` are no-ops for other environments.

{{< /alert >}}

{{< alert type="note" >}}

`prepare_partitioned_async_index` only creates the indexes for partitions asynchronously. It doesn't attach the partition indexes to the partitioned table.
In the [next step for the partitioned table](#create-the-index-synchronously-for-partitioned-table), `add_concurrent_partitioned_index` will not only add the index synchronously but also attach the partition indexes to the partitioned table.

{{< /alert >}}

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

{{< alert type="warning" >}}

Verify that the index exists in production before merging a second migration with `add_concurrent_index`.
If the second migration is deployed before the index has been created,
the index is created synchronously when the second migration executes.

{{< /alert >}}

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
1. To verify the index, open the PostgreSQL console using the [GDK](https://gitlab-org.gitlab.io/gitlab-development-kit/howto/postgresql/) command `gdk psql` and run the command `\d <index_name>` to check that your newly created index exists.
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

{{< alert type="warning" >}}

Verify that the index no longer exists in production before merging a second migration with `remove_concurrent_index_by_name`.
If the second migration is deployed before the index has been destroyed,
the index is destroyed synchronously when the second migration executes.

{{< /alert >}}

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
1. To verify the index, open the PostgreSQL console by using the [GDK](https://gitlab-org.gitlab.io/gitlab-development-kit/howto/postgresql/)
   command `gdk psql` and run `\d <index_name>` to check that the destroyed index no longer exists.
