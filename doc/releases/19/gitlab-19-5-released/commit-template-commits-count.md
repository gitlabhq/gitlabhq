---
title: Commit count variable in commit templates
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
co_create: true
documentation_link: "../../../user/project/merge_requests/commit_templates/#supported-variables-in-commit-templates"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255231
categories: [ Code Review Workflow ]
level: secondary
weight: 50
---

You can now use `%{commits_count}` in merge commit and squash commit message templates, and in
new merge request description templates. For example, `%{title} (%{commits_count} commits)`
renders as `Bugfix (3 commits)`.

Thank you to [Jeston Singh](https://gitlab.com/sjestonsingh) for this contribution ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255231))!
