---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Concurrency limiting
---

To avoid overwhelming the servers running Gitaly, you can limit concurrency of:

- RPCs.
- Pack objects.

These limits can be fixed, or set as adaptive.

{{< alert type="warning" >}}

Enabling limits on your environment should be done with caution and only
in select circumstances, such as to protect against unexpected traffic.
When reached, limits do result in disconnects that negatively impact users.
For consistent and stable performance, you should first explore other options such as
adjusting node specifications, and [reviewing large repositories](../../user/project/repository/monorepos/_index.md) or workloads.

{{< /alert >}}

## Limit RPC concurrency

When cloning or pulling repositories, various RPCs run in the background. In particular, the Git pack RPCs:

- `SSHUploadPackWithSidechannel` (for Git SSH).
- `PostUploadPackWithSidechannel` (for Git HTTP).

These RPCs can consume a large amount of resources, which can have a significant impact in situations such as:

- Unexpectedly high traffic.
- Running against [large repositories](../../user/project/repository/monorepos/_index.md) that don't follow best practices.

You can limit these processes from overwhelming your Gitaly server in these scenarios using the concurrency limits in the Gitaly configuration file. For
example:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
      {
         rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
   ],
}
```

- `rpc` is the name of the RPC to set a concurrency limit for per repository.
- `max_per_repo` is the maximum number of in-flight RPC calls for the given RPC per repository.
- `max_queue_wait` is the maximum amount of time a request can wait in the concurrency queue to
  be picked up by Gitaly.
- `max_queue_size` is the maximum size the concurrency queue (per RPC method) can grow to before requests are rejected by
  Gitaly.

This limits the number of in-flight RPC calls for the given RPCs. The limit is applied per
repository. In the previous example:

- Each repository served by the Gitaly server can have at most 20 simultaneous `PostUploadPackWithSidechannel` and
  `SSHUploadPackWithSidechannel` RPC calls in flight.
- If another request comes in for a repository that has used up its 20 slots, that request gets
  queued.
- If a request waits in the queue for more than 1 second, it is rejected with an error.
- If the queue grows beyond 10, subsequent requests are rejected with an error.

{{< alert type="note" >}}

When these limits are reached, users are disconnected.

{{< /alert >}}

You can observe the behavior of this queue using the Gitaly logs and Prometheus. For more
information, see the [relevant documentation](monitoring.md#monitor-gitaly-concurrency-limiting).

### Separate limits for unauthenticated requests

{{< history >}}

- Introduced in GitLab 18.7 [with a flag](../../operations/feature_flags.md) named `gitaly_limit_unauthenticated`. Disabled by default.

{{< /history >}}

{{< alert type="note">}}
The availability of this feature is controlled by a feature flag.
For more information, see the history.

This feature is available for testing, but not ready for production use.
{{< /alert >}}

By default, RPC concurrency limits apply to all requests regardless of
authentication status. However, you can configure separate, more restrictive
limits for unauthenticated requests to protect your Gitaly server from
potential abuse or resource exhaustion from anonymous traffic.

When you configure the `unauthenticated` field for an RPC, Gitaly uses
separate limiters:

- **Authenticated requests** use the main concurrency limits (configured at
  the top level of the RPC configuration).
- **Unauthenticated requests** use the limits specified in the
  `unauthenticated` field.

This separation allows you to:

- Apply stricter limits to unauthenticated traffic while maintaining higher
  throughput for authenticated users.
- Protect against denial-of-service scenarios from anonymous clones or pulls.
- Ensure authenticated users have priority access to Gitaly resources.

If you don't configure the `unauthenticated` field, all requests (both
authenticated and unauthenticated) share the same concurrency limits.

#### When to use separate unauthenticated limits

Consider configuring separate unauthenticated limits when:

- Your GitLab instance allows public repository access and experiences high
  anonymous traffic.
- You want to prioritize authenticated users during periods of high load.
- You need to protect against potential abuse from unauthenticated sources.
- You observe resource contention between authenticated and unauthenticated
  requests.

#### Configure static limits for unauthenticated requests

The following example shows how to configure separate static limits for authenticated
and unauthenticated requests:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         # Limits for authenticated requests
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
         # Separate limits for unauthenticated requests
         unauthenticated: {
            max_per_repo: 5,
            max_queue_wait: '500ms',
            max_queue_size: 5,
         },
      },
   ],
}
```

