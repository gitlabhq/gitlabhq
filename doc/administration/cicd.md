---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab CI/CD instance configuration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

GitLab administrators can manage the GitLab CI/CD configuration for their instance.

## Disable GitLab CI/CD in new projects

GitLab CI/CD is enabled by default in all new projects on an instance. You can set
CI/CD to be disabled by default in new projects by modifying the settings in:

- `gitlab.yml` for self-compiled installations.
- `gitlab.rb` for Linux package installations.

Existing projects that already had CI/CD enabled are unchanged. Also, this setting only changes
the project default, so project owners [can still enable CI/CD in the project settings](../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines).

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

## Set the `needs` job limit

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

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
1. [Reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

For example, to set the maximum frequency of pipelines to twice a day, set `pipeline_schedule_worker_cron`
to a cron value of `0 */12 * * *` (`00:00` and `12:00` every day).

## Disaster recovery

You can disable some important but computationally expensive parts of the application
to relieve stress on the database during ongoing downtime.

### Disable fair scheduling on instance runners

When clearing a large backlog of jobs, you can temporarily enable the `ci_queueing_disaster_recovery_disable_fair_scheduling`
[feature flag](../administration/feature_flags.md). This flag disables fair scheduling
on instance runners, which reduces system resource usage on the `jobs/request` endpoint.

When enabled, jobs are processed in the order they were put in the system, instead of
balanced across many projects.

### Disable compute quota enforcement

To disable the enforcement of [compute quotas](../ci/pipelines/cicd_minutes.md) on instance runners, you can temporarily
enable the `ci_queueing_disaster_recovery_disable_quota` [feature flag](../administration/feature_flags.md).
This flag reduces system resource usage on the `jobs/request` endpoint.

When enabled, jobs created in the last hour can run in projects which are out of quota.
Earlier jobs are already canceled by a periodic background worker (`StuckCiJobsWorker`).

## CI/CD troubleshooting Rails console commands

The following commands are run in the [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session).

WARNING:
Any command that changes data directly could be damaging if not run correctly, or under the right conditions.
We highly recommend running them in a test environment with a backup of the instance ready to be restored, just in case.

### Cancel stuck pending pipelines

```ruby
project = Project.find_by_full_path('<project_path>')
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').each {|p| p.cancel if p.stuck?}
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
```

### Try merge request integration

```ruby
project = Project.find_by_full_path('<project_path>')
mr = project.merge_requests.find_by(iid: <merge_request_iid>)
mr.project.try(:ci_integration)
```

### Validate the `.gitlab-ci.yml` file

```ruby
project = Project.find_by_full_path('<project_path>')
content = p.ci_config_for(project.repository.root_ref_sha)
Gitlab::Ci::Lint.new(project: project,  current_user: User.first).validate(content)
```

### Disable AutoDevOps on Existing Projects

```ruby
Project.all.each do |p|
  p.auto_devops_attributes={"enabled"=>"0"}
  p.save
end
```

### Obtain runners registration token

```ruby
Gitlab::CurrentSettings.current_application_settings.runners_registration_token
```

### Seed runners registration token

```ruby
appSetting = Gitlab::CurrentSettings.current_application_settings
appSetting.set_runners_registration_token('<new-runners-registration-token>')
appSetting.save!
```

### Run pipeline schedules manually

You can run pipeline schedules manually through the Rails console to reveal any errors that are usually not visible.

```ruby
# schedule_id can be obtained from Edit Pipeline Schedule page
schedule = Ci::PipelineSchedule.find_by(id: <schedule_id>)

# Select the user that you want to run the schedule for
user = User.find_by_username('<username>')

# Run the schedule
ps = Ci::CreatePipelineService.new(schedule.project, user, ref: schedule.ref).execute!(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
```
