---
stage: AI-powered
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI Expert Agent
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

この機能は[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/587460)され、[ベータ](../../../../policy/development_stages_support.md#beta)版として[機能フラグ](../../../../administration/feature_flags/_index.md) `foundational_pipeline_authoring_agent`の名前でリリースされました。デフォルトでは無効になっています。
- GitLab 19.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/588564)開始。機能フラグ`foundational_pipeline_authoring_agent`は削除されました。

{{< /history >}}

CI Expertエージェントは、GitLab CI/CDパイプラインの作成、デバッグ、最適化を支援する専門のエージェントです。組み合わせる要素:

- GitLab CI/CDの構文と設定に関する深い専門知識。
- パイプライン最適化戦略とベストプラクティスに関する知識。

次のヘルプが必要な場合は、CI Expertエージェントを使用します:

- パイプライン作成: プロジェクト要件に基づいて、`.gitlab-ci.yml`設定をゼロから生成します。
- コンポーネントの提案: プロジェクトタイプに基づいて、CI/CDコンポーネントの推奨事項を取得します。例えば、Node.js、Python、Go、Ruby、またはDockerプロジェクトなど。
- 構文の説明: CI/CDキーワードと設定オプションを理解します。
- デバッグ: ジョブログを分析し、パイプラインの失敗のトラブルシューティングを行います。
- 最適化: パイプラインのパフォーマンスを、キャッシュ、並列化、および`needs`キーワードを使用してジョブを早めに開始させることで改善します。
- CI/CDキーワード（`rules`、`artifacts`、`services`、`environments`など）の適切な使用を実装します。

## CI Expertエージェントにアクセスする {#access-the-ci-expert-agent}

前提条件: 

- 基本エージェントを[オン](_index.md#turn-foundational-agents-on-or-off)にする必要があります。

CI Expertエージェントにアクセスするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. GitLab Duoサイドバーで、**新しいチャットを追加**（{{< icon name="pencil-square" >}}）を選択します。
1. ドロップダウンリストから、**CI Expert**を選択します。

   画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。
1. CI/CD関連の質問またはリクエストを入力します。リクエストから最良の結果を得るには、次の点に留意してください:

   - プロジェクトタイプと技術スタックを説明します。
   - 既存の`.gitlab-ci.yml`があれば共有します。
   - 目標を指定します。例えば、高速なビルド、Kubernetesへのデプロイ、または並列でのテスト実行など。

### プロンプトの例 {#example-prompts}

- 「テストとDockerビルドを含むNode.jsプロジェクト用のCI/CDパイプラインを作成してください。」
- 「私のパイプラインはなぜ失敗しているのですか？エラーは次のとおりです: （エラーメッセージを貼り付け）」
- 「ビルドを高速化するために、依存関係をキャッシュするにはどうすればよいですか？」
- 「Kubernetes用のパイプラインにデプロイメントステージを追加してください。」
- 「`cache`と`artifacts`の違いは何ですか？」
- 「テストスイートの並列テストを設定するのを手伝ってください。」
- 「ジョブをより早く開始させるために、`needs`をどのように使用すればよいですか？」
- 「このCI/CD設定が何をするのか説明してください: （設定を貼り付け）」
- 「マルチプロジェクトパイプラインを設定するにはどうすればよいですか？」
- 「パイプラインでシークレットを処理する最善の方法は何ですか？」
- 「ビルド時間を短縮するために、パイプラインを最適化するのを手伝ってください。」
- 「ジョブをマージリクエストでのみ実行するにはどうすればよいですか？」
- 「pytestとLint機能を含むPythonプロジェクト用に`.gitlab-ci.yml`を作成してください。」
- 「アーティファクトを使用してジョブ間でデータを渡すにはどうすればよいですか？」
- 「私のプロジェクト用にAuto DevOpsを設定してください。」
