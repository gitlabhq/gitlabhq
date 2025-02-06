---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD maintenance console commands
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The following commands are run in the [Rails console](../operations/rails_console.md#starting-a-rails-console-session).

WARNING:
Any command that changes data directly could be damaging if not run correctly, or under the right conditions.
We highly recommend running them in a test environment with a backup of the instance ready to be restored, just in case.

## Cancel all running pipelines and their jobs

```ruby
admin = User.find(user_id) # replace user_id with the id of the admin you want to cancel the pipeline
# Iterate over each cancelable pipeline
Ci::Pipeline.cancelable.find_each do |pipeline|
  Ci::CancelPipelineService.new(
    pipeline: pipeline,
    current_user: user,
    cascade_to_children: false # the children are included in the outer loop
  )
end
```

## Cancel stuck pending pipelines

```ruby
project = Project.find_by_full_path('<project_path>')
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').each {|p| p.cancel if p.stuck?}
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
```

## Try merge request integration

```ruby
project = Project.find_by_full_path('<project_path>')
mr = project.merge_requests.find_by(iid: <merge_request_iid>)
mr.project.try(:ci_integration)
```

## Validate the `.gitlab-ci.yml` file

```ruby
project = Project.find_by_full_path('<project_path>')
content = p.ci_config_for(project.repository.root_ref_sha)
Gitlab::Ci::Lint.new(project: project, current_user: User.first).validate(content)
```

## Disable AutoDevOps on Existing Projects

```ruby
Project.all.each do |p|
  p.auto_devops_attributes={"enabled"=>"0"}
  p.save
end
```

## Run pipeline schedules manually

You can run pipeline schedules manually through the Rails console to reveal any errors that are usually not visible.

```ruby
# schedule_id can be obtained from Edit Pipeline Schedule page
schedule = Ci::PipelineSchedule.find_by(id: <schedule_id>)

# Select the user that you want to run the schedule for
user = User.find_by_username('<username>')

# Run the schedule
ps = Ci::CreatePipelineService.new(schedule.project, user, ref: schedule.ref).execute!(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
```

<!--- start_remove The following content will be removed on remove_date: '2025-08-15' -->

## Obtain runners registration token (deprecated)

WARNING:
The ability to pass a runner registration token, and support for certain configuration arguments, was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and is planned for removal
in GitLab 18.0. Runner authentication tokens should be used instead. For more information, see
[Migrating to the new runner registration workflow](../../ci/runners/new_creation_workflow.md).

Prerequisites:

- Runner registration tokens must be [enabled](../settings/continuous_integration.md#allow-runner-registrations-tokens) in the **Admin** area.

```ruby
Gitlab::CurrentSettings.current_application_settings.runners_registration_token
```

## Seed runners registration token (deprecated)

WARNING:
The ability to pass a runner registration token, and support for certain configuration arguments, was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and is planned for removal
in GitLab 18.0. Runner authentication tokens should be used instead. For more information, see
[Migrating to the new runner registration workflow](../../ci/runners/new_creation_workflow.md).

```ruby
appSetting = Gitlab::CurrentSettings.current_application_settings
appSetting.set_runners_registration_token('<new-runners-registration-token>')
appSetting.save!
```

<!--- end_remove -->