---
title: Foundational flows readiness checks
offering: [ self_managed, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../administration/gitlab_duo/configure/#run-a-health-check-for-gitlab-duo"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/599536
categories: [ Duo Agent Platform ]
level: secondary
---

<!-- categories: Duo Agent Platform  -->

GitLab Duo health checks now include foundational flows readiness checks, which verify:

- The instance-level flow execution setting is enabled.
- The instance-level foundational flows setting is enabled.
- At least one active instance runner with the `gitlab--duo` tag is registered and
  connected, and uses a Docker-compatible executor.
