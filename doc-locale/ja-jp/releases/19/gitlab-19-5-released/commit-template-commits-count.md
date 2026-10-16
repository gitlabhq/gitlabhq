---
title: コミットテンプレートのコミット数変数
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

マージコミットおよびスカッシュコミットメッセージテンプレート、ならびに新しいマージリクエスト説明テンプレートで `%{commits_count}` を使用できるようになりました。たとえば、`%{title} (%{commits_count} commits)` は `Bugfix (3 commits)` としてレンダリングされます。

この機能への貢献に対して、[Jeston Singh](https://gitlab.com/sjestonsingh) さんに感謝します（[MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255231)）。
