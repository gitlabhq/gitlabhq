---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabインスタンスを構成して、GitLab Duo Self-Hostedを使用します。
title: GitLabを構成してGitLab Duo Self-Hostedにアクセスする
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6の[GitLab Self-Managed](https://gitlab.com/groups/gitlab-org/-/epics/15176)で有効になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.8で機能フラグ`ai_custom_model`は削除されました。
- UIを使用したAIゲートウェイURLの設定機能が、GitLab 17.9で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/473143)されました。
- GitLab 17.9で一般提供となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

前提要件: 

- [GitLabをバージョン17.9以降にアップグレード](../../update/_index.md)。

インフラストラクチャ内の利用可能なセルフホストモデルにアクセスするようにGitLabインスタンスを構成するには:

1. [完全にセルフホストの設定が、ユースケースに適していることを確認してください](_index.md#configuration-types)。
1. AIゲートウェイにアクセスするようにGitLabインスタンスを構成します。
1. GitLab 18.4以降では、GitLabインスタンスを構成してGitLab Duo Agent Platformサービスにアクセスします。
1. セルフホストモデルを構成します。
1. セルフホストモデルを使用するようにGitLab Duo機能を構成します。

## AIゲートウェイにアクセスするようにGitLabインスタンスを構成する {#configure-your-gitlab-instance-to-access-the-ai-gateway}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **ローカルAIゲートウェイURL**に、AIゲートウェイURLを入力します。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

AIゲートウェイURLがローカルネットワークまたはプライベートIPアドレス（たとえば、`172.31.x.x`、または`ip-172-xx-xx-xx.region.compute.internal`のような内部ホスト名）を指している場合、セキュリティ上の理由から、GitLabがリクエストをブロックする可能性があります。このアドレスへのリクエストを許可するには、[アドレスをIP許可リストに追加します](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)。

{{< /alert >}}

## GitLab Duo Agent Platformへのアクセスを構成する {#configure-access-to-the-gitlab-duo-agent-platform}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.4で、`self_hosted_agent_platform`という[機能フラグ](../feature_flags/_index.md)を持つ[実験](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLabインスタンスからAgent PlatformサービスにアクセスするためのURLを提供する必要があります。

- Agent PlatformサービスのURLのプレフィックスは、`http://`または`https://`で始めることはできません。

- Agent PlatformサービスのURLがTLSでセットアップされていない場合は、GitLabインスタンスで`DUO_AGENT_PLATFORM_SERVICE_SECURE`環境変数を設定する必要があります:

  - Linuxパッケージインストールの場合、`gitlab_rails['env']`で`'DUO_AGENT_PLATFORM_SERVICE_SECURE' => false`を設定します。
  - セルフコンパイルインストールの場合、`/etc/default/gitlab`で`export DUO_AGENT_PLATFORM_SERVICE_SECURE=false`を設定します。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duo Agent PlatformサービスのローカルURL**に、ローカルAgent PlatformサービスのURLを入力します。
1. **変更を保存**を選択します。

## セルフホストモデルを構成する {#configure-the-self-hosted-model}

前提要件: 

- 管理者である必要があります。
- PremiumまたはUltimateのライセンスが必要です。
- GitLab Duo Enterpriseライセンスアドオンが必要です。

セルフホストモデルを構成するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
   - **GitLab Duo Self-Hostedの設定**ボタンが使用できない場合は、購入後にサブスクリプションを同期してください:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最後の同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **セルフホストモデルの追加**を選択します。
1. フィールドに入力します:
   - **デプロイ名**: モデルデプロイを識別子で一意に識別するための名前を入力します。例：`Mixtral-8x7B-it-v0.1 on GCP`。
   - **モデルファミリー**: デプロイが属するモデルファミリーを選択します。次のいずれかを選択できます:

     - [サポートされているモデルファミリー](supported_models_and_hardware_requirements.md#supported-models)。
     - **一般**を選択して、GitLabで明示的にサポートされていない[独自のモデルを使用](supported_models_and_hardware_requirements.md#compatible-models)します。
   - **エンドポイント**: モデルがホストされているURLを入力します。
     - vLLMを介してデプロイされたモデルのエンドポイントの設定の詳細については、[vLLMドキュメント](supported_llm_serving_platforms.md#endpoint-configuration)を参照してください。
   - **APIキー**: オプション。モデルにアクセスするために必要な場合は、APIキーを追加します。
   - **モデルの識別子**: これは必須フィールドです。このフィールドの値は、デプロイ方法に基づいており、次の構造と一致する必要があります:

     | デプロイ方法 | 形式 | 例 |
     |-------------|---------|---------|
     | vLLM | `custom_openai/<name of the model served through vLLM>` | `custom_openai/Mixtral-8x7B-Instruct-v0.1` |
     | Bedrock | `bedrock/<model ID of the model>` | `bedrock/mistral.mixtral-8x7b-instruct-v0:1` |
     | Azure OpenAI | `azure/<model ID of the model>` | `azure/gpt-35-turbo` |

     - Amazon Bedrockモデルの場合:

       1. `AWS_REGION`を設定し、AIゲートウェイDockerの設定で、そのリージョンのモデルにアクセスできることを確認してください。
       1. リージョン間推論のために、適切なリージョンのプレフィックスをモデルの推論プロファイルIDに追加します。
       1. リージョンのプレフィックスとモデル推論プロファイルIDを**モデルの識別子**フィールドに、`bedrock/`プレフィックスとともに入力します。

       たとえば、東京リージョンのAnthropic Claude 3.5 v2モデルの場合:

       - `AWS_REGION`は`ap-northeast-1`です。
       - リージョン間推論プレフィックスは`apac.`です。
       - モデル識別子は`bedrock/apac.anthropic.claude-3-5-sonnet-20241022-v2:0`です。

       一部のリージョンは、リージョン間推論ではサポートされていません。これらのリージョンでは、モデル識別子はリージョンのプレフィックスなしで指定する必要があります。次に例を示します: 

       - `AWS_REGION`は`eu-west-2`です。
       - モデル識別子は`bedrock/anthropic.claude-3-7-sonnet-20250219-v1:0`にする必要があります。

1. **セルフホストモデルの作成**を選択します。

詳細については、以下をご覧ください:

- vLLMを介してデプロイされたモデルのモデル識別子の設定については、[vLLMドキュメント](supported_llm_serving_platforms.md#find-the-model-name)を参照してください。
- リージョン間推論を使用したAmazon Bedrockモデルの設定については、[推論プロファイルのドキュメントでAmazonがサポートしているリージョンとモデル](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-support.html)を参照してください

## ベータのセルフホストモデルと機能を構成する {#configure-self-hosted-beta-models-and-features}

前提要件: 

- 管理者である必要があります。
- PremiumまたはUltimateのライセンスが必要です。
- GitLab Duo Enterpriseライセンスアドオンが必要です。

[ベータ](../../policy/development_stages_support.md#beta)セルフホストモデルと機能を有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **ベータ版のセルフホスト型モデルと機能**で、**GitLab Duo Self-Hostedでベータ版のモデルおよび機能を使用する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

ベータのセルフホストモデルと機能をオンにすると、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)にも同意したことになります。

{{< /alert >}}

## セルフホストモデルを使用するようにGitLab Duo機能を構成する {#configure-gitlab-duo-features-to-use-self-hosted-models}

前提要件: 

- 管理者である必要があります。
- PremiumまたはUltimateのライセンスが必要です。
- GitLab Duo Enterpriseライセンスアドオンが必要です。

### 構成された機能を表示する {#view-configured-features}

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
   - **GitLab Duo Self-Hostedの設定**ボタンが使用できない場合は、購入後にサブスクリプションを同期してください:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最後の同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **AIネイティブ機能**タブを選択します。

### セルフホストモデルを使用するように機能を構成する {#configure-the-feature-to-use-a-self-hosted-model}

構成済みのセルフホストモデルにクエリを送信するように、GitLab Duo機能とサブ機能を構成します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
1. **AIネイティブ機能**タブを選択します。
1. 設定する機能とサブ機能について、ドロップダウンリストから、使用するセルフホストモデルを選択します。

   たとえば、GitLab Duoコード提案のコード生成サブ機能の場合は、**Claude-3 on Bedrock deployment (Claude 3)**（BedrockデプロイのClaude-3 (Claude 3)）を選択できます。

   ![GitLab Duo Self-Hostedの機能の設定](img/gitlab_duo_self_hosted_feature_configuration_v17_11.png)

### GitLab AIベンダーモデルを使用するように機能を構成する {#configure-the-feature-to-use-a-gitlab-ai-vendor-model}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.3で、`ai_self_hosted_vendored_features`という[機能フラグ](../feature_flags/_index.md)を持つ[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/17192)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab 18.3以降では、セルフホストのAIゲートウェイとモデルを使用している場合でも、特定のGitLab Duo機能を構成してGitLab AIベンダーモデルを使用できます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
1. **AIネイティブ機能**タブを選択します。
1. 設定する機能とサブ機能について、ドロップダウンリストから**GitLab AIベンダーモデル**を選択します。

   たとえば、GitLab Duoコード提案のコード生成サブ機能の場合は、**GitLab AIベンダーモデル**を選択できます。

   ![GitLab AIベンダーモデルを使用したGitLab Duo Self-Hostedの機能の設定](img/gitlab_duo_self_hosted_feature_configuration_with_vendored_model_v18_3.png)

このハイブリッド設定の詳細については、[GitLab Duo Self-Hostedの設定タイプ](_index.md#configuration-types)に関するドキュメントを参照してください。

### GitLab Duoチャットサブ機能のフォールバック設定 {#gitlab-duo-chat-sub-feature-fall-back-configuration}

GitLab Duoチャットサブ機能を設定するときに、サブ機能に特定のモデルを選択しない場合、そのサブ機能は自動的にフォールバックして、**General Chat**（一般チャット）に設定されているモデルを使用します。これにより、各サブ機能を独自のモデルで明示的に設定していなくても、すべてのチャット機能が動作することが保証されます。

### GitLabドキュメントをセルフホストする {#self-host-the-gitlab-documentation}

GitLab Duo Self-Hostedのセットアップによって`docs.gitlab.com`でGitLabドキュメントにアクセスできなくなった場合は、代わりにドキュメントをセルフホストできます。詳細については、[GitLab製品ドキュメントをホストする方法](../docs_self_host.md)を参照してください。

### GitLab Duo機能を無効にする {#disable-gitlab-duo-features}

機能を無効にするには、機能またはサブ機能を設定するときに、明示的に**無効**を選択する必要があります。

- サブ機能のモデルを選択しないだけでは不十分です。
- チャットサブ機能の場合、モデルを選択しないと、そのサブ機能は[**General Chat**（一般チャット）に設定されているモデルを使用するようにフォールバック](#gitlab-duo-chat-sub-feature-fall-back-configuration)します。

GitLab Duo機能またはサブ機能を無効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
1. **AIネイティブ機能**タブを選択します。
1. 無効にする機能またはサブ機能について、ドロップダウンリストから**無効**を選択します。

   たとえば、`Write Test`機能と`Refactor Code`機能を明確に無効にするには、**無効**を選択します:

   ![GitLab Duo機能を無効にする](img/gitlab_duo_self_hosted_disable_feature_v17_11.png)
