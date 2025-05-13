---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Calculations, quotas, purchase information.
title: Compute minutes
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Renamed](https://gitlab.com/groups/gitlab-com/-/epics/2150) from "CI/CD minutes" to "compute quota" or "compute minutes" in GitLab 16.1.

{{< /history >}}

The usage of instance runners by projects running CI/CD jobs is measured in compute minutes.

For some installation types, your [namespace](../../user/namespace/_index.md) has an [compute quota](instance_runner_compute_minutes.md#compute-quota-enforcement),
which limits the available compute minutes you can use.

A compute quota can be applied to all [admin-managed instance runners](instance_runner_compute_minutes.md):

- All instance runners on GitLab.com or GitLab Self-Managed
- All self-hosted instance runners on GitLab Dedicated

The compute quota is disabled by default but can be enabled for top-level groups and user namespaces.
On GitLab.com, the quota is enabled by default to limit usage on Free namespaces. The limit is increased if a paid subscription is purchased.

GitLab-hosted instance runners on GitLab Dedicated cannot have the instance runner compute quota applied.

### Instance runners

For instance runners on GitLab.com, GitLab Self-Managed, and self-hosted instance runners on GitLab Dedicated:

- You can view your usage in the [instance runner usage dashboard](instance_runner_compute_minutes.md#view-usage).
- When a quota is enabled:
  - You receive notifications when approaching your quota limits.
  - Enforcement measures are applied when you exceed your quota.

For GitLab.com:

- The base monthly compute quota is determined by your subscription tier.
- You can [purchase additional compute minutes](../../subscriptions/gitlab_com/compute_minutes.md) if you need more.

### GitLab-hosted runners on GitLab Dedicated

GitLab-hosted runners on GitLab Dedicated [are tracked separately](dedicated_hosted_runner_compute_minutes.md):

- You can view the estimated usage for your instance in the [GitLab-hosted runner usage dashboard](dedicated_hosted_runner_compute_minutes.md#view-compute-usage).
- Usage billing is based on build duration logs collected from GitLab-hosted runners.
- Quota enforcement and notifications are not available.

## Compute minute usage

### Compute usage calculation

Your compute minute usage for each job is calculated using this formula:

```plaintext
Job duration / 60 * Cost factor
```

- **Job duration**: The time, in seconds, that a job took to run on an instance runner,
  not including time spent in the `created` or `pending` statuses.
- **Cost factor**: A number based on the [runner type](#cost-factors-for-gitlab-hosted-runners) and
  [project type](#cost-factors-for-gitlabcom).

The value is converted into compute minutes and added to the count of used units
in the job's top-level namespace.

For example, if a user `alice` runs a pipeline:

- In a project in the `gitlab-org` namespace, the compute minutes used by each job in the pipeline are
  added to the overall usage for the `gitlab-org` namespace, not the `alice` namespace.
- In a personal project in their `alice` namespace, the compute minutes are added
  to the overall usage for their namespace.

The compute used by one pipeline is the total compute minutes used by all the jobs
that ran in the pipeline. Jobs can run concurrently, so the total compute usage
can be higher than the end-to-end duration of a pipeline.

[Trigger jobs](../yaml/_index.md#trigger) do not execute on runners, so they do not
consume compute minutes, even when using [`strategy:depend`](../yaml/_index.md#triggerstrategy)
to wait for the [downstream pipeline](downstream_pipelines.md) status.
The triggered downstream pipeline consumes compute minutes the same as other pipelines.

Usage is tracked on a monthly basis. On the first day of the month the usage is `0` for that month for all namespaces.

### Cost factors

The rate at which compute minutes are consumed varies based on the runner type and project settings.

#### Cost factors for GitLab-hosted runners

GitLab-hosted runners have different cost factors depending on the runner type
(Linux, Windows, macOS) and the virtual machine configuration:

| GitLab-hosted runner type  | Machine size           | Cost factor             |
|:---------------------------|:-----------------------|:------------------------|
| Linux x86-64 (default)     | `small`                | `1`                     |
| Linux x86-64               | `medium`               | `2`                     |
| Linux x86-64               | `large`                | `3`                     |
| Linux x86-64               | `xlarge`               | `6`                     |
| Linux x86-64               | `2xlarge`              | `12`                    |
| Linux x86-64 + GPU-enabled | `medium`, GPU standard | `7`                     |
| Linux Arm64                | `small`                | `1`                     |
| Linux Arm64                | `medium`               | `2`                     |
| Linux Arm64                | `large`                | `3`                     |
| macOS M1                   | `medium`               | `6` (**Status:** Beta)  |
| macOS M2 Pro               | `large`                | `12` (**Status:** Beta) |
| Windows                    | `medium`               | `1` (**Status:** Beta)  |

These cost factors apply to GitLab-hosted runners on GitLab.com and GitLab Dedicated.

Certain [discounts apply to GitLab.com](#cost-factors-for-gitlabcom) based on project type.

#### Cost factors for GitLab.com

| Project type | Cost factor | Compute minutes used |
|--------------|-------------|---------------------|
| Standard projects | [Based on runner type](#cost-factors-for-gitlab-hosted-runners) | 1 minute per (job duration / 60 × factor) |
| Public projects in [GitLab for Open Source program](../../subscriptions/community_programs.md#gitlab-for-open-source) | `0.5` | 1 minute per 2 minutes of job time |
| Public forks of [GitLab Open Source program projects](../../subscriptions/community_programs.md#gitlab-for-open-source) | `0.008` | 1 minute per 125 minutes of job time |
| [Community contributions to GitLab projects](#community-contributions-to-gitlab-projects) | Dynamic discount | See below |

#### Community contributions to GitLab projects

Community contributors can use up to 300,000 minutes on instance runners when contributing to open source projects
maintained by GitLab. The maximum of 300,000 minutes would only be possible if contributing exclusively to projects
part of the GitLab product.

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

### Reduce compute minute usage

If your project consumes too many compute minutes, try these strategies to reduce your usage:

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

If you manage an open source project, these improvements can also reduce compute minute
usage for contributor fork projects, enabling more contributions.

See the [pipeline efficiency guide](pipeline_efficiency.md) for more details.
