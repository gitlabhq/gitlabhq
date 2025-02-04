---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Sidekiq limited capacity worker
---

NOTE:
The following documentation for limited capacity worker relates to a specific
type of worker that usually does not take arguments but instead gets work from
a custom queue (e.g. a PostgresSQL backlog of work). It cannot be used for
throttling normal Sidekiq workers. To restrict the concurrency of a normal
Sidekiq worker you can use a [concurrency limit](worker_attributes.md#concurrency-limit).

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

To queue this worker, use
`MyDummyWorker.perform_with_capacity(*args)`. The `*args` passed to this worker
are passed to the `perform_work` method. Due to the way this job throttles
and requeues itself, it is expected that you always provide the same
`*args` in every usage. In practice, this type of worker is often not
used with arguments and must instead consume a workload stored
elsewhere (like in PostgreSQL). This design also means it is unsuitable to
take a normal Sidekiq workload with arguments and make it a
`LimitedCapacity::Worker`. Instead, to use this, you might need to
re-architect your queue to be stored elsewhere.

A common use case for this kind of worker is one that runs periodically
consuming a separate queue of work to be done (like from PostgreSQL). In that case,
you need an additional cron worker to start the worker periodically. For
example, in the following scheduler:

```ruby
class ScheduleMyDummyCronWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    MyDummyWorker.perform_with_capacity
  end
end
```

## How many jobs are running?

It runs `max_running_jobs` at almost all times.

The cron worker checks the remaining capacity on each execution and it
schedules at most `max_running_jobs` jobs. Those jobs on completion
re-enqueue themselves immediately, but not on failure. The cron worker is in
charge of replacing those failed jobs.

## Handling errors and idempotence

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

## Metrics

This concern exposes three Prometheus metrics of gauge type with the worker class
name as label:

- `limited_capacity_worker_running_jobs`
- `limited_capacity_worker_max_running_jobs`
- `limited_capacity_worker_remaining_work_count`
