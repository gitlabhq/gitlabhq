---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab DuoとSDLCの傾向
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: GitLab Self-Managedのベータ版

{{< /details >}}

{{< history >}}

- GitLab 16.11で`ai_impact_analytics_dashboard`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443696)されました。デフォルトでは無効になっています。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/451873)になりました。機能フラグ`ai_impact_analytics_dashboard`は削除されました。
- GitLab 17.6から、GitLab Duoアドオンが必須になりました。
- 18.2でGitLab UltimateからGitLab Premiumに移行しました。
- GitLab 18.2.1でAmazon Qのサポート対象となりました。
- パイプラインメトリクステーブルがGitLab 18.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/550356)されました。
- GitLab 18.4で、`AI impact analytics`から`GitLab Duo and SDLC trends`に名称が変更されました。

{{< /history >}}

この機能は、GitLab Self-Managedのベータ版です。詳細については、[エピック51](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/epics/51)を参照してください。

GitLab DuoとSDLCの傾向は、GitLab Duoがソフトウェア開発ライフサイクル（SDLC）のパフォーマンスに与える影響を測定します。このダッシュボードは、プロジェクトまたはグループのAI導入状況における主要なSDLCメトリクスの表示レベルを提供します。このダッシュボードを使用して、AI投資によってどのメトリクスが改善されたかを測定できます。

GitLab DuoとSDLCの傾向を使用すると、次のことができます:

- Duoの過程に関連するSDLCの傾向を追跡します: プロジェクトまたはグループにおけるGitLab Duoの使用傾向が、平均マージ時間やCI/CD統計などの他の重要な生産性メトリクスにどのように影響するかを調べます。Duoの使用状況メトリクスは、現在月を含め、過去6か月間表示されます。
- GitLab Duo機能の導入状況を監視します: 過去30日間のプロジェクトまたはグループにおけるシートと機能の使用状況を追跡します。

ライセンスの使用率を最適化する方法については、[GitLab Duoアドオン](../../subscriptions/subscription-add-ons.md)を参照してください。

GitLab DuoとSDLCの傾向の詳細については、ブログ記事[GitLab Duoの開発: AIインパクト分析ダッシュボードがAIのROIを測定](https://about.gitlab.com/blog/2024/05/15/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/)を参照してください。

クリックスルーデモについては、[GitLab DuoとSDLCの傾向の製品ツアー](https://gitlab.navattic.com/ai-impact)をご覧ください。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab Duo AIインパクトダッシュボード](https://youtu.be/FxSWX64aUOE?si=7Yfc6xHm63c3BRwn)を参照してください。
<!-- Video published on 2025-03-06 -->

## 主要メトリクス {#key-metrics}

- **アサインしたDuoシートの取り決め**: Duoシートが割り当てられ、過去30日間に少なくとも1つのAI機能を使用したユーザーの割合。これは、AI機能を使用するDuoシートを持つユーザー数を、割り当てられたDuoシートの合計数で割って算出されます。
- **コード提案の使用状況**: 過去30日間にコード提案を使用した、割り当てられたDuoシートを持つユーザーの割合。これは、コード提案と対話するDuoシートを持つユニークユーザーの数を、Duoシートを持つユニークコントリビューター（`pushed`イベントを持つユーザー）の総数で割って算出されます。コード提案のメトリクスを計算するために、GitLabはコードエディタ拡張機能からのみデータを収集します。
- **Code Suggestions acceptance rate**（コード提案の承認率）: 過去30日間にコードコントリビューターによって承認されたGitLab Duoが提供するコード提案の割合。これは、承認されたコード提案の数を、生成されたコード提案の総数で割って算出されます。
- **Duo Chat usage**（Duoチャットの使用状況）: 毎月GitLab Duoチャットを利用するユーザーの割合。これは、毎月のユニークGitLab Duoチャットユーザー数を、割り当てられたGitLab Duoユーザーの合計数で割って算出されます。

## メトリクスの傾向 {#metric-trends}

**Metric trends**（Metric trends）テーブルには、過去6か月のメトリクスが、月ごとの値、過去6か月の変化率、傾向スパークラインとともに表示されます。

### Duoの使用メトリクス {#duo-usage-metrics}

{{< history >}}

- Duo RCAの利用状況は、`duo_rca_usage_rate`という名前の[機能フラグ](../../administration/feature_flags/_index.md)とともにGitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/513252)されました。デフォルトでは無効になっています。
- Duo根本原因分析の利用状況[が、GitLab 18.3でGitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/543987)になりました。
- GitLab 18.4でDuo根本原因分析が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/556726)されました。機能フラグ`duo_rca_usage_rate`は削除されました。
- GitLab 18.6でDuo機能の使用状況が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207562)されました。

