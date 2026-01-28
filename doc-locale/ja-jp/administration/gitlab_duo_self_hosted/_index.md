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
- GitLab 17.6の[GitLab Self-Managedで有効](https://gitlab.com/groups/gitlab-org/-/epics/15176)になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- 機能フラグ`ai_custom_model`は、GitLab 17.8で削除されました。
- GitLab 17.9で一般提供となりました。
- GitLab 18.0でPremiumを含むように変更されました。

{{< /history >}}

GitLab Duo Self-Hostedを使用すると、独自の大規模言語モデル（LLM）をGitLab Duo機能と統合し、データのプライバシーとセキュリティを管理できます。

GitLab Duo Self-Hostedでできること:

- GitLabでサポートされている任意のLLM、または互換性のある独自モデルを選択する。
- ユーザー向けに特定のGitLab Duo機能を選択する。
- 外部APIコールなしで、すべてのリクエスト/レスポンスログをドメインに保持する。
- 独自の環境でGitLabインスタンス、AIゲートウェイ、モデルを分離します。
- 共有AIゲートウェイへの依存をなくします。
- GitLab Duo機能のLLMバックエンドへのリクエストのライフサイクルを管理し、外部依存関係を回避して、リクエストを企業ネットワーク内にとどめる。

クリックスルーデモについては、[GitLab Duo Self-Hosted製品ツアー](https://gitlab.navattic.com/gitlab-duo-self-hosted)を参照してください。
<!-- Demo published on 2025-02-13 -->

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab Duo Self-Hosted: AI in your private environment](https://youtu.be/TQoO3sFnb28?si=uD-ps6aRnE28xNv3)をご覧ください。
<!-- Video published on 2025-02-20 -->

## 前提条件 {#prerequisites}

- クラウドベースまたはオンプレミスでサポートされているモデルを用意します。
- クラウドベースまたはオンプレミスでサポートされているサービスプラットフォームを用意します。
- ローカルでホストされているAIゲートウェイを用意します。

## サポート対象のGitLab Duo機能 {#supported-gitlab-duo-features}

次の表に一覧を示します:

- GitLab Duo Self-HostedでサポートされているGitLab Duoの機能。
- GitLab Duo Self-Hostedで機能を使用するために必要なGitLabバージョン。
- 機能のステータス。GitLab Duo Self-Hostedの機能のステータスは、[機能の概要](../../user/gitlab_duo/feature_summary.md)に記載されているステータスと異なる場合があります。

{{< alert type="note" >}}

GitLab Duo Self-Hostedでこれらの機能を使用するには、GitLab Duo Enterpriseアドオンが必要です。GitLabがクラウドベースの[AIゲートウェイ](../../administration/gitlab_duo/gateway.md)を介してこれらのモデルをホストおよび接続する場合、GitLab Duo CoreまたはGitLab Duo Proでこれらの機能を使用できる場合でも、これは適用されます。

{{< /alert >}}

| 機能                                                                                                                                | GitLabバージョン          | ステータス              |
|----------------------------------------------------------------------------------------------------------------------------------------|-------------------------|---------------------|
| [コード提案](../../user/project/repository/code_suggestions/_index.md)                                                           | GitLab 17.9以降   | 一般提供 |
| [GitLab Duo Chat（クラシック）](../../user/gitlab_duo_chat/_index.md)                                                                      | GitLab 17.9以降   | 一般提供 |
| [コード説明](../../user/gitlab_duo_chat/examples.md#explain-selected-code)                                                       | GitLab 17.9以降   | 一般提供 |
| [テスト生成](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)                                                       | GitLab 17.9以降   | 一般提供 |
| [コードのリファクタリング](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)                                                       | GitLab 17.9以降   | 一般提供 |
| [コード修正](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)                                                                 | GitLab 17.9以降   | 一般提供 |
| [コードレビュー](../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)                             | GitLab 18.3以降   | 一般提供 |
| [根本原因分析](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)                   | GitLab 17.10以降  | ベータ版                |
| [脆弱性の説明](../../user/application_security/vulnerabilities/_index.md#vulnerability-explanation)                       | GitLab 18.1.2以降 | ベータ版                |
| [マージコミットメッセージ生成](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)          | GitLab 18.1.2以降 | ベータ版                |
| [マージリクエストサマリー](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | GitLab 18.1.2以降 | ベータ版                |
| [ディスカッションサマリー](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)                                | GitLab 18.1.2以降 | ベータ版                |
| [CLI用GitLab Duo](https://docs.gitlab.com/cli/)                                                                                 | GitLab 18.1.2以降 | ベータ版                |
| [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md)                                                                   | GitLab 18.4以降   | ベータ版                |
| [脆弱性の修正](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)                         | GitLab 18.1.2以降 | ベータ版                |
| [GitLab DuoとSDLCの傾向ダッシュボード](../../user/analytics/duo_and_sdlc_trends.md)                                                    | GitLab 17.9以降   | ベータ版                |
| [コードレビューサマリー](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)                              | GitLab 18.1.2以降 | 実験的機能          |

## 構成タイプ {#configuration-types}

AI機能を実装するには、以下のオプションのいずれかを使用します:

- **Self-hosted AI Gateway and LLMs**: 独自のAIインフラストラクチャを完全に制御するために、独自のAIゲートウェイとモデルを使用します。
- **Hybrid AI Gateway and model configuration**: 機能ごとに、セルフホストAIゲートウェイとセルフホストモデル、またはGitLab.com AIゲートウェイとGitLab AIベンダーモデルのいずれかを使用します。
- **GitLab.com AI Gateway with default GitLab external vendor LLMs**: GitLabが管理するAIインフラストラクチャを使用します。

| 構成                     | セルフホストAIゲートウェイ                                                        | ハイブリッドAIゲートウェイとモデル設定 | GitLab.com AIゲートウェイ                        |
| --------------------------- | ----------------------------------------------------------------------------- | --------------------------------------------------- | -------------------------------------------- |
| インフラストラクチャ要件 | 独自のAIゲートウェイとモデルをホストする必要があります                               | 独自のAIゲートウェイとモデルをホストする必要があります | 追加のインフラストラクチャは不要          |
| モデルオプション               | [サポート対象のセルフホストモデル](supported_models_and_hardware_requirements.md)から選択 | [サポート対象のセルフホストモデル](supported_models_and_hardware_requirements.md)、または各GitLab Duo機能のGitLab AIベンダーモデルから選択 | デフォルトのGitLab AIベンダーモデルを使用します |
| ネットワーク要件        | 完全に隔離されたネットワークで動作可能                                        | GitLab AIベンダーモデルを使用するGitLab Duo機能にはインターネット接続が必要 | インターネット接続が必要               |
| 責任            | インフラストラクチャのセットアップと独自のメンテナンスを実施                   | インフラストラクチャをセットアップし、独自のメンテナンスを行い、どの機能でGitLab AIベンダーモデルとAIゲートウェイを使用するかを選択します | GitLabがセットアップとメンテナンスを実施       |

### セルフホストAIゲートウェイとLLM {#self-hosted-ai-gateway-and-llms}

完全にセルフホストされた構成では、独自のAIゲートウェイをデプロイし、GitLabインフラストラクチャまたはAIベンダーモデルを使用せずに、インフラストラクチャでサポートされている[LLM](supported_models_and_hardware_requirements.md)のみを使用します。これにより、データとセキュリティを完全に制御できます。

> [!note]この構成には、セルフホストAIゲートウェイを介して構成されたモデルのみが含まれます。機能に[GitLab AIベンダーモデル](configure_duo_features.md#configure-a-feature-to-use-a-gitlab-ai-vendor-model)を使用する場合、これらの機能はセルフホストゲートウェイの代わりにGitLabでホストされているAIゲートウェイに接続されるため、完全にセルフホストされるのではなく、ハイブリッド構成になります。

独自のAIゲートウェイをデプロイする一方で、モデルバックエンドとして、[AWS Bedrock](https://aws.amazon.com/bedrock/)や[Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service)のようなクラウドベースのLLMサービスを引き続き使用でき、セルフホストAIゲートウェイ経由で接続し続けることができます。

インターネットアクセスを防止または制限する物理的な障壁やセキュリティポリシーがあるオフライン環境で、包括的なLLM制御が必要な場合は、この完全なセルフホスト設定を使用する必要があります。

詳細については、以下を参照してください: 

- [GitLab Duo Self-Hostedインフラストラクチャをセットアップする](#set-up-a-gitlab-duo-self-hosted-infrastructure)
- [セルフホストAIゲートウェイ構成図](configuration_types.md#self-hosted-ai-gateway)。

### ハイブリッドAIゲートウェイとモデル設定 {#hybrid-ai-gateway-and-model-configuration}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- `ai_self_hosted_vendored_features`[フラグ](../feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)機能として、GitLab 18.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/17192)されました。デフォルトでは無効になっています。
- [デフォルト（GitLab 18.7）](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030)

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

このハイブリッド構成では、ほとんどの機能について独自のAIゲートウェイとセルフホストモデルをデプロイしますが、特定の機能でGitLab AIベンダーモデルを使用するように構成します。機能がGitLab AIベンダーモデルを使用するように構成されている場合、その機能のリクエストは、セルフホストAIゲートウェイではなく、GitLabでホストされているAIゲートウェイに送信されます。

このオプションは、以下を可能にすることで柔軟性を提供します:

- 完全な制御が必要な機能には独自のセルフホスティング型モデルを使用する。
- GitLabがキュレーションしたモデルを優先する特定の機能には、GitLab管理のベンダーモデルを使用する。

{{< alert type="warning" >}}

機能がGitLab AIベンダーモデルを使用するように設定されている場合:

- これらの機能へのすべての呼び出しは、セルフホストAIゲートウェイではなく、GitLabでホストされているAIゲートウェイを使用します。
- これらの機能にはインターネット接続が必要です。
- これは、完全にセルフホストまたは隔離された設定ではありません。

{{< /alert >}}

詳細については、以下を参照してください: 

- [GitLab AIベンダーモデルを設定する](configure_duo_features.md#configure-a-feature-to-use-a-gitlab-ai-vendor-model)

#### GitLab管理モデル {#gitlab-managed-models}

GitLab管理モデルを使用すると、インフラストラクチャをセルフホストすることなくAIモデルに接続できます。これらのモデルは、GitLabによって完全に管理されます。

AIネイティブ機能で使用するデフォルトのGitLabモデルを選択できます。デフォルトモデルの場合、GitLabは可用性、品質、信頼性に基づいて最適なモデルを使用します。機能に使用されるモデルは、予告なく変更される場合があります。

特定のGitLab管理モデルを選択すると、その機能のすべてのリクエストはそのモデルのみを使用します。モデルが利用できなくなった場合、AIゲートウェイへのリクエストは失敗し、別のモデルが選択されるまで、ユーザーはその機能を使用できません。

{{< alert type="note" >}}

GitLab管理モデルを使用するように機能を設定する場合:

- これらの機能への呼び出しは、セルフホストAIゲートウェイではなく、GitLabでホストされているAIゲートウェイを使用します。
- これらの機能にはインターネット接続が必要です。
- この設定は、完全なセルフホストまたは隔離された構成ではありません。

{{< /alert >}}

### GitLab.com AIゲートウェイとデフォルトのGitLab外部ベンダーLLM {#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise

{{< /details >}}

GitLab Duo Self-Hostedのユースケースの基準を満たしていない場合は、デフォルトのGitLab外部ベンダーLLMでGitLab.com AIゲートウェイを使用できます。

GitLab.com AIゲートウェイは、デフォルトのエンタープライズ製品であり、セルフホストされていません。この構成では、インスタンスをGitLabでホストされているAIゲートウェイに接続します。このゲートウェイは、次の外部ベンダーLLMプロバイダーと統合されています:

- [Anthropic](https://www.anthropic.com/)
- [Fireworks AI](https://fireworks.ai/)
- [Google Vertex](https://cloud.google.com/vertex-ai/)

これらのLLMはGitLab Cloud Connectorを介して通信し、オンプレミスインフラストラクチャを必要とせずに、すぐに使用できるAIソリューションを提供します。

詳細については、[GitLab.com AIゲートウェイ構成図](configuration_types.md#gitlabcom-ai-gateway)を参照してください。

このインフラストラクチャをセットアップするには、[Self-ManagedインスタンスでGitLab Duoを設定する方法](../../administration/gitlab_duo/configure/gitlab_self_managed.md)を参照してください。

## GitLab Duo Self-Hostedインフラストラクチャをセットアップする {#set-up-a-gitlab-duo-self-hosted-infrastructure}

完全に隔離されたGitLab Duo Self-Hostedインフラストラクチャをセットアップするには:

1. 大規模言語モデル（LLM）サービスインフラストラクチャをインストールします。

   - GitLabは、vLLM、AWS Bedrock、およびAzure OpenAIなど、LLMの提供とホスティングのためのさまざまなプラットフォームをサポートしています。各プラットフォームの詳細については、[サポートされているLLMプラットフォームのドキュメント](supported_llm_serving_platforms.md)を参照してください。

   - GitLabは、特定の機能とハードウェア要件を備えたサポート対象モデルのマトリックスを提供しています。詳細については、[サポートされているモデルとハードウェア要件](supported_models_and_hardware_requirements.md)を参照してください。

1. [AI](../../install/install_ai_gateway.md)ゲートウェイをインストールして、AIネイティブなGitLab Duoの機能にアクセスします。

1. 機能がセルフホストモデルにアクセスできるように、[GitLabインスタンスを設定](configure_duo_features.md)します。

1. システムのパフォーマンスを追跡および管理するには、[ロギングを有効](logging.md)にします。

## 関連トピック {#related-topics}

- [トラブルシューティング](troubleshooting.md)
- [GitLab AIゲートウェイをインストール](../../install/install_ai_gateway.md)
- [サポート対象モデル](supported_models_and_hardware_requirements.md)
- [GitLab Duo Self-Hostedのサポート対象プラットフォーム](supported_llm_serving_platforms.md)
