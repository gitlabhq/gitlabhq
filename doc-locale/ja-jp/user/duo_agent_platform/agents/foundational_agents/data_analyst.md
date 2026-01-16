---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: データアナリストエージェント
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578342)されました。[という](../../../../administration/feature_flags/_index.md)FFは`foundational_analytics_agent`です。デフォルトでは無効になっています。
- GitLab 18.7で[ベータ版](https://gitlab.com/gitlab-org/gitlab/-/issues/583940)に[変更](../../../../policy/development_stages_support.md#beta)されました。
- GitLab 18.7の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/583940)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

データアナリストエージェントは、GitLabプラットフォーム全体のデータをクエリし、可視化し、表面化するのに役立つ、特殊なAIアシスタントです。データ取得と分析には[GitLab Query Language（GLQL）](../../../glql/_index.md)を使用し、プロジェクトとグループに関する明確で実用的なインサイトを提供します。

データアナリストエージェントは、次のような場合に役立ちます:

- ボリューム分析: 一定期間にわたるマージリクエスト、イシュー、またはその他の作業アイテムのカウント。
- チームのパフォーマンス: チームメンバーが何に取り組み、どのような出力を行っているかを把握する。
- トレンド分析: 開発ワークフローのパターンを特定する。
- ステータスのモニタリング: プロジェクトまたはグループ全体の作業アイテムの状態をチェックする。
- 作業アイテムの検出: 作成者、ラベル、マイルストーン、またはその他の条件でイシュー、マージリクエスト、またはエピックを見つける。
- GLQLクエリの生成: イシュー、マージリクエスト、エピック、コメント、Wiki、スニペット、リリースなど、GitLab Flavored Markdownをサポートする任意の場所に埋め込むクエリを作成します。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab Duoデータアナリストベータリリースのデモ](https://youtu.be/9MTT2P_t-CU)をご覧ください。
<!-- Video published on 2025-12-15 -->

[イシュー574028](https://gitlab.com/gitlab-org/gitlab/-/issues/574028)でフィードバックをお寄せください。

## 既知の問題 {#known-issues}

- エージェントはクエリされたデータに対して軽い集計を実行できますが、データセットが100件を超えると結果が不完全になる場合があります。
- GLQLは[特定の領域](../../../glql/_index.md#supported-areas)のクエリをサポートしていますが、すべてのGitLabデータソースをサポートしているわけではありません。
- エージェントは、作業アイテムまたはダッシュボードに直接出力できません。ただし、生成されたGLQLクエリをコピーして、GitLab Flavored Markdownをサポートする任意のページに埋め込むことができます。

## データアナリストエージェントにアクセス {#access-the-data-analyst-agent}

前提条件: 

- ファウンデーショナルエージェントは[オン](_index.md#turn-foundational-agents-on-or-off)にする必要があります。

1. GitLab Duo Chatを開きます:

   GitLab Duoサイドバーで、**新しいGitLab Duo Chat**（{{< icon name="pencil-square" >}}）または**現在のGitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択します。

   チャットでの会話が、画面右側のGitLab Duoサイドバーに表示されます。

1. **新しいチャット**（{{< icon name="duo-chat-new" >}}）ドロップダウンリストから、**データアナリスト**を選択します。
1. 分析に関する質問またはリクエストを入力します。リクエストから最良の結果を得るには:

   - データについて質問する場合は、スコープ（プロジェクトまたはグループ）を指定します。
   - 時間ベースの分析には、時間範囲を含めます。
   - 関心のある作業アイテムの種類を具体的に指定します。

## プロンプトの例 {#example-prompts}

- ボリュームとカウント:
  - 「今月はいくつのマージリクエストがマージされましたか?」
  - 「先週作成されたイシューを数えてください。」
  - 「現在オープンになっているバグの数は?」
- チームのパフォーマンス: 
  - 「@ユーザー名は今月何に取り組みましたか?」
  - 「過去2週間にチームXによってマージされたマージリクエストを表示してください。」
  - 「タイトルとラベルが割り当てられたイシューの表を表示してください。」
  - 「作成者別にオープンなマージリクエストをリスト表示します。」
- ステータスとモニタリング:
  - 「`~priority::1`および`~bug`ラベルの付いたオープンイシューを表示してください。」
  - 「期限切れのイシューを表示します。」
  - 「レビュー待ちのマージリクエストは何ですか?」
  - 「現在のマイルストーンにあるイシューをリスト表示します。」
- トレンド分析: 
  - 「過去1か月のマージリクエストアクティビティーを表示してください。」
  - 「今四半期のバグ作成の傾向は何ですか?」
  - 「今月と先月のイシューのクローズ率を比較してください。」
- GLQLクエリの生成: 
  - 「自分に割り当てられたオープンなイシューのGLQLクエリを記述します。」
  - 「今週マージされたすべてのマージリクエストを示すテーブルを作成します。」
  - 「チームXのオープンな作業のためのGLQL埋め込みビューを生成します。」
  - 「複数のラベルでフィルタリングするためのGLQL構文は何ですか?」
- 作業アイテムの検出: 
  - 「mainブランチをターゲットとするマージリクエストをリスト表示します。」
  - 「過去24時間以内に更新されたイシューを見つけます。」
  - 「チームXに割り当てられたオープンなバグを表示します。」
