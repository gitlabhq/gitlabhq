---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 管理者向けRunnerフリートダッシュボード
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/424495) GitLab 16.6

{{< /history >}}

GitLab管理者は、Runnerフリートダッシュボードを使用して、インスタンスRunnerのヘルス状態を評価できます。Runnerフリートダッシュボードには、以下が表示されます:

- Runnerインフラストラクチャによって引き起こされた最近のCIエラー
- 最もビジーなRunnerで実行されている同時ジョブの数
- インスタンスRunnerで使用されるコンピューティング時間
- ジョブキュー時間（[ClickHouse](#enable-more-ci-analytics-features-with-clickhouse)を使用する場合のみ利用可能）

![Runnerフリートダッシュボード](img/runner_fleet_dashboard_v17_1.png)

## ダッシュボードのメトリクス {#dashboard-metrics}

次のメトリクスは、Runnerフリートダッシュボードで使用できます:

| メトリック                        | 説明 |
|-------------------------------|-------------|
| オンライン                        | インスタンス全体でオンラインになっているRunnerの数。 |
| オフライン                       | 現在オフラインになっているRunnerの数。登録されたものの、GitLabに接続されたことのないRunnerは、この数には含まれていません。 |
| アクティブなRunner                | 現在アクティブなRunnerの総数。 |
| Runnerの使用率（前月） | **ClickHouseが必要**: 前月の各プロジェクトまたはグループRunnerで使用された合計コンピューティング時間。このデータは、コスト分析のためにCSVファイルとしてエクスポートできます。 |
| ジョブを選択するまでの待機時間       | **ClickHouseが必要**: Runnerがジョブをピックアップするまで、ジョブがキューで待機する平均時間。このメトリクスは、組織の目標サービスレベル目標（SLO）で、RunnerがCI/CDジョブキューを処理できるかどうかについてのインサイトを提供します。このデータは24時間ごとに更新されます。 |

{{< alert type="note" >}}

ClickHouseを設定しない場合、フリートダッシュボードページには、ClickHouseバックエンドに依存するウィジェットは入力されたされません。

{{< /alert >}}

## Runnerフリートダッシュボードを表示する {#view-the-runner-fleet-dashboard}

前提要件: 

- 管理者である必要があります。

Runnerフリートダッシュボードを表示するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Runners**を選択します。
1. **フリートダッシュボード**を選択します。

ほとんどのダッシュボードは追加のアクションなしで動作しますが、**ジョブを選択するまでの待機時間**のチャートと、[エピック11183](https://gitlab.com/groups/gitlab-org/-/epics/11183)で提案されている機能は例外です。これらの機能を使用するには、[追加のインフラストラクチャをセットアップ](#enable-more-ci-analytics-features-with-clickhouse)する必要があります。

## インスタンスRunnerで使用されるコンピューティング時間をエクスポートする {#export-compute-minutes-used-by-instance-runners}

前提要件: 

- インスタンスへの管理者アクセス権が必要です。
- [ClickHouseのインテグレーション](../../integration/clickhouse.md)を有効にする必要があります。

Runnerの使用状況を分析するには、ジョブの数と実行されたRunner時間を含むCSVファイルをエクスポートします。CSVファイルには、各プロジェクトのRunnerタイプとジョブステータスが表示されます。CSVは、エクスポートが完了するとメールで送信されます。

インスタンスRunnerで使用されるコンピューティング時間をエクスポートするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Runners**を選択します。
1. **フリートダッシュボード**を選択します。
1. **Export CSV**（CSVをエクスポート）を選択します。

## ClickHouseでCI分析機能をさらに有効にする {#enable-more-ci-analytics-features-with-clickhouse}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.7で`ci_data_ingestion_to_click_house``clickhouse_ci_analytics`という[フラグ](../../administration/feature_flags/_index.md)を伴い、[実験](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/11180)されました。デフォルトでは無効になっています。
- GitLab 16.10で、[GitLab.comとGitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/424866)で有効化されました。機能フラグ`ci_data_ingestion_to_click_house`および`clickhouse_ci_analytics`は削除されました。
- GitLab 17.1で[ベータ](../../policy/development_stages_support.md#beta)版に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/424789)されました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は[ベータ](../../policy/development_stages_support.md#beta)版であり、予告なく変更される場合があります。詳細については、[エピック11180](https://gitlab.com/groups/gitlab-org/-/epics/11180)を参照してください。

{{< /alert >}}

CI分析の追加機能を有効にするには、[ClickHouseのインテグレーション](../../integration/clickhouse.md)を構成します。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[ClickHouseを使用したRunnerフリートダッシュボードの設定](https://www.youtube.com/watch?v=YpGV95Ctbpk)を参照してください。
<!-- Video published on 2023-12-19 -->

## フィードバック {#feedback}

Runnerフリートダッシュボードの改善にご協力いただくため、[イシュー421737](https://gitlab.com/gitlab-org/gitlab/-/issues/421737)でフィードバックをお寄せください。特に:

- ダッシュボードを機能させるためのGitLabの設定がどれほど簡単か難しかったか。
- ダッシュボードがどれほど役に立ったか。
- そのダッシュボードに他にどのような情報を表示したいか。
- その他の関連する考えやアイデア。
