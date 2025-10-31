---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD Jobs
description: Configuration, rules, caching, artifacts, and logs.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD jobs are the fundamental elements of a [GitLab CI/CD pipeline](../pipelines/_index.md).
Jobs are configured in the `.gitlab-ci.yml` file with a list of commands to execute
to accomplish tasks like building, testing, or deploying code.

Jobs:

- Execute on a [runner](../runners/_index.md), for example in a Docker container.
- Run independently from other jobs.
- Have a [job log](job_logs.md) with the full execution log for the job.

Jobs are defined with [YAML keywords](../yaml/_index.md) that define all aspects
of the job's execution, including keywords that:

- Control [how](job_control.md) and [when](job_rules.md) jobs run.
- Group jobs together in collections called [stages](../yaml/_index.md#stages).
  Stages run in sequence, while all jobs in a stage can run in parallel.
- Define [CI/CD variables](../variables/_index.md) for flexible configuration.
- Define [caches](../caching/_index.md) to speed up job execution.
- Save files as [artifacts](job_artifacts.md) which can be used by other jobs.

## Add a job to a pipeline

To add a job to a pipeline, add it into your `.gitlab-ci.yml` file. The job must:

- Be defined at the top-level of the YAML configuration.
- Have a unique [job name](#job-names).
- Have either a [`script`](../yaml/_index.md#script) section defining commands to run,
  or a [`trigger`](../yaml/_index.md#trigger) section to trigger a [downstream pipeline](../pipelines/downstream_pipelines.md)
  to run.

For example:

```yaml
my-ruby-job:
  script:
    - bundle install
    - bundle exec my_ruby_command

my-shell-script-job:
  script:
    - my_shell_script.sh
```

### Job names

You can't use these keywords as job names:

- `image`
- `services`
- `stages`
- `before_script`
- `after_script`
- `variables`
- `cache`
- `include`
- `pages:deploy` configured for a `deploy` stage

Additionally, these names are valid when quoted, but are
not recommended as they can make pipeline configuration unclear:

- `"true":`
- `"false":`
- `"nil":`

Job names must be 255 characters or fewer.

Use unique names for your jobs. If multiple jobs have the same name in a file,
only one is added to the pipeline, and it's difficult to predict which one is chosen.
If the same job name is used in one or more included files,
[parameters are merged](../yaml/includes.md#override-included-configuration-values).

### Hide a job

To temporarily disable a job without deleting it from the configuration
file, add a period (`.`) to the start of the job name. Hidden jobs do not need to contain
the `script` or `trigger` keywords, but must contain valid YAML configuration.

For example:

```yaml
.hidden_job:
  script:
    - run test
```

Hidden jobs are not processed by GitLab CI/CD, but they can be used as templates
for reusable configuration with:

- The [`extends` keyword](../yaml/yaml_optimization.md#use-extends-to-reuse-configuration-sections).
- [YAML anchors](../yaml/yaml_optimization.md#anchors).

## Set default values for job keywords

You can use the `default` keyword to set default job keywords and values, which are
used by default by all jobs in a pipeline.

For example:

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

rspec-job:
  script: bundle exec rspec
```

When the pipeline runs, the job uses the default keywords:

```yaml
rspec-job:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World
  script: bundle exec rspec
```

### Control the inheritance of default keywords and variables

You can control the inheritance of:

- [default keywords](../yaml/_index.md#default) with [`inherit:default`](../yaml/_index.md#inheritdefault).
- [default variables](../yaml/_index.md#default) with [`inherit:variables`](../yaml/_index.md#inheritvariables).

For example:

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

variables:
  DOMAIN: example.com
  WEBHOOK_URL: https://my-webhook.example.com

rubocop:
  inherit:
    default: false
    variables: false
  script: bundle exec rubocop

rspec:
  inherit:
    default: [image]
    variables: [WEBHOOK_URL]
  script: bundle exec rspec

capybara:
  inherit:
    variables: false
  script: bundle exec capybara

karma:
  inherit:
    default: true
    variables: [DOMAIN]
  script: karma
```

In this example:

- `rubocop`:
  - inherits: Nothing.
- `rspec`:
  - inherits: the default `image` and the `WEBHOOK_URL` variable.
  - does **not** inherit: the default `before_script` and the `DOMAIN` variable.
- `capybara`:
  - inherits: the default `before_script` and `image`.
  - does **not** inherit: the `DOMAIN` and `WEBHOOK_URL` variables.
- `karma`:
  - inherits: the default `image` and `before_script`, and the `DOMAIN` variable.
  - does **not** inherit: `WEBHOOK_URL` variable.

## View jobs in a pipeline

When you access a pipeline, you can see the related jobs for that pipeline.

The order of jobs in a pipeline depends on the type of pipeline graph.

- For [full pipeline graphs](../pipelines/_index.md#pipeline-details), jobs are sorted alphabetically by name.
- For [pipeline mini graphs](../pipelines/_index.md#pipeline-mini-graphs), jobs are sorted by status severity
  with failed jobs appearing first, and then alphabetically by name.

Selecting an individual job shows you its [job log](job_logs.md), and allows you to:

- Cancel the job.
- Retry the job, if it failed.
- Run the job again, if it passed.
- Erase the job log.

### View project jobs

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Job name filter [added](https://gitlab.com/gitlab-org/gitlab/-/issues/387547) as an [experiment](../../policy/development_stages_support.md) on GitLab.com and GitLab Self-Managed in GitLab 17.3 [with flags](../../administration/feature_flags/_index.md) named `populate_and_use_build_names_table` for the API and `fe_search_build_by_name` for the UI. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/512149) in GitLab 18.5. Feature flags `populate_and_use_build_names_table` and `fe_search_build_by_name` removed.
- Job kind filter [added](https://gitlab.com/gitlab-org/gitlab/-/issues/555434) in GitLab 18.3.

{{< /history >}}

To view jobs that ran in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build** > **Jobs**.

You can filter the list by job status, source, name, and kind.

{{< alert type="note" >}}

The filter by name returns jobs created in the last 30 days. This retention period applies to both UI and API filtering.

{{< /alert >}}

By default, the filter shows only build jobs. To view trigger jobs, clear the filter, then select **Kind** > **Trigger**.

{{< alert type="note" >}}

The **Kind** filter is available only for project jobs. It is not available in the **Admin** area.

{{< /alert >}}

### Available job statuses

CI/CD jobs can have the following statuses:

- `canceled`: Job was manually canceled or automatically aborted.
- `canceling`: Job is being canceled but `after_script` is running.
- `created`: Job has been created but not yet processed.
- `failed`: Job execution failed.
- `manual`: Job requires manual action to start.
- `pending`: Job is in the queue waiting for a runner.
- `preparing`: Runner is preparing the execution environment.
- `running`: Job is executing on a runner.
- `scheduled`: Job has been scheduled but execution hasn't started.
- `skipped`: Job was skipped due to conditions or dependencies.
- `success`: Job completed successfully.
- `waiting_for_resource`: Job is waiting for resources to become available.

### View the source of a job

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181159) job source in GitLab 17.9 [with a flag](../../administration/feature_flags/_index.md) named `populate_and_use_build_source_table`. Enabled by default.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/11796) on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in GitLab 17.11.

{{< /history >}}

GitLab CI/CD jobs now include a source attribute that indicates the action that initially triggered a CI/CD job.
Use this attribute to track how a job was initiated or filter job runs based on the specific sources.

#### Available job sources

The source attribute can have the following values:

- `api`: Job initiated by a REST call to the Jobs API.
- `chat`: Job initiated by a chat command using GitLab ChatOps.
- `container_registry_push`: Job initiated by container registry push.
- `duo_workflow`: Job initiated by GitLab Duo Agent Platform.
- `external`: Job initiated by an event in an external repository integrated with GitLab. This does not include pull request events.
- `external_pull_request_event`: Job initiated by a pull request event in an external repository.
- `merge_request_event`: Job initiated by a merge request event.
- `ondemand_dast_scan`: Job initiated by an on-demand DAST scan.
- `ondemand_dast_validation`: Job initiated by an on-demand DAST validation.
- `parent_pipeline`: Job initiated by a parent pipeline
- `pipeline`: Job initiated by a user manually running a pipeline.
- `pipeline_execution_policy`: Job initiated by a triggered pipeline execution policy.
- `pipeline_execution_policy_schedule`: Job initiated by a scheduled pipeline execution policy.
- `push`: Job initiated by a code push.
- `scan_execution_policy`: Job initiated by a scan execution policy.
- `schedule`: Job initiated by a scheduled pipeline.
- `security_orchestration_policy`: Job initiated by a scheduled scan execution policy.
- `trigger`: Job initiated by another job or pipeline.
- `unknown`: Job initiated by an unknown source.
- `web`: Job initiated by a user from the GitLab UI.
- `webide`: Job initiated by a user from the Web IDE.

### Group similar jobs together in pipeline views

If you have many similar jobs, your [pipeline graph](../pipelines/_index.md#pipeline-details)
becomes long and hard to read.

You can automatically group similar jobs together. If the job names are formatted in a certain way,
they are collapsed into a single group in regular pipeline graphs (not the mini graphs).

You can recognize when a pipeline has grouped jobs if you see a number next to a job
name instead of the retry or cancel buttons. The number indicates the amount of grouped
jobs. Hovering over them shows you if all jobs have passed or any has failed. Select to expand them.

![A pipeline graph showing several stages and jobs, including three groups of grouped jobs.](img/pipeline_grouped_jobs_v17_9.png)

To create a group of jobs, in the `.gitlab-ci.yml` file,
separate each job name with a number and one of the following:

- A slash (`/`), for example, `slash-test 1/3`, `slash-test 2/3`, `slash-test 3/3`.
- A colon (`:`), for example, `colon-test 1:3`, `colon-test 2:3`, `colon-test 3:3`.
- A space, for example `space-test 0 3`, `space-test 1 3`, `space-test 2 3`.

You can use these symbols interchangeably.

In the following example, these three jobs are in a group named `build ruby`:

```yaml
build ruby 1/3:
  stage: build
  script:
    - echo "ruby1"

build ruby 2/3:
  stage: build
  script:
    - echo "ruby2"

build ruby 3/3:
  stage: build
  script:
    - echo "ruby3"
```

The pipeline graph displays a group named `build ruby` with three jobs.

The jobs are ordered by comparing the numbers from left to right. You
usually want the first number to be the index and the second number to be the total.

[This regular expression](https://gitlab.com/gitlab-org/gitlab/-/blob/2f3dc314f42dbd79813e6251792853bc231e69dd/app/models/commit_status.rb#L99)
evaluates the job names: `([\b\s:]+((\[.*\])|(\d+[\s:\/\\]+\d+))){1,3}\s*\z`.
One or more `: [...]`, `X Y`, `X/Y`, or `X\Y` sequences are removed from the **end**
of job names only. Matching substrings found at the beginning or in the middle of
job names are not removed.

## Retry jobs

You can retry a job after it completes, regardless of its final state (failed, success, or canceled).

When you retry a job:

- A new job instance is created with a new job ID.
- The job runs with the same parameters and variables as the original job.
- If the job produces artifacts, new artifacts are created and stored.
- The new job associates with the user who initiated the retry, not the user who created the original pipeline.
- Any subsequent jobs that were previously skipped are reassigned to the user who initiated the retry.

When you retry a [trigger job](../yaml/_index.md#trigger) that triggers a downstream pipeline:

- The trigger job generates a new downstream pipeline.
- The downstream pipeline also associates with the user who initiated the retry.
- The downstream pipeline runs with the configuration that exists at the time of the retry,
  which might be different from the original run.

### Retry a job

Prerequisites:

- You must have at least the Developer role for the project.
- The job must not be [archived](../../administration/settings/continuous_integration.md#archive-pipelines).

To retry a job from a merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. From your merge request, do one of the following:
   - In the pipeline widget, next to the job you want to retry, select **Run again** ({{< icon name="retry" >}}).
   - Select the **Pipelines** tab, next to the job you want to retry, select **Run again** ({{< icon name="retry" >}}).

To retry a job from the job log:

1. Go to the job's log page.
1. In the upper-right corner, select **Run again** ({{< icon name="retry" >}}).

To retry a job from a pipeline:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build** > **Pipelines**.
1. Find the pipeline that contains the job you want to retry.
1. From the pipeline graph, next to the job you want to retry, select **Run again** ({{< icon name="retry" >}}).

### Retry all failed or canceled jobs in a pipeline

If a pipeline has multiple failed or canceled jobs, you can retry all of them at once:

1. On the left sidebar, select **Search or go to** and find your project.
1. Do one of the following:
   - Select **Build** > **Pipelines**.
   - Go to a merge request and select the **Pipelines** tab.
1. For the pipeline with failed or canceled jobs, select **Retry all failed or canceled jobs** ({{< icon name="retry" >}}).

## Cancel jobs

You can cancel a CI/CD job that hasn't completed yet.

When you cancel a job, what happens next depends on its state and the GitLab Runner version:

- For jobs that haven't started executing yet, the job is canceled immediately.
- For running jobs:
  - For GitLab Runner 16.10 and later with GitLab 17.0 and later:
    1. The job is marked as `canceling`.
    1. The currently-running command is allowed to complete. The rest of the commands in the job's
       [`before_script`](../yaml/_index.md#before_script) or [`script`](../yaml/_index.md#script) are skipped.
    1. If the job has an `after_script` section, it always starts and runs to completion.
    1. The job is marked as `canceled`.
  - For GitLab Runner 16.9 and earlier with GitLab 16.11 and earlier, the job is `canceled` immediately without running `after_script`.

If you need to cancel a job immediately without waiting for the `after_script`, use [force cancel](#force-cancel-a-job).

### Cancel a job

Prerequisites:

- You must have at least the Developer role for the project,
  or the [minimum role required to cancel a pipeline or job](../pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs).

To cancel a job from a merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. From your merge request, do one of the following:
   - In the pipeline widget, next to the job you want to cancel, select **Cancel** ({{< icon name="cancel" >}}).
   - Select the **Pipelines** tab, next to the job you want to cancel, select **Cancel** ({{< icon name="cancel" >}}).

To cancel a job from the job log:

1. Go to the job's log page.
1. In the upper-right corner, select **Cancel** ({{< icon name="cancel" >}}).

To cancel a job from a pipeline:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build** > **Pipelines**.
1. Find the pipeline that contains the job you want to cancel.
1. From the pipeline graph, next to the job you want to cancel, select **Cancel** ({{< icon name="cancel" >}}).

### Cancel all running jobs in a pipeline

You can cancel all jobs in a running pipeline at once.

1. On the left sidebar, select **Search or go to** and find your project.
1. Do one of the following:
   - Select **Build** > **Pipelines**.
   - Go to a merge request and select the **Pipelines** tab.
1. For the pipeline you want to cancel, select **Cancel the running pipeline** ({{< icon name="cancel" >}}).

### Force cancel a job

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/467107) as an [experiment](../../policy/development_stages_support.md) in GitLab 17.10 [with a flag](../../administration/feature_flags/_index.md) named `force_cancel_build`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/519313) in GitLab 17.11. Feature flag `force_cancel_build` removed.

{{< /history >}}

If you don't want to wait for `after_script` to finish or a job is unresponsive, you can force cancel it.
Force cancel immediately moves a job from the `canceling` state to `canceled`.

When you force cancel a job, the [job token](ci_job_token.md) is immediately revoked.
If the runner is still executing the job, it loses access to GitLab.
The runner aborts the job without waiting for `after_script` to complete.

Prerequisites:

- You must have at least the Maintainer role for the project.
- The job must be in the `canceling` state, which requires:
  - GitLab 17.0 and later.
  - GitLab Runner 16.10 and later.

To force cancel a job:

1. Go to the job's log page.
1. In the upper-right corner, select **Force cancel**.

## Troubleshoot a failed job

When a pipeline fails or is allowed to fail, there are several places where you
can find the reason:

- In the [pipeline graph](../pipelines/_index.md#pipeline-details), in the pipeline details view.
- In the pipeline widgets, in the merge requests and commit pages.
- In the job views, in the global and detailed views of a job.

In each place, if you hover over the failed job you can see the reason it failed.

![A pipeline graph showing a failed job and the failure-reason.](img/job_failure_reason_v17_9.png)

You can also see the reason it failed on the Job detail page.

### With Root Cause Analysis

You can use GitLab Duo Root Cause Analysis in GitLab Duo Chat to [troubleshoot failed CI/CD jobs](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis).

## Deployment jobs

Deployment jobs are CI/CD jobs that use [environments](../environments/_index.md).
A deployment job is any job that uses the `environment` keyword and the [`start` environment `action`](../yaml/_index.md#environmentaction).
Deployment jobs do not need to be in the `deploy` stage. The following `deploy me`
job is an example of a deployment job. `action: start` is the default behavior and
is defined here for clarity, but you can omit it:

```yaml
deploy me:
  script:
    - deploy-to-cats.sh
  environment:
    name: production
    url: https://cats.example.com
    action: start
```

The behavior of deployment jobs can be controlled with
[deployment safety](../environments/deployment_safety.md) settings like
[preventing outdated deployment jobs](../environments/deployment_safety.md#prevent-outdated-deployment-jobs)
and [ensuring only one deployment job runs at a time](../environments/deployment_safety.md#ensure-only-one-deployment-job-runs-at-a-time).
