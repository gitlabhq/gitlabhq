---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Troubleshooting CI/CD **(FREE)**

GitLab provides several tools to help make troubleshooting your pipelines easier.

This guide also lists common issues and possible solutions.

## Verify syntax

An early source of problems can be incorrect syntax. The pipeline shows a `yaml invalid`
badge and does not start running if any syntax or formatting problems are found.

### Edit `.gitlab-ci.yml` with the pipeline editor

The [pipeline editor](pipeline_editor/index.md) is the recommended editing
experience (rather than the single file editor or the Web IDE). It includes:

- Code completion suggestions that ensure you are only using accepted keywords.
- Automatic syntax highlighting and validation.
- The [CI/CD configuration visualization](pipeline_editor/index.md#visualize-ci-configuration),
  a graphical representation of your `.gitlab-ci.yml` file.

### Edit `.gitlab-ci.yml` locally

If you prefer to edit your pipeline configuration locally, you can use the
GitLab CI/CD schema in your editor to verify basic syntax issues. Any
[editor with Schemastore support](https://www.schemastore.org/json/#editors) uses
the GitLab CI/CD schema by default.

If you need to link to the schema directly, it
is at:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json
```

To see the full list of custom tags covered by the CI/CD schema, check the
latest version of the schema.

### Verify syntax with CI Lint tool

The [CI Lint tool](lint.md) is a simple way to ensure the syntax of a CI/CD configuration
file is correct. Paste in full `.gitlab-ci.yml` files or individual jobs configuration,
to verify the basic syntax.

When a `.gitlab-ci.yml` file is present in a project, you can also use the CI Lint
tool to [simulate the creation of a full pipeline](lint.md#simulate-a-pipeline).
It does deeper verification of the configuration syntax.

## Verify variables

A key part of troubleshooting CI/CD is to verify which variables are present in a
pipeline, and what their values are. A lot of pipeline configuration is dependent
on variables, and verifying them is one of the fastest ways to find the source of
a problem.

[Export the full list of variables](variables/index.md#list-all-variables)
available in each problematic job. Check if the variables you expect are present,
and check if their values are what you expect.

## GitLab CI/CD documentation

The [complete `.gitlab-ci.yml` reference](yaml/index.md) contains a full list of
every keyword you can use to configure your pipelines.

You can also look at a large number of pipeline configuration [examples](examples/index.md)
and [templates](examples/index.md#cicd-templates).

### Documentation for pipeline types

Branch pipelines are the most basic type.
Other pipeline types have their own detailed usage guides that you should read
if you are using that type:

- [Multi-project pipelines](pipelines/downstream_pipelines.md#multi-project-pipelines): Have your pipeline trigger
  a pipeline in a different project.
- [Parent/child pipelines](pipelines/downstream_pipelines.md#parent-child-pipelines): Have your main pipeline trigger
  and run separate pipelines in the same project. You can also
  [dynamically generate the child pipeline's configuration](pipelines/downstream_pipelines.md#dynamic-child-pipelines)
  at runtime.
- [Merge request pipelines](pipelines/merge_request_pipelines.md): Run a pipeline
  in the context of a merge request.
  - [Merged results pipelines](pipelines/merged_results_pipelines.md):
    Merge request pipelines that run on the combined source and target branch
  - [Merge trains](pipelines/merge_trains.md):
    Multiple merged results pipelines that queue and run automatically before
    changes are merged.

### Troubleshooting Guides for CI/CD features

Troubleshooting guides are available for some CI/CD features and related topics:

- [Container Registry](../user/packages/container_registry/troubleshoot_container_registry.md)
- [GitLab Runner](https://docs.gitlab.com/runner/faq/)
- [Merge Trains](pipelines/merge_trains.md#troubleshooting)
- [Docker Build](docker/using_docker_build.md#troubleshooting)
- [Environments](environments/deployment_safety.md#ensure-only-one-deployment-job-runs-at-a-time)

## Common CI/CD issues

A lot of common pipeline issues can be fixed by analyzing the behavior of the `rules`
or `only/except` configuration. You shouldn't use these two configurations in the same
pipeline, as they behave differently. It's hard to predict how a pipeline runs with
this mixed behavior.

If your `rules` or `only/except` configuration makes use of [predefined variables](variables/predefined_variables.md)
like `CI_PIPELINE_SOURCE`, `CI_MERGE_REQUEST_ID`, you should [verify them](#verify-variables)
as the first troubleshooting step.

### Jobs or pipelines don't run when expected

The `rules` or `only/except` keywords are what determine whether or not a job is
added to a pipeline. If a pipeline runs, but a job is not added to the pipeline,
it's usually due to `rules` or `only/except` configuration issues.

If a pipeline does not seem to run at all, with no error message, it may also be
due to `rules` or `only/except` configuration, or the `workflow: rules` keyword.

If you are converting from `only/except` to the `rules` keyword, you should check
the [`rules` configuration details](yaml/index.md#rules) carefully. The behavior
of `only/except` and `rules` is different and can cause unexpected behavior when migrating
between the two.

The [common `if` clauses for `rules`](jobs/job_control.md#common-if-clauses-for-rules)
can be very helpful for examples of how to write rules that behave the way you expect.

#### Two pipelines run at the same time

Two pipelines can run when pushing a commit to a branch that has an open merge request
associated with it. Usually one pipeline is a merge request pipeline, and the other
is a branch pipeline.

This situation is usually caused by the `rules` configuration, and there are several ways to
[prevent duplicate pipelines](jobs/job_control.md#avoid-duplicate-pipelines).

#### A job is not in the pipeline

GitLab determines if a job is added to a pipeline based on the [`only/except`](yaml/index.md#only--except)
or [`rules`](yaml/index.md#rules) defined for the job. If it didn't run, it's probably
not evaluating as you expect.

#### No pipeline or the wrong type of pipeline runs

Before a pipeline can run, GitLab evaluates all the jobs in the configuration and tries
to add them to all available pipeline types. A pipeline does not run if no jobs are added
to it at the end of the evaluation.

If a pipeline did not run, it's likely that all the jobs had `rules` or `only/except` that
blocked them from being added to the pipeline.

If the wrong pipeline type ran, then the `rules` or `only/except` configuration should
be checked to make sure the jobs are added to the correct pipeline type. For
example, if a merge request pipeline did not run, the jobs may have been added to
a branch pipeline instead.

It's also possible that your [`workflow: rules`](yaml/index.md#workflow) configuration
blocked the pipeline, or allowed the wrong pipeline type.

### Pipeline with many jobs fails to start

A Pipeline that has more jobs than the instance's defined [CI/CD limits](../user/admin_area/settings/continuous_integration.md#set-cicd-limits)
fails to start.

To reduce the number of jobs in your pipeline, you can split your `.gitlab-ci.yml`
configuration using [parent-child pipelines](../ci/pipelines/pipeline_architectures.md#parent-child-pipelines).

### A job runs unexpectedly

A common reason a job is added to a pipeline unexpectedly is because the `changes`
keyword always evaluates to true in certain cases. For example, `changes` is always
true in certain pipeline types, including scheduled pipelines and pipelines for tags.

The `changes` keyword is used in combination with [`only/except`](yaml/index.md#onlychanges--exceptchanges)
or [`rules`](yaml/index.md#ruleschanges)). It's recommended to use `changes` with
`rules` or `only/except` configuration that ensures the job is only added to branch
pipelines or merge request pipelines.

### "fatal: reference is not a tree" error

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17043) in GitLab 12.4.

Previously, you'd have encountered unexpected pipeline failures when you force-pushed
a branch to its remote repository. To illustrate the problem, suppose you've had the current workflow:

1. A user creates a feature branch named `example` and pushes it to a remote repository.
1. A new pipeline starts running on the `example` branch.
1. A user rebases the `example` branch on the latest default branch and force-pushes it to its remote repository.
1. A new pipeline starts running on the `example` branch again, however,
   the previous pipeline (2) fails because of `fatal: reference is not a tree:` error.

This occurs because the previous pipeline cannot find a checkout-SHA (which is associated with the pipeline record)
from the `example` branch that the commit history has already been overwritten by the force-push.
Similarly, [Merged results pipelines](pipelines/merged_results_pipelines.md)
might have failed intermittently due to [the same reason](pipelines/merged_results_pipelines.md#pipelines-fail-intermittently-with-a-fatal-reference-is-not-a-tree-error).

As of GitLab 12.4, we've improved this behavior by persisting pipeline refs exclusively.
To illustrate its life cycle:

1. A pipeline is created on a feature branch named `example`.
1. A persistent pipeline ref is created at `refs/pipelines/<pipeline-id>`,
   which retains the checkout-SHA of the associated pipeline record.
   This persistent ref stays intact during the pipeline execution,
   even if the commit history of the `example` branch has been overwritten by force-push.
1. The runner fetches the persistent pipeline ref and gets source code from the checkout-SHA.
1. When the pipeline finishes, its persistent ref is cleaned up in a background process.

### Merge request pipeline messages

The merge request pipeline widget shows information about the pipeline status in
a merge request. It's displayed above the [ability to merge status widget](#merge-request-status-messages).

#### "Checking ability to merge automatically" message

There is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/229352)
where a merge request can be stuck with the `Checking ability to merge automatically`
message.

If your merge request has this message and it does not disappear after a few minutes,
you can try one of these workarounds:

- Refresh the merge request page.
- Close & Re-open the merge request.
- Rebase the merge request with the `/rebase` [quick action](../user/project/quick_actions.md).
- If you have already confirmed the merge request is ready to be merged, you can merge
  it with the `/merge` quick action.

#### "Checking pipeline status" message

This message is shown when the merge request has no pipeline associated with the
latest commit yet. This might be because:

- GitLab hasn't finished creating the pipeline yet.
- You are using an external CI service and GitLab hasn't heard back from the service yet.
- You are not using CI/CD pipelines in your project.
- You are using CI/CD pipelines in your project, but your configuration prevented a pipeline from running on the source branch for your merge request.
- The latest pipeline was deleted (this is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/214323)).
- The source branch of the merge request is on a private fork.

After the pipeline is created, the message updates with the pipeline status.

### Merge request status messages

The merge request status widget shows the **Merge** button and whether or not a merge
request is ready to merge. If the merge request can't be merged, the reason for this
is displayed.

If the pipeline is still running, **Merge** is replaced with the
**Merge when pipeline succeeds** button.

If [**Merge Trains**](pipelines/merge_trains.md)
are enabled, the button is either **Add to merge train** or **Add to merge train when pipeline succeeds**. **(PREMIUM)**

#### "A CI/CD pipeline must run and be successful before merge" message

This message is shown if the [Pipelines must succeed](../user/project/merge_requests/merge_when_pipeline_succeeds.md#require-a-successful-pipeline-for-merge)
setting is enabled in the project and a pipeline has not yet run successfully.
This also applies if the pipeline has not been created yet, or if you are waiting
for an external CI service. If you don't use pipelines for your project, then you
should disable **Pipelines must succeed** so you can accept merge requests.

#### "Merge blocked: pipeline must succeed. Push a new commit that fixes the failure" message

This message is shown if the [merge request pipeline](pipelines/merge_request_pipelines.md),
[merged results pipeline](pipelines/merged_results_pipelines.md),
or [merge train pipeline](pipelines/merge_trains.md)
has failed or been canceled.
This does not happen when a basic branch pipeline fails.

If a merge request pipeline or merged result pipeline was canceled or failed, you can:

- Re-run the entire pipeline by selecting **Run pipeline** in the pipeline tab in the merge request.
- [Retry only the jobs that failed](pipelines/index.md#view-pipelines). If you re-run the entire pipeline, this is not necessary.
- Push a new commit to fix the failure.

If the merge train pipeline has failed, you can:

- Check the failure and determine if you can use the [`/merge` quick action](../user/project/quick_actions.md) to immediately add the merge request to the train again.
- Re-run the entire pipeline by selecting **Run pipeline** in the pipeline tab in the merge request, then add the merge request to the train again.
- Push a commit to fix the failure, then add the merge request to the train again.

If the merge train pipeline was canceled before the merge request was merged, without a failure, you can:

- Add it to the train again.

### Project `group/project` not found or access denied

This message is shown if configuration is added with [`include`](yaml/index.md#include) and one of the following:

- The configuration refers to a project that can't be found.
- The user that is running the pipeline is unable to access any included projects.

To resolve this, check that:

- The path of the project is in the format `my-group/my-project` and does not include
  any folders in the repository.
- The user running the pipeline is a [member of the projects](../user/project/members/index.md#add-users-to-a-project)
  that contain the included files. Users must also have the [permission](../user/permissions.md#job-permissions)
  to run CI/CD jobs in the same projects.

### "The parsed YAML is too big" message

This message displays when the YAML configuration is too large or nested too deeply.
YAML files with a large number of includes, and thousands of lines overall, are
more likely to hit this memory limit. For example, a YAML file that is 200kb is
likely to hit the default memory limit.

To reduce the configuration size, you can:

- Check the length of the expanded CI/CD configuration in the pipeline editor's
  [Full configuration](pipeline_editor/index.md#view-full-configuration) tab. Look for
  duplicated configuration that can be removed or simplified.
- Move long or repeated `script` sections into standalone scripts in the project.
- Use [parent and child pipelines](pipelines/downstream_pipelines.md#parent-child-pipelines) to move some
  work to jobs in an independent child pipeline.

On a self-managed instance, you can [increase the size limits](../administration/instance_limits.md#maximum-size-and-depth-of-cicd-configuration-yaml-files).

### Error 500 when editing the `.gitlab-ci.yml` file

A [loop of included configuration files](pipeline_editor/index.md#configuration-validation-currently-not-available-message)
can cause a `500` error when editing the `.gitlab-ci.yml` file with the [web editor](../user/project/repository/web_editor.md).

### A CI/CD job does not use newer configuration when run again

The configuration for a pipeline is only fetched when the pipeline is created.
When you rerun a job, uses the same configuration each time. If you update configuration files,
including separate files added with [`include`](yaml/index.md#include), you must
start a new pipeline to use the new configuration.

## Pipeline warnings

Pipeline configuration warnings are shown when you:

- [Validate configuration with the CI Lint tool](yaml/index.md).
- [Manually run a pipeline](pipelines/index.md#run-a-pipeline-manually).

### "Job may allow multiple pipelines to run for a single action" warning

When you use [`rules`](yaml/index.md#rules) with a `when` clause without an `if`
clause, multiple pipelines may run. Usually this occurs when you push a commit to
a branch that has an open merge request associated with it.

To [prevent duplicate pipelines](jobs/job_control.md#avoid-duplicate-pipelines), use
[`workflow: rules`](yaml/index.md#workflow) or rewrite your rules to control
which pipelines can run.

### Console workaround if job using `resource_group` gets stuck **(FREE SELF)**

```ruby
# find resource group by name
resource_group = Project.find_by_full_path('...').resource_groups.find_by(key: 'the-group-name')
busy_resources = resource_group.resources.where('build_id IS NOT NULL')

# identify which builds are occupying the resource
# (I think it should be 1 as of today)
busy_resources.pluck(:build_id)

# it's good to check why this build is holding the resource.
# Is it stuck? Has it been forcefully dropped by the system?
# free up busy resources
busy_resources.update_all(build_id: nil)
```

### Job log slow to update

When you visit the job log page for a running job, there could be a delay of up to
60 seconds before the log updates. The default refresh time is 60 seconds, but after
the log is viewed in the UI, the following log updates should occur every 3 seconds.

## Disaster recovery

You can disable some important but computationally expensive parts of the application
to relieve stress on the database during ongoing downtime.

### Disable fair scheduling on shared runners

When clearing a large backlog of jobs, you can temporarily enable the `ci_queueing_disaster_recovery_disable_fair_scheduling`
[feature flag](../administration/feature_flags.md). This flag disables fair scheduling
on shared runners, which reduces system resource usage on the `jobs/request` endpoint.

When enabled, jobs are processed in the order they were put in the system, instead of
balanced across many projects.

### Disable CI/CD minutes quota enforcement

To disable the enforcement of CI/CD minutes quotas on shared runners, you can temporarily
enable the `ci_queueing_disaster_recovery_disable_quota` [feature flag](../administration/feature_flags.md).
This flag reduces system resource usage on the `jobs/request` endpoint.

When enabled, jobs created in the last hour can run in projects which are out of quota.
Earlier jobs are already canceled by a periodic background worker (`StuckCiJobsWorker`).

## CI/CD troubleshooting rails console commands

The following commands are run in the [rails console](../administration/operations/rails_console.md#starting-a-rails-console-session).

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
content = p.repository.gitlab_ci_yml_for(project.repository.root_ref_sha)
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

## How to get help

If you are unable to resolve pipeline issues, you can get help from:

- The [GitLab community forum](https://forum.gitlab.com/)
- GitLab [Support](https://about.gitlab.com/support/)
