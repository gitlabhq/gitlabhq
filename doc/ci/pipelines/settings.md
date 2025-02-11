---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Customize pipeline configuration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can customize how pipelines run for your project.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of pipelines, watch the video [GitLab CI Pipeline, Artifacts, and Environments](https://www.youtube.com/watch?v=PCKDICEe10s).
Watch also [GitLab CI pipeline tutorial for beginners](https://www.youtube.com/watch?v=Jav4vbUrqII).

## Change which users can view your pipelines

For public and internal projects, you can change who can see your:

- Pipelines
- Job output logs
- Job artifacts
- [Pipeline security dashboard](../../user/application_security/vulnerability_report/pipeline.md#view-vulnerabilities-in-a-pipeline)

To change the visibility of your pipelines and related features:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. Select or clear the **Public pipelines** checkbox.
   When it is selected, pipelines and related features are visible:

   - For [**Public**](../../user/public_access.md) projects, to everyone.
   - For **Internal** projects, to all authenticated users except [external users](../../administration/external_users.md).
   - For **Private** projects, to all project members (Guest or higher).

   When it is cleared:

   - For **Public** projects, job logs, job artifacts, the pipeline security dashboard,
     and the **CI/CD** menu items are visible only to project members (Reporter or higher).
     Other users, including guest users, can only view the status of pipelines and jobs, and only
     when viewing merge requests or commits.
   - For **Internal** projects, pipelines are visible to all authenticated users except [external users](../../administration/external_users.md).
     Related features are visible only to project members (Reporter or higher).
   - For **Private** projects, pipelines and related features are visible to project members (Reporter or higher) only.

### Change pipeline visibility for non-project members in public projects

You can control the visibility of pipelines for non-project members in [public projects](../../user/public_access.md).

This setting has no effect when:

- Project visibility is set to [**Internal** or **Private**](../../user/public_access.md),
  because non-project members cannot access internal or private projects.
- The [**Public pipelines**](#change-which-users-can-view-your-pipelines) setting is disabled.

To change the pipeline visibility for non-project members:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. For **CI/CD**, choose:
   - **Only project members**: Only project members can view pipelines.
   - **Everyone With Access**: Non-project members can also view pipelines.
1. Select **Save changes**.

The [CI/CD permissions table](../../user/permissions.md#cicd)
lists the pipeline features non-project members can access when **Everyone With Access**
is selected.

## Auto-cancel redundant pipelines

You can set pending or running pipelines to cancel automatically when a pipeline for new changes runs on the same branch. You can enable this in the project settings:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General Pipelines**.
1. Select the **Auto-cancel redundant pipelines** checkbox.
1. Select **Save changes**.

Use the [`interruptible`](../yaml/_index.md#interruptible) keyword to indicate if a
running job can be canceled before it completes. After a job with
`interruptible: false` starts, the entire pipeline is no longer considered interruptible.

## Prevent outdated deployment jobs

> - Also preventing outdated manual or retried deployment jobs from running [added](https://gitlab.com/gitlab-org/gitlab/-/issues/363328) in GitLab 15.5.

Your project may have multiple concurrent deployment jobs that are
scheduled to run in the same time frame.

This can lead to a situation where an older deployment job runs after a
newer one, which may not be what you want.

To avoid this scenario:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. Select the **Prevent outdated deployment jobs** checkbox.
1. Optional. Clear the **Allow job retries for rollback deployments** checkbox.
1. Select **Save changes**.

For more information, see [Deployment safety](../environments/deployment_safety.md#prevent-outdated-deployment-jobs).

## Restrict roles that can cancel pipelines or jobs

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137301) in GitLab 16.7.

You can customize which roles have permission to cancel pipelines or jobs.

By default, users with at least the Developer role can cancel pipelines or jobs.
You can restrict cancellation permission to only users with at least the Maintainer role,
or completely prevent cancellation of any pipelines or jobs.

To change the permissions to cancel pipelines or jobs:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. Select an option from **Minimum role required to cancel a pipeline or job**.
1. Select **Save changes**.

## Specify a custom CI/CD configuration file

GitLab expects to find the CI/CD configuration file (`.gitlab-ci.yml`) in the project's root
directory. However, you can specify an alternate filename path, including locations outside the project.

To customize the path:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. In the **CI/CD configuration file** field, enter the filename. If the file:
   - Is not in the root directory, include the path.
   - Is in a different project, include the group and project name.
   - Is on an external site, enter the full URL.
1. Select **Save changes**.

NOTE:
You cannot use your project's [pipeline editor](../pipeline_editor/_index.md) to
edit CI/CD configuration files in other projects or on an external site.

### Custom CI/CD configuration file examples

If the CI/CD configuration file is not in the root directory, the path must be relative to it.
For example:

- `my/path/.gitlab-ci.yml`
- `my/path/.my-custom-file.yml`

If the CI/CD configuration file is on an external site, the URL must end with `.yml`:

- `http://example.com/generate/ci/config.yml`

If the CI/CD configuration file is in a different project:

- The file must exist on its default branch, or specify the branch as refname.
- The path must be relative to the root directory in the other project.
- The path must be followed by an `@` symbol and the full group and project path.

For example:

- `.gitlab-ci.yml@namespace/another-project`
- `my/path/.my-custom-file.yml@namespace/subgroup/another-project`
- `my/path/.my-custom-file.yml@namespace/subgroup1/subgroup2/another-project:refname`

If the configuration file is in a separate project, you can set more granular permissions. For example:

- Create a public project to host the configuration file.
- Give write permissions on the project only to users who are allowed to edit the file.

Then other users and projects can access the configuration file without being
able to edit it.

## Choose the default Git strategy

You can choose how your repository is fetched from GitLab when a job runs.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. Under **Git strategy**, select an option:
   - `git clone` is slower because it clones the repository from scratch
     for every job. However, the local working copy is always pristine.
   - `git fetch` is faster because it re-uses the local working copy (and falls
     back to clone if it doesn't exist). This is recommended, especially for
     [large repositories](../../user/project/repository/monorepos/_index.md#git-strategy).

The configured Git strategy can be overridden by the [`GIT_STRATEGY` variable](../runners/configure_runners.md#git-strategy)
in the `.gitlab-ci.yml` file.

## Limit the number of changes fetched during clone

You can limit the number of changes that GitLab CI/CD fetches when it clones
a repository.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. Under **Git strategy**, under **Git shallow clone**, enter a value.
   The maximum value is `1000`. To disable shallow clone and make GitLab CI/CD
   fetch all branches and tags each time, keep the value empty or set to `0`.

Newly created projects have a default `git depth` value of `20`.

This value can be overridden by the [`GIT_DEPTH` variable](../../user/project/repository/monorepos/_index.md#shallow-cloning)
in the `.gitlab-ci.yml` file.

## Set a limit for how long jobs can run

You can define how long a job can run before it times out.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. In the **Timeout** field, enter the number of minutes, or a human-readable value like `2 hours`.
   Must be 10 minutes or more, and less than one month. Default is 60 minutes.
   Pending jobs are dropped after 24 hours of inactivity.

Jobs that exceed the timeout are marked as failed.

You can override this value [for individual runners](../runners/configure_runners.md#set-the-maximum-job-timeout).

## Pipeline badges

You can use [pipeline badges](../../user/project/badges.md) to indicate the pipeline status and
test coverage of your projects. These badges are determined by the latest successful pipeline.

## Disable GitLab CI/CD pipelines

GitLab CI/CD pipelines are enabled by default on all new projects. If you use an external CI/CD server like
Jenkins or Drone CI, you can disable GitLab CI/CD to avoid conflicts with the commits status API.

You can disable GitLab CI/CD per project or [for all new projects on an instance](../../administration/cicd/_index.md).

When you disable GitLab CI/CD:

- The **CI/CD** item in the left sidebar is removed.
- The `/pipelines` and `/jobs` pages are no longer available.
- Existing jobs and pipelines are hidden, not removed.

To disable GitLab CI/CD in your project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. In the **Repository** section, turn off **CI/CD**.
1. Select **Save changes**.

These changes do not apply to projects in an [external integration](../../user/project/integrations/_index.md#available-integrations).

## Automatic pipeline cleanup

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/498969) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `ci_delete_old_pipelines`. Disabled by default.
> - [Feature flag `ci_delete_old_pipelines`](https://gitlab.com/gitlab-org/gitlab/-/issues/503153) removed in GitLab 17.9.

Users with the Owner role can set a CI/CD pipeline expiry time to help manage pipeline storage and improve system performance.
The system automatically deletes pipelines that were created before the configured value.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **General pipelines**.
1. In the **Automatic pipeline cleanup** field, enter the number of seconds, or a human-readable value like `2 weeks`.
   Must be one day or more, and less than one year. Leave empty to never delete pipelines automatically.
   Empty by default.
1. Select **Save changes**.
