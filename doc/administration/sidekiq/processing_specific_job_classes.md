---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Processing specific job classes

WARNING:
These are advanced settings. While they are used on GitLab.com, most GitLab
instances should only add more processes that listen to all queues. This is the
same approach we take in our [Reference Architectures](../reference_architectures/index.md).

GitLab has two options for creating Sidekiq processes that only handle specific
job classes:

1. [Routing rules](#routing-rules) are used on GitLab.com. They direct jobs
   inside the application to queue names configured by administrators. This
   lowers the load on Redis, which is important on very large-scale deployments.
1. [Queue selectors](#queue-selectors-deprecated) perform the job selection outside the
   application, when starting the Sidekiq process. This was used on GitLab.com
   until September 2021, and is retained for compatibility reasons.

Both of these use the same [worker matching query](#worker-matching-query)
syntax. While they can technically be used together, most deployments should
choose one or the other; there is no particular benefit in combining them.

## Routing rules

> - [Default routing rule value](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97908) introduced in GitLab 15.4.

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

After the Sidekiq routing rules are changed, administrators must take care with
the migration to avoid losing jobs entirely, especially in a system with long
queues of jobs. The migration can be done by following the migration steps
mentioned in [Sidekiq job migration](sidekiq_job_migration.md).

### Routing rules in a scaled architecture

Routing rules must be the same across all GitLab nodes (especially GitLab Rails and Sidekiq nodes) as they are part of the
application configuration. Queue selectors can be different across GitLab nodes
because they only change the arguments to the launched Sidekiq process.

### Detailed example

This is a comprehensive example intended to show different possibilities.
A [Helm chart example is also available](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/#queues).
They are not recommendations.

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
     # Run one process for throttled, network-intensive, import
     'throttled,network-intensive,import',
     # Run one 'catchall' process on the default and mailers queues
     'default,mailers'
   ]
   ```

   If you are using GitLab 16.11 and earlier, explicitly disable any [queue selectors](#queue-selectors-deprecated)
   that might be enabled:

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

<!--- start_remove The following content will be removed on remove_date: '2024-08-22' -->

## Queue selectors (deprecated)

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/390787) in GitLab 15.9
and is planned for removal in 17.0. Most instances should have [all processes to listen to all queues](extra_sidekiq_processes.md#start-multiple-processes).
Another alternative is to use [routing rules](#routing-rules) (be warned this is an advanced setting). This change is a breaking change.

The `queue_selector` option allows queue groups to be selected in a more general
way using a [worker matching query](#worker-matching-query). After
`queue_selector` is set, all `queue_groups` must follow the aforementioned
syntax.

### Using queue selectors

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['enable'] = true
   sidekiq['routing_rules'] = [['*', nil]]
   sidekiq['queue_selector'] = true
   sidekiq['queue_groups'] = [
     # Run all non-CPU-bound queues that are high urgency
     'resource_boundary!=cpu&urgency=high',
     # Run all continuous integration and pages queues that are not high urgency
     'feature_category=continuous_integration,pages&urgency!=high',
     # Run all queues
     '*'
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Negate settings (deprecated)

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/390787) in GitLab 15.9
and is planned for removal in 17.0. Most instances should have [all processes to listen to all queues](extra_sidekiq_processes.md#start-multiple-processes).
Another alternative is to use [routing rules](#routing-rules) (be warned this is an advanced setting). This change is a breaking change.

This allows you to have the Sidekiq process work on every queue **except** the
ones you list. This is generally only used when there are multiple Sidekiq
nodes. In this example, we exclude all import-related jobs from a Sidekiq node.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['routing_rules'] = [['*', nil]]
   sidekiq['negate'] = true
   sidekiq['queue_selector'] = true
   sidekiq['queue_groups'] = [
      "feature_category=importers"
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Migrating from queue selectors to routing rules

We recommend GitLab deployments add more Sidekiq processes listening to all queues, as in the
[Reference Architectures](../reference_architectures/index.md). For very large-scale deployments, we recommend
[routing rules](#routing-rules) instead of [queue selectors](#queue-selectors-deprecated). We use routing rules on GitLab.com as
it helps to lower the load on Redis.

### Single node setup

To migrate from queue selectors to routing rules in a [single node setup](../reference_architectures/index.md#standalone-non-ha):

1. Open `/etc/gitlab/gitlab.rb`.
1. Set `sidekiq['queue_selector']` to `false`.
1. Take all queue `selector`s in the `sidekiq['queue_groups']`.
1. Give each `selector` a `queue_name` and put them in `[selector, queue_name]` format.
1. Replace `sidekiq['routing_rules']` with an array of `[selector, queue_name]` entries.
1. Add a wildcard match of `['*', 'default']` as the last entry in `sidekiq['routing_rules']`. This "catchall" queue has
   to be named as `default`.
1. Replace `sidekiq['queue_groups']` with `queue_name`s.
1. Add at least one `default` queue and at least one `mailers` queue to the `sidekiq['queue_groups']`.
1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Run the Rake task to [migrate existing jobs](sidekiq_job_migration.md):

   ```shell
   sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued
   ```

NOTE:
It is important to run the Rake task immediately after reconfiguring GitLab.
After reconfiguring GitLab, existing jobs are not processed until the Rake task starts to migrate the jobs.

#### Migration example

The following example better illustrates the migration process above:

1. In `/etc/gitlab/gitlab.rb`, check the `urgency` queries in the `sidekiq['queue_groups']`. For example:

   ```ruby
   sidekiq['routing_rules'] = []
   sidekiq['queue_selector'] = true
   sidekiq['queue_groups'] = [
     'urgency=high',
     'urgency=low',
     'urgency=throttled',
     '*'
   ]
   ```

1. Use these same `urgency` queries to update `/etc/gitlab/gitlab.rb` to use routing rules:

   ```ruby
   sidekiq['min_concurrency'] = 20
   sidekiq['max_concurrency'] = 20

   sidekiq['routing_rules'] = [
     ['urgency=high', 'high_urgency'],
     ['urgency=low', 'low_urgency'],
     ['urgency=throttled', 'throttled_urgency'],
     # Wildcard matching, route the rest to `default` queue
     ['*', 'default']
   ]

   sidekiq['queue_selector'] = false
   sidekiq['queue_groups'] = [
     'high_urgency',
     'low_urgency',
     'throttled_urgency',
     'default,mailers'
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Run the Rake task to [migrate existing jobs](sidekiq_job_migration.md):

   ```shell
   sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued
   ```

WARNING:
As described in [the concurrency section](extra_sidekiq_processes.md#manage-thread-counts-explicitly), we
recommend setting `min_concurrency` and `max_concurrency` to the same value. For example, if the number of queues
in a queue group entry is 1, while `min_concurrency` is set to `0`, and `max_concurrency` is set to `20`, the resulting
concurrency is set to `2` instead. A concurrency of `2` might be too low in most cases, except for very highly-CPU
bound tasks.

### Multiple node setup

For a multiple node setup:

- Reconfigure all GitLab Rails and Sidekiq nodes with the same `sidekiq['routing_rules']` setting.
- Alternate between GitLab Rails and Sidekiq nodes as you update and reconfigure the nodes. This ensures the newly configured Sidekiq is ready to consume jobs from the new set of
  queues during the migration. Otherwise, the new jobs hang until the end of the migration.

Consider the following example of three GitLab Rails nodes and two Sidekiq nodes. To migrate from queue selectors to routing rules:

1. In Sidekiq 1, follow all steps but one in [single node setup](#single-node-setup).
   **Do not** run the Rake task to [migrate existing jobs](sidekiq_job_migration.md).
1. Configure the external load balancer to remove Rails 1 from accepting traffic. This step ensures Rails 1 is not serving any request while the Rails process is restarting. For more information, see [issue 428794](https://gitlab.com/gitlab-org/gitlab/-/issues/428794#note_1619505870).
1. In Rails 1, update `/etc/gitlab/gitlab.rb` to use the same `sidekiq['routing_rules']` setting as Sidekiq 1.
   Only `sidekiq['routing_rules']` is required in Rails nodes.
1. Configure the external load balancer to register Rails 1 back.
1. Repeat steps 1 to 4 for Sidekiq 2 and Rails 2.
1. Repeat steps 2 to 4 for Rails 3.
1. If there are more Sidekiq nodes than Rails nodes, follow step 1 on the remaining Sidekiq nodes.
1. Run the Rake task to [migrate existing jobs](sidekiq_job_migration.md):

   ```shell
   sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued
   ```

<!--- end_remove -->

## Worker matching query

GitLab provides a query syntax to match a worker based on its attributes. This
query syntax is employed by both [routing rules](#routing-rules) and
[queue selectors](#queue-selectors-deprecated). A query includes two components:

- Attributes that can be selected.
- Operators used to construct a query.

### Available attributes

Queue matching query works upon the worker attributes, described in
[Sidekiq style guide](../../development/sidekiq/index.md). We support querying
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

`has_external_dependencies` is a boolean attribute: only the exact
string `true` is considered true, and everything else is considered
false.

`tags` is a set, which means that `=` checks for intersecting sets, and
`!=` checks for disjoint sets. For example, `tags=a,b` selects queues
that have tags `a`, `b`, or both. `tags!=a,b` selects queues that have
neither of those tags.

### Available operators

Routing rules and queue selectors support the following operators, listed from
highest to lowest precedence:

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
