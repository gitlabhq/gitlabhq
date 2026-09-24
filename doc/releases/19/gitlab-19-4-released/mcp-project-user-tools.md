---
title: MCP server project and user tools
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

New project and user tools give agents the context they need to target work
correctly through the GitLab MCP server:

- `list_projects` finds and reads project details.
- `get_user` looks up user details for assignment and mentions.

Previously, agents had no way to discover project or user information
through the GitLab MCP server.
