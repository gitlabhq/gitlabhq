---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 独自のAIゲートウェイと言語モデルをホストします。
title: GitLab Duo Self-Hosted
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6で[GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176)で有効になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.8で機能フラグ`ai_custom_model`は削除されました。
- GitLab 17.9で一般提供となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

GitLab Duo Self-Hostedを使用して、独自の大規模言語モデル（LLM）をGitLab Duoの機能と統合し、データのプライバシーとセキュリティを管理します。

GitLab Duo Self-Hostedを使用すると、次のことができます:

- GitLabでサポートされているLLM、または独自の互換性のあるモデルを選択します。
- ユーザーに特定のGitLab Duo機能を選択します。
- 外部APIコールなしで、すべてのリクエスト/レスポンスログをドメインに保持します。
- GitLabインスタンス、AIゲートウェイ、およびモデルを独自の環境に隔離します。
- 共有GitLab AIゲートウェイへの依存をなくします。
- GitLab Duo機能のLLMバックエンドへのリクエストのライフサイクルを管理し、外部の依存関係を回避して、リクエストがエンタープライズネットワーク内にとどまるようにします。

クリック操作のデモについては、[GitLab Duo Self-Hosted product tour](https://gitlab.navattic.com/gitlab-duo-self-hosted)を参照してください。
<!-- Demo published on 2025-02-13 -->

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab Duo Self-Hosted: プライベート環境でのAI](https://youtu.be/TQoO3sFnb28?si=uD-ps6aRnE28xNv3)を参照してください。
<!-- Video published on 2025-02-20 -->

## 前提要件 {#prerequisites}

GitLab Duo Self-Hostedを使用するには、以下が必要です:

- クラウドベースまたはオンプレミスでサポートされているモデル
- クラウドベースまたはオンプレミスでサポートされているサービスプラットフォーム
- ローカルでホストされているAIゲートウェイ

## サポートされているGitLab Duo機能 {#supported-gitlab-duo-features}

次の表に記載されています:

- GitLab Duoの機能と、それらの機能がGitLab Duo Self-Hostedで使用できるかどうか。
- GitLab Duo Self-Hostedでこれらの機能を使用するために必要なバージョンのGitLab。
- これらの機能のステータス。GitLab Duo Self-Hostedでの機能のステータスは、[that same feature's status when it is hosted on GitLab](../../user/gitlab_duo/feature_summary.md)とは異なる場合があります。

{{< alert type="note" >}}

GitLab Duo Self-Hostedでこれらの機能を使用するには、GitLab Duo Enterpriseアドオンが必要です。これは、クラウドベースの[AIゲートウェイ](../../user/gitlab_duo/gateway.md)を介してGitLabがこれらのモデルをホストおよび接続する場合、GitLab Duo CoreまたはDuo Proでこれらの機能を使用できる場合でも適用されます。

{{< /alert >}}

### コード提案 {#code-suggestions}

| 機能                                                                      | GitLab Duo Self-Hostedで利用可能         | GitLabバージョン        | ステータス  |
| ---------------------------------------------------------------------------- | ------------------------------------------- | --------------------- | --- |
| [コード提案](../../user/project/repository/code_suggestions/_index.md) | {{< icon name="check-circle-filled" >}}対応 | GitLab 17.9以降 | 一般提供 |

### チャット {#chat}

| 機能                                                                                                           | GitLab Duo Self-Hostedで利用可能         | GitLabバージョン         | ステータス  |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [一般](../../user/gitlab_duo_chat/_index.md)                                                                   | {{< icon name="check-circle-filled" >}}対応 | GitLab 17.9以降  | 一般提供 |
| [コードの説明](../../user/gitlab_duo_chat/examples.md#explain-selected-code)                                      | {{< icon name="check-circle-filled" >}}対応 | GitLab 17.9以降  | 一般提供 |
| [テスト生成](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)                                       | {{< icon name="check-circle-filled" >}}対応 | GitLab 17.9以降  | 一般提供 |
| [コードのリファクタリング](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)                                  | {{< icon name="check-circle-filled" >}}対応 | GitLab 17.9以降  | 一般提供 |
| [コードの修正](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)                                            | {{< icon name="check-circle-filled" >}}対応 | GitLab 17.9以降  | 一般提供 |
| [根本原因分析](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< icon name="check-circle-filled" >}}対応 | GitLab 17.10以降 | ベータ |
| [脆弱性の説明](../../user/application_security/vulnerabilities/_index.md#vulnerability-explanation)     | {{< icon name="check-circle-filled" >}}対応 | GitLab 18.1.2以降 | ベータ |

質問の例については、[Ask about GitLab](../../user/gitlab_duo_chat/examples.md)を参照してください。

### マージリクエストにおけるGitLab Duo {#gitlab-duo-in-merge-requests}

| 機能                                                                                                                                      | GitLab Duo Self-Hostedで利用可能         | GitLabバージョン         | ステータス |
| -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [マージコミットメッセージ生成](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)                        | {{< icon name="check-circle-filled" >}}対応 | GitLab 18.1.2以降 | ベータ |
| [マージリクエストサマリー](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< icon name="check-circle-filled" >}}対応 | GitLab 18.1.2以降 | ベータ |
| [コードレビュー](../../user/project/merge_requests/duo_in_merge_requests.md#have-gitlab-duo-review-your-code)                                   | {{< icon name="check-circle-filled" >}}対応 | GitLab 18.3以降         | 一般提供 |
| [コードレビューサマリー](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)                                    | {{< icon name="check-circle-filled" >}}対応 | GitLab 18.1.2以降 | 実験的機能 |

### イシューにおけるGitLab Duo {#gitlab-duo-in-issues}

| 機能                                                                                                                          | GitLab Duo Self-Hostedで利用可能         | GitLabバージョン         | ステータス |
| -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [イシュー説明の生成](../../user/project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< icon name="dash-circle" >}}不可  | 該当なし   | 該当なし |
| [ディスカッションサマリー](../../user/discussions/_index.md#summarize-issue-discussions-with-duo-chat)                           | {{< icon name="check-circle-filled" >}}対応 | GitLab 18.1.2以降 | ベータ |

### その他の機能 {#other-features}

| 機能                                                                                                        | GitLab Duo Self-Hostedで利用可能         | GitLabバージョン         | ステータス |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ---------------------- | --- |
| [CLI用GitLab Duo](../../editor_extensions/gitlab_cli/_index.md#gitlab-duo-for-the-cli)                  | {{< icon name="check-circle-filled" >}}対応 | GitLab 18.1.2以降 | ベータ |
| [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)                                                       | {{< icon name="check-circle-filled" >}}対応  | GitLab 18.4以降 | 実験的機能 |
| [脆弱性の修正](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) | {{< icon name="check-circle-filled" >}}対応 | GitLab 18.1.2以降 | ベータ |
| [GitLab DuoとSDLCの傾向ダッシュボード](../../user/analytics/duo_and_sdlc_trends.md)                                             | {{< icon name="check-circle-filled" >}}対応 | GitLab 17.9以降  | ベータ |

## 設定の種類 {#configuration-types}

次のいずれかのオプションを使用して、AIネイティブな機能を実装します:

- **Self-hosted AI gateway and LLMs**: 独自のAIインフラストラクチャを完全に制御するために、独自のAIゲートウェイとモデルを使用します。
- **Hybrid AI gateway and model configuration**: 機能ごとに、セルフホストモデルを使用した独自のセルフホストモデルのAIゲートウェイ、またはGitLab.com AIゲートウェイとGitLab AI AIベンダーモデルを使用します。
- **GitLab.com AI gateway with default GitLab external vendor LLMs**: GitLabが管理するAIインフラストラクチャを使用します。

| 設定                     | セルフホストモデルのAIゲートウェイ                                                        | ハイブリッドAIゲートウェイおよびモデル設定 | GitLab.com AIゲートウェイ                        |
| --------------------------- | ----------------------------------------------------------------------------- | --------------------------------------------------- | -------------------------------------------- |
| インフラストラクチャ要件 | 独自のAIゲートウェイとモデルをホストする必要があります                               | 独自のAIゲートウェイとモデルをホストする必要があります | 追加のインフラストラクチャは不要です          |
| モデルオプション               | [supported self-hosted models](supported_models_and_hardware_requirements.md)から選択 | [supported self-hosted models](supported_models_and_hardware_requirements.md)、または各GitLab Duo機能のGitLab AI AIベンダーモデルから選択します | デフォルトのGitLab AI AIベンダーモデルを使用します |
| ネットワーク要件        | 完全に隔離されたネットワークで動作可能                                        | GitLab AI AIベンダーモデルを使用するGitLab Duo機能には、インターネット接続が必要です | インターネット接続が必要です               |
| 責任            | インフラストラクチャをセットアップし、独自のメンテナンスを行います                   | インフラストラクチャをセットアップし、独自のメンテナンスを行い、どの機能でGitLab AI AIベンダーモデルとAIゲートウェイを使用するかを選択します | GitLabがセットアップとメンテナンスを行います       |

### セルフホストモデルのAIゲートウェイとLLM {#self-hosted-ai-gateway-and-llms}

完全にセルフホストモデルの設定では、独自のAIゲートウェイをデプロイし、GitLabインフラストラクチャまたはAI AIベンダーモデルを使用せずに、インフラストラクチャで[supported LLMs](supported_models_and_hardware_requirements.md)のみを使用します。これにより、データとセキュリティを完全に制御できます。

{{< alert type="note" >}}

この設定には、セルフホストモデルのAIゲートウェイを介して設定されたモデルのみが含まれます。機能に[GitLab AI AIベンダーモデル](configure_duo_features.md#configure-the-feature-to-use-a-gitlab-ai-vendor-model)を使用する場合、これらの機能はセルフホストモデルのゲートウェイではなく、GitLabでホストされているAIゲートウェイに接続されるため、完全にセルフホストモデルではなく、ハイブリッド設定になります。

{{< /alert >}}

独自のAIゲートウェイをデプロイしている間も、[AWS Bedrock](https://aws.amazon.com/bedrock/)や[Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service)のようなクラウドベースのLLMサービスをモデルバックエンドとして使用でき、セルフホストモデルのAIゲートウェイを介して接続し続けることができます。

インターネットアクセスを防止または制限する物理的な障壁またはセキュリティポリシーがあり、包括的なLLM制御があるオフライン環境がある場合は、この完全にセルフホストモデルの設定を使用する必要があります。

ライセンスの場合、GitLab PremiumまたはUltimateプランのサブスクリプション、および[GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)が必要です。完全に隔離されたオフライン環境を持つお客様には、オフラインエンタープライズライセンスをご利用いただけます。購入したサブスクリプションにアクセスするには、[GitLabカスタマーポータル](../../subscriptions/billing_account.md)からライセンスをリクエストしてください。

詳細については、以下を参照してください: 

- [GitLab Duo Self-Hostedインフラストラクチャをセットアップする](#set-up-a-gitlab-duo-self-hosted-infrastructure)
- [セルフホストモデルのAIゲートウェイ設定図](configuration_types.md#self-hosted-ai-gateway)。

### ハイブリッドAIゲートウェイとモデル設定 {#hybrid-ai-gateway-and-model-configuration}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/17192) GitLab 18.3では、[ベータ](../../policy/development_stages_support.md#beta)と[機能フラグ](../feature_flags/_index.md)という名前の`ai_self_hosted_vendored_features`。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

このハイブリッド設定では、ほとんどの機能で独自のAIゲートウェイとセルフホストモデルをデプロイしますが、特定の機能を使用するように設定して、GitLab AI AIベンダーモデルを使用します。機能がGitLab AI AIベンダーモデルを使用するように設定されている場合、その機能へのリクエストは、セルフホストモデルのAIゲートウェイではなく、GitLabでホストされているAIゲートウェイに送信されます。

このオプションは、次のことを可能にすることで柔軟性を提供します:

- 完全に制御したい機能には、独自のセルフホストモデルを使用します。
- GitLabがキュレーションしたモデルを優先する場合は、特定の機能にGitLabが管理するベンダーモデルを使用します。

{{< alert type="warning" >}}

機能がGitLab AI AIベンダーモデルを使用するように設定されている場合:

- これらの機能へのすべての呼び出しは、セルフホストモデルのAIゲートウェイではなく、GitLabでホストされているAIゲートウェイを使用します。
- これらの機能にはインターネット接続が必要です。
- これは、完全にセルフホストモデルまたは隔離された設定ではありません。

{{< /alert >}}

ライセンスの場合、GitLab PremiumまたはUltimateプランのサブスクリプション、および[GitLab Duo Enterprise](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)が必要です。この設定を使用するためのオフラインライセンスはサポートされていません。購入したサブスクリプションにアクセスするには、[GitLabカスタマーポータル](../../subscriptions/billing_account.md)からライセンスをリクエストしてください。

詳細については、以下を参照してください: 

- [GitLab AI AIベンダーモデルを設定する](configure_duo_features.md#configure-the-feature-to-use-a-gitlab-ai-vendor-model)

#### GitLabが管理するモデル {#gitlab-managed-models}

GitLabが管理するモデルを使用して、インフラストラクチャをセルフホストモデルにする必要なく、AIモデルに接続します。これらのモデルは、GitLabによって完全に管理されます。

AIネイティブな機能で使用するデフォルトのGitLabモデルを選択できます。デフォルトのモデルの場合、GitLabは可用性、品質、信頼性に基づいて最適なモデルを使用します。機能に使用されるモデルは、予告なしに変更される場合があります。

特定のGitLab管理モデルを選択すると、その機能へのすべてのリクエストでそのモデルが排他的に使用されます。モデルが利用できなくなった場合、AIゲートウェイへのリクエストは失敗し、別のモデルが選択されるまで、ユーザーはその機能を使用できません。

{{< alert type="note" >}}

機能を使用するように設定するとGitLab管理モデル:

- これらの機能への呼び出しは、セルフホストモデルのAIゲートウェイではなく、GitLabでホストされているAIゲートウェイを使用します。
- これらの機能にはインターネット接続が必要です。
- この設定は、完全にセルフホストモデルまたは隔離されていません。

{{< /alert >}}

### デフォルトのGitLab外部ベンダーLLMを備えたGitLab.com AIゲートウェイ {#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。

{{< /details >}}

GitLab Duo Self-Hostedのユースケース基準を満たしていない場合は、デフォルトのGitLab外部ベンダーLLMでGitLab.com AIゲートウェイを使用できます。

GitLab.com AIゲートウェイはデフォルトのエンタープライズ製品であり、セルフホストモデルではありません。この設定では、インスタンスをGitLabがホストするAIゲートウェイに接続します。これは、次のものを含む外部ベンダーLLMプロバイダーと統合されます:

- [Anthropic](https://www.anthropic.com/)
- [Fireworks AI](https://fireworks.ai/)
- [Google Vertex](https://cloud.google.com/vertex-ai/)

これらのLLMはGitLab Cloud Connectorを介して通信し、オンプレミスインフラストラクチャを必要とせずに、すぐに使用できるAIソリューションを提供します。

詳細については、[GitLab.com AIゲートウェイ設定図](configuration_types.md#gitlabcom-ai-gateway)を参照してください。

このインフラストラクチャをセットアップするには、[Self-ManagedインスタンスでGitLab Duoを設定する方法](../../user/gitlab_duo/setup.md)を参照してください。

## GitLab Duo Self-Hostedインフラストラクチャをセットアップする {#set-up-a-gitlab-duo-self-hosted-infrastructure}

完全に隔離されたGitLab Duo Self-Hostedインフラストラクチャをセットアップするには:

1. 大規模言語モデル（LLM）サービスインフラストラクチャをインストールします。

   - GitLabは、vLLM、AWS Bedrock、およびAzure OpenAIなど、LLMのサービスとホスティングのためのさまざまなプラットフォームをサポートしています。各プラットフォームの詳細については、[supported LLM platforms documentation](supported_llm_serving_platforms.md)を参照してください。

   - GitLabは、特定の機能とハードウェア要件を備えた、サポートされているモデルのマトリックスを提供します。詳細については、[supported models and hardware requirements documentation](supported_models_and_hardware_requirements.md)を参照してください。

1. AIネイティブなGitLab Duo機能にアクセスするには、[AIゲートウェイをインストール](../../install/install_ai_gateway.md)します。

1. 機能がセルフホストモデルにアクセスできるように、[GitLabインスタンスを設定する](configure_duo_features.md)。

1. システムのパフォーマンスを追跡および管理するには、[ロギングを有効にする](logging.md)。

## 関連トピック {#related-topics}

- [トラブルシューティング](troubleshooting.md)
- [GitLab AIゲートウェイをインストールする](../../install/install_ai_gateway.md)
- [Supported models](supported_models_and_hardware_requirements.md)
- [GitLab Duo Self-Hosted supported platforms](supported_llm_serving_platforms.md)
