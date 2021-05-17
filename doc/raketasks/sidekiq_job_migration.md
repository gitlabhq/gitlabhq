---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sidekiq job migration **(FREE SELF)**

WARNING:
This operation should be very uncommon. We do not recommend it for the vast majority of GitLab instances.

Sidekiq routing rules allow administrators to re-route certain background jobs from their regular queue to an alternative queue. By default, GitLab uses one queue per background job type. GitLab has over 400 background job types, and so correspondingly it has over 400 queues.

Most administrators will not need to change this setting. In some cases with particularly large background job processing workloads, Redis performance may suffer due to the number of queues that GitLab listens to.

If the Sidekiq routing rules are changed, administrators need to take care with the migration to avoid losing jobs entirely. The basic migration steps are:

1. Listen to both the old and new queues.
1. Update the routing rules.
1. Wait until there are no publishers dispatching jobs to the old queues.
1. Run the [Rake tasks for future jobs](#future-jobs).
1. Wait for the old queues to be empty.
1. Stop listening to the old queues.

## Future jobs

Step 4 involves rewriting some Sidekiq job data for jobs that are already stored in Redis, but due to run in future. There are two sets of jobs to run in future: scheduled jobs and jobs to be retried. We provide a separate Rake task to migrate each set:

- `gitlab:sidekiq:migrate_jobs:retry` for jobs to be retried.
- `gitlab:sidekiq:migrate_jobs:scheduled` for scheduled jobs.

Most of the time, running both at the same time is the correct choice. There are two separate tasks to allow for more fine-grained control where needed. To run both at once:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule

# source installations
bundle exec rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule RAILS_ENV=production
```
