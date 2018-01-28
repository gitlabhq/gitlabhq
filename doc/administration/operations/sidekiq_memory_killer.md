# Sidekiq MemoryKiller

The GitLab Rails application code suffers from memory leaks. For web requests
this problem is made manageable using
[unicorn-worker-killer](https://github.com/kzk/unicorn-worker-killer) which
restarts Unicorn worker processes in between requests when needed. The Sidekiq
MemoryKiller applies the same approach to the Sidekiq processes used by GitLab
to process background jobs.

Unlike unicorn-worker-killer, which is enabled by default for all GitLab
installations since GitLab 6.4, the Sidekiq MemoryKiller is enabled by default
_only_ for Omnibus packages. The reason for this is that the MemoryKiller
relies on Runit to restart Sidekiq after a memory-induced shutdown and GitLab
installations from source do not all use Runit or an equivalent.

With the default settings, the MemoryKiller will cause a Sidekiq restart no
more often than once every 15 minutes, with the restart causing about one
minute of delay for incoming background jobs.

## Configuring the MemoryKiller

The MemoryKiller is controlled using environment variables.

- `SIDEKIQ_MEMORY_KILLER_MAX_RSS`: if this variable is set, and its value is
  greater than 0, then after each Sidekiq job, the MemoryKiller will check the
  RSS of the Sidekiq process that executed the job. If the RSS of the Sidekiq
  process (expressed in kilobytes) exceeds SIDEKIQ_MEMORY_KILLER_MAX_RSS, a
  delayed shutdown is triggered. The default value for Omnibus packages is set
  [in the omnibus-gitlab
  repository](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb).
- `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`: defaults to 900 seconds (15 minutes). When
  a shutdown is triggered, the Sidekiq process will keep working normally for
  another 15 minutes.
- `SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT`: defaults to 30 seconds. When the grace
  time has expired, the MemoryKiller tells Sidekiq to stop accepting new jobs.
  Existing jobs get 30 seconds to finish. After that, the MemoryKiller tells
  Sidekiq to shut down, and an external supervision mechanism (e.g. Runit) must
  restart Sidekiq.
