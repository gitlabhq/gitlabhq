---
title: MCP server repository tools
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

New repository tools let agents browse a project's structure, read its commit
history, and propose changes through the GitLab MCP server:

- `list_repository_tree` explores the file tree.
- `list_branches` and `list_tags` enumerate refs.
- `list_releases` inspects published releases.
- `get_commit` retrieves a commit's metadata, diff, or notes.
- `list_commits` pages through a branch's history.
- `add_commit` commits one or more file actions in a single call, optionally to a
  new branch from a specific starting ref or source project.
- `fork_repository` forks a project, so an agent can go from exploring an
  upstream repository to proposing changes without leaving its client.
