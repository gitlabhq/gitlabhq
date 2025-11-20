---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AIネイティブの機能と機能性。
title: GitLab Duoのデータの使用
---

GitLab Duoは生成AIを使用して、ベロシティを向上させ、生産性を高めます。各AIネイティブ機能は個別に動作し、他の機能が機能するために必須ではありません。

GitLabは、特定のタスクに適した大規模言語モデル（LLM）を使用します。これらのLLMは、[Anthropic Claude](https://www.anthropic.com/product) 、[Fireworks AI-hosted Codestral](https://mistral.ai/news/codestral-2501) 、および[Google Vertex AI Models](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/overview#genai-models)です。

## プログレッシブエンハンスメント {#progressive-enhancement}

GitLab Duo AIネイティブ機能は、DevSecOpsプラットフォーム全体の既存のGitLab機能に対するプログレッシブエンハンスメントとして設計されています。これらの機能は、正常に失敗するように設計されており、基盤となる機能の中核機能を妨げるべきではありません。各機能は、関連する[feature support policy](../../policy/development_stages_support.md)で定義されているように、期待される機能の対象となることに注意してください。

## 安定性とパフォーマンス {#stability-and-performance}

GitLab Duo AIネイティブ機能は、さまざまな[feature support levels](../../policy/development_stages_support.md#beta)にあります。これらの機能の性質上、使用に対する高い需要があり、機能のパフォーマンスの低下や予期しないダウンタイムが発生する可能性があります。これらの機能は正常に低下するように構築されており、不正使用を軽減するための制御が整っています。GitLabは、ベータ版および試験的な機能を、当社の裁量により、いつでもすべてまたは一部のお客様に対して無効にする場合があります。

## データプライバシー {#data-privacy}

GitLab Duo AIネイティブ機能は、生成AI AIモデルを搭載しています。すべての個人データの処理は、当社の[プライバシーに関する声明](https://about.gitlab.com/privacy/)に従って行われます。これらの機能を提供するために使用するサブプロセッサのリストを表示するには、[Sub-Processors page](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors)にアクセスしてください。

## データ保持 {#data-retention}

以下は、GitLab AIモデル[Sub-Processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors)の現在の保持期間を反映しています。:

[Fireworks AI prompt caching](../project/repository/code_suggestions/_index.md#prompt-caching)を除外すると、GitLabはGitLab Duoリクエストに対して、Anthropic、Fireworks AI、およびGoogleとのゼロデイデータ保持を手配しました。Anthropic、Fireworks AI（プロンプトキャッシュが無効になっている場合）、およびGoogleは、出力が提供された直後にモデルの入力および出力データを破棄します。入力および出力データは、不正使用のモニタリングのために保存されません。モデルの入力と出力がモデルのトレーニングに使用されることはありません。

これらのすべてのAIプロバイダーは、独立した法的義務を履行する場合を除き、顧客コンテンツを独自の目的で使用することを禁止するGitLabとのデータ保護契約を結んでいます。

GitLab Duo ChatとGitLab Duo Duo Agent Platformは、それぞれチャットの履歴とワークフローの履歴を保持し、以前に議論したトピックにすばやく戻るのに役立ちます。GitLab Duo Chatインターフェースでチャットを削除できます。それ以外の場合、GitLabは、顧客がGitLab [Support Ticket](https://about.gitlab.com/support/portal/)を通じて同意を提供しない限り、入力データと出力データを保持しません。[AI feature logging](../../administration/logs/_index.md)の詳細をご覧ください。

コード提案のレイテンシーを改善するために、プロンプトのキャッシュがデフォルトで有効になっています。詳細およびプロンプトキャッシュをオプトアウトする方法については、[コード提案prompt caching documentation](../project/repository/code_suggestions/_index.md#prompt-caching)を参照してください。

## トレーニングデータ {#training-data}

GitLabは生成AIモデルをトレーニングしません。

当社のAI [sub-processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors)の詳細については、以下を参照してください。:

- Google Vertex AIモデルAPIの[データガバナンス](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance)、[責任あるAI](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/responsible-ai)、[基盤モデルのトレーニングに関する詳細](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance#foundation_model_training)、Googleの[Secure AI Framework (SAIF)](https://safety.google/cybersecurity-advancements/saif/)、および[リリースノート](https://cloud.google.com/vertex-ai/docs/release-notes)。
- Anthropic Claudeの[Constitution](https://www.anthropic.com/news/claudes-constitution)、トレーニングデータ[FAQ](https://support.anthropic.com/en/articles/7996885-how-do-you-use-personal-data-in-model-training)、[モデル概要](https://docs.anthropic.com/en/docs/about-claude/models)、および[データの最新性に関する記事](https://support.anthropic.com/en/articles/8114494-how-up-to-date-is-claude-s-training-data)。

## テレメトリ {#telemetry}

GitLab Duoは、Snowplowコレクターを介して、集約または匿名化されたファーストパーティーの使用状況データを収集します。この使用状況データには、次のメトリクスが含まれます。:

- ユニークユーザー数
- ユニークインスタンス数
- プロンプトとサフィックスの長さ
- 使用されたモデル
- ステータスコードのレスポンス
- APIレスポンス時間
- コード提案も収集します。:
  - コード提案で使用された言語（例：Python）
  - 使用されているエディタ（例：VS Code）
  - 表示、承認、拒否、またはエラーが発生したコード提案の数
  - コード提案が表示された時間の長さ

## モデルの精度と品質 {#model-accuracy-and-quality}

生成AIは、次のような予期しない結果を生成する可能性があります。:

- 低品質
- 支離滅裂
- 不完全
- 失敗したパイプラインを生成する
- 脆弱なコード
- 攻撃的または配慮に欠ける
- 日付切れの情報

GitLabは、生成されたコンテンツの品質を向上させるために、すべてのAIアシスト機能を積極的にイテレーションを行うています。これらの機能を強化するために、プロンプトエンジニアリングや新しいAI/MLモデルの評価、そしてこれらの機能に直接組み込まれた斬新なヒューリスティックを通じて、品質を向上させています。

## シークレット検出と墨消し {#secret-detection-and-redaction}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/632)されました。

{{< /history >}}

GitLab Duoには、Gitleaksを利用したシークレット検出と墨消し機能が含まれています。大規模な言語モデルで処理する前に、APIキー、認証情報、トークンなどの機密情報を自動的に検出してコードから削除します。このセキュリティ機能は、GDPRなどのデータ保護規制へのコンプライアンスにとって特に重要です。

GitLab Duoを使用すると、コードは事前スキャンセキュリティワークフローを通過します:

1. コードは、Gitleaksを使用して機密情報がスキャンされます。
1. 検出されたシークレットは、リクエストから自動的に削除されます。

## GitLab Duo Self-Hosted {#gitlab-duo-self-hosted}

[GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)とセルフホストAIゲートウェイを使用している場合、GitLabとデータを共有することはありません。

GitLab Self-Managed管理者は、[Service Ping](../../administration/settings/usage_statistics.md#service-ping)を使用して、使用状況の統計をGitLabに送信できます。これは、[テレメトリデータ](#telemetry)とは異なります。
