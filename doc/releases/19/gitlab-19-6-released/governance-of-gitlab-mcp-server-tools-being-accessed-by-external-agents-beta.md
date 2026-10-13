---
title: Govern GitLab MCP server tools for AI agents
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../user/ai-governance/tool-governance/#gitlab-mcp-server-tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/633490
categories: [ AI Governance ]
level: primary
weight: 50
---

You can now control which GitLab MCP server tools AI agents can use, with rules that GitLab enforces for every client that connects.

Owners of a top-level group set each tool to:

- **Always Deny**: The tool is blocked entirely and is invisible to the agent.
- **Always Ask**: The user must approve the tool before it runs.
- **Always Allow**: The tool runs as usual.

This feature is in beta. To provide feedback, see [issue 633490](https://gitlab.com/gitlab-org/gitlab/-/work_items/633490).
