---
title: Per-session tool approvals with admin controls
stage: ai-powered
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/gitlab_duo_chat/agentic_chat/#tool-approvals"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/596366"
categories: [ Duo Agent Platform, Duo Chat ]
weight: 70
---

Before GitLab Duo Agentic Chat can use a tool on your behalf, it requires your approval. Each tool
invocation requires a separate approval.

Now, you can approve a trusted tool once for an entire session and streamline your workflows.

Administrators control whether tool approval for sessions is available. The following settings
cascade from instance to group to project:

- **On by default**
- **Off by default**
- **Always off**

Groups and subgroups can modify the setting unless an administrator sets it to **Always off**.

The default setting is **Off by default**, ensuring each tool invocation requires explicit approval
unless an administrator changes it.
