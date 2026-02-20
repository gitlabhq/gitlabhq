---
stage: Database Excellence
group: Database Frameworks
info: 'See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines'
title: Background operations
---

Background operations provide a framework for performing large-scale
data operations on GitLab databases. Unlike
[batched background migrations](batched_background_migrations.md) (BBM), which run
once to completion during upgrades, background operations support both
recurring cron-scheduled execution and on-demand programmatic execution via
the `.enqueue` API.

For one-time data migrations tied to a release, use
[batched background migrations](batched_background_migrations.md) instead.

## When to use background operations

Use a background operation when you need to perform a data operation on
a large table that cannot complete within a single execution window.

Background operations are appropriate when:

- Deleting or updating rows on a recurring schedule (for example, purging stale data).
- Performing ongoing data hygiene that must run continuously, not just during upgrades.
- Triggering a one-off large-scale data operation programmatically from application code.
- Operating on [high-traffic tables](../migration_style_guide.md#high-traffic-tables)
  where a single pass would exceed safe execution time.

Do **not** use background operations for schema changes or operations
that can complete within
[regular migration time limits](../migration_style_guide.md#how-long-a-migration-should-take).

## How background operations work

A background operation is a subclass of
`Gitlab::BackgroundOperation::BaseOperationWorker` that defines a `perform`
method. Operations can be scheduled in two ways:

- **Cron-based**: A cron job (`Database::BackgroundOperation::CronEnqueueWorker`)
  triggers the operation on a configured schedule.
- **On-demand**: Application code calls `Worker.enqueue` to create and execute
  the operation programmatically.

Each invocation processes a batch of rows using cursor-based keyset iteration,
picks up where the last run left off, and yields sub-batches to user-defined logic.

All operation classes must be defined in the namespace
`Gitlab::BackgroundOperation`. Place files in the directory
`lib/gitlab/background_operation/`.

### Execution mechanism

Background operations follow the same execution pipeline as BBM
(Scheduler → Orchestrator → Runner → Executor). See the
[BBM execution mechanism](batched_background_migrations.md#execution-mechanism)
for details. The key difference is that background operations use cursor-based
keyset pagination instead of primary key range batching.

The worker tables are list-partitioned for lock-free concurrent execution.
A partial unique index on unfinished statuses prevents duplicate operations
with the same configuration.

### Organization-scoped and cell-local tables

Two table variants exist:

- `background_operation_workers` stores organization-scoped operations. These
  records require `organization_id` and `user_id` and are created when a user
  triggers an action (for example, via `.enqueue` with a `user:` parameter).
- `background_operation_workers_cell_local` stores cell-local operations without
  organization context. These records are typically created by cron jobs that
  perform system-wide maintenance tasks.

The same split applies to the jobs tables (`background_operation_jobs` and
`background_operation_jobs_cell_local`).

### What happens when organizations move

When an organization moves to a different cell, the records in
`background_operation_workers` move with it because they are scoped by
`organization_id`. Any in-progress operation resumes on the new cell from its
stored cursor position. Cell-local records in
`background_operation_workers_cell_local` are not affected by organization
moves — they remain on the cell where they were created.

### Duplicate detection

A partial unique index on unfinished statuses (`queued`, `active`, `on_hold`)
prevents multiple operations with the same configuration from running
concurrently. This is necessary because running duplicate operations on the
same table and column range would cause redundant work, increase database load,
and risk data integrity issues from concurrent mutations on the same rows.

When using `.enqueue`, the framework checks for existing unfinished operations
with the same configuration (`job_class_name`, `table_name`, `column_name`,
`job_arguments`). If a duplicate is found, the enqueue is skipped and a warning
is logged. Operations in `finished` or `failed` status do not block new enqueues.

### Idempotence

Background operation workers execute within Sidekiq. Jobs must be idempotent.
Design your `perform` method so that re-processing the same rows produces
the same outcome.

### Throttling and isolation

Background operations share the same
[database health checks](batched_background_migrations.md#throttling-batched-migrations)
and [isolation constraints](batched_background_migrations.md#isolation) as BBM.

## How to

### Schedule via cron (recurring operations)

Use cron scheduling for operations that must run indefinitely on a fixed
interval — for example, purging expired data every hour.

#### 1. Define the operation class

Create a file in `lib/gitlab/background_operation/`:

```ruby
# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    class UsersDeleteUnconfirmedSecondaryEmails < BaseOperationWorker
      operation_name :delete_all
      feature_category :user_management
      cursor :id

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('created_at < ? AND confirmed_at IS NULL', created_cut_off)
            .delete_all
        end
      end

      private

      def created_cut_off
        ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS.days.ago
      end
    end
  end
end
```

Key DSL methods:

- `operation_name`: A symbol describing the SQL operation (for example, `:delete_all`,
  `:update_all`). Used for instrumentation.
- `feature_category`: The feature category that owns this operation.
- `cursor`: One or more column names used for keyset pagination. Use the table's
  primary key. For composite primary keys: `cursor :partition_id, :id`.

#### 2. Configure the cron job

Add the cron schedule to `config/initializers/1_settings.rb`:

```ruby
Settings.cron_jobs['bbo_users_delete_unconfirmed_secondary'] ||= {}
Settings.cron_jobs['bbo_users_delete_unconfirmed_secondary']['cron'] ||= '0 * * * *'
Settings.cron_jobs['bbo_users_delete_unconfirmed_secondary']['job_class'] = 'Database::BackgroundOperation::CronEnqueueWorker'
Settings.cron_jobs['bbo_users_delete_unconfirmed_secondary']['args'] = {
  'job_class_name' => 'UsersDeleteUnconfirmedSecondaryEmails',
  'table_name' => 'emails',
  'column_name' => 'id'
}
```

Configuration fields:

- `cron`: Standard cron expression for the schedule.
- `job_class`: Always `Database::BackgroundOperation::CronEnqueueWorker`.
- `args`: A hash containing:
  - `job_class_name`: The class name of your operation (without the
    `Gitlab::BackgroundOperation::` prefix).
  - `table_name`: The database table to iterate over.
  - `column_name`: The column used for cursor-based iteration.

### Schedule via enqueue (on-demand operations)

Use `.enqueue` for operations triggered programmatically — for example, a bulk
cleanup initiated by application logic or a service.

```ruby
Gitlab::Database::BackgroundOperation::Worker.enqueue(
  'MyOperationClass',
  'target_table',
  'id',
  job_arguments: %w[arg1 arg2],
  user: current_user
)
```

Parameters:

- `job_class_name`: The operation class name.
- `table_name`: The database table to iterate over.
- `column_name`: The cursor column.
- `job_arguments` (optional): An array of string arguments. Defaults to `[]`.
- `user`: The user initiating the operation. Sets `user_id` and
  `organization_id` on the record.

The framework automatically checks for duplicates, estimates
`total_tuple_count` via `pg_class`, sets default batch parameters, and resolves
the correct database connection based on the table's `gitlab_schema`.

For operations without organization context, use `WorkerCellLocal`:

```ruby
Gitlab::Database::BackgroundOperation::WorkerCellLocal.enqueue(
  'MyOperationClass',
  'target_table',
  'id'
)
```

## Monitoring

Background operations emit structured logs and Prometheus metrics for
observability.

### Structured logs

The framework logs events to `Gitlab::AppLogger` on state transitions and
batch size optimizations. Filter by the following `message` values:

- `background_operation_worker_transition_event`: Logged when an operation
  changes state (for example, `queued` → `active`, `active` → `finished`).
  Includes `job_class_name`, `table_name`, `previous_state`, and `new_state`.
- `background_operation_job_transition_event`: Logged when an individual job
  changes state. Includes `attempts`, `exception_class`, and
  `exception_message` on failure.
- `background_operation_worker_optimization_event`: Logged when the batch size
  is adjusted. Includes `old_batch_size` and `new_batch_size`.

### Prometheus metrics

The following metrics are exported after each job execution:

| Metric | Type | Description |
|---|---|---|
| `background_operation_job_batch_size` | Gauge | Current batch size |
| `background_operation_job_sub_batch_size` | Gauge | Current sub-batch size |
| `background_operation_job_interval_seconds` | Gauge | Interval between batches |
| `background_operation_job_duration_seconds` | Gauge | Duration of the last job |
| `background_operation_job_updated_tuples_total` | Counter | Cumulative tuples processed |
| `background_operation_job_query_duration_seconds` | Histogram | Query timings per operation |
| `background_operation_worker_migrated_tuples_total` | Gauge | Total tuples migrated so far |
| `background_operation_worker_total_tuple_count` | Gauge | Estimated total tuples to process |
| `background_operation_worker_last_update_time_seconds` | Gauge | Unix timestamp of last update |

All metrics are labeled with `migration_id` and `migration_identifier`
(`job_class_name/table_name.column_name`).
