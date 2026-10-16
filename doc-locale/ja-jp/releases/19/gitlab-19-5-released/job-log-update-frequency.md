---
title: ジョブログの更新頻度を設定する
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: verify
co_create: true
documentation_link: "../../../administration/settings/continuous_integration/#configure-the-frequency-of-job-log-updates"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251401
categories: [ Continuous Integration (CI) ]
level: secondary
weight: 30
---

管理者は、**管理者エリア** > **設定** > **CI/CD** またはSettings APIを通じて、ジョブログの更新頻度を設定できるようになりました。3秒から3600秒の範囲で選択できます。
以前のバージョンのGitLabでは、これらの間隔は定数であったため、インスタンスにパッチを適用しない限り、短いジョブのライブログの初期遅延を短縮することができませんでした。

この貢献をしてくださった [Aleksandr Kotlyar](https://gitlab.com/aleksandr-kotlyar) さんに感謝します（[MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251401)）！
