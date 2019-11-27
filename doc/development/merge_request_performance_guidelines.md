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
- [What requires downtime?](what_requires_downtime.md)

## Definition

The term `SHOULD` per the [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt) means:

> This word, or the adjective "RECOMMENDED", mean that there
> may exist valid reasons in particular circumstances to ignore a
> particular item, but the full implications must be understood and
> carefully weighed before choosing a different course.

Ideally, each of these tradeoffs should be documented
in the separate issues, labelled accordingly and linked
to original issue and epic.

## Impact Analysis

**Summary:** think about the impact your merge request may have on performance
and those maintaining a GitLab setup.

Any change submitted can have an impact not only on the application itself but
also those maintaining it and those keeping it up and running (e.g. production
engineers). As a result you should think carefully about the impact of your
merge request on not only the application but also on the people keeping it up
and running.

Can the queries used potentially take down any critical services and result in
engineers being woken up in the night? Can a malicious user abuse the code to
take down a GitLab instance? Will my changes simply make loading a certain page
slower? Will execution time grow exponentially given enough load or data in the
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

Everyone has their own perception how the new feature is going to be used.
Always consider how users might be using the feature instead. Usually,
users test our features in a very unconventional way,
like by brute forcing or abusing edge conditions that we have.

## Data set

The data set that will be processed by the merge request should be known
and documented. The feature should clearly document what the expected
data set is for this feature to process, and what problems it might cause.

If you would think about the following example that puts
a strong emphasis of data set being processed.
The problem is simple: you want to filter a list of files from
some Git repository. Your feature requests a list of all files
from the repository and perform search for the set of files.
As an author you should in context of that problem consider
the following:

1. What repositories are going to be supported?
1. How long it will take for big repositories like Linux kernel?
1. Is there something that we can do differently to not process such a
   big data set?
1. Should we build some fail-safe mechanism to contain
   computational complexity? Usually it is better to degrade
   the service for a single user instead of all users.

## Query plans and database structure

The query plan can answer the questions whether we need additional
indexes, or whether we perform expensive filtering (i.e. using sequential scans).

Each query plan should be run against substantional size of data set.
For example if you look for issues with specific conditions,
you should consider validating the query against
a small number (a few hundred) and a big number (100_000) of issues.
See how the query will behave if the result will be a few
and a few thousand.

This is needed as we have users using GitLab for very big projects and
in a very unconventional way. Even, if it seems that it is unlikely
that such big data set will be used, it is still plausible that one
of our customers will have the problem with the feature.

Understanding ahead of time how it is going to behave at scale even if we accept it,
is the desired outcome. We should always have a plan or understanding what it takes
to optimise feature to the magnitude of higher usage patterns.

Every database structure should be optimised and sometimes even over-described
to be prepared to be easily extended. The hardest part after some point is
data migration. Migrating millions of rows will always be troublesome and
can have negative impact on application.

