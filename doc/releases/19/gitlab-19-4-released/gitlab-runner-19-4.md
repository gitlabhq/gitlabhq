---
title: GitLab Runner 19.4
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/?milestone_title=19.4&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

We're also releasing GitLab Runner 19.4 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

**What's New**

- [Fastzip is now the default archiver for caches and artifacts](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39681)
- [Add `runner` and `system_id` labels to `gitlab_runner_job_router_get_job_duration_seconds`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39576)
- [Add a dedicated SLI, SLO, and alerting integration for the Job Router](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39533)
- [Add suspend and resume support for the Kubernetes executor](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39464)
- [Emit the environment key on job-complete `PUT` request](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39463)
- [Option to suppress the cache upload and download URL in job logs](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39405)
- [Add `services_cap_add` and `services_cap_drop` options to the Docker executor configuration](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/4748)

**Bug Fixes**

- [Job router `409` responses disable runner managers for an hour](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39726)
- [The logrotate usage writer can panic the runner by mutating shared runner labels](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39723)
- [Windows service console restore failure force-kills a job that is stopping gracefully](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39720)
- [Unbounded cardinality for the `job_id` and `runner_controller_id` attributes in a histogram](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39719)
- [Config validation warns `got null` for nil-able fields that have a TOML tag but no JSON tag](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39688)
- [Intermittent silent failure in `get_sources` caused by SIGPIPE in the Git version check](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39680)
- [Spurious `Request bottleneck` warning when `FF_USE_ADAPTIVE_REQUEST_CONCURRENCY` is enabled](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39575)
- [Secret-resolution failures for AWS, GCP, Azure, and GitLab Secrets Manager are now classified by cause](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39574)
- [Kubernetes pause pods fail to start when the runner short ID begins with `-`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39456)
- [Canceling a job always results in a process kill when running as a Windows service](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39297)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-4-stable/CHANGELOG.md).
