---
title: "Improved first-run experience in GitLab Duo CLI"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#startup-cards"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22187
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLI now helps new users get started without leaving the terminal:

- On first run, an onboarding card helps you connect MCP servers and install GitLab plugins.
- Each new session opens with prompts suggested from your open merge requests and issues.
  For a merge request prompt, GitLab Duo checks out the source branch first if it exists.
- The status bar shows your branch, project, merge request, `/goal` progress, and MCP status.
- The setup screen links to token creation and validates your token before saving.
- Tips in the prompt and the `/whatsnew` command point you to new features.

To get the full experience, update to GitLab Duo CLI 9.28.0 or later.