To better understand how to get help with the query plan reviews
read this section on [how to prepare the merge request for a database review](https://docs.gitlab.com/ee/development/database_review.html#how-to-prepare-the-merge-request-for-a-database-review).

## Query Counts

**Summary:** a merge request **should not** increase the number of executed SQL
queries unless absolutely necessary.

The number of queries executed by the code modified or added by a merge request
must not increase unless absolutely necessary. When building features it's
entirely possible you will need some extra queries, but you should try to keep
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

This will end up running one query for every object to update. This code can
easily overload a database given enough rows to update or many instances of this
code running in parallel. This particular problem is known as the
["N+1 query problem"](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations). You can write a test with [QueryRecoder](query_recorder.md) to detect this and prevent regressions.

In this particular case the workaround is fairly easy:

```ruby
objects_to_update.update_all(some_field: some_value)
```

This uses ActiveRecord's `update_all` method to update all rows in a single
query. This in turn makes it much harder for this code to overload a database.

## Executing Queries in Loops

**Summary:** SQL queries **must not** be executed in a loop unless absolutely
necessary.

Executing SQL queries in a loop can result in many queries being executed
depending on the number of iterations in a loop. This may work fine for a
development environment with little data, but in a production environment this
can quickly spiral out of control.

There are some cases where this may be needed. If this is the case this should
be clearly mentioned in the merge request description.

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
some large document (e.g. an HTML document) it's best to parse it as a stream
whenever possible, instead of loading the entire input into memory. Sometimes
this isn't possible, in that case this should be stated explicitly in the merge
request.

## Lazy Rendering of UI Elements

**Summary:** only render UI elements when they're actually needed.

Certain UI elements may not always be needed. For example, when hovering over a
diff line there's a small icon displayed that can be used to create a new
comment. Instead of always rendering these kind of elements they should only be
rendered when actually needed. This ensures we don't spend time generating
Haml/HTML when it's not going to be used.

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
mentions (e.g. `Hello @alice` and `How are you doing @alice?`). By caching the
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
1. Next page using keyset-based pagination: user can only go to next page, as we do not know how many pages
   are available.
1. Infinite scrolling pagination: user scrolls the page and next items are loaded asynchronously. This is ideal,
   as it has exact same benefits as the previous one.

The ultimately scalable solution for pagination is to use Keyset-based pagination.
However, we don't have support for that at GitLab at that moment. You
can follow the progress looking at [API: Keyset Pagination
](https://gitlab.com/groups/gitlab-org/-/epics/2039).

Take into consideration the following when choosing a pagination strategy:

1. It is very inefficient to calculate amount of objects that pass the filtering,
   this operation usually can take seconds, and can time out,
1. It is very inefficent to get entries for page at higher ordinals, like 1000.
   The database has to sort and iterate all previous items, and this operation usually
   can result in substantial load put on database.

## Badge counters

Counters should always be truncated. It means that we do not want to present
the exact number over some threshold. The reason for that is for the cases where we want
to calculate exact number of items, we effectively need to filter each of them for
the purpose of knowing the exact number of items matching.

From ~UX perspective it is often acceptable to see that you have over 1000+ pipelines,
instead of that you have 40000+ pipelines, but at a tradeoff of loading page for 2s longer.

An example of this pattern is the list of pipelines and jobs. We truncate numbers to `1000+`,
but we show an accurate number of running pipelines, which is the most interesting information.

There's a helper method that can be used for that purpose - `NumbersHelper.limited_counter_with_delimiter` -
that accepts an upper limit of counting rows.

In some cases it is desired that badge counters are loaded asynchronously.
This can speed up the initial page load and give a better user experience overall.

## Application/misuse limits

Every new feature should have safe usage quotas introduced.
The quota should be optimised to a level that we consider the feature to
be performant and usable for the user, but **not limiting**.

**We want the features to be fully usable for the users.**
**However, we want to ensure that the feature will continue to perform well if used at its limit**
**and it will not cause availability issues.**

Consider that it is always better to start with some kind of limitation,
instead of later introducing a breaking change that would result in some
workflows breaking.

The intent is to provide a safe usage pattern for the feature,
as our implementation decisions are optimised for the given data set.
Our feature limits should reflect the optimisations that we introduced.

The intent of quotas could be different:

1. We want to provide higher quotas for higher tiers of features:
   we want to provide on GitLab.com more capabilities for different tiers,
1. We want to prevent misuse of the feature: someone accidentially creates
   10000 deploy tokens, because of a broken API script,
1. We want to prevent abuse of the feature: someone purposely creates
   a 10000 pipelines to take advantage of the system.

Examples:

1. Pipeline Schedules: It is very unlikely that user will want to create
   more than 50 schedules.
   In such cases it is rather expected that this is either misuse
   or abuse of the feature. Lack of the upper limit can result
   in service degredation as the system will try to process all schedules
   assigned the the project.

1. GitLab CI includes: We started with the limit of maximum of 50 nested includes.
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
[Feature flags in GitLab development](https://docs.gitlab.com/ee/development/feature_flags/process.html#feature-flags-in-gitlab-development).
