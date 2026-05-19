---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab DuoとSDLCのトレンド
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: GitLab Self-Managedにおいてベータ版

{{< /details >}}

{{< history >}}

- GitLab 16.11で`ai_impact_analytics_dashboard`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/443696)されました。デフォルトでは無効になっています。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/451873)になりました。機能フラグ`ai_impact_analytics_dashboard`は削除されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- 18.2でGitLab UltimateからGitLab Premiumに移行しました。
- GitLab 18.2.1でAmazon Qのサポートに変更されました。
- GitLab 18.4でパイプラインメトリクスの表が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/550356)されました。
- GitLab 18.4で`AI impact analytics`から`GitLab Duo and SDLC trends`に名前が変更されました。
- GitLab 18.7でアドオンが不要になりました。

{{< /history >}}

この機能は、GitLab Self-Managedにおいてベータ版です。詳細については、[エピック51](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/epics/51)を参照してください。

GitLab DuoとSDLCのトレンドは、ソフトウェア開発ライフサイクル（SDLC）のパフォーマンスに対するGitLab Duoの影響を測定します。このダッシュボードは、AIの採用というコンテキストにおいて、プロジェクトまたはグループの主要なSDLCメトリクスを可視化します。このダッシュボードを使用すると、AIへの投資によってどのメトリクスが改善したかを測定できます。

GitLab DuoとSDLCのトレンドを使用して、次のことを行えます:

- GitLab Duoの導入過程におけるSDLCトレンドの追跡: プロジェクトまたはグループにおけるGitLab Duoの使用トレンドが、マージまでの平均時間やCI/CDの統計など、他の重要な生産性メトリクスにどのように影響しているかを確認できます。GitLab Duoの使用状況メトリクスは、当月を含む過去6か月間分が表示されます。
- GitLab Duo機能の導入状況の監視: 過去30日間におけるプロジェクトまたはグループでのシートおよび機能の使用状況を追跡します。

ライセンスの使用状況を最適化する方法については、[GitLab Duoアドオン](../../subscriptions/subscription-add-ons.md)を参照してください。

GitLab DuoとSDLCのトレンドの詳細については、ブログ記事[Developing GitLab Duo: AI impact analytics dashboard measures the ROI of AI](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/)を参照してください。

