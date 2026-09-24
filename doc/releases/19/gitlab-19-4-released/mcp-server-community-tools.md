---
title: GitLab MCP server tools from the community
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
co_create: true
documentation_link: "../../../user/model_context_protocol/mcp_server_tools/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248155
categories: [ Agent Tools ]
level: secondary
weight: 30
---

Community contributors added new tools for the GitLab MCP server. Agents can now use `get_project`
and `list_project_members` to read project metadata and members, `list_branches` to list a
repository's branches, and `list_merge_requests` to list merge requests across a whole group.
`get_duo_session` fetches a GitLab Duo session so you can see what an earlier run did.

These tools ship alongside the other new GitLab MCP server tools in 19.4 and run under the same
tool governance, so an agent using them follows the rules your team already set.

Thank you to the following users for these contributions!

- [Dhairya Majmudar](https://gitlab.com/DhairyaMajmudar) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248155) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250316))
- [Giannis Kepas](https://gitlab.com/gkepas) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250430) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251379))
- [Mahaveer A](https://gitlab.com/Mahaveer1013) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252619))
