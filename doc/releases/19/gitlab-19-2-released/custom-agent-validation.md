---
title: Custom Agent validation
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/duo_agent_platform/agents/custom"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/601986
categories: [ AI Catalog Creation ]
level: secondary
weight: 50
---

Previously, you could save a custom agent in AI Catalog whose prompt would fail when run. For example, prompts that tripped security rules caused the agent to silently do nothing when being used.

Now, when you create or update a custom agent, GitLab validates the prompt configuration, and tells you about any errors before you save that agent.
