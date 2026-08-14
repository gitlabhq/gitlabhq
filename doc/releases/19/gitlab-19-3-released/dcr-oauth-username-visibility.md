---
title: See which user authorized each MCP OAuth application
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/605884
categories: [ AI Agents ]
level: secondary
weight: 50
---

Previously, when MCP clients connected to GitLab using OAuth Dynamic Client Registration (DCR),
all dynamically-registered OAuth applications appeared in the Admin Area with only a generic
client name, making it impossible to tell which user authorized a given application.
Now, when you approve an MCP OAuth connection, your username is automatically appended to the
application name — for example, `[Unverified Dynamic Application] kiro — authorized by @username`.
You can quickly identify which user is behind each dynamic OAuth application directly from the
Admin Area, without any additional configuration.
