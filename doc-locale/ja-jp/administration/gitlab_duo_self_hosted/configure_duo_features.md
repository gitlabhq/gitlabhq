---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabインスタンスを設定してGitLab Duo Self-Hostedを使用します。
title: GitLab Duo Self-HostedにアクセスするようにGitLabを設定する
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
- UIを使用したAIゲートウェイURLの設定機能がGitLab 17.9で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/473143)されました。
- GitLab 17.9で一般提供となりました。
- GitLab 18.0でPremiumを含むように変更されました。

{{< /history >}}

前提条件: 

- [GitLabをバージョン17.9以降にアップグレード](../../update/_index.md)してください。
- 管理者である必要があります。

インフラストラクチャ内の利用可能なセルフホストモデルにアクセスするようにGitLabインスタンスを設定するには:

1. [完全なセルフホスト設定が、ユースケースに適していることを確認](_index.md#configuration-types)します。
1. AIゲートウェイにアクセスするようにGitLabインスタンスを構成します。
1. GitLab 18.4以降では、GitLab Duo Agent PlatformサービスにアクセスするようにGitLabインスタンスを設定します。
1. セルフホストモデルを設定します。
1. セルフホストモデルを使用するようにGitLab Duo機能を設定します。

## ローカルAIゲートウェイへのアクセスを設定する {#configure-access-to-the-local-ai-gateway}

GitLabインスタンスとローカルAIゲートウェイ間のアクセスを設定するには、次の手順を実行します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **ローカルAIゲートウェイURL**に、AIゲートウェイURLを入力します。
1. **変更を保存**を選択します。

> [!note] AIゲートウェイのURLがローカルネットワークまたはプライベートIPアドレス（`172.31.x.x`や`ip-172-xx-xx-xx.region.compute.internal`のような内部ホスト名）を指している場合、セキュリティ上の理由からGitLabがリクエストをブロックする可能性があります。このアドレスへのリクエストを許可するには、[アドレスをIP許可リストに追加](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)します。

## AIゲートウェイのタイムアウトを設定する {#configure-timeout-for-the-ai-gateway}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/567878)されました。

{{< /history >}}

リソースを節約し、長時間実行されるクエリを防ぐために、モデル応答を待機する際に、GitLabからAIゲートウェイへのリクエストのタイムアウトを設定します。コンテキストウィンドウが大きい、または複雑なクエリを使用するセルフホストモデルには、より長いタイムアウトを使用します。

タイムアウトは60秒から600秒（10分）の間で設定できます。タイムアウトを設定しない場合、GitLabはデフォルトのタイムアウトである60秒を使用します。

AIゲートウェイのタイムアウトを設定するには、次の手順に従います:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **AIゲートウェイリクエストのタイムアウト**で、タイムアウトの値を秒単位（60～600秒）で入力します。
1. **変更を保存**を選択します。

### タイムアウトの値を決定する {#determine-the-timeout-value}

タイムアウトの値は、特定のデプロイおよびユースケースによって異なります。

タイムアウトの値を決定するには、次の手順に従います:

- デフォルトのタイムアウトである60秒から始めて、タイムアウトエラーを監視します。
- ログで`A1000`タイムアウトエラーを監視します。これらのエラーが頻繁に発生する場合は、タイムアウトの増加を検討してください。
- ユースケースを検討してください。より大きなプロンプト、複雑なコード生成タスク、または大規模な設計ドキュメントの処理には、より長いタイムアウトが必要になる場合があります。
- インフラストラクチャを検討してください。モデルのパフォーマンスは、利用可能なGPUリソース、AIゲートウェイとモデルエンドポイント間のネットワークレイテンシー、およびモデルの処理機能によって異なります。
- 段階的に増やします。タイムアウトが発生した場合は、値を徐々に増やし（たとえば、30〜60秒単位で）、結果を監視します。

タイムアウトエラーのトラブルシューティングの詳細については、[エラーA1000](troubleshooting.md#error-a1000)を参照してください。

## GitLab Duo Agent Platformへのアクセスを設定する {#configure-access-to-the-gitlab-duo-agent-platform}

{{< history >}}

- GitLab 18.4で`self_hosted_agent_platform`[機能フラグ](../feature_flags/_index.md)とともに[実験的機能](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)されました。デフォルトでは無効になっています。
- GitLab 18.5で実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/558083)。
- GitLab 18.7で[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)になりました。
- GitLab 18.8で[一般提供](https://gitlab.com/groups/gitlab-org/-/work_items/19125)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

前提条件: 

- セルフホストモデルのベータ版と機能は[オン](#turn-on-self-hosted-beta-models-and-features)になっています。

GitLabインスタンスからエージェントプラットフォームサービスにアクセスするには、次の手順を実行します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duo Agent PlatformサービスのローカルURL**に、ローカルAgent PlatformサービスのURLを入力します。
   - URLのプレフィックスを`http://`または`https://`で始めることはできません。

   - URLがTLSで設定されていない場合は、GitLabインスタンスで`DUO_AGENT_PLATFORM_SERVICE_SECURE`環境変数を設定する必要があります:

     - Linuxパッケージインストールの場合、`gitlab_rails['env']`で`'DUO_AGENT_PLATFORM_SERVICE_SECURE' => false`を設定します
     - セルフコンパイルインストールの場合、`/etc/default/gitlab`内で`export DUO_AGENT_PLATFORM_SERVICE_SECURE=false`を設定します
1. **変更を保存**を選択します。

## セルフホストモデルを追加する {#add-a-self-hosted-model}

GitLab Duo機能で使用するには、セルフホストモデルをGitLabインスタンスに追加する必要があります。

セルフホストモデルを追加するには、次の手順を実行します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
   - **GitLab Duo Self-Hostedの設定**が利用できない場合は、購入後にサブスクリプションを同期します:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最終同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **セルフホストモデルの追加**を選択します。
1. フィールドに入力します:
   - **デプロイ名**: モデルデプロイを一意に識別する名前を入力します。例 `Mixtral-8x7B-it-v0.1 on GCP`。
   - **モデルファミリー**: デプロイが属するモデルファミリーを選択します。サポートされているモデルまたは互換性のあるモデルを選択できます。
   - **エンドポイント**: モデルがホストされているURLを入力します。
   - **APIキー**: オプション。モデルにアクセスするために必要な場合は、APIキーを追加します。
   - **モデル識別子**: デプロイ方法に基づいてモデル識別子を入力します。モデル識別子は、次の形式と一致する必要があります:

     | デプロイ方法 | 形式 | 例 |
     |-------------|---------|---------|
     | [vLLM](supported_llm_serving_platforms.md#find-the-model-name)        | `custom_openai/<name of the model served through vLLM>` | `custom_openai/Mixtral-8x7B-Instruct-v0.1` |
     | [Amazon Bedrock](#set-the-model-identifier-for-amazon-bedrock-models) | `bedrock/<model ID of the model>`                       | `bedrock/mistral.mixtral-8x7b-instruct-v0:1` |
     | Azure OpenAI                                                          | `azure/<model ID of the model>`                         | `azure/gpt-35-turbo` |

1. **セルフホストモデルの作成**を選択します。

### Amazon Bedrockモデルのモデル識別子を設定する {#set-the-model-identifier-for-amazon-bedrock-models}

Amazon Bedrockモデルのモデル識別子を設定するには、次の手順を実行します:

1. `AWS_REGION`を設定します。AIゲートウェイDocker設定で、そのリージョンのモデルへのアクセス権があることを確認します。
1. リージョン間推論のために、モデルの推論プロファイルIDにリージョンプレフィックスを追加します。
1. `bedrock/`プレフィックスリージョンをモデル識別子のプレフィックスとして使用します。

   たとえば、東京リージョンのAnthropic Claude 4.0モデルの場合:

   - `AWS_REGION`は`ap-northeast-1`です。
   - クロスリージョン推論プレフィックスは`apac.`です。
   - モデル識別子は`bedrock/apac.anthropic.claude-sonnet-4-20250514-v1:0`です。

一部のリージョンは、クロスリージョン推論ではサポートされていません。これらのリージョンでは、モデル識別子にリージョンプレフィックスを指定しないでください。例: 

- `AWS_REGION`は`eu-west-2`です。
- モデル識別子は`anthropic.claude-sonnet-4-5-20250929-v1:0`です。

## セルフホストモデルのベータ版と機能をオンにする {#turn-on-self-hosted-beta-models-and-features}

> [!note]ベータ版のセルフホストモデルと機能をオンにすると、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)にも同意したことになります。

セルフホストモデルのベータ版と機能を有効にするには、次の手順を実行します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **ベータ版のセルフホストモデルと機能**で、**GitLab Duo Self-Hostedでベータ版のモデルおよび機能を使用する**チェックボックスをオンにします。
1. **変更を保存**を選択します。

## セルフホストモデルを使用するようにGitLab Duo機能を設定する {#configure-gitlab-duo-features-to-use-self-hosted-models}

### 設定された機能を表示する {#view-configured-features}

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
   - **GitLab Duo Self-Hostedの設定**が利用できない場合は、購入後にサブスクリプションを同期します:
     1. 左側のサイドバーで、**サブスクリプション**を選択します。
     1. **サブスクリプションの詳細**の**最終同期**の右側で、サブスクリプションの同期（{{< icon name="retry" >}}）を選択します。
1. **AIネイティブ機能**タブを選択します。

### セルフホストモデルを使用するように機能を設定する {#configure-a-feature-to-use-a-self-hosted-model}

クエリをセルフホストモデルに送信するように、GitLab Duoの機能とサブ機能を構成します:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
1. **AIネイティブ機能**タブを選択します。
1. 設定する機能とサブ機能について、ドロップダウンリストから使用したいセルフホストモデルを選択します。

   たとえば、コード生成の場合、**Claude-3 on Bedrock deployment (Claude 3)**を選択できます。

   ![GitLab Duo Self-Hostedの機能の設定](img/gitlab_duo_self_hosted_feature_configuration_v17_11.png)

{{< alert type="note" >}}

GitLab Duo Chatサブ機能のモデルを指定しない場合、**General Chat**に設定されたモデルが自動的に使用されます。これにより、サブ機能ごとに個別のモデル設定を必要とせずに、すべてのチャット機能が確実に動作します。

{{< /alert >}}

### GitLab AIベンダーモデルを使用するように機能を設定する {#configure-a-feature-to-use-a-gitlab-ai-vendor-model}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.3で、`ai_self_hosted_vendored_features`[機能フラグ](../feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)機能として[導入](https://gitlab.com/groups/gitlab-org/-/epics/17192)されました。デフォルトでは無効になっています。
- GitLab 18.7で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214030)

{{< /history >}}

{{< alert type="flag" >}}この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

セルフホストAIゲートウェイとモデルを使用している場合でも、GitLab Duo機能がGitLab AIベンダーモデルを使用するように構成できます。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
1. **AIネイティブ機能**タブを選択します。
1. 設定する機能とサブ機能について、ドロップダウンリストから**GitLab AIベンダーモデル**を選択します。

![GitLab AIベンダーモデルを使用したGitLab Duo Self-Hosted機能の構成](img/gitlab_duo_self_hosted_feature_configuration_with_vendored_model_v18_3.png)

### GitLab Duo機能を無効にする {#disable-gitlab-duo-features}

GitLab Duoの機能は、サブ機能のモデルを選択していなくても、オンのままです。

GitLab Duo機能またはサブ機能を無効にするには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **GitLab Duo Self-Hostedの設定**を選択します。
1. **AIネイティブ機能**タブを選択します。
1. 無効にする機能またはサブ機能について、ドロップダウンリストから**無効**を選択します。

![GitLab Duo機能を無効にする](img/gitlab_duo_self_hosted_disable_feature_v17_11.png)

### GitLabドキュメントをセルフホストする {#self-host-the-gitlab-documentation}

GitLab Duoセルフホスト設定により、`docs.gitlab.com`にあるGitLabドキュメントにアクセスできない場合は、ドキュメントをセルフホストできます。詳細については、[GitLab製品ドキュメントのホスト](../docs_self_host.md)を参照してください。

## 関連トピック {#related-topics}

- [サポート対象モデル](supported_models_and_hardware_requirements.md#supported-models)
- [互換性のあるモデル](supported_models_and_hardware_requirements.md#compatible-models)
- [GitLab Duo Self-Hosted設定タイプ](_index.md#configuration-types)
