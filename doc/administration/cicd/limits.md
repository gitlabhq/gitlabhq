---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure CI/CD limits for pipelines, jobs, schedules, and artifacts to control resource usage on your instance.
title: CI/CD limits
---

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can manage many CI/CD-related instance limits through the [admin area](../admin_area.md).
The other limits can only be changed by modifying the instance configuration through the GitLab Rails console.

GitLab.com might have different values than the defaults for GitLab Self-Managed.
Review the [CI/CD limits and settings for GitLab.com](../../user/gitlab_com/_index.md#cicd).

## Instance CI/CD variable limit

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/456845) in GitLab 17.1.

{{< /history >}}

The number of [CI/CD variables](../../ci/variables/_index.md) that can be defined in
instance settings is limited. This limits is checked each time a new variable is created.
If a new variable would cause the total number of variables to exceed the limit,
the new variable is not created.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum number of Instance-level CI/CD variables that can be defined**.
   The default is `25`.
1. Select **Save changes**.

## Limit dotenv file size

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791) in GitLab 17.1.

{{< /history >}}

You can set a limit on the maximum size of a dotenv artifact. This limit is checked
every time a dotenv file is exported as an artifact.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum size of a dotenv artifact in bytes**.
1. Select **Save changes**.

Set the limit to `0` to disable it. Defaults to 5 KB.

## Limit dotenv variables

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791) in GitLab 17.1.

{{< /history >}}

You can set a limit on the maximum number of variables inside of a dotenv artifact.
This limit is checked every time a dotenv file is exported as an artifact.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum number of variables in a dotenv artifact**.
1. Select **Save changes**.

Set the limit to `0` to disable it. Defaults to `20`.

You can also set this limit by using the [Plan limits API](../../api/plan_limits.md).

## Maximum number of jobs in a pipeline

{{< history >}}

- Setting [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/287669) from GitLab Enterprise Edition to GitLab Community Edition in 17.6.

{{< /history >}}

You can limit the maximum number of jobs in a pipeline. The number
of jobs in a pipeline is checked at pipeline creation and when new commit statuses are created.
Pipelines that have too many jobs fail with a `size_limit_exceeded` error.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum number of jobs in a single pipeline**.
1. Select **Save changes**.

Set the limit to `0` to disable it. Disabled by default.

## Number of jobs in active pipelines

The total number of jobs in active pipelines can be limited per project. This limit is checked
each time a new pipeline is created. An active pipeline is any pipeline in one of the following states:

- `created`
- `pending`
- `running`

If a new pipeline would cause the total number of jobs to exceed the limit, the pipeline
fails with a `job_activity_limit_exceeded` error.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Total number of jobs in currently active pipelines**.
1. Select **Save changes**.

Set the limit to `0` to disable it. Disabled by default.

## Number of CI/CD subscriptions to a project

The total number of subscriptions can be limited per project. This limit is
checked each time a new subscription is created.

If a new subscription would cause the total number of subscription to exceed the
limit, the subscription is considered invalid.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum number of pipeline subscriptions to and from a project**.
1. Select **Save changes**.

By default, there is a limit of `2` subscriptions. Set the limit to `0` to disable it.

## Number of pipeline schedules

The total number of pipeline schedules can be limited per project. This limit is
checked each time a new pipeline schedule is created. If a new pipeline schedule
would cause the total number of pipeline schedules to exceed the limit, the
pipeline schedule is not created.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum number of pipeline schedules**.
1. Select **Save changes**.

By default, there is a limit of `10` pipeline schedules.

You can also use the [Plan Limits API](../../api/plan_limits.md).

## Maximum number of needs dependencies

You can set a maximum number of needs dependencies that a single job can have.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum number of needs dependencies that a job can have**
1. Select **Save changes**.

This limit cannot be disabled. Defaults to `50`.

Set to `0` to block all needs dependencies. Pipelines with jobs configured to use `needs`
then return the error `job can only need 0 others`.

## Number of registered runners for groups and projects

{{< history >}}

- Runner stale timeout [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155795) from 3 months to 7 days in GitLab 17.1.

{{< /history >}}

The total number of registered runners is limited for groups and projects. Each time a new runner is registered,
GitLab checks these limits against runners created or active in the last 7 days.
A runner's registration fails if it exceeds the limit for the scope determined by the runner registration token.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for either:
   - **Maximum number of runners created or active in a group during the past seven days**
   - **Maximum number of runners created or active in a project during the past seven days**
1. Select **Save changes**.

Set the limit to `0` to disable it.

## Limit pipeline hierarchy size

By default, a [pipeline hierarchy](../../ci/pipelines/downstream_pipelines.md) can contain up to 1000 downstream pipelines.
When this limit is exceeded, pipeline creation fails with the error `downstream pipeline tree is too large`.

> [!warning]
> Increasing this limit is not recommended. The default limit protects your GitLab instance from excessive resource consumption,
> potential pipeline recursion, and database overload.
>
> Instead of increasing the limit, restructure your CI/CD configuration by splitting large pipeline hierarchies into smaller pipelines.
> Consider using `needs` between jobs or dependent stages in a single pipeline.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum number of downstream pipelines in a pipeline's hierarchy tree**.
1. Select **Save changes**.

You can also use the [Plan Limits API](../../api/plan_limits.md).

## Merge train parallel pipeline limit

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/374188) in GitLab 19.0.

{{< /history >}}

By default, each [merge train](../../ci/pipelines/merge_trains.md) can run
a maximum of 20 pipelines in parallel. When this limit is reached,
additional merge requests are queued until a pipeline slot is available.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Under **CI/CD limits**, set a value for **Maximum parallel pipelines per merge train**.
   The minimum value is `1`. A value of `1` processes merge requests sequentially with no parallelism.
1. Select **Save changes**.

You can also use the [Plan Limits API](../../api/plan_limits.md).

You can set a different value [for a specific project](../../ci/pipelines/merge_trains.md#merge-train-parallel-pipeline-limit).

## Maximum time jobs can run

The default maximum time that jobs can run for is 60 minutes. Jobs that run for
more than 60 minutes time out.

You can change the maximum time a job can run before it times out:

- For a project in the [project's CI/CD settings](../../ci/pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)
  for a given project. This limit must be between 10 minutes and 1 month.
- [For a runner](../../ci/runners/configure_runners.md#set-the-maximum-job-timeout).
  This limit must be 10 minutes or longer.

Regardless of configured timeout limits, GitLab terminates any job that has been inactive for 60 minutes.
An inactive job is one that has produced no new logs or trace updates.

## Number of pipelines per Git push

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186134) in GitLab 18.0.

{{< /history >}}

> [!warning]
> Increasing this limit is not recommended. It can cause excessive load on your GitLab instance if many changes are pushed simultaneously, potentially creating a flood of pipelines.

When pushing multiple changes with a single Git push, like multiple tags or branches,
only four tag or branch pipelines can be triggered by default. This limit prevents the accidental
creation of a large number of pipelines when using `git push --all` or `git push --mirror`.

[Merge request pipelines](../../ci/pipelines/merge_request_pipelines.md) are limited.
If the Git push updates multiple merge requests at the same time, a merge request pipeline
can trigger for every updated merge request before reaching the limit.

The default value is `4` for GitLab Self-Managed and GitLab.com.

To change this limit on your GitLab Self-Managed instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Change the value of **Pipeline limit per Git push**.
1. Select **Save changes**.

## Pipeline creation rate limits

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362475) in GitLab 15.0 [with a flag](../feature_flags/_index.md) named `ci_enforce_throttle_pipelines_creation`. Disabled by default. Enabled on GitLab.com
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196545) in 18.3.

{{< /history >}}

You can set limits so that users and processes can't request more than a certain number of pipelines each minute.
These limits can help save resources and improve stability.

GitLab enforces two types of rate limits for pipeline creation:

- **Per project, commit, and user**: Limits pipelines created for the same combination of project,
  commit SHA, and user. Disabled by default.
- **Per user**: Limits total pipelines created by a user across all projects. Disabled by default.

For example, if you set a per-user limit of `100`, and a user sends `101` pipeline creation requests
to the [trigger API](../../ci/triggers/_index.md) within one minute across different projects,
the 101st request is blocked. Access to the endpoint is allowed again after one minute.

These limits are not applied per IP address.

Requests that exceed the limits are logged in the `application_json.log` file.

### Set pipeline request limits

Prerequisites:

- Administrator access.

To limit the number of pipeline requests:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Pipelines Rate Limits**.
   - Under **Max requests per minute per project, user, and commit**, enter a value greater than `0` to limit pipelines
     for the same project, commit, and user combination.
   - Under **Max requests per minute per user**, enter a value greater than `0` to limit total pipelines created by each user.
     Set to `0` for unlimited requests per minute.
1. Select **Save changes**.

Both rate limits are evaluated independently:

- A user creating multiple pipelines for the same commit SHA in a project is subject to the **per project, user, and commit** limit.
- A user creating pipelines across different projects or commits is subject to the **per user** limit.
- If either limit is exceeded, the pipeline creation request is blocked.

## Limit downstream pipeline trigger rate

Restrict how many [downstream pipelines](../../ci/pipelines/downstream_pipelines.md)
can be triggered per minute from a single source.

The maximum downstream pipeline trigger rate limits how many downstream pipelines
can be triggered per minute for a given combination of project, user, and commit.
The default value is `0`, which means there is no restriction.

To configure this limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Set a value for **Maximum downstream pipeline trigger rate**.
1. Select **Save changes**.

## Maximum artifacts size

Set size limits for job artifacts to control storage use.
Each artifact file in a job has a default maximum size of 100 MB.

