---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD Admin area settings
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The [**Admin** area](_index.md) has the instance settings for CI/CD-related features,
including runners, job artifacts, and the package registry.

## Auto DevOps

To enable (or disable) [Auto DevOps](../../topics/autodevops/_index.md)
for all projects:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Check (or uncheck to disable) the box that says **Default to Auto DevOps pipeline for all projects**.
1. Optionally, set up the [Auto DevOps base domain](../../topics/autodevops/requirements.md#auto-devops-base-domain)
   which is used for Auto Deploy and Auto Review Apps.
1. Select **Save changes** for the changes to take effect.

Every existing project and newly created ones that don't have a
`.gitlab-ci.yml` use the Auto DevOps pipelines.

## Runners

### Enable instance runners for new projects

You can set all new projects to have instance runners available by default.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Select the **Enable instance runners for new projects** checkbox.

Any time a new project is created, the instance runners are available.

### Add a message for instance runners

To display details about the instance runners in all projects'
runner settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Enter text, including Markdown if you want, in the **Instance runner details** field.

To view the rendered details:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.

![A project's runner settings shows a message about instance runner guidelines.](img/continuous_integration_instance_runner_details_v17_6.png)

### Enable a project runner for multiple projects

If you have already registered a [project runner](../../ci/runners/runners_scope.md#project-runners)
you can assign that runner to other projects.

To enable a project runner for more than one project:

1. On the left sidebar, at the bottom, select **Admin**.
1. From the left sidebar, select **CI/CD > Runners**.
1. Select the runner you want to edit.
1. In the upper-right corner, select **Edit** (**{pencil}**).
1. Under **Restrict projects for this runner**, search for a project.
1. To the left of the project, select **Enable**.
1. Repeat this process for each additional project.

### Disable runner version management

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114041) in GitLab 15.10.

By default, GitLab instances periodically fetch official runner version data from GitLab.com to [determine whether the runners need upgrades](../../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded).

To disable your instance fetching this data:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Runner version management** section, clear the **Fetch GitLab Runner release version data from GitLab.com** checkbox.
1. Select **Save changes**.

### Restrict runner registration by all users in an instance

> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/368008) in GitLab 15.5.

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

NOTE:
After you disable runner registration by members of a project, the registration
token automatically rotates. The token is no longer valid and you must
use the new registration token for the project.

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

### Allow runner registrations tokens

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147559) in GitLab 16.11

WARNING:
The ability to pass a runner registration token, and support for certain configuration arguments
was deprecated in GitLab 15.6 and will be removed in GitLab 18.0. Runner authentication tokens should be used instead.
For more information, see [Migrating to the new runner registration workflow](../../ci/runners/new_creation_workflow.md).

In GitLab 17.0, the use of runner registration tokens to create runners will be disabled in all GitLab instances.
Users must use runner authentication tokens instead.
If you have not yet [migrated to the use of runner authentication tokens](../../ci/runners/new_creation_workflow.md),
you can allow runner registration tokens. This setting and support for runner registration tokens will be removed in GitLab 18.0.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. Select the **Allow runner registration token** checkbox.

## Artifacts

### Maximum artifacts size

An administrator can set the maximum size of the
[job artifacts](../cicd/job_artifacts.md) for:

- The entire instance
- Each project
- Each group

