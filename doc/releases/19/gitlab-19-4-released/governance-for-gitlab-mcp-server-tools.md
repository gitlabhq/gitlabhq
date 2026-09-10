---
title: Governance for GitLab MCP server tools
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Free, Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/ai_governance/tool-governance"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/628391
categories: [ AI Governance ]
level: primary
weight: 50
---

Previously, you could only apply [AI agent tool governance](../../../user/ai-governance/tool-governance.md)
rules to internal GitLab Duo Agent Platform tools. Tools available to both GitLab Duo Agent Platform and
third-party agents through the GitLab MCP server followed fixed rules that could not be changed.

You can now govern GitLab MCP server tools from the same place as internal GitLab Duo Agent Platform
tools. They appear alongside internal tools in your group and project **GitLab Duo** settings, where
you can set a mode for each tool:

- Read-only tools default to **Always Allow**, so routine lookups run without interrupting your team.
- Write and delete tools default to **Always Ask**, giving reviewers a checkpoint before an agent
  changes anything.
