# Performing Operations in GitLab

Keep your GitLab instance up and running smoothly.

- [Clean up Redis sessions](cleaning_up_redis_sessions.md): Prior to GitLab 7.3,
user sessions did not automatically expire from Redis. If
you have been running a large GitLab server (thousands of users) since before
GitLab 7.3 we recommend cleaning up stale sessions to compact the Redis
database after you upgrade to GitLab 7.3.
- [Moving repositories](moving_repositories.md): Moving all repositories managed
by GitLab to another file system or another server.
- [Sidekiq job throttling](sidekiq_job_throttling.md): Throttle Sidekiq queues
that to prioritize important jobs.
- [Sidekiq MemoryKiller](sidekiq_memory_killer.md): Configure Sidekiq MemoryKiller
to restart Sidekiq.
- [Extra Sidekiq operations](extra_sidekiq_processes.md): Configure an extra set of Sidekiq processes to ensure certain queues always have dedicated workers, no matter the amount of jobs that need to be processed. **[STARTER ONLY]**
- [Unicorn](unicorn.md): Understand Unicorn and unicorn-worker-killer.
- [Speed up SSH operations](fast_ssh_key_lookup.md): Authorize SSH users via a fast, indexed lookup to the GitLab database.