For the setting on GitLab.com, see [Artifacts maximum size](../../user/gitlab_com/_index.md#gitlab-cicd).

The value is in MB, and the default value is 100 MB per job. An administrator can change the default value for the:

- Instance:

  1. On the left sidebar, at the bottom, select **Admin**.
  1. On the left sidebar, select **Settings > CI/CD > Continuous Integration and Deployment**.
  1. Change the value of **Maximum artifacts size (MB)**.
  1. Select **Save changes** for the changes to take effect.

- Group (this overrides the instance setting):

  1. Go to the group's **Settings > CI/CD > General Pipelines**.
  1. Change the value of **Maximum artifacts size** (in MB).
  1. Select **Save changes** for the changes to take effect.

- Project (this overrides the instance and group settings):

  1. Go to the project's **Settings > CI/CD > General Pipelines**.
  1. Change the value of **Maximum artifacts size** (in MB).
  1. Select **Save changes** for the changes to take effect.

### Default artifacts expiration

The default expiration time of the [job artifacts](../cicd/job_artifacts.md)
can be set in the **Admin** area of your GitLab instance. The syntax of duration is
described in [`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in)
and the default value is `30 days`.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Change the value of default expiration time.
1. Select **Save changes** for the changes to take effect.

This setting is set per job and can be overridden in
[`.gitlab-ci.yml`](../../ci/yaml/_index.md#artifactsexpire_in).
To disable the expiration, set it to `0`. The default unit is in seconds.

NOTE:
Any changes to this setting applies to new artifacts only. The expiration time is not
be updated for artifacts created before this setting was changed.
The administrator may need to manually search for and expire previously-created
artifacts, as described in the [troubleshooting documentation](../cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts).

### Keep the latest artifacts for all jobs in the latest successful pipelines

When enabled (default), the artifacts of the most recent pipeline for each Git ref
([branches and tags](https://git-scm.com/book/en/v2/Git-Internals-Git-References))
are locked against deletion and kept regardless of the expiry time.

When disabled, the latest artifacts for any **new** successful or fixed pipelines
are allowed to expire.

This setting takes precedence over the [project setting](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs).
If disabled for the entire instance, you cannot enable this in individual projects.

To disable the setting:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Clear the **Keep the latest artifacts for all jobs in the latest successful pipelines** checkbox.
1. Select **Save changes**

When you disable the feature, the latest artifacts do not immediately expire.
A new pipeline must run before the latest artifacts can expire and be deleted.

NOTE:
All application settings have a [customizable cache expiry interval](../application_settings_cache.md) which can delay the settings affect.

### Disable the external redirect page for job artifacts

By default, GitLab Pages shows an external redirect page when a user tries to view
a job artifact served by GitLab Pages. This page warns about the potential for
malicious user-generated content, as described in
[issue 352611](https://gitlab.com/gitlab-org/gitlab/-/issues/352611).

GitLab Self-Managed administrators can disable the external redirect warning page,
so you can view job artifact pages directly:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. Clear **Enable the external redirect page for job artifacts**.

## Archive jobs

You can archive old jobs to prevent them from being re-run individually. Archived jobs
display a lock icon (**{lock}**) and **This job is archived** at the top of the job log.

To set the duration for which the jobs are considered as old and expired:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Continuous Integration and Deployment** section.
1. Set the value of **Archive jobs**.
1. Select **Save changes** for the changes to take effect.

After that time passes, the jobs are archived in the background and no longer able to be
retried. Make it empty to never expire jobs. It has to be no less than 1 day,
for example: <code>15 days</code>, <code>1 month</code>, <code>2 years</code>.

For the value set for GitLab.com, see [Scheduled job archiving](../../user/gitlab_com/_index.md#gitlab-cicd).

## Protect CI/CD variables by default

To set all new [CI/CD variables](../../ci/variables/_index.md) as
[protected](../../ci/variables/_index.md#protect-a-cicd-variable) by default:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Select **Protect CI/CD variables by default**.

## Maximum includes

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207270) in GitLab 16.0.

The maximum number of [includes](../../ci/yaml/includes.md) per pipeline can be set for the entire instance.
The default is `150`.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Change the value of **Maximum includes**.
1. Select **Save changes** for the changes to take effect.

## Maximum downstream pipeline trigger rate

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077) in GitLab 16.10.

The maximum number of [downstream pipelines](../../ci/pipelines/downstream_pipelines.md) that can be triggered per minute
(for a given project, user, and commit) can be set for the entire instance.
The default value is `0` (no restriction).

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Change the value of **Maximum downstream pipeline trigger rate**.
1. Select **Save changes** for the changes to take effect.

## Default CI/CD configuration file

The default CI/CD configuration file and path for new projects can be set in the **Admin** area
of your GitLab instance (`.gitlab-ci.yml` if not set):

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Input the new file and path in the **Default CI/CD configuration file** field.
1. Select **Save changes** for the changes to take effect.

It is also possible to specify a [custom CI/CD configuration file for a specific project](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file).

## Set CI/CD limits

> - **Maximum number of active pipelines per project** setting [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/368195) in GitLab 16.0.
> - **Maximum number of instance-level CI/CD variables** setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/456845) in GitLab 17.1.
> - **Maximum size of a dotenv artifact in bytes** setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791) in GitLab 17.1.
> - **Maximum number of variables in a dotenv artifact** setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791) in GitLab 17.1.
> - **Maximum number of jobs in a single pipeline** setting [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/287669) from GitLab Enterprise Edition to GitLab Community Edition in 17.6.

You can configure some [CI/CD limits](../instance_limits.md#cicd-limits)
from the **Admin** area:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
<!-- vale gitlab_base.CurrentStatus = NO -->
1. In the **CI/CD limits** section, you can set the following limits:
   - **Maximum number of instance-level CI/CD variables**
   - **Maximum size of a dotenv artifact in bytes**
   - **Maximum number of variables in a dotenv artifact**
   - **Maximum number of jobs in a single pipeline**
   - **Total number of jobs in currently active pipelines**
   - **Maximum number of pipeline subscriptions to and from a project**
   - **Maximum number of pipeline schedules**
   - **Maximum number of needs dependencies that a job can have**
   - **Maximum number of runners created or active in a group during the past seven days**
   - **Maximum number of runners created or active in a project during the past seven days**
   - **Maximum number of downstream pipelines in a pipeline's hierarchy tree**
<!-- vale gitlab_base.CurrentStatus = YES -->

## Job token permissions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/496647) in GitLab 17.6.

You can configure the [CI/CD job token access setting](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)
for all projects from the **Admin** area.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Job token permissions** section.
1. Enable **Enable and enforce job token allowlist for all projects** setting to
   require all projects to control job token access with the allowlist.

## Disable the pipeline suggestion banner

By default, a banner displays in merge requests with no pipeline suggesting a
walkthrough on how to add one.

![A banner displays guidance on how to get started with GitLab Pipelines.](img/suggest_pipeline_banner_v14_5.png)

To disable the banner:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Clear the **Enable pipeline suggestion banner** checkbox.
1. Select **Save changes**.

## Disable the migrate from Jenkins banner

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/470025) in GitLab 17.7.

By default, a banner shows in merge requests in projects with the [Jenkins integration enabled](../../integration/jenkins.md) to prompt migration to GitLab CI/CD.

![A banner prompting migration from Jenkins to GitLab CI](img/suggest_migrate_from_jenkins_v_17_7.png)

To disable the banner:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Clear the **Show the migrate from Jenkins banner** checkbox.
1. Select **Save changes**.

## Required pipeline configuration

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/352316) from GitLab Premium to GitLab Ultimate in 15.0.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) in GitLab 15.9.
> - [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) in GitLab 17.0.
> - [Re-added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165111) behind the `required_pipelines` feature flag in GitLab 17.4. Disabled by default.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/389467) in GitLab 15.9
and was removed in 17.0. From 17.4, it is available only behind the feature flag `required_pipelines`, disabled by default.
Use [compliance pipelines](../../user/group/compliance_pipelines.md) instead. This change is a breaking change.

You can set a [CI/CD template](../../ci/examples/_index.md#cicd-templates)
as a required pipeline configuration for all projects on a GitLab instance. You can
use a template from:

- The default CI/CD templates.
- A custom template stored in an [instance template repository](instance_template_repository.md).

  NOTE:
  When you use a configuration defined in an instance template repository,
  nested [`include:`](../../ci/yaml/_index.md#include) keywords
  (including `include:file`, `include:local`, `include:remote`, and `include:template`)
  [do not work](https://gitlab.com/gitlab-org/gitlab/-/issues/35345).

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

## Package registry configuration

### Maven Forwarding

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab administrators can disable the forwarding of Maven requests to [Maven Central](https://search.maven.org/).

To disable forwarding Maven requests:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Package Registry** section.
1. Clear the checkbox **Forward Maven package requests to the Maven Registry if the packages are not found in the GitLab Package Registry**.
1. Select **Save changes**.

### npm Forwarding

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab administrators can disable the forwarding of npm requests to [npmjs.com](https://www.npmjs.com/).

To disable it:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Package Registry** section.
1. Clear the checkbox **Forward npm package requests to the npm Registry if the packages are not found in the GitLab Package Registry**.
1. Select **Save changes**.

### PyPI Forwarding

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab administrators can disable the forwarding of PyPI requests to [pypi.org](https://pypi.org/).

To disable it:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Package Registry** section.
1. Clear the checkbox **Forward PyPI package requests to the PyPI Registry if the packages are not found in the GitLab Package Registry**.
1. Select **Save changes**.

### Package file size limits

GitLab administrators can adjust the maximum allowed file size for each package type.

To set the maximum file size:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand the **Package Registry** section.
1. Find the package type you would like to adjust.
1. Enter the maximum file size, in bytes.
1. Select **Save size limits**.
