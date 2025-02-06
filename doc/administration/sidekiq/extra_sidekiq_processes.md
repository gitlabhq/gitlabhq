---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Run multiple Sidekiq processes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab allows you to start multiple Sidekiq processes to process background jobs
at a higher rate on a single instance. By default, Sidekiq starts one worker
process and only uses a single core.

NOTE:
The information in this page applies only to Linux package installations.

## Start multiple processes

When starting multiple processes, the number of processes should at most equal
(and **not** exceed) the number of CPU cores you want to dedicate to Sidekiq.
The Sidekiq worker process uses no more than one CPU core.

To start multiple processes, use the `sidekiq['queue_groups']` array setting to
specify how many processes to create using `sidekiq-cluster` and which queues
they should handle. Each item in the array equates to one additional Sidekiq
process, and values in each item determine the queues it works on. In the vast
majority of cases, all processes should listen to all queues (see
[processing specific job classes](processing_specific_job_classes.md) for more
details).

For example, to create four Sidekiq processes, each listening
to all available queues:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['queue_groups'] = ['*'] * 4
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

To view the Sidekiq processes in GitLab:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Background jobs**.

## Concurrency

By default each process defined under `sidekiq` starts with a number of threads
that equals the number of queues, plus one spare thread, up to a maximum of 50.
For example, a process that handles all queues uses 50 threads by default.

These threads run inside a single Ruby process, and each process can only use a
single CPU core. The usefulness of threading depends on the work having some
external dependencies to wait on, like database queries or HTTP requests. Most
Sidekiq deployments benefit from this threading.

### Manage thread counts explicitly

The correct maximum thread count (also called concurrency) depends on the
workload. Typical values range from `5` for highly CPU-bound tasks to `15` or
higher for mixed low-priority work. A reasonable starting range is `15` to `25`
for a non-specialized deployment.

The values vary according to the work each specific deployment of Sidekiq does.
Any other specialized deployments with processes dedicated to specific queues
should have the concurrency tuned according to:

- The CPU usage of each type of process.
- The throughput achieved.

Each thread requires a Redis connection, so adding threads may increase Redis
latency and potentially cause client timeouts. See the
[Sidekiq documentation about Redis](https://github.com/mperham/sidekiq/wiki/Using-Redis)
for more details.

#### Manage thread counts with concurrency field

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/439687) in GitLab 16.9.

In GitLab 16.9 and later, you can set the concurrency by setting `concurrency`. This value explicitly sets each process
with this amount of concurrency.

For example, to set the concurrency to `20`:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['concurrency'] = 20
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Modify the check interval

To modify the Sidekiq health check interval for the additional Sidekiq
processes:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   sidekiq['interval'] = 5
   ```

   The value can be any integer number of seconds.

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Troubleshoot using the CLI

WARNING:
It's recommended to use `/etc/gitlab/gitlab.rb` to configure the Sidekiq processes.
If you experience a problem, you should contact GitLab support. Use the command
line at your own risk.

For debugging purposes, you can start extra Sidekiq processes by using the command
`/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster`. This command
takes arguments using the following syntax:

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster [QUEUE,QUEUE,...] [QUEUE, ...]
```

The `--dryrun` argument allows viewing the command to be executed without
actually starting it.

Each separate argument denotes a group of queues that have to be processed by a
Sidekiq process. Multiple queues can be processed by the same process by
separating them with a comma instead of a space.

Instead of a queue, a queue namespace can also be provided, to have the process
automatically listen on all queues in that namespace without needing to
explicitly list all the queue names. For more information about queue namespaces,
see the relevant section in the
[Sidekiq development documentation](../../development/sidekiq/_index.md#queue-namespaces).

### Monitor the `sidekiq-cluster` command

The `sidekiq-cluster` command does not terminate once it has started the desired
amount of Sidekiq processes. Instead, the process continues running and
forwards any signals to the child processes. This allows you to stop all
Sidekiq processes as you send a signal to the `sidekiq-cluster` process,
instead of having to send it to the individual processes.

If the `sidekiq-cluster` process crashes or receives a `SIGKILL`, the child
processes terminate themselves after a few seconds. This ensures you don't
end up with zombie Sidekiq processes.

This allows you to monitor the processes by hooking up
`sidekiq-cluster` to your supervisor of choice (for example, runit).

If a child process died the `sidekiq-cluster` command signals all remaining
process to terminate, then terminate itself. This removes the need for
`sidekiq-cluster` to re-implement complex process monitoring/restarting code.
Instead you should make sure your supervisor restarts the `sidekiq-cluster`
process whenever necessary.

### PID files

The `sidekiq-cluster` command can store its PID in a file. By default no PID
file is written, but this can be changed by passing the `--pidfile` option to
`sidekiq-cluster`. For example:

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster --pidfile /var/run/gitlab/sidekiq_cluster.pid process_commit
```

Keep in mind that the PID file contains the PID of the `sidekiq-cluster`
command and not the PIDs of the started Sidekiq processes.

### Environment

The Rails environment can be set by passing the `--environment` flag to the
`sidekiq-cluster` command, or by setting `RAILS_ENV` to a non-empty value. The
default value can be found in `/opt/gitlab/etc/gitlab-rails/env/RAILS_ENV`.
