---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab DuoとSDLCの傾向
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: GitLab Self-Managedのベータ版

{{< /details >}}

{{< history >}}

- GitLab 16.11で`ai_impact_analytics_dashboard`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443696)されました。デフォルトでは無効になっています。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/451873)になりました。機能フラグ`ai_impact_analytics_dashboard`は削除されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- 18.2でGitLab UltimateからGitLab Premiumに移行しました。
- GitLab 18.2.1でAmazon Qのサポートが追加されました。
- パイプラインメトリクスの表がGitLab 18.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/550356)されました。
- GitLab 18.4で、`AI impact analytics`から`GitLab Duo and SDLC trends`に名称が変更されました。
- GitLab 18.7では、アドオンは不要になりました。

{{< /history >}}

この機能は、GitLab Self-Managedのベータ版です。詳細については、[エピック51](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/epics/51)を参照してください。

GitLab DuoとSDLCの傾向は、ソフトウェア開発ライフサイクル（SDLC）のパフォーマンスに対するGitLab Duoの影響を測定します。このダッシュボードは、プロジェクトまたはグループに対するAIの採用というコンテキストにおいて、主要なSDLCメトリクスの可視性を提供します。このダッシュボードを使用すると、AI投資によってどのメトリクスが改善されたかを測定できます。

GitLab DuoとSDLCの傾向を使用して、以下を行います:

- GitLab Duoの過程に関連するSDLCの傾向を追跡します: プロジェクトまたはグループでのGitLab Duoの使用傾向が、マージまでの時間の中央値やCI/CDの統計などの他の重要な生産性メトリクスにどのように影響するかを調べます。GitLab Duoの使用メトリクスは、現在の月を含む過去6か月間表示されます。
- GitLab Duoの機能採用を監視します: 過去30日間のプロジェクトまたはグループでのシートと機能の使用状況を追跡します。

ライセンスの使用率を最適化する方法については、[GitLab Duoアドオン](../../subscriptions/subscription-add-ons.md)を参照してください。

GitLab DuoとSDLCの傾向の詳細については、ブログ記事[Developing GitLab Duo: AI impact analytics dashboard measures the ROI of AI](https://about.gitlab.com/blog/2024/05/15/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/)を参照してください。

クリックスルーデモについては、[GitLab DuoとSDLCの傾向の製品ツアー](https://gitlab.navattic.com/ai-impact)をご覧ください。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab Duo AIインパクトダッシュボード](https://youtu.be/FxSWX64aUOE?si=7Yfc6xHm63c3BRwn)を参照してください。
<!-- Video published on 2025-03-06 -->

## 主要メトリクス {#key-metrics}

- **アサインしたDuoシートの取り決め**: 過去30日間にGitLab Duoシートが割り当てられ、少なくとも1つのAI機能を使用したユーザーの割合。AI機能を使用するGitLab Duoシートを持つユーザー数を、割り当てられたGitLab Duoシートの総数で割ったものとして計算されます。
- **コード提案の使用状況**: 割り当てられたGitLab Duoシートを持つユーザーのうち、過去30日間にコード提案を使用したユーザーの割合。コード提案とやり取りするGitLab Duoシートを持つユニークユーザー数を、GitLab Duoシートを持つユニークコードコントリビューター（`pushed`イベントを持つユーザー）の総数で割ったものとして計算されます。コード提案のメトリクスを計算するために、GitLabはエディタの拡張機能からのみデータを収集します。
- **コード提案の受け入れ率**: 過去30日間にコードコントリビューターによって受け入れられたGitLab Duoによって提供されるコード提案の割合。受け入れられたコード提案の数を、生成されたコード提案の総数で割ったものとして計算されます。
- **Duo Chat使用状況**: GitLab Duo Chatを毎月利用するユーザーの割合。月次のGitLab Duo Chatのユニークユーザー数を、GitLab Duoが割り当てられている総ユーザー数で割って計算されます。

## メトリックの傾向 {#metric-trends}

**Metric trends**テーブルには、過去6か月間のメトリックが、月ごとの値、過去6か月間の変化率、傾向スパークラインとともに表示されます。

### GitLab Duoの使用メトリクス {#gitlab-duo-usage-metrics}

{{< history >}}

- GitLab 18.1でDuo RCAの使用状況が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/513252)されました。`duo_rca_usage_rate`という名前の[フラグ付き](../../administration/feature_flags/_index.md)。デフォルトでは無効になっています。
- GitLab 18.3でDuo RCAの使用状況が[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/543987)になりました。
- GitLab 18.4でDuo RCAの使用状況が[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/556726)されました。機能フラグ`duo_rca_usage_rate`は削除されました。
- GitLab 18.6でDuo機能の使用状況が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207562)されました。
- GitLab 18.7でDuoコードレビューリクエストとGitLab Duo Duoコードレビューコメントが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/573979)されました。
- GitLab 18.7でDuo Agent Platformのチャットとフローが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/583375)されました。

