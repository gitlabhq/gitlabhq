---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD settings
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Configure CI/CD settings for your GitLab instance in the Admin area.

The following settings are available:

- Variables: Configure CI/CD variables available to all projects in your instance.
- Continuous Integration and Deployment: Configure settings for Auto DevOps, jobs, artifacts, instance runners, and pipeline features.
- Package registry: Configure package forwarding and file size limits.
- Runners: Configure runner registration, version management, and token settings.
- Job token permissions: Control job token access across projects.
- Job logs: Configure job log settings like incremental logging.

## Access continuous integration and deployment settings

Customize CI/CD settings, including Auto DevOps, instance runners, and job artifacts.

To access these settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.

### Configure Auto DevOps for all projects

Configure [Auto DevOps](../../topics/autodevops/_index.md)
to run for all projects that don't have a `.gitlab-ci.yml` file.
This applies to both existing projects and any new projects.

To configure Auto DevOps for all projects in your instance:

1. Select the **Default to Auto DevOps pipeline for all projects** checkbox.
1. Optional. To use Auto Deploy and Auto Review Apps,
   specify the [Auto DevOps base domain](../../topics/autodevops/requirements.md#auto-devops-base-domain).
1. Select **Save changes**.

### Instance runners

#### Enable instance runners for new projects

Make instance runners available to all new projects by default.

To make instance runners available to new projects:

1. Select the **Enable instance runners for new projects** checkbox.
1. Select **Save changes**.

#### Add details for instance runners

Add explanatory text about the instance runners.
This text appears in all projects' runner settings.

To add instance runner details:

1. Enter text in the **Instance runner details** field. You can use Markdown formatting.
1. Select **Save changes**.

To view the rendered details:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.

![A project's runner settings shows a message about instance runner guidelines.](img/continuous_integration_instance_runner_details_v17_6.png)

#### Share project runners with multiple projects

Share a project runner with multiple projects.

Prerequisites:

- You must have a registered [project runner](../../ci/runners/runners_scope.md#project-runners).

To share a project runner with multiple projects:

1. On the left sidebar, at the bottom, select **Admin**.
1. From the left sidebar, select **CI/CD > Runners**.
1. Select the runner you want to edit.
1. In the upper-right corner, select **Edit** ({{< icon name="pencil" >}}).
1. Under **Restrict projects for this runner**, search for a project.
1. To the left of the project, select **Enable**.
1. Repeat this process for each additional project.

### Job artifacts

Control how [job artifacts](../cicd/job_artifacts.md) are stored and managed across your GitLab instance.

#### Set maximum artifacts size

Set size limits for job artifacts to control storage use.
Each artifact file in a job has a default maximum size of 100 MB.

Job artifacts defined with `artifacts:reports` can have [different limits](../../administration/instance_limits.md#maximum-file-size-per-type-of-artifact).
When different limits apply, the smaller value is used.

{{< alert type="note" >}}

This setting applies to the size of the final archive file, not individual files in a job.

{{< /alert >}}

You can configure artifact size limits for:

- An instance: The base setting that applies to all projects and groups.
- A group: Overrides the instance setting for all projects in the group.
- A project: Overrides both instance and group settings for a specific project.

For GitLab.com limits, see [Artifacts maximum size](../../user/gitlab_com/_index.md#cicd).

To change the maximum artifact size for an instance:

1. Enter a value in the **Maximum artifacts size (MB)** field.
1. Select **Save changes**.

To change the maximum artifact size for a group or project:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**
1. Change the value of **Maximum artifacts size** (in MB).
1. Select **Save changes**.

#### Set default artifacts expiration

Set how long job artifacts are kept before being automatically deleted.
The default expiration time is 30 days.

The syntax for duration is described in [`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in).
Individual job definitions can override this default value in the project's `.gitlab-ci.yml` file.

Changes to this setting apply only to new artifacts. Existing artifacts keep their original expiration time.
For information about manually expiring older artifacts,
see the [troubleshooting documentation](../cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts).

To set the default expiration time for job artifacts:

1. Enter a value in the **Default artifacts expiration** field.
1. Select **Save changes**.

#### Keep artifacts from latest successful pipelines

Preserve artifacts from the most recent successful pipeline
for each Git ref (branch or tag), regardless of their expiration time.

By default, this setting is turned on.

This setting takes precedence over [project settings](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs).
If turned off for an instance, it cannot be turned on for individual projects.

When this feature is turned off, existing preserved artifacts don't immediately expire.
A new successful pipeline must run on a branch before its artifacts can expire.

{{< alert type="note" >}}

All application settings have a [customizable cache expiry interval](../application_settings_cache.md),
which can delay the effect of settings changes.

{{< /alert >}}

To keep artifacts from the latest successful pipelines:

1. Select the **Keep the latest artifacts for all jobs in the latest successful pipelines** checkbox.
1. Select **Save changes**.

To allow artifacts to expire according to their expiration settings, clear the checkbox instead.

#### Display or hide the external redirect warning page

Control whether to display a warning page when users view job artifacts through GitLab Pages.
This warning alerts about potential security risks from user-generated content.

The external redirect warning page is displayed by default. To hide it:

1. Clear the **Enable the external redirect page for job artifacts** checkbox.
1. Select **Save changes**.

### Jobs

#### Archive older jobs

Archive older jobs automatically after a specified time period. Archived jobs:

- Display a lock icon ({{< icon name="lock" >}}) and **This job is archived** at the top of the job log.
- Cannot be re-run individually.
- Are still visible in job logs.
- Can still be retried.
- Are no longer subject to expiration settings.

The archive duration must be at least 1 day.
Examples of valid durations include `15 days`, `1 month`, and `2 years`.
Leave this field empty to never archive jobs automatically.

For GitLab.com, see [Scheduled job archiving](../../user/gitlab_com/_index.md#cicd).

To set up job archiving:

1. Enter a value in the **Archive jobs** field.
1. Select **Save changes**.

### Pipelines

#### Protect CI/CD variables by default

Set all new CI/CD variables in projects and groups to be protected by default.
Protected variables are available only to pipelines that run on protected branches or protected tags.

To protect all new CI/CD variables by default:

1. Select the **Protect CI/CD variables by default** checkbox.
1. Select **Save changes**.

#### Set maximum includes

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207270) in GitLab 16.0.

{{< /history >}}

Limit how many external YAML files a pipeline can include using the [`include` keyword](../../ci/yaml/includes.md).
This limit prevents performance issues when pipelines include too many files.

By default, a pipeline can include up to 150 files.
When a pipeline exceeds this limit, it fails with an error.

To set the maximum number of included files per pipeline:

1. Enter a value in the **Maximum includes** field.
1. Select **Save changes**.

#### Limit downstream pipeline trigger rate

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077) in GitLab 16.10.

{{< /history >}}

Restrict how many [downstream pipelines](../../ci/pipelines/downstream_pipelines.md)
can be triggered per minute from a single source.

The maximum downstream pipeline trigger rate limits how many downstream pipelines
can be triggered per minute for a given combination of project, user, and commit.
The default value is `0`, which means there is no restriction.

To set the maximum downstream pipeline trigger rate:

1. Enter a value in the **Maximum downstream pipeline trigger rate** field.
1. Select **Save changes**.

#### Specify a default CI/CD configuration file

Set a custom path and filename to use as the default for CI/CD configuration files in all new projects.
By default, GitLab uses the `.gitlab-ci.yml` file in the project's root directory.

This setting applies only to new projects created after you change it.
Existing projects continue to use their current CI/CD configuration file path.

To set a custom default CI/CD configuration file path:

1. Enter a value in the **Default CI/CD configuration file** field.
1. Select **Save changes**.

Individual projects can override this instance default by
[specifying a custom CI/CD configuration file](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file).

#### Display or hide the pipeline suggestion banner

Control whether to display a guidance banner in merge requests that have no pipelines.
This banner provides a walkthrough on how to add a `.gitlab-ci.yml` file.

![A banner displays guidance on how to get started with GitLab pipelines.](img/suggest_pipeline_banner_v14_5.png)

The pipeline suggestion banner is displayed by default. To hide it:

1. Clear the **Enable pipeline suggestion banner** checkbox.
1. Select **Save changes**.

#### Display or hide the Jenkins migration banner

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/470025) in GitLab 17.7.

{{< /history >}}

Control whether to display a banner encouraging migration from Jenkins to GitLab CI/CD.
This banner appears in merge requests for projects that have the
[Jenkins integration enabled](../../integration/jenkins.md).

![A banner prompting migration from Jenkins to GitLab CI](img/suggest_migrate_from_jenkins_v17_7.png)

The Jenkins migration banner is displayed by default. To hide it:

1. Select the **Show the migrate from Jenkins banner** checkbox.
1. Select **Save changes**.

### Set CI/CD limits

{{< history >}}

- **Maximum number of active pipelines per project** setting [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/368195) in GitLab 16.0.
- **Maximum number of instance-level CI/CD variables** setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/456845) in GitLab 17.1.
- **Maximum size of a dotenv artifact in bytes** setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791) in GitLab 17.1.
- **Maximum number of variables in a dotenv artifact** setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791) in GitLab 17.1.
- **Maximum number of jobs in a single pipeline** setting [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/287669) from GitLab Enterprise Edition to GitLab Community Edition in 17.6.

{{< /history >}}

Set CI/CD limits to control resource usage and help prevent performance issues.

You can configure the following CI/CD limits:

<!-- vale gitlab_base.CurrentStatus = NO -->
- Maximum number of instance-level CI/CD variables
- Maximum size of a dotenv artifact in bytes
- Maximum number of variables in a dotenv artifact
- Maximum number of jobs in a single pipeline
- Total number of jobs in currently active pipelines
- Maximum number of pipeline subscriptions to and from a project
- Maximum number of pipeline schedules
- Maximum number of needs dependencies that a job can have
- Maximum number of runners created or active in a group during the past seven days
- Maximum number of runners created or active in a project during the past seven days
- Maximum number of downstream pipelines in a pipeline's hierarchy tree
<!-- vale gitlab_base.CurrentStatus = YES -->

For more information on what these limits control, see [CI/CD limits](../instance_limits.md#cicd-limits).

To configure CI/CD limits:

1. Under **CI/CD limits**, set values for the limits you want to configure.
1. Select **Save changes**.

## Package registry configuration

Configure package forwarding, package limits, and package file size limits.

To access these settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Package registry**.

### Maven forwarding

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab administrators can disable the forwarding of Maven requests to [Maven Central](https://search.maven.org/).

To disable forwarding Maven requests:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Package registry** section.
1. Clear the checkbox **Forward Maven package requests to the Maven registry if the packages are not found in the GitLab Package registry**.
1. Select **Save changes**.

### npm forwarding

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab administrators can disable the forwarding of npm requests to [npmjs.com](https://www.npmjs.com/).

To disable it:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Package registry** section.
1. Clear the checkbox **Forward npm package requests to the npm registry if the packages are not found in the GitLab package registry**.
1. Select **Save changes**.

### PyPI forwarding

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab administrators can disable the forwarding of PyPI requests to [pypi.org](https://pypi.org/).

To disable it:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Package registry** section.
1. Clear the checkbox **Forward PyPI package requests to the PyPI registry if the packages are not found in the GitLab package registry**.
1. Select **Save changes**.

### Package file size limits

GitLab administrators can adjust the maximum allowed file size for each package type.

To set the maximum file size:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Package registry** section.
1. Find the package type you would like to adjust.
1. Enter the maximum file size, in bytes.
1. Select **Save size limits**.

## Runners

Configure runner version management and registration settings.

To access these settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.

### Disable runner version management

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114041) in GitLab 15.10.

{{< /history >}}

By default, GitLab instances periodically fetch official runner version data from GitLab.com to [determine whether the runners need upgrades](../../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded).

To disable your instance fetching this data:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Runner version management** section, clear the **Fetch GitLab Runner release version data from GitLab.com** checkbox.
1. Select **Save changes**.

### Restrict runner registration by all users in an instance

{{< history >}}

- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/368008) in GitLab 15.5.

{{< /history >}}

GitLab administrators can adjust who is allowed to register runners, by showing and hiding areas of the UI.
This setting does not affect the ability to create a runner from the UI or through an authenticated API call.

When the registration sections are hidden in the UI, members of the project or group must contact administrators to enable runner registration in the group or project. If you plan to prevent registration, ensure users have access to the runners they need to run jobs.

By default, all members of a project and group are able to register runners.

To restrict all users in an instance from registering runners:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Runner registration** section, clear the **Members of the project can register runners** and
   **Members of the group can register runners** checkboxes to remove runner registration from the UI.
1. Select **Save changes**.

{{< alert type="note" >}}

After you disable runner registration by members of a project, the registration
token automatically rotates. The token is no longer valid and you must
use the new registration token for the project.

{{< /alert >}}

### Restrict runner registration by all members in a group

Prerequisites:

- Runner registration must be enabled for [all users in the instance](#restrict-runner-registration-by-all-users-in-an-instance).

GitLab administrators can adjust group permissions to restrict runner registration by group members.

To restrict runner registration by members in a specific group:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Groups** and find your group.
1. Select **Edit**.
1. Clear the **New group runners can be registered** checkbox if you want to disable runner registration by all members in the group. If the setting is read-only, you must enable runner registration for the [instance](#restrict-runner-registration-by-all-users-in-an-instance).
1. Select **Save changes**.

### Allow runner registration tokens

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147559) in GitLab 16.11

{{< /history >}}

{{< alert type="warning" >}}

The option to pass runner registration tokens and support for certain configuration arguments are
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and is planned for removal in GitLab 20.0.
Use the [runner creation workflow](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)
to generate an authentication token to register runners. This process provides full
traceability of runner ownership and enhances your runner fleet's security.

For more information, see
[Migrating to the new runner registration workflow](../../ci/runners/new_creation_workflow.md).

{{< /alert >}}

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. Select the **Allow runner registration token** checkbox.

## Job token permissions

Configure CI/CD job token settings for all projects.

To access these settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Job token permissions**.

### Enforce job token allowlist

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/496647) in GitLab 17.6.

{{< /history >}}

You can configure the [CI/CD job token access setting](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)
for all projects from the **Admin** area.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Job token permissions** section.
1. Enable **Enable and enforce job token allowlist for all projects** setting to
   require all projects to control job token access with the allowlist.

## Job logs

Configure CI job log settings for all projects.

To access these settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Job logs**.

### Incremental logging

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350883) in GitLab 17.11.

{{< /history >}}

Incremental logging uses Redis instead of disk space for temporary caching of job logs.
When turned on, archived job logs are incrementally uploaded to object storage.
For more information, see [incremental logging](../cicd/job_logs.md#incremental-logging).

Prerequisites:

- You must [configure object storage](../cicd/job_artifacts.md#using-object-storage)
  for CI/CD artifacts, logs, and builds.

To turn on incremental logging for all projects:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Job logs**.
1. Select the **Turn on incremental logging** checkbox.
1. Select **Save changes**.

## Required pipeline configuration (deprecated)

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/352316) from GitLab Premium to GitLab Ultimate in 15.0.
- [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) in GitLab 15.9.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) in GitLab 17.0.
- [Re-added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165111) behind the `required_pipelines` feature flag in GitLab 17.4. Disabled by default.

{{< /history >}}

{{< alert type="warning" >}}

This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) in GitLab 15.9
and was removed in 17.0. From 17.4, it is available only behind the feature flag `required_pipelines`, disabled by default.
Use [compliance pipelines](../../user/compliance/compliance_pipelines.md) instead. This change is a breaking change.

{{< /alert >}}

You can set a [CI/CD template](../../ci/examples/_index.md#cicd-templates)
as a required pipeline configuration for all projects on a GitLab instance. You can
use a template from:

- The default CI/CD templates.
- A custom template stored in an [instance template repository](instance_template_repository.md).

  {{< alert type="note" >}}

  When you use a configuration defined in an instance template repository,
  nested [`include:`](../../ci/yaml/_index.md#include) keywords
  (including `include:file`, `include:local`, `include:remote`, and `include:template`)
  [do not work](https://gitlab.com/gitlab-org/gitlab/-/issues/35345).

  {{< /alert >}}

The project CI/CD configuration merges into the required pipeline configuration when
a pipeline runs. The merged configuration is the same as if the required pipeline configuration
added the project configuration with the [`include` keyword](../../ci/yaml/_index.md#include).
To view a project's full merged configuration, [View full configuration](../../ci/pipeline_editor/_index.md#view-full-configuration)
in the pipeline editor.

To select a CI/CD template for the required pipeline configuration:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > CI/CD**.
1. Expand the **Required pipeline configuration** section.
1. Select a CI/CD template from the dropdown list.
1. Select **Save changes**.
