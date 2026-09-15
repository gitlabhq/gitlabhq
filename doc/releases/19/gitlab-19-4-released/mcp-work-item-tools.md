---
title: MCP server work item tools
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

The GitLab MCP server now exposes work item tools, so agents and MCP clients can search, read, create, and update issues, epics, tasks, incidents, objectives, and key results.

Use `get_work_item` to read a single item in depth, `list_work_items` to search across a group or project, and `save_work_item` to create or update any work item type.

Because issues and epics are work item types, `get_work_item` and `save_work_item` cover what `get_issue` and `create_issue` do today.

`save_note` lets an agent comment on a work item or merge request and reply inside an existing discussion thread. The introduction of this tool renames existing `create_merge_request_note` and `create_workitem_note`.
