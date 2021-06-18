---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Puma **(FREE SELF)**

Puma is a simple, fast, multi-threaded, and highly concurrent HTTP 1.1 server for
Ruby applications. It's the default GitLab web server since GitLab 13.0
and has replaced Unicorn. From GitLab 14.0, Unicorn is no longer supported.

NOTE:
Starting with GitLab 13.0, Puma is the default web server and Unicorn has been disabled.
In GitLab 14.0, Unicorn was removed from the Linux package and only Puma is available.

## Configure Puma

To configure Puma:

1. Determine suitable Puma worker and thread [settings](../../install/requirements.md#puma-settings).
1. If you're switching from Unicorn, [convert any custom settings to Puma](#convert-unicorn-settings-to-puma).
1. For multi-node deployments, configure the load balancer to use the
   [readiness check](../load_balancer.md#readiness-check).
1. Reconfigure GitLab so the above changes take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

For Helm-based deployments, see the
[`webservice` chart documentation](https://docs.gitlab.com/charts/charts/gitlab/webservice/index.html).

For more details about the Puma configuration, see the
[Puma documentation](https://github.com/puma/puma#configuration).

## Puma Worker Killer

By default:

- The [Puma Worker Killer](https://github.com/schneems/puma_worker_killer) restarts a worker if it
  exceeds a [memory limit](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/cluster/puma_worker_killer_initializer.rb).
- Rolling restarts of Puma workers are performed every 12 hours.

To change the memory limit setting:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   puma['per_worker_max_memory_mb'] = 1024
   ```

1. Reconfigure GitLab for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Worker timeout

A [timeout of 60 seconds](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/rack_timeout.rb)
is used when Puma is enabled.

NOTE:
Unlike Unicorn, the `puma['worker_timeout']` setting does not set the maximum request duration.

To change the worker timeout:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['env'] = {
      'GITLAB_RAILS_RACK_TIMEOUT' => 600
    }
   ```

1. Reconfigure GitLab for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Memory-constrained environments

In a memory-constrained environment with less than 4GB of RAM available, consider disabling Puma
[Clustered mode](https://github.com/puma/puma#clustered-mode).

Configuring Puma by setting the amount of `workers` to `0` could reduce memory usage by hundreds of MB.
For details on Puma worker and thread settings, see the [Puma requirements](../../install/requirements.md#puma-settings).

Unlike in a Clustered mode, which is set up by default, only a single Puma process would serve the application.

The downside of running Puma with such configuration is the reduced throughput, which could be
considered as a fair tradeoff in a memory-constraint environment.

When running Puma in Single mode, some features are not supported:

- Phased restart do not work: [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/300665)
- [Phased restart](https://gitlab.com/gitlab-org/gitlab/-/issues/300665)
- [Puma Worker Killer](https://gitlab.com/gitlab-org/gitlab/-/issues/300664)

To learn more, visit [epic 5303](https://gitlab.com/groups/gitlab-org/-/epics/5303).

## Performance caveat when using Puma with Rugged

For deployments where NFS is used to store Git repository, we allow GitLab to use
[direct Git access](../gitaly/index.md#direct-access-to-git-in-gitlab) to improve performance using
[Rugged](https://github.com/libgit2/rugged).

Rugged usage is automatically enabled if direct Git access
[is available](../gitaly/index.md#how-it-works)
and Puma is running single threaded, unless it is disabled by
[feature flags](../../development/gitaly.md#legacy-rugged-code).

MRI Ruby uses a GVL. This allows MRI Ruby to be multi-threaded, but running at
most on a single core. Since Rugged can use a thread for long periods of
time (due to intensive I/O operations of Git access), this can starve other threads
that might be processing requests. This is not a case for Unicorn or Puma running
in a single thread mode, as concurrently at most one request is being processed.

We are actively working on removing Rugged usage. Even though performance without Rugged
is acceptable today, in some cases it might be still beneficial to run with it.

Given the caveat of running Rugged with multi-threaded Puma, and acceptable
performance of Gitaly, we disable Rugged usage if Puma multi-threaded is
used (when Puma is configured to run with more than one thread).

This default behavior may not be the optimal configuration in some situations. If Rugged
plays an important role in your deployment, we suggest you benchmark to find the
optimal configuration:

- The safest option is to start with single-threaded Puma. When working with
  Rugged, single-threaded Puma works the same as Unicorn.
- To force Rugged to be used with multi-threaded Puma, you can use
  [feature flags](../../development/gitaly.md#legacy-rugged-code).

## Convert Unicorn settings to Puma

NOTE:
Starting with GitLab 13.0, Puma is the default web server and Unicorn has been
disabled by default. In GitLab 14.0, Unicorn was removed from the Linux package
and only Puma is available.

Puma has a multi-thread architecture which uses less memory than a multi-process
application server like Unicorn. On GitLab.com, we saw a 40% reduction in memory
consumption. Most Rails applications requests normally include a proportion of I/O wait time.

During I/O wait time MRI Ruby releases the GVL (Global VM Lock) to other threads.
Multi-threaded Puma can therefore still serve more requests than a single process.

When switching to Puma, any Unicorn server configuration will _not_ carry over
automatically, due to differences between the two application servers.

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
