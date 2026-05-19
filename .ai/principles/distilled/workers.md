---
source_checksum: d8c986681e4fe92c
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# Sidekiq Workers Principles

## Checklist

### Worker Class Structure

- Include `ApplicationWorker` instead of `Sidekiq::Worker` in all workers.
- Set `data_consistency` explicitly on every worker (RuboCop enforces this).
- Define a known `feature_category` on every Sidekiq worker.
- Mark workers as `idempotent!` unless there is a documented reason they cannot be.
- Use `deduplicate :until_executing` (default) or `:until_executed` alongside `idempotent!`; pass `including_scheduled: true` if future-scheduled jobs should also be deduplicated.
- DO NOT mark a worker as both `urgency :high` and `worker_has_external_dependencies!`.
- DO NOT mark a worker as both `urgency :high` and `worker_resource_boundary :memory`.
- Prepend `::Geo::SkipSecondary` to workers that attempt database writes if they can be enqueued on Geo secondary sites.

### Sharding

- Wrap all Sidekiq API calls in `Sidekiq::Client.via(pool)` using `Gitlab::SidekiqSharding::Router.get_shard_instance`.
- Use `Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls` only for components that do not affect GitLab.com; add a comment explaining why it is safe.

### Retries and Failure Handling

- Use `find_by_id` (not `find`) for database lookups in `perform`, and return early if the record is nil, to guard against state changes between scheduling and execution.
- Prefer the default of 25 retries; only lower the retry count for workers contacting external services without delivery guarantees, non-idempotent workers, or high-frequency cron jobs.
- Use an exception class inheriting from `Gitlab::SidekiqMiddleware::RetryError` when retrying without tracking in Sentry.
- Add permanent failure handling to `sidekiq_retries_exhausted`, not inline in `perform`.
- Allow exceptions to propagate so Sidekiq can reschedule; DO NOT swallow exceptions silently.

### Concurrency Limit

- Set a `concurrency_limit` for all workers to prevent system overload.
- Use only boolean (fully on/off) feature flags when rolling out a concurrency limit — DO NOT use percentage-based rollouts with `Feature.current_request`.
- Use a lambda returning `nil` or `0` to disable the limit; use a negative number to pause execution.
- Use `max_concurrency_limit_percentage` to override the default shard capacity percentage when the GitLab.com default is not appropriate for the worker.

### Job Urgency

- Set `urgency :high` only for jobs where median execution time is under 1 second and 99th percentile is under 10 seconds.
- Ping `@gitlab-com/gl-infra/data-access/durability` on the MR when changing a queue's urgency if the expected shard load increase exceeds 5%.

### Data Consistency

- Prefer `data_consistency :sticky` for jobs that must execute quickly.
- Use `data_consistency :delayed` for jobs where delayed execution is acceptable (cache expiration, webhooks); DO NOT use `:delayed` for cron jobs where retry is disabled.
- Use `data_consistency :always` only for jobs with documented edge cases around primary stickiness; it is strongly discouraged.
- Use `overrides:` keyword with `data_consistency` when a worker's database usage is skewed toward a specific decomposed database (e.g., `ci`).
- Use the `feature_flag:` property with `data_consistency` to safely toggle load balancing for a specific job; DO NOT use actor-based feature gates (project, group, user) — use percentage-of-time rollout only.

### Job Parameters

- Ensure hash keys and values in worker parameters are native JSON types (strings, numbers, booleans, arrays, objects, null).
- Add a test using `param_containing_valid_native_json_types` matcher for code that generates worker parameters.
- Order `perform` parameters: highest-level resource IDs → user IDs → lower-level resource IDs → optional config hash.
- Place non-core or frequently-changing parameters inside a trailing hash (`params = {}`) rather than as positional arguments.
- DO NOT refactor existing workers' parameter order or structure (breaks queue compatibility).

### Compatibility Across Updates

- Add new arguments to `perform` with a default value first (Release M), update call sites in Release M+1, remove the default in Release M+2.
- Deprecate removed arguments with a default of `nil` and a comment before removing them across two releases.
- Control new worker scheduling with a feature flag to avoid scheduling before Sidekiq deployment completes.
- When removing a worker: make `perform` a no-op in Release M, add a migration using `sidekiq_remove_jobs` in Release M+1, delete the class in Release M+2.
- Use `sidekiq_queue_migrate` in a **post-deployment migration** (not a standard migration) when renaming queues.
- When renaming a worker class, have the old worker delegate to the new worker's `perform` in Release M, enable scheduling of the new worker in Release M+1, remove the old class in Release M+2.

### Queue and Namespace

- Run `bin/rake gitlab:sidekiq:all_queues_yml:generate` and `bin/rake gitlab:sidekiq:sidekiq_queues_yml:generate` after adding a new worker.
- DO NOT manually override the queue name with `sidekiq_options queue:` unless there is a specific documented reason.
- Use `queue_namespace :cronjob` (via `CronjobQueue`) for cron-scheduled workers.

### Versioning

- Increment `version` on the worker class when changing `perform` arguments, and ensure the worker handles all prior argument formats.

### Job Size

- DO NOT pass large objects as job arguments; if compressed arguments exceed 5 MB, store data in object storage or reload from the database inside the job.

### Logging and Context

- Use `loggable_arguments` to explicitly allowlist non-numeric arguments that are safe to log; DO NOT rely on default logging for string arguments containing sensitive data.
- Wrap job scheduling in `with_context` or use `bulk_perform_async_with_contexts` / `bulk_perform_in_with_contexts` when scheduling from cron workers to propagate correct context.
- Pre-load the route for namespaces and projects (`.with_route`) before passing them to context helpers.

### Deferring Workers

- Use `defer_on_database_health_signal` with `gitlab_schema`, `delay_by`, and `tables` parameters to opt in to automatic deferral based on database health indicators.

### LimitedCapacity::Worker

- Implement `perform_work`, `remaining_work_count`, and `max_running_jobs` when using `LimitedCapacity::Worker`.
- Schedule `LimitedCapacity::Worker` subclasses via `perform_with_capacity`, not `perform_async`; always pass the same `*args` on every invocation.
- Handle all exceptions inside `perform_work`; DO NOT let the job raise, as retries are disabled and failures reduce running capacity until the cron worker refills slots.
- Use a separate cron worker to call `perform_with_capacity` periodically when the worker consumes a workload stored outside Sidekiq (for example, in PostgreSQL).

### Deduplication TTL

- Configure a custom `ttl:` on `deduplicate` only for jobs that can tolerate some duplication; the default is 10 minutes, during which duplicate jobs are suppressed even if the first job never ran.

### Tests

- Place worker tests in `spec/workers` using RSpec.
- Use the `it_behaves_like 'an idempotent worker'` shared example without stubbing service side-effects.

## Authoritative sources

For the full picture, see:

- doc/development/sidekiq/_index.md
- doc/development/sidekiq/worker_attributes.md
- doc/development/sidekiq/idempotent_jobs.md
- doc/development/sidekiq/compatibility_across_updates.md
- doc/development/sidekiq/limited_capacity_worker.md
- doc/development/sidekiq/logging.md

