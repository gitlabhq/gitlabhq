---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: howto
---

# GitLab CI/CD instance configuration **(FREE SELF)**

GitLab administrators can manage the GitLab CI/CD configuration for their instance.

## Disable GitLab CI/CD in new projects

GitLab CI/CD is enabled by default in all new projects on an instance. You can set
CI/CD to be disabled by default in new projects by modifying the settings in:

- `gitlab.yml` for source installations.
- `gitlab.rb` for Omnibus GitLab installations.

Existing projects that already had CI/CD enabled are unchanged. Also, this setting only changes
the project default, so project owners [can still enable CI/CD in the project settings](../ci/enable_or_disable_ci.md#enable-cicd-in-a-project).

For installations from source:

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

For Omnibus GitLab installations:

1. Edit `/etc/gitlab/gitlab.rb` and add this line:

   ```ruby
   gitlab_rails['gitlab_default_projects_features_builds'] = false
   ```

1. Save the `/etc/gitlab/gitlab.rb` file.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Set the `needs` job limit **(FREE SELF)**

The maximum number of jobs that can be defined in `needs` defaults to 50.

A GitLab administrator with [access to the GitLab Rails console](operations/rails_console.md#starting-a-rails-console-session)
can choose a custom limit. For example, to set the limit to `100`:

```ruby
Plan.default.actual_limits.update!(ci_needs_size_limit: 100)
```

To disable directed acyclic graphs (DAG), set the limit to `0`. Pipelines with jobs
configured to use `needs` then return the error `job can only need 0 others`.

## Change maximum scheduled pipeline frequency

[Scheduled pipelines](../ci/pipelines/schedules.md) can be configured with any [cron value](../topics/cron/index.md),
but they do not always run exactly when scheduled. An internal process, called the
_pipeline schedule worker_, queues all the scheduled pipelines, but does not
run continuously. The worker runs on its own schedule, and scheduled pipelines that
are ready to start are only queued the next time the worker runs. Scheduled pipelines
can't run more frequently than the worker.

The default frequency of the pipeline schedule worker is `3-59/10 * * * *` (every ten minutes,
starting with `0:03`, `0:13`, `0:23`, and so on). The default frequency for GitLab.com
is listed in the [GitLab.com settings](../user/gitlab_com/index.md#gitlab-cicd).

To change the frequency of the pipeline schedule worker:

1. Edit the `gitlab_rails['pipeline_schedule_worker_cron']` value in your instance's `gitlab.rb` file.
1. [Reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

For example, to set the maximum frequency of pipelines to twice a day, set `pipeline_schedule_worker_cron`
to a cron value of `0 */12 * * *` (`00:00` and `12:00` every day).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
