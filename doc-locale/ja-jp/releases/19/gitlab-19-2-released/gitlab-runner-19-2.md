---
title: GitLab Runner 19.2
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/?milestone_title=19.2&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

本日、GitLab Runner 19.2もリリースしました。GitLab Runnerは、CI/CDジョブを実行してその結果をGitLabインスタンスに送信する、高いスケーラビリティを持つビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

**新機能**

- [GitLab Runnerがジョブ完了PUTリクエスト時に環境キーを送信するようになりました](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39463)
- [GitLab RunnerにKASジョブリクエストが連続して失敗した場合にRailsへ自動的にフォールバックするサーキットブレーカーが追加されました](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39389)

**バグ修正**

- [シークレットの解決失敗が`runner_system_failure`として誤って分類される](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39573)
- [GitLab Runnerを19.1.0にアップデートするとジョブが`context deadline exceeded`で失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39556)
- [DockerのexecutorでジョブがときどきContext deadline exceededで失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39555)
- [`FF_CONCRETE`が有効な場合にアーティファクトのダウンロードが失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39475)
- [KAS Job RouterのGetJobレイテンシーヒストグラムにステージング環境でデータが表示されない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39388)
- [Runnerトークンの自動ローテーションによりDocker Autoscalerのexecutorがアクティブなインスタンスを削除し、実行中のジョブが失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39380)

すべての変更点はGitLab Runnerの[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-2-stable/CHANGELOG.md)をご覧ください。
