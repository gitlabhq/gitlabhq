---
title: MCP server semantic search tool
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

`semantic_code_search` is now `semantic_search`. The tool finds code by meaning
rather than by exact symbol or filename, which is unchanged from earlier
releases. The rename adds a `scope` parameter so that additional indexed content
types can fold into the same tool in future releases. Today `scope` accepts
`code` only.
