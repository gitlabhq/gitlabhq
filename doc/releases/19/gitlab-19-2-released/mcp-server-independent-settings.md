---
title: Turn on MCP server independently from the Agent Platform
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/590729
categories: [ AI Agents ]
level: secondary
weight: 50
---

To give you finer control over how external tools connect to your GitLab instance or group,
you can now turn the GitLab MCP server on or off independently from Agent Platform settings.

Previously, the GitLab MCP server and Agent Platform shared the same on and off setting,
so you could not turn the MCP server on without also turning on Agent Platform features.
Now you can let other tools access GitLab as an MCP server without turning on the Agent Platform,
or keep the GitLab MCP server turned off while you use Agent Platform features.
