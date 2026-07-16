---
title: GitLab Runner 19.2
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/?milestone_title=19.2&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

We're also releasing GitLab Runner 19.2 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

**What's New**

- [GitLab Runner now emits the environment key during the job-complete PUT request](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39463)
- [GitLab Runner now includes a circuit breaker that automatically falls back to Rails when KAS job requests fail consecutively](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39389)

**Bug Fixes**

- [Secret resolution failures are misclassified as `runner_system_failure`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39573)
- [Jobs fail with `context deadline exceeded` when you update GitLab Runner to 19.1.0](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39556)
- [Jobs fail intermittently with `context deadline exceeded` in the Docker executor](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39555)
- [Artifact downloads fail when `FF_CONCRETE` is enabled](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39475)
- [KAS Job Router `GetJob` latency histogram doesn't show any data in staging](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39388)
- [Automatic runner token rotation causes Docker Autoscaler executor to prune active instances and fail running jobs](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39380)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-2-stable/CHANGELOG.md).
