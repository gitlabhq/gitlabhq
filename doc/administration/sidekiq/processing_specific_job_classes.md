---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Processing specific job classes
---

WARNING:
These are advanced settings. While they are used on GitLab.com, most GitLab
instances should only add more processes that listen to all queues. This is the
same approach described in the [Reference Architectures](../reference_architectures/_index.md).

Most GitLab instances should have [all processes to listen to all queues](extra_sidekiq_processes.md#start-multiple-processes).

Another alternative is to use [routing rules](#routing-rules) which direct specific
job classes inside the application to queue names that you configure. Then, the Sidekiq
processes only need to listen to a handful of the configured queues. Doing so
lowers the load on Redis, which is important on very large-scale deployments.

## Routing rules

> - [Default routing rule value](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97908) introduced in GitLab 15.4.
> - Queue selectors [replaced by routing rules](https://gitlab.com/gitlab-org/gitlab/-/issues/390787) in GitLab 17.0.

NOTE:
Mailer jobs cannot be routed by routing rules, and always go to the
`mailers` queue. When using routing rules, ensure that at least one process is
listening to the `mailers` queue. Typically this can be placed alongside the
`default` queue.

We recommend most GitLab instances using routing rules to manage their Sidekiq
queues. This allows administrators to choose single queue names for groups of
job classes based on their attributes. The syntax is an ordered array of pairs of `[query, queue]`:

1. The query is a [worker matching query](#worker-matching-query).
1. The queue name must be a valid Sidekiq queue name. If the queue name
   is `nil`, or an empty string, the worker is routed to the queue generated
   by the name of the worker instead. (See [list of available job classes](#list-of-available-job-classes)
   for more information).
   The queue name does not have to match any existing queue name in the
   list of available job classes.
1. The first query matching a worker is chosen for that worker; later rules are
   ignored.

### Routing rules migration

After the Sidekiq routing rules are changed, you must take care with
the migration to avoid losing jobs entirely, especially in a system with long
queues of jobs. The migration can be done by following the migration steps
mentioned in [Sidekiq job migration](sidekiq_job_migration.md).

### Routing rules in a scaled architecture

Routing rules must be the same across all GitLab nodes (especially GitLab Rails
and Sidekiq nodes) as they are part of the application configuration.

### Detailed example

This is a comprehensive example intended to show different possibilities.
A [Helm chart example is also available](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/#queues).
These are not recommendations.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['routing_rules'] = [
     # Route all non-CPU-bound workers that are high urgency to `high-urgency` queue
     ['resource_boundary!=cpu&urgency=high', 'high-urgency'],
     # Route all database, gitaly and global search workers that are throttled to `throttled` queue
     ['feature_category=database,gitaly,global_search&urgency=throttled', 'throttled'],
     # Route all workers having contact with outside world to a `network-intenstive` queue
     ['has_external_dependencies=true|feature_category=hooks|tags=network', 'network-intensive'],
     # Wildcard matching, route the rest to `default` queue
     ['*', 'default']
   ]
   ```

   The `queue_groups` can then be set to match these generated queue names. For
   instance:

   ```ruby
   sidekiq['queue_groups'] = [
     # Run two high-urgency processes
     'high-urgency',
     'high-urgency',
     # Run one process for throttled, network-intensive
     'throttled,network-intensive',
     # Run one 'catchall' process on the default and mailers queues
     'default,mailers'
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Worker matching query

GitLab provides a query syntax to match a worker based on its attributes
employed by routing rules. A query includes two components:

- Attributes that can be selected.
- Operators used to construct a query.

### Available attributes

Queue matching query works upon the worker attributes, described in
[Sidekiq style guide](../../development/sidekiq/_index.md). We support querying
based on a subset of worker attributes:

- `feature_category` - the
  [GitLab feature category](https://handbook.gitlab.com/handbook/product/categories/#categories-a-z) the
  queue belongs to. For example, the `merge` queue belongs to the
  `source_code_management` category.
- `has_external_dependencies` - whether or not the queue connects to external
  services. For example, all importers have this set to `true`.
- `urgency` - how important it is that this queue's jobs run
  quickly. Can be `high`, `low`, or `throttled`. For example, the
  `authorized_projects` queue is used to refresh user permissions, and
  is `high` urgency.
- `worker_name` - the worker name. Use this attribute to select a specific worker. Find all available names in [the job classes lists](#list-of-available-job-classes) below.
- `name` - the queue name generated from the worker name. Use this attribute to select a specific queue. Because this is generated from
  the worker name, it does not change based on the result of other routing
  rules.
- `resource_boundary` - if the queue is bound by `cpu`, `memory`, or
  `unknown`. For example, the `ProjectExportWorker` is memory bound as it has
  to load data in memory before saving it for export.
- `tags` - short-lived annotations for queues. These are expected to frequently
  change from release to release, and may be removed entirely.
- `queue_namespace` - Some workers are grouped by a namespace, and
  `name` is prefixed with `<queue_namespace>:`. For example, for a queue `name` of `cronjob:admin_email`,
  `queue_namespace` is `cronjob`. Use this attribute to select a group of workers.

`has_external_dependencies` is a boolean attribute: only the exact
string `true` is considered true, and everything else is considered
false.

`tags` is a set, which means that `=` checks for intersecting sets, and
`!=` checks for disjoint sets. For example, `tags=a,b` selects queues
that have tags `a`, `b`, or both. `tags!=a,b` selects queues that have
neither of those tags.

### Available operators

Routing rules support the following operators, listed from highest to lowest
precedence:

- `|` - the logical `OR` operator. For example, `query_a|query_b` (where `query_a`
  and `query_b` are queries made up of the other operators here) includes
  queues that match either query.
- `&` - the logical `AND` operator. For example, `query_a&query_b` (where
  `query_a` and `query_b` are queries made up of the other operators here)
  include only queues that match both queries.
- `!=` - the `NOT IN` operator. For example, `feature_category!=issue_tracking`
  excludes all queues from the `issue_tracking` feature category.
- `=` - the `IN` operator. For example, `resource_boundary=cpu` includes all
  queues that are CPU bound.
- `,` - the concatenate set operator. For example,
  `feature_category=continuous_integration,pages` includes all queues from
  either the `continuous_integration` category or the `pages` category. This
  example is also possible using the OR operator, but allows greater brevity, as
  well as being lower precedence.

The operator precedence for this syntax is fixed: it's not possible to make `AND`
have higher precedence than `OR`.

As with the standard queue group syntax above, a single `*` as the
entire queue group selects all queues.

### List of available job classes

For a list of the existing Sidekiq job classes and queues, check the following
files:

- [Queues for all GitLab editions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
- [Queues for GitLab Enterprise Editions only](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)
