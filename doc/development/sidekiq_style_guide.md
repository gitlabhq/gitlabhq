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

You must always add any new queues to `app/workers/all_queues.yml` or `ee/app/workers/all_queues.yml`
otherwise your worker will not run.

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

## Feature Categorization

Each Sidekiq worker, or one of its ancestor classes, must declare a
`feature_category` attribute. This attribute maps each worker to a feature
category. This is done for error budgeting, alert routing, and team attribution
for Sidekiq workers.

The declaration uses the `feature_category` class method, as shown below.

```ruby
class SomeScheduledTaskWorker
  include ApplicationWorker

  # Declares that this feature is part of the
  # `continuous_integration` feature category
  feature_category :continuous_integration

  # ...
end
```

The list of value values can be found in the file `config/feature_categories.yml`.
This file is, in turn generated from the [`stages.yml` from the GitLab Company Handbook
source](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml).

### Updating `config/feature_categories.yml`

Occassionally new features will be added to GitLab stages. When this occurs, you
can automatically update `config/feature_categories.yml` by running
`scripts/update-feature-categories`. This script will fetch and parse
[`stages.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml)
and generare a new version of the file, which needs to be checked into source control.

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

## Tests

Each Sidekiq worker must be tested using RSpec, just like any other class. These
tests should be placed in `spec/workers`.

## Removing or renaming queues

Try to avoid renaming or removing workers and their queues in minor and patch releases.
During online update instance can have pending jobs and removing the queue can
lead to those jobs being stuck forever. If you can't write migration for those
Sidekiq jobs, please consider doing rename or remove queue in major release only.
