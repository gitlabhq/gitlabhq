---
title: Trigger flows with a generally available API
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../api/duo_agent_platform_flows/#trigger-a-flow"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607860
categories: [ Agent Tools ]
level: secondary
weight: 50
---

In previous versions of GitLab, the API endpoint you use to trigger GitLab Duo Agent Platform flows
from CI/CD pipelines, scripts, and other automation was an experiment, so it was hard to know whether you could rely on it in production.
Now the [trigger a flow endpoint](../../../api/duo_agent_platform_flows.md#trigger-a-flow) of the Flows API is generally available, so you can build production automation on it knowing it follows the GitLab REST API breaking changes policy.
