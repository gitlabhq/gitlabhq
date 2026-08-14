---
title: New MCP tools for reading and searching merge requests
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/605878
categories: [ Agent Tools ]
level: secondary
weight: 50
---

You can now use `get_merge_request` to retrieve a merge request along with its diffs, commits,
notes, pipelines, or discussions in a single call, so your AI agent no longer has to chain
multiple requests to get the full picture of an MR.

You can also use the new `list_merge_requests`
tool to search and filter merge requests by author, assignee, reviewer, state, labels, or
free-text query, making it easy to find exactly the MRs you care about without leaving your workflow.
