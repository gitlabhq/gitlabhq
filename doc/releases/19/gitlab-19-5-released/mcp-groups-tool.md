---
title: MCP server groups tool
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/607719
categories: [ Agent Tools ]
level: secondary
weight: 50
---

Previously, an agent connecting to GitLab over MCP had no way to discover which groups and
subgroups you have access to without you hardcoding IDs or paths. The new `list_groups` tool
lets your agent browse your organization's group hierarchy on its own, so it can find the right
group before acting instead of guessing at identifiers.
