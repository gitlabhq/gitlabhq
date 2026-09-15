---
title: GitLab Duoでマージコンフリクトを解決（ベータ版）
stage: ai_coding
level: secondary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/project/merge_requests/conflicts/#resolve-conflicts-with-gitlab-duo"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20688"
categories: [ Duo Agent Platform, Code Review Workflow ]
weight: 80
---

これまでのGitLabでは、単純なケースであっても、GitLab UIまたはコマンドラインでマージコンフリクトを手動で解決する必要がありました。

今回のリリースで、GitLab Duoがマージコンフリクトを自律的に分析し、該当ファイルの編集からコミット作成、ソースブランチへのプッシュまでを自動で行えるようになりました。コンフリクトの解決は、**コンフリクトを解決**ページまたはマージリクエストウィジェットから直接トリガーできます。完了すると、GitLab Duoがサマリーコメントを投稿するため、レビュアーは変更内容をすぐに確認できます。

GitLab Duoはブランチ保護ルールを遵守し、保護ブランチへの強制プッシュは行いません。

この機能はベータ版であり、`mr_ai_resolve_conflicts`機能フラグによって制御されています（デフォルトで有効）。
