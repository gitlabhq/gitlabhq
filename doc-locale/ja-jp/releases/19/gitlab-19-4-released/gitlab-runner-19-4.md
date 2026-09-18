---
title: GitLab Runner 19.4
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/issues/?milestone_title=19.4&state=closed
categories: [ GitLab Runner Core ]
level: secondary
---

本日、GitLab Runner 19.4もリリースしました。GitLab Runnerは、CI/CDジョブを実行してその結果をGitLabインスタンスに送信する、高いスケーラビリティを持つビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

**新機能**

- [Fastzipがキャッシュとアーティファクトのデフォルトアーカイバーになりました](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39681)
- [`gitlab_runner_job_router_get_job_duration_seconds`に`runner`および`system_id`ラベルを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39576)
- [ジョブルーターに専用のSLI、SLO、およびアラートインテグレーションを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39533)
- [Kubernetesエグゼキューターにサスペンドおよびレジューム機能のサポートを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39464)
- [ジョブ完了時の`PUT`リクエストに環境キーを出力](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39463)
- [ジョブログにおけるキャッシュのアップロードおよびダウンロードURLを非表示にするオプション](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39405)
- [Dockerエグゼキューターの設定に`services_cap_add`および`services_cap_drop`オプションを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/4748)

**バグ修正**

- [ジョブルーターの`409`レスポンスによりRunnerマネージャーが1時間無効化される](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39726)
- [logrotate使用状況ライターが共有Runnerラベルを変更することでRunnerがパニックを起こす可能性がある](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39723)
- [Windowsサービスのコンソール復元失敗により、正常停止中のジョブが強制終了される](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39720)
- [ヒストグラム内の`job_id`および`runner_controller_id`属性に対する無制限のカーディナリティ](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39719)
- [TOMLタグはあるがJSONタグのないnull許容フィールドに対して設定検証が`got null`と警告する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39688)
- [Gitバージョンチェック時のSIGPIPEにより`get_sources`で断続的なサイレント障害が発生する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39680)
- [`FF_USE_ADAPTIVE_REQUEST_CONCURRENCY`が有効な場合に誤った`Request bottleneck`警告が表示される](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39575)
- [AWS、GCP、Azure、およびGitLabシークレットマネージャーのシークレット解決失敗が原因別に分類されるようになりました](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39574)
- [RunnerのショートIDが`-`で始まる場合にKubernetesのポーズポッドが起動に失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39456)
- [Windowsサービスとして実行中にジョブをキャンセルすると常にプロセスが強制終了される](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39297)

すべての変更点の一覧は、GitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-4-stable/CHANGELOG.md)をご覧ください。
