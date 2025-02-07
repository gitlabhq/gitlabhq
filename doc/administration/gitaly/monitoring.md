---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Monitoring Gitaly and Gitaly Cluster
---

You can use the available logs and [Prometheus metrics](../monitoring/prometheus/_index.md) to
monitor Gitaly and Gitaly Cluster (Praefect).

Metric definitions are available:

- Directly from Prometheus `/metrics` endpoint configured for Gitaly.
- Using [Grafana Explore](https://grafana.com/docs/grafana/latest/explore/) on a
  Grafana instance configured against Prometheus.

<!--- start_remove The following content will be removed on remove_date: '2025-08-01' -->

## Monitor Gitaly rate limiting (deprecated)

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitaly/-/issues/5011) in GitLab 17.7
and is planned for removal in 18.0. Use [concurrency limiting](concurrency_limiting.md) instead.

Gitaly can be configured to limit requests based on:

- Concurrency of requests.
- A rate limit.

Monitor Gitaly request limiting with the `gitaly_requests_dropped_total` Prometheus metric. This metric provides a total count
of requests dropped due to request limiting. The `reason` label indicates why a request was dropped:

- `rate`, due to rate limiting.
- `max_size`, because the concurrency queue size was reached.
- `max_time`, because the request exceeded the maximum queue wait time as configured in Gitaly.

<!--- end_remove -->

## Monitor Gitaly concurrency limiting