クリックスルーデモについては、[GitLab DuoおよびSDLCのトレンドの製品ツアー](https://gitlab.navattic.com/ai-impact)をご覧ください。

<i class="fa-youtube-play" aria-hidden="true"></i> 概要については、[GitLab Duo AIインパクトダッシュボードに関する動画](https://youtu.be/FxSWX64aUOE?si=7Yfc6xHm63c3BRwn)を参照してください。
<!-- Video published on 2025-03-06 -->

## 主要メトリクス {#key-metrics}

{{< history >}}

- GitLab Duo Chatのメトリクスは、GitLab 18.10で[GitLab Duo Agentic Chat sessions](https://gitlab.com/gitlab-org/gitlab/-/issues/587301)にGitLab Duo Agentic Chatセッションに置き換えられました。
- 割り当てられたGitLab Duoのシートエンゲージメントメトリクスは、GitLab 18.10で[置き換えられました](https://gitlab.com/gitlab-org/gitlab/-/work_items/587298)。
- GitLab Duoのコード提案利用メトリクスは、GitLab 18.10で[割合](https://gitlab.com/gitlab-org/gitlab/-/work_items/592813)から絶対ユーザー数に変更されました。
- コード提案の採用率メトリクスは、GitLab 18.11で[GitLab Duoエージェント/フローユーザー](https://gitlab.com/gitlab-org/gitlab/-/work_items/587300)に置き換えられました。

{{< /history >}}

- **GitLab Duo users**: 過去30日間に少なくとも1つのGitLab DuoまたはGitLab Duo Agent Platform機能を使用したユーザー数。
- **コード提案のユーザー**: 過去30日間にコード提案を使用したユーザー数。コード提案のメトリクス算出にあたって、GitLabはコードエディタの拡張機能からのみデータを収集します。
- **GitLab Duo agent/flow users**: 過去30日間に少なくとも1つのGitLab Duoエージェントまたはフローを使用したユーザー数。
- **GitLab Duo Agent chat sessions**: 過去30日間にGitLab Duo Agent Platformで開始されたチャットセッションの数。

## メトリクスのトレンド {#metric-trends}

**メトリクスのトレンド**テーブルには、過去6か月間のメトリクスが表示され、月次の値、過去6か月間の変化率、トレンドを示すスパークラインも示されます。

変更の割合は、利用可能な統計の最初の完全な月と、当月を除いた最後の完了した月を比較したものです。

緑色の値はプラスの変化を、赤色の値はマイナスの変化を示します。値の横にあるアイコンは、上昇傾向{{< icon name="trend-up" >}}または下降傾向{{< icon name="trend-down" >}}を示します。

上昇傾向は一部のメトリクス（[デプロイ頻度](dora_metrics.md#deployment-frequency)など）ではポジティブ（緑）ですが、その他のメトリクス（[マージまでの平均時間](merge_request_analytics.md)など）ではネガティブ（赤）です。

### GitLab Duoの使用状況メトリクス {#gitlab-duo-usage-metrics}

{{< history >}}

- GitLab Duo根本原因分析の使用は、GitLab 18.1で、`duo_rca_usage_rate`という名前の[フラグとともに](../../administration/feature_flags/_index.md) [導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/513252)。デフォルトでは無効になっています。
- GitLab Duo根本原因分析の使用は、GitLab 18.3で[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/543987)になりました。
- GitLab Duo根本原因分析の使用は、GitLab 18.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/556726)されました。機能フラグ`duo_rca_usage_rate`は削除されました。
- GitLab Duo機能の使用は、GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207562)されました。
- GitLab Duoのコードレビューリクエストとコメントは、GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/573979)されました。
- GitLab Duo GitLab Duo Agent Platformのチャットとフローは、GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/583375)されました。
- GitLab Duoコード提案、非Agentic Chat、および根本原因分析のメトリクスは、GitLab 18.10で[割合](https://gitlab.com/gitlab-org/gitlab/-/issues/589605)から絶対ユーザー数に変更されました。

{{< /history >}}

- **機能の使用状況**: 少なくとも1つのGitLab DuoまたはGitLab Duo Agent Platform機能を使用したユーザー数。
- **Agent Platformチャット**: GitLab Duo Agent Platformを通じて開始されたチャットセッションの数。
- **Agent Platformフロー**: GitLab Duo Agent Platformを通じて実行された（チャットを除く）エージェントフローの数。
- **Non-Agentic Chat usage**: 非Agentic Chatを使用したユーザー数。
- **根本原因分析の使用量**: 根本原因分析を使用したユーザー数。
- **コードレビューリクエスト**: マージリクエストで作成されたコードレビューリクエストの数。これには、マージリクエストの作成者と作成者以外の両方によって開始されたリクエストが含まれます。
- **コードレビューコメント**: マージリクエストのマージリクエストの差分に投稿されたコードレビューコメントの数。
- **コード提案の使用状況**: コード提案を使用したユーザー数。GitLab.comでは、データは5分ごとに更新されます。GitLabでは、ユーザーが当月にコードをプロジェクトにプッシュした場合にのみ、コード提案の使用状況がカウントされます。
- **コード提案の受け入れ率**: GitLab Duoが提供したコード提案のうち、コントリビューターによって採用されたものの割合。

### 開発メトリクス {#development-metrics}

- [**リードタイム**](../group/value_stream_analytics/_index.md#lifecycle-metrics)
- [**マージまでの時間の中央値**](merge_request_analytics.md)
- [**デプロイ頻度**](dora_metrics.md#deployment-frequency)
- [**マージリクエストのスループット**](merge_request_analytics.md#view-the-number-of-merge-requests-in-a-date-range)
- [**重大な脆弱性の推移**](../application_security/vulnerability_report/_index.md)
- [**コントリビューター数**](../profile/contributions_calendar.md#user-contribution-events)

### パイプラインメトリクス {#pipeline-metrics}

パイプラインメトリクステーブルには、選択したプロジェクトで実行されたパイプラインのメトリクスが表示されます。

- **総パイプライン実行数**: プロジェクト内で実行されたパイプラインの数。
- **期間の中央値**: パイプライン実行期間の中央値（分）。
- **成功率**: 正常に完了したパイプライン実行の割合。
- **失敗率**: 失敗して完了したパイプライン実行の割合。

## 言語別のGitLab Duoコード提案の採用状況 {#gitlab-duo-code-suggestions-acceptance-by-language}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/454809)されました。

{{< /history >}}

**言語別のGitLab Duoコード提案の採用状況**チャートには、過去30日間におけるプログラミング言語別のコード提案の採用数が表示されます。

バーにカーソルを合わせると、各言語について次の項目を確認できます:

- **受け入れた提案**: ユーザーが採用した提案の数。
- **表示された提案**: ユーザーに表示された提案の数。
- **採用率**: 採用された提案の割合。採用されたコード提案数を、表示されたコード提案の総数で割って算出されます。

## IDE別のGitLab Duoコード提案の採用状況 {#gitlab-duo-code-suggestions-acceptance-by-ide}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/550064)されました。

{{< /history >}}

**IDE別のGitLab Duoコード提案の採用状況**チャートには、過去30日間におけるIDE別のコード提案の採用数が表示されます。

バーにカーソルを合わせると、各IDEについて次の項目を確認できます:

- **受け入れた提案**: ユーザーが採用した提案の数。
- **表示された提案**: ユーザーに表示された提案の数。
- **採用率**: 採用された提案の割合。採用されたコード提案数を、表示されたコード提案の総数で割って算出されます。

## コード生成量のトレンド {#code-generation-volume-trends}

{{< history >}}

- GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/573972)されました。

{{< /history >}}

**コード生成量のトレンド**チャートには、過去180日間のコード提案を通じて生成されたコードの量が月次で集計されて表示されます。チャートには次の項目が表示されます:

- **受け入れたコード行数**: コード提案によって生成され、採用されたコードの行数。
- **表示されたコード行数**: コード提案で表示されたコードの行数。

## ロール別のGitLab Duoコードレビューリクエスト数 {#gitlab-duo-code-review-requests-by-role}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/574003)されました。

{{< /history >}}

**GitLab Duo Code Review requests by role**チャートには、過去180日間のコードレビューリクエストの数が月ごとに集計されて表示されます。チャートには次の項目が表示されます:

- **作成者によるレビューリクエスト数**: マージリクエストの作成者によって行われたコードレビューリクエストの数。これには、プロジェクト設定を通じて自動的にリクエストされたコードレビューと、作成者がマージリクエスト内で手動でリクエストしたコードレビューが含まれます。
- **作成者以外によるレビューリクエスト数**: マージリクエストの作成者以外のユーザーによって行われたコードレビューリクエストの数。たとえば、レビュアーがGitLab Duoに対してマージリクエストの変更内容をレビューするよう依頼した場合が該当します。

作成者による利用数が多いほど、チームが自動化されたレビューワークフローを積極的に取り入れていることを示しています。

## GitLab Duoコードレビューコメントのセンチメント {#gitlab-duo-code-review-comments-sentiment}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/574005)されました。

{{< /history >}}

**GitLab Duo Code Review comments sentiment**チャートは、過去180日間のコードレビューコメントのセンチメントを、ポジティブ (👍) およびネガティブ (👎) のリアクション率で表示します。チャートには次の項目が表示されます:

- **承認率**: ポジティブ (👍) なリアクションを受け取ったコードレビューコメントの割合。
- **不承認率**: ネガティブ (👎) なリアクションを受け取ったコードレビューコメントの割合。

分析結果を解釈する際は、次の点に注意してください:

- ネガティビティバイアスが生じることが予想されます。ユーザーは問題を指摘する傾向がありますが、提案を採用する場合でも、良い提案に対してリアクションを付けることはめったにありません。
- リアクション率が低いのが一般的です。コードの品質が向上しているか、レビューがより迅速に完了しているかに注目してください。
- 不承認（👎）率の上昇は問題の兆候です。不承認率が安定または低下している場合は、GitLab Duoコードレビューが健全に導入されていることを示しています。

## ユーザー別のGitLab Duoメトリクス {#gitlab-duo-metrics-by-user}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/574420)されました。

{{< /history >}}

ユーザーメトリクステーブルには、過去30日間にわたるさまざまなGitLab Duo機能の使用状況がユーザーごとに表示されます。

- **ユーザー別のGitLab Duoコード提案の使用状況**: 採用されたコード提案の数と、コード提案の採用率。
- **ユーザー別のGitLab Duoコードレビューの使用状況**: マージリクエストの作成者としてGitLab Duoにリクエストしたコードレビューの数、およびコードレビューコメントに対するリアクション（:thumbsup:と:thumbsdown:）の数。
- **ユーザー別のGitLab Duo根本原因分析の使用状況**: GitLab Duoによるトラブルシューティングリクエストの数。
- **ユーザー別のGitLab Duo使用状況**: ユーザーが行ったGitLab Duoイベントの数。

## GitLab DuoとSDLCのトレンドを表示する {#view-gitlab-duo-and-sdlc-trends}

前提条件: 

- グループに対するレポーターロール以上が必要です。
- このグループはトップレベルグループである必要があります。
- GitLab Duoコード提案が有効になっている必要があります。
- GitLab Self-Managedの場合、[コントリビュート分析用のClickHouse](../group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse)を設定する必要があります。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **分析** > **分析ダッシュボード**を選択します。
1. **GitLab DuoとSDLCのトレンド**を選択します。

GitLab DuoとSDLCのメトリクスは、`AiMetrics`、`AiUserMetrics`、`AiUsageData`の[GraphQL API](../../api/graphql/duo_and_sdlc_trends.md)を使用して取得することもできます。

## メトリクスデータの利用可否 {#metric-data-availability}

次の表は、GitLab Duoの各メトリクスについて、使用状況データの算出が開始されたGitLabのバージョンを示しています:

| GitLab Duoのメトリクス | データ算出の開始 |
|--------|------------------------------|
| コード提案の使用状況 | GitLab 16.11 |
| 根本原因分析の使用状況 | GitLab 18.0 |
| コードレビューのリクエストとコメント | GitLab 18.3 |
| Agent Platformのチャットとフロー | GitLab 18.7 |
