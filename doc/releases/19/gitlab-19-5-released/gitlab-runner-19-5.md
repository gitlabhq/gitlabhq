---
title: GitLab Runner 19.5
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/?milestone_title=19.5&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

We're also releasing GitLab Runner 19.5 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

**What's New**

- [Clearer Kubernetes executor error message when the helper container is OOM-killed](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39842)
- [Log the CPU model of the job execution environment at job start](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39814)

**Bug Fixes**

- [IPv4-only services fail on dual-stack networks because Docker service health check dials only the last resolved address](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39939)
- [Runner and job tokens with an instance prefix are not recognized](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39938)
- [Kubernetes executor sends an unpaginated events `LIST` request on every poll, saturating API Priority and Fairness on busy clusters](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39848)
- [Docker executor applies `mac_address` to service containers instead of only the build container](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39803)
- [`RUNNER_AFTER_SCRIPT_TIMEOUT` is reset to 5 minutes when it exceeds the job timeout](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39717)
- [Cache upload fails with `403` on S3 servers that enforce SigV4 signed-header rules because `cache_archiver` sends a `Content-Type` the presigned URL does not sign](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39701)
- [Kubernetes executor always sets an empty pod-level `resources` object, causing `BestEffort` QoS misclassification on Kubernetes 1.34 and later](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39671)
- [Step-runner local server reports ready before its gRPC server is listening](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39653)
- [Documented `systemd` graceful shutdown configuration kills the running VM for the VirtualBox, Parallels, and SSH executors](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39563)
- [`proxy_exec` prints the helper binary help and exits instead of running the job when the image has a multi-argument `ENTRYPOINT`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39452)
- [Docker executor ignores the `platform` parameter when multiple platforms of the same image are pulled](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38514)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-5-stable/CHANGELOG.md).
