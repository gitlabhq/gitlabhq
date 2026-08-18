---
title: GitLab Runner 19.0
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: "https://docs.gitlab.com/runner"
work_item: "https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/?milestone_title=19.0&state=closed"
categories: [ GitLab Runner Core ]
level: secondary
weight: 150
---

We're also releasing GitLab Runner 19.0 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

**What's New**

- [Runner instrumentation: Feature negotiation, OTLP export client, and first `job_execution` span](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39231)
- [Add configurable prepare stage timeout to runner configuration](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/26583)

**Bug Fixes**

- [Comprehensive fixes for `FF_SCRIPTS_TO_STEPS` feature flag implementation](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39403)
- [`SignatureDoesNotMatch` error when downloading S3 cache](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39402)
- [Runtime error when GitLab Runner runs in AWS with S3 cache](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39386)
- [Broken RPM S3 download links for `amd64`, `arm64`, `arm`, and `armhf` in GitLab Runner 18.9.0 and later](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39362)
- [Negative exit codes are reported incorrectly on Windows](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39292)
- [Incorrect Kubernetes executor service container naming documentation](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39235)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-0-stable/CHANGELOG.md).
