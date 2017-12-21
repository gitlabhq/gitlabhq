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

## Queue Namespaces

While different workers cannot share a queue, they can share a queue namespace.

Defining a queue namespace for a worker makes it possible to start a Sidekiq
process that automatically handles jobs for all workers in that namespace,
without needing to explicitly list all their queue names. If, for example, all
workers that are managed by sidekiq-cron use the `cronjob` queue namespace, we
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

## Versioning

In an environment where different versions of GitLab may be running at the same time,
newer GitLabs may enqueue Sidekiq jobs that will be dequeued by an older GitLab
that doesn't have the relevant worker class yet, or that has an older version with
a different set of arguments.

In vanilla Sidekiq, a job like this would fail, be pushed back on the queue to be
retried (if retries for the worker in question aren't disabled to begin with),
and would then be picked up again and again by GitLabs that cannot process it
until it is ultimately marked by Sidekiq as "dead" and never retried again.

To prevent this from happening, every worker class has a version number set that
is sent along with any job the worker queues. When the job is then dequeued by a
Sidekiq that doesn't know the worker at all, or that has a version of the worker
with a lower version than the job version, the job is requeued onto a
version-specific queue that is only listened on by Sidekiqs that actually support
that version, because they have a higher or equal version of the worker class.

Version queues are constructed by taking the base queue name and appending `:vN`,
where `N` is the worker/job version.

When a Sidekiq process starts, it will listen on all queues specified in the `-q`
option, and on the version queues for the current versions of the workers
those queues belong to. On top of that, it will read the list of all queues Sidekiq
is aware of from Redis, to see if Sidekiq is tracking any version queues for
older versions of these workers, that may contain or receive jobs that Sidekiq
is also capable of processing. If any of these are found, they are also listened on.

Sidekiq will then add all of these queues it's listening on to Sidekiq's queue
list, including version queues, so that other Sidekiq processes can discover
version queues they should listen on (if they support the version) or that they
could requeue jobs on (if they don't).

When a Sidekiq process picks up a job that it doesn't support, either because it
doesn't know the worker at all, or because it has a version of the worker with a
lower version than the job version, the job is requeued on a specific version
queue. However, this version queue is not always the version queue for the exact
version that the job itself references.

To determine the version queue to requeue a job on, the Sidekiq process will
read the list of all queues Sidekiq is aware of from Redis, and will find the
_lowest_ version queue for the worker in question that has a version that's
equal to or higher than the job version. This means that if a Sidekiq with a
worker with version 29 picks up a job for version 30 of that worker, it may be
requeued on the queue for version 31 if Sidekiq is only aware of machines
listening on queues for versions 29 and 31. Perhaps, the machine with worker
version 30 that enqueued the job was immediately killed and replaced with a
worker with version 31 because version 30 contained some critical bug.

If the job had been requeued onto the queue for version 30 which no one was
listening on at that time, it would not get picked up until a new Sidekiq process
with version 30 or above got started, that would find out about the queue from
Sidekiq's list of all queues.

Under this schema, any worker is expected to be able to handle any job that was
enqueued by an older version of that worker. This means that when changing the
arguments a worker takes, you should increment the `version` (or set `version 1`
if this is the first time a worker's arguments are changing), but also make sure
that the worker is still able to handle jobs that were queued with any earlier
version of the arguments. From the worker's `perform` method, you can read
`self.job_version` if you want to specifically branch on job version, or you
simply go off the number or type of provided arguments.

For an example of a worker that supports multiple versions and has tests to
prove it, check out `RepositoryForkWorker` and its spec.

## Tests

Each Sidekiq worker must be tested using RSpec, just like any other class. These
tests should be placed in `spec/workers`.

## Removing or renaming queues

Try to avoid renaming or removing workers and their queues in minor and patch releases.
During online update instance can have pending jobs and removing the queue can
lead to those jobs being stuck forever. If you can't write migration for those
Sidekiq jobs, please consider doing rename or remove queue in major release only.
