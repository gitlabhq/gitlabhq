---
title: Pattern-based tool approval for Agentic Chat
offering: [ gitlab_com, self_managed, gitlab_dedicated]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/gitlab_duo_chat/agentic_chat/#approve-tools-in-your-local-environment"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21850
categories: [ 'Duo Agent Platform', 'Duo Chat', 'Editor Extensions' ]
weight: 50
ignore_in_report: true
---

<!-- categories: Duo Agent Platform, Duo Chat, Editor Extensions -->

Previously, when Agentic Chat asked you to approve a tool invocation, you could approve it once or approve the tool call with these arguments for the remainder of the session. Different arguments would require additional approval.

Workflows that repeated similar
commands, such as a series of `git` operations, forced you through a stream of nearly
identical prompts.

You can now choose a third approval option, **Approve all uses of this tool for
session**. This option approves invocations of the tool for the remainder of the session whenever the arguments match the approved pattern. 

Pattern-based approvals are available for Agentic Chat in the GitLab UI, GitLab Duo CLI, GitLab for VS Code, and the GitLab Duo plugin for JetBrains IDEs.
