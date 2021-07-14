---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sidekiq Style Guide

This document outlines various guidelines that should be followed when adding or
modifying Sidekiq workers.

## ApplicationWorker

All workers should include `ApplicationWorker` instead of `Sidekiq::Worker`,
which adds some convenience methods and automatically sets the queue based on
the worker's name.

## Retries

Sidekiq defaults to using [25
retries](https://github.com/mperham/sidekiq/wiki/Error-Handling#automatic-job-retry),
with back-off between each retry. 25 retries means that the last retry
would happen around three weeks after the first attempt (assuming all 24
prior retries failed).

For most workers - especially [idempotent workers](#idempotent-jobs) -
the default of 25 retries is more than sufficient. Many of our older
workers declare 3 retries, which used to be the default within the
GitLab application. 3 retries happen over the course of a couple of
minutes, so the jobs are prone to failing completely.

A lower retry count may be applicable if any of the below apply:

1. The worker contacts an external service and we do not provide
   guarantees on delivery. For example, webhooks.
1. The worker is not idempotent and running it multiple times could
   leave the system in an inconsistent state. For example, a worker that
   posts a system note and then performs an action: if the second step
   fails and the worker retries, the system note will be posted again.
1. The worker is a cronjob that runs frequently. For example, if a cron
   job runs every hour, then we don't need to retry beyond an hour
   because we don't need two of the same job running at once.

Each retry for a worker is counted as a failure in our metrics. A worker
which always fails 9 times and succeeds on the 10th would have a 90%
error rate.

## Dedicated Queues

All workers should use their own queue, which is automatically set based on the
worker class name. For a worker named `ProcessSomethingWorker`, the queue name
would be `process_something`. If you're not sure what queue a worker uses,
you can find it using `SomeWorker.queue`. There is almost never a reason to
manually override the queue name using `sidekiq_options queue: :some_queue`.

After adding a new queue, run `bin/rake
gitlab:sidekiq:all_queues_yml:generate` to regenerate
`app/workers/all_queues.yml` or `ee/app/workers/all_queues.yml` so that
it can be picked up by
[`sidekiq-cluster`](../administration/operations/extra_sidekiq_processes.md).
Additionally, run
`bin/rake gitlab:sidekiq:sidekiq_queues_yml:generate` to regenerate
`config/sidekiq_queues.yml`.

## Queue Namespaces

While different workers cannot share a queue, they can share a queue namespace.

Defining a queue namespace for a worker makes it possible to start a Sidekiq
process that automatically handles jobs for all workers in that namespace,
without needing to explicitly list all their queue names. If, for example, all
workers that are managed by `sidekiq-cron` use the `cronjob` queue namespace, we
can spin up a Sidekiq process specifically for these kinds of scheduled jobs.
If a new worker using the `cronjob` namespace is added later on, the Sidekiq
process also picks up jobs for that worker (after having been restarted),
without the need to change any configuration.

A queue namespace can be set using the `queue_namespace` DSL class method:

```ruby
class SomeScheduledTaskWorker
  include ApplicationWorker

  queue_namespace :cronjob

  # ...
end
```

Behind the scenes, this sets `SomeScheduledTaskWorker.queue` to
`cronjob:some_scheduled_task`. Commonly used namespaces have their own
concern module that can easily be included into the worker class, and that may
set other Sidekiq options besides the queue namespace. `CronjobQueue`, for
example, sets the namespace, but also disables retries.

`bundle exec sidekiq` is namespace-aware, and listens on all
queues in a namespace (technically: all queues prefixed with the namespace name)
when a namespace is provided instead of a simple queue name in the `--queue`
(`-q`) option, or in the `:queues:` section in `config/sidekiq_queues.yml`.

Note that adding a worker to an existing namespace should be done with care, as
the extra jobs take resources away from jobs from workers that were already
there, if the resources available to the Sidekiq process handling the namespace
are not adjusted appropriately.

## Versioning

Version can be specified on each Sidekiq worker class.
This is then sent along when the job is created.

```ruby
class FooWorker
  include ApplicationWorker

  version 2

  def perform(*args)
    if job_version == 2
      foo = args.first['foo']
    else
      foo = args.first
    end
  end
end
```

Under this schema, any worker is expected to be able to handle any job that was
enqueued by an older version of that worker. This means that when changing the
arguments a worker takes, you must increment the `version` (or set `version 1`
if this is the first time a worker's arguments are changing), but also make sure
that the worker is still able to handle jobs that were queued with any earlier
version of the arguments. From the worker's `perform` method, you can read
`self.job_version` if you want to specifically branch on job version, or you
can read the number or type of provided arguments.

## Idempotent Jobs

It's known that a job can fail for multiple reasons. For example, network outages or bugs.
In order to address this, Sidekiq has a built-in retry mechanism that is
used by default by most workers within GitLab.

It's expected that a job can run again after a failure without major side-effects for the
application or users, which is why Sidekiq encourages
jobs to be [idempotent and transactional](https://github.com/mperham/sidekiq/wiki/Best-Practices#2-make-your-job-idempotent-and-transactional).

As a general rule, a worker can be considered idempotent if:

- It can safely run multiple times with the same arguments.
- Application side-effects are expected to happen only once
  (or side-effects of a second run do not have an effect).

A good example of that would be a cache expiration worker.

A job scheduled for an idempotent worker is [deduplicated](#deduplication) when
an unstarted job with the same arguments is already in the queue.

WARNING:
For [data consistency jobs](#job-data-consistency-strategies), the deduplication is not compatible with the
`data_consistency` attribute set to `:sticky` or `:delayed`.
The reason for this is that deduplication always takes into account the latest binary replication pointer into account, not the first one.
There is an [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/325291) to improve this.

### Ensuring a worker is idempotent

Make sure the worker tests pass using the following shared example:

```ruby
include_examples 'an idempotent worker' do
  it 'marks the MR as merged' do
    # Using subject inside this block will process the job multiple times
    subject

    expect(merge_request.state).to eq('merged')
  end
end
```

Use the `perform_multiple` method directly instead of `job.perform` (this
helper method is automatically included for workers).

### Declaring a worker as idempotent

```ruby
class IdempotentWorker
  include ApplicationWorker

  # Declares a worker is idempotent and can
  # safely run multiple times.
  idempotent!

  # ...
end
```

It's encouraged to only have the `idempotent!` call in the top-most worker class, even if
the `perform` method is defined in another class or module.

If the worker class isn't marked as idempotent, a cop fails. Consider skipping
the cop if you're not confident your job can safely run multiple times.

### Deduplication

When a job for an idempotent worker is enqueued while another
unstarted job is already in the queue, GitLab drops the second
job. The work is skipped because the same work would be
done by the job that was scheduled first; by the time the second
job executed, the first job would do nothing.

#### Strategies

GitLab supports two deduplication strategies:

- `until_executing`
- `until_executed`

More [deduplication strategies have been
suggested](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/195). If
you are implementing a worker that could benefit from a different
strategy, please comment in the issue.

##### Until Executing

This strategy takes a lock when a job is added to the queue, and removes that lock before the job starts.

For example, `AuthorizedProjectsWorker` takes a user ID. When the
worker runs, it recalculates a user's authorizations. GitLab schedules
this job each time an action potentially changes a user's
authorizations. If the same user is added to two projects at the
same time, the second job can be skipped if the first job hasn't
begun, because when the first job runs, it creates the
authorizations for both projects.

```ruby
module AuthorizedProjectUpdate
  class UserRefreshOverUserRangeWorker
    include ApplicationWorker

    deduplicate :until_executing
    idempotent!

    # ...
  end
end
```

##### Until Executed

This strategy takes a lock when a job is added to the queue, and removes that lock after the job finishes.
It can be used to prevent jobs from running simultaneously multiple times.

```ruby
module Ci
  class BuildTraceChunkFlushWorker
    include ApplicationWorker

    deduplicate :until_executed
    idempotent!

    # ...
  end
end
```

#### Scheduling jobs in the future

GitLab doesn't skip jobs scheduled in the future, as we assume that
the state has changed by the time the job is scheduled to
execute. Deduplication of jobs scheduled in the feature is possible
for both `until_executed` and `until_executing` strategies.

If you do want to deduplicate jobs scheduled in the future,
this can be specified on the worker by passing `including_scheduled: true` argument
when defining deduplication strategy:

```ruby
module AuthorizedProjectUpdate
  class UserRefreshOverUserRangeWorker
    include ApplicationWorker

    deduplicate :until_executing, including_scheduled: true
    idempotent!

    # ...
  end
end
```

## Limited capacity worker

It is possible to limit the number of concurrent running jobs for a worker class
by using the `LimitedCapacity::Worker` concern.

The worker must implement three methods:

- `perform_work`: The concern implements the usual `perform` method and calls
  `perform_work` if there's any available capacity.
- `remaining_work_count`: Number of jobs that have work to perform.
- `max_running_jobs`: Maximum number of jobs allowed to run concurrently.

```ruby
class MyDummyWorker
  include ApplicationWorker
  include LimitedCapacity::Worker

  def perform_work(*args)
  end

  def remaining_work_count(*args)
    5
  end

  def max_running_jobs
    25
  end
end
```

Additional to the regular worker, a cron worker must be defined as well to
backfill the queue with jobs. the arguments passed to `perform_with_capacity`
are passed to the `perform_work` method.

```ruby
class ScheduleMyDummyCronWorker
  include ApplicationWorker
  include CronjobQueue

  def perform(*args)
    MyDummyWorker.perform_with_capacity(*args)
  end
end
```

### How many jobs are running?

It runs `max_running_jobs` at almost all times.

The cron worker checks the remaining capacity on each execution and it
schedules at most `max_running_jobs` jobs. Those jobs on completion
re-enqueue themselves immediately, but not on failure. The cron worker is in
charge of replacing those failed jobs.

### Handling errors and idempotence

This concern disables Sidekiq retries, logs the errors, and sends the job to the
dead queue. This is done to have only one source that produces jobs and because
the retry would occupy a slot with a job to perform in the distant future.

We let the cron worker enqueue new jobs, this could be seen as our retry and
back off mechanism because the job might fail again if executed immediately.
This means that for every failed job, we run at a lower capacity
until the cron worker fills the capacity again. If it is important for the
worker not to get a backlog, exceptions must be handled in `#perform_work` and
the job should not raise.

The jobs are deduplicated using the `:none` strategy, but the worker is not
marked as `idempotent!`.

### Metrics

This concern exposes three Prometheus metrics of gauge type with the worker class
name as label:

- `limited_capacity_worker_running_jobs`
- `limited_capacity_worker_max_running_jobs`
- `limited_capacity_worker_remaining_work_count`

## Job urgency

Jobs can have an `urgency` attribute set, which can be `:high`,
`:low`, or `:throttled`. These have the below targets:

| **Urgency**  | **Queue Scheduling Target** | **Execution Latency Requirement**  |
|--------------|-----------------------------|------------------------------------|
| `:high`      | 10 seconds                  | p50 of 1 second, p99 of 10 seconds |
| `:low`       | 1 minute                    | Maximum run time of 5 minutes      |
| `:throttled` | None                        | Maximum run time of 5 minutes      |

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
occur while jobs wait for a worker node to be become available. This is normal
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
period of time after being scheduled. However, in order to ensure throughput,
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
into account the expected workload on the new shard. Note that, if we're
changing an existing queue, there is also an effect on the old shard,
but that always reduces work.

To do this, we want to calculate the expected increase in total execution time
and RPS (throughput) for the new shard. We can get these values from:

- The [Queue Detail
  dashboard](https://dashboards.gitlab.net/d/sidekiq-queue-detail/sidekiq-queue-detail)
  has values for the queue itself. For a new queue, we can look for
  queues that have similar patterns or are scheduled in similar
  circumstances.
- The [Shard Detail
  dashboard](https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq-shard-detail)
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

Otherwise, please ping `@gitlab-org/scalability` on the merge request and ask
for a review.

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
[database load balancing for Sidekiq workers](../administration/database_load_balancing.md#load-balancing-for-sidekiq).
By configuring a worker's `data_consistency` field, we can then allow the scheduler to target read replicas
under several strategies outlined below.

## Trading immediacy for reduced primary load

Not requiring immediate data consistency allows developers to decide to either:

- Ensure immediately consistent reads, but increase load on the primary database.
- Prefer read replicas to add relief to the primary, but increase the likelihood of stale reads that have to be retried.

By default, any worker has a data consistency requirement of `:always`, so, as before, all
database operations target the primary. To allow for reads to be served from replicas instead, we
added two additional consistency modes: `:sticky` and `:delayed`.

When you declare either `:sticky` or `:delayed` consistency, workers become eligible for database
load-balancing. In both cases, jobs are enqueued with a short delay.
This minimizes the likelihood of replication lag after a write.

The difference is in what happens when there is replication lag after the delay: `sticky` workers
switch over to the primary right away, whereas `delayed` workers fail fast and are retried once.
If they still encounter replication lag, they also switch to the primary instead.
**If your worker never performs any writes, it is strongly advised to apply one of these consistency settings,
since it will never need to rely on the primary database node.**

The table below shows the `data_consistency` attribute and its values, ordered by the degree to which
they prefer read replicas and will wait for replicas to catch up:

| **Data Consistency**  | **Description**  |
|--------------|-----------------------------|
| `:always`    | The job is required to use the primary database (default). It should be used for workers that primarily perform writes or that have very strict requirements around reading their writes without suffering any form of delay. |
| `:sticky`    | The job prefers replicas, but switches to the primary for writes or when encountering replication lag. It should be used for jobs that require to be executed as fast as possible but can sustain a small initial queuing delay.  |
| `:delayed`   | The job prefers replicas, but switches to the primary for writes. When encountering replication lag before the job starts, the job is retried once. If the replica is still not up to date on the next retry, it switches to the primary. It should be used for jobs where delaying execution further typically does not matter, such as cache expiration or web hooks execution. |

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

For [idempotent jobs](#idempotent-jobs), the deduplication is not compatible with the
`data_consistency` attribute set to `:sticky` or `:delayed`.
The reason for this is that deduplication always takes into account the latest binary replication pointer into account, not the first one.
There is an [open issue](https://gitlab.com/gitlab-org/gitlab/-/issues/325291) to improve this.

### `feature_flag` property

The `feature_flag` property allows you to toggle a job's `data_consistency`,
which permits you to safely toggle load balancing capabilities for a specific job.
When `feature_flag` is disabled, the job defaults to `:always`, which means that the job will always use the primary database.

The `feature_flag` property does not allow the use of
[feature gates based on actors](../development/feature_flags/index.md).
This means that the feature flag cannot be toggled only for particular
projects, groups, or users, but instead, you can safely use [percentage of time rollout](../development/feature_flags/index.md).
Note that since we check the feature flag on both Sidekiq client and server, rolling out a 10% of the time,
will likely results in 1% (`0.1` `[from client]*0.1` `[from server]`) of effective jobs using replicas.

Example:

```ruby
class DelayedWorker
  include ApplicationWorker

  data_consistency :delayed, feature_flag: :load_balancing_for_delayed_worker

  # ...
end
```

## Jobs with External Dependencies

Most background jobs in the GitLab application communicate with other GitLab
services. For example, PostgreSQL, Redis, Gitaly, and Object Storage. These are considered
to be "internal" dependencies for a job.

However, some jobs are dependent on external services in order to complete
successfully. Some examples include:

1. Jobs which call web-hooks configured by a user.
1. Jobs which deploy an application to a k8s cluster configured by a user.

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

Note that memory-bound workers create heavy GC workloads, with pauses of
10-50ms. This has an impact on the latency requirements for the
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
- Note that these values should not be used over small sample sizes, but
  rather over fairly large aggregates.

## Feature category

All Sidekiq workers must define a known [feature
category](feature_categorization/index.md#sidekiq-workers).

## Job weights

Some jobs have a weight declared. This is only used when running Sidekiq
in the default execution mode - using
[`sidekiq-cluster`](../administration/operations/extra_sidekiq_processes.md)
does not account for weights.

As we are [moving towards using `sidekiq-cluster` in
Free](https://gitlab.com/gitlab-org/gitlab/-/issues/34396), newly-added
workers do not need to have weights specified. They can use the
default weight, which is 1.

## Worker context

> - [Introduced](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/9) in GitLab 12.8.

To have some more information about workers in the logs, we add
[metadata to the jobs in the form of an
`ApplicationContext`](logging.md#logging-context-metadata-through-rails-or-grape-requests).
In most cases, when scheduling a job from a request, this context is already
deducted from the request and added to the scheduled job.

When a job runs, the context that was active when it was scheduled
is restored. This causes the context to be propagated to any job
scheduled from within the running job.

All this means that in most cases, to add context to jobs, we don't
need to do anything.

There are however some instances when there would be no context
present when the job is scheduled, or the context that is present is
likely to be incorrect. For these instances, we've added Rubocop rules
to draw attention and avoid incorrect metadata in our logs.

As with most our cops, there are perfectly valid reasons for disabling
them. In this case it could be that the context from the request is
correct. Or maybe you've specified a context already in a way that
isn't picked up by the cops. In any case, leave a code comment
pointing to which context to use when disabling the cops.

When you do provide objects to the context, make sure that the
route for namespaces and projects is pre-loaded. This can be done by using
the `.with_route` scope defined on all `Routable`s.

### Cron workers

The context is automatically cleared for workers in the cronjob queue
(`include CronjobQueue`), even when scheduling them from
requests. We do this to avoid incorrect metadata when other jobs are
scheduled from the cron worker.

Cron workers themselves run instance wide, so they aren't scoped to
users, namespaces, projects, or other resources that should be added to
the context.

However, they often schedule other jobs that _do_ require context.

That is why there needs to be an indication of context somewhere in
the worker. This can be done by using one of the following methods
somewhere within the worker:

1. Wrap the code that schedules jobs in the `with_context` helper:

   ```ruby
     def perform
       deletion_cutoff = Gitlab::CurrentSettings
                           .deletion_adjourned_period.days.ago.to_date
       projects = Project.with_route.with_namespace
                    .aimed_for_deletion(deletion_cutoff)

       projects.find_each(batch_size: 100).with_index do |project, index|
         delay = index * INTERVAL

         with_context(project: project) do
           AdjournedProjectDeletionWorker.perform_in(delay, project.id)
         end
       end
     end
   ```

1. Use the a batch scheduling method that provides context:

   ```ruby
     def schedule_projects_in_batch(projects)
       ProjectImportScheduleWorker.bulk_perform_async_with_contexts(
         projects,
         arguments_proc: -> (project) { project.id },
         context_proc: -> (project) { { project: project } }
       )
     end
   ```

   Or, when scheduling with delays:

   ```ruby
     diffs.each_batch(of: BATCH_SIZE) do |diffs, index|
       DeleteDiffFilesWorker
         .bulk_perform_in_with_contexts(index *  5.minutes,
                                        diffs,
                                        arguments_proc: -> (diff) { diff.id },
                                        context_proc: -> (diff) { { project: diff.merge_request.target_project } })
     end
   ```

### Jobs scheduled in bulk

Often, when scheduling jobs in bulk, these jobs should have a separate
context rather than the overarching context.

If that is the case, `bulk_perform_async` can be replaced by the
`bulk_perform_async_with_context` helper, and instead of
`bulk_perform_in` use `bulk_perform_in_with_context`.

For example:

```ruby
    ProjectImportScheduleWorker.bulk_perform_async_with_contexts(
      projects,
      arguments_proc: -> (project) { project.id },
      context_proc: -> (project) { { project: project } }
    )
```

Each object from the enumerable in the first argument is yielded into 2
blocks:

- The `arguments_proc` which needs to return the list of arguments the
  job needs to be scheduled with.

- The `context_proc` which needs to return a hash with the context
  information for the job.

## Arguments logging

As of GitLab 13.6, Sidekiq job arguments are logged by default, unless [`SIDEKIQ_LOG_ARGUMENTS`](../administration/troubleshooting/sidekiq.md#log-arguments-to-sidekiq-jobs)
is disabled.

By default, the only arguments logged are numeric arguments, because
arguments of other types could contain sensitive information. To
override this, use `loggable_arguments` inside a worker with the indexes
of the arguments to be logged. (Numeric arguments do not need to be
specified here.)

For example:

```ruby
class MyWorker
  include ApplicationWorker

  loggable_arguments 1, 3

  # object_id will be logged as it's numeric
  # string_a will be logged due to the loggable_arguments call
  # string_b will be filtered from logs
  # string_c will be logged due to the loggable_arguments call
  def perform(object_id, string_a, string_b, string_c)
  end
end
```

## Tests

Each Sidekiq worker must be tested using RSpec, just like any other class. These
tests should be placed in `spec/workers`.

## Sidekiq Compatibility across Updates

Keep in mind that the arguments for a Sidekiq job are stored in a queue while it
is scheduled for execution. During a online update, this could lead to several
possible situations:

1. An older version of the application publishes a job, which is executed by an
   upgraded Sidekiq node.
1. A job is queued before an upgrade, but executed after an upgrade.
1. A job is queued by a node running the newer version of the application, but
   executed on a node running an older version of the application.

### Adding new workers

On GitLab.com, we [do not currently have a Sidekiq deployment in the
canary stage](https://gitlab.com/gitlab-org/gitlab/-/issues/19239). This
means that a new worker than can be scheduled from an HTTP endpoint may
be scheduled from canary but not run on Sidekiq until the full
production deployment is complete. This can be several hours later than
scheduling the job. For some workers, this will not be a problem. For
others - particularly [latency-sensitive
jobs](#latency-sensitive-jobs) - this will result in a poor user
experience.

This only applies to new worker classes when they are first introduced.
As we recommend [using feature flags](feature_flags/) as a general
development process, it's best to control the entire change (including
scheduling of the new Sidekiq worker) with a feature flag.

### Changing the arguments for a worker

Jobs need to be backward and forward compatible between consecutive versions
of the application. Adding or removing an argument may cause problems
during deployment before all Rails and Sidekiq nodes have the updated code.

#### Deprecate and remove an argument

**Before you remove arguments from the `perform_async` and `perform` methods.**, deprecate them. The
following example deprecates and then removes `arg2` from the `perform_async` method:

1. Provide a default value (usually `nil`) and use a comment to mark the
   argument as deprecated in the coming minor release. (Release M)

    ```ruby
    class ExampleWorker
      # Keep arg2 parameter for backwards compatibility.
      def perform(object_id, arg1, arg2 = nil)
        # ...
      end
    end
    ```

1. One minor release later, stop using the argument in `perform_async`. (Release M+1)

    ```ruby
    ExampleWorker.perform_async(object_id, arg1)
    ```

1. At the next major release, remove the value from the worker class. (Next major release)

    ```ruby
    class ExampleWorker
      def perform(object_id, arg1)
        # ...
      end
    end
    ```

#### Add an argument

There are two options for safely adding new arguments to Sidekiq workers:

1. Set up a [multi-step deployment](#multi-step-deployment) in which the new argument is first added to the worker.
1. Use a [parameter hash](#parameter-hash) for additional arguments. This is perhaps the most flexible option.

##### Multi-step deployment

This approach requires multiple releases.

1. Add the argument to the worker with a default value (Release M).

    ```ruby
    class ExampleWorker
      def perform(object_id, new_arg = nil)
        # ...
      end
    end
    ```

1. Add the new argument to all the invocations of the worker (Release M+1).

    ```ruby
    ExampleWorker.perform_async(object_id, new_arg)
    ```

1. Remove the default value (Release M+2).

    ```ruby
    class ExampleWorker
      def perform(object_id, new_arg)
        # ...
      end
    end
    ```

##### Parameter hash

This approach doesn't require multiple releases if an existing worker already
uses a parameter hash.

1. Use a parameter hash in the worker to allow future flexibility.

    ```ruby
    class ExampleWorker
      def perform(object_id, params = {})
        # ...
      end
    end
    ```

### Removing workers

Try to avoid removing workers and their queues in minor and patch
releases.

During online update instance can have pending jobs and removing the queue can
lead to those jobs being stuck forever. If you can't write migration for those
Sidekiq jobs, please consider removing the worker in a major release only.

### Renaming queues

For the same reasons that removing workers is dangerous, care should be taken
when renaming queues.

When renaming queues, use the `sidekiq_queue_migrate` helper migration method
in a **post-deployment migration**:

```ruby
class MigrateTheRenamedSidekiqQueue < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  def up
    sidekiq_queue_migrate 'old_queue_name', to: 'new_queue_name'
  end

  def down
    sidekiq_queue_migrate 'new_queue_name', to: 'old_queue_name'
  end
end

```

You must rename the queue in a post-deployment migration not in a normal
migration. Otherwise, it runs too early, before all the workers that
schedule these jobs have stopped running. See also [other examples](post_deployment_migrations.md#use-cases).
