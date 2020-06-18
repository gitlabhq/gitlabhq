# Sidekiq Style Guide

This document outlines various guidelines that should be followed when adding or
modifying Sidekiq workers.

## ApplicationWorker

All workers should include `ApplicationWorker` instead of `Sidekiq::Worker`,
which adds some convenience methods and automatically sets the queue based on
the worker's name.

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

## Queue Namespaces

While different workers cannot share a queue, they can share a queue namespace.

Defining a queue namespace for a worker makes it possible to start a Sidekiq
process that automatically handles jobs for all workers in that namespace,
without needing to explicitly list all their queue names. If, for example, all
workers that are managed by `sidekiq-cron` use the `cronjob` queue namespace, we
can spin up a Sidekiq process specifically for these kinds of scheduled jobs.
If a new worker using the `cronjob` namespace is added later on, the Sidekiq
process will automatically pick up jobs for that worker too (after having been
restarted), without the need to change any configuration.

A queue namespace can be set using the `queue_namespace` DSL class method:

```ruby
class SomeScheduledTaskWorker
  include ApplicationWorker

  queue_namespace :cronjob

  # ...
end
```

Behind the scenes, this will set `SomeScheduledTaskWorker.queue` to
`cronjob:some_scheduled_task`. Commonly used namespaces will have their own
concern module that can easily be included into the worker class, and that may
set other Sidekiq options besides the queue namespace. `CronjobQueue`, for
example, sets the namespace, but also disables retries.

`bundle exec sidekiq` is namespace-aware, and will automatically listen on all
queues in a namespace (technically: all queues prefixed with the namespace name)
when a namespace is provided instead of a simple queue name in the `--queue`
(`-q`) option, or in the `:queues:` section in `config/sidekiq_queues.yml`.

Note that adding a worker to an existing namespace should be done with care, as
the extra jobs will take resources away from jobs from workers that were already
there, if the resources available to the Sidekiq process handling the namespace
are not adjusted appropriately.

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