In this example:

- Authenticated requests can have up to 20 concurrent operations per
  repository.
- Unauthenticated requests are limited to 5 concurrent operations per
  repository.
- Unauthenticated requests have a shorter queue wait time (500ms vs 1s) and
  smaller queue (5 vs 10).

#### Configure adaptive limits for unauthenticated requests

The `unauthenticated` field supports both static and adaptive concurrency
limits, just like the main configuration. You can configure adaptive limits
for unauthenticated requests:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         # Adaptive limits for authenticated requests
         adaptive: true,
         min_limit: 10,
         initial_limit: 20,
         max_limit: 40,
         max_queue_wait: '1s',
         max_queue_size: 10,
         # Adaptive limits for unauthenticated requests
         unauthenticated: {
            adaptive: true,
            min_limit: 2,
            initial_limit: 5,
            max_limit: 10,
            max_queue_wait: '500ms',
            max_queue_size: 5,
         },
      },
   ],
}
```

This configuration allows both authenticated and unauthenticated limits to
adapt independently based on system resource usage, while maintaining the
separation between the two traffic types.

## Limit pack-objects concurrency

Gitaly triggers `git-pack-objects` processes when handling both SSH and HTTPS traffic to clone or pull repositories. These processes generate a `pack-file` and can
consume a significant amount of resources, especially in situations such as unexpectedly high traffic or concurrent pulls from a large repository. On GitLab.com, we also
observe problems with clients that have slow internet connections.

You can limit these processes from overwhelming your Gitaly server by setting pack-objects concurrency limits in the Gitaly configuration file. This setting limits the
number of in-flight pack-object processes per remote IP address.

{{< alert type="warning" >}}

Only enable these limits on your environment with caution and only in select circumstances, such as to protect against unexpected traffic. When reached, these limits
disconnect users. For consistent and stable performance, you should first explore other options such as adjusting node specifications, and
[reviewing large repositories](../../user/project/repository/monorepos/_index.md) or workloads.

{{< /alert >}}

Example configuration:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_concurrency' => 15,
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
}
```

- `max_concurrency` is the maximum number of in-flight pack-object processes per key.
- `max_queue_length` is the maximum size the concurrency queue (per key) can grow to before requests are rejected by Gitaly.
- `max_queue_wait` is the maximum amount of time a request can wait in the concurrency queue to be picked up by Gitaly.

In the previous example:

- Each remote IP can have at most 15 simultaneous pack-object processes in flight on a Gitaly node.
- If another request comes in from an IP that has used up its 15 slots, that request gets queued.
- If a request waits in the queue for more than 1 minute, it is rejected with an error.
- If the queue grows beyond 200, subsequent requests are rejected with an error.

