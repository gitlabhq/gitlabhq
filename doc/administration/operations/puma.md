---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Configure the bundled Puma instance of the GitLab package **(FREE SELF)**

Puma is a fast, multi-threaded, and highly concurrent HTTP 1.1 server for
Ruby applications. It runs the core Rails application that provides the user-facing
features of GitLab.

## Reducing memory use

To reduce memory use, Puma forks worker processes. Each time a worker is created,
it shares memory with the primary process. The worker uses additional memory only
when it changes or adds to its memory pages.

Memory use increases over time, but you can use Puma Worker Killer to recover memory.

By default:

- The [Puma Worker Killer](https://github.com/schneems/puma_worker_killer) restarts a worker if it
  exceeds a [memory limit](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/cluster/puma_worker_killer_initializer.rb).
- Rolling restarts of Puma workers are performed every 12 hours.

### Change the memory limit setting

To change the memory limit setting:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   puma['per_worker_max_memory_mb'] = 1024
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

When workers are killed and replaced, capacity to run GitLab is reduced,
and CPU is consumed. Set `per_worker_max_memory_mb` to a higher value if the worker killer
is replacing workers too often.

Worker count is calculated based on CPU cores. A small GitLab deployment
with 4-8 workers may experience performance issues if workers are being restarted
too often (once or more per minute).

A higher value of `1200` or more would be beneficial if the server has free memory.

### Monitor worker memory

The worker killer checks memory every 20 seconds.

To monitor the worker killer, use [the Puma log](../logs.md#puma_stdoutlog) `/var/log/gitlab/puma/puma_stdout.log`.
For example:

```plaintext
PumaWorkerKiller: Out of memory. 4 workers consuming total: 4871.23828125 MB
out of max: 4798.08 MB. Sending TERM to pid 26668 consuming 1001.00390625 MB.
```

From this output:

- The formula that calculates the maximum memory value results in workers
  being killed before they reach the `per_worker_max_memory_mb` value.
- In GitLab 13.4 and earlier, the default values for the formula were 550MB for the primary
  and 850MB for each worker.
- In GitLab 13.5 and later, the values are primary: 800MB, worker: 1024MB.
- The threshold for workers to be killed is set at 98% of the limit:

  ```plaintext
  0.98 * ( 800 + ( worker_processes * 1024MB ) )
  ```

- In the log output above, `0.98 * ( 800 + ( 4 * 1024 ) )` returns the
  `max: 4798.08 MB` value.

Increasing the maximum to `1200`, for example, would set a `max: 5488 MB` value.

Workers use additional memory on top of the shared memory. The amount of memory
depends on a site's use of GitLab.

## Change the worker timeout

The default Puma [timeout is 60 seconds](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/rack_timeout.rb).

NOTE:
The `puma['worker_timeout']` setting does not set the maximum request duration.

To change the worker timeout to 600 seconds:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['env'] = {
      'GITLAB_RAILS_RACK_TIMEOUT' => 600
    }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Disable Puma clustered mode in memory-constrained environments

In a memory-constrained environment with less than 4GB of RAM available, consider disabling Puma
[clustered mode](https://github.com/puma/puma#clustered-mode).

Set the number of `workers` to `0` to reduce memory usage by hundreds of MB:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   puma['worker_processes'] = 0
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Unlike in a clustered mode, which is set up by default, only a single Puma process would serve the application.
For details on Puma worker and thread settings, see the [Puma requirements](../../install/requirements.md#puma-settings).

The downside of running Puma in this configuration is the reduced throughput, which can be
considered a fair tradeoff in a memory-constrained environment.

When running Puma in single mode, some features are not supported:

- [Phased restart](https://gitlab.com/gitlab-org/gitlab/-/issues/300665)
- [Puma Worker Killer](https://gitlab.com/gitlab-org/gitlab/-/issues/300664)

To learn more, visit [epic 5303](https://gitlab.com/groups/gitlab-org/-/epics/5303).

## Performance caveat when using Puma with Rugged

For deployments where NFS is used to store Git repositories, GitLab uses
[direct Git access](../gitaly/index.md#direct-access-to-git-in-gitlab) to improve performance by using
[Rugged](https://github.com/libgit2/rugged).

Rugged usage is automatically enabled if direct Git access
[is available](../gitaly/index.md#how-it-works)
and Puma is running single threaded, unless it is disabled by a
[feature flag](../../development/gitaly.md#legacy-rugged-code).

MRI Ruby uses a Global VM Lock (GVL). GVL allows MRI Ruby to be multi-threaded, but running at
most on a single core.

Git includes intensive I/O operations. When Rugged uses a thread for a long period of time,
other threads that might be processing requests can starve. Puma running in single thread mode
does not have this issue, because concurrently at most one request is being processed.

GitLab is working to remove Rugged usage. Even though performance without Rugged
is acceptable today, in some cases it might be still beneficial to run with it.

Given the caveat of running Rugged with multi-threaded Puma, and acceptable
performance of Gitaly, we disable Rugged usage if Puma multi-threaded is
used (when Puma is configured to run with more than one thread).

This default behavior may not be the optimal configuration in some situations. If Rugged
plays an important role in your deployment, we suggest you benchmark to find the
optimal configuration:

- The safest option is to start with single-threaded Puma.
- To force Rugged to be used with multi-threaded Puma, you can use a
  [feature flag](../../development/gitaly.md#legacy-rugged-code).

## Switch from Unicorn to Puma

NOTE:
For Helm-based deployments, see the
[`webservice` chart documentation](https://docs.gitlab.com/charts/charts/gitlab/webservice/index.html).

Starting with GitLab 13.0, Puma is the default web server and Unicorn has been disabled.
In GitLab 14.0, [Unicorn was removed](../../update/removals.md#unicorn-in-gitlab-self-managed)
from the Linux package and is no longer supported.

Puma has a multi-thread architecture that uses less memory than a multi-process
application server like Unicorn. On GitLab.com, we saw a 40% reduction in memory
consumption. Most Rails application requests normally include a proportion of I/O wait time.

During I/O wait time, MRI Ruby releases the GVL to other threads.
Multi-threaded Puma can therefore still serve more requests than a single process.

When switching to Puma, any Unicorn server configuration will _not_ carry over
automatically, due to differences between the two application servers.

To switch from Unicorn to Puma:

1. Determine suitable Puma [worker and thread settings](../../install/requirements.md#puma-settings).
1. Convert any custom Unicorn settings to Puma.

   The table below summarizes which Unicorn configuration keys correspond to those
   in Puma when using the Linux package, and which ones have no corresponding counterpart.

   | Unicorn                              | Puma                               |
   | ------------------------------------ | ---------------------------------- |
   | `unicorn['enable']`                  | `puma['enable']`                   |
   | `unicorn['worker_timeout']`          | `puma['worker_timeout']`           |
   | `unicorn['worker_processes']`        | `puma['worker_processes']`         |
   | n/a                                  | `puma['ha']`                       |
   | n/a                                  | `puma['min_threads']`              |
   | n/a                                  | `puma['max_threads']`              |
   | `unicorn['listen']`                  | `puma['listen']`                   |
   | `unicorn['port']`                    | `puma['port']`                     |
   | `unicorn['socket']`                  | `puma['socket']`                   |
   | `unicorn['pidfile']`                 | `puma['pidfile']`                  |
   | `unicorn['tcp_nopush']`              | n/a                                |
   | `unicorn['backlog_socket']`          | n/a                                |
   | `unicorn['somaxconn']`               | `puma['somaxconn']`                |
   | n/a                                  | `puma['state_path']`               |
   | `unicorn['log_directory']`           | `puma['log_directory']`            |
   | `unicorn['worker_memory_limit_min']` | n/a                                |
   | `unicorn['worker_memory_limit_max']` | `puma['per_worker_max_memory_mb']` |
   | `unicorn['exporter_enabled']`        | `puma['exporter_enabled']`         |
   | `unicorn['exporter_address']`        | `puma['exporter_address']`         |
   | `unicorn['exporter_port']`           | `puma['exporter_port']`            |

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Optional. For multi-node deployments, configure the load balancer to use the
   [readiness check](../load_balancer.md#readiness-check).

## Related topics

- [Use the Puma exporter to measure various Puma metrics](../monitoring/prometheus/puma_exporter.md)
