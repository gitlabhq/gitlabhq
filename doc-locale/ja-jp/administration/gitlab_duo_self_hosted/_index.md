---
stage: AI Platform
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIゲートウェイと言語モデルを自社環境でホストします。
title: セルフホストモデル
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated for Government

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[機能フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6の[GitLab Self-Managedで有効](https://gitlab.com/groups/gitlab-org/-/work_items/15176)になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。
- 機能フラグ`ai_custom_model`は、GitLab 17.8で削除されました。
- GitLab 17.9で一般提供になりました。
- GitLab 18.0でPremiumを含むように変更されました。
- GitLab 18.5の[GitLab Dedicated for Government](https://gitlab.com/gitlab-org/gitlab/-/issues/569874)で有効になりました。
- GitLab 18.8のオフラインライセンスでは、GitLab Duo Agent Platform Self-Hostedアドオンが必須になりました
- GitLab 18.9のオンラインライセンスでは、GitLab Duo Agent Platformの機能の利用状況に応じた課金に変更されました

{{< /history >}}

独自のAIインフラストラクチャをホストすることで、GitLab Duoの各種機能を任意のLLMで動作させることができます。セルフホストAIゲートウェイを使用すると、すべてのリクエストおよびレスポンスデータを自組織環境内に保持し、外部APIに対するコールを実行することなく、LLMバックエンドへのリクエストのライフサイクル全体を管理できます。

## デプロイオプション {#deployment-options}

セルフホストモデルは、複数のデプロイオプションに対応しています。

### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

オンプレミス型モデル、またはGitLab Duo Agent Platform内のプライベートクラウドでホストされるモデルには、GitLab Duo Agent Platform Self-Hostedを使用します。

オフラインライセンスをお持ちのお客様は、GitLab Duoのエンタープライズライセンス契約に基づいて請求が行われ、[GitLab Duo Agent Platformセルフホスト型](../../subscriptions/subscription-add-ons.md#gitlab-duo-agent-platform-self-hosted)アドオンが必要です。

オンラインライセンスをお持ちのお客様の場合、請求は[使用量課金](../../subscriptions/gitlab_credits.md)です。ハイブリッドデプロイメントでは、GitLabが管理するモデルも使用できます。

### GitLab Duo {#gitlab-duo}

GitLab Duo Self-Hostedは、GitLab Duo Enterpriseを利用し、GitLab Duo機能を使用している顧客向けです。使用できるモデルは次のとおりです:

- オンプレミスモデルまたはプライベートクラウドでホストされるモデル
- ハイブリッドデプロイメントのGitLab管理モデル

このオプションはシートベースの価格設定となっています。

### 機能のバージョンとステータス {#feature-versions-and-status}

下記の表に次の一覧を示します:

- 機能を使用するために必要なGitLabのバージョン。
- 機能のステータス。デプロイメントの機能ステータスは、機能にリストされているステータスと異なる場合があります。

GitLab Duo Self-HostedでGitLab Duo機能を使用するには、GitLab Duo Enterpriseアドオンが必要です。これは、GitLabがクラウドベースの[AIゲートウェイ](../gitlab_duo/gateway.md)を介してこれらのモデルをホストおよび接続し、GitLab Duo CoreまたはGitLab Duo Proでこれらの機能を使用できる場合でも適用されます。

| 機能                                                                                                                                | GitLabバージョン          | ステータス              |
|----------------------------------------------------------------------------------------------------------------------------------------|-------------------------|---------------------|
| [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)                                                                   | GitLab 18.8以降   | 一般提供 |
| **GitLab Duo** | | |
| [コード提案](../../user/project/repository/code_suggestions/_index.md)                                                 | GitLab 17.9以降   | 一般提供 |
| [GitLab Duo Non-Agentic Chat](../../user/gitlab_duo_chat/_index.md)                                                                      | GitLab 17.9以降   | 一般提供 |
| [コード説明](../../user/gitlab_duo_chat/examples.md#explain-selected-code)                                                       | GitLab 17.9以降   | 一般提供 |
| [テスト生成](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)                                                       | GitLab 17.9以降   | 一般提供 |
| [コードのリファクタリング](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)                                                       | GitLab 17.9以降   | 一般提供 |
| [コード修正](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)                                                                 | GitLab 17.9以降   | 一般提供 |
| [コードレビュー](../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)                           | GitLab 18.3以降   | 一般提供 |
| [根本原因分析](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)                   | GitLab 17.10以降  | ベータ版                |
| [脆弱性の説明](../../user/application_security/analyze/duo.md)                                                            | GitLab 18.1.2以降 | ベータ版                |
| [マージコミットメッセージ生成](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)          | GitLab 18.1.2以降 | ベータ版                |
| [マージリクエストサマリー](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | GitLab 18.1.2以降 | ベータ版                |
| [ディスカッションサマリー](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)                                | GitLab 18.1.2以降 | ベータ版                |
| [CLI用GitLab Duo](https://docs.gitlab.com/cli/)                                                                                 | GitLab 18.1.2以降 | ベータ版                |
| [脆弱性の修正](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)                         | GitLab 18.1.2以降 | ベータ版                |
| [GitLab DuoとSDLCのトレンドダッシュボード](../../user/analytics/duo_and_sdlc_trends.md)                                                    | GitLab 17.9以降   | ベータ版                |
| [コードレビューサマリー](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)                              | GitLab 18.1.2以降 | 実験的機能          |

## Agent Platformのインターネット接続要件 {#internet-connectivity-requirements-for-the-agent-platform}

インターネット接続の要件は、お使いのサブスクリプションがオンラインライセンスかオフラインライセンスかによって異なります。

お使いのサブスクリプションがオンラインライセンスの場合、使用量課金には送信インターネット接続が必要です。お使いのファイアウォールまたはネットワークポリシーが以下のコンポーネントのいずれかをブロックすると、使用量課金は失敗し、GitLab Duo Agent Platformの機能を使用できません。

お使いのサブスクリプションがオフラインライセンスの場合、お使いのインスタンスは以下のコンポーネントに接続しません。使用量課金ではなく、エンタープライズライセンス契約に基づいて請求が行われます。詳細については、[オフラインデプロイ](offline_deployment.md)を参照してください。

| コンポーネント | エンドポイント | ポート | 目的 |
|-----------|----------|------|---------|
| CustomersDot | `customers.gitlab.com` | `443` | ライセンスとサブスクリプションの情報を同期させます。 |
| クラウドAIゲートウェイ | `cloud.gitlab.com` | `443` | Agent Platform機能の使用量クォータチェックを実行します。 |
| クラウドGitLab Duoワークフローサービス<sup>1</sup> | `duo-workflow-svc.runway.gitlab.net` | `443` | GitLab Duo Agent Platform機能の使用量課金メタデータを送信します。 |

**補足説明**: 

1. HTTP/2が必要です。

これらのコンポーネントには請求メタデータのみが送信されます。プロンプト、コード入力、およびモデルの応答は、お客様のネットワーク外には送信されません。送信されるデータの種類については、[データ送信](#data-transmission)を参照してください。

## データ転送 {#data-transmission}

以下の請求メタデータが、使用量課金のためにJSONオブジェクトでGitLabに送信されます:

- インスタンスID
- ユーザーID
- 呼び出し回数
- タイムスタンプ

例: 

```json
{
  "InstanceId": "ccbb3949-9836-471c-b2nb-32a38e8cca99",
  "GlobalUserId": "KWDTe17sGSADiAzEGJ6IuL1D7RAzsXqa2wun3aX1YuA=",
  "Quantity": 1,
  "Timestamp": "2026-05-04 18:04:30.969000000"
}
```

> [!note]
> `GlobalUserId`は、決定論的でありながら非特定化された識別子です。`GlobalUserId`は、GitLabコード内で、インスタンスIDおよびユーザーIDからSHA-256を用いて生成されます。お客様がルックアップを構築すれば、特定のユーザーにマップし直すことが可能です。

コード入力、モデルプロンプト、モデル応答を含む推論データは、顧客のネットワーク外に送信されることはありません。

GitLabは、顧客がどのモデルまたはモデルプロバイダーを使用しているかを捕捉しません。

## AIゲートウェイ構成 {#ai-gateway-configurations}

デプロイオプションを選択したら、次にAIゲートウェイのLLM接続を構成します:

- **セルフホストAIゲートウェイとLLM**: AIインフラストラクチャを完全に制御するために、独自のAIゲートウェイとモデルを使用します。
- **ハイブリッドAIゲートウェイとモデル構成**: 機能ごとに、独自のAIゲートウェイとセルフホストモデルを使用するか、GitLab.comのAIゲートウェイとGitLab管理のモデルを使用します。
- **デフォルトのGitLab外部ベンダーLLMを使用したGitLab.com AIゲートウェイ**: GitLabが管理するAIインフラストラクチャを使用します。

| 構成               | セルフホストAIゲートウェイ                                                                    | ハイブリッドAIゲートウェイとモデル構成                                                                                                        | GitLab.com AIゲートウェイ                    |
|-----------------------------|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| インフラストラクチャ要件 | 独自のAIゲートウェイとモデルのホスティングが必要                                           | 独自のAIゲートウェイとモデルのホスティングが必要                                                                                                  | 追加のインフラストラクチャは不要      |
| モデルオプション               | [サポート対象のセルフホストモデル](supported_models_and_hardware_requirements.md)から選択 | [サポートされているセルフホストモデル](supported_models_and_hardware_requirements.md)またはGitLab管理モデルを、各GitLab Duo機能に選択します。 | デフォルトのGitLab管理モデルを使用します。 |
| ネットワーク要件        | 完全に隔離されたネットワークで動作可能                                                    | GitLab管理モデルを使用するGitLab Duo機能には、インターネット接続が必要です。                                                          | インターネット接続が必要           |
| 責任            | インフラストラクチャのセットアップと独自のメンテナンスを実施                               | インフラストラクチャを設定し、独自のメンテナンスを行い、どの機能がGitLab管理モデルとAIゲートウェイを使用するかを選択します。                    | GitLabがセットアップとメンテナンスを実施   |

### セルフホストAIゲートウェイとLLM {#self-hosted-ai-gateway-and-llms}

完全なセルフホスト設定では、独自のAIゲートウェイをデプロイし、GitLabインフラストラクチャやAIベンダーモデルを使用せずに、自社のインフラストラクチャで[サポートされているLLM](supported_models_and_hardware_requirements.md)のみを使用します。これにより、データとセキュリティを完全に制御できます。

> [!note]
> この設定には、セルフホストAIゲートウェイを介して設定されたモデルのみが含まれます。いずれかの機能で[GitLab管理モデル](configure_duo_features.md#select-a-gitlab-managed-model-for-a-feature)を使用する場合、それらの機能はセルフホストAIゲートウェイではなく、GitLabホストのAIゲートウェイに接続されるため、完全にセルフホストされるのではなく、ハイブリッド設定になります。

独自のAIゲートウェイをデプロイしている間も、[AWS Bedrock](https://aws.amazon.com/bedrock/)や[Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service)のようなクラウドベースのLLMサービスをモデルバックエンドとして使用でき、セルフホストAIゲートウェイを介して接続し続けることができます。

インターネットアクセスを防止または制限する物理的な障壁やセキュリティポリシーがあるオフライン環境で、包括的なLLM制御が必要な場合は、この完全なセルフホスト設定を使用する必要があります。

詳細については、以下を参照してください:

- [セルフホストAIゲートウェイ構成図](configuration_types.md#self-hosted-ai-gateway)。

### ハイブリッドAIゲートウェイとモデル構成 {#hybrid-ai-gateway-and-model-configuration}

{{< history >}}

- GitLab 18.3で`ai_self_hosted_vendored_features`[機能フラグ](../feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17192)されました。デフォルトでは無効になっています。
- GitLab 18.7で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030)になりました。
- GitLab 18.9で一般提供になりました。機能フラグ`ai_self_hosted_vendored_features`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595)されました。

{{< /history >}}

このハイブリッド設定では、ほとんどの機能に独自のAIゲートウェイとセルフホストモデルをデプロイしますが、特定の機能ではGitLab管理モデルを使用するように設定します。ある機能がGitLab管理モデルを使用するように設定されている場合、その機能へのリクエストは、セルフホストAIゲートウェイではなく、GitLabホストのAIゲートウェイに送信されます。

このオプションは、以下を可能にすることで柔軟性を提供します:

- 完全な制御が必要な機能には独自のセルフホスティング型モデルを使用する。
- GitLabがキュレーションしたモデルを優先する特定の機能には、GitLab管理のベンダーモデルを使用する。

> [!note]
> 機能がGitLabマネージドモデルを使用するように設定されている場合:
>
> - これらの機能へのすべての呼び出しは、セルフホストAIゲートウェイではなく、GitLabでホストされているAIゲートウェイを使用します。
> - これらの機能にはインターネット接続が必要です。
> - これは、完全にセルフホストまたは隔離された設定ではありません。

#### GitLab管理モデル {#gitlab-managed-models}

インフラストラクチャをセルフホストする必要なく、GitLabマネージドモデルを使用してAIモデルに接続します。これらのモデルは、GitLabによって完全に管理されます。

AIネイティブ機能で使用するデフォルトのGitLabモデルを選択できます。デフォルトモデルの場合、GitLabは可用性、品質、信頼性に基づいて最適なモデルを使用します。機能に使用されるモデルは、予告なく変更される場合があります。

特定のGitLabマネージドモデルを選択すると、その機能に対するすべてのリクエストがそのモデルのみを使用します。モデルが利用できなくなった場合、AIゲートウェイへのリクエストは失敗し、別のモデルが選択されるまで、ユーザーはその機能を使用できません。

> [!note]
> 機能をGitLabマネージドモデルを使用するように設定する場合:
>
> - これらの機能への呼び出しは、セルフホストAIゲートウェイではなく、GitLabでホストされているAIゲートウェイを使用します。
> - これらの機能にはインターネット接続が必要です。
> - この設定は、完全なセルフホストまたは隔離された構成ではありません。

### デフォルトのGitLab外部ベンダーLLMを使用したGitLab.com AIゲートウェイ {#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise

{{< /details >}}

GitLab Duo Self-Hostedのユースケース基準を満たしていない場合は、デフォルトのGitLab外部ベンダーLLMを備えたGitLab.com AIゲートウェイを使用できます。

GitLab.com AIゲートウェイはデフォルトのEnterprise提供であり、セルフホストではありません。この設定では、インスタンスをGitLabがホストするAIゲートウェイに接続し、以下を含む外部ベンダーLLMプロバイダーと統合します:

- [Anthropic](https://www.anthropic.com/)
- [Fireworks AI](https://fireworks.ai/)
- [Google Vertex](https://cloud.google.com/vertex-ai/)

これらのLLMはGitLab Cloud Connectorを介して通信し、オンプレミスインフラストラクチャを必要とせずに、すぐに使用できるAIソリューションを提供します。

詳細については、[GitLab.com AIゲートウェイ構成図](configuration_types.md#gitlabcom-ai-gateway)を参照してください。

このインフラストラクチャをセットアップするには、[GitLab Self-ManagedインスタンスでGitLab Duoを設定する方法](../gitlab_duo/configure/_index.md)を参照してください。

## プライベートインフラストラクチャのセットアップ {#set-up-private-infrastructure}

オフラインライセンスをお持ちの場合は、完全にプライベートなインフラストラクチャをセットアップできます:

1. 大規模言語モデル（LLM）サービスインフラストラクチャをインストールします。

   - [サポートされているLLMプラットフォーム](supported_llm_serving_platforms.md)をレビューして、vLLM、AWS Bedrock、Azure OpenAIなどのサービングおよびホスティングプラットフォームを選択してください。
   - [サポートされているモデルとハードウェア要件](supported_models_and_hardware_requirements.md)を確認して、モデルとハードウェアの選択を確定してください。

1. [AIゲートウェイをインストール](../../install/install_ai_gateway.md)してGitLab Duo機能にアクセスします。
1. セルフホストモデルを使用するように[GitLabインスタンスを設定](configure_duo_features.md)します。
1. システムのパフォーマンスを追跡および管理するには、[ロギングを有効](logging.md)にします。

## 関連トピック {#related-topics}

- [トラブルシューティング](troubleshooting.md)
- [GitLab AIゲートウェイをインストールする](../../install/install_ai_gateway.md)
- [サポート対象モデル](supported_models_and_hardware_requirements.md)
- [サポートされているプラットフォーム](supported_llm_serving_platforms.md)
- [チュートリアル: AWS Bedrock BYOMデプロイガイド](../../solutions/integrations/aws_bedrock_byom.md)