When the pack-object cache is enabled, pack-objects limiting kicks in only if the cache is missed. For more, see [Pack-objects cache](configure_gitaly.md#pack-objects-cache).

You can observe the behavior of this queue using Gitaly logs and Prometheus. For more information, see
[Monitor Gitaly pack-objects concurrency limiting](monitoring.md#monitor-gitaly-pack-objects-concurrency-limiting).

## Calibrating concurrency limits

When setting concurrency limits, you should choose appropriate values based on your specific workload patterns. This section provides guidance on how to calibrate these limits effectively.

### Using Prometheus metrics and logs for calibration

Prometheus metrics provide quantitative insights into usage patterns and the impact of each type of RPC on Gitaly node resources. Several key metrics are particularly valuable for this analysis:

- Resource consumption metrics per-RPC. Gitaly offloads most heavy operations to `git` processes and so the command usually shelled out to is the Git binary.
  Gitaly exposes collected metrics from those commands as logs and Prometheus metrics.
  - `gitaly_command_cpu_seconds_total` - Sum of CPU time spent by shelling out, with labels for `grpc_service`, `grpc_method`, `cmd`, and `subcmd`.
  - `gitaly_command_real_seconds_total` - Sum of real time spent by shelling out, with similar labels.
- Recent limiting metrics per-RPC:
  - `gitaly_concurrency_limiting_in_progress` - Number of concurrent requests being processed.
  - `gitaly_concurrency_limiting_queued` - Number of requests for an RPC for a given repository in waiting state.
  - `gitaly_concurrency_limiting_acquiring_seconds` - Duration a request waits due to concurrency limits before processing.

These metrics provide a high-level view of resource utilization at a given point in time. The `gitaly_command_cpu_seconds_total` metric is particularly effective for
identifying specific RPCs that consume substantial CPU resources. Additional metrics are available for more detailed analysis as described in
[Monitoring Gitaly](monitoring.md).

While metrics capture overall resource usage patterns, they typically do not provide per-repository breakdowns. Therefore, logs serve as a complementary data source. To analyze logs:

1. Filter logs by identified high-impact RPCs.
1. Aggregate filtered logs by repository or project.
1. Visualize aggregated results on a time-series graph.

This combined approach of using both metrics and logs provides comprehensive visibility into both system-wide resource usage and repository-specific patterns. Analysis tools such as Kibana or similar log aggregation platforms can facilitate this process.

### Adjusting limits

If you find that your initial limits are not efficient enough, you might need to adjust them. With adaptive limiting, precise limits are less critical because the system
automatically adjusts based on resource usage.

Remember that concurrency limits are scoped by repository. A limit of 30 means allowing at most 30 simultaneous in-flight requests per repository. If the limit is reached,
requests are queued and only rejected if the queue is full or the maximum waiting time is reached.

## Adaptive concurrency limiting

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10734) in GitLab 16.6.

{{< /history >}}

Gitaly supports two concurrency limits:

- An [RPC concurrency limit](#limit-rpc-concurrency), which allow you to configure a maximum number of simultaneous in-flight requests for each
  Gitaly RPC. The limit is scoped by RPC and repository.
- A [Pack-objects concurrency limit](#limit-pack-objects-concurrency), which restricts the number of concurrent Git data transfer request by IP.

If this limit is exceeded, either:

- The request is put in a queue.
- The request is rejected if the queue is full or if the request remains in the queue for too long.

Both of these concurrency limits can be configured statically. Though static limits can yield good protection results, they have some drawbacks:

- Static limits are not good for all usage patterns. There is no one-size-fits-all value. If the limit is too low, big repositories are
  negatively impacted. If the limit is too high, the protection is essentially lost.
- It's tedious to maintain a sane value for the concurrency limit, especially when the workload of each repository changes over time.
- A request can be rejected even though the server is idle because the rate doesn't factor in the load on the server.

You can overcome all of these drawbacks and keep the benefits of concurrency limiting by configuring adaptive concurrency limits. Adaptive
concurrency limits are optional and build on the two concurrency limiting types. It uses Additive Increase/Multiplicative Decrease (AIMD)
algorithm. Each adaptive limit:

- Gradually increases up to a certain upper limit during typical process functioning.
- Quickly decreases when the host machine has a resource problem.

This mechanism provides some headroom for the machine to "breathe" and speeds up current inflight requests.

![Graph showing a Gitaly adaptive concurrency limit being adjusted based on the system resource usage by following the AIMD algorithm](img/gitaly_adaptive_concurrency_limit_v16_6.png)

The adaptive limiter calibrates the limits every 30 seconds and:

- Increases the limits by one until reaching the upper limit.
- Decreases the limits by half when the top-level cgroup has either memory usage that exceeds 90%, excluding highly-evictable page caches,
  or CPU throttled for 50% or more of the observation time.

Otherwise, the limits increase by one until reaching the upper bound.

Adaptive limiting is enabled for each RPC or pack-objects cache individually. However, limits are calibrated at the same time. Adaptive limiting has the following configurations:

- `adaptive` sets whether the adaptiveness is enabled.
- `max_limit` is the maximum concurrency limit. Gitaly increases the current limit until it reaches this number. This should be a generous value that the system can fully support under typical conditions.
- `min_limit` is the is the minimum concurrency limit of the configured RPC. When the host machine has a resource problem, Gitaly quickly reduces the limit until reaching this value. Setting `min_limit` to 0 could completely shut down processing, which is typically undesirable.
- `initial_limit` provides a reasonable starting point between these extremes.

### Enable adaptiveness for RPC concurrency

Prerequisites:

- Because adaptive limiting depends on [control groups](configure_gitaly.md#control-groups), control groups must be enabled before using adaptive limiting.

The following is an example to configure an adaptive limit for RPC concurrency:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
    # ...
    cgroups: {
        # Minimum required configuration to enable cgroups support.
        repositories: {
            count: 1
        },
    },
    concurrency: [
        {
            rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
            max_queue_wait: '1s',
            max_queue_size: 10,
            adaptive: true,
            min_limit: 10,
            initial_limit: 20,
            max_limit: 40
        },
        {
            rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
            max_queue_wait: '10s',
            max_queue_size: 20,
            adaptive: true,
            min_limit: 10,
            initial_limit: 50,
            max_limit: 100
        },
   ],
}
```

For more information, see [RPC concurrency](#limit-rpc-concurrency).

### Enable adaptiveness for pack-objects concurrency

Prerequisites:

- Because adaptive limiting depends on [control groups](configure_gitaly.md#control-groups), control groups must be enabled before using adaptive limiting.

The following is an example to configure an adaptive limit for pack-objects concurrency:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
   'adaptive' => true,
   'min_limit' => 10,
   'initial_limit' => 20,
   'max_limit' => 40
}
```

For more information, see [pack-objects concurrency](#limit-pack-objects-concurrency).

### Calibrating adaptive concurrency limits

Adaptive concurrency limiting is very different from the usual way that GitLab protects Gitaly resources. Rather than relying on static thresholds that may be either too restrictive or too permissive, adaptive limiting intelligently responds to actual resource conditions in real-time.

This approach eliminates the need to find "perfect" threshold values through extensive calibration as described in
[Calibrating concurrency limits](#calibrating-concurrency-limits). During failure scenarios, the adaptive limiter reduces limits exponentially (for example, 60 → 30 → 15 → 10)
and then automatically recovers by incrementally raising limits when the system stabilizes.

When calibrating adaptive limits, you can prioritize flexibility over precision.

#### RPC categories and configuration examples

Expensive Gitaly RPCs, which should be protected, can be categorized into two general types:

- Pure Git data operations.
- Time sensitive RPCs.

Each type has distinct characteristics that influence how concurrency limits should be configured. The following examples illustrate the reasoning behind
limit configuration. They can also be used as a starting point.

##### Pure Git data operations

These RPCs involve Git pull, push, and fetch operations, and possess the following characteristics:

- Long-running processes.
- Significant resource utilization.
- Computationally expensive.
- Not time-sensitive. Additional latency is generally acceptable.

RPCs in `SmartHTTPService` and `SSHService` fall into the pure Git data operations category. A configuration example:

```ruby
{
  rpc: "/gitaly.SmartHTTPService/PostUploadPackWithSidechannel", # or `/gitaly.SmartHTTPService/SSHUploadPackWithSidechannel`
  adaptive: true,
  min_limit: 10,  # Minimum concurrency to maintain even under extreme load
  initial_limit: 40,  # Starting concurrency when service initializes
  max_limit: 60,  # Maximum concurrency under ideal conditions
  max_queue_wait: "60s",
  max_queue_size: 300
}
```

##### Time-sensitive RPCs

These RPCs serve GitLab itself and other clients with different characteristics:

- Typically part of online HTTP requests or Sidekiq background jobs.
- Shorter latency profiles.
- Generally less resource-intensive.

For these RPCs, the timeout configuration in GitLab should inform the `max_queue_wait` parameter. For instance, `get_tree_entries` typically has a medium timeout of 30 seconds in GitLab:

```ruby
{
  rpc: "/gitaly.CommitService/GetTreeEntries",
  adaptive: true,
  min_limit: 5,  # Minimum throughput maintained under resource pressure
  initial_limit: 10,  # Initial concurrency setting
  max_limit: 20,  # Maximum concurrency under optimal conditions
  max_queue_size: 50,
  max_queue_wait: "30s"
}
```

### Monitoring adaptive limiting

To observe how adaptive limits are behaving in production environments, refer to the monitoring tools and metrics described in
[Monitor Gitaly adaptive concurrency limiting](monitoring.md#monitor-gitaly-adaptive-concurrency-limiting). Observing adaptive limit behavior helps confirm that limits
are properly responding to resource pressures and adjusting as expected.
