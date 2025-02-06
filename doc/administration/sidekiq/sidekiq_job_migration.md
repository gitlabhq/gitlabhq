---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sidekiq job migration Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

WARNING:
This operation should be very uncommon. We do not recommend it for the vast majority of GitLab instances.

Sidekiq routing rules allow administrators to re-route certain background jobs from their regular queue to an alternative queue. By default, GitLab uses one queue per background job type. GitLab has over 400 background job types, and so correspondingly it has over 400 queues.

Most administrators do not need to change this setting. In some cases with particularly large background job processing workloads, Redis performance may suffer due to the number of queues that GitLab listens to.

If the Sidekiq routing rules are changed, administrators need to take care with the migration to avoid losing jobs entirely. The basic migration steps are:

1. Listen to both the old and new queues.
1. Update the routing rules.
1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. Run the [Rake tasks for migrating queued and future jobs](#migrate-queued-and-future-jobs).
1. Stop listening to the old queues.

## Migrate queued and future jobs

Step 4 involves rewriting some Sidekiq job data for jobs that are already stored in Redis, but due to run in future. There are two sets of jobs to run in future: scheduled jobs and jobs to be retried. We provide a separate Rake task to migrate each set:

- `gitlab:sidekiq:migrate_jobs:retry` for jobs to be retried.
- `gitlab:sidekiq:migrate_jobs:schedule` for scheduled jobs.

Queued jobs that are yet to be run can also be migrated with a Rake task ([available in GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101348) and later):

- `gitlab:sidekiq:migrate_jobs:queued` for queued jobs to be performed asynchronously.

Most of the time, running all three at the same time is the correct choice. There are three separate tasks to allow for more fine-grained control where needed. To run all three at once ([available in GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101348) and later):

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued

# source installations
bundle exec rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued RAILS_ENV=production
```
