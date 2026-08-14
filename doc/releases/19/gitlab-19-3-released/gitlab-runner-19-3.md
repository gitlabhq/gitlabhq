---
title: GitLab Runner 19.3
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/?milestone_title=19.3&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

We're also releasing GitLab Runner 19.3 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

**What's New**

- [Document Job Router version compatibility matrix](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39408)
- [Verify Workhorse is in the KAS to Rails request path for Job Router](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39383)

**Bug Fixes**

- [`clear-docker-cache` prunes all unused images when `IMAGE_FILTER_FLAGS` is empty](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39621)
- [Concrete-mode dispatch skips steps where `When` is unset](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39539)
- [`PrintPodWarningEvents` doesn't work](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38982)
- [Custom executor fails when the `.git` folder is corrupt](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/27540)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-3-stable/CHANGELOG.md).
