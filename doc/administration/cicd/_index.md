---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD instance configuration
description: Manage GitLab CI/CD configuration.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab administrators can manage the GitLab CI/CD configuration for their instance.

## Disable GitLab CI/CD in new projects

GitLab CI/CD is enabled by default in all new projects on an instance. You can set
CI/CD to be disabled by default in new projects by modifying the settings in:

- `gitlab.yml` for self-compiled installations.
- `gitlab.rb` for Linux package installations.

Existing projects that already had CI/CD enabled are unchanged. Also, this setting only changes
the project default, so project owners [can still enable CI/CD in the project settings](../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines).

For self-compiled installations:

1. Open `gitlab.yml` with your editor and set `builds` to `false`:

   ```yaml
   ## Default project features settings
   default_projects_features:
     issues: true
     merge_requests: true
     wiki: true
     snippets: false
     builds: false
   ```

1. Save the `gitlab.yml` file.
1. Restart GitLab:

   ```shell
   sudo service gitlab restart
   ```

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb` and add this line:

   ```ruby
   gitlab_rails['gitlab_default_projects_features_builds'] = false
   ```

1. Save the `/etc/gitlab/gitlab.rb` file.
1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Disaster recovery

You can disable some important but computationally expensive parts of the application
to relieve stress on the database during ongoing downtime.

### Disable fair scheduling on instance runners

When clearing a large backlog of jobs, you can temporarily enable the `ci_queueing_disaster_recovery_disable_fair_scheduling`
[feature flag](../feature_flags/_index.md). This flag disables fair scheduling
on instance runners, which reduces system resource usage on the `jobs/request` endpoint.

When enabled, jobs are processed in the order they were put in the system, instead of
balanced across many projects.

### Disable compute quota enforcement

To disable the enforcement of [compute minutes quotas](compute_minutes.md) on instance runners, you can temporarily
enable the `ci_queueing_disaster_recovery_disable_quota` [feature flag](../feature_flags/_index.md).
This flag reduces system resource usage on the `jobs/request` endpoint.

When enabled, jobs created in the last hour can run in projects which are out of quota.
Earlier jobs are already canceled by a periodic background worker (`StuckCiJobsWorker`).
