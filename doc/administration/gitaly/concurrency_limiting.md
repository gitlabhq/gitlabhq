---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Concurrency limiting
---

To avoid overwhelming the servers running Gitaly, you can limit concurrency of:

- RPCs.
- Pack objects.

These limits can be fixed, or set as adaptive.

WARNING:
Enabling limits on your environment should be done with caution and only
in select circumstances, such as to protect against unexpected traffic.
When reached, limits _do_ result in disconnects that negatively impact users.
For consistent and stable performance, you should first explore other options such as
adjusting node specifications, and [reviewing large repositories](../../user/project/repository/monorepos/_index.md) or workloads.

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
repository. In the example above:

- Each repository served by the Gitaly server can have at most 20 simultaneous `PostUploadPackWithSidechannel` and
  `SSHUploadPackWithSidechannel` RPC calls in flight.
- If another request comes in for a repository that has used up its 20 slots, that request gets
  queued.
- If a request waits in the queue for more than 1 second, it is rejected with an error.
- If the queue grows beyond 10, subsequent requests are rejected with an error.

NOTE:
When these limits are reached, users are disconnected.

You can observe the behavior of this queue using the Gitaly logs and Prometheus. For more
information, see the [relevant documentation](monitoring.md#monitor-gitaly-concurrency-limiting).

## Limit pack-objects concurrency

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/7891) in GitLab 15.11 [with a flag](../feature_flags.md) named `gitaly_pack_objects_limiting_remote_ip`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5772) in GitLab 16.0. Feature flag `gitaly_pack_objects_limiting_remote_ip` removed.

Gitaly triggers `git-pack-objects` processes when handling both SSH and HTTPS traffic to clone or pull repositories. These processes generate a `pack-file` and can
consume a significant amount of resources, especially in situations such as unexpectedly high traffic or concurrent pulls from a large repository. On GitLab.com, we also
observe problems with clients that have slow internet connections.

You can limit these processes from overwhelming your Gitaly server by setting pack-objects concurrency limits in the Gitaly configuration file. This setting limits the
number of in-flight pack-object processes per remote IP address.

WARNING:
Only enable these limits on your environment with caution and only in select circumstances, such as to protect against unexpected traffic. When reached, these limits
disconnect users. For consistent and stable performance, you should first explore other options such as adjusting node specifications, and
[reviewing large repositories](../../user/project/repository/monorepos/_index.md) or workloads.

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

In the example above:

- Each remote IP can have at most 15 simultaneous pack-object processes in flight on a Gitaly node.
- If another request comes in from an IP that has used up its 15 slots, that request gets queued.
- If a request waits in the queue for more than 1 minute, it is rejected with an error.
- If the queue grows beyond 200, subsequent requests are rejected with an error.

When the pack-object cache is enabled, pack-objects limiting kicks in only if the cache is missed. For more, see [Pack-objects cache](configure_gitaly.md#pack-objects-cache).

You can observe the behavior of this queue using Gitaly logs and Prometheus. For more information, see
[Monitor Gitaly pack-objects concurrency limiting](monitoring.md#monitor-gitaly-pack-objects-concurrency-limiting).

## Adaptive concurrency limiting

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10734) in GitLab 16.6.

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

Otherwise, the limits increase by one until reaching the upper bound. For more information about technical implementation
of this system, refer to [the related design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/gitaly_adaptive_concurrency_limit/).

Adaptive limiting is enabled for each RPC or pack-objects cache individually. However, limits are calibrated at the same time.

### Enable adaptiveness for RPC concurrency

Prerequisites:

- Because adaptive limiting depends on [control groups](configure_gitaly.md#control-groups), control groups must be enabled before using adaptive limiting.

The following is an example to configure an adaptive limit for RPC concurrency:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
    # ...
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

In this example:

- `adaptive` sets whether the adaptiveness is enabled. If set, the `max_per_repo` value is ignored in favor of the following configuration.
- `initial_limit` is the per-repository concurrency limit to use when Gitaly starts.
- `max_limit` is the minimum per-repository concurrency limit of the configured RPC. Gitaly increases the current limit
  until it reaches this number.
- `min_limit` is the is the minimum per-repository concurrency limit of the configured RPC. When the host machine has a resource problem,
  Gitaly quickly reduces the limit until reaching this value.

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

In this example:

- `adaptive` sets whether the adaptiveness is enabled. If set, the value of `max_concurrency` is ignored in favor of the following configuration.
- `initial_limit` is the per-IP concurrency limit to use when Gitaly starts.
- `max_limit` is the minimum per-IP concurrency limit for pack-objects. Gitaly increases the current limit until it reaches this number.
- `min_limit` is the is the minimum per-IP concurrency limit for pack-objects. When the host machine has a resources problem, Gitaly quickly
  reduces the limit until it reaches this value.

For more information, see [pack-objects concurrency](#limit-pack-objects-concurrency).
