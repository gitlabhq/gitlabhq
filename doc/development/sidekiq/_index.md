---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Sidekiq development guidelines
---

We use [Sidekiq](https://github.com/mperham/sidekiq) as our background
job processor. These guides are for writing jobs that work well on
GitLab.com and are consistent with our existing worker classes. For
information on administering GitLab, see [configuring Sidekiq](../../administration/sidekiq/_index.md).

There are pages with additional detail on the following topics:

1. [Compatibility across updates](compatibility_across_updates.md)
1. [Job idempotence and job deduplication](idempotent_jobs.md)
1. [Limited capacity worker: continuously performing work with a specified concurrency](limited_capacity_worker.md)
1. [Logging](logging.md)
1. [Worker attributes](worker_attributes.md)
   1. **Job urgency** specifies queuing and execution SLOs
   1. **Resource boundaries** and **external dependencies** for describing the workload
   1. **Feature categorization**
   1. **Database load balancing**

## ApplicationWorker

All workers should include `ApplicationWorker` instead of `Sidekiq::Worker`,
which adds some convenience methods and automatically sets the queue based on
the [routing rules](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules).

## Sharding

All calls to Sidekiq APIs must account for sharding. To achieve this,
utilize the Sidekiq API within the `Sidekiq::Client.via` block to guarantee the correct `Sidekiq.redis` pool is utilized.
Obtain the suitable Redis pool by invoking the `Gitlab::SidekiqSharding::Router.get_shard_instance` method.

```ruby
pool_name, pool = Gitlab::SidekiqSharding::Router.get_shard_instance(worker_class.sidekiq_options['store'])
Sidekiq::Client.via(pool) do
  ...
end
```

Unrouted Sidekiq calls are caught by the validator in all API requests, Sidekiq jobs on the server-side and in tests.
We recommend writing application logic with the use of the `Gitlab::SidekiqSharding::Router`. However, since sharding is an
unreleased feature, if the component does not affect GitLab.com, it is acceptable run it within a `.allow_unrouted_sidekiq_calls` scope like so:

```ruby
# Add a comment explaining why it is safe to allow unrouted Sidekiq calls in this case
Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
  # your unrouted logic
end
```

A past example is the use of `allow_unrouted_sidekiq_calls` in [Geo Rake tasks](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149958#note_1906072228)
as it does not affect GitLab.com. However, developer should write shard-aware code where possible since
that is a pre-requisite for sharding to be [released as a feature to users on GitLab Self-Managed](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430).

## Retries

Sidekiq defaults to using [25 retries](https://github.com/mperham/sidekiq/wiki/Error-Handling#automatic-job-retry),
with back-off between each retry. 25 retries means that the last retry
would happen around three weeks after the first attempt (assuming all 24
prior retries failed).

This means that a lot can happen in between the job being scheduled
and its execution. Therefore, we must guard workers so they don't
fail 25 times when the state changes after they are scheduled. For
example, a job should not fail when the project it was scheduled for
is deleted.

Instead of:

```ruby
def perform(project_id)
  project = Project.find(project_id)
  # ...
end
```

Do this:

```ruby
def perform(project_id)
  project = Project.find_by_id(project_id)
  return unless project
  # ...
end
```

For most workers - especially [idempotent workers](idempotent_jobs.md) -
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
   fails and the worker retries, the system note is posted again.
1. The worker is a cronjob that runs frequently. For example, if a cron
   job runs every hour, then we don't need to retry beyond an hour
   because we don't need two of the same job running at once.

Each retry for a worker is counted as a failure in our metrics. A worker
which always fails 9 times and succeeds on the 10th would have a 90%
error rate.

If you want to manually retry the worker without tracking the exception in Sentry,
use an exception class inherited from `Gitlab::SidekiqMiddleware::RetryError`.

```ruby
ServiceUnavailable = Class.new(::Gitlab::SidekiqMiddleware::RetryError)

def perform
  ...

  raise ServiceUnavailable if external_service_unavailable?
end
```

## Failure handling

Failures are typically handled by Sidekiq itself, which takes advantage of the inbuilt retry mechanism mentioned above. You should allow exceptions to be raised so that Sidekiq can reschedule the job.

If you need to perform an action when a job fails after all of its retry attempts, add it to the `sidekiq_retries_exhausted` method.

```ruby
sidekiq_retries_exhausted do |msg, ex|
  project = Project.find_by_id(msg['args'].first)
  return unless project

  project.perform_a_rollback # handle the permanent failure
end

def perform(project_id)
  project = Project.find_by_id(project_id)
  return unless project

  project.some_action # throws an exception
end
```

## Concurrency Limit

To prevent system overload and ensure reliable operations, we strongly recommend setting a
[concurrency limit](worker_attributes.md#concurrency-limit) for all workers. Limiting the number of jobs each worker
can schedule helps mitigate the risk of overwhelming the system, which could lead to severe incidents.

This guidance applies both to .com and self-managed customers. A single worker scheduling thousands of jobs can easily disrupt the normal functioning of an SM instance.

{{< alert type="note" >}}

If Sidekiq only has 20 threads and the limit for a specific job is 200 then it will never be able to hit this 200 concurrency so it will not be limited.

{{< /alert >}}

### Static Concurrency Limit

For a static limit, consider the following example:

```ruby
class LimitedWorker
  include ApplicationWorker

  concurrency_limit -> { 100 if Feature.enabled?(:concurrency_limit_some_worker, Feature.current_request) }

  # ...
end
```

{{< alert type="warning" >}}

Use only boolean feature flags (fully on/off) when rolling out the concurrency limit.
Percentage-based rollouts with `Feature.current_request` can cause inconsistent behavior.

{{< /alert >}}

Alternatively, you can set a fixed limit directly:

```ruby
concurrency_limit -> { 250 }
```

{{< alert type="note" >}}

Keep in mind that using a static limit means any updates or changes require merging an MR and waiting for the next deployment to take effect.

{{< /alert >}}

### Instance-Configurable Concurrency Limit

If you want to allow instance administrators to control the concurrency limit:

```ruby
concurrency_limit -> { ApplicationSetting.current.some_feature_concurrent_sidekiq_jobs }
```

This approach also allows having separate limits for .com and GitLab Self-Managed instances. To achieve this, you can:

1. Create a migration to add the configuration option with a default set to the self-managed limit.
1. In the same MR, ship a migration to update the limit for .com only.

### How to pick the limit

To determine an appropriate limit, you can use the `sidekiq: Worker Concurrency Detail` dashboard as a guide in [Grafana](https://dashboards.gitlab.net/goto/z244H0YNR?orgId=1).

{{< alert type="note" >}}

The [concurrency limit may be momentarily exceeded](https://gitlab.com/gitlab-org/gitlab/-/issues/490936#note_2172737349) and should not be relied on as a strict limit.

{{< /alert >}}

## Deferring Sidekiq workers

Sidekiq workers are deferred by two ways,

1. Manual: Feature flags can be used to explicitly defer a particular worker, more details can be found [here](../feature_flags/_index.md#deferring-sidekiq-jobs).
1. Automatic: Similar to the [throttling mechanism](../database/batched_background_migrations.md#throttling-batched-migrations) in batched migrations, database health indicators are used to defer a Sidekiq worker.

   To use the automatic deferring mechanism, worker has to opt-in by calling `defer_on_database_health_signal` with `gitlab_schema`, `delay_by` (time to delay) and tables (which is used by autovacuum db indicator) as it's parameters.

   **Example**:

   ```ruby
    module Chaos
      class SleepWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include ChaosQueue

        defer_on_database_health_signal :gitlab_main, [:users], 1.minute

        def perform(duration_s)
          Gitlab::Chaos.sleep(duration_s)
        end
      end
    end
   ```

For deferred jobs, logs contain the following to indicate the source:

- `job_status`: `deferred`
- `job_deferred_by`: `feature_flag` or `database_health_check`

## Sidekiq Queues

Previously, each worker had its own queue, which was automatically set based on the
worker class name. For a worker named `ProcessSomethingWorker`, the queue name
would be `process_something`. You can now route workers to a specific queue using
[queue routing rules](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules).
In GDK, new workers are routed to a queue named `default`.

If you're not sure what queue a worker uses,
you can find it using `SomeWorker.queue`. There is almost never a reason to
manually override the queue name using `sidekiq_options queue: :some_queue`.

After adding a new worker, run `bin/rake gitlab:sidekiq:all_queues_yml:generate`
to regenerate `app/workers/all_queues.yml` or `ee/app/workers/all_queues.yml` so that
it can be picked up by
[`sidekiq-cluster`](../../administration/sidekiq/extra_sidekiq_processes.md)
in installations that don't use routing rules. For more information about potential changes,
see [epic 596](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/596).

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

Adding a worker to an existing namespace should be done with care, as
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

## Job size

GitLab stores Sidekiq jobs and their arguments in Redis. To avoid
excessive memory usage, we compress the arguments of Sidekiq jobs
if their original size is bigger than 100 KB.

After compression, if their size still exceeds 5 MB, it raises an
[`ExceedLimitError`](https://gitlab.com/gitlab-org/gitlab/-/blob/f3dd89e5e510ea04b43ffdcb58587d8f78a8d77c/lib/gitlab/sidekiq_middleware/size_limiter/exceed_limit_error.rb#L8)
error when scheduling the job.

If this happens, rely on other means of making the data
available in Sidekiq. There are possible workarounds such as:

- Rebuild the data in Sidekiq with data loaded from the database or
  elsewhere.
- Store the data in [object storage](../file_storage.md#object-storage)
  before scheduling the job, and retrieve it inside the job.

## Job weights

Some jobs have a weight declared. This is only used when running Sidekiq
in the default execution mode - using
[`sidekiq-cluster`](../../administration/sidekiq/extra_sidekiq_processes.md)
does not account for weights.

As we are [moving towards using `sidekiq-cluster` in Free](https://gitlab.com/gitlab-org/gitlab/-/issues/34396), newly-added
workers do not need to have weights specified. They can use the
default weight, which is 1.

## Job parameters

Based on [Sidekiq's recommended best practices](https://github.com/sidekiq/sidekiq/wiki/Best-Practices#1-make-your-job-parameters-small-and-simple), parameters should be small and simple.

For a hash passed as a worker parameter, the keys should be strings and the values
should be of native JSON types. If these expectations are not met in Sidekiq versions 7.0 and later,
[exceptions are raised](https://github.com/sidekiq/sidekiq/blob/main/docs/7.0-Upgrade.md#strict-arguments).
We have disabled these exceptions
[and only display warnings](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161262)
in development and test mode, to enable us to upgrade to this version.

Going forward, developers should ensure that the keys and values in worker parameters are of native JSON types.

You are encouraged to add a test for code generating worker parameters. For example, this custom
RSpec matcher `param_containing_valid_native_json_types` (defined in `SidekiqJSONMatcher`)
tests the parameter expected to be an array of hashes:

```ruby
 it 'passes a valid JSON parameter to MyWorker#perform_async' do
  expect(MyWorker).to receive(:perform_async).with(param_containing_valid_native_json_types)

  method_calling_worker_perform_sync
end
```

## Tests

Each Sidekiq worker must be tested using RSpec, just like any other class. These
tests should be placed in `spec/workers`.

## Interacting with Sidekiq Redis and APIs

The application should minimise interaction with of any `Sidekiq.redis` and Sidekiq [APIs](https://github.com/mperham/sidekiq/blob/main/lib/sidekiq/api.rb). Such interactions in generic application logic should be abstracted to a [Sidekiq middleware](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/sidekiq_middleware) for re-use across teams. By decoupling application logic from Sidekiq datastore, it allows for greater freedom when horizontally scaling the GitLab background processing setup.

Some exceptions to this rule would be migration-related logic or administration operations.

## Job duration limit

In general it is best-practice for Sidekiq jobs to run for short durations.

Although there is no specific hard limit for job duration, there are two special considerations for long running jobs:

1. Job durations above our [`urgency` attribute](worker_attributes.md#job-urgency) thresholds contribute negatively to
   [Sidekiq Apdex](../application_slis/sidekiq_execution.md) and can impact error budgets.
1. Deploys interrupt long-running jobs. On GitLab.com, deploys can happen several times a day, which can [effectively limit the length a job can run](#effect-of-deploys-on-job-duration).

### Effect of deploys on job duration

During a deploy, Sidekiq is given a `TERM` signal. Jobs are given 25 seconds to finish, after which they are
interrupted and forced to stop. The 25 second grace period is the
[Sidekiq default](https://github.com/sidekiq/sidekiq/blob/ba51d286d821777fbe87ea0eff8b04f212aeadf5/lib/sidekiq/config.rb#L18) but can be
[configured through the charts](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/d2bb7cca2130cd9859e5d40e5bd90f5ef061d422/vendor/charts/gitlab/gprd/charts/gitlab/charts/sidekiq/values.yaml#L291).

If a job is forced to stop a certain number of times (3 times by default, configurable
through `max_retries_after_interruption`), they are permanently killed. This happens through
our [`sidekiq-reliable-fetch` gem](https://gitlab.com/gitlab-org/gitlab/-/blob/master/vendor/gems/sidekiq-reliable-fetch/README.md).

This effectively puts a limit on the length of time a job can run
to a span of `max_retries_after_interruption` deploys, or 3 deploys by default.

### Tips for handling jobs with long durations

Instead of having one big job, it's better to have many small jobs.

To decide if a worker needs to be split up and parallelized we can look at the runtime of jobs in the logs.
If the 99th percentile of the job duration is lower than the target for that shard based on the configured
[urgency](worker_attributes.md#job-urgency), there is no need to break up the job.

When breaking up long running jobs into many smaller jobs, do take into account downstream dependencies.
For example, if we schedule thousands of jobs that all need to write to the primary database, this
could create contention on connections to the primary database causing other Sidekiq jobs on the shard to
have to wait to obtain a connection. To circumvent this, we can consider specifying a
[concurrency limit](worker_attributes.md#concurrency-limit).
