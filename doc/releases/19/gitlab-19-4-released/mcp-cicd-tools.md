---
title: MCP server CI/CD tools
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

New CI/CD tools let agents trigger, inspect, and control CI/CD from any MCP
client:

- `save_pipeline` runs, retries, or cancels a pipeline without switching tools.
- `get_job` returns job metadata together with the job trace, so an agent can
  read the log of a failed build and diagnose the problem on its own.

Previously, agents had no way to trigger or inspect pipelines through MCP.
