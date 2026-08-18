---
title: Restricted visibility for custom agents and flows
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_catalog
documentation_link: "../../../user/duo_agent_platform/agents/custom/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22590
categories: [ AI Catalog Creation ]
level: secondary
weight: 50
---

You can now set custom agents and custom flows to **Restricted visibility** for every group, subgroup, and project in your top-level group.

Previously, you could only set a custom flow or agent to **Private** (one project only) or **Public** (visible to everyone on GitLab.com). When you set the visibility to **Restricted**, the flow or agent is visible to only groups, subgroup, and projects in your top-level group. This ensures that internal logic about your custom agents and flows are not shared outside your company or organization.
