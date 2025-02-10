---
stage: Verify
group: Pipeline Execution
description: Calculations, quotas, purchase information.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compute minutes
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Renamed](https://gitlab.com/groups/gitlab-com/-/epics/2150) from "CI/CD minutes" to "compute quota" or "compute minutes" in GitLab 16.1.

The amount of time that projects can use to run jobs on [instance runners](../runners/runners_scope.md#instance-runners)
on GitLab.com is limited. This limit is tracked with a compute quota. [Project runners](../runners/runners_scope.md#project-runners)
are not subject to the compute quota.

By default, one minute of execution time by a single job uses one compute minute.
The total compute usage for a pipeline is calculated using [the sum of all its jobs' durations](#compute-usage-calculation).
Jobs can run concurrently, so the total usage can be higher than the end-to-end duration of a pipeline.

On GitLab.com:

- Compute quotas are enabled for all projects, but certain
  projects [consume compute minutes at a slower rate](#cost-factor).
- The base monthly compute quota for a GitLab.com [namespace](../../user/namespace/_index.md)
  is determined by its [license tier](https://about.gitlab.com/pricing/).
- You can [purchase additional compute minutes](../../subscriptions/gitlab_com/compute_minutes.md)
  if you need more than the amount of compute in your monthly quota.

Compute quotas [are disabled by default on GitLab Self-Managed](../../administration/cicd/compute_minutes.md).

## View compute usage

You can view the compute usage for a group or personal namespace to understand
compute usage trends and how many compute minutes remain.

In some cases, the quota limit is replaced by one of the following labels:

- **Unlimited**: For namespaces with unlimited compute quota.
- **Not supported**: For namespaces where active instance runners are not enabled.

### View usage quota reports for a group

> - Displaying instance runners duration per project [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355666) in GitLab 15.0.

Prerequisites:

- You must have the Owner role for the group.

To view compute usage for your group:

1. On the left sidebar, select **Search or go to** and
   find your group. The group must not be a subgroup.
1. Select **Settings > Usage Quotas**.
1. Select the **Pipelines** tab.

The projects list shows projects with compute usage or instance runners usage
in the current month only. The list includes all projects in the namespace and its
subgroups, sorted in descending order of compute usage.

### View usage quota reports for a personal namespace

> - Displaying instance runners duration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345795) in GitLab 15.0.

You can view the compute usage for your personal namespace:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Usage Quotas**.

The projects list shows [personal projects](../../user/project/working_with_projects.md#view-personal-projects)
with compute usage or instance runners usage in the current month only.

### Exceeding the quota

On GitLab.com an in-app banner is displayed and an email notification sent to the
namespace owners when the remaining compute minutes is:

- Less than 25% of the quota.
- Less than 5% of the quota.
- Completely used (zero minutes remaining).

When the compute quota is used for the current month, instance runners stop processing new jobs.
In pipelines that have already started:

- Any pending job (not yet started) or retried job that must be processed by instance runners is dropped.
- Jobs running on instance runners can continue to run until the overall namespace usage goes over-quota
  by 1,000 compute minutes. After the 1,000 compute minute grace period, any remaining running jobs
  are also dropped.

If you're using GitLab.com, you can [purchase additional packs of compute minutes](../../subscriptions/gitlab_com/_index.md)
to continue running CI/CD pipelines on instance runners.

Project runners are not affected by the compute quota and continue processing jobs.

## Compute usage calculation

GitLab uses this formula to calculate the compute usage of a job:

```plaintext
Job duration * Cost factor
```

- **Job duration**: The time, in seconds, that a job took to run on an instance runner,
  not including time spent in the `created` or `pending` statuses.
- [**Cost factor**](#cost-factor): A number based on the project type.

The value is converted into compute minutes and added to the count of used units
in the job's top-level namespace.

For example, if a user `alice` runs a pipeline:

- In a project in the `gitlab-org` namespace, the compute minutes used by each job in the pipeline are
  added to the overall consumption for the `gitlab-org` namespace, not the `alice` namespace.
- In a personal projects in their `alice` namespace, the compute minutes are added
  to the overall consumption for their namespace.

The compute used by one pipeline is the total compute minutes used by all the jobs
that ran in the pipeline. Jobs can run concurrently, so the total compute usage
can be higher than the end-to-end duration of a pipeline.

[Trigger jobs](../yaml/_index.md#trigger) do not execute on runners, so they do not
consume compute minutes, even when using [`strategy:depend`](../yaml/_index.md#triggerstrategy)
to wait for the [downstream pipeline](../pipelines/downstream_pipelines.md) status.
The triggered downstream pipeline consumes compute minutes the same as other pipelines.

### Cost factor

The default cost factors for jobs running on instance runners on GitLab.com are:

- `1` for internal, public, and private projects.
  For every 1 minute of job execution time, you use 1 compute minute.
- `0.5` for public projects in the [GitLab for Open Source program](../../subscriptions/community_programs.md#gitlab-for-open-source).
  For every 2 minutes of job execution time, you use 1 compute minute.
- `0.008` for public forks of projects in the [GitLab for Open Source program](../../subscriptions/community_programs.md#gitlab-for-open-source).
  For every 125 minutes of job execution time, you use 1 compute minute.
- Discounted dynamically for [community contributions to GitLab projects](#community-contributions-to-gitlab-projects).
- Increased if you use [different types of instance runners](#gitlab-hosted-runner-cost-factors).

The cost factors on GitLab Self-Managed [are different](../../administration/cicd/compute_minutes.md).

#### Community contributions to GitLab projects

Community contributors can use up to 300,000 minutes on instance runners when contributing to open source projects
maintained by GitLab. The maximum of 300,000 minutes would only be possible if contributing exclusively to projects
[part of the GitLab product](https://handbook.gitlab.com/handbook/engineering/metrics/#projects-that-are-part-of-the-product).
The total number of minutes available on instance runners is reduced by the compute minutes used by pipelines from
other projects. The 300,000 minutes applies to all GitLab.com tiers.

The cost factor calculation is:

- `Monthly compute quota / 300,000 job duration minutes = Cost factor`

For example, with a monthly compute quota of 10,000 in the Premium tier:

- 10,000 / 300,000 = 0.03333333333 cost factor.

For this reduced cost factor:

- The merge request source project must be a fork of a GitLab-maintained project,
  such as [`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com),
  or [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab).
- The merge request target project must be the fork's parent project.
- The pipeline must be a merge request, merged results, or merge train pipeline.

#### GitLab-hosted runner cost factors

GitLab-hosted runners have different cost factors depending on the runner type
(Linux, Windows, macOS) and the virtual machine configuration:

| GitLab-hosted runner type  | Machine Size           | Cost factor |
|:---------------------------|:-----------------------|:------------|
| Linux x86-64 (default)     | `small`                | `1`         |
| Linux x86-64               | `medium`               | `2`         |
| Linux x86-64               | `large`                | `3`         |
| Linux x86-64               | `xlarge`               | `6`         |
| Linux x86-64               | `2xlarge`              | `12`        |
| Linux x86-64 + GPU-enabled | `medium`, GPU standard | `7`         |
| Linux Arm64                | `small`                | `1`         |
| Linux Arm64                | `medium`               | `2`         |
| Linux Arm64                | `large`                | `3`         |
| macOS M1                   | `medium`               | `6` (**Status:** Beta)  |
| macOS M2 Pro               | `large`                | `12` (**Status:** Beta) |
| Windows                    | `medium`               | `1` (**Status:** Beta)  |

### Monthly reset of compute usage

On the first day of each calendar month, the accumulated compute usage is reset to `0`
for all namespaces.

For example, if you have a monthly quota of 10,000 compute minutes:

1. On April 1 you have 10,000 compute minutes available.
1. During April, you use 6,000 of the 10,000 compute minutes.
1. On May 1, the accumulated compute usage resets to 0, and you have 10,000
   compute minutes available for May.

Usage data for the previous month is kept to show a historical view of the consumption over time.

## Reduce compute quota usage

If your project consumes too much compute quota, there are some strategies you can
use to reduce your usage:

- If you are using project mirrors, ensure that [pipelines for mirror updates](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates)
  is disabled.
- Reduce the frequency of [scheduled pipelines](schedules.md).
- [Skip pipelines](_index.md#skip-a-pipeline) when not needed.
- Use [interruptible](../yaml/_index.md#interruptible) jobs which can be auto-canceled
  if a new pipeline starts.
- If a job doesn't have to run in every pipeline, use [`rules`](../jobs/job_control.md)
  to make it only run when it's needed.
- [Use private runners](../runners/runners_scope.md#group-runners) for some jobs.
- If you are working from a fork and you submit a merge request to the parent project,
  you can ask a maintainer to run a pipeline [in the parent project](merge_request_pipelines.md#run-pipelines-in-the-parent-project).

If you manage an open source project, these improvements can also reduce compute quota
consumption for contributor fork projects, enabling more contributions.

See the [pipeline efficiency guide](pipeline_efficiency.md) for more details.
