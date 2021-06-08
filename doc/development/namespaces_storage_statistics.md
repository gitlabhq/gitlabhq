---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Database case study: Namespaces storage statistics

## Introduction

On [Storage and limits management for groups](https://gitlab.com/groups/gitlab-org/-/epics/886),
we want to facilitate a method for easily viewing the amount of
storage consumed by a group, and allow easy management.

## Proposal

1. Create a new ActiveRecord model to hold the namespaces' statistics in an aggregated form (only for root namespaces).
1. Refresh the statistics in this model every time a project belonging to this namespace is changed.

## Problem

In GitLab, we update the project storage statistics through a
[callback](https://gitlab.com/gitlab-org/gitlab/-/blob/4ab54c2233e91f60a80e5b6fa2181e6899fdcc3e/app/models/project.rb#L97)
every time the project is saved.

The summary of those statistics per namespace is then retrieved
by [`Namespaces#with_statistics`](https://gitlab.com/gitlab-org/gitlab/-/blob/4ab54c2233e91f60a80e5b6fa2181e6899fdcc3e/app/models/namespace.rb#L70) scope. Analyzing this query we noticed that:

- It takes up to `1.2` seconds for namespaces with over `15k` projects.
- It can't be analyzed with [ChatOps](chatops_on_gitlabcom.md), as it times out.

Additionally, the pattern that is currently used to update the project statistics
(the callback) doesn't scale adequately. It is currently one of the largest
[database queries transactions on production](https://gitlab.com/gitlab-org/gitlab/-/issues/29070)
that takes the most time overall. We can't add one more query to it as
it increases the transaction's length.

Because of all of the above, we can't apply the same pattern to store
and update the namespaces statistics, as the `namespaces` table is one
of the largest tables on GitLab.com. Therefore we needed to find a performant and
alternative method.

## Attempts

### Attempt A: PostgreSQL materialized view

Model can be updated through a refresh strategy based on a project routes SQL and a [materialized view](https://www.postgresql.org/docs/11/rules-materializedviews.html):

```sql
SELECT split_part("rs".path, '/', 1) as root_path,
        COALESCE(SUM(ps.storage_size), 0) AS storage_size,
        COALESCE(SUM(ps.repository_size), 0) AS repository_size,
        COALESCE(SUM(ps.wiki_size), 0) AS wiki_size,
        COALESCE(SUM(ps.lfs_objects_size), 0) AS lfs_objects_size,
        COALESCE(SUM(ps.build_artifacts_size), 0) AS build_artifacts_size,
        COALESCE(SUM(ps.packages_size), 0) AS packages_size
FROM "projects"
    INNER JOIN routes rs ON rs.source_id = projects.id AND rs.source_type = 'Project'
    INNER JOIN project_statistics ps ON ps.project_id  = projects.id
GROUP BY root_path
```

We could then execute the query with:

```sql
REFRESH MATERIALIZED VIEW root_namespace_storage_statistics;
```

While this implied a single query update (and probably a fast one), it has some downsides:

- Materialized views syntax varies from PostgreSQL and MySQL. While this feature was worked on, MySQL was still supported by GitLab.
- Rails does not have native support for materialized views. We'd need to use a specialized gem to take care of the management of the database views, which implies additional work.

### Attempt B: An update through a CTE

Similar to Attempt A: Model update done through a refresh strategy with a [Common Table Expression](https://www.postgresql.org/docs/9.1/queries-with.html)

```sql
WITH refresh AS (
  SELECT split_part("rs".path, '/', 1) as root_path,
        COALESCE(SUM(ps.storage_size), 0) AS storage_size,
        COALESCE(SUM(ps.repository_size), 0) AS repository_size,
        COALESCE(SUM(ps.wiki_size), 0) AS wiki_size,
        COALESCE(SUM(ps.lfs_objects_size), 0) AS lfs_objects_size,
        COALESCE(SUM(ps.build_artifacts_size), 0) AS build_artifacts_size,
        COALESCE(SUM(ps.packages_size), 0) AS packages_size
  FROM "projects"
        INNER JOIN routes rs ON rs.source_id = projects.id AND rs.source_type = 'Project'
        INNER JOIN project_statistics ps ON ps.project_id  = projects.id
  GROUP BY root_path)
UPDATE namespace_storage_statistics
SET storage_size = refresh.storage_size,
    repository_size = refresh.repository_size,
    wiki_size = refresh.wiki_size,
    lfs_objects_size = refresh.lfs_objects_size,
    build_artifacts_size = refresh.build_artifacts_size,
    packages_size  = refresh.packages_size
FROM refresh
    INNER JOIN routes rs ON rs.path = refresh.root_path AND rs.source_type = 'Namespace'
WHERE namespace_storage_statistics.namespace_id = rs.source_id
```

Same benefits and downsides as attempt A.

### Attempt C: Get rid of the model and store the statistics on Redis

We could get rid of the model that stores the statistics in aggregated form and instead use a Redis Set.
This would be the [boring solution](https://about.gitlab.com/handbook/values/#boring-solutions) and the fastest one
to implement, as GitLab already includes Redis as part of its [Architecture](architecture.md#redis).

The downside of this approach is that Redis does not provide the same persistence/consistency guarantees as PostgreSQL,
and this is information we can't afford to lose in a Redis failure.

### Attempt D: Tag the root namespace and its child namespaces

Directly relate the root namespace to its child namespaces, so
whenever a namespace is created without a parent, this one is tagged
with the root namespace ID:

| ID | root ID | parent ID |
|:---|:--------|:----------|
| 1  | 1       | NULL      |
| 2  | 1       | 1         |
| 3  | 1       | 2         |

To aggregate the statistics inside a namespace we'd execute something like:

```sql
SELECT COUNT(...)
FROM projects
WHERE namespace_id IN (
  SELECT id
  FROM namespaces
  WHERE root_id = X
)
```

Even though this approach would make aggregating much easier, it has some major downsides:

- We'd have to migrate **all namespaces** by adding and filling a new column. Because of the size of the table, dealing with time/cost would be significant. The background migration would take approximately `153h`, see <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/29772>.
- Background migration has to be shipped one release before, delaying the functionality by another milestone.

### Attempt E (final): Update the namespace storage statistics asynchronously

This approach consists of continuing to use the incremental statistics updates we already have,
but we refresh them through Sidekiq jobs and in different transactions:

1. Create a second table (`namespace_aggregation_schedules`) with two columns `id` and `namespace_id`.
1. Whenever the statistics of a project changes, insert a row into `namespace_aggregation_schedules`
   - We don't insert a new row if there's already one related to the root namespace.
   - Keeping in mind the length of the transaction that involves updating `project_statistics`(<https://gitlab.com/gitlab-org/gitlab/-/issues/29070>), the insertion should be done in a different transaction and through a Sidekiq Job.
1. After inserting the row, we schedule another worker to be executed asynchronously at two different moments:
   - One enqueued for immediate execution and another one scheduled in `1.5h` hours.
   - We only schedule the jobs, if we can obtain a `1.5h` lease on Redis on a key based on the root namespace ID.
   - If we can't obtain the lease, it indicates there's another aggregation already in progress, or scheduled in no more than `1.5h`.
1. This worker will:
   - Update the root namespace storage statistics by querying all the namespaces through a service.
   - Delete the related `namespace_aggregation_schedules` after the update.
1. Another Sidekiq job is also included to traverse any remaining rows on the `namespace_aggregation_schedules` table and schedule jobs for every pending row.
   - This job is scheduled with cron to run every night (UTC).

This implementation has the following benefits:

- All the updates are done asynchronously, so we're not increasing the length of the transactions for `project_statistics`.
- We're doing the update in a single SQL query.
- It is compatible with PostgreSQL and MySQL.
- No background migration required.

The only downside of this approach is that namespaces' statistics are updated up to `1.5` hours after the change is done,
which means there's a time window in which the statistics are inaccurate. Because we're still not
[enforcing storage limits](https://gitlab.com/gitlab-org/gitlab/-/issues/17664), this is not a major problem.

## Conclusion

Updating the storage statistics asynchronously, was the less problematic and
performant approach of aggregating the root namespaces.

All the details regarding this use case can be found on:

- <https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62214>
- Merge Request with the implementation: <https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/28996>

Performance of the namespace storage statistics were measured in staging and production (GitLab.com). All results were posted
on <https://gitlab.com/gitlab-org/gitlab-foss/-/issues/64092>: No problem has been reported so far.