Job artifacts defined with `artifacts:reports` can have [different limits](#maximum-file-size-per-type-of-artifact).
When different limits apply, the smaller value is used.

> [!note]
> This setting applies to the size of the final archive file, not individual files in a job.

You can configure artifact size limits for:

- An instance: The base setting that applies to all projects and groups.
- A group: Overrides the instance setting for all projects in the group.
- A project: Overrides both instance and group settings for a specific project.

For GitLab.com limits, see [Artifacts maximum size](../../user/gitlab_com/_index.md#cicd).

To change the maximum artifact size for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Enter a value in the **Maximum artifacts size (MB)** text box.
1. Select **Save changes**.

## Maximum number of includes

Limit how many external YAML files a pipeline can include using the [`include` keyword](../../ci/yaml/includes.md).
This limit prevents performance issues when pipelines include too many files.

By default, a pipeline can include up to 150 files.
When a pipeline exceeds this limit, it fails with an error.

To set the maximum number of included files per pipeline:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Enter a value in the **Maximum includes** text box.
1. Select **Save changes**.

## Maximum number of caches per job

{{< details >}}

- Status: Beta

{{< /details >}}

Limit how many [`cache`](../../ci/yaml/_index.md#cache) entries a single CI/CD job can define.
This limit caps the number of Gitaly calls a job can trigger during pipeline creation when caches use `cache:key:files`.

By default, a job can define up to 4 caches.
When a job exceeds this limit, the configuration fails to parse with an error.

The value must be at least 1. Raising the limit above the default can impact pipeline creation performance.

To change the maximum number of caches per job:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Enter a value in the **Maximum caches per job** text box.
1. Select **Save changes**.

## CI/CD limits instance configuration

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

Some CI/CD limits can be only be changed by editing the instance configuration.

Prerequisites:

- You must have access to the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session)
  for the instance.

### Maximum number of deployment jobs in a pipeline

You can limit the maximum number of deployment jobs in a pipeline. A deployment is
any job with an [`environment`](../../ci/environments/_index.md) specified. The number
of deployments in a pipeline is checked at pipeline creation. Pipelines that have
too many deployments fail with a `deployments_limit_exceeded` error.

To change the limit, change the `default` plan's limit with the following
[GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session) command:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_deployments: 500)
```

The default limit is `500`. Set the limit to `0` to disable it.

### Limit the number of pipeline triggers

You can set a limit on the maximum number of pipeline triggers per project. This
limit is checked every time a new trigger is created.

If a new trigger would cause the total number of pipeline triggers to exceed the
limit, the trigger is considered invalid.

Set the limit to `0` to disable it. Defaults to `25000`.

To set this limit to `100`, run the following in the
[GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session):

```ruby
Plan.default.actual_limits.update!(pipeline_triggers: 100)
```

### Limit the number of pipelines created by a pipeline schedule each day

You can limit the number of pipelines that each individual pipeline schedule can trigger per day.

Schedules that try to run pipelines more frequently than the limit are slowed to a maximum frequency.
The frequency is calculated by dividing 1440 (the number minutes in a day) by the
limit value. For example, for a maximum frequency of:

- Once per minute, the limit must be `1440`.
- Once per 10 minutes, the limit must be `144`.
- Once per 60 minutes, the limit must be `24`

The minimum value is `24`, or one pipeline per 60 minutes.
There is no maximum value.

To set this limit to `1440` on a GitLab Self-Managed instance, run the following in the
[GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session):

```ruby
Plan.default.actual_limits.update!(ci_daily_pipeline_schedule_triggers: 1440)
```

### Maximum scheduled pipeline frequency

[Scheduled pipelines](../../ci/pipelines/schedules.md) can be configured with any [cron value](../../topics/cron/_index.md),
but they do not always run exactly when scheduled. An internal process, called the
"pipeline schedule worker", queues all the scheduled pipelines, but does not
run continuously. The worker runs on its own schedule, and scheduled pipelines that
are ready to start are only queued the next time the worker runs. Scheduled pipelines
can't run more frequently than the worker.

The default frequency of the pipeline schedule worker is `3-59/10 * * * *` (every ten minutes,
starting with `0:03`, `0:13`, `0:23`, and so on). The default frequency for GitLab.com
is listed in the [GitLab.com settings](../../user/gitlab_com/_index.md#cicd).

To change the frequency of the pipeline schedule worker:

1. Edit the `gitlab_rails['pipeline_schedule_worker_cron']` value in your instance's `gitlab.rb` file.
1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

For example, to set the maximum frequency of pipelines to twice a day, set `pipeline_schedule_worker_cron`
to a cron value of `0 */12 * * *` (`00:00` and `12:00` every day).

When many pipeline schedules run at the same time, additional delays can occur.
The pipeline schedule worker processes pipelines in [batches](https://gitlab.com/gitlab-org/gitlab/-/blob/3426be1b93852c5358240c5df40970c0ddfbdb2a/app/workers/pipeline_schedule_worker.rb#L13-14)
with a small delay between each batch to distribute system load. This can cause pipeline
schedules to start several minutes to over an hour after their scheduled time, depending on system load.

### Limit the number of schedule rules defined for security policy project

You can limit the total number of schedule rules per security policy project. This limit is
checked each time policies with schedule rules are updated. If a new schedule rule would
cause the total number of schedule rules to exceed the limit, the new schedule rule is
not processed.

By default, GitLab does not limit the number of processable schedule rules.

To set this limit, run the following in the
[GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session):

```ruby
Plan.default.actual_limits.update!(security_policy_scan_execution_schedules: 100)
```

### Group and project CI/CD variable limits

The number of [CI/CD variables](../../ci/variables/_index.md) that can be defined in groups and projects,
are limited for the entire instance. These limits are checked each time a new variable is created.
If a new variable would cause the total number of variables to exceed the respective limit,
the new variable is not created.

To update the `default` plan of one of these limits, in the
[GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session) run the following command:

- [Group-level CI/CD variable](../../ci/variables/_index.md#for-a-group) limit per group (default: `30000`):

  ```ruby
  Plan.default.actual_limits.update!(group_ci_variables: 40000)
  ```

- [Project-level CI/CD variable](../../ci/variables/_index.md#for-a-project) limit per project (default: `8000`):

  ```ruby
  Plan.default.actual_limits.update!(project_ci_variables: 10000)
  ```

### Maximum file size per type of artifact

{{< history >}}

- `ci_max_artifact_size_annotations` limit [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) in GitLab 16.3.
- `ci_max_artifact_size_jacoco` limit [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159696) in GitLab 17.3
- `ci_max_artifact_size_lsif` limit [increased](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175684) in GitLab 17.8.

{{< /history >}}

Job artifacts defined with [`artifacts:reports`](../../ci/yaml/_index.md#artifactsreports)
that are uploaded by the runner are rejected if the file size exceeds the maximum
file size limit. The limit is determined by comparing the project's
[maximum artifact size setting](#maximum-artifacts-size)
with the instance limit for the given artifact type, and choosing the smaller value.

Limits are set in megabytes, so the smallest possible value that can be defined is `1 MB`.

Each type of artifact has a size limit that can be set. A default of `0` means there
is no limit for that specific artifact type, and the project's maximum artifact size
setting is used:

| Artifact limit name                         | Default value |
|---------------------------------------------|---------------|
| `ci_max_artifact_size_accessibility`        | 0             |
| `ci_max_artifact_size_annotations`          | 0             |
| `ci_max_artifact_size_api_fuzzing`          | 0             |
| `ci_max_artifact_size_archive`              | 0             |
| `ci_max_artifact_size_browser_performance`  | 0             |
| `ci_max_artifact_size_cluster_applications` | 0             |
| `ci_max_artifact_size_cobertura`            | 0             |
| `ci_max_artifact_size_codequality`          | 0             |
| `ci_max_artifact_size_container_scanning`   | 0             |
| `ci_max_artifact_size_coverage_fuzzing`     | 0             |
| `ci_max_artifact_size_dast`                 | 0             |
| `ci_max_artifact_size_dependency_scanning`  | 0             |
| `ci_max_artifact_size_dotenv`               | 0             |
| `ci_max_artifact_size_jacoco`               | 0             |
| `ci_max_artifact_size_junit`                | 0             |
| `ci_max_artifact_size_license_management`   | 0             |
| `ci_max_artifact_size_license_scanning`     | 0             |
| `ci_max_artifact_size_load_performance`     | 0             |
| `ci_max_artifact_size_lsif`                 | 200 MB        |
| `ci_max_artifact_size_metadata`             | 0             |
| `ci_max_artifact_size_metrics_referee`      | 0             |
| `ci_max_artifact_size_metrics`              | 0             |
| `ci_max_artifact_size_network_referee`      | 0             |
| `ci_max_artifact_size_performance`          | 0             |
| `ci_max_artifact_size_requirements`         | 0             |
| `ci_max_artifact_size_requirements_v2`      | 0             |
| `ci_max_artifact_size_sast`                 | 0             |
| `ci_max_artifact_size_secret_detection`     | 0             |
| `ci_max_artifact_size_terraform`            | 5 MB          |
| `ci_max_artifact_size_trace`                | 0             |
| `ci_max_artifact_size_cyclonedx`            | 5 MB          |

For example, to set the `ci_max_artifact_size_junit` limit to 10 MB on
GitLab Self-Managed, run the following in the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session):

```ruby
Plan.default.actual_limits.update!(ci_max_artifact_size_junit: 10)
```

### Maximum file size for job logs

The job log file size limit in GitLab is 100 megabytes by default. Any job that exceeds the
limit is marked as failed, and dropped by the runner.

You can change the limit in the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session).
Update `ci_jobs_trace_size_limit` with the new value in megabytes:

```ruby
Plan.default.actual_limits.update!(ci_jobs_trace_size_limit: 125)
```

GitLab Runner also has an [`output_limit` setting](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)
that configures the maximum log size in a runner. Jobs that exceed the runner limit
continue to run, but the log is truncated when it hits the limit.

### Maximum number of active DAST profile schedules per project

Limit the number of active DAST profile schedules per project. A DAST profile schedule can be active or inactive.

You can change the limit in the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session).
Update `dast_profile_schedules` with the new value:

```ruby
Plan.default.actual_limits.update!(dast_profile_schedules: 50)
```

### Maximum size of the CI artifacts archive

This setting is used to restrict YAML sizes for [dynamic child pipelines](../../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines).

The default maximum size of the CI artifacts archive is 5 megabytes.

You can change this limit by using the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session).
To update the maximum size of the CI artifacts archive,
update `max_artifacts_content_include_size` with the new value. For example, to set it to 20 MB:

```ruby
ApplicationSetting.update(max_artifacts_content_include_size: 20.megabytes)
```

### Maximum size and depth of CI/CD configuration YAML files

{{< history >}}

- Default value for `max_yaml_size_bytes` [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) in GitLab 17.3.

{{< /history >}}

The default maximum size of a single CI/CD configuration YAML file is 2 megabytes and the
default depth is 100.

You can change these limits in the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session):

- To update the maximum YAML size, update `max_yaml_size_bytes` with the new value in megabytes:

  ```ruby
  ApplicationSetting.update(max_yaml_size_bytes: 4.megabytes)
  ```

  The `max_yaml_size_bytes` value is not directly tied to the size of the YAML file,
  but rather the memory allocated for the relevant objects.

- To update the maximum YAML depth, update `max_yaml_depth` with the new value in number of lines:

  ```ruby
  ApplicationSetting.update(max_yaml_depth: 125)
  ```

### Maximum size of the entire CI/CD configuration

{{< history >}}

- Default value for `max_yaml_size_bytes` [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) in GitLab 17.3.
- Default value for `ci_max_total_yaml_size_bytes` [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826) in GitLab 17.3.

{{< /history >}}

The maximum amount of memory, in bytes, that can be allocated for the full pipeline configuration,
with all included YAML configuration files.

The default value is calculated by multiplying [`max_yaml_size_bytes`](#maximum-size-and-depth-of-cicd-configuration-yaml-files) (default 2 MB) with [`ci_max_includes`](../../api/settings.md#available-settings) (default 150):

- In GitLab 17.2 and earlier: 1 MB × 150 = `157286400` bytes (150 MB).
- In GitLab 17.3 and later: 2 MB × 150 = `314572800` bytes (314.6 MB).

You can change this limit by using the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session).
To update the maximum memory that can be allocated for the CI/CD configuration,
update `ci_max_total_yaml_size_bytes` with the new value. For example, to set it to 20 MB:

```ruby
ApplicationSetting.update(ci_max_total_yaml_size_bytes: 20.megabytes)
```

### Limit CI/CD job annotations

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) in GitLab 16.3.

{{< /history >}}

You can set a limit on the maximum number of [annotations](../../ci/yaml/artifacts_reports.md#artifactsreportsannotations)
per CI/CD job.

Set the limit to `0` to disable it. Defaults to `20`.

To set this limit to `100` on your instance, run the following command in the
[GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session):

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_num: 100)
```

### Limit CI/CD job annotations file size

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38337) in GitLab 16.3.

