---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Performing operations in GitLab **(FREE SELF)**

Keep your GitLab instance up and running smoothly.

- [Clean up Redis sessions](cleaning_up_redis_sessions.md): Prior to GitLab 7.3,
  user sessions did not automatically expire from Redis. If
  you have been running a large GitLab server (thousands of users) since before
  GitLab 7.3 we recommend cleaning up stale sessions to compact the Redis
  database after you upgrade to GitLab 7.3.
- [Rake tasks](../../raketasks/index.md): Tasks for common administration and operational processes such as
  [cleaning up unneeded items from GitLab instance](../../raketasks/cleanup.md), integrity checks,
  and more.
- [Moving repositories](moving_repositories.md): Moving all repositories managed
  by GitLab to another file system or another server.
- [Sidekiq MemoryKiller](sidekiq_memory_killer.md): Configure Sidekiq MemoryKiller
  to restart Sidekiq.
- [Multiple Sidekiq processes](extra_sidekiq_processes.md): Configure multiple Sidekiq processes to ensure certain queues always have dedicated workers, no matter the number of jobs that need to be processed. **(FREE SELF)**
- [Sidekiq routing rules](extra_sidekiq_routing.md): Configure the routing rules to route a job from a worker to a desirable queue. **(FREE SELF)**
- [Puma](puma.md): Understand Puma and puma-worker-killer.
- Speed up SSH operations by [Authorizing SSH users via a fast,
  indexed lookup to the GitLab database](fast_ssh_key_lookup.md), and/or
  by [doing away with user SSH keys stored on GitLab entirely in favor
  of SSH certificates](ssh_certificates.md).
- [File System Performance Benchmarking](filesystem_benchmarking.md): File system
  performance can have a big impact on GitLab performance, especially for actions
  that read or write Git repositories. This information will help benchmark
  file system performance against known good and bad real-world systems.
- [The Rails Console](rails_console.md): Provides a way to interact with your GitLab instance from the command line.
  Used for troubleshooting a problem or retrieving some data that can only be done through direct access to GitLab.
- [ChatOps Scripts](https://gitlab.com/gitlab-com/chatops): The GitLab.com Infrastructure team uses this repository to house
  common ChatOps scripts they use to troubleshoot and maintain the production instance of GitLab.com.
  These scripts are likely useful to administrators of GitLab instances of all sizes.
