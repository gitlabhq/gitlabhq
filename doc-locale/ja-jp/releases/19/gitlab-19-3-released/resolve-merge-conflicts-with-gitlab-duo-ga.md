---
title: "GitLab Duoによるマージコンフリクトの解決が一般提供になりました"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/conflicts/#resolve-conflicts-with-gitlab-duo"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20688
categories: [ DAP Code Review ]
level: secondary
weight: 20
---

以前のバージョンのGitLabでは、単純なケースであっても、GitLab UIまたはコマンドラインからマージコンフリクトを手動で解決する必要がありました。

今回のリリースで、GitLab Duoにコンフリクトの解決を依頼できるようになりました。

マージウィジェットまたは**コンフリクトを解決**ページからコンフリクトの解決を開始します。GitLab Duoがコンフリクトを分析し、該当ファイルを編集してソースブランチに解決内容をコミットしたうえで、変更内容を説明するサマリーコメントをマージリクエストに投稿します。
