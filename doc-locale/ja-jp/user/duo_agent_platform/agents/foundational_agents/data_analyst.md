---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: データ分析エージェント
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.6で`foundational_analytics_agent`[機能フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578342)されました。デフォルトでは無効になっています。
- GitLab 18.7で[ベータ版](../../../../policy/development_stages_support.md#beta)に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/583940)されました。
- GitLab 18.7の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/583940)になりました。
- [正式リリース](https://gitlab.com/gitlab-org/gitlab/-/work_items/584536)されました。GitLab 18.11。

{{< /history >}}

データ分析エージェントは、GitLabプラットフォーム全体にわたるデータのクエリ、可視化、抽出を支援する特化型AIアシスタントです。[GitLab Query Language（GLQL）](../../../glql/_index.md)を使用してデータを取得および分析し、プロジェクトとグループに関する明確で実用的なインサイトを提供します。ご利用のティアで利用可能なデータソースとフィールドについては、[GLQLデータソース](../../../glql/data_sources/_index.md)を参照してください。

データ分析エージェントは、次のような場合に役立ちます:

- ボリューム分析: 一定期間におけるマージリクエスト、イシュー、その他の作業アイテムの件数をカウントする。
- チームパフォーマンス: チームメンバーが何に取り組み、どのような成果を上げているかを把握する。
- トレンド分析: 開発ワークフローにおけるパターンを特定する。
- ステータスのモニタリング: プロジェクトまたはグループ全体の作業アイテムのステータスを確認する。
- 作業アイテムの探索: 作成者、ラベル、マイルストーン、その他の条件に基づいて、イシュー、マージリクエスト、エピックを見つける。
- GLQLクエリの生成: イシュー、マージリクエスト、エピック、コメント、Wiki、スニペット、リリースなど、GitLab Flavored Markdownをサポートするあらゆる場所に埋め込めるクエリを作成する。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab Duoデータアナリストデモ](https://youtu.be/9MTT2P_t-CU)を参照してください。

フィードバックは[イシュー574028](https://gitlab.com/gitlab-org/gitlab/-/issues/574028)に投稿してください。

## 既知の問題 {#known-issues}

- エージェントはクエリしたデータに対して簡易的な集計を実行できますが、データセットが100件を超えると結果が不完全になる場合があります。
- GLQLは[特定の領域](../../../glql/data_sources/_index.md)に対するクエリをサポートしていますが、すべてのGitLabデータソースをサポートしているわけではありません。
- エージェントは、作業アイテムまたはダッシュボードに直接出力することはできません。ただし、生成されたGLQLクエリをコピーし、GitLab Flavored Markdownをサポートする任意のページに埋め込むことは可能です。

## データアナリストエージェントを使用する {#use-the-data-analyst-agent}

GitLab UI、VS Code、およびJetBrains IDEでデータアナリストエージェントを使用できます。

### GitLab UIの場合 {#in-the-gitlab-ui}

前提条件: 

- [オンにする](_index.md#turn-foundational-agents-on-or-off)基本エージェント。

GitLab UIでデータアナリストエージェントを使用するには:

1. GitLab Duoサイドバーで、**新しいチャットを追加** ({{< icon name="pencil-square" >}}) を選択します。
1. ドロップダウンリストから**データ分析**を選択します。

   画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。
1. 分析に関する質問またはリクエストを入力します。リクエストから最良の結果を得るには、次の点に留意してください:

   - データについて質問する際は、スコープ（プロジェクトまたはグループ）を指定する。
   - 時系列の分析には、期間を指定する。
   - 関心のある作業アイテムの種類を具体的に指定する。

### VS Codeで {#in-vs-code}

前提条件: 

- [オンにする](_index.md#turn-foundational-agents-on-or-off)基本エージェント。
- [GitLab for VS Code](../../../../editor_extensions/visual_studio_code/setup.md)バージョン6.57.3以降をインストールして設定します。
- [デフォルトのGitLab Duoネームスペース](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定します。

VS Codeでデータアナリストエージェントを使用するには:

1. VS Codeの左サイドバーで、**GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}) を選択します。
1. **Chat**タブを選択します。
1. **新しいチャット**（{{< icon name="duo-chat-new" >}}）ドロップダウンリストから、**データ分析**を選択します。
1. 分析に関する質問またはリクエストを入力します。リクエストから最良の結果を得るには、次の点に留意してください:

   - データについて質問する際は、スコープ（プロジェクトまたはグループ）を指定する。
   - 時系列の分析には、期間を指定する。
   - 関心のある作業アイテムの種類を具体的に指定する。

### JetBrains IDEで {#in-jetbrains-ides}

前提条件: 

- [オンにする](_index.md#turn-foundational-agents-on-or-off)基本エージェント。
- JetBrains IDE用の[GitLab Duoプラグイン](../../../../editor_extensions/jetbrains_ide/setup.md)バージョン3.24.4以降をインストールして設定します。
- [デフォルトのGitLab Duoネームスペース](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)を設定します。

まず、GitLab Duo Agent Platformを有効にします:

1. JetBrains IDEで、**Settings** > **Tools** > **GitLab Duo**に移動します。
1. **GitLab Duo Agent Platform**で、**Enable GitLab Duo Agent Platform**チェックボックスを選択します。
1. プロンプトが表示されたら、IDEを再起動します。

その後、データアナリストエージェントを使用するには:

1. JetBrains IDEの右側のツールウィンドウバーで、**GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}) を選択します。
1. **Chat**タブを選択します。
1. **新しいチャット**（{{< icon name="duo-chat-new" >}}）ドロップダウンリストから、**データ分析**を選択します。
1. 分析に関する質問またはリクエストを入力します。リクエストから最良の結果を得るには、次の点に留意してください:

   - データについて質問する際は、スコープ（プロジェクトまたはグループ）を指定する。
   - 時系列の分析には、期間を指定する。
   - 関心のある作業アイテムの種類を具体的に指定する。

## プロンプトの例 {#example-prompts}

- ボリュームとカウント:
  - 「今月マージされたマージリクエストは何件ですか？」
  - 「先週作成されたイシューの数をカウントしてください。」
  - 「現在オープンしているバグはいくつですか？」
- チームパフォーマンス: 
  - 「@ユーザー名は今月何に取り組みましたか？」
  - 「過去2週間にチームXがマージしたマージリクエストを表示してください。」
  - 「私に割り当てられているイシューのタイトルとラベルを表形式で表示してください。」
  - 「作成者別に、オープンマージリクエストを一覧表示してください。」
- ステータスとモニタリング:
  - 「`~priority::1`と`~bug`のラベルが付いた未解決のイシューを表示してください。」
  - 「期限切れのイシューを表示してください。」
  - 「レビュー待ちのマージリクエストはどれですか？」
  - 「現在のマイルストーンに含まれるイシューを一覧表示してください。」
- トレンド分析: 
  - 「過去1か月間のマージリクエストのアクティビティを表示してください。」
  - 「今四半期のバグの発生傾向はどうなっていますか？」
  - 「今月と先月のイシューのクローズ率を比較してください。」
- GLQLクエリの生成: 
  - 「私に割り当てられているオープンイシューを取得するGLQLクエリを書いてください。」
  - 「今週マージされたすべてのマージリクエストを示す表を作成してください。」
  - 「チームXのオープン中の作業アイテムを対象とした、GLQL埋め込みビューを生成してください。」
  - 「複数のラベルでフィルタリングするためのGLQL構文を教えてください。」
- 作業アイテムの探索: 
  - 「mainブランチをターゲットとするマージリクエストを一覧表示してください。」
  - 「過去24時間以内に更新されたイシューを見つけてください。」
  - 「チームXに割り当てられたオープン中のバグを表示してください。」
