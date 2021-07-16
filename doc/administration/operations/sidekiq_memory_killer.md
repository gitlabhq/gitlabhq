---
stage: Enablement
group: Memory
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sidekiq MemoryKiller

The GitLab Rails application code suffers from memory leaks. For web requests
this problem is made manageable using
[`puma-worker-killer`](https://github.com/schneems/puma_worker_killer) which
restarts Puma worker processes if it exceeds a memory limit. The Sidekiq
MemoryKiller applies the same approach to the Sidekiq processes used by GitLab
to process background jobs.

Unlike puma-worker-killer, which is enabled by default for all GitLab
installations of GitLab 13.0 and later, the Sidekiq MemoryKiller is enabled by default
_only_ for Omnibus packages. The reason for this is that the MemoryKiller
relies on runit to restart Sidekiq after a memory-induced shutdown and GitLab
installations from source do not all use runit or an equivalent.

With the default settings, the MemoryKiller causes a Sidekiq restart no
more often than once every 15 minutes, with the restart causing about one
minute of delay for incoming background jobs.

Some background jobs rely on long-running external processes. To ensure these
are cleanly terminated when Sidekiq is restarted, each Sidekiq process should be
run as a process group leader (for example, using `chpst -P`). If using Omnibus or the
`bin/background_jobs` script with `runit` installed, this is handled for you.

## Configuring the MemoryKiller

The MemoryKiller is controlled using environment variables.

- `SIDEKIQ_DAEMON_MEMORY_KILLER`: defaults to 1. When set to 0, the MemoryKiller
  works in _legacy_ mode. Otherwise, the MemoryKiller works in _daemon_ mode.

  In _legacy_ mode, the MemoryKiller checks the Sidekiq process RSS
  ([Resident Set Size](https://github.com/mperham/sidekiq/wiki/Memory#rss))
  after each job.

  In _daemon_ mode, the MemoryKiller checks the Sidekiq process RSS every 3 seconds
  (defined by `SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL`).

- `SIDEKIQ_MEMORY_KILLER_MAX_RSS` (KB): if this variable is set, and its value is greater
  than 0, the MemoryKiller is enabled. Otherwise the MemoryKiller is disabled.

  `SIDEKIQ_MEMORY_KILLER_MAX_RSS` defines the Sidekiq process allowed RSS.

  In _legacy_ mode, if the Sidekiq process exceeds the allowed RSS then an irreversible
  delayed graceful restart is triggered. The restart of Sidekiq happens
  after `SIDEKIQ_MEMORY_KILLER_GRACE_TIME` seconds.

  In _daemon_ mode, if the Sidekiq process exceeds the allowed RSS for longer than
  `SIDEKIQ_MEMORY_KILLER_GRACE_TIME` the graceful restart is triggered. If the
  Sidekiq process go below the allowed RSS within `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`,
  the restart is aborted.

  The default value for Omnibus packages is set
  [in the Omnibus GitLab
  repository](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb).

- `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS` (KB): is used by _daemon_ mode. If the Sidekiq
  process RSS (expressed in kilobytes) exceeds `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS`,
  an immediate graceful restart of Sidekiq is triggered.

- `SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL`: used in _daemon_ mode to define how
  often to check process RSS, default to 3 seconds.

- `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`: defaults to 900 seconds (15 minutes).
  The usage of this variable is described as part of `SIDEKIQ_MEMORY_KILLER_MAX_RSS`.

- `SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT`: defaults to 30 seconds. This defines the
  maximum time allowed for all Sidekiq jobs to finish. No new jobs are accepted
  during that time, and the process exits as soon as all jobs finish.

  If jobs do not finish during that time, the MemoryKiller interrupts all currently
  running jobs by sending `SIGTERM` to the Sidekiq process.

  If the process hard shutdown/restart is not performed by Sidekiq,
  the Sidekiq process is forcefully terminated after
  `Sidekiq.options[:timeout] + 2` seconds. An external supervision mechanism
  (for example, runit) must restart Sidekiq afterwards.
