---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Sidekiq idempotent jobs
---

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

## Ensuring a worker is idempotent

Use the following shared example to see the effects of running a job twice.

```ruby
it_behaves_like 'an idempotent worker'
```

The shared example requires `job_args` to be defined. If not given, it
calls the job without arguments.

When the shared example runs, there should be no mocking in place that would avoid
side-effects of the job. For example, allow the worker to call a service without
stubbing its execute method. This way, we can assert that the job is truly idempotent.

The shared examples include some basic tests. You can add more idempotency tests
specific to the worker in the shared examples block.

```ruby
it_behaves_like 'an idempotent worker' do
  it 'checks the side-effects for multiple calls' do
    # `perform_idempotent_work` will call the job's perform method 2 times
    perform_idempotent_work

    expect(model.state).to eq('state')
  end
end
```

## Declaring a worker as idempotent

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

## Deduplication

When a job for an idempotent worker is enqueued while another
unstarted job is already in the queue, GitLab drops the second
job. The work is skipped because the same work would be
done by the job that was scheduled first; by the time the second
job executed, the first job would do nothing.

### Strategies

GitLab supports two deduplication strategies:

- `until_executing`, which is the default strategy
- `until_executed`

More [deduplication strategies have been suggested](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/195).
If you are implementing a worker that could benefit from a different
strategy, comment in the issue.

#### Until Executing

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

#### Until Executed

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

Also, you can pass `if_deduplicated: :reschedule_once` option to re-run a job once after
the currently running job finished and deduplication happened at least once.
This ensures that the latest result is always produced even if a race condition
happened. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/342123) for more information.

### Scheduling jobs in the future

GitLab doesn't skip jobs scheduled in the future, as we assume that
the state has changed by the time the job is scheduled to
execute. Deduplication of jobs scheduled in the future is possible
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

## Setting the deduplication time-to-live (TTL)

Deduplication depends on an idempotent key that is stored in Redis. This is usually
cleared by the configured deduplication strategy.

However, the key can remain until its TTL in certain cases like:

1. `until_executing` is used but the job was never enqueued or executed after the Sidekiq
   client middleware was run.

1. `until_executed` is used but the job fails to finish due to retry exhaustion, gets
   interrupted the maximum number of times, or gets lost.

The default value is 6 hours. During this time, jobs won't be enqueued even if the first
job never executed or finished.

The TTL can be configured with:

```ruby
class ProjectImportScheduleWorker
  include ApplicationWorker

  idempotent!
  deduplicate :until_executing, ttl: 5.minutes
end
```

Duplicate jobs can happen when the TTL is reached, so make sure you lower this only for jobs
that can tolerate some duplication.

### Preserve the latest WAL location for idempotent jobs

The deduplication always take into account the latest binary replication pointer, not the first one.
This happens because we drop the same job scheduled for the second time and the Write-Ahead Log (WAL) is lost.
This could lead to comparing the old WAL location and reading from a stale replica.

To support both deduplication and maintaining data consistency with load balancing,
we are preserving the latest WAL location for idempotent jobs in Redis.
This way we are always comparing the latest binary replication pointer,
making sure that we read from the replica that is fully caught up.
