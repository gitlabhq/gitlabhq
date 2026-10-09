---
title: Auto mode in GitLab Duo CLI
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#auto-mode"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23697
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLI has a new auto mode.
In auto mode, GitLab Duo uses tools without asking for approval first, so longer tasks run
without stopping for each shell command, `git` operation, or MCP tool call.

Auto mode respects your organization's controls:

- Auto mode is off by default. Administrators, Owners, and Maintainers can turn the setting on for instances, groups, and projects.
  Administrators and group Owners can also lock it to **Always off** for the entire instance or group.
- Agent tool governance still applies. Tools set to **Always Deny** stay blocked.

To use auto mode, you need GitLab Duo CLI 9.22.0 or later.
Press <kbd>Tab</kbd> until the mode under the `>` prompt shows `auto`.
Use auto mode only in repositories you trust and on branches you can discard.