{{< /history >}}

- **コード提案の使用状況**: AIコード提案による月ごとのユーザーエンゲージメント。

  GitLab.comでは、データは5分ごとに更新されます。GitLabでは、ユーザーが当月中にプロジェクトにプッシュした場合にのみ、コード提案の使用状況がカウントされます。

  AI使用状況のユニークユーザー率の月ごとの比較により、DevExレベルやプロジェクトのタイプまたは複雑さなどの要因が排除されるため、コード提案の使用状況をより正確に示すことができます。

  AI使用傾向のベースラインは、GitLab Duoシートを持つユーザーだけでなく、コードコントリビューターの総数です。このベースラインにより、チームメンバーによるAIの使用状況をより正確に把握できます。

- **Duo RCA使用状況**: GitLab Duoの根本原因分析による月ごとのユーザーエンゲージメント。マージリクエストを起点として、失敗したCI/CDジョブのトラブルシューティングにGitLab Duo Chatを使用したGitLab Duoユーザーの割合を追跡します。

- **Duo機能の利用状況**: GitLab Duo機能を使用したコントリビューターの数。

- **Duoコードレビューリクエスト**: マージリクエストに対して行われたGitLab Duoコードレビューリクエストの数。これには、マージリクエストの作成者と作成者以外の両方によって開始されたリクエストが含まれます。

- **Duoコードレビューコメント**: マージリクエストの差分にGitLab Duoコードレビューによって投稿されたコメントの数。

- **Duo Agent Platformチャット**: GitLab Duo Agent Platformを介して開始されたチャットセッションの数。

- **Duo Agent Platformフロー**: GitLab Duo Agent Platformを介して実行された（チャットを除く）エージェントフローの数。

### 開発メトリクス {#development-metrics}

