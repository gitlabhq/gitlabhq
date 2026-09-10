---
title: MCP server merge request tools
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

Merge request tools let agents run the full merge request loop through the
GitLab MCP server:

- `save_merge_request` opens and updates an MR.
- `get_merge_request` inspects an MR in depth, with new diffs, conflicts, and
  approvals facets.
- `list_merge_requests` now works at group scope.
- `save_merge_request_review` leaves line-level review comments, with batched
  diff comments and a summary in a single call.
- `accept_merge_request` merges an MR once checks pass, and can also approve
  or unapprove it.
