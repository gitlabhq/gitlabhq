---
title: MCP server GitLab Duo agent and flow tools
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools/#start_duo_session"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21395
categories: [ Agent Tools ]
level: secondary
weight: 50
---

New GitLab Duo agent and flow tools let you invoke and track GitLab Duo agents and flows
from any MCP client:

- `start_duo_session` starts a session.
- `get_duo_session` reads a session's current state.
- `list_duo_sessions` pages through your session history.
- `list_duo_agents_and_flows` lists the GitLab Duo agents and flows enabled in a project.
