---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Sidekiq worker attributes
---

Worker classes can define certain attributes to control their behavior and add metadata.

Child classes inheriting from other workers also inherit these attributes, so you only
have to redefine them if you want to override their values.

## Job urgency

Jobs can have an `urgency` attribute set, which can be `:high`,
`:low`, or `:throttled`. These have the below targets:

| **Urgency**      | **Queue Scheduling Target**   | **Execution Latency Requirement**    |
|---------------   | ----------------------------- | ------------------------------------ |
| `:high`          | 10 seconds                    | 10 seconds                           |
| `:low` (default) | 1 minute                      | 5 minutes                            |
| `:throttled`     | None                          | 5 minutes                            |

To set a job's urgency, use the `urgency` class method:

```ruby
class HighUrgencyWorker
  include ApplicationWorker

  urgency :high

  # ...
end
```

### Latency sensitive jobs

If a large number of background jobs get scheduled at once, queueing of jobs may
occur while jobs wait for a worker node to be become available. This is standard
and gives the system resilience by allowing it to gracefully handle spikes in
traffic. Some jobs, however, are more sensitive to latency than others.

In general, latency-sensitive jobs perform operations that a user could
reasonably expect to happen synchronously, rather than asynchronously in a
background worker. A common example is a write following an action. Examples of
these jobs include:

1. A job which updates a merge request following a push to a branch.
1. A job which invalidates a cache of known branches for a project after a push
   to the branch.
1. A job which recalculates the groups and projects a user can see after a
   change in permissions.
1. A job which updates the status of a CI pipeline after a state change to a job
   in the pipeline.

When these jobs are delayed, the user may perceive the delay as a bug: for
example, they may push a branch and then attempt to create a merge request for
that branch, but be told in the UI that the branch does not exist. We deem these
jobs to be `urgency :high`.

Extra effort is made to ensure that these jobs are started within a very short
period of time after being scheduled. However, to ensure throughput,
these jobs also have very strict execution duration requirements:

1. The median job execution time should be less than 1 second.
1. 99% of jobs should complete within 10 seconds.

If a worker cannot meet these expectations, then it cannot be treated as a
`urgency :high` worker: consider redesigning the worker, or splitting the
work between two different workers, one with `urgency :high` code that
executes quickly, and the other with `urgency :low`, which has no
execution latency requirements (but also has lower scheduling targets).

### Changing a queue's urgency

On GitLab.com, we run Sidekiq in several
[shards](https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq-shard-detail),
each of which represents a particular type of workload.

When changing a queue's urgency, or adding a new queue, we need to take
into account the expected workload on the new shard. If we're
changing an existing queue, there is also an effect on the old shard,
but that always reduces work.

To do this, we want to calculate the expected increase in total execution time
and RPS (throughput) for the new shard. We can get these values from:

