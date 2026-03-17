---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIゲートウェイと言語モデルを自社環境でホストします。
title: セルフホストモデル
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6の[GitLab Self-Managedで有効](https://gitlab.com/groups/gitlab-org/-/epics/15176)になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。
- 機能フラグ`ai_custom_model`は、GitLab 17.8で削除されました。
- GitLab 17.9で一般提供になりました。
- GitLab 18.0でPremiumを含むように変更されました。
- GitLab 18.8のオフラインライセンスでは、GitLab Duo Agent Platform Self-Hostedアドオンが必須になりました
- GitLab 18.9のオンラインライセンスでは、GitLab Duo Agent Platformの機能の利用状況に応じた課金に変更されました

{{< /history >}}

独自のAIインフラストラクチャをホストして、お好みのLLMでGitLab Duo機能を使用します。セルフホストAIゲートウェイを使用して、すべてのリクエストとレスポンスデータを独自の環境に保持し、外部APIコールを回避して、LLMバックエンドへのリクエストのフルライフサイクルを管理します。

## デプロイオプション {#deployment-options}

さまざまなデプロイオプションでセルフホストモデルを使用できます。

### GitLab Duo（クラシック） {#gitlab-duo-classic}

GitLab Duo Enterpriseをお使いのGitLab Duo（クラシック）機能をお使いのお客様向けのGitLab Duoセルフホスト。使用できるモデルは次のとおりです:

- オンプレミスモデルまたはプライベートクラウドでホストされるモデル
- ハイブリッドデプロイメントのGitLab管理モデル

このオプションでは、シートベースの価格設定が使用されます。

### GitLab Duo Agent Platform {#gitlab-duo-agent-platform}

GitLab Duo Agent Platformのオンプレミスモデルまたはプライベートクラウドでホストされるモデルを使用するためのGitLab Duo Agent Platform Self-Hosted。

オフラインライセンスをお持ちのお客様の場合、料金はシートベースで、[GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md#gitlab-duo-agent-platform-self-hosted)アドオンが必要です。

オンラインライセンスをお持ちのお客様の場合、料金は使用量に基づきます。ハイブリッドデプロイメントでは、GitLabが管理するモデルも使用できます。

### 機能のバージョンとステータス {#feature-versions-and-status}

下記の表に次の一覧を示します:

- 機能を使用するために必要なGitLabのバージョン。
- 機能のステータス。デプロイメントの機能ステータスは、機能にリストされているステータスと異なる場合があります。

GitLab Duo Self-HostedでGitLab Duo（クラシック）機能を使用するには、GitLab Duo Enterpriseアドオンが必要です。これは、GitLabがクラウドベースの[AIゲートウェイ](../../administration/gitlab_duo/gateway.md)を介してこれらのモデルをホストおよび接続し、GitLab Duo CoreまたはGitLab Duo Proでこれらの機能を使用できる場合でも適用されます。

| 機能                                                                                                                                | GitLabバージョン          | ステータス              |
|----------------------------------------------------------------------------------------------------------------------------------------|-------------------------|---------------------|
| [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)                                                                   | GitLab 18.8以降   | 一般提供 |
| **GitLab Duo（クラシック）** | | |
| [コード提案（クラシック）](../../user/project/repository/code_suggestions/_index.md)                                                 | GitLab 17.9以降   | 一般提供 |
| [GitLab Duo Chat（クラシック）](../../user/gitlab_duo_chat/_index.md)                                                                      | GitLab 17.9以降   | 一般提供 |
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

## AIゲートウェイ構成 {#ai-gateway-configurations}

製品オプションを選択したら、AIゲートウェイをLLMに接続する方法を構成します:

- **セルフホストAIゲートウェイとLLM**: AIインフラストラクチャを完全に制御するために、独自のAIゲートウェイとモデルを使用します。
- **ハイブリッドAIゲートウェイとモデル構成**: 機能ごとに、セルフホストモデルを使用した独自のセルフホストAIゲートウェイ、またはGitLab.com AIゲートウェイとGitLab AIベンダーモデルのいずれかを使用します。
- **デフォルトのGitLab外部ベンダーLLMを使用したGitLab.com AIゲートウェイ**: GitLabが管理するAIインフラストラクチャを使用します。

| 構成               | セルフホストAIゲートウェイ                                                                    | ハイブリッドAIゲートウェイとモデル構成                                                                                                        | GitLab.com AIゲートウェイ                    |
|-----------------------------|-------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| インフラストラクチャ要件 | 独自のAIゲートウェイとモデルのホスティングが必要                                           | 独自のAIゲートウェイとモデルのホスティングが必要                                                                                                  | 追加のインフラストラクチャは不要      |
| モデルオプション               | [サポート対象のセルフホストモデル](supported_models_and_hardware_requirements.md)から選択 | [サポート対象のセルフホストモデル](supported_models_and_hardware_requirements.md)、または各GitLab Duo機能のGitLab AIベンダーモデルから選択 | デフォルトのGitLab AIベンダーモデルを使用 |
| ネットワーク要件        | 完全に隔離されたネットワークで動作可能                                                    | GitLab AIベンダーモデルを使用するGitLab Duo機能にはインターネット接続が必要                                                          | インターネット接続が必要           |
| 責任            | インフラストラクチャのセットアップと独自のメンテナンスを実施                               | インフラのセットアップ、独自のメンテナンスを実施し、どの機能がGitLab AIベンダーモデルとAIゲートウェイを使用するかを選択                    | GitLabがセットアップとメンテナンスを実施   |

### セルフホストAIゲートウェイとLLM {#self-hosted-ai-gateway-and-llms}

完全なセルフホスト設定では、独自のAIゲートウェイをデプロイし、GitLabインフラストラクチャやAIベンダーモデルを使用せずに、自社のインフラストラクチャで[サポートされているLLM](supported_models_and_hardware_requirements.md)のみを使用します。これにより、データとセキュリティを完全に制御できます。

> [!note] 
> この設定には、セルフホストAIゲートウェイを介して設定されたモデルのみが含まれます。いずれかの機能で[GitLab AIベンダーモデル](configure_duo_features.md#configure-a-feature-to-use-a-gitlab-ai-vendor-model)を使用する場合、これらの機能はセルフホストゲートウェイではなく、GitLabでホストされているAIゲートウェイに接続されるため、完全にセルフホスト設定ではなく、ハイブリッド設定になります。

独自のAIゲートウェイをデプロイしている間も、[AWS Bedrock](https://aws.amazon.com/bedrock/)や[Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service)のようなクラウドベースのLLMサービスをモデルバックエンドとして使用でき、セルフホストAIゲートウェイを介して接続し続けることができます。

インターネットアクセスを防止または制限する物理的な障壁やセキュリティポリシーがあるオフライン環境で、包括的なLLM制御が必要な場合は、この完全なセルフホスト設定を使用する必要があります。

詳細については、以下を参照してください: 

- [セルフホストAIゲートウェイ構成図](configuration_types.md#self-hosted-ai-gateway)。

### ハイブリッドAIゲートウェイとモデル構成 {#hybrid-ai-gateway-and-model-configuration}

{{< history >}}

- GitLab 18.3で`ai_self_hosted_vendored_features`[機能フラグ](../feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/17192)されました。デフォルトでは無効になっています。
- GitLab 18.7で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030)になりました。
- GitLab 18.9で一般提供。機能フラグ`ai_self_hosted_vendored_features`は[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218595)されました。

{{< /history >}}

このハイブリッド設定では、ほとんどの機能で独自のAIゲートウェイとセルフホストモデルをデプロイしますが、特定の機能を使用するように設定して、GitLab AIベンダーモデルを使用します。機能がGitLab AIベンダーモデルを使用するように設定されている場合、その機能へのリクエストは、セルフホストAIゲートウェイではなく、GitLabでホストされているAIゲートウェイに送信されます。

このオプションは、以下を可能にすることで柔軟性を提供します:

- 完全な制御が必要な機能には独自のセルフホスティング型モデルを使用する。
- GitLabがキュレーションしたモデルを優先する特定の機能には、GitLab管理のベンダーモデルを使用する。

> [!note]
> 機能がGitLab AI AIベンダーモデルを使用するように構成されている場合:
>
> - これらの機能へのすべての呼び出しは、セルフホストAIゲートウェイではなく、GitLabでホストされているAIゲートウェイを使用します。
> - これらの機能にはインターネット接続が必要です。
> - これは、完全にセルフホストまたは隔離された設定ではありません。

詳細については、以下を参照してください: 

- [GitLab AIベンダーモデルを設定する](configure_duo_features.md#configure-a-feature-to-use-a-gitlab-ai-vendor-model)

#### GitLab管理モデル {#gitlab-managed-models}

GitLab管理モデルを使用すると、インフラストラクチャをセルフホストすることなくAIモデルに接続できます。これらのモデルは、GitLabによって完全に管理されます。

AIネイティブ機能で使用するデフォルトのGitLabモデルを選択できます。デフォルトモデルの場合、GitLabは可用性、品質、信頼性に基づいて最適なモデルを使用します。機能に使用されるモデルは、予告なく変更される場合があります。

特定のGitLab管理モデルを選択すると、その機能のすべてのリクエストはそのモデルのみを使用します。モデルが利用できなくなった場合、AIゲートウェイへのリクエストは失敗し、別のモデルが選択されるまで、ユーザーはその機能を使用できません。

> [!note] 
> GitLab管理モデルを使用するように機能を構成する場合:
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

このインフラストラクチャをセットアップするには、[GitLab Self-ManagedインスタンスでGitLab Duoを設定する方法](../../administration/gitlab_duo/configure/gitlab_self_managed.md)を参照してください。

## プライベートインフラストラクチャをセットアップする {#set-up-a-private-infrastructure}

オフラインライセンスをお持ちの場合は、完全にプライベートなインフラストラクチャをセットアップできます:

1. 大規模言語モデル（LLM）サービスインフラストラクチャをインストールします。

   - GitLabは、vLLM、AWS Bedrock、およびAzure OpenAIなど、LLMの提供とホスティングのためのさまざまなプラットフォームをサポートしています。各プラットフォームの詳細については、[サポートされているLLMプラットフォームのドキュメント](supported_llm_serving_platforms.md)を参照してください。

   - GitLabは、特定の機能とハードウェア要件を備えたサポート対象モデルのマトリックスを提供しています。詳細については、[サポートされているモデルとハードウェア要件](supported_models_and_hardware_requirements.md)を参照してください。

1. [AIゲートウェイをインストール](../../install/install_ai_gateway.md)してGitLab Duo機能にアクセスします。

1. [セルフホストモデルを使用する機能についてGitLabインスタンスを構成します](configure_duo_features.md)。

1. システムのパフォーマンスを追跡および管理するには、[ロギングを有効](logging.md)にします。

## 関連トピック {#related-topics}

- [トラブルシューティング](troubleshooting.md)
- [GitLab AIゲートウェイをインストールする](../../install/install_ai_gateway.md)
- [サポート対象モデル](supported_models_and_hardware_requirements.md)
- [サポートされているプラットフォーム](supported_llm_serving_platforms.md)
