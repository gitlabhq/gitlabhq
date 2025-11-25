---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループのRunnerフリートダッシュボード
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 17.0で、`runners_dashboard_for_groups`という名前の[フラグ](../../administration/feature_flags/_index.md)を伴う[ベータ](../../policy/development_stages_support.md#beta)版として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151640)されました。デフォルトでは無効になっています。
- GitLab 17.2で機能フラグ`runners_dashboard_for_groups`が[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/459052)されました。

{{< /history >}}

グループのメンテナーロール以上のユーザーは、Runnerフリートダッシュボードを使用して、グループRunnerの健全性を評価できます。

![グループのRunnerフリートダッシュボード](img/runner_fleet_dashboard_groups_v17_1.png)

## ダッシュボードのメトリクス {#dashboard-metrics}

以下のメトリクスは、Runnerフリートダッシュボードで使用できます:

| メトリック                        | 説明 |
|-------------------------------|-------------|
| オンライン                        | オンラインのRunnerの数。**管理者**エリアでは、このメトリクスはインスタンス全体のRunnerの数を表示します。グループでは、このメトリクスはグループとそのサブグループのRunnerの数を表示します。 |
| オフライン                       | オフラインのRunnerの数。 |
| アクティブなRunner                | アクティブなRunnerの数。 |
| Runnerの使用率（前月） | グループRunner上の各プロジェクトで使用されるコンピューティング時間。コスト分析のためにCSVとしてエクスポートするオプションが含まれています。 |
| ジョブを選択するまでの待機時間       | Runnerの平均待機時間を表示します。このメトリクスは、Runnerが組織の目標サービスレベルの目標でCI/CDジョブキューを処理できるかどうかについてのインサイトを提供します。このメトリクスウィジェットを作成するデータは、24時間ごとに更新されます。 |

## グループのRunnerフリートダッシュボード {#view-the-runner-fleet-dashboard-for-groups}

前提要件: 

- グループのメンテナーロールが必要です。

グループのRunnerフリートダッシュボードを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **ビルド** > **Runners**を選択します。
1. **フリートダッシュボード**を選択します。

GitLab Self-Managedの場合、ほとんどのダッシュボードメトリクスは追加の設定なしで動作します。**Runner usage**と**ジョブを選択するまでの待機時間**のメトリクスを使用するには、[ClickHouse分析データベースを設定](runner_fleet_dashboard.md#enable-more-ci-analytics-features-with-clickhouse)する必要があります。
