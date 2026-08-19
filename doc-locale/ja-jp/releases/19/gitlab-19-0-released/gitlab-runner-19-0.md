---
title: GitLab Runner 19.0
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: "https://docs.gitlab.com/runner"
work_item: "https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/?milestone_title=19.0&state=closed"
categories: [ GitLab Runner Core ]
level: secondary
weight: 150
---

本日、GitLab Runner 19.0もリリースします。GitLab Runnerは、CI/CDジョブを実行してその結果をGitLabインスタンスに送信する、高いスケーラビリティを持つビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

**新機能**

- [Runnerインストルメンテーション: 機能ネゴシエーション、OTLPエクスポートクライアント、および最初の`job_execution`スパン](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39231)
- [Runner設定に設定可能なprepareステージタイムアウトを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/26583)

**バグ修正**

- [`FF_SCRIPTS_TO_STEPS`機能フラグ実装の包括的な修正](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39403)
- [S3キャッシュのダウンロード時に発生する`SignatureDoesNotMatch`エラー](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39402)
- [GitLab RunnerがS3キャッシュを使用してAWS上で実行される際のランタイムエラー](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39386)
- [GitLab Runner 18.9.0以降における`amd64`、`arm64`、`arm`、`armhf`のRPM S3ダウンロードリンクの破損](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39362)
- [Windowsで負の終了コードが正しく報告されない問題](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39292)
- [Kubernetesエグゼキューターのサービスコンテナ命名に関するドキュメントの誤り](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39235)

すべての変更点の一覧は、GitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-0-stable/CHANGELOG.md)をご覧ください。