You can observe specific behavior of [concurrency-queued requests](concurrency_limiting.md#limit-rpc-concurrency) using Gitaly logs and Prometheus.

In the [Gitaly logs](../logs/_index.md#gitaly-logs), you can identify logs related to the pack-objects concurrency limiting with entries such as:

| Log Field | Description |
| --- | --- |
| `limit.concurrency_queue_length` | Indicates the current length of the queue specific to the RPC type of the ongoing call. It provides insight into the number of requests waiting to be processed due to concurrency limits.                                       |
| `limit.concurrency_queue_ms`     | Represents the duration, in milliseconds, that a request has spent waiting in the queue due to the limit on concurrent RPCs. This field helps understand the impact of concurrency limits on request processing times.           |
| `limit.concurrency_dropped`      | If the request is dropped due to limits being reached, this field specifies the reason: either `max_time` (request waited in the queue longer than the maximum allowed time) or `max_size` (the queue reached its maximum size). |
| `limit.limiting_key`             | Identifies the key used for limiting.  |
| `limit.limiting_type`            | Specifies the type of process being limited. In this context, it's `per-rpc`, indicating that the concurrency limiting is applied on a per-RPC basis.                                                                            |

For example:

```json
{
  "limit .concurrency_queue_length": 1,
  "limit .concurrency_queue_ms": 0,
  "limit.limiting_key": "@hashed/79/02/7902699be42c8a8e46fbbb450172651786b22c56a189f7625a6da49081b2451.git",
  "limit.limiting_type": "per-rpc"
}
```

In Prometheus, look for the following metrics:

- `gitaly_concurrency_limiting_in_progress` indicates how many concurrent requests are being processed.
- `gitaly_concurrency_limiting_queued` indicates how many requests for an RPC for a given repository are waiting due to the concurrency limit being reached.
- `gitaly_concurrency_limiting_acquiring_seconds` indicates how long a request has to wait due to concurrency limits before being processed.

## Monitor Gitaly pack-objects concurrency limiting

You can observe specific behavior of [pack-objects limiting](concurrency_limiting.md#limit-pack-objects-concurrency) using Gitaly logs and Prometheus.

In the [Gitaly logs](../logs/_index.md#gitaly-logs), you can identify logs related to the pack-objects concurrency limiting with entries such as:

| Log Field | Description |
|:---|:---|
| `limit.concurrency_queue_length` | Current length of the queue for the pack-objects processes. Indicates the number of requests that are waiting to be processed because the limit on concurrent processes has been reached. |
| `limit.concurrency_queue_ms` | Time a request has spent waiting in the queue, in milliseconds. Indicates how long a request has had to wait because of the limits on concurrency. |
| `limit.limiting_key` | Remote IP of the sender. |
| `limit.limiting_type` | Type of process being limited. In this case, `pack-objects`. |

Example configuration:

```json
{
  "limit .concurrency_queue_length": 1,
  "limit .concurrency_queue_ms": 0,
  "limit.limiting_key": "1.2.3.4",
  "limit.limiting_type": "pack-objects"
}
```

In Prometheus, look for the following metrics:

- `gitaly_pack_objects_in_progress` indicates how many pack-objects processes are being processed concurrently.
- `gitaly_pack_objects_queued` indicates how many requests for pack-objects processes are waiting due to the concurrency limit being reached.
- `gitaly_pack_objects_acquiring_seconds` indicates how long a request for a pack-object process has to wait due to concurrency limits before being processed.

## Monitor Gitaly adaptive concurrency limiting

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10734) in GitLab 16.6.

You can observe specific behavior of [adaptive concurrency limiting](concurrency_limiting.md#adaptive-concurrency-limiting) using Gitaly logs and Prometheus.

In the [Gitaly logs](../logs/_index.md#gitaly-logs), you can identify logs related to the adaptive concurrency limiting when the current limits are adjusted.
You can filter the content of the logs (`msg`) for "Multiplicative decrease" and "Additive increase" messages.

| Log Field | Description |
|:---|:---|
| `limit` | The name of the limit being adjusted. |
| `previous_limit` | The previous limit before it was increased or decreased. |
| `new_limit` | The new limit after it was increased or decreased. |
| `watcher` | The resource watcher that decided the node is under pressure. For example: `CgroupCpu` or `CgroupMemory`. |
| `reason` | The reason behind limit adjustment. |
| `stats.*` | Some statistics behind an adjustment decision. They are for debugging purposes. |

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

In Prometheus, look for the following metrics:

- `gitaly_concurrency_limiting_current_limit` The current limit value of an adaptive concurrency limit.
- `gitaly_concurrency_limiting_watcher_errors_total` indicates the total number of watcher errors while fetching resource metrics.
- `gitaly_concurrency_limiting_backoff_events_total` indicates the total number of backoff events, which are when the limits being
  adjusted due to resource pressure.

## Monitor Gitaly cgroups

You can observe the status of [control groups (cgroups)](configure_gitaly.md#control-groups) using Prometheus:

- `gitaly_cgroups_reclaim_attempts_total`, a gauge for the total number of times
  there has been a memory reclaim attempt. This number resets each time a server is
  restarted.
- `gitaly_cgroups_cpu_usage`, a gauge that measures CPU usage per cgroup.
- `gitaly_cgroup_procs_total`, a gauge that measures the total number of
  processes Gitaly has spawned under the control of cgroups.
- `gitaly_cgroup_cpu_cfs_periods_total`, a counter that for the value of [`nr_periods`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics).
- `gitaly_cgroup_cpu_cfs_throttled_periods_total`, a counter for the value of [`nr_throttled`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics).
- `gitaly_cgroup_cpu_cfs_throttled_seconds_total`, a counter for the value of [`throttled_time`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics) in seconds.

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

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/5358) in GitLab 16.7.

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

  The `status="ok"` number reflects your current request rate. In the example above, Gitaly is
  handling about 4000 requests per second.

- Use the following Prometheus query to observe the [Git protocol versions](../git_protocol.md)
  being used in a production environment:

  ```prometheus
  sum(rate(gitaly_git_protocol_requests_total[1m])) by (grpc_method,git_protocol,grpc_service)
  ```

## Monitor Gitaly Cluster

To monitor Gitaly Cluster (Praefect), you can use these Prometheus metrics. Two separate metrics endpoints are
available from which metrics can be scraped:

- The default `/metrics` endpoint.
- `/db_metrics`, which contains metrics that require database queries.

### Default Prometheus `/metrics` endpoint

The following metrics are available from the `/metrics` endpoint:

- `gitaly_praefect_read_distribution`, a counter to track [distribution of reads](_index.md#distributed-reads).
  It has two labels:

  - `virtual_storage`.
  - `storage`.

  They reflect configuration defined for this instance of Praefect.

- `gitaly_praefect_replication_latency_bucket`, a histogram measuring the amount of time it takes
  for replication to complete after the replication job starts.
- `gitaly_praefect_replication_delay_bucket`, a histogram measuring how much time passes between
  when the replication job is created and when it starts.
- `gitaly_praefect_connections_total`, the total number of connections to Praefect.
- `gitaly_praefect_method_types`, a count of accessor and mutator RPCs per node.

To monitor [strong consistency](_index.md#strong-consistency), you can use the following Prometheus metrics:

- `gitaly_praefect_transactions_total`, the number of transactions created and voted on.
- `gitaly_praefect_subtransactions_per_transaction_total`, the number of times nodes cast a vote for
  a single transaction. This can happen multiple times if multiple references are getting updated in
  a single transaction.
- `gitaly_praefect_voters_per_transaction_total`: the number of Gitaly nodes taking part in a
  transaction.
- `gitaly_praefect_transactions_delay_seconds`, the server-side delay introduced by waiting for the
  transaction to be committed.
- `gitaly_hook_transaction_voting_delay_seconds`, the client-side delay introduced by waiting for
  the transaction to be committed.

To monitor [repository verification](praefect.md#repository-verification), use the following Prometheus metrics:

- `gitaly_praefect_verification_jobs_dequeued_total`, the number of verification jobs picked up by the
  worker.
- `gitaly_praefect_verification_jobs_completed_total`, the number of verification jobs completed by the
  worker. The `result` label indicates the end result of the jobs:
  - `valid` indicates the expected replica existed on the storage.
  - `invalid` indicates the replica expected to exist did not exist on the storage.
  - `error` indicates the job failed and has to be retried.
- `gitaly_praefect_stale_verification_leases_released_total`, the number of stale verification leases
  released.

You can also monitor the [Praefect logs](../logs/_index.md#praefect-logs).

### Database metrics `/db_metrics` endpoint

The following metrics are available from the `/db_metrics` endpoint:

- `gitaly_praefect_unavailable_repositories`, the number of repositories that have no healthy, up to date replicas.
- `gitaly_praefect_replication_queue_depth`, the number of jobs in the replication queue.
- `gitaly_praefect_verification_queue_depth`, the total number of replicas pending verification.
- `gitaly_praefect_read_only_repositories`, the number of repositories in read-only mode in a virtual storage.
  - This metric was [removed](https://gitlab.com/gitlab-org/gitaly/-/issues/4229) in GitLab 15.4.