NOTE: **Note:**
A job scheduled for an idempotent worker will automatically be
[deduplicated](#deduplication) when an unstarted job with the same
arguments is already in the queue.

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

NOTE: **Note:**
If the worker class is not marked as idempotent, a cop will fail.
Consider skipping the cop if you're not confident your job can safely
run multiple times.

### Deduplication

When a job for an idempotent worker is enqueued while another
unstarted job is already in the queue, GitLab drops the second
job. The work is skipped because the same work would be
done by the job that was scheduled first; by the time the second
job executed, the first job would do nothing.

For example, `AuthorizedProjectsWorker` takes a user ID. When the
worker runs, it recalculates a user's authorizations. GitLab schedules
this job each time an action potentially changes a user's
authorizations. If the same user is added to two projects at the
same time, the second job can be skipped if the first job hasn't
begun, because when the first job runs, it creates the
authorizations for both projects.

GitLab doesn't skip jobs scheduled in the future, as we assume that
the state will have changed by the time the job is scheduled to
execute.

More [deduplication strategies have been suggested](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/195). If you are implementing a worker that
could benefit from a different strategy, please comment in the issue.

If the automatic deduplication were to cause issues in certain
queues. This can be temporarily disabled by enabling a feature flag
named `disable_<queue name>_deduplication`. For example to disable
deduplication for the `AuthorizedProjectsWorker`, we would enable the
feature flag `disable_authorized_projects_deduplication`.

From ChatOps:

```shell
/chatops run feature set disable_authorized_projects_deduplication true
```

From the rails console:

```ruby
Feature.enable!(:disable_authorized_projects_deduplication)
```

## Job urgency

Jobs can have an `urgency` attribute set, which can be `:high`,
`:low`, or `:throttled`. These have the below targets:

| **Urgency**  | **Queue Scheduling Target** | **Execution Latency Requirement**  |
|--------------|-----------------------------|------------------------------------|
| `:high`      | 100 milliseconds            | p50 of 1 second, p99 of 10 seconds |
| `:low`       | 1 minute                    | Maximum run time of 1 hour         |
| `:throttled` | None                        | Maximum run time of 1 hour         |

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
traffic. Some jobs, however, are more sensitive to latency than others. Examples
of these jobs include:

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

## Jobs with External Dependencies

Most background jobs in the GitLab application communicate with other GitLab
services. For example, PostgreSQL, Redis, Gitaly, and Object Storage. These are considered
to be "internal" dependencies for a job.

However, some jobs will be dependent on external services in order to complete
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

NOTE: **Note:** Note that a job cannot be both high urgency and have
external dependencies.

## CPU-bound and Memory-bound Workers

Workers that are constrained by CPU or memory resource limitations should be
annotated with the `worker_resource_boundary` method.

Most workers tend to spend most of their time blocked, wait on network responses
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

If many threads are attempting to run Ruby code simultaneously, this will lead
to contention on the GIL which will have the affect of slowing down all
processes.

In high-traffic environments, knowing that a worker is CPU-bound allows us to
run it on a different fleet with lower concurrency. This ensures optimal
performance.

Likewise, if a worker uses large amounts of memory, we can run these on a
bespoke low concurrency, high memory fleet.

Note that memory-bound workers create heavy GC workloads, with pauses of
10-50ms. This will have an impact on the latency requirements for the
worker. For this reason, `memory` bound, `urgency :high` jobs are not
permitted and will fail CI. In general, `memory` bound workers are
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

## Feature Categorization

Each Sidekiq worker, or one of its ancestor classes, must declare a
`feature_category` attribute. This attribute maps each worker to a feature
category. This is done for error budgeting, alert routing, and team attribution
for Sidekiq workers.

The declaration uses the `feature_category` class method, as shown below.

```ruby
class SomeScheduledTaskWorker
  include ApplicationWorker

  # Declares that this worker is part of the
  # `continuous_integration` feature category
  feature_category :continuous_integration

  # ...
end
```

The list of value values can be found in the file `config/feature_categories.yml`.
This file is, in turn generated from the [`stages.yml` from the GitLab Company Handbook
source](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml).

### Updating `config/feature_categories.yml`

Occasionally new features will be added to GitLab stages. When this occurs, you
can automatically update `config/feature_categories.yml` by running
`scripts/update-feature-categories`. This script will fetch and parse
[`stages.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml)
and generate a new version of the file, which needs to be checked into source control.

### Excluding Sidekiq workers from feature categorization

A few Sidekiq workers, that are used across all features, cannot be mapped to a
single category. These should be declared as such using the `feature_category_not_owned!`
 declaration, as shown below:

```ruby
class SomeCrossCuttingConcernWorker
  include ApplicationWorker

  # Declares that this worker does not map to a feature category
  feature_category_not_owned!

  # ...
end
```

## Job weights

Some jobs have a weight declared. This is only used when running Sidekiq
in the default execution mode - using
[`sidekiq-cluster`](../administration/operations/extra_sidekiq_processes.md)
does not account for weights.

As we are [moving towards using `sidekiq-cluster` in
Core](https://gitlab.com/gitlab-org/gitlab/-/issues/34396), newly-added
workers do not need to have weights specified. They can simply use the
default weight, which is 1.

## Worker context

To have some more information about workers in the logs, we add
[metadata to the jobs in the form of an
`ApplicationContext`](logging.md#logging-context-metadata-through-rails-or-grape-requests).
In most cases, when scheduling a job from a request, this context will
already be deducted from the request and added to the scheduled
job.

When a job runs, the context that was active when it was scheduled
will be restored. This causes the context to be propagated to any job
scheduled from within the running job.

All this means that in most cases, to add context to jobs, we don't
need to do anything.

There are however some instances when there would be no context
present when the job is scheduled, or the context that is present is
likely to be incorrect. For these instances we've added rubocop-rules
to draw attention and avoid incorrect metadata in our logs.

As with most our cops, there are perfectly valid reasons for disabling
them. In this case it could be that the context from the request is
correct. Or maybe you've specified a context already in a way that
isn't picked up by the cops. In any case, please leave a code-comment
pointing to which context will be used when disabling the cops.

When you do provide objects to the context, please make sure that the
route for namespaces and projects is pre-loaded. This can be done using
the `.with_route` scope defined on all `Routable`s.

### Cron-Workers

The context is automatically cleared for workers in the cronjob-queue
(which `include CronjobQueue`), even when scheduling them from
requests. We do this to avoid incorrect metadata when other jobs are
scheduled from the cron-worker.

Cron-Workers themselves run instance wide, so they aren't scoped to
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

or when scheduling with delays:

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

The `arguments_proc` which needs to return the list of arguments the
job needs to be scheduled with.

The `context_proc` which needs to return a hash with the context
information for the job.

## Arguments logging

When [`SIDEKIQ_LOG_ARGUMENTS`](../administration/troubleshooting/sidekiq.md#log-arguments-to-sidekiq-jobs)
is enabled, Sidekiq job arguments will be logged.

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

### Changing the arguments for a worker

Jobs need to be backward and forward compatible between consecutive versions
of the application. Adding or removing an argument may cause problems
during deployment before all Rails and Sidekiq nodes have the updated code.

#### Remove an argument

**Do not remove arguments from the `perform` function.**. Instead, use the
following approach:

1. Provide a default value (usually `nil`) and use a comment to mark the
   argument as deprecated
1. Stop using the argument in `perform_async`.
1. Ignore the value in the worker class, but do not remove it until the next
   major release.

In the following example, if you want to remove `arg2`, first set a `nil` default value,
and then update locations where `ExampleWorker.perform_async` is called.

```ruby
class ExampleWorker
  def perform(object_id, arg1, arg2 = nil)
    # ...
  end
end
```

#### Add an argument

There are two options for safely adding new arguments to Sidekiq workers:

1. Set up a [multi-step deployment](#multi-step-deployment) in which the new argument is first added to the worker
1. Use a [parameter hash](#parameter-hash) for additional arguments. This is perhaps the most flexible option.
1. Use a parameter hash for additional arguments. This is perhaps the most flexible option.

##### Multi-step deployment

This approach requires multiple merge requests and for the first merge request
to be merged and deployed before additional changes are merged.

1. In an initial merge request, add the argument to the worker with a default
   value:

    ```ruby
    class ExampleWorker
      def perform(object_id, new_arg = nil)
        # ...
      end
    end
    ```

1. Merge and deploy the worker with the new argument.
1. In a further merge request, update `ExampleWorker.perform_async` calls to
   use the new argument.

##### Parameter hash

This approach will not require multiple deployments if an existing worker already
utilizes a parameter hash.

1. Use a parameter hash in the worker to allow for future flexibility:

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

When renaming queues, use the `sidekiq_queue_migrate` helper migration method,
as show in this example:

```ruby
class MigrateTheRenamedSidekiqQueue < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'old_queue_name', to: 'new_queue_name'
  end

  def down
    sidekiq_queue_migrate 'new_queue_name', to: 'old_queue_name'
  end
end

```