- The [Queue Detail dashboard](https://dashboards.gitlab.net/d/sidekiq-queue-detail/sidekiq-queue-detail)
  has values for the queue itself. For a new queue, we can look for
  queues that have similar patterns or are scheduled in similar
  circumstances.
- The [Shard Detail dashboard](https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq-shard-detail)
  has Total Execution Time and Throughput (RPS). The Shard Utilization
  panel displays if there is currently any excess capacity for this
  shard.

We can then calculate the RPS * average runtime (estimated for new jobs)
for the queue we're changing to see what the relative increase in RPS and
execution time we expect for the new shard:

```ruby
new_queue_consumption = queue_rps * queue_duration_avg
shard_consumption = shard_rps * shard_duration_avg

(new_queue_consumption / shard_consumption) * 100
```

If we expect an increase of **less than 5%**, then no further action is needed.

Otherwise, ping `@gitlab-org/scalability` on the merge request and ask
for a review.

## Jobs with External Dependencies

Most background jobs in the GitLab application communicate with other GitLab
services. For example, PostgreSQL, Redis, Gitaly, and Object Storage. These are considered
to be "internal" dependencies for a job.

However, some jobs are dependent on external services to complete
successfully. Some examples include:

1. Jobs which call web-hooks configured by a user.
1. Jobs which deploy an application to a Kubernetes cluster configured by a user.

These jobs have "external dependencies". This is important for the operation of
the background processing cluster in several ways:

1. Most external dependencies (such as web-hooks) do not provide SLOs, and
   therefore we cannot guarantee the execution latencies on these jobs. Since we
   cannot guarantee execution latency, we cannot ensure throughput and
   therefore, in high-traffic environments, we need to ensure that jobs with
   external dependencies are separated from high urgency jobs, to ensure
   throughput on those queues.
1. Errors in jobs with external dependencies have higher alerting thresholds as
   there is a likelihood that the cause of the error is external.

```ruby
class ExternalDependencyWorker
  include ApplicationWorker

  # Declares that this worker depends on
  # third-party, external services in order
  # to complete successfully
  worker_has_external_dependencies!

  # ...
end
```

A job cannot be both high urgency and have external dependencies.

## CPU-bound and Memory-bound Workers

Workers that are constrained by CPU or memory resource limitations should be
annotated with the `worker_resource_boundary` method.

Most workers tend to spend most of their time blocked, waiting on network responses
from other services such as Redis, PostgreSQL, and Gitaly. Since Sidekiq is a
multi-threaded environment, these jobs can be scheduled with high concurrency.

Some workers, however, spend large amounts of time _on-CPU_ running logic in
Ruby. Ruby MRI does not support true multi-threading - it relies on the
[GIL](https://thoughtbot.com/blog/untangling-ruby-threads#the-global-interpreter-lock)
to greatly simplify application development by only allowing one section of Ruby
code in a process to run at a time, no matter how many cores the machine
hosting the process has. For IO bound workers, this is not a problem, since most
of the threads are blocked in underlying libraries (which are outside of the
GIL).

If many threads are attempting to run Ruby code simultaneously, this leads
to contention on the GIL which has the effect of slowing down all
processes.

In high-traffic environments, knowing that a worker is CPU-bound allows us to
run it on a different fleet with lower concurrency. This ensures optimal
performance.

Likewise, if a worker uses large amounts of memory, we can run these on a
bespoke low concurrency, high memory fleet.

Memory-bound workers create heavy GC workloads, with pauses of
10-50 ms. This has an impact on the latency requirements for the
worker. For this reason, `memory` bound, `urgency :high` jobs are not
permitted and fail CI. In general, `memory` bound workers are
discouraged, and alternative approaches to processing the work should be
considered.

If a worker needs large amounts of both memory and CPU time, it should
be marked as memory-bound, due to the above restriction on high urgency
memory-bound workers.

## Declaring a Job as CPU-bound

This example shows how to declare a job as being CPU-bound.

```ruby
class CPUIntensiveWorker
  include ApplicationWorker

  # Declares that this worker will perform a lot of
  # calculations on-CPU.
  worker_resource_boundary :cpu

  # ...
end
```

## Determining whether a worker is CPU-bound

We use the following approach to determine whether a worker is CPU-bound:

- In the Sidekiq structured JSON logs, aggregate the worker `duration` and
  `cpu_s` fields.
- `duration` refers to the total job execution duration, in seconds
- `cpu_s` is derived from the
  [`Process::CLOCK_THREAD_CPUTIME_ID`](https://www.rubydoc.info/stdlib/core/Process:clock_gettime)
  counter, and is a measure of time spent by the job on-CPU.
- Divide `cpu_s` by `duration` to get the percentage time spend on-CPU.
- If this ratio exceeds 33%, the worker is considered CPU-bound and should be
  annotated as such.
- These values should not be used over small sample sizes, but
  rather over fairly large aggregates.

## Feature category

All Sidekiq workers must define a known [feature category](../feature_categorization/_index.md#sidekiq-workers).

## Job data consistency strategies

In GitLab 13.11 and earlier, Sidekiq workers would always send database queries to the primary
database node,
both for reads and writes. This ensured that data integrity
is both guaranteed and immediate, since in a single-node scenario it is impossible to encounter
stale reads even for workers that read their own writes.
If a worker writes to the primary, but reads from a replica, however, the possibility
of reading a stale record is non-zero due to replicas potentially lagging behind the primary.

When the number of jobs that rely on the database increases, ensuring immediate data consistency
can put unsustainable load on the primary database server. We therefore added the ability to use
[Database Load Balancing for Sidekiq workers](../../administration/postgresql/database_load_balancing.md).
By configuring a worker's `data_consistency` field, we can then allow the scheduler to target read replicas
under several strategies outlined below.

### Trading immediacy for reduced primary load

We require Sidekiq workers to make an explicit decision around whether they need to use the
primary database node for all reads and writes, or whether reads can be served from replicas. This is
enforced by a RuboCop rule, which ensures that the `data_consistency` field is set.

Before `data_consistency` was introduced, the default behavior mimicked that of `:always`. Since jobs are
now enqueued along with the current database LSN, the replica (for `:sticky` or `:delayed`) is guaranteed
to be caught up to that point, or the job will be retried, or use the primary. This means that the data
will be consistent at least to the point at which the job was enqueued.

The table below shows the `data_consistency` attribute and its values, ordered by the degree to which
they prefer read replicas and wait for replicas to catch up:

| **Data consistency**  | **Description**  | **Guideline** |
|--------------|-----------------------------|----------|
| `:always`    | The job is required to use the primary database for all queries. (Deprecated) | **Deprecated** Only needed for jobs that encounter edge cases around primary stickiness. |
| `:sticky`    | The job prefers replicas, but switches to the primary for writes or when encountering replication lag. (Default) | This is the default option. It should be used for jobs that require to be executed as fast as possible. Replicas are guaranteed to be caught up to the point at which the job was enqueued in Sidekiq. |
| `:delayed`   | The job prefers replicas, but switches to the primary for writes. When encountering replication lag before the job starts, the job is retried once. If the replica is still not up to date on the next retry, it switches to the primary. | It should be used for jobs where delaying execution further typically does not matter, such as cache expiration or web hooks execution. It should not be used for jobs where retry is disabled, such as cron jobs. |

In all cases workers read either from a replica that is fully caught up,
or from the primary node, so data consistency is always ensured.

To set a data consistency for a worker, use the `data_consistency` class method:

```ruby
class DelayedWorker
  include ApplicationWorker

  data_consistency :delayed

  # ...
end
```

### Overriding data consistency for a decomposed database

GitLab uses multiple decomposed databases. Sidekiq workers usage of the respective databases may be skewed towards
a particular database. For example, `PipelineProcessWorker` has a higher write traffic to the `ci` database compared to the
`main` database. In the event of edge cases around primary stickiness, having separate data consistency defined for each
database allows the worker to more efficiently use read replicas.

If the `overrides` keyword argument is set, the `Gitlab::Database::LoadBalancing::SidekiqServerMiddleware` loads the load
balancing strategy using the data consistency which most prefers the read replicas.
The order of preference in increasing preference is: `:always`, `:sticky`, then `:delayed`.

The overrides only apply if the GitLab instance is using multiple databases or `Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES`.

To set a data consistency for a worker, use the `data_consistency` class method with the `overrides` keyword argument:

```ruby
class MultipleDataConsistencyWorker
  include ApplicationWorker

  data_consistency :always, overrides: { ci: :sticky }

  # ...
end
```

### `feature_flag` property

The `feature_flag` property allows you to toggle a job's `data_consistency`,
which permits you to safely toggle load balancing capabilities for a specific job.
When `feature_flag` is disabled, the job defaults to `:always`, which means that the job always uses the primary database.

The `feature_flag` property does not allow the use of
[feature gates based on actors](../feature_flags/_index.md).
This means that the feature flag cannot be toggled only for particular
projects, groups, or users, but instead, you can safely use [percentage of time rollout](../feature_flags/_index.md).
Since we check the feature flag on both Sidekiq client and server, rolling out a 10% of the time,
likely results in 1% (`0.1` `[from client]*0.1` `[from server]`) of effective jobs using replicas.

Example:

```ruby
class DelayedWorker
  include ApplicationWorker

  data_consistency :delayed, feature_flag: :load_balancing_for_delayed_worker

  # ...
end
```

When using the `feature_flag` property with `overrides`, the jobs defaults to `always` for all database connections.
When the feature flag is enabled, the configured data consistency is then applied to each database independently.
For the below example, when the flag is enabled, the `main` database connections will use the `:always` data consistency while
`ci` database connections will use `:sticky` data consistency.

```ruby
class DelayedWorker
  include ApplicationWorker

  data_consistency :always, overrides: { ci: :sticky }, feature_flag: :load_balancing_for_delayed_worker

  # ...
end
```

### Data consistency with idempotent jobs

For [idempotent jobs](idempotent_jobs.md) that declare either `:sticky` or `:delayed` data consistency, we are
[preserving the latest WAL location](idempotent_jobs.md#preserve-the-latest-wal-location-for-idempotent-jobs) while deduplicating,
ensuring that we read from the replica that is fully caught up.

## Job pause control

With the `pause_control` property, you can conditionally pause job processing. If the strategy is active, the job
is stored in a separate `ZSET` and re-enqueued when the strategy becomes inactive. `PauseControl::ResumeWorker` is a cron
worker that checks if any paused jobs must be restarted.

To use `pause_control`, you can:

- Use one of the strategies defined in `lib/gitlab/sidekiq_middleware/pause_control/strategies/`.
- Define a custom strategy in `lib/gitlab/sidekiq_middleware/pause_control/strategies/` and add the strategy to `lib/gitlab/sidekiq_middleware/pause_control.rb`.

For example:

```ruby
module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        class CustomStrategy < Base
          def should_pause?
            ApplicationSetting.current.elasticsearch_pause_indexing?
          end
        end
      end
    end
  end
end
```

```ruby
class PausedWorker
  include ApplicationWorker

  pause_control :custom_strategy

  # ...
end
```

WARNING:
In case you want to remove the middleware for a worker, please set the strategy to `:deprecated` to disable it and wait until
a required stop before removing it completely. That ensures that all paused jobs are resumed correctly.

## Concurrency limit

With the `concurrency_limit` property, you can limit the worker's concurrency. It will put the jobs that are over this limit in
a separate `LIST` and re-enqueued when it falls under the limit. `ConcurrencyLimit::ResumeWorker` is a cron
worker that checks if any throttled jobs should be re-enqueued.

The first job that crosses the defined concurrency limit initiates the throttling process for all other jobs of this class.
Until this happens, jobs are scheduled and executed as usual.

When the throttling starts, newly scheduled and executed jobs will be added to the end of the `LIST` to ensure that
the execution order is preserved. As soon as the `LIST` is empty again, the throttling process ends.

Prometheus metrics are exposed to monitor workers using concurrency limit middleware:

- `sidekiq_concurrency_limit_deferred_jobs_total`
- `sidekiq_concurrency_limit_queue_jobs`
- `sidekiq_concurrency_limit_queue_jobs_total`
- `sidekiq_concurrency_limit_max_concurrent_jobs`
- `sidekiq_concurrency_limit_current_concurrent_jobs_total`

WARNING:
If there is a sustained workload over the limit, the `LIST` is going to grow until the limit is disabled or
the workload drops under the limit.

You should use a lambda to define the limit. If it returns `nil` or `0`, the limit won't be applied.
Negative numbers pause the execution.

```ruby
class LimitedWorker
  include ApplicationWorker

  concurrency_limit -> { 60 }

  # ...
end
```

```ruby
class LimitedWorker
  include ApplicationWorker

  concurrency_limit -> { ApplicationSetting.current.elasticsearch_concurrent_sidekiq_jobs }

  # ...
end
```

## Skip execution of workers in Geo secondary

On Geo secondary sites, database writes are disabled.
You must skip execution of workers that attempt database writes from Geo secondary sites,
if those workers get enqueued on Geo secondary sites.
Conveniently, most workers do not get enqueued on Geo secondary sites, because
[most non-GET HTTP requests get proxied to the Geo primary site](https://gitlab.com/gitlab-org/gitlab/-/blob/v16.8.0-ee/workhorse/internal/upstream/routes.go#L382-L431),
and because Geo secondary sites
[disable most Sidekiq-Cron jobs](https://gitlab.com/gitlab-org/gitlab/-/blob/v16.8.0-ee/ee/lib/gitlab/geo/cron_manager.rb#L6-L26).
Ask a Geo engineer if you are unsure.
To skip execution, prepend the `::Geo::SkipSecondary` module to the worker class.

```ruby
class DummyWorker
  include ApplicationWorker
  prepend ::Geo::SkipSecondary

 # ...
end
```
