---
title: "`/goal` command in GitLab Duo CLI is generally available"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#slash-commands"
work_item: https://gitlab.com/groups/gitlab-org/ai-powered/-/work_items/10
categories: [ Duo CLI ]
level: secondary
weight: 50
---


The `/goal` slash command in GitLab Duo CLI is now generally available in GitLab Duo CLI 9.27.0.

Describe an open-ended goal, and GitLab Duo delegates it to a governed, goal-driven flow that
runs locally and handles both implementation and verification.

To start, run `/goal <task>`. For example:

```plaintext
/goal Fix the failing tests in spec/models/user_spec.rb
```

In GitLab 19.5 (GitLab Duo CLI 9.24.0), the **Run suggested prompts as /goal sessions** setting
in `/settings` runs suggested prompts as `/goal` sessions instead of chat messages.

`/goal` requires GitLab 19.3 and later, and GitLab Duo CLI 9.17.0 and later.
