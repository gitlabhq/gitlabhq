---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Reducing memory use
---

The GitLab Rails application code suffers from memory leaks. For web requests
this problem is made manageable using a [supervision thread](../operations/puma.md#reducing-memory-use)
that automatically restarts workers if they exceed a given resident set size (RSS) threshold
for a certain amount of time.
We use the same approach to the Sidekiq processes used by GitLab
to process background jobs.

GitLab monitors the available RSS limit by default only for Linux package or Docker installations. The reason for this
is that GitLab relies on runit to restart Sidekiq after a memory-induced shutdown, and self-compiled and Helm chart
installations don't use runit or an equivalent tool.

With the default settings, Sidekiq restarts no
more often than once every 15 minutes, with the restart causing about one
minute of delay for incoming background jobs.

Some background jobs rely on long-running external processes. To ensure these
are cleanly terminated when Sidekiq is restarted, each Sidekiq process should be
run as a process group leader (for example, using `chpst -P`). If using a Linux package installation or the
`bin/background_jobs` script with `runit` installed, this is handled for you.

## Configuring the limits

Sidekiq memory limits are controlled using [environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html#setting-custom-environment-variables)

- `SIDEKIQ_MEMORY_KILLER_MAX_RSS` (KB): defines the Sidekiq process soft limit for allowed RSS.
  If the Sidekiq process RSS (expressed in kilobytes) exceeds `SIDEKIQ_MEMORY_KILLER_MAX_RSS`,
  for longer than `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`, the graceful restart is triggered.
  If `SIDEKIQ_MEMORY_KILLER_MAX_RSS` is not set, or its value is set to 0, the soft limit is not monitored.
  `SIDEKIQ_MEMORY_KILLER_MAX_RSS` defaults to `2000000`.

- `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`: defines the grace time period in seconds for which the Sidekiq process is allowed to run
  above the allowed RSS soft limit. If the Sidekiq process goes below the allowed RSS (soft limit)
  within `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`, the restart is aborted. Default value is 900 seconds (15 minutes).

- `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS` (KB): defines the Sidekiq process hard limit for allowed RSS.
  If the Sidekiq process RSS (expressed in kilobytes) exceeds `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS`,
  an immediate graceful restart of Sidekiq is triggered. If this value is not set, or set to 0,
  the hard limit is not be monitored.

- `SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL`: defines how often to check the process RSS. Defaults to 3 seconds.

- `SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT`: defines the maximum time allowed for all Sidekiq jobs to finish.
  No new jobs are accepted during that time. Defaults to 30 seconds.

  If the process restart is not performed by Sidekiq, the Sidekiq process is forcefully terminated after
  [Sidekiq shutdown timeout](https://github.com/mperham/sidekiq/wiki/Signals#term) (defaults to 25 seconds) +2 seconds.
  If jobs do not finish during that time, all currently running jobs are interrupted with a `SIGTERM` signal
  sent to the Sidekiq process.

- `GITLAB_MEMORY_WATCHDOG_ENABLED`: enabled by default. Set the `GITLAB_MEMORY_WATCHDOG_ENABLED` to false, to disable Watchdog from running.

### Monitor worker restarts

GitLab emits log events if workers are restarted due to high memory usage.

The following is an example of one of these log events in `/var/log/gitlab/gitlab-rails/sidekiq_client.log`:

```json
{
  "severity": "WARN",
  "time": "2023-02-04T09:45:16.173Z",
  "correlation_id": null,
  "pid": 2725,
  "worker_id": "sidekiq_1",
  "memwd_handler_class": "Gitlab::Memory::Watchdog::SidekiqHandler",
  "memwd_sleep_time_s": 3,
  "memwd_rss_bytes": 1079683247,
  "memwd_max_rss_bytes": 629145600,
  "memwd_max_strikes": 5,
  "memwd_cur_strikes": 6,
  "message": "rss memory limit exceeded",
  "running_jobs": [
    {
      jid: "83efb701c59547ee42ff7068",
      worker_class: "Ci::DeleteObjectsWorker"
    },
    {
      jid: "c3a74503dc2637f8f9445dd3",
      worker_class: "Ci::ArchiveTraceWorker"
    }
  ]
}
```

Where:

- `memwd_rss_bytes` is the actual amount of memory consumed.
- `memwd_max_rss_bytes` is the RSS limit set through `per_worker_max_memory_mb`.
- `running jobs` lists the jobs that were running at the time when the process
  exceeded the RSS limit and started a graceful restart.
