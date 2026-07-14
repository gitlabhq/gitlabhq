---
title: すべてのアクタータイプに対するGit操作の監査イベント
stage: create
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../administration/compliance/audit_event_reports/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20506"
categories: [ Source Code Management ]
---

<!-- categories: Source Code Management -->

GitLab 18.10では、人間のユーザーによるGit操作（clone、pull、fetch、push）が監査ログに記録されるようになりました。

GitLab 19.1では、この機能がすべてのアクタータイプに拡張され、デプロイトークンを使用するRunnerやSSH証明書ユーザーも対象となりました。
これにより、監査ログはリポジトリ全体のすべてのGitアクティビティを、操作の実行者を問わず完全に反映するようになりました。
