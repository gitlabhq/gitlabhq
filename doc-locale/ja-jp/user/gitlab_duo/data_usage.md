---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIネイティブの機能と機能性。
title: GitLab Duoのデータの使用
---

GitLab Duoは生成AIを使用して、ベロシティを向上させ、生産性を高めます。各AIネイティブ機能は独立して動作し、他の機能の動作に依存しません。

GitLabは、特定のタスクに適した大規模言語モデル（LLM）を使用します。これらの大規模言語モデルは、[Anthropic Claude](https://claude.com/product/overview)、[Fireworks AI-hosted Codestral](https://mistral.ai/news/codestral)、[Gemini Enterprise Agent Platformモデル](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/beginners-guide)、および[OpenAIモデル](https://platform.openai.com/docs/models)です。

## 段階的な機能拡張 {#progressive-enhancement}

GitLab DuoのAIネイティブ機能は、DevSecOpsプラットフォーム全体の既存のGitLab機能を段階的に拡張するように設計されています。これらの機能は適切に機能低下するように設計されており、基盤となる機能のコア動作を妨げることはありません。各機能は、関連する[機能サポートポリシー](../../policy/development_stages_support.md)で定義された期待される動作に準拠します。

## 安定性とパフォーマンス {#stability-and-performance}

GitLab DuoのAIネイティブ機能は、さまざまな[機能サポートレベル](../../policy/development_stages_support.md#beta)にあります。これらの機能の性質上、使用に対する高い需要により、機能のパフォーマンス低下や予期しないダウンタイムが発生する可能性があります。これらの機能は適切に低下するように構築されており、不正使用や誤用を軽減できる制御機能を備えています。GitLabは、独自の裁量により、いつでもすべてまたは一部のお客様に対してベータ版および実験的機能を無効にする場合があります。

## データプライバシー {#data-privacy}

GitLab DuoのAIネイティブ機能は、生成AIモデルによって提供されます。GitLabは、[GitLabプライバシーに関する声明](https://about.gitlab.com/privacy/)に従って、あらゆる個人データを処理します。

GitLabがこれらの機能を提供するために使用するAIモデルサブプロセッサのリストについては、[サードパーティのサブプロセッサ](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors)を参照してください。

## データ保持 {#data-retention}

### モデルサブプロセッサ {#model-sub-processors}

GitLab Duoのリクエストについて、GitLabはFireworks AIとのゼロデータ保持ポリシーを定めています。Fireworks AIは、モデルの入力および出力データが提供された直後にそれを破棄し、悪用モニタリングのために入力および出力データを保存しません。このポリシーの例外は、プロンプトキャッシュがGitLab Duoコード提案およびGitLab Duo Agentic Chatに対して有効になっている場合です。OpenAIモデルの場合、プロンプトキャッシュをオフにすることはできません。

AnthropicおよびOpenAIの一部のモデルは、Amazon BedrockおよびGemini Enterprise Agent Platformでホストされている場合を含め、ベンダー側の限定的なデータ保持の対象となります。これらのモデルの詳細については、[サポートされているGitLab Duo Agent PlatformのAIモデル](../duo_agent_platform/model_selection.md#supported-models)を参照してください。

### GitLab {#gitlab}

GitLab Duo ChatとGitLab Duo Agent Platformは、以前に議論したトピックに素早く戻るのに役立つように、チャットとワークフローの履歴を保持します。GitLab Duo Chatインターフェースでチャットを削除できます。GitLab.comでは、GitLabは不正使用防止のためにチャットとワークフローの履歴を保持します。GitLabは、顧客が[GitLabサポートチケット](https://about.gitlab.com/support/portal/)を通じて同意を提供しない限り、入力および出力データを保持しません。

GitLab Duo Agent Platformの拡張ロギングを有効にすると、GitLabはトレースデータを保持します。AI機能に関連するロギング情報は、GitLab AIモデルサブプロセッサとのゼロデータ保持ポリシーとは別です。詳細については、[GitLabログシステム](../../administration/logs/_index.md)を参照してください。

## モデルトレーニング {#model-training}

GitLabは生成AIモデルをトレーニングしません。

すべてのGitLab AIモデルサブプロセッサは、モデルの入力および出力をモデルのトレーニングに使用することを制限されています。これらのサブプロセッサは、独自の目的で顧客コンテンツを使用することを禁止するGitLabとのデータ保護契約に基づいており、独立した法的義務を履行する場合を除きます。

## テレメトリ {#telemetry}

GitLab Duoは、Snowplowコレクターを介して、集約または匿名化されたファーストパーティーの使用状況データを収集します。この使用状況データには、次のメトリクスが含まれます:

- ユニークユーザー数
- ユニークインスタンス数
- プロンプトとサフィックスの長さ
- 使用されたモデル
- ステータスコードレスポンス
- APIレスポンス時間
- コード提案はさらに以下を収集します:
  - 提案で使用された言語（例: Python）
  - 使用されているエディタ（例: VS Code）
  - 表示、承認、拒否、またはエラーが発生した提案の数
  - 提案が表示された時間の長さ

## GitLab Model Context Protocolサーバー {#gitlab-model-context-protocol-server}

次の情報は、GitLab Self-Managedインスタンスでの[GitLab Model Context Protocol（MCP）サーバー](../model_context_protocol/mcp_server.md)の使用に適用されます。

GitLab MCPサーバーが使用されている場合、GitLabはデータを送信、保存、保持、または処理しません。すべての通信は、MCPクライアントとお客様の環境にあるGitLab MCPサーバーの間で直接行われます。

リポジトリデータとメタデータはGitLabに送信されません。

どのMCPクライアントがお客様のインスタンスに接続するかは、お客様が管理します。各クライアントのプライバシーおよびデータ保持ポリシーが適用されます。

## モデルの精度と品質 {#model-accuracy-and-quality}

生成AIは、次のような予期しない結果を生成する可能性があります:

- 低品質
- 一貫性がない
- 不完全
- パイプラインの失敗を引き起こす
- 安全でないコード
- 攻撃的または配慮に欠ける
- 古い情報

GitLabは、生成されたコンテンツの品質を向上させるために、すべてのAIアシスト機能について、積極的にイテレーションを重ねています。プロンプトエンジニアリング、これらの機能を強化する新しいAI/MLモデルの評価、およびこれらの機能に直接組み込まれた新しいヒューリスティックを通じて品質を向上させています。

## シークレット検出と墨消し {#secret-detection-and-redaction}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/632)されました。

{{< /history >}}

GitLab Duoには、フロー実行中に[シークレット検出と削除](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/docs/developer/secret-redaction.md)が含まれています。シナリオに応じて、GitLab Duoは、大規模言語モデルで処理する前に、APIキー、認証情報、トークンなどの機密情報を自動的に検出し、コードから削除します。

GitLab Duoを使用する際、コードは事前スキャンセキュリティワークフローを通過します:

1. コードは、Gitleaksを使用して機密情報がスキャンされます。
1. 検出されたシークレットは、リクエストから自動的に削除されます。

シークレットスキャンは以下のシナリオで実行されます:

- コード補完のコンテキスト変換（コンテキストがAIに送信される前）
- AIコンテキスト変換
- ワークフローツール結果
- Agentic Chatユーザー入力
- Gitコマンドロギング
- CLI設定ロギング

> [!note]
> シークレットスキャンは、ウェブインターフェースを通じてGitLab Duo Chatを操作する際には行われません。

### 例外: シークレット誤検出判定 {#exception-secret-false-positive-detection}

[シークレット誤検出判定](../application_security/vulnerabilities/secret_false_positive_detection.md)は、検出されたシークレットを含むコードと脆弱性に関する情報を分析のためにLLMに送信するオプトイン機能です。これは、[シークレット検出および削除](#secret-detection-and-redaction)の動作に対する意図的な例外です。

この機能はオプトインであるため、脆弱性データがLLMに送信される前に、グループレベルとプロジェクトレベルの両方で明示的に有効にする必要があります。この機能を有効にする前に、組織のデータポリシーを確認してください。

## グループの利用データをGitLabと共有する {#share-group-usage-data-with-gitlab}

{{< history >}}

- GitLab 18.9.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/587976)されました。

{{< /history >}}

サービス品質の向上に役立つよう、GitLab Duo Agent Platform機能に関する使用状況データをGitLabと共有できます。

データ収集を有効にすると、ネームスペース内のすべてのプロジェクトおよびサブグループからのAIインタラクションがGitLabにログ記録されます。このデータは、サービス改善およびデバッグのみに使用され、AIモデルのトレーニングには使用されません。

使用状況データの収集は、[インスタンス](../../administration/gitlab_duo/configure/_index.md#share-usage-data-with-gitlab)についても有効にできます。

前提条件: 

- GitLab 18.9.1以降が必要です。
- トップレベルグループのオーナーロールを持っていること。
- GitLab.comでは、グループで[GitLab Duoが有効になっている](turn_on_off.md#turn-gitlab-duo-on-or-off)必要があります。

グループのデータ収集を有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **データ収集**の下にある**使用状況データの収集**チェックボックスを選択します。
1. **変更を保存**を選択します。

### エージェントプラットフォームの利用データ {#agent-platform-usage-data}

データ収集を有効にすると、以下のデータがログに記録されます:

- GitLab Duoとのインタラクションからの完全なプロンプトおよび応答テキスト。
- 設定が有効になった時点で進行中だったセッションを含むセッションコンテキスト。
- モデルメタデータ（モデルバージョン、トークン数、レイテンシー）。
- ツール呼び出しとその結果。
- ユーザーフィードバックとの相関関係を示すセッションID。

ユーザーが自身のプロンプトに含めない限り、以下の情報はログに含まれません:

- ユーザーIDまたはユーザー名。
- メールアドレスまたは個人識別子。
- プロジェクトまたはネームスペース識別子。

GitLabは、ユーザーが自身のプロンプトに含めた識別子を削除しません。

## プロンプトキャッシュ {#prompt-caching}

プロンプトキャッシュは、キャッシュされたプロンプトおよび入力データの再処理を回避することで、レイテンシーを改善します。プロンプトキャッシュを有効にすると、モデルベンダーはプロンプトデータを一時的にメモリに保存します。キャッシュされたデータは、永続ストレージに記録されません。

プロンプトレジストリを使用するAgent Platform機能とコード提案の両方で、サポートされているモデルに対してトークンキャッシュが自動的に有効になります。

### プロンプトキャッシュをオフにする {#turn-off-prompt-caching}

デフォルトで、プロンプトキャッシュは有効になっています。プロンプトキャッシュは、トップレベルグループまたはインスタンスに対して無効にすることができます。

{{< tabs >}}

{{< tab title="トップレベルグループの場合" >}}

前提条件: 

- トップレベルグループのオーナーロール。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **データとプライバシー**セクションの**プロンプトキャッシュ**で、**プロンプトキャッシュを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="インスタンスの場合" >}}

前提条件: 

- 管理者アクセス権。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **データとプライバシー**セクションの**プロンプトキャッシュ**で、**プロンプトキャッシュを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< /tabs >}}