{{< /history >}}

You can set a limit on the maximum size of a CI/CD job [annotation](../../ci/yaml/artifacts_reports.md#artifactsreportsannotations).

Set the limit to `0` to disable it. Defaults to 80 KB.

To set this limit to 100 KB, run the following in the
[GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session):

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_size: 100.kilobytes)
```

### Maximum database partition size for CI/CD tables

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189131) in GitLab 18.0.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/577314) in GitLab 18.11.

{{< /history >}}

The maximum amount of disk space, in bytes, that can be used by a partition of a partitioned table,
before new partitions are automatically created. Defaults to 100 GB.

You can change this limit by using the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session).
To change the limit, update `ci_partitions_size_limit` with the new value. For example, to set it to 20 GB:

```ruby
ApplicationSetting.update(ci_partitions_size_limit: 20.gigabytes)
```

### Maximum time window for CI/CD partitions

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/577314) in GitLab 18.10.

{{< /history >}}

The time window, in seconds, before new CI partitions are created and the system switches
to the next set of partitions. Must be between 1 month and 6 months. Defaults to 1 month (2592000 seconds).

You can change this limit by using the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session).
To change the limit, update `ci_partitions_in_seconds_limit` with the new value. For example, to set it to 3 months:

```ruby
ApplicationSetting.update(ci_partitions_in_seconds_limit: ChronicDuration.parse('3 months'))
```

### Maximum retention period for automatic pipeline cleanup

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189191) in GitLab 18.0.

{{< /history >}}

Configures the upper limit for [automatic pipeline cleanup](../../ci/pipelines/settings.md#automatic-pipeline-cleanup).
Defaults to 1 year.

You can change this limit by using the [GitLab Rails console](../operations/rails_console.md#starting-a-rails-console-session).
To change the limit, update `ci_delete_pipelines_in_seconds_limit_human_readable` with the new value.
For example, to set it to 3 years:

```ruby
ApplicationSetting.update(ci_delete_pipelines_in_seconds_limit_human_readable: '3 years')
```
