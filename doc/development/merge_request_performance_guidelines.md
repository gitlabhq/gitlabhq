---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Merge Request Performance Guidelines

Each new introduced merge request **should be performant by default**.

To ensure a merge request does not negatively impact performance of GitLab
_every_ merge request **should** adhere to the guidelines outlined in this
document. There are no exceptions to this rule unless specifically discussed
with and agreed upon by backend maintainers and performance specialists.

To measure the impact of a merge request you can use
[Sherlock](profiling.md#sherlock). It's also highly recommended that you read
the following guides:

- [Performance Guidelines](performance.md)
- [Avoiding downtime in migrations](avoiding_downtime_in_migrations.md)

## Definition

The term `SHOULD` per the [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt) means:

> This word, or the adjective "RECOMMENDED", mean that there
> may exist valid reasons in particular circumstances to ignore a
> particular item, but the full implications must be understood and
> carefully weighed before choosing a different course.

Ideally, each of these tradeoffs should be documented
in the separate issues, labeled accordingly and linked
to original issue and epic.

## Impact Analysis

**Summary:** think about the impact your merge request may have on performance
and those maintaining a GitLab setup.

Any change submitted can have an impact not only on the application itself but
also those maintaining it and those keeping it up and running (for example, production
engineers). As a result you should think carefully about the impact of your
merge request on not only the application but also on the people keeping it up
and running.

Can the queries used potentially take down any critical services and result in
engineers being woken up in the night? Can a malicious user abuse the code to
take down a GitLab instance? Do my changes simply make loading a certain page
slower? Does execution time grow exponentially given enough load or data in the
database?

These are all questions one should ask themselves before submitting a merge
request. It may sometimes be difficult to assess the impact, in which case you
should ask a performance specialist to review your code. See the "Reviewing"
section below for more information.

## Performance Review

**Summary:** ask performance specialists to review your code if you're not sure
about the impact.

Sometimes it's hard to assess the impact of a merge request. In this case you
should ask one of the merge request reviewers to review your changes. You can
find a list of these reviewers at <https://about.gitlab.com/company/team/>. A reviewer
in turn can request a performance specialist to review the changes.

## Think outside of the box

Everyone has their own perception of how to use the new feature.
Always consider how users might be using the feature instead. Usually,
users test our features in a very unconventional way,
like by brute forcing or abusing edge conditions that we have.

## Data set

The data set the merge request processes should be known
and documented. The feature should clearly document what the expected
data set is for this feature to process, and what problems it might cause.

If you would think about the following example that puts
a strong emphasis of data set being processed.
The problem is simple: you want to filter a list of files from
some Git repository. Your feature requests a list of all files
from the repository and perform search for the set of files.
As an author you should in context of that problem consider
the following:

1. What repositories are planned to be supported?
1. How long it do big repositories like Linux kernel take?
1. Is there something that we can do differently to not process such a
   big data set?
1. Should we build some fail-safe mechanism to contain
   computational complexity? Usually it's better to degrade
   the service for a single user instead of all users.

## Query plans and database structure

The query plan can tell us if we need additional
indexes, or expensive filtering (such as using sequential scans).

Each query plan should be run against substantial size of data set.
For example, if you look for issues with specific conditions,
you should consider validating a query against
a small number (a few hundred) and a big number (100_000) of issues.
See how the query behaves if the result is a few
and a few thousand.

This is needed as we have users using GitLab for very big projects and
in a very unconventional way. Even if it seems that it's unlikely
that such a big data set is used, it's still plausible that one
of our customers could encounter a problem with the feature.

Understanding ahead of time how it behaves at scale, even if we accept it,
is the desired outcome. We should always have a plan or understanding of what is needed
to optimize the feature for higher usage patterns.

Every database structure should be optimized and sometimes even over-described
in preparation for easy extension. The hardest part after some point is
data migration. Migrating millions of rows is always troublesome and
can have a negative impact on the application.

To better understand how to get help with the query plan reviews
read this section on [how to prepare the merge request for a database review](database_review.md#how-to-prepare-the-merge-request-for-a-database-review).

## Query Counts

**Summary:** a merge request **should not** increase the total number of executed SQL
queries unless absolutely necessary.

The total number of queries executed by the code modified or added by a merge request
must not increase unless absolutely necessary. When building features it's
entirely possible you need some extra queries, but you should try to keep
this at a minimum.

As an example, say you introduce a feature that updates a number of database
rows with the same value. It may be very tempting (and easy) to write this using
the following pseudo code:

```ruby
objects_to_update.each do |object|
  object.some_field = some_value
  object.save
end
```

This means running one query for every object to update. This code can
easily overload a database given enough rows to update or many instances of this
code running in parallel. This particular problem is known as the
["N+1 query problem"](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations). You can write a test with [QueryRecorder](query_recorder.md) to detect this and prevent regressions.

In this particular case the workaround is fairly easy:

```ruby
objects_to_update.update_all(some_field: some_value)
```

This uses ActiveRecord's `update_all` method to update all rows in a single
query. This in turn makes it much harder for this code to overload a database.

## Use read replicas when possible

In a DB cluster we have many read replicas and one primary. A classic use of scaling the DB is to have read-only actions be performed by the replicas. We use [load balancing](../administration/database_load_balancing.md) to distribute this load. This allows for the replicas to grow as the pressure on the DB grows.

By default, queries use read-only replicas, but due to
[primary sticking](../administration/database_load_balancing.md#primary-sticking), GitLab uses the
primary for some time and reverts to secondaries after they have either caught up or after 30 seconds.
Doing this can lead to a considerable amount of unnecessary load on the primary.
To prevent switching to the primary [merge request 56849](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56849) introduced the
`without_sticky_writes` block. Typically, this method can be applied to prevent primary stickiness
after a trivial or insignificant write which doesn't affect the following queries in the same session.

To learn when a usage timestamp update can lead the session to stick to the primary and how to
prevent it by using `without_sticky_writes`, see [merge request 57328](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57328)

As a counterpart of the `without_sticky_writes` utility,
[merge request 59167](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59167) introduced
`use_replicas_for_read_queries`. This method forces all read-only queries inside its block to read
replicas regardless of the current primary stickiness.
This utility is reserved for cases where queries can tolerate replication lag.

Internally, our database load balancer classifies the queries based on their main statement (`select`, `update`, `delete`, etc.). When in doubt, it redirects the queries to the primary database. Hence, there are some common cases the load balancer sends the queries to the primary unnecessarily:

- Custom queries (via `exec_query`, `execute_statement`, `execute`, etc.)
- Read-only transactions
- In-flight connection configuration set
- Sidekiq background jobs

After the above queries are executed, GitLab
[sticks to the primary](../administration/database_load_balancing.md#primary-sticking).
To make the inside queries prefer using the replicas,
[merge request 59086](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59086) introduced
`fallback_to_replicas_for_ambiguous_queries`. This MR is also an example of how we redirected a
costly, time-consuming query to the replicas.

## Use CTEs wisely

Read about [complex queries on the relation object](iterating_tables_in_batches.md#complex-queries-on-the-relation-object) for considerations on how to use CTEs. We have found in some situations that CTEs can become problematic in use (similar to the n+1 problem above). In particular, hierarchical recursive CTE queries such as the CTE in [AuthorizedProjectsWorker](https://gitlab.com/gitlab-org/gitlab/-/issues/325688) are very difficult to optimize and don't scale. We should avoid them when implementing new features that require any kind of hierarchical structure.

CTEs have been effectively used as an optimization fence in many simpler cases, 
such as this [example](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/43242#note_61416277).
Beginning in PostgreSQL 12, CTEs are inlined then [optimized by default](https://paquier.xyz/postgresql-2/postgres-12-with-materialize/).
Keeping the old behavior requires marking CTEs with the keyword `MATERIALIZED`.

When building CTE statements, use the `Gitlab::SQL::CTE` class [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56976) in GitLab 13.11.
By default, this `Gitlab::SQL::CTE` class forces materialization through adding the `MATERIALIZED` keyword for PostgreSQL 12 and higher.
`Gitlab::SQL::CTE` automatically omits materialization when PostgreSQL 11 is running
(this behavior is implemented using a custom arel node `Gitlab::Database::AsWithMaterialized` under the surface).

WARNING:
We plan to drop the support for PostgreSQL 11. Upgrading to GitLab 14.0 requires PostgreSQL 12 or higher.

## Cached Queries

**Summary:** a merge request **should not** execute duplicated cached queries.

Rails provides an [SQL Query Cache](cached_queries.md#cached-queries-guidelines),
used to cache the results of database queries for the duration of the request.

See [why cached queries are considered bad](cached_queries.md#why-cached-queries-are-considered-bad) and
[how to detect them](cached_queries.md#how-to-detect-cached-queries).

The code introduced by a merge request, should not execute multiple duplicated cached queries.

The total number of the queries (including cached ones) executed by the code modified or added by a merge request
should not increase unless absolutely necessary.
The number of executed queries (including cached queries) should not depend on
collection size.
You can write a test by passing the `skip_cached` variable to [QueryRecorder](query_recorder.md) to detect this and prevent regressions.

As an example, say you have a CI pipeline. All pipeline builds belong to the same pipeline,
thus they also belong to the same project (`pipeline.project`):

```ruby
pipeline_project = pipeline.project
# Project Load (0.6ms)  SELECT "projects".* FROM "projects" WHERE "projects"."id" = $1 LIMIT $2
build = pipeline.builds.first

build.project == pipeline_project
# CACHE Project Load (0.0ms)  SELECT "projects".* FROM "projects" WHERE "projects"."id" = $1 LIMIT $2
# => true
```

When we call `build.project`, it doesn't hit the database, it uses the cached result, but it re-instantiates
the same pipeline project object. It turns out that associated objects do not point to the same in-memory object.

If we try to serialize each build:

```ruby
pipeline.builds.each do |build|
  build.to_json(only: [:name], include: [project: { only: [:name]}])
end
```

It re-instantiates project object for each build, instead of using the same in-memory object.

In this particular case the workaround is fairly easy:

```ruby
pipeline.builds.each do |build|
  build.project = pipeline.project
  build.to_json(only: [:name], include: [project: { only: [:name]}])
end
```

We can assign `pipeline.project` to each `build.project`, since we know it should point to the same project.
This allows us that each build point to the same in-memory project,
avoiding the cached SQL query and re-instantiation of the project object for each build.

## Executing Queries in Loops

**Summary:** SQL queries **must not** be executed in a loop unless absolutely
necessary.

Executing SQL queries in a loop can result in many queries being executed
depending on the number of iterations in a loop. This may work fine for a
development environment with little data, but in a production environment this
can quickly spiral out of control.

There are some cases where this may be needed. If this is the case this should
be clearly mentioned in the merge request description.

## Batch process

**Summary:** Iterating a single process to external services (for example, PostgreSQL, Redis, Object Storage)
should be executed in a **batch-style** in order to reduce connection overheads.

For fetching rows from various tables in a batch-style, please see [Eager Loading](#eager-loading) section.

### Example: Delete multiple files from Object Storage

When you delete multiple files from object storage, like GCS,
executing a single REST API call multiple times is a quite expensive
process. Ideally, this should be done in a batch-style, for example, S3 provides
[batch deletion API](https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjects.html),
so it'd be a good idea to consider such an approach.

The `FastDestroyAll` module might help this situation. It's a
small framework when you remove a bunch of database rows and its associated data
in a batch style.

## Timeout

**Summary:** You should set a reasonable timeout when the system invokes HTTP calls
to external services (such as Kubernetes), and it should be executed in Sidekiq, not
in Puma threads.

Often, GitLab needs to communicate with an external service such as Kubernetes
clusters. In this case, it's hard to estimate when the external service finishes
the requested process, for example, if it's a user-owned cluster that's inactive for some reason,
GitLab might wait for the response forever ([Example](https://gitlab.com/gitlab-org/gitlab/-/issues/31475)).
This could result in Puma timeout and should be avoided at all cost.

You should set a reasonable timeout, gracefully handle exceptions and surface the
errors in UI or logging internally.

Using [`ReactiveCaching`](utilities.md#reactivecaching) is one of the best solutions to fetch external data.

## Keep database transaction minimal

**Summary:** You should avoid accessing to external services like Gitaly during database
transactions, otherwise it leads to severe contention problems
as an open transaction basically blocks the release of a PostgreSQL backend connection.

For keeping transaction as minimal as possible, please consider using `AfterCommitQueue`
module or `after_commit` AR hook.

Here is [an example](https://gitlab.com/gitlab-org/gitlab/-/issues/36154#note_247228859)
that one request to Gitaly instance during transaction triggered a ~"priority::1" issue.

## Eager Loading

**Summary:** always eager load associations when retrieving more than one row.

When retrieving multiple database records for which you need to use any
associations you **must** eager load these associations. For example, if you're
retrieving a list of blog posts and you want to display their authors you
**must** eager load the author associations.

In other words, instead of this:

```ruby
Post.all.each do |post|
  puts post.author.name
end
```

You should use this:

```ruby
Post.all.includes(:author).each do |post|
  puts post.author.name
end
```

Also consider using [QueryRecoder tests](query_recorder.md) to prevent a regression when eager loading.

## Memory Usage

**Summary:** merge requests **must not** increase memory usage unless absolutely
necessary.

A merge request must not increase the memory usage of GitLab by more than the
absolute bare minimum required by the code. This means that if you have to parse
some large document (for example, an HTML document) it's best to parse it as a stream
whenever possible, instead of loading the entire input into memory. Sometimes
this isn't possible, in that case this should be stated explicitly in the merge
request.

## Lazy Rendering of UI Elements

**Summary:** only render UI elements when they are actually needed.

Certain UI elements may not always be needed. For example, when hovering over a
diff line there's a small icon displayed that can be used to create a new
comment. Instead of always rendering these kind of elements they should only be
rendered when actually needed. This ensures we don't spend time generating
Haml/HTML when it's not used.

## Instrumenting New Code

**Summary:** always add instrumentation for new classes, modules, and methods.

Newly added classes, modules, and methods must be instrumented. This ensures
we can track the performance of this code over time.

For more information see [Instrumentation](instrumentation.md). This guide
describes how to add instrumentation and where to add it.

## Use of Caching

**Summary:** cache data in memory or in Redis when it's needed multiple times in
a transaction or has to be kept around for a certain time period.

Sometimes certain bits of data have to be re-used in different places during a
transaction. In these cases this data should be cached in memory to remove the
need for running complex operations to fetch the data. You should use Redis if
data should be cached for a certain time period instead of the duration of the
transaction.

For example, say you process multiple snippets of text containing username
mentions (for example, `Hello @alice` and `How are you doing @alice?`). By caching the
user objects for every username we can remove the need for running the same
query for every mention of `@alice`.

Caching data per transaction can be done using
[RequestStore](https://github.com/steveklabnik/request_store) (use
`Gitlab::SafeRequestStore` to avoid having to remember to check
`RequestStore.active?`). Caching data in Redis can be done using [Rails' caching
system](https://guides.rubyonrails.org/caching_with_rails.html).

## Pagination

Each feature that renders a list of items as a table needs to include pagination.

The main styles of pagination are:

1. Offset-based pagination: user goes to a specific page, like 1. User sees the next page number,
   and the total number of pages. This style is well supported by all components of GitLab.
1. Offset-based pagination, but without the count: user goes to a specific page, like 1.
   User sees only the next page number, but does not see the total amount of pages.
1. Next page using keyset-based pagination: user can only go to next page, as we don't know how many pages
   are available.
1. Infinite scrolling pagination: user scrolls the page and next items are loaded asynchronously. This is ideal,
   as it has exact same benefits as the previous one.

The ultimately scalable solution for pagination is to use Keyset-based pagination.
However, we don't have support for that at GitLab at that moment. You
can follow the progress looking at [API: Keyset Pagination
](https://gitlab.com/groups/gitlab-org/-/epics/2039).

Take into consideration the following when choosing a pagination strategy:

1. It's very inefficient to calculate amount of objects that pass the filtering,
   this operation usually can take seconds, and can time out,
1. It's very inefficient to get entries for page at higher ordinals, like 1000.
   The database has to sort and iterate all previous items, and this operation usually
   can result in substantial load put on database.

You can find useful tips related to pagination in the [pagination guidelines](database/pagination_guidelines.md).

## Badge counters

Counters should always be truncated. It means that we don't want to present
the exact number over some threshold. The reason for that is for the cases where we want
to calculate exact number of items, we effectively need to filter each of them for
the purpose of knowing the exact number of items matching.

From ~UX perspective it's often acceptable to see that you have over 1000+ pipelines,
instead of that you have 40000+ pipelines, but at a tradeoff of loading page for 2s longer.

An example of this pattern is the list of pipelines and jobs. We truncate numbers to `1000+`,
but we show an accurate number of running pipelines, which is the most interesting information.

There's a helper method that can be used for that purpose - `NumbersHelper.limited_counter_with_delimiter` -
that accepts an upper limit of counting rows.

In some cases it's desired that badge counters are loaded asynchronously.
This can speed up the initial page load and give a better user experience overall.

## Application/misuse limits

Every new feature should have safe usage quotas introduced.
The quota should be optimised to a level that we consider the feature to
be performant and usable for the user, but **not limiting**.

**We want the features to be fully usable for the users.**
**However, we want to ensure that the feature continues to perform well if used at its limit**
**and it doesn't cause availability issues.**

Consider that it's always better to start with some kind of limitation,
instead of later introducing a breaking change that would result in some
workflows breaking.

The intent is to provide a safe usage pattern for the feature,
as our implementation decisions are optimised for the given data set.
Our feature limits should reflect the optimisations that we introduced.

The intent of quotas could be different:

1. We want to provide higher quotas for higher tiers of features:
   we want to provide on GitLab.com more capabilities for different tiers,
1. We want to prevent misuse of the feature: someone accidentally creates
   10000 deploy tokens, because of a broken API script,
1. We want to prevent abuse of the feature: someone purposely creates
   a 10000 pipelines to take advantage of the system.

Examples:

1. Pipeline Schedules: It's very unlikely that user wants to create
   more than 50 schedules.
   In such cases it's rather expected that this is either misuse
   or abuse of the feature. Lack of the upper limit can result
   in service degradation as the system tries to process all schedules
   assigned the project.

1. GitLab CI/CD includes: We started with the limit of maximum of 50 nested includes.
   We understood that performance of the feature was acceptable at that level.
   We received a request from the community that the limit is too small.
   We had a time to understand the customer requirement, and implement an additional
   fail-safe mechanism (time-based one) to increase the limit 100, and if needed increase it
   further without negative impact on availability of the feature and GitLab.

## Usage of feature flags

Each feature that has performance critical elements or has a known performance deficiency
needs to come with feature flag to disable it.

The feature flag makes our team more happy, because they can monitor the system and
quickly react without our users noticing the problem.

Performance deficiencies should be addressed right away after we merge initial
changes.

Read more about when and how feature flags should be used in
[Feature flags in GitLab development](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#feature-flags-in-gitlab-development).

## Storage

We can consider the following types of storages:

- **Local temporary storage** (very-very short-term storage) This type of storage is system-provided storage, ex. `/tmp` folder.
  This is the type of storage that you should ideally use for all your temporary tasks.
  The fact that each node has its own temporary storage makes scaling significantly easier.
  This storage is also very often SSD-based, thus is significantly faster.
  The local storage can easily be configured for the application with
  the usage of `TMPDIR` variable.

- **Shared temporary storage** (short-term storage) This type of storage is network-based temporary storage,
  usually run with a common NFS server. As of Feb 2020, we still use this type of storage
  for most of our implementations. Even though this allows the above limit to be significantly larger,
  it does not really mean that you can use more. The shared temporary storage is shared by
  all nodes. Thus, the job that uses significant amount of that space or performs a lot
  of operations creates a contention on execution of all other jobs and request
  across the whole application, this can easily impact stability of the whole GitLab.
  Be respectful of that.

- **Shared persistent storage** (long-term storage) This type of storage uses
  shared network-based storage (ex. NFS). This solution is mostly used by customers running small
  installations consisting of a few nodes. The files on shared storage are easily accessible,
  but any job that is uploading or downloading data can create a serious contention to all other jobs.
  This is also an approach by default used by Omnibus.

- **Object-based persistent storage** (long term storage) this type of storage uses external
  services like [AWS S3](https://en.wikipedia.org/wiki/Amazon_S3). The Object Storage
  can be treated as infinitely scalable and redundant. Accessing this storage usually requires
  downloading the file in order to manipulate it. The Object Storage can be considered as an ultimate
  solution, as by definition it can be assumed that it can handle unlimited concurrent uploads
  and downloads of files. This is also ultimate solution required to ensure that application can
  run in containerized deployments (Kubernetes) at ease.

### Temporary storage

The storage on production nodes is really sparse. The application should be built
in a way that accommodates running under very limited temporary storage.
You can expect the system on which your code runs has a total of `1G-10G`
of temporary storage. However, this storage is really shared across all
jobs being run. If your job requires to use more than `100MB` of that space
you should reconsider the approach you have taken.

Whatever your needs are, you should clearly document if you need to process files.
If you require more than `100MB`, consider asking for help from a maintainer
to work with you to possibly discover a better solution.

#### Local temporary storage

The usage of local storage is a desired solution to use,
especially since we work on deploying applications to Kubernetes clusters.
When you would like to use `Dir.mktmpdir`? In a case when you want for example
to extract/create archives, perform extensive manipulation of existing data, etc.

```ruby
Dir.mktmpdir('designs') do |path|
  # do manipulation on path
  # the path will be removed once
  # we go out of the block
end
```

#### Shared temporary storage

The usage of shared temporary storage is required if your intent
is to persistent file for a disk-based storage, and not Object Storage.
[Workhorse direct_upload](uploads.md#direct-upload) when accepting file
can write it to shared storage, and later GitLab Rails can perform a move operation.
The move operation on the same destination is instantaneous.
The system instead of performing `copy` operation just re-attaches file into a new place.

Since this introduces extra complexity into application, you should only try
to re-use well established patterns (ex.: `ObjectStorage` concern) instead of re-implementing it.

The usage of shared temporary storage is otherwise deprecated for all other usages.

### Persistent storage

#### Object Storage

It is required that all features holding persistent files support saving data
to Object Storage. Having a persistent storage in the form of shared volume across nodes
is not scalable, as it creates a contention on data access all nodes.

GitLab offers the [ObjectStorage concern](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/uploaders/object_storage.rb)
that implements a seamless support for Shared and Object Storage-based persistent storage.

#### Data access

Each feature that accepts data uploads or allows to download them needs to use
[Workhorse direct_upload](uploads.md#direct-upload). It means that uploads needs to be
saved directly to Object Storage by Workhorse, and all downloads needs to be served
by Workhorse.

Performing uploads/downloads via Puma is an expensive operation,
as it blocks the whole processing slot (thread) for the duration of the upload.

Performing uploads/downloads via Puma also has a problem where the operation
can time out, which is especially problematic for slow clients. If clients take a long time
to upload/download the processing slot might be killed due to request processing
timeout (usually between 30s-60s).

For the above reasons it is required that [Workhorse direct_upload](uploads.md#direct-upload) is implemented
for all file uploads and downloads.