- [**リードタイム**](../group/value_stream_analytics/_index.md#lifecycle-metrics)
- [**マージまでの時間の中央値**](merge_request_analytics.md)
- [**デプロイ頻度**](dora_metrics.md#deployment-frequency)
- [**マージリクエストのスループット**](merge_request_analytics.md#view-the-number-of-merge-requests-in-a-date-range)
- [**経時的に発生する重大な脆弱性**](../application_security/vulnerability_report/_index.md)
- [**コントリビューター数**](../profile/contributions_calendar.md#user-contribution-events)

### パイプラインメトリクス {#pipeline-metrics}

パイプラインメトリクスの表には、選択したプロジェクトで実行されたパイプラインのメトリクスが表示されます。

- **総パイプライン実行数**: プロジェクト内のパイプライン実行数。
- **期間の中央値**: パイプライン実行バージョンの期間の中央値（分単位）。
- **成功率**: 正常に完了したパイプライン実行の割合。
- **失敗率**: 失敗して完了したパイプライン実行の割合。

## 言語別のGitLab Duoコードコード提案の承認 {#gitlab-duo-code-suggestions-acceptance-by-language}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/454809)されました。

{{< /history >}}

**GitLab Duo Code Suggestions acceptance by language**チャートには、過去30日間のプログラミング言語で承認されたコード提案の数が表示されます。

各言語の表示については、バーにカーソルを合わせる:

- **Suggestions accepted**: ユーザーが受け入れた提案の数。
- **Suggestions shown**: ユーザーに表示された提案の数。
- **Acceptance rate**: 受け入れられた提案の割合。表示されたコード提案の総数で割ったコード提案数として計算されます。

## IDE別のGitLab Duoコード提案の承認 {#gitlab-duo-code-suggestions-acceptance-by-ide}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/550064)されました。

{{< /history >}}

**GitLab Duo Code Suggestions acceptance by IDE**チャートには、過去30日間のIDEで承認されたコード提案の数が表示されます。

各IDEの表示については、バーにカーソルを合わせる:

- **Suggestions accepted**: ユーザーが受け入れた提案の数。
- **Suggestions shown**: ユーザーに表示された提案の数。
- **Acceptance rate**: 受け入れられた提案の割合。表示されたコード提案の総数で割ったコード提案数として計算されます。

## コード生成量トレンド {#code-generation-volume-trends}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/573972)されました。

{{< /history >}}

**Code generation volume trends**チャートには、過去180日間のコード提案を通じて生成されたコードの量が、月ごとに集計されて表示されます。チャートに表示される内容:

- **受け入れたコード行数**: 受け入れられたコード提案からのコード行。
- **表示されたコード行数**: コード提案に表示されるコード行。

## ロール別のGitLab Duoコードレビューリクエスト {#gitlab-duo-code-review-requests-by-role}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/574003)されました。

{{< /history >}}

**GitLab Duo Code Review requests by role**チャートには、過去180日間のGitLab Duoコードレビューリクエスト数が、月ごとに集計されて表示されます。チャートに表示される内容:

- **Review requests by authors**: マージリクエストの作成者によって作成されたGitLab Duoコードレビューリクエストの数。これには、プロジェクト設定を通じて自動的にリクエストされたコードレビューと、作成者によってマージリクエストで手動でリクエストされたコードレビューが含まれます。
- **Review requests by non-authors**: マージリクエストの作成者以外のユーザーによって作成されたGitLab Duoコードレビューリクエストの数。たとえば、マージリクエストの変更をレビューするようにGitLab Duoに依頼するレビュアー。

作成者の採用率が高いほど、自動化されたレビューのワークフローを受け入れているチームであることを示しています。

## GitLab Duoコードレビューコメントのセンチメント {#gitlab-duo-code-review-comments-sentiment}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/574005)。

{{< /history >}}

**GitLab Duo Code Review comments sentiment**チャートには、過去180日間のGitLab Duoコードレビューコメントの感情が、肯定的な（👍）および否定的な（👎）リアクション率で測定されて表示されます。チャートに表示される内容:

- **Approval rate**: 肯定的な（👍）リアクションを受けたGitLab Duoコードレビューコメントの割合。
- **Disapproval rate**: 否定的な（👎）リアクションを受けたGitLab Duoコードレビューコメントの割合。

分析を解釈する際には、次の点に注意してください:

- ネガティブバイアスが予想されます。ユーザーは問題にフラグを立てる傾向がありますが、適用する場合でも、良い提案を認識することはめったにありません。
- リアクション率が低いのが一般的です。コードが改善され、レビューがより迅速に完了するかどうかに焦点を当てます。
- 不承認（👎）率の上昇は問題を示しています。安定または低下する不承認率は、GitLab Duoコードレビューが正常に採用されていることを示しています。

## ユーザー別のGitLab Duoメトリクス {#gitlab-duo-metrics-by-user}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/574420)されました。

{{< /history >}}

ユーザーメトリクスの表には、過去30日間の個々のユーザーによるさまざまなGitLab Duo機能の使用状況が表示されます。

- **GitLab Duo Code Suggestions usage by user**: 受け入れられたコード提案の数と、コード提案の承認率。
- **GitLab Duo Code Review usage by user**: GitLab Duoからのマージリクエストの作成者としてリクエストされたコードレビューの数と、コードレビューコメントに対するリアクション（:thumbsup:と:thumbsdown:）の数。
- **GitLab Duo Root Cause Analysis usage by user**: GitLab Duoからのトラブルシューティングのリクエストの数。
- **GitLab Duo usage by user**: ユーザーによって作成されたDuoイベントの数。

## GitLab DuoとSDLCの傾向を表示 {#view-gitlab-duo-and-sdlc-trends}

前提条件: 

- [コード補完](../project/repository/code_suggestions/_index.md)を有効にする必要があります。
- GitLab Self-Managedの場合、[コントリビューション分析用のClickHouse](../group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse)を構成する必要があります。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **分析** > **分析ダッシュボード**を選択します。
1. **GitLab Duo and SDLC trends**を選択します。

GitLab DuoとSDLCのメトリクスを取得するには、`AiMetrics`、`AiUserMetrics`、および`AiUsageData` [GraphQL API](../../api/graphql/duo_and_sdlc_trends.md)を使用することもできます。

## メトリクスデータ利用可否 {#metric-data-availability}

次の表は、GitLab Duoのメトリクスの使用状況データ計算が開始されたGitLabのバージョンを示しています:

| GitLab Duoのメトリクス | データ計算の開始 |
|--------|------------------------------|
| コード提案使用率 | GitLab 16.11 |
| 根本原因分析の使用状況 | GitLab 18.0 |
| コードレビューのリクエストとコメント | GitLab 18.3 |
| エージェントプラットフォームのチャットとフロー | GitLab 18.7 |