{{< /history >}}

- **コード提案の使用状況**: AIコード提案の月間ユーザーエンゲージメント。

  GitLab.comでは、データは5分ごとに更新されます。GitLabは、ユーザーが当月中にプロジェクトにプッシュされたコードをプッシュした場合にのみ、コード提案の使用状況をカウントします。

  AI使用状況のユニークユーザー率を月ごとに比較することで、デベロッパーの経験レベルやプロジェクトのタイプまたは複雑さなどの要因が排除されるため、より正確なコード提案の使用状況がわかります。

  AI使用状況の傾向のベースラインは、GitLab Duoシートを持つユーザーだけでなく、コードコントリビューターの総数です。このベースラインは、チームメンバーによるAI使用状況をより正確に表しています。

  {{< alert type="note" >}}

  コード提案の使用率は、GitLab 16.11以降のデータを使用して計算されます。

  {{< /alert >}}

- **Duo RCA usage**（Duo RCAの使用状況）: Duo根本原因分析の月間ユーザーエンゲージメント。マージリクエストから失敗したCI/CDジョブの問題を解決するためにGitLab Duoチャットを使用するDuoユーザーの割合を追跡します。

  {{< alert type="note" >}}

  Duo根本原因分析の使用率は、GitLab 18.0以降のデータを使用して計算されます。

  {{< /alert >}}

- **Duo features usage**（Duo機能の使用状況）: GitLab Duo機能を使用したコントリビューターの数。

### 開発メトリクス {#development-metrics}

- [**リードタイム**](../group/value_stream_analytics/_index.md#lifecycle-metrics)
- [**マージまでの時間の中央値**](merge_request_analytics.md)
- [**デプロイ頻度**](dora_metrics.md#deployment-frequency)
- [**マージリクエストのスループット**](merge_request_analytics.md#view-the-number-of-merge-requests-in-a-date-range)
- [**経時的に発生する重大な脆弱性**](../application_security/vulnerability_report/_index.md)
- [**コントリビューター数**](../profile/contributions_calendar.md#user-contribution-events)

### パイプラインメトリクス {#pipeline-metrics}

パイプラインメトリクステーブルには、選択したプロジェクトで実行されたパイプラインのメトリクスが表示されます。

- **総パイプライン実行数**: プロジェクト内のパイプライン実行数。
- **期間の中央値**: パイプライン実行のメトリクス（分単位）。
- **成功率**: 正常に完了したパイプライン実行の割合。
- **失敗率**: 失敗して完了したパイプライン実行の割合。

## 言語別のコード提案の承認率 {#code-suggestions-acceptance-rate-by-language}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/454809)されました。

{{< /history >}}

**Code Suggestions acceptance rate by language**（言語別のコード提案の承認率） チャートには、過去30日間のプログラミング言語別に分類されたコード提案の承認率が表示されます。

各言語の承認率は、承認されたコード提案の数を、表示されたコード提案の総数で割って算出されます。

## コード量の傾向 {#code-generation-volume-trends}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/573972)されました。

{{< /history >}}

**Code generation volume trends**（コード生成量の傾向） チャートには、過去180日間にコード提案を通じて生成されたコード量が月ごとに集計されて表示されます。チャートには以下が表示されます:

- **Lines of code accepted**（承認されたコード行）: 承認されたコード提案からのコード行。
- **Lines of code shown**（表示されたコード行）: コード提案に表示されるコード行。

## GitLab DuoとSDLCの傾向を表示する {#view-gitlab-duo-and-sdlc-trends}

前提要件:

- [コード提案](../project/repository/code_suggestions/_index.md)を有効にする必要があります。
- GitLab Self-Managedの場合は、[コントリビューション分析用のClickHouse](../group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse)を設定する必要があります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **分析**>**分析ダッシュボード**を選択します。
1. **GitLab Duo and SDLC trends**（GitLab DuoとSDLCの傾向）を選択します。

GitLab DuoとSDLCのメトリクスを取得するには、`AiMetrics`、`AiUserMetrics`、`AiUsageData` [GraphQL API](../../api/graphql/duo_and_sdlc_trends.md)も使用できます。
