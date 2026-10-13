---
title: MCP server toolset selection
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server/#select-tool-groups-toolsets"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607755
categories: [ Agent Tools ]
level: secondary
weight: 50
---

You can now choose which toolsets the GitLab MCP server exposes. Every additional tool that isn't required wastes space in the LLM's context window, and runs the risk of confusing the LLM, especially if you are using multiple MCP servers at once.
