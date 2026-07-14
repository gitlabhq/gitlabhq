---
title: GitLab Runner 19.1
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/?milestone_title=19.1&state=closed
categories: [ Runner Core ]
level: secondary
---

<!-- categories: Runner Core -->

本日、GitLab Runner 19.1もリリースしました。GitLab Runnerは、CI/CDジョブを実行してその結果をGitLabインスタンスに送信する、高いスケーラビリティを持つビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

**新機能**

- [Runner設定に設定可能な`get_sources`タイムアウトを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39426)

**バグ修正**

- [具体的な実行（`FF_CONCRETE`）が複数の動作領域で抽象シェルと乖離する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39473)
- [`FF_USE_GIT_PROACTIVE_AUTH`と`FF_USE_GIT_BUNDLE_URIS`が有効な場合、Bundle URIのダウンロードが機能不足エラーで失敗する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39471)
- [競合状態によりUI経由でジョブをキャンセルした際にスクリプトがダンプされる問題を修正](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39005)
- [Kubernetesのexecutorヘルパーコンテナのメモリ使用量がOOMキルを引き起こす問題を修正](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/29026)

すべての変更点の一覧は、GitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-1-stable/CHANGELOG.md)をご確認ください。
