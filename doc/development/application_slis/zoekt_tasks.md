---
stage: Platforms
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Zoekt tasks SLIs (service level indicators)
---

The Zoekt tasks SLIs track the performance and reliability of asynchronous indexing tasks
for Zoekt code search.

## Metrics

The following metrics are emitted for Zoekt task processing:

### Request rate

- `gitlab_sli_search_zoekt_tasks_requests_total`: Counter that tracks the rate of tasks
  being added to the Zoekt indexing queue. This metric increments when tasks are created
  via `Search::Zoekt::Repository#create_bulk_tasks`.

### Error rate

- `gitlab_sli_search_zoekt_tasks_total`: Counter for total number of task completion attempts.
- `gitlab_sli_search_zoekt_tasks_error_total`: Counter for tasks that reached final failure state
  (after retries exhausted). This metric only increments when a task transitions to the `:failed`
  state, not during intermediate retries.

### Apdex (Application Performance Index)

The Apdex SLI measures task completion performance with a 2-hour (7200 second)
threshold, defined as `APDEX_THRESHOLD_S` in
`ee/lib/gitlab/metrics/zoekt_tasks_slis.rb`.

The following metrics track Apdex:

- `gitlab_sli_search_zoekt_tasks_apdex_total`: Counter for total number of completed tasks.
- `gitlab_sli_search_zoekt_tasks_apdex_success_total`: Counter for tasks that completed
  within the threshold.

### Task duration

The Apdex records only whether a task beat its threshold.
`gitlab_search_zoekt_task_duration_seconds` is a histogram of the same
duration, observed in the same call, so duration quantiles are computable.

Buckets are `1, 5, 10, 30, 60, 120, 300, 600, 1800, 3600, 7200, 21600` seconds.
The exact `60` edge answers a 60-second objective with a bucket read instead of
a quantile interpolated across a bucket.

The duration is `Time.current - task.perform_at`, so it covers queue wait and
execution together: `zoekt_tasks` records no task start time, so the two cannot
be separated.

Each sample also logs a `Zoekt task Apdex SLI` line to `Gitlab::AppJsonLogger`
with `duration_s`, `target_s`, `success`, `zoekt_node`, and `task_type`, so
percentiles are available from logs as well as from the histogram.

## Labels

All metrics include the following labels for detailed analysis:

- `zoekt_node`: The Zoekt node identifier handling the task (from `zoekt_node_id`)
- `task_type`: The operation type, such as:
  - `index_repo`: Full repository indexing
  - `delete_repo`: Repository deletion from index
  - Other task-specific operations

## Example Prometheus queries

### Overall task success rate

```promql
rate(gitlab_sli_search_zoekt_tasks_apdex_success_total[5m])
/
rate(gitlab_sli_search_zoekt_tasks_apdex_total[5m])
```

### Error rate by node

```promql
sum by (zoekt_node) (
  rate(gitlab_sli_search_zoekt_tasks_error_total[5m])
)
/
sum by (zoekt_node) (
  rate(gitlab_sli_search_zoekt_tasks_total[5m])
)
```

### Task duration percentiles

```promql
histogram_quantile(0.99,
  sum by (le, zoekt_node, task_type) (
    rate(gitlab_search_zoekt_task_duration_seconds_bucket[5m])
  )
)
```

### Fraction of tasks completing within 60 seconds

```promql
sum(rate(gitlab_search_zoekt_task_duration_seconds_bucket{le="60"}[5m]))
/
sum(rate(gitlab_search_zoekt_task_duration_seconds_count[5m]))
```

### Task throughput by type

```promql
sum by (task_type) (
  rate(gitlab_sli_search_zoekt_tasks_requests_total[5m])
)
```

### Slow tasks (exceeding Apdex threshold)

```promql
rate(gitlab_sli_search_zoekt_tasks_apdex_total[5m])
-
rate(gitlab_sli_search_zoekt_tasks_apdex_success_total[5m])
```

### Per-node, per-type error rate

```promql
sum by (zoekt_node, task_type) (
  rate(gitlab_sli_search_zoekt_tasks_error_total[5m])
)
```

## Implementation details

The SLI is defined in `Gitlab::Metrics::ZoektTasksSlis` and instrumented at key
points in the task lifecycle:

- **Request rate**: Incremented when tasks are created in `Search::Zoekt::Repository#create_bulk_tasks`
- **Error rate**: Incremented when tasks reach final failure in `Search::Zoekt::CallbackService#process_failure`
- **Apdex**: Recorded when tasks complete successfully in `Search::Zoekt::CallbackService#process_zoekt_success`

For more information about Application SLIs, see the [Application SLI framework documentation](_index.md).
