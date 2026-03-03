---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Self-Hostedのデプロイに関するトラブルシューティングのヒント
title: セルフホストモデルのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.1で`ai_custom_model`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/12972)されました。デフォルトでは無効になっています。
- GitLab 17.6の[GitLab Self-Managedで有効](https://gitlab.com/groups/gitlab-org/-/epics/15176)になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。
- 機能フラグ`ai_custom_model`は、GitLab 17.8で削除されました。
- GitLab 17.9で一般提供になりました。
- GitLab 18.0でPremiumを含むように変更されました。

{{< /history >}}

トラブルシューティングを開始する前に、以下を確認してください:

- [`gitlab-rails`コンソール](../operations/rails_console.md)にアクセスできる。
- AIゲートウェイDockerイメージでShellを開いている。
- 以下のエンドポイントを把握している:
  - AIゲートウェイがホストされているエンドポイント。
  - モデルがホストされているエンドポイント。
- GitLabからAIゲートウェイへのリクエストとレスポンスが[`llm.log`](../logs/_index.md#llmlog)に記録されるように[ログを有効化](logging.md#enable-logging)している。

GitLab Duoのトラブルシューティングの詳細については、以下を参照してください:

- [GitLab Duoのトラブルシューティング](../../user/gitlab_duo/troubleshooting.md)。
- [コード提案のトラブルシューティング](../../user/project/repository/code_suggestions/_index.md#direct-and-indirect-connections)。
- [GitLab Duo Chatのトラブルシューティング](../../user/gitlab_duo_chat/troubleshooting.md)。

## デバッグスクリプトを使用する {#use-debugging-scripts}

管理者がセルフホストモデルの設定を検証するためのデバッグスクリプトが2つ提供されています。

1. GitLabからAIゲートウェイへの接続をデバッグします。GitLabインスタンスから、[Rakeタスク](../../administration/raketasks/_index.md)を実行します:

   ```shell
   gitlab-rake "gitlab:duo:verify_self_hosted_setup[<username>]"
   ```

   オプション: 割り当てられたシートを持つ`<username>`を含めます。ユーザー名パラメータを含めない場合、Rakeタスクはrootユーザーを使用します。

1. AIゲートウェイの設定をデバッグします。AIゲートウェイコンテナの場合:

   - 次の設定で認証を無効にして、AIゲートウェイコンテナを再起動します:

     ```shell
     -e AIGW_AUTH__BYPASS_EXTERNAL=true
     ```

     この設定は、**System Exchangeテスト**を実行するトラブルシューティングコマンドに必要です。トラブルシューティングが完了したら、この設定を削除する必要があります。

   - AIゲートウェイコンテナから、以下を実行します:

     ```shell
     docker exec -it <ai-gateway-container> sh
     poetry run troubleshoot [options]
     ```

     `troubleshoot`コマンドは、次のオプションをサポートしています:

     | オプション               | デフォルト          | 例                                                       | 説明 |
     |----------------------|------------------|---------------------------------------------------------------|-------------|
     | `--endpoint`         | `localhost:5052` | `--endpoint=localhost:5052`                                   | AIゲートウェイエンドポイント |
     | `--model-family`     | -                | `--model-family=mistral`                                      | テストするモデルファミリー。使用可能な値は`mistral`、`mixtral`、`gpt`、`claude_3`です。 |
     | `--model-endpoint`   | -                | `--model-endpoint=http://localhost:4000/v1`                   | モデルエンドポイント。vLLMでホストされているモデルの場合は、`/v1`サフィックスを追加します。 |
     | `--model-identifier` | -                | `--model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1` | モデル識別子。 |
     | `--api-key`          | -                | `--api-key=your-api-key`                                      | モデルAPIキー。 |

     **例**:

     AWS Bedrockで実行されている`claude_3`モデルの場合:

     ```shell
     poetry run troubleshoot \
       --model-family=claude_3 \
       --model-identifier=bedrock/anthropic.claude-3-5-sonnet-20240620-v1:0
     ```

     vLLMで実行されている`mixtral`モデルの場合:

     ```shell
     poetry run troubleshoot \
       --model-family=mixtral \
       --model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1 \
       --api-key=your-api-key \
       --model-endpoint=http://<your-model-endpoint>/v1
     ```

トラブルシューティングが完了したら、AIゲートウェイコンテナを停止して、`AIGW_AUTH__BYPASS_EXTERNAL=true`**なし**で再起動します。

> [!warning] 
> 本番環境では認証をバイパスしないでください。

コマンドの出力を検証し、必要に応じて修正します。

両方のコマンドが成功しても、GitLab Duoコード提案がまだ機能しない場合は、イシュートラッカーでイシューを作成してください。

## GitLab Duoヘルスチェックが機能しない {#gitlab-duo-health-check-is-not-working}

[GitLab Duoのヘルスチェックを実行](../../administration/gitlab_duo/configure/gitlab_self_managed.md#run-a-health-check-for-gitlab-duo)すると、`401 response from the AI Gateway`のようなエラーが表示される場合があります。

解決するには、まずGitLab Duoの機能が正しく機能しているかどうかを確認します。たとえば、GitLab Duo Chatにメッセージを送信します。

これが機能しない場合、エラーはGitLab Duoヘルスチェックの既知の問題に起因する可能性があります。詳細については、[イシュー517097](https://gitlab.com/gitlab-org/gitlab/-/issues/517097)を参照してください。

## GitLabがモデルにリクエストを送信できるかどうかを確認する {#check-if-gitlab-can-make-a-request-to-the-model}

GitLab Railsコンソールから、次のコマンドを実行して、GitLabがモデルにリクエストを送信できることを検証します:

```ruby
model_name = "<your_model_name>"
model_endpoint = "<your_model_endpoint>"
model_api_key = "<your_model_api_key>"
body = {:prompt_components=>[{:type=>"prompt", :metadata=>{:source=>"GitLab EE", :version=>"17.3.0"}, :payload=>{:content=>[{:role=>:user, :content=>"Hello"}], :provider=>:litellm, :model=>model_name, :model_endpoint=>model_endpoint, :model_api_key=>model_api_key}}]}
ai_gateway_url = Ai::Setting.instance.ai_gateway_url # Verify that the AI Gateway URL is set in the database
client = Gitlab::Llm::AiGateway::Client.new(User.find_by_id(1), unit_primitive_name: :self_hosted_models)
client.complete(url: "#{ai_gateway_url}/v1/chat/agent", body: body)
```

これは、次の形式でモデルからのレスポンスを返すはずです:

```ruby
{"response"=> "<Model response>",
 "metadata"=>
  {"provider"=>"litellm",
   "model"=>"<>",
   "timestamp"=>1723448920}}
```

そうでない場合、これは次のいずれかを意味する可能性があります:

- ユーザーがコード提案にアクセスできない可能性がある。解決するには、[ユーザーがコード提案をリクエストできるかどうかを確認](#check-if-a-user-can-request-code-suggestions)します。
- GitLabの環境変数が正しく設定されていない。解決するには、[GitLabの環境変数が正しくセットアップされていることを確認](#check-that-the-ai-gateway-environment-variables-are-set-up-correctly)します。
- GitLabインスタンスが、セルフホストモデルを使用するように設定されていない。解決するには、[GitLabインスタンスが、セルフホストモデルを使用するように設定されているかどうかを確認](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models)します。
- AIゲートウェイに到達できない。解決するには、[GitLabがAIゲートウェイにHTTPリクエストを送信できるかどうかを確認](#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway)します。
- LLMサーバーがAIゲートウェイコンテナと同じインスタンスにインストールされている場合、ローカルリクエストが機能しないことがある。解決するには、[Dockerコンテナからのローカルリクエストを許可](#llm-server-is-not-available-inside-the-ai-gateway-container)します。

## ユーザーがコード提案をリクエストできるかどうかを確認する {#check-if-a-user-can-request-code-suggestions}

GitLab Railsコンソールで、次のコマンドを実行して、ユーザーがコード提案をリクエストできるかどうかを確認します:

```ruby
User.find_by_id("<user_id>").can?(:access_code_suggestions)
```

これが`false`を返す場合、何らかの設定が不足しており、ユーザーはコード提案にアクセスできません。

この不足している設定は、次のいずれかが原因である可能性があります:

- ライセンスが有効ではない。解決するには、[ライセンスを確認または更新](../license_file.md#see-current-license-information)します。
- GitLab Duoが、セルフホストモデルを使用するように設定されてない。解決するには、[GitLabインスタンスが、セルフホストモデルを使用するように設定されているかどうかを確認](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models)します。

## GitLabインスタンスがセルフホストモデルを使用するように設定されているかどうかを確認する {#check-if-gitlab-instance-is-configured-to-use-self-hosted-models}

前提条件: 

- 管理者アクセス権が必要です。

GitLab Duoが正しく設定されているかどうかを確認するには:

1. 右上隅で、**管理者**を選択します。
1. **セルフホストモデル**を選択します
1. **AIネイティブ機能**を展開します。
1. **機能**で、**コード提案**と**コード生成**が**セルフホストモデル**に設定されていることを確認します。

## AIゲートウェイURLが正しく設定されていることを確認する {#check-that-the-ai-gateway-url-is-set-up-correctly}

AIゲートウェイURLが正しいことを確認するには、GitLab Railsコンソールで以下を実行します:

```ruby
Ai::Setting.instance.ai_gateway_url == "<your-ai-gateway-instance-url>"
```

AIゲートウェイがセットアップされていない場合は、[AIゲートウェイにアクセスするようにGitLabインスタンスを設定](configure_duo_features.md#configure-access-to-the-local-ai-gateway)します。

## GitLab Duo Agent PlatformサービスURLを検証する {#validate-the-gitlab-duo-agent-platform-service-url}

Agent PlatformサービスのURLが正しいことを確認するには、GitLab Railsコンソールで以下を実行します:

```ruby
Ai::Setting.instance.duo_agent_platform_service_url == "<your-duo-agent-platform-instance-url>"
```

Agent PlatformサービスのURLはTCP URLであり、`http://`または`https://`のプレフィックスを持つことはできません。

Agent PlatformのURLがセットアップされていない場合は、[URLにアクセスできるようにGitLabインスタンスを設定](configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)する必要があります。

## GitLabがAIゲートウェイにHTTPリクエストを送信できるかどうかを確認する {#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway}

GitLab Railsコンソールで、次のコマンドを実行して、GitLabがAIゲートウェイにHTTPリクエストを送信できることを確認します:

```ruby
HTTParty.get('<your-aigateway-endpoint>/monitoring/healthz', headers: { 'accept' => 'application/json' }).code
```

レスポンスが`200`でない場合、次のいずれかを意味します:

- ネットワークが、GitLabがAIゲートウェイコンテナに到達できるように適切に設定されていない。ネットワーク管理者に連絡して、セットアップを検証します。
- AIゲートウェイがリクエストを処理できない。この問題を解決するには、[AIゲートウェイがモデルにリクエストを送信できるかどうかを確認](#check-if-the-ai-gateway-can-make-a-request-to-the-model)します。

## AIゲートウェイがモデルにリクエストを送信できるかどうかを確認する {#check-if-the-ai-gateway-can-make-a-request-to-the-model}

AIゲートウェイコンテナから、コード提案のAIゲートウェイAPIにHTTPリクエストを送信します。次のようにします。

- `<your_model_name>`を、使用しているモデルの名前に置き換えます。例: `mistral`、`codegemma`。
- `<your_model_endpoint>`を、モデルがホストされているエンドポイントに置き換えます。

```shell
docker exec -it <ai-gateway-container> sh
curl --request POST "http://localhost:5052/v1/chat/agent" \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --data '{ "prompt_components": [ { "type": "string", "metadata": { "source": "string", "version": "string" }, "payload": { "content": "Hello", "provider": "litellm", "model": "<your_model_name>", "model_endpoint": "<your_model_endpoint>" } } ], "stream": false }'
```

リクエストが失敗した場合:

- AIゲートウェイが、セルフホストモデルを使用するように適切に設定されていない可能性があります。解決するには、[AIゲートウェイURLが正しく設定されていることを確認します](#check-that-the-ai-gateway-url-is-set-up-correctly)。
- AIゲートウェイがモデルにアクセスできない可能性があります。解決するには、[AIゲートウェイからモデルに到達できるかどうかを確認します](#check-if-the-model-is-reachable-from-ai-gateway)。
- モデル名またはエンドポイントが正しくない可能性があります。値を確認し、必要に応じて修正します。

## AIゲートウェイがリクエストを処理できるかどうかを確認する {#check-if-ai-gateway-can-process-requests}

```shell
docker exec -it <ai-gateway-container> sh
curl '<your-aigateway-endpoint>/monitoring/healthz'
```

レスポンスが`200`でない場合、AIゲートウェイが正しくインストールされていないことを意味します。解決するには、[AIゲートウェイのインストール方法に関するドキュメント](../../install/install_ai_gateway.md)に従います。

## AIゲートウェイの環境変数が正しくセットアップされていることを確認する {#check-that-the-ai-gateway-environment-variables-are-set-up-correctly}

AIゲートウェイの環境変数が正しくセットアップされていることを確認するには、AIゲートウェイコンテナのコンソールで以下を実行します:

```shell
docker exec -it <ai-gateway-container> sh
echo $AIGW_CUSTOM_MODELS__ENABLED # must be true
```

環境変数が正しくセットアップされていない場合は、[コンテナを作成](../../install/install_ai_gateway.md#find-the-ai-gateway-image)して設定します。

## AIゲートウェイからモデルに到達可能かどうかを確認する {#check-if-the-model-is-reachable-from-ai-gateway}

AIゲートウェイコンテナでShellを作成し、モデルにcurlリクエストを送信します。AIゲートウェイがそのリクエストを送信できないことが判明した場合、これは次のことが原因である可能性があります:

1. モデルサーバーが正しく機能していない。
1. コンテナ周辺のネットワーク設定が、モデルがホストされている場所へのリクエストを許可するように適切に設定されていない。

これを解決するには、ネットワーク管理者にお問い合わせください。

## AIゲートウェイがGitLabインスタンスにリクエストを送信できるかどうかを確認する {#check-if-ai-gateway-can-make-requests-to-your-gitlab-instance}

`AIGW_GITLAB_URL`で定義されたGitLabインスタンスは、リクエスト認証のためにAIゲートウェイコンテナからアクセスできる必要があります。インスタンスに到達できない場合（たとえば、プロキシ設定エラーが原因）、リクエストが次のようなエラーで失敗する可能性があります:

- ```shell
  jose.exceptions.JWTError: Signature verification failed
  ```

- ```shell
  gitlab_cloud_connector.providers.CompositeProvider.CriticalAuthError: No keys founds in JWKS; are OIDC providers up?
  ```

このシナリオでは、`AIGW_GITLAB_URL`と`$AIGW_GITLAB_API_URL`がコンテナに適切に設定され、アクセスできるかどうかを検証します。次のコマンドは、コンテナから実行すると成功するはずです:

```shell
poetry run troubleshoot
curl "$AIGW_GITLAB_API_URL/projects"
```

成功しない場合は、ネットワーク設定を検証してください。

## イメージのプラットフォームがホストと一致しない {#the-images-platform-does-not-match-the-host}

[AIゲートウェイリリースを見つける](../../install/install_ai_gateway.md#find-the-ai-gateway-image)と、`The requested image's platform (linux/amd64) does not match the detected host`というエラーが表示される場合があります。

この回避策として、`docker run`コマンドに`--platform linux/amd64`を追加します:

```shell
docker run --platform linux/amd64 -e AIGW_GITLAB_URL=<your-gitlab-endpoint> <image>
```

## LLMサーバーがAIゲートウェイコンテナ内で使用できない {#llm-server-is-not-available-inside-the-ai-gateway-container}

LLMサーバーがAIゲートウェイコンテナと同じインスタンスにインストールされている場合、ローカルホストからはアクセスできない可能性があります。

これを解決するには:

1. `--network host`を`docker run`コマンドに含めて、AIゲートウェイコンテナからのローカルリクエストを有効にします。
1. ポートの競合に対処するために、`-e AIGW_FASTAPI__METRICS_PORT=8083`フラグを使用します。

```shell
docker run --network host -e AIGW_GITLAB_URL=<your-gitlab-endpoint> -e AIGW_FASTAPI__METRICS_PORT=8083 <image>
```

## vLLM 404エラー {#vllm-404-error}

vLLMの使用中に**404エラー**が発生した場合は、次の手順に従って問題を解決してください:

1. 次の内容で`chat_template.jinja`という名前のチャットテンプレートファイルを作成します:

   ```jinja
   {%- for message in messages %}
     {%- if message["role"] == "user" %}
       {{- "[INST] " + message["content"] + "[/INST]" }}
     {%- elif message["role"] == "assistant" %}
       {{- message["content"] }}
     {%- elif message["role"] == "system" %}
       {{- bos_token }}{{- message["content"] }}
     {%- endif %}
   {%- endfor %}
   ```

1. vLLMコマンドを実行するときは、必ず`--served-model-name`を指定してください。例: 

   ```shell
   vllm serve "mistralai/Mistral-7B-Instruct-v0.3" --port <port> --max-model-len 17776 --served-model-name mistral --chat-template chat_template.jinja
   ```

1. GitLab UIでvLLMサーバーのURLを確認して、URLに`/v1`サフィックスが含まれていることを確認します。正しい形式は次のとおりです:

   ```shell
   http(s)://<your-host>:<your-port>/v1
   ```

## コード提案アクセスエラー {#code-suggestions-access-error}

セットアップ後にコード提案へのアクセスで問題が発生する場合は、次の手順を試してください:

1. Railsコンソールで、ライセンスパラメータを確認および検証します:

   ```shell
   sudo gitlab-rails console
   user = User.find(id) # Replace id with the user provisioned with GitLab Duo Enterprise seat
   Ability.allowed?(user, :access_code_suggestions) # Must return true
   ```

1. 必要な機能が有効で利用可能かどうかを確認します:

   ```shell
   ::Ai::FeatureSetting.exists?(feature: [:code_generations, :code_completions], provider: :self_hosted) # Should be true
   ```

## エラーA1000 {#error-a1000}

セルフホストモデルでGitLab Duoの機能を使用すると、次のエラーが発生する可能性があります:

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`

この問題は、モデルへのリクエストにかかる時間が、設定されたタイムアウト期間よりも長くなった場合に発生します。

一般的な原因は次のとおりです:

- 大きなコンテキストウィンドウまたは複雑なプロンプト
- モデルのパフォーマンスの制限
- AIゲートウェイとモデルエンドポイント間のネットワークレイテンシー
- リージョンをまたがる推論の遅延（AWS Bedrockデプロイの場合）

タイムアウトエラーを解決するには:

1. [より高いAIゲートウェイタイムアウト値を設定します](configure_duo_features.md#configure-timeout-for-the-ai-gateway)。タイムアウトは60秒から600秒（10分）の間に設定できます。
1. タイムアウトを調整した後、ログをモニタリングしてエラーが解決されたことを確認します。
1. より高いタイムアウト値を設定してもタイムアウトエラーが解決しない場合:
   - モデルのパフォーマンスとリソース割り当てを確認します。
   - AIゲートウェイとモデルエンドポイント間のネットワーク接続を確認します。
   - よりパフォーマンスの高いモデルまたはデプロイ設定の使用を検討してください。

## GitLabのセットアップを検証する {#verify-gitlab-setup}

GitLab Self-Managedのセットアップを検証するには、次のコマンドを実行します:

```shell
gitlab-rake gitlab:duo:verify_self_hosted_setup
```

## AIゲートウェイサーバーでログが生成されない {#no-logs-generated-in-the-ai-gateway-server}

AIゲートウェイサーバーでログが生成されない場合は、次の手順に従ってトラブルシューティングを行います:

1. [AIログが有効になっている](logging.md#enable-logging)ことを確認します。
1. 次のコマンドを実行して、GitLab Railsログを表示し、エラーがないか確認します:

   ```shell
   sudo gitlab-ctl tail
   sudo gitlab-ctl tail sidekiq
   ```

1. ログで「Error」や「Exception」などのキーワードを探して、根本的な問題を特定します。

## AIゲートウェイコンテナでのSSL証明書エラーとキーの逆シリアル化の問題 {#ssl-certificate-errors-and-key-de-serialization-issues-in-the-ai-gateway-container}

AIゲートウェイコンテナ内でGitLab Duo Chatを開始しようとすると、SSL証明書エラーとキーの逆シリアル化の問題が発生する可能性があります。

システムでPEMファイルを読み込む際に問題が発生し、次のようなエラーが発生する可能性があります:

```plaintext
JWKError: Could not deserialize key data. The data may be in an incorrect format, the provided password may be incorrect, or it may be encrypted with an unsupported algorithm.
```

SSL証明書エラーを解決するには:

- 次の環境変数を使用して、Dockerコンテナに適切な証明書バンドルパスを設定します:
  - `SSL_CERT_FILE=/path/to/ca-bundle.pem`
  - `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

## エラー: モデルID metaの呼び出しがサポートされていない {#error-invocation-of-model-id-meta-isnt-supported}

AIGWログでは、モデル識別子の形式が正しくない場合、次のエラーが表示されます:

```plaintext
Invocation of model ID meta.llama3-3-70b-instruct-v1:0 with on-demand throughput isn\u2019t supported. Retry your request with the ID or ARN of an inference profile that contains this model
```

`model identifier`の形式が`bedrock/<region>.<model-id>`であることを確認します。ここで:

- `<region>`はAWSリージョン（`us`など）
- `<model-id>`は完全なモデル識別子。

例: `bedrock/us.meta.llama3-3-70b-instruct-v1:0`。正しい形式を使用するようにモデル設定を更新します。

## 機能にアクセスできない、または機能ボタンが表示されない {#feature-not-accessible-or-feature-button-not-visible}

機能が動作しない場合、または機能ボタン（たとえば、**`/troubleshoot`**）が表示されない場合:

1. その機能の`unit_primitive`が、[`gitlab-cloud-connector` gem設定のセルフホストモデルunit primitiveリスト](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/blob/main/config/services/self_hosted_models.yml)に記載されているかどうかを確認します。

   このファイルに機能が見つからない場合、それがアクセスできない理由である可能性があります。

1. オプション。機能がリストされていない場合、GitLabインスタンスで以下を設定することで、これが問題の原因であることを検証できます:

   ```shell
   CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1
   ```

   その後、GitLabを再起動し、機能にアクセスできるようになるかどうかを確認します。

   **重要**: トラブルシューティング後、このフラグを設定**せずに**GitLabを再起動します。

   > [!warning] 
   > **Do not use in production**では`CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1`を使用しないでください。開発環境は本番環境を忠実に反映する必要があり、隠れたフラグや内部専用の回避策があってはなりません。

1. この問題を解決するには、次の手順に従います:
   - GitLabチームのメンバーである場合は、[`#g_custom_models` Slackチャンネル](https://gitlab.enterprise.slack.com/archives/C06DCB3N96F)を通じて、カスタムモデルチームに連絡してください。
   - お客様の場合は、[GitLabサポート](https://about.gitlab.com/support/)を通じて問題を報告してください。

## エラー: このワークフローの認証トークンのフェッチ中にエラーが発生しました {#error-an-error-occurred-while-fetching-an-authentication-token-for-this-workflow}

このエラーは、GitLabまたはローカル環境でAgentic Chatを使用しようとすると発生する可能性があります。

IDEの[GitLab言語サーバー](../../editor_extensions/language_server/_index.md)のログに、次の内容が表示されることもあります:

```shell
2026-01-09T20:17:43:419 [error]: [WorkflowRailsService] Failed to fetch the workflow token
    Error: Fetching direct_access from https://gitlab.example.com/api/v4/ai/duo_workflows/direct_access failed.
{"message":"400 Bad request - 14:failed to connect to all addresses; last error: UNKNOWN: ipv4:172.x.x.x:50052: Ssl handshake failed (TSI_PROTOCOL_FAILURE): SSL_ERROR_SSL: error:100000f7:SSL routines:OPENSSL_internal:WRONG_VERSION_NUMBER: Invalid certificate verification context. debug_error_string:{UNKNOWN:Error received from peer  {grpc_status:14, grpc_message:\"failed to connect to all addresses; last error: UNKNOWN: ipv4:172.x.x.x:50052: Ssl handshake failed (TSI_PROTOCOL_FAILURE): SSL_ERROR_SSL: error:100000f7:SSL routines:OPENSSL_internal:WRONG_VERSION_NUMBER: Invalid certificate verification context\"}}"}
2026-01-09T20:17:43:433 [error]: Max retries exceeded or non-retryable error: An error occurred while fetching an authentication token for this workflow.
2026-01-09T20:17:43:435 [error]: Workflow failed with status code "50": An error occurred while fetching an authentication token for this workflow.
```

これは、証明書の問題により、言語サーバーが`direct_access`エンドポイントと通信してJWTトークンを生成できなかったことを意味します。

TLSなしでセルフホストモデルを使用している場合、この問題を解決するには、`DUO_AGENT_PLATFORM_SERVICE_SECURE`を`false`に設定してください。[AIゲートウェイのインストール](../../install/install_ai_gateway.md#start-a-container-from-the-image)を参照してください。

> [!warning]
> `DUO_AGENT_PLATFORM_SERVICE_SECURE`グローバル設定には既知のイシューがあります。GitLab Duo Agent Platformの機能でクラウドホストモデルとセルフホストモデル（TLSなし）を組み合わせて使用すると、これらのモデルのいずれかが失敗する可能性があります。失敗するかどうかは、`DUO_AGENT_PLATFORM_SERVICE_SECURE`が`true`か`false`かによって異なります。この既知のイシューは、次の機能のモデルに影響します:
>
> - GitLab Duo Chat（エージェント）
> - Agentic Chatを除くすべてのエージェント
>
> これらの機能に選択されたモデルが異なるバックエンドにルーティングされる場合（たとえば、1つのクラウドホストモデルと1つのTLSなしのセルフホストモデル）、それらのいずれかが失敗する可能性があります。詳細については、[イシュー590454](https://gitlab.com/gitlab-org/gitlab/-/issues/590454)を参照してください。

## 関連トピック {#related-topics}

- [サポートエンジニア向けプレイブックと一般的な問題](support_engineer_playbook.md)
