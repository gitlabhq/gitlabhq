---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# CI/CD minutes quota **(PREMIUM)**

NOTE:
The term `CI/CD minutes` is being renamed to `units of compute`. During this transition, you might see references in the UI and documentation to `CI/CD minutes`, `CI minutes`, `pipeline minutes`, `CI pipeline minutes`, `pipeline minutes quota`, and `units of compute`. For more information, see [epic 2150](https://gitlab.com/groups/gitlab-com/-/epics/2150).

Administrators can limit the amount of time that projects can use to run jobs on
[shared runners](../runners/runners_scope.md#shared-runners) each month. This limit
is tracked with a quota of CI/CD minutes.

By default, one minute of execution time by a single job uses
one CI/CD minute. The total amount of CI/CD minutes used by a pipeline is
[the sum of all its jobs' durations](#how-cicd-minute-usage-is-calculated).
Jobs can run concurrently, so the total CI/CD minute usage can be higher than the
end-to-end duration of a pipeline.

On GitLab.com:

- CI/CD minutes quotas are enabled for all projects, but certain
  projects [consume CI/CD minutes at a slower rate](#cost-factor).
- The base monthly CI/CD minutes quota for a GitLab.com [namespace](../../user/namespace/index.md)
  is determined by its [license tier](https://about.gitlab.com/pricing/).
- You can [purchase additional CI/CD minutes](#purchase-additional-cicd-minutes)
  if you need more than the number of CI/CD minutes in your monthly quota.

On self-managed GitLab instances:

- CI/CD minutes quotas are disabled by default.
- When enabled, CI/CD minutes quotas apply to private projects only.
- Administrators can [assign more CI/CD minutes](#set-the-quota-of-cicd-minutes-for-a-specific-namespace)
  if a namespace uses all the CI/CD minutes in its monthly quota.

[Project runners](../runners/runners_scope.md#project-runners) are not subject to a quota of CI/CD minutes.

## Set the quota of CI/CD minutes for all namespaces

> [Moved](https://about.gitlab.com/blog/2021/01/26/new-gitlab-product-subscription-model/) to GitLab Premium in 13.9.

By default, GitLab instances do not have a quota of CI/CD minutes.
The default value for the quota is `0`, which grants unlimited CI/CD minutes.
However, you can change this default value.

Prerequisite:

- You must be a GitLab administrator.

To change the default quota that applies to all namespaces:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Continuous Integration and Deployment**.
1. In the **Quota of CI/CD minutes** box, enter the maximum number of CI/CD minutes.
1. Select **Save changes**.

If a quota is already defined for a specific namespace, this value does not change that quota.

## Set the quota of CI/CD minutes for a specific namespace

> [Moved](https://about.gitlab.com/blog/2021/01/26/new-gitlab-product-subscription-model/) to GitLab Premium in 13.9.

You can override the global value and set a quota of CI/CD minutes
for a specific namespace.

Prerequisite:

- You must be a GitLab administrator.

To set a quota of CI/CD minutes for a namespace:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Groups**.
1. For the group you want to update, select **Edit**.
1. In the **Quota of CI/CD minutes** box, enter the maximum number of CI/CD minutes.
1. Select **Save changes**.

You can also use the [update group API](../../api/groups.md#update-group) or the
[update user API](../../api/users.md#user-modification) instead.

NOTE:
You can set a quota of CI/CD minutes for only top-level groups or user namespaces.
If you set a quota for a subgroup, it is not used.

## View CI/CD minutes

Prerequisite:

- You must have access to the build to view the total usage and quota summary for a namespace associated with a build.
- Access to **Usage Quotas** page is based on your role in the associated namespace or group.

### View Usage Quota Reports for a group

> Displaying shared runners duration per project [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355666) in GitLab 15.0.

Prerequisite:

- You must have the Owner role for the group.

To view CI/CD minutes being used for your group:

1. On the top bar, select **Main menu > Groups** and find your group. The group must not be a subgroup.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. Select the **Pipelines** tab.

![Group CI/CD minutes quota](img/group_cicd_minutes_quota.png)

The projects list shows projects with CI/CD minute usage or shared runners usage
in the current month only. The list includes all projects in the namespace and its
subgroups, sorted in descending order of CI/CD minute usage.

### View Usage Quota reports for a personal namespace

> Displaying shared runners duration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345795) in GitLab 15.0.

Prerequisite:

- The namespace must be your personal namespace.

You can view the number of CI/CD minutes being used by a personal namespace:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Usage Quotas**.

The projects list shows [personal projects](../../user/project/working_with_projects.md#view-personal-projects)
with CI/CD minutes usage or shared runners usage in the current month only. The list
is sorted in descending order of CI/CD minute usage.

## Purchase additional CI/CD minutes **(FREE SAAS)**

If you're using GitLab SaaS, you can purchase additional packs of CI/CD minutes.
These additional CI/CD minutes:

- Are used only after the monthly quota included in your subscription runs out.
- Are carried over to the next month, if any remain at the end of the month.
- Are valid for 12 months from date of purchase or until all minutes are consumed, whichever comes first. Expiry of minutes is not enforced.

For example, with a GitLab SaaS Premium license:

- You have `10,000` monthly minutes.
- You purchase an additional `5,000` minutes.
- Your total limit is `15,000` minutes.

If you use `13,000` minutes during the month, the next month your additional minutes become
`2,000`. If you use `9,000` minutes during the month, your additional minutes remain the same.

If you bought additional CI/CD minutes while on a trial subscription, those minutes are available after the trial ends or you upgrade to a paid plan.

You can find pricing for additional CI/CD minutes on the
[GitLab Pricing page](https://about.gitlab.com/pricing/).

### Purchase CI/CD minutes for a group **(FREE SAAS)**

Prerequisite:

- You must have the Owner role for the group.

You can purchase additional CI/CD minutes for your group.
You cannot transfer purchased CI/CD minutes from one group to another,
so be sure to select the correct group.

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. Select **Pipelines**.
1. Select **Buy additional minutes**.
1. Complete the details of the transaction.

After your payment is processed, the additional CI/CD minutes are added to your group
namespace.

### Purchase CI/CD minutes for a personal namespace **(FREE SAAS)**

Prerequisite:

- The namespace must be your personal namespace.

To purchase additional minutes for your personal namespace:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Usage Quotas**.
1. Select **Buy additional minutes**. GitLab redirects you to the Customers Portal.
1. Locate the subscription card that's linked to your personal namespace on GitLab SaaS, select **Buy more CI minutes**,
   and complete the details of the transaction.

After your payment is processed, the additional CI/CD minutes are added to your personal
namespace.

## How CI/CD minute usage is calculated

GitLab uses this formula to calculate the CI/CD minute usage of a job:

```plaintext
Job duration * Cost factor
```

- **Job duration**: The time, in seconds, that a job took to run on a shared runner,
  not including time spent in the `created` or `pending` statuses.
- [**Cost factor**](#cost-factor): A number based on project visibility.

The value is transformed into minutes and added to the count of used CI/CD minutes
in the job's top-level namespace.

For example, if a user `alice` runs a pipeline:

- Under the `gitlab-org` namespace, the CI/CD minutes used by each job in the pipeline are
  added to the overall consumption for the `gitlab-org` namespace, not the `alice` namespace.
- For one of the personal projects in their namespace, the CI/CD minutes are added
  to the overall consumption for the `alice` namespace.

The CI/CD minutes used by one pipeline is the total CI/CD minutes used by all the jobs
that ran in the pipeline. Jobs can run concurrently, so the total CI/CD minutes usage
can be higher than the end-to-end duration of a pipeline.

### Cost factor

The cost factors for jobs running on shared runners on GitLab.com are:

- `1` for internal, public, and private projects.
- Exceptions for public projects:
  - `0.5` for projects in the [GitLab for Open Source program](../../subscriptions/community_programs.md#gitlab-for-open-source).
  - `0.008` for forks of projects in the [GitLab for Open Source program](../../subscriptions/community_programs.md#gitlab-for-open-source). For every 125 minutes of job execution time,
  you use 1 CI/CD minute.
- Discounted dynamically for [community contributions to GitLab projects](#cost-factor-for-community-contributions-to-gitlab-projects).

The cost factors on self-managed instances are:

- `0` for public projects, so they do not consume CI/CD minutes.
- `1` for internal and private projects.

#### Cost factor for community contributions to GitLab projects

Community contributors can use up to 300,000 minutes on shared runners when contributing to open source projects
maintained by GitLab. The maximum of 300,000 minutes would only be possible if contributing exclusively to projects [part of the GitLab product](https://about.gitlab.com/handbook/engineering/metrics/#projects-that-are-part-of-the-product). The total number of minutes available on shared runners
is reduced by the CI/CD minutes used by pipelines from other projects.
The 300,000 minutes applies to all SaaS tiers, and the cost factor calculation is:

- `Monthly minute quota / 300,000 job duration minutes = Cost factor`

For example, with the 10,000 CI/CD minutes per month in the Premium tier:

- 10,000 / 300,000 = 0.03333333333 cost factor.

For this reduced cost factor:

- The merge request source project must be a fork of a GitLab-maintained project,
  such as [`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com),
  or [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab).
- The merge request target project must be the fork's parent project.
- The pipeline must be a merge request, merged results, or merge train pipeline.

GitLab administrators can add a namespace to the reduced cost factor
[with a flag](../../administration/feature_flags.md) named `ci_minimal_cost_factor_for_gitlab_namespaces`.

### Additional costs on GitLab SaaS

GitLab SaaS runners have different cost factors, depending on the runner type (Linux, Windows, macOS) and the virtual machine configuration.

| GitLab SaaS runner type  | Machine Type   | CI/CD minutes cost factor  |
| :--------- | :------------------- | :--------- |
| Linux OS + Docker executor| Small  |1|
| Linux OS + Docker executor| Medium  |2|
| Linux OS + Docker executor| Large |3|

### Monthly reset of CI/CD minutes

On the first day of each calendar month, the accumulated usage of CI/CD minutes is reset to `0`
for all namespaces that use shared runners. This means your full quota is available, and
calculations start again from `0`.

For example, if you have a monthly quota of `10,000` CI/CD minutes:

- On **April 1**, you have `10,000` minutes.
- During April, you use only `6,000` of the `10,000` minutes.
- On **May 1**, the accumulated usage of minutes resets to `0`, and you have `10,000` minutes to use again
  during May.

Usage data for the previous month is kept to show historical view of the consumption over time.

### Monthly rollover of purchased CI/CD minutes

If you purchase additional CI/CD minutes and don't use the full amount, the remaining amount rolls over to
the next month.

For example:

- On **April 1**, you purchase `5,000` additional CI/CD minutes.
- During April, you use only `3,000` of the `5,000` additional minutes.
- On **May 1**, the unused minute roll over, so you have `2,000` additional minutes available for May.

Additional CI/CD minutes are a one-time purchase and do not renew or refresh each month.

## What happens when you exceed the quota

When the quota of CI/CD minutes is used for the current month, GitLab stops
processing new jobs.

- Any non-running job that should be picked by shared runners is automatically dropped.
- Any job being retried is automatically dropped.
- Any running job can be dropped at any point if the overall namespace usage goes over-quota
  by a grace period.

The grace period for running jobs is `1,000` CI/CD minutes.

Jobs on project runners are not affected by the quota of CI/CD minutes.

### GitLab SaaS usage notifications

On GitLab SaaS an email notification is sent to the namespace owners when:

- The available CI/CD minutes are below 30% of the quota.
- The available CI/CD minutes are below 5% of the quota.
- All CI/CD minutes have been used.

### Special quota limits

In some cases, the quota limit is replaced by one of the following labels:

- **Unlimited minutes**: For namespaces with unlimited CI/CD minutes
- **Not supported minutes**: For namespaces where active shared runners are not enabled

## Reduce consumption of CI/CD minutes

If your project consumes too many CI/CD minutes, there are some strategies you can
use to reduce your CI/CD minutes usage:

- If you are using project mirrors, ensure that [pipelines for mirror updates](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates)
  is disabled.
- Reduce the frequency of [scheduled pipelines](schedules.md).
- [Skip pipelines](index.md#skip-a-pipeline) when not needed.
- Use [interruptible](../yaml/index.md#interruptible) jobs which can be auto-canceled
  if a new pipeline starts.
- If a job doesn't have to run in every pipeline, use [`rules`](../jobs/job_control.md)
  to make it only run when it's needed.
- [Use private runners](../runners/runners_scope.md#group-runners) for some jobs.
- If you are working from a fork and you submit a merge request to the parent project,
  you can ask a maintainer to run a pipeline [in the parent project](merge_request_pipelines.md#run-pipelines-in-the-parent-project).

If you manage an open source project, these improvements can also reduce CI/CD minutes
consumption for contributor fork projects, enabling more contributions.

See our [pipeline efficiency guide](pipeline_efficiency.md) for more details.

## Reset CI/CD minutes used **(PREMIUM SELF)**

An administrator can reset the number of minutes used by a namespace for the current month.

### Reset minutes for a personal namespace

1. Find the [user in the admin area](../../user/admin_area/index.md#administering-users).
1. Select **Edit**.
1. In **Limits**, select **Reset pipeline minutes**.

### Reset minutes for a group namespace

1. Find the [group in the admin area](../../user/admin_area/index.md#administering-groups).
1. Select **Edit**.
1. In **Permissions and group features**, select **Reset pipeline minutes**.
