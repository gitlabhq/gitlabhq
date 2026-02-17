---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: サポートされているLLMサービスプラットフォーム。
title: GitLab Duo Self-Hostedのサポート対象プラットフォーム
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
- GitLab 17.9で一般提供になりました。
- GitLab 18.0でPremiumを含むように変更されました。

{{< /history >}}

セルフホストの大規模言語モデル（LLM）をホストする場合、複数のプラットフォームが利用可能です。各プラットフォームには、さまざまなニーズに対応できる独自の機能と利点があります。次のドキュメントでは、現在サポートされているオプションをまとめています。使用したいプラットフォームがこのドキュメントにない場合は、[プラットフォームリクエストイシュー（イシュー526144）](https://gitlab.com/gitlab-org/gitlab/-/issues/526144)でフィードバックをお寄せください。

## セルフホストモデルのデプロイ {#for-self-hosted-model-deployments}

### vLLM {#vllm}

[vLLM](https://docs.vllm.ai/en/latest/index.html)は、LLM配信に最適化された高性能推論サーバーで、メモリ効率に優れています。モデル並列処理をサポートし、既存のワークフローと簡単に統合できます。

vLLMをインストールするには、[vLLMインストールガイド](https://docs.vllm.ai/en/latest/getting_started/installation.html)を参照してください。[バージョンv0.6.4.post1](https://github.com/vllm-project/vllm/releases/tag/v0.6.4.post1)以降をインストールする必要があります。

#### エンドポイント設定 {#endpoint-configuration}

GitLabでOpenAI API互換プラットフォーム（vLLMなど）のエンドポイントURLを設定する場合:

- URLのサフィックスは`/v1`にする必要があります
- デフォルトのvLLM設定を使用している場合、エンドポイントURLは`https://<hostname>:8000/v1`になります
- サーバーがプロキシまたはロードバランサーの背後に設定されている場合、ポートを指定する必要がない場合があります。その場合、URLは`https://<hostname>/v1`になります

#### モデル名を取得する {#find-the-model-name}

モデルがデプロイされた後、GitLabのモデル識別子フィールドに使用するモデル名を取得するには、vLLMサーバーの`/v1/models`エンドポイントにクエリを実行します:

```shell
curl \
  --header "Authorization: Bearer API_KEY" \
  --header "Content-Type: application/json" \
  http://your-vllm-server:8000/v1/models
```

モデル名は、レスポンスの`data.id`フィールドの値です。

レスポンス例:

```json
{
  "object": "list",
  "data": [
    {
      "id": "Mixtral-8x22B-Instruct-v0.1",
      "object": "model",
      "created": 1739421415,
      "owned_by": "vllm",
      "root": "mistralai/Mixtral-8x22B-Instruct-v0.1",
      // Additional fields removed for readability
    }
  ]
}
```

この例では、モデルの`id`が`Mixtral-8x22B-Instruct-v0.1`の場合、GitLabのモデル識別子を`custom_openai/Mixtral-8x22B-Instruct-v0.1`として設定します。

詳細:

- vLLMでサポートされているモデルについては、[vLLMサポートモデルのドキュメント](https://docs.vllm.ai/en/latest/models/supported_models.html)を参照してください。
- vLLMを使用してモデルを実行する場合に使用できるオプションについては、[エンジン引数に関するvLLMのドキュメント](https://docs.vllm.ai/en/stable/configuration/engine_args.html)を参照してください。
- モデルに必要なハードウェアについては、[サポートされているモデルとハードウェア要件に関するドキュメント](supported_models_and_hardware_requirements.md)を参照してください。

例: 

#### Mistral-7B-Instruct-v0.2 {#mistral-7b-instruct-v02}

1. HuggingFaceからモデルをダウンロードする:

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mistral-7B-Instruct-v0.3
   ```

1. サーバーを実行する:

   ```shell
   vllm serve <path-to-model>/Mistral-7B-Instruct-v0.3 \
      --served_model_name <choose-a-name-for-the-model>  \
      --tokenizer_mode mistral \
      --tensor_parallel_size <number-of-gpus> \
      --load_format mistral \
      --config_format mistral \
      --tokenizer <path-to-model>/Mistral-7B-Instruct-v0.3
   ```

#### Mixtral-8x7B-Instruct-v0.1 {#mixtral-8x7b-instruct-v01}

1. HuggingFaceからモデルをダウンロードする:

   ```shell
   git clone https://<your-hugging-face-username>:<your-hugging-face-token>@huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1
   ```

1. トークン設定の名前を変更する:

   ```shell
   cd <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   cp tokenizer.model tokenizer.model.v3
   ```

1. モデルを実行する:

   ```shell
   vllm serve <path-to-model>/Mixtral-8x7B-Instruct-v0.1 \
     --tensor_parallel_size 4 \
     --served_model_name <choose-a-name-for-the-model> \
     --tokenizer_mode mistral \
     --load_format safetensors \
     --tokenizer <path-to-model>/Mixtral-8x7B-Instruct-v0.1
   ```

#### レイテンシーを削減するためにリクエストログを無効にする {#disable-request-logging-to-reduce-latency}

本番環境でvLLMを実行する場合、`--disable-log-requests`フラグを使用してリクエストログを無効にすると、レイテンシーを大幅に削減できます。

> [!note] このフラグは、詳細なリクエストログを必要としない場合にのみ使用してください。

リクエストログを無効にすると、特に高負荷時に冗長なログによって発生するオーバーヘッドが最小限に抑えられ、パフォーマンスレベルの向上に役立ちます。

```shell
vllm serve <path-to-model>/<model-version> \
--served_model_name <choose-a-name-for-the-model>  \
--disable-log-requests
```

この変更により、内部ベンチマークでの応答時間が大幅に改善されることが確認されています。

## クラウドホストモデルのデプロイ {#for-cloud-hosted-model-deployments}

### AWS Bedrock {#aws-bedrock}

[AWS Bedrock](https://aws.amazon.com/bedrock/)は、デベロッパーが大手AI企業の事前トレーニング済みモデルを使用して生成AIアプリケーションをビルドおよびスケールできるようにする、フルマネージドサービスです。他のAWSサービスとシームレスに統合され、従量課金制の価格モデルを提供します。

AWS Bedrockモデルにアクセスするには:

1. 適切なAWS IAM権限でBedrockにアクセスするようにIAM認証情報を設定します:

   - IAMロールに`AmazonBedrockFullAccess`ポリシーがあることを確認し、[Amazon Web Services Bedrockへのアクセス](https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonBedrockFullAccess)を許可します。これは、GitLab Duo Self-Hosted UIでは実行できません。

   - 使用する[モデルへのアクセスをAmazon Web Servicesコンソールを使用してリクエストします](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access-modify.html)。

1. Dockerコンテナを起動する際に、[`AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`、`AWS_REGION_NAME`](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)などの適切なAWS SDK環境変数をエクスポートして、AIゲートウェイインスタンスを認証してください。

   詳細については、[AWS Identity and Access Management (IAM) Guide](https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html)を参照してください。

   {{< alert type="note" >}}

   一時的な認証情報は、現時点ではAIゲートウェイでサポートされていません。インスタンスプロファイルまたは一時的な認証情報を使用するためにBedrockのサポートを追加する方法については、[イシュー542389](https://gitlab.com/gitlab-org/gitlab/-/issues/542389)を参照してください。

   {{< /alert >}}

1. オプション。Virtual Private Cloud（VPC）で動作するプライベートBedrockエンドポイントをセットアップするには、AIゲートウェイコンテナを起動する際に、`AWS_BEDROCK_RUNTIME_ENDPOINT`環境変数が内部URLで設定されていることを確認してください。

   設定例: `AWS_BEDROCK_RUNTIME_ENDPOINT = https://bedrock-runtime.{aws_region_name}.amazonaws.com`

   VPCエンドポイントの場合、URL形式が`https://vpce-{vpc-endpoint-id}-{service-name}.{aws_region_name}.vpce.amazonaws.com`のように異なる場合があります

詳細については、[Supported foundation models in Amazon Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)を参照してください。

### Azure OpenAI {#azure-openai}

[Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/)は、OpenAIの強力なモデルへのアクセスを提供し、デベロッパーが堅牢なセキュリティとスケーラブルなインフラストラクチャを備えた高度なAI機能をアプリケーションに統合できるようにします。

詳細については、以下を参照してください:

- [Working with Azure OpenAI models](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/working-with-models?tabs=powershell)
- [Azure OpenAI Service models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models?tabs=python-secure%2Cglobal-standard%2Cstandard-chat-completions)

## 複数のモデルとプラットフォームを使用する {#use-multiple-models-and-platforms}

GitLab Duo Self-Hostedを使用すると、同じGitLabインスタンスで複数のモデルとプラットフォームを使用できます。

たとえば、ある機能については、Azure OpenAIを使用するように設定し、別の機能では、AWS BedrockまたはvLLMで提供されるセルフホストモデルを使用するように設定できます。

このセットアップにより、各ユースケースに最適なモデルとプラットフォームを柔軟に選択できます。使用するモデルは、サポート対象かつ互換性のあるプラットフォームで提供されている必要があります。

異なるプロバイダーのセットアップの詳細については、以下を参照してください:

- [GitLab Duo Self-Hosted機能を設定する](configure_duo_features.md)
- [サポートされているGitLab Duo Self-Hostedのモデルとハードウェア要件](supported_models_and_hardware_requirements.md)
