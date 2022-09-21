---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Sidekiq limited capacity worker

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
