---
title: Restrict access to MCP servers (beta)
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: software_supply_chain_security
documentation_link: "../../../user/ai-governance/tool-governance/#block-model-context-protocol-mcp-servers"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/628378
categories: [ AI Governance ]
level: primary
weight: 50
---

You can now restrict access to MCP (Model Context Protocol) servers by
allowing or denying access to:

- An entire external MCP server.
- Individual tools on an MCP server.

This feature gives you assurance that AI agents within Duo Agent Platform are operating
within governed boundaries and can only access MCP tools that are within their scope to
perform their activities, sessions, and tasks.

These controls apply consistently wherever AI agents run, including:

- Agentic Chat.
- Flows.
- IDE and CLI environments.

This feature is currently in beta and we welcome your feedback in [issue #628378](https://gitlab.com/gitlab-org/gitlab/-/issues/628378).
