---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Monitoring Gitaly
---

Use the available logs and [Prometheus metrics](../monitoring/prometheus/_index.md) to monitor Gitaly.

Metric definitions are available:

- Directly from Prometheus `/metrics` endpoint configured for Gitaly.
- Using [Grafana Explore](https://grafana.com/docs/grafana/latest/visualizations/explore/) on a
  Grafana instance configured against Prometheus.

Gitaly can be configured to limit requests based on concurrency of requests (adaptive or non-adaptive).

## Monitor Gitaly concurrency limiting

You can observe specific behavior of [concurrency-queued requests](concurrency_limiting.md#limit-rpc-concurrency) using Gitaly logs and Prometheus.

In the [Gitaly logs](../logs/_index.md#gitaly-logs), you can identify logs related to the pack-objects concurrency limiting with entries such as:

| Log Field                        | Description |
|----------------------------------|-------------|
| `limit.concurrency_queue_length` | Indicates the current length of the queue specific to the RPC type of the ongoing call. It provides insight into the number of requests waiting to be processed due to concurrency limits. |
| `limit.concurrency_queue_ms`     | Represents the duration, in milliseconds, that a request has spent waiting in the queue due to the limit on concurrent RPCs. This field helps understand the impact of concurrency limits on request processing times. |
| `limit.concurrency_dropped`      | If the request is dropped due to limits being reached, this field specifies the reason: either `max_time` (request waited in the queue longer than the maximum allowed time) or `max_size` (the queue reached its maximum size). |
| `limit.limiting_key`             | Identifies the key used for limiting. |
| `limit.limiting_type`            | Specifies the type of process being limited. In this context, it's `per-rpc`, indicating that the concurrency limiting is applied on a per-RPC basis. |

For example:

```json
{
  "limit.concurrency_queue_length": 1,
  "limit.concurrency_queue_ms": 0,
  "limit.limiting_key": "@hashed/79/02/7902699be42c8a8e46fbbb450172651786b22c56a189f7625a6da49081b2451.git",
  "limit.limiting_type": "per-rpc"
}
```

In Prometheus, look for the following metrics:

- `gitaly_concurrency_limiting_in_progress` indicates how many concurrent requests are being processed.
- `gitaly_concurrency_limiting_queued` indicates how many requests for an RPC for a given repository are waiting due to the concurrency limit being reached.
- `gitaly_concurrency_limiting_acquiring_seconds` indicates how long a request has to wait due to concurrency limits before being processed.
- `gitaly_requests_dropped_total` provides a total count of requests dropped due to request limiting. The `reason` label indicates why a request was dropped:
  - `max_size`, because the concurrency queue size was reached.
  - `max_time`, because the request exceeded the maximum queue wait time as configured in Gitaly.

## Monitor Gitaly pack-objects concurrency limiting

You can observe specific behavior of [pack-objects limiting](concurrency_limiting.md#limit-pack-objects-concurrency) using Gitaly logs and Prometheus.

In the [Gitaly logs](../logs/_index.md#gitaly-logs), you can identify logs related to the pack-objects concurrency limiting with entries such as:

| Log Field                        | Description |
|:---------------------------------|:------------|
| `limit.concurrency_queue_length` | Current length of the queue for the pack-objects processes. Indicates the number of requests that are waiting to be processed because the limit on concurrent processes has been reached. |
| `limit.concurrency_queue_ms`     | Time a request has spent waiting in the queue, in milliseconds. Indicates how long a request has had to wait because of the limits on concurrency. |
| `limit.limiting_key`             | Remote IP of the sender. |
| `limit.limiting_type`            | Type of process being limited. In this case, `pack-objects`. |

Example configuration:

```json
{
  "limit.concurrency_queue_length": 1,
  "limit.concurrency_queue_ms": 0,
  "limit.limiting_key": "1.2.3.4",
  "limit.limiting_type": "pack-objects"
}
```

In Prometheus, look for the following metrics:

- `gitaly_pack_objects_in_progress` indicates how many pack-objects processes are being processed concurrently.
- `gitaly_pack_objects_queued` indicates how many requests for pack-objects processes are waiting due to the concurrency limit being reached.
- `gitaly_pack_objects_acquiring_seconds` indicates how long a request for a pack-object process has to wait due to concurrency limits before being processed.

## Monitor Gitaly adaptive concurrency limiting

You can observe specific behavior of [adaptive concurrency limiting](concurrency_limiting.md#adaptive-concurrency-limiting) using Gitaly logs and Prometheus.

Adaptive concurrency limiting is an extension of static concurrency limiting, so all metrics and logs applicable to [static concurrency limiting](#monitor-gitaly-concurrency-limiting) are also relevant when monitoring adaptive limits. In addition, adaptive limiting introduces several specific metrics that help monitor the dynamic adjustment of limits.

### Adaptive limiting logs

In the [Gitaly logs](../logs/_index.md#gitaly-logs), you can identify logs related to the adaptive concurrency limiting when the current limits are adjusted.
You can filter the content of the logs (`msg`) for "Multiplicative decrease" and "Additive increase" messages.

These debug logs are only available at debug severity level and can be verbose, but they provide detailed insights into adaptive limit adjustments.

| Log Field        | Description |
|:-----------------|:------------|
| `limit`          | The name of the limit being adjusted. |
| `previous_limit` | The previous limit before it was increased or decreased. |
| `new_limit`      | The new limit after it was increased or decreased. |
| `watcher`        | The resource watcher that decided the node is under pressure. For example: `CgroupCpu` or `CgroupMemory`. |
| `reason`         | The reason behind limit adjustment. |
| `stats.*`        | Some statistics behind an adjustment decision. They are for debugging purposes. |

Example log:

```json
{
  "msg": "Multiplicative decrease",
  "limit": "pack-objects",
  "new_limit": 14,
  "previous_limit": 29,
  "reason": "cgroup CPU throttled too much",
  "watcher": "CgroupCpu",
  "stats.time_diff": 15.0,
  "stats.throttled_duration": 13.0,
  "stat.sthrottled_threshold": 0.5
}
```

### Adaptive limiting metrics

In Prometheus, look for the following metrics:

General concurrency limiting metrics, applicable to both static and adaptive limits:

- `gitaly_concurrency_limiting_in_progress` - Number of requests being processed.
- `gitaly_concurrency_limiting_queued` - Number of requests waiting in the queue due to concurrency limits.
- `gitaly_concurrency_limiting_acquiring_seconds` - Time spent by requests waiting due to concurrency limits before processing begins.

Adaptive concurrency limiting specific metrics:

- `gitaly_concurrency_limiting_current_limit` - A gauge showing the current limit value of an adaptive concurrency limit for each RPC type. Only adaptive limits are included in this metric.
- `gitaly_concurrency_limiting_backoff_events_total` - Counter indicating the total number of backoff events, representing when and why limits are reduced due to resource pressure.
- `gitaly_concurrency_limiting_watcher_errors_total` - Counter tracking errors that occur when Gitaly fails to retrieve resource data, which may impact the ability of
  Gitaly to evaluate the current resource situation.

When investigating issues with adaptive limiting, correlate these metrics with the general concurrency limiting metrics and logs to get a complete picture of system behavior.

## Monitor Gitaly cgroups

{{< history >}}

- `gitaly_cgroup_memory_pressure_percent`, `gitaly_cgroup_io_pressure_percent`,
  `gitaly_cgroup_memory_events_high_total`, and `gitaly_cgroup_memory_events_max_total`
  [introduced](https://gitlab.com/gitlab-org/gitaly/-/work_items/7043) in GitLab 18.9.
- `gitaly_cgroup_cpu_pressure_percent`
  [introduced](https://gitlab.com/gitlab-org/gitaly/-/work_items/7078) in GitLab 18.10.
- [Changed](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/8639) in GitLab 18.11.
  Metrics are reported for the parent Gitaly cgroup only, the `metrics_enabled` setting under `[cgroups]`
  no longer has any effect, and `gitaly_cgroup_memory_reclaim_attempts_total`, `gitaly_cgroup_cpu_usage_total`,
  `gitaly_cgroup_procs_total`, `gitaly_cgroup_cpu_cfs_periods_total`, `gitaly_cgroup_cpu_cfs_throttled_periods_total`,
  `gitaly_cgroup_cpu_cfs_throttled_seconds_total`, `gitaly_cgroup_memory_events_oom_total`,
  `gitaly_cgroup_memory_pgfault_total`, and `gitaly_cgroup_memory_pgmajfault_total` were removed.
- Because of [issue 7280](https://gitlab.com/gitlab-org/gitaly/-/work_items/7280), no cgroup metrics are exported
  in GitLab 18.11 to 19.2.
  Fixed in GitLab 19.3.

{{< /history >}}

You can observe the status of [control groups (cgroups)](configure_gitaly.md#control-groups) by using Prometheus.
These metrics are reported for the parent Gitaly cgroup and are available only when the Gitaly node uses cgroups v2.
Each metric has a `path` label containing the cgroup path.
No additional configuration is required beyond
[enabling cgroups](configure_gitaly.md#control-groups).

- `gitaly_cgroup_cpu_pressure_percent`, a gauge for the percentage of time processes were stalled waiting for CPU,
  read from [`cpu.pressure`](https://docs.kernel.org/accounting/psi.html).
  Available labels: `type` (`some` only) and `window` (`avg10`, `avg60`, or `avg300`).
- `gitaly_cgroup_memory_pressure_percent`, a gauge for the percentage of time processes were stalled because of memory
  pressure, read from `memory.pressure`.
  Available labels: `type` (`some` or `full`) and `window`.
- `gitaly_cgroup_io_pressure_percent`, a gauge for the percentage of time processes were stalled because of I/O
  pressure, read from `io.pressure`.
  Available labels: `type` (`some` or `full`) and `window`.
- `gitaly_cgroup_memory_events_high_total`, a counter for the number of times the cgroup memory usage exceeded
  `memory.high`, read from `memory.events`.
- `gitaly_cgroup_memory_events_max_total`, a counter for the number of times the cgroup memory usage was about to
  exceed `memory.max`, read from `memory.events`.

In GitLab 18.11 and later, Gitaly does not export CPU usage, CPU throttling, process count, or OOM metrics for cgroups.
To collect these, use a cgroup-aware exporter such as [cAdvisor](https://github.com/google/cadvisor).
On Linux package installations, you must install and configure the exporter yourself.
The following table maps the removed metrics to their cAdvisor equivalents:

| Removed Gitaly metric                           | cAdvisor equivalent                                          |
|:------------------------------------------------|:-------------------------------------------------------------|
| `gitaly_cgroup_cpu_usage_total`                 | `container_cpu_usage_seconds_total`                          |
| `gitaly_cgroup_cpu_cfs_periods_total`           | `container_cpu_cfs_periods_total`                            |
| `gitaly_cgroup_cpu_cfs_throttled_periods_total` | `container_cpu_cfs_throttled_periods_total`                  |
| `gitaly_cgroup_cpu_cfs_throttled_seconds_total` | `container_cpu_cfs_throttled_seconds_total`                  |
| `gitaly_cgroup_procs_total`                     | `container_processes`                                        |
| `gitaly_cgroup_memory_reclaim_attempts_total`   | `container_memory_failures_total`                            |
| `gitaly_cgroup_memory_events_oom_total`         | `container_oom_events_total`                                 |
| `gitaly_cgroup_memory_pgfault_total`            | `container_memory_failures_total{failure_type="pgfault"}`    |
| `gitaly_cgroup_memory_pgmajfault_total`         | `container_memory_failures_total{failure_type="pgmajfault"}` |

## `pack-objects` cache

The following [`pack-objects` cache](configure_gitaly.md#pack-objects-cache) metrics are available:

- `gitaly_pack_objects_cache_enabled`, a gauge set to `1` when the cache is enabled. Available
  labels: `dir` and `max_age`.
- `gitaly_pack_objects_cache_lookups_total`, a counter for cache lookups. Available label: `result`.
- `gitaly_pack_objects_generated_bytes_total`, a counter for the number of bytes written into the
  cache.
- `gitaly_pack_objects_served_bytes_total`, a counter for the number of bytes read from the cache.
- `gitaly_streamcache_filestore_disk_usage_bytes`, a gauge for the total size of cache files.
  Available label: `dir`.
- `gitaly_streamcache_index_entries`, a gauge for the number of entries in the cache. Available
  label: `dir`.

Some of these metrics start with `gitaly_streamcache` because they are generated by the
`streamcache` internal library package in Gitaly.

Example:

```plaintext
gitaly_pack_objects_cache_enabled{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache",max_age="300"} 1
gitaly_pack_objects_cache_lookups_total{result="hit"} 2
gitaly_pack_objects_cache_lookups_total{result="miss"} 1
gitaly_pack_objects_generated_bytes_total 2.618649e+07
gitaly_pack_objects_served_bytes_total 7.855947e+07
gitaly_streamcache_filestore_disk_usage_bytes{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 2.6200152e+07
gitaly_streamcache_filestore_removed_total{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
gitaly_streamcache_index_entries{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
```

## Monitor Gitaly server-side backups

Monitor [server-side repository backups](configure_gitaly.md#configure-server-side-backups) with the following metrics:

- `gitaly_backup_latency_seconds`, a histogram measuring the amount of time in seconds that each phase of a server-side
  backup takes. The different phases are `refs`, `bundle`, and `custom_hooks` and represent the type of data being
  processed at each stage.
- `gitaly_backup_bundle_bytes`, a histogram measuring the upload data rate of Git bundles being pushed to object
  storage by the Gitaly backup service.

Use these metrics especially if your GitLab instance contains large repositories.

## Queries

The following are some queries for monitoring Gitaly:

- Use the following Prometheus query to observe the
  [type of connections](tls_support.md) Gitaly is serving a production
  environment:

  ```prometheus
  sum(rate(gitaly_connections_total[5m])) by (type)
  ```

- Use the following Prometheus query to monitor the
  [authentication behavior](tls_support.md#observe-type-of-gitaly-connections) of your GitLab
  installation:

  ```prometheus
  sum(rate(gitaly_authentications_total[5m])) by (enforced, status)
  ```

  In a system where authentication is configured correctly and where you have live traffic, you
  see something like this:

  ```prometheus
  {enforced="true",status="ok"}  4424.985419441742
  ```

  There may also be other numbers with rate 0, but you only have to take note of the non-zero numbers.

  The only non-zero number should have `enforced="true",status="ok"`. If you have other non-zero
  numbers, something is wrong in your configuration.

  The `status="ok"` number reflects your current request rate. In the previous example, Gitaly is
  handling about 4000 requests per second.

- Use the following Prometheus query to observe the [Git protocol versions](../git_protocol.md)
  being used in a production environment:

  ```prometheus
  sum(rate(gitaly_git_protocol_requests_total[1m])) by (grpc_method,git_protocol,grpc_service)
  ```
