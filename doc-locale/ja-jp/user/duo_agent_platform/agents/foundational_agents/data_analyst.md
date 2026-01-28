---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: データ分析エージェント
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.6で`foundational_analytics_agent`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578342)されました。デフォルトでは無効になっています。
- GitLab 18.7で[ベータ版](../../../../policy/development_stages_support.md#beta)に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/583940)されました。
- GitLab 18.7の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/583940)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

データ分析エージェントは、GitLabプラットフォーム全体にわたるデータのクエリ、可視化、抽出を支援する、専門特化したAIアシスタントです。[GitLab Query Language（GLQL）](../../../glql/_index.md)を使用してデータを取得および分析し、プロジェクトとグループに関する明確で実用的なインサイトを提供します。

データ分析エージェントは、次のような場合に役立ちます:

- ボリューム分析: 一定期間におけるマージリクエスト、イシュー、その他の作業アイテムの件数をカウントする。
- チームパフォーマンス: チームメンバーが何に取り組み、どのような成果を上げているかを把握する。
- トレンド分析: 開発ワークフローにおけるパターンを特定する。
- ステータスのモニタリング: プロジェクトまたはグループ全体の作業アイテムのステータスを確認する。
- 作業アイテムの探索: 作成者、ラベル、マイルストーン、その他の条件に基づいて、イシュー、マージリクエスト、エピックを見つける。
- GLQLクエリの生成: イシュー、マージリクエスト、エピック、コメント、Wiki、スニペット、リリースなど、GitLab Flavored Markdownをサポートするあらゆる場所に埋め込めるクエリを作成する。

<i class="fa-youtube-play" aria-hidden="true"></i> 概要については、[GitLab Duoデータ分析ベータ版リリースのデモ](https://youtu.be/9MTT2P_t-CU)をご覧ください。
<!-- Video published on 2025-12-15 -->

フィードバックは[イシュー574028](https://gitlab.com/gitlab-org/gitlab/-/issues/574028)に投稿してください。

## 既知の問題 {#known-issues}

- エージェントはクエリしたデータに対して簡易的な集計を実行できますが、データセットが100件を超えると結果が不完全になる場合があります。
- GLQLは[特定の領域](../../../glql/_index.md#supported-areas)に対するクエリをサポートしていますが、すべてのGitLabデータソースをサポートしているわけではありません。
- エージェントは、作業アイテムまたはダッシュボードに直接出力することはできません。ただし、生成されたGLQLクエリをコピーし、GitLab Flavored Markdownをサポートする任意のページに埋め込むことは可能です。

## データ分析エージェントにアクセスする {#access-the-data-analyst-agent}

前提条件: 

- 基本エージェントを[オン](_index.md#turn-foundational-agents-on-or-off)にする必要があります。

1. GitLab Duo Chatを開きます:

   GitLab Duoのサイドバーで、**新しいGitLab Duo Chat**（{{< icon name="pencil-square" >}}）または**現在のGitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択します。

   画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。

1. **新しいチャット**（{{< icon name="duo-chat-new" >}}）ドロップダウンリストから、**データアナリスト**を選択します。
1. 分析に関する質問またはリクエストを入力します。リクエストから最良の結果を得るには、次の点に留意してください:

   - データについて質問する際は、スコープ（プロジェクトまたはグループ）を指定する。
   - 時系列の分析には、期間を指定する。
   - 関心のある作業アイテムの種類を具体的に指定する。

## プロンプトの例 {#example-prompts}

- ボリュームとカウント:
  - `How many merge requests were merged this month?`
  - `Count the issues created last week.`
  - `How many bugs are currently open?`
- チームパフォーマンス: 
  - `What has @username worked on this month?`
  - `Show me merge requests merged by team X in the last two weeks.`
  - `Show me a table of issues with titles and labels assigned to me.`
  - `List open merge requests by author.`
- ステータスとモニタリング:
  - `Show me open issues with ~priority::1 and ~bug labels.`
  - `Show me overdue issues.`
  - `What merge requests are waiting for review?`
  - `List issues in the current milestone.`
- トレンド分析: 
  - `Show me the merge request activity over the last month.`
  - `What's the trend of bug creation this quarter?`
  - `Compare issue closure rates between this month and last month.`
- GLQLクエリの生成: 
  - `Write a GLQL query for open issues assigned to me.`
  - `Create a table showing all merge requests merged this week.`
  - `Generate a GLQL embedded view for team X's open work.`
  - `What's the GLQL syntax for filtering by multiple labels?`
- 作業アイテムの探索: 
  - `List merge requests targeting the main branch.`
  - `Find issues updated in the last 24 hours.`
  - `Show me open bugs assigned to team X.`
