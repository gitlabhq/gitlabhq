---
title: GitLab Runner 19.1
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/?milestone_title=19.1&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

We're also releasing GitLab Runner 19.1 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

**What's New**

- [Add configurable `get_sources` timeout to runner configuration](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39426)

**Bug Fixes**

- [Concrete execution (`FF_CONCRETE`) diverges from abstract shell in multiple behavior areas](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39473)
- [Bundle URI downloads fail with insufficient capabilities when `FF_USE_GIT_PROACTIVE_AUTH` and `FF_USE_GIT_BUNDLE_URIS` are enabled](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39471)
- [Prevent script dump on job cancellation through UI due to race condition](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39005)
- [Fix Kubernetes executor helper container memory usage causing OOM kills](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/29026)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-1-stable/CHANGELOG.md).
