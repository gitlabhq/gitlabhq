---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Job router
description: Route CI/CD jobs through the job router for advanced job orchestration.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19607) in GitLab 18.7 [with feature flags](../../../administration/feature_flags/_index.md) named `job_router` and `job_router_instance_runners`. Disabled by default.
- [Admission control introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/584394) in GitLab 18.9 [with a flag](../../../administration/feature_flags/_index.md) named `job_router_admission_control`. Disabled by default.

{{< /history >}}

The job router is a component of the GitLab Agent Server (KAS) that provides advanced
job orchestration capabilities for GitLab CI/CD. Instead of runners that poll GitLab
directly for jobs, runners connect to the job router, which manages job distribution
and provides features like admission control.

## Architecture

```plaintext
GitLab Instance → Job Router (KAS) → Runner
                        ↓
              Runner Controller (optional)
```

The job router:

- Receives job requests from runners
- Responds with jobs to run to runners
- Optionally consults runner controllers for admission decisions

## Prerequisites

To use the job router, you must have:

- GitLab instance with the following feature flags set to `true`:
  - `job_router`: For group and project runners
  - `job_router_instance_runners`: For instance runners
  - `job_router_admission_control`: For admission control (optional)
- GitLab Runner 18.9 or later with the `FF_USE_JOB_ROUTER` environment variable set to `true`.

## Discover job router information

Runners can discover the job router URL using the [job router discovery API](../../../api/runners.md#discover-job-router-information).

## Runner controllers

Runner controllers enable admission control for jobs routed through the job router.
For more information, see [runner controllers](runner_controllers.md).

## Related topics

- [Runner controllers](runner_controllers.md)
- [Runner controllers API](../../../api/runner_controllers.md)
- [Runner controller scopes API](../../../api/runner_controllers.md#runner-controller-scopes)
- [Runner controller tokens API](../../../api/runner_controller_tokens.md)
- [Tutorial: Build a runner admission controller](../../../tutorials/build_runner_admission_controller/_index.md)
