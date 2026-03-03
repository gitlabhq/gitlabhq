---
stage: Platforms
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
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

The Apdex SLI measures task completion performance with a **30-minute (1800 second) threshold**.
This threshold aligns with the indexing timeout to ensure consistency with task execution limits.

The following metrics track Apdex:

- `gitlab_sli_search_zoekt_tasks_apdex_total`: Counter for total number of completed tasks.
- `gitlab_sli_search_zoekt_tasks_apdex_success_total`: Counter for tasks that completed
  within the 30-minute threshold.

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
