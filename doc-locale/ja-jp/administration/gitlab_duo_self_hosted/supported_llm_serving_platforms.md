---
stage: AI Platform
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: サポートされているLLMサービスプラットフォーム。
title: LLMプラットフォームを設定する
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

{{< /history >}}

AIゲートウェイは、[LiteLLM](https://docs.litellm.ai/docs/providers)を通じて複数のLLMプロバイダーをサポートしています。各プラットフォームには、さまざまなニーズに対応できる独自の機能と利点があります。次のドキュメントでは、検証およびテスト済みのプロバイダーについてまとめています。使用したいプラットフォームがこのドキュメントにない場合は、[プラットフォームリクエストイシュー（イシュー526144）](https://gitlab.com/gitlab-org/gitlab/-/issues/526144)でフィードバックをお寄せください。

## 複数のモデルとプラットフォームを使用する {#use-multiple-models-and-platforms}

同じGitLabインスタンスで複数のモデルとプラットフォームを使用できます。

たとえば、ある機能がAzure OpenAIを使用するように設定し、別の機能がAWS BedrockまたはvLLMで提供されるセルフホストモデルを使用するように設定できます。

このセットアップにより、各ユースケースに最適なモデルとプラットフォームを柔軟に選択できます。使用するモデルは、サポート対象かつ互換性のあるプラットフォームで提供されている必要があります。

## セルフホストモデルのデプロイ {#self-hosted-model-deployments}

### vLLM {#vllm}

[vLLM](https://docs.vllm.ai/en/latest/index.html)は、LLM配信に最適化された高性能推論サーバーで、メモリ効率に優れています。モデル並列処理をサポートし、既存のワークフローと簡単に統合できます。

vLLMをインストールするには、[vLLMインストールガイド](https://docs.vllm.ai/en/latest/getting_started/installation.html)を参照してください。[version v0.18.1](https://github.com/vllm-project/vllm/releases/tag/v0.18.1)以降をインストールする必要があります。

vLLMでGPT OSS 120Bを提供する規範的なセットアップガイドについては、[vLLMでGPT OSS 120Bを提供する](vllm_gpt_oss_120b.md)を参照してください。

#### エンドポイントURLを設定する {#configuring-the-endpoint-url}

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

詳細については、次のドキュメントを参照してください:

- vLLMでサポートされているモデルについては、[vLLMサポートモデルのドキュメント](https://docs.vllm.ai/en/latest/models/supported_models.html)を参照してください。
- vLLMを使用してモデルを実行する場合に使用できるオプションについては、[エンジン引数に関するvLLMのドキュメント](https://docs.vllm.ai/en/stable/configuration/engine_args.html)を参照してください。

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

> [!note]
> 詳細なリクエストの記録が不要な場合にのみ、このフラグを使用してください。

リクエストログを無効にすると、特に高負荷時に冗長なログによって発生するオーバーヘッドが最小限に抑えられ、パフォーマンスレベルの向上に役立ちます。

```shell
vllm serve <path-to-model>/<model-version> \
--served_model_name <choose-a-name-for-the-model>  \
--disable-log-requests
```

この変更により、内部ベンチマークでの応答時間が大幅に改善されることが確認されています。

## クラウドホスト型モデルのデプロイ {#cloud-hosted-model-deployments}

GitLabは、以下のプロバイダーの検証およびテストを完了しています。AIゲートウェイは、[LiteLLM](https://docs.litellm.ai/docs/providers)と互換性のあるLLMプロバイダーをサポートしています。

- [AWS Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [Amazon Bedrock Mantle](#configure-amazon-bedrock-mantle)
- [Gemini Enterprise Agent Platform](https://cloud.google.com/products/gemini-enterprise-agent-platform)
- [Azure OpenAI](https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure?tabs=global-standard&pivots=azure-openai)
- [Anthropic](https://platform.claude.com/docs/en/about-claude/models/overview)
- [OpenAI](https://developers.openai.com/api/docs/models)

### AWS Bedrockでの認証を設定する {#configure-authentication-with-aws-bedrock}

AWS BedrockをAIゲートウェイで認証するには、いくつかの方法を使用できます。

前提条件: 

- モデルは、最初に実行されたときにBedrockで自動的に有効になります。詳細については、[Bedrockモデルアクセス](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html)を参照してください。
- 適切なIAM権限でAWS認証情報が設定されていることを確認してください。

#### Amazon EKSとHelm Chart（推奨） {#amazon-eks-with-helm-chart-recommended}

AWS Bedrockを認証するためにAIゲートウェイのポッドにIRSA（サービスアカウントのIAMロール）を使用します。セキュアな静的認証情報は使用しません。

Amazon EKSをIRSAで認証すると、AIゲートウェイはIRSAロールから一時的な認証情報を自動的に取得します。

IRSAを使用してAmazon EKSを認証するには:

1. Bedrockモデルへのアクセスを許可するIAMポリシーを作成します。より高いセキュリティが必要な場合は、これを特定のモデルに制限できます:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "bedrock:InvokeModel",
           "bedrock:InvokeModelWithResponseStream"
         ],
         "Resource": "arn:aws:bedrock:*::foundation-model/*"
       }
     ]
   }
   ```

   ```shell
   aws iam create-policy \
     --policy-name bedrock-ai-gateway-access \
     --policy-document file://bedrock-policy.json \
     --description "Bedrock access for AI Gateway"
   ```

1. オプション。より厳格なアクセス制御には、ワイルドカードリソースを特定のモデルのAmazon Resource Name (ARN) に置き換えます。これにより、GitLabの設定が変更されても、承認されたモデルのみがアクセスできるようになります。利用可能なモデルのARNについては、[Amazon BedrockモデルのID](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)を参照してください。

   ```json
   "Resource": [
     "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
     "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
   ]
   ```

   > [!note]
   > 一部のモデルでは、異なるARN形式を使用する場合があります。たとえば、新しいモデルでは、基盤モデルのARNに加えて、推論プロファイルのARNが必要になる場合があります。ご使用のモデルのARN形式を確認するには、[Amazon BedrockモデルID](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)を参照してください。

1. Amazon EKSサービスアカウントが使用する信頼ポリシーを持つIAMロールを作成します。次の値を置き換えます:

   - `YOUR_ACCOUNT_ID`: AWSアカウントID。
   - `REGION`: Amazon EKSクラスターリージョン（例: `us-east-1`）。
   - `YOUR_OIDC_ID`: Amazon EKSクラスターのOIDCプロバイダーID。
   - `NAMESPACE`: AIゲートウェイがデプロイされているKubernetesネームスペース。

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID:sub": "system:serviceaccount:NAMESPACE:ai-gateway",
             "oidc.eks.REGION.amazonaws.com/id/YOUR_OIDC_ID:aud": "sts.amazonaws.com"
           }
         }
       }
     ]
   }
   ```

   ```shell
   # Create the role
   aws iam create-role \
     --role-name eks-ai-gateway-bedrock \
     --assume-role-policy-document file://trust-policy.json \
     --description "EKS IRSA role for AI Gateway to access Bedrock"
   ```

1. Bedrock IAMポリシーをこのロールにアタッチします。

   ```shell
   # Attach the role
   aws iam attach-role-policy \
     --role-name eks-ai-gateway-bedrock \
     --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/bedrock-ai-gateway-access
   ```

1. Helmチャートを設定するには、IAMロール注釈付きでAIゲートウェイをインストールします:

   ```yaml
   serviceAccount:
     create: true
     name: ai-gateway
     annotations:
       eks.amazonaws.com/role-arn: arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE_NAME
   extraEnvironmentVariables:
     - name: AWS_REGION
       value: us-east-1
   ```

詳細については、[サービスアカウントのIAMロール](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)を参照してください。

#### Dockerデプロイ {#docker-deployments}

AIゲートウェイコンテナの起動時に、環境変数を通じてIAM認証情報を設定します:

```shell
docker run -d \
  -e AWS_ACCESS_KEY_ID=your-access-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret-key \
  -e AWS_REGION=us-east-1 \
  -p 5052:5052 \
  registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-vX.Y.Z-ee
```

IAMユーザーまたはロールは、Amazon EKSとHelm Chartで設定するものと同様のポリシーを持っている必要があります。

#### Kubernetesデプロイ {#kubernetes-deployments}

Amazon EKS以外のKubernetesクラスターの場合、AWS認証情報を保存するためにKubernetes Secretsを使用できます:

1. Kubernetesシークレットを作成します:

   ```shell
   kubectl create secret generic aws-credentials \
     --from-literal=access-key-id=YOUR_ACCESS_KEY_ID \
     --from-literal=secret-access-key=YOUR_SECRET_ACCESS_KEY \
     -n YOUR_NAMESPACE
   ```

1. Helmチャートをシークレットを参照するように設定します:

   ```yaml
   extraEnvironmentVariables:
     - name: AWS_ACCESS_KEY_ID
       valueFrom:
         secretKeyRef:
           name: aws-credentials
           key: access-key-id
     - name: AWS_SECRET_ACCESS_KEY
       valueFrom:
         secretKeyRef:
           name: aws-credentials
           key: secret-access-key
     - name: AWS_REGION
       value: us-east-1
   ```

#### AWS Bedrock APIキー {#aws-bedrock-api-keys}

IAM認証情報の代わりにAWS Bedrock APIキーを使用するには:

1. [Bedrock APIキーを作成します](https://docs.aws.amazon.com/bedrock/latest/userguide/api-keys-generate.html)
1. APIキーを含むKubernetesシークレットを作成します:

   ```shell
   kubectl create secret generic bedrock-api-key \
     --from-literal=token=YOUR_BEDROCK_API_KEY \
     -n YOUR_NAMESPACE
   ```

1. AIゲートウェイを設定します（`values.yaml`に追加）:

   ```yaml
   extraEnvironmentVariables:
     - name: AWS_BEARER_TOKEN_BEDROCK
       valueFrom:
         secretKeyRef:
           name: bedrock-api-key
           key: token
     - name: AWS_REGION
       value: us-east-1
   ```

#### プライベートVPCエンドポイント {#private-vpc-endpoints}

VPCでプライベートBedrockエンドポイントを使用するには、`AWS_BEDROCK_RUNTIME_ENDPOINT`環境変数を設定します。

Helmデプロイの場合:

```yaml
extraEnvironmentVariables:
  - name: AWS_BEDROCK_RUNTIME_ENDPOINT
    value: https://bedrock-runtime.us-east-1.amazonaws.com
```

Dockerデプロイの場合:

```shell
docker run -d \
  -e AWS_BEDROCK_RUNTIME_ENDPOINT=https://bedrock-runtime.us-east-1.amazonaws.com \
  -e AWS_REGION=us-east-1 \
  # ... other configuration
```

VPCエンドポイントの場合、次の形式を使用します: `https://vpce-{vpc-endpoint-id}-{service-name}.{region}.vpce.amazonaws.com`

#### Bedrockガードレール {#bedrock-guardrails}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/4715)されました。

{{< /history >}}

Amazon Bedrockガードレールを使用して、Bedrockモデルのリクエストに対する安全性とプライバシー制御を提供できます。

これらのガードレールを適用するには、`AIGW_BEDROCK_GUARDRAIL_CONFIG`環境変数の値を、以下のフィールドを含むJSONオブジェクトに設定します:

| フィールド                 | 説明 |
|-----------------------|-------------|
| `guardrailIdentifier` | AWSアカウント内のガードレールのID。単純なID（`abc123`）または完全なARN（`arn:aws:bedrock:us-east-1:123456789012:guardrail/abc123`）を使用できます。 |
| `guardrailVersion`    | 適用するガードレールのバージョン。`1`に設定します。 |
| `trace`               | レスポンスにトレース情報を含めるかどうか。`enabled`または`disabled`に設定できます。 |

> [!note]
> ガードレールがリクエストをブロックした場合、ユーザーに返されるメッセージは、GitLabが提供するメッセージではなく、AWS Bedrockのガードレールで設定されたカスタムブロックメッセージです。ユーザーが適切なガイダンスを受けられるように、AWSコンソールでガードレールのブロックされたメッセージングを設定してください。

Helmデプロイの場合、環境変数を次のように設定します:

```yaml
extraEnvironmentVariables:
  - name: AIGW_BEDROCK_GUARDRAIL_CONFIG
    value: '{"guardrailIdentifier": "<guardrail_id>", "guardrailVersion": "1", "trace": "disabled"}'
```

Dockerデプロイの場合:

```shell
docker run -d \
  -e AIGW_BEDROCK_GUARDRAIL_CONFIG='{"guardrailIdentifier": "<guardrail_id>", "guardrailVersion": "1", "trace": "disabled"}' \
  # ... other configuration
```

詳細については、[Amazon Bedrock Guardrails](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html)を参照してください。

### Amazon Bedrock Mantleを設定する {#configure-amazon-bedrock-mantle}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/22787)された[ベータ](../../policy/development_stages_support.md#beta)版です。

{{< /history >}}

[Amazon Bedrock Mantle](https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-mantle.html)は、AWSのOpenAI API互換推論サービスです。Amazon Bedrock Mantleを、他のOpenAI互換エンドポイントと同様にAPIプラットフォームで設定します。

Amazon Bedrock MantleでGPT OSS 120Bのみが検証され、サポートされています。

Amazon Bedrock Mantleモデルを設定するには、次の値を持つ[セルフホストモデルを追加](configure_duo_features.md#add-a-self-hosted-model)します:

- **モデルファミリー**については、モデルに一致するファミリーを選択します。GPT OSS 120Bの場合は、**GPT**を選択します。
- **エンドポイント**については、`https://bedrock-mantle.<region>.api.aws/v1`の形式でリージョンエンドポイントを入力します（例: `https://bedrock-mantle.us-east-1.api.aws/v1`）。
- **モデル識別子**については、`bedrock_mantle/`プレフィックスを使用します（例: `bedrock_mantle/openai.gpt-oss-120b`）。
- **APIキー**については、Amazon Bedrock MantleのAPIキーを入力します。詳細については、[AWS Bedrock API key](#aws-bedrock-api-keys)を参照してください。

### Gemini Enterprise Agent Platformで認証を設定する {#configure-authentication-with-gemini-enterprise-agent-platform}

Gemini Enterprise Agent Platformのモデルを使用するには、AIゲートウェイのインスタンスを認証する必要があります。以下のいずれかのメカニズムを使用できます:

- Dockerコンテナの起動時に環境変数をエクスポートします。これを行うには、AIゲートウェイコンテナの実行時に以下の環境変数を設定します:

  ```shell
  GOOGLE_APPLICATION_CREDENTIALS=/path/to/application_default_credentials.json
  VERTEXAI_PROJECT=<gcp-project-id>
  VERTEXAI_LOCATION=global # or any specific location, e.g., "europe-west1"
  ```

- Google Cloud RunでAIゲートウェイコンテナを実行し、Gemini Enterprise Agent Platformへのアクセスには[Cloud Runサービスアカウント](https://docs.litellm.ai/docs/providers/vertex#using-gcp-service-account)を使用します。

## 関連トピック {#related-topics}

- [サポートされているモデルとハードウェア要件ドキュメント](supported_models_and_hardware_requirements.md)。
- [Amazon Bedrockでサポートされている基盤モデル](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html)
- [AWS IAMのベストプラクティス](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Amazon Bedrockのセキュリティ](https://docs.aws.amazon.com/bedrock/latest/userguide/security.html)
- 設定情報については、以下のドキュメントを参照してください:
  - [Anthropic APIの概要](https://platform.claude.com/docs/en/api/overview)
  - [OpenAI APIの概要](https://developers.openai.com/api/docs)
  - [Working with Azure OpenAI models](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/working-with-models?tabs=powershell)
