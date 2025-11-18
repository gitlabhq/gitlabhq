---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duoセルフホストモデルのデプロイに関するトラブルシューティングのヒント
title: GitLab Duoセルフホストモデルのトラブルシューティング
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
- 機能フラグ`ai_custom_model`はGitLab 17.8で削除されました。
- GitLab 17.9で一般提供となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

GitLab Duoセルフホストモデルを使用していると、問題が発生することがあります。

トラブルシューティングを開始する前に、次のことを行う必要があります:

- [`gitlab-rails`コンソール](../operations/rails_console.md)にアクセスできること。
- AIゲートウェイDockerイメージでShellを開きます。
- 以下のエンドポイントを知っておくこと:
  - AIゲートウェイがホストされている場所
  - モデルがホストされている場所
- [ログを有効化](logging.md#enable-logging)して、GitLabからAIゲートウェイへのリクエストとレスポンスが[`llm.log`](../logs/_index.md#llmlog)に記録されていることを確認します。

GitLab Duoのトラブルシューティングの詳細については、以下を参照してください:

- [GitLab Duo](../../user/gitlab_duo/troubleshooting.md)のトラブルシューティング
- [コード提案のトラブルシューティング](../../user/project/repository/code_suggestions/troubleshooting.md)。
- [GitLab Duo Chat](../../user/gitlab_duo_chat/troubleshooting.md)のトラブルシューティング

## デバッグスクリプトを使用する {#use-debugging-scripts}

管理者がセルフホストモデルの設定を検証するのに役立つ、2つのデバッグスクリプトを提供しています。

1. GitLabからAIゲートウェイへの接続をデバッグします。GitLabインスタンスから、[Rakeタスク](../../administration/raketasks/_index.md)を実行します:

   ```shell
   gitlab-rake "gitlab:duo:verify_self_hosted_setup[<username>]"
   ```

   （オプション）: 割り当てられたシートを持つ`<username>`を含めます。ユーザー名パラメータを含めない場合、Rakeタスクはrootユーザー名を使用します。

1. AIゲートウェイのセットアップをデバッグします。AIゲートウェイコンテナの場合:

   - 次のように設定して、認証を無効にしてAIゲートウェイコンテナを再起動します:

     ```shell
     -e AIGW_AUTH__BYPASS_EXTERNAL=true
     ```

     この設定は、トラブルシューティングコマンドが**System Exchange test**（システム交換テスト）を実行するために必要です。トラブルシューティングが完了したら、この設定を削除する必要があります。

   - AIゲートウェイコンテナから、以下を実行します:

     ```shell
     docker exec -it <ai-gateway-container> sh
     poetry run troubleshoot [options]
     ```

     `troubleshoot`コマンドは、次のオプションをサポートしています:

     | オプション               | デフォルト          | 例                                                       | 説明 |
     |----------------------|------------------|---------------------------------------------------------------|-------------|
     | `--endpoint`         | `localhost:5052` | `--endpoint=localhost:5052`                                   | AIゲートウェイエンドポイント |
     | `--model-family`     | -                | `--model-family=mistral`                                      | テストするモデルファミリー。使用できる値は、`mistral`、`mixtral`、`gpt`、または`claude_3`です。 |
     | `--model-endpoint`   | -                | `--model-endpoint=http://localhost:4000/v1`                   | モデルエンドポイント。vLLMでホストされているモデルの場合は、`/v1`サフィックスを追加します。 |
     | `--model-identifier` | -                | `--model-identifier=custom_openai/Mixtral-8x7B-Instruct-v0.1` | モデル識別子。 |
     | `--api-key`          | -                | `--api-key=your-api-key`                                      | モデルAPIキー。 |

     **Examples**（例）:

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

トラブルシューティングが完了したら、`AIGW_AUTH__BYPASS_EXTERNAL=true`**without**（なしで）AIゲートウェイコンテナを停止して再起動します。

{{< alert type="warning" >}}

本番環境で認証を回避しないでください。

{{< /alert >}}

コマンドの出力を検証し、必要に応じて修正します。

両方のコマンドが成功しても、GitLab Duoコード提案がまだ機能しない場合は、イシュートラッカーでイシューを提起してください。

## GitLab Duoヘルスチェックが機能していません {#gitlab-duo-health-check-is-not-working}

[GitLab Duoのヘルスチェックを実行](../../administration/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo)すると、`401 response from the AI gateway`のようなエラーが発生する場合があります。

解決するには、まずGitLab Duoの機能が正しく機能しているかどうかを確認してください。たとえば、Duoチャットにメッセージを送信します。

これで問題が解決しない場合、GitLab Duoヘルスチェックの既知の問題が原因である可能性があります。詳細については、[issue 517097](https://gitlab.com/gitlab-org/gitlab/-/issues/517097)を参照してください。

## GitLabがモデルにリクエストを送信できるかどうかを確認する {#check-if-gitlab-can-make-a-request-to-the-model}

GitLab Railsコンソールから、次のコマンドを実行して、GitLabがモデルにリクエストを送信できることを検証します:

```ruby
model_name = "<your_model_name>"
model_endpoint = "<your_model_endpoint>"
model_api_key = "<your_model_api_key>"
body = {:prompt_components=>[{:type=>"prompt", :metadata=>{:source=>"GitLab EE", :version=>"17.3.0"}, :payload=>{:content=>[{:role=>:user, :content=>"Hello"}], :provider=>:litellm, :model=>model_name, :model_endpoint=>model_endpoint, :model_api_key=>model_api_key}}]}
ai_gateway_url = Ai::Setting.instance.ai_gateway_url # Verify that the AI gateway URL is set in the database
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

- ユーザーがコード提案にアクセスできない可能性があります。解決するには、[ユーザーがコード提案をリクエストできるかどうかを確認](#check-if-a-user-can-request-code-suggestions)してください。
- GitLabの環境変数が正しく設定されていません。解決するには、[GitLabの環境変数が正しくセットアップされていることを確認](#check-that-the-ai-gateway-environment-variables-are-set-up-correctly)してください。
- GitLabインスタンスが、セルフホストモデルを使用するように設定されていません。解決するには、[GitLabインスタンスが、セルフホストモデルを使用するように設定されているかどうかを確認](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models)します。
- AIゲートウェイに到達できません。解決するには、[GitLabがAIゲートウェイにHTTPリクエストを送信できるかどうかを確認](#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway)します。
- LLMサーバーがAIゲートウェイコンテナと同じインスタンスにインストールされている場合、ローカルリクエストが機能しない可能性があります。解決するには、[Dockerコンテナからのローカルリクエストを許可](#llm-server-is-not-available-inside-the-ai-gateway-container)します。

## ユーザーがコード提案をリクエストできるかどうかを確認する {#check-if-a-user-can-request-code-suggestions}

GitLab Railsコンソールで、次のコマンドを実行して、ユーザーがコード提案をリクエストできるかどうかを確認します:

```ruby
User.find_by_id("<user_id>").can?(:access_code_suggestions)
```

これにより`false`が返される場合、いくつかの設定が欠落しており、ユーザーはコード提案にアクセスできません。

この欠落している設定は、次のいずれかが原因である可能性があります:

- ライセンスが有効ではありません。解決するには、[ライセンスを確認または更新](../license_file.md#see-current-license-information)してください。
- GitLab Duoが、セルフホストモデルを使用するように設定されていません。解決するには、[GitLabインスタンスが、セルフホストモデルを使用するように設定されているかどうかを確認](#check-if-gitlab-instance-is-configured-to-use-self-hosted-models)します。

## GitLabインスタンスがセルフホストモデルを使用するように設定されているかどうかを確認する {#check-if-gitlab-instance-is-configured-to-use-self-hosted-models}

GitLab Duoが正しく設定されているかどうかを確認するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **セルフホスティングモデル**を選択します
1. **AIネイティブ機能**を展開します。
1. **機能**で、**コード提案**と**Code generation**（コード生成）が**セルフホストモデル**に設定されていることを確認します。

## AIゲートウェイURLが正しくセットアップされていることを確認してください {#check-that-the-ai-gateway-url-is-set-up-correctly}

AIゲートウェイURLが正しいことを確認するには、GitLab Railsコンソールで以下を実行します:

```ruby
Ai::Setting.instance.ai_gateway_url == "<your-ai-gateway-instance-url>"
```

AIゲートウェイがセットアップされていない場合は、[AIゲートウェイにアクセスするようにGitLabインスタンスを設定](configure_duo_features.md#configure-your-gitlab-instance-to-access-the-ai-gateway)します。

## GitLab DuoエージェントプラットフォームサービスURLを検証する {#validate-the-gitlab-duo-agent-platform-service-url}

エージェントプラットフォームサービスのURLが正しいことを確認するには、GitLab Railsコンソールで以下を実行します:

```ruby
Ai::Setting.instance.duo_agent_platform_service_url == "<your-duo-agent-platform-instance-url>"
```

エージェントプラットフォームサービスのURLはTCP URLであり、`http://`または`https://`のプレフィックスを持つことはできません。

エージェントプラットフォームのURLがセットアップされていない場合は、[URLにアクセスするようにGitLabインスタンスを設定](configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform)する必要があります。

## GitLabがAIゲートウェイにHTTPリクエストを送信できるかどうかを確認する {#check-if-gitlab-can-make-an-http-request-to-the-ai-gateway}

GitLab Railsコンソールで、次のコマンドを実行して、GitLabがAIゲートウェイにHTTPリクエストを送信できることを確認します:

```ruby
HTTParty.get('<your-aigateway-endpoint>/monitoring/healthz', headers: { 'accept' => 'application/json' }).code
```

レスポンスが`200`でない場合、これは次のいずれかを意味します:

- ネットワークが、GitLabがAIゲートウェイコンテナに到達できるように適切に設定されていません。ネットワーク管理者に連絡して、セットアップを検証してください。
- AIゲートウェイはリクエストを処理できません。この問題を解決するには、[AIゲートウェイがモデルにリクエストを送信できるかどうかを確認](#check-if-the-ai-gateway-can-make-a-request-to-the-model)します。

## AIゲートウェイがモデルにリクエストを送信できるかどうかを確認する {#check-if-the-ai-gateway-can-make-a-request-to-the-model}

AIゲートウェイコンテナから、コード提案のAIゲートウェイAPIにHTTPリクエストを送信します。以下の値を置き換えます:

- 使用しているモデルの名前で`<your_model_name>`。例: `mistral`、`codegemma`。
- モデルがホストされているエンドポイントで`<your_model_endpoint>`。

```shell
docker exec -it <ai-gateway-container> sh
curl --request POST "http://localhost:5052/v1/chat/agent" \
     --header 'accept: application/json' \
     --header 'Content-Type: application/json' \
     --data '{ "prompt_components": [ { "type": "string", "metadata": { "source": "string", "version": "string" }, "payload": { "content": "Hello", "provider": "litellm", "model": "<your_model_name>", "model_endpoint": "<your_model_endpoint>" } } ], "stream": false }'
```

リクエストが失敗した場合:

- AIゲートウェイが、セルフホストモデルを使用するように適切に設定されていない可能性があります。これを解決するには、[AIゲートウェイURLが正しくセットアップされていることを確認](#check-that-the-ai-gateway-url-is-set-up-correctly)します。
- AIゲートウェイがモデルにアクセスできない可能性があります。解決するには、[AIゲートウェイからモデルに到達できるかどうかを確認](#check-if-the-model-is-reachable-from-ai-gateway)します。
- モデル名またはエンドポイントが正しくない可能性があります。値をチェックし、必要に応じて修正します。

## AIゲートウェイがリクエストを処理できるかどうかを確認する {#check-if-ai-gateway-can-process-requests}

```shell
docker exec -it <ai-gateway-container> sh
curl '<your-aigateway-endpoint>/monitoring/healthz'
```

レスポンスが`200`でない場合、これはAIゲートウェイが正しくインストールされていないことを意味します。解決するには、[AIゲートウェイのインストール方法に関するドキュメント](../../install/install_ai_gateway.md)に従ってください。

## AIゲートウェイの環境変数が正しくセットアップされていることを確認する {#check-that-the-ai-gateway-environment-variables-are-set-up-correctly}

AIゲートウェイの環境変数が正しくセットアップされていることを確認するには、AIゲートウェイコンテナのコンソールで以下を実行します:

```shell
docker exec -it <ai-gateway-container> sh
echo $AIGW_CUSTOM_MODELS__ENABLED # must be true
```

環境変数が正しくセットアップされていない場合は、[コンテナを作成](../../install/install_ai_gateway.md#find-the-ai-gateway-image)してセットアップします。

## AIゲートウェイからモデルに到達できるかどうかを確認する {#check-if-the-model-is-reachable-from-ai-gateway}

AIゲートウェイコンテナでShellを作成し、モデルにcURLリクエストを送信します。AIゲートウェイがそのリクエストを送信できないことが判明した場合、これは次のことが原因である可能性があります:

1. モデルサーバーが正しく機能していません。
1. モデルがホストされている場所にリクエストを許可するように、コンテナ周辺のネットワーク設定が適切に設定されていません。

これを解決するには、ネットワーク管理者にお問い合わせください。

## AIゲートウェイがGitLabインスタンスにリクエストを送信できるかどうかを確認する {#check-if-ai-gateway-can-make-requests-to-your-gitlab-instance}

`AIGW_GITLAB_URL`で定義されたGitLabインスタンスは、リクエスト認証のためにAIゲートウェイコンテナからアクセスできる必要があります。インスタンスに到達できない場合（たとえば、プロキシ設定エラーが原因）、リクエストが次のエラーで失敗する可能性があります:

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

## イメージのプラットフォームがホストと一致しません {#the-images-platform-does-not-match-the-host}

[AIゲートウェイリリースを見つける](../../install/install_ai_gateway.md#find-the-ai-gateway-image)と、`The requested image's platform (linux/amd64) does not match the detected host`というエラーが表示される場合があります。

この回避策として、`--platform linux/amd64`を`docker run`コマンドに追加します:

```shell
docker run --platform linux/amd64 -e AIGW_GITLAB_URL=<your-gitlab-endpoint> <image>
```

## LLMサーバーがAIゲートウェイコンテナ内で使用できません {#llm-server-is-not-available-inside-the-ai-gateway-container}

LLMサーバーがAIゲートウェイコンテナと同じインスタンスにインストールされている場合、ローカルホストからはアクセスできない可能性があります。

これを解決するには:

1. AIゲートウェイコンテナからのローカルリクエストを有効にするには、`--network host`を`docker run`コマンドに含めます。
1. ポートの競合に対処するには、`-e AIGW_FASTAPI__METRICS_PORT=8083`フラグを使用します。

```shell
docker run --network host -e AIGW_GITLAB_URL=<your-gitlab-endpoint> -e AIGW_FASTAPI__METRICS_PORT=8083 <image>
```

## vLLM 404エラー {#vllm-404-error}

vLLMの使用中に**404 error**（404エラー）が発生した場合は、次の手順に従って問題を解決してください:

1. 次のコンテンツを含む`chat_template.jinja`という名前のチャットテンプレートファイルを作成します:

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

1. vLLMコマンドを実行するときは、必ず`--served-model-name`を指定してください。次に例を示します: 

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

1. 必要な機能が有効になっていて、使用可能であることを確認します:

   ```shell
   ::Ai::FeatureSetting.code_suggestions_self_hosted? # Should be true
   ```

## GitLabのセットアップを検証する {#verify-gitlab-setup}

GitLabセルフマネージドモデルのセットアップを検証するには、次のコマンドを実行します:

```shell
gitlab-rake gitlab:duo:verify_self_hosted_setup
```

## AIゲートウェイサーバーでログが生成されていません {#no-logs-generated-in-the-ai-gateway-server}

**AI gateway server**（AIゲートウェイサーバー）でログが生成されない場合は、次の手順に従ってトラブルシューティングを行います:

1. [AIログが有効になっている](logging.md#enable-logging)ことを確認します。
1. 次のコマンドを実行して、エラーがないかGitLab Railsコンソールログを表示します:

   ```shell
   sudo gitlab-ctl tail
   sudo gitlab-ctl tail sidekiq
   ```

1. ログで「Error」や「Exception」などのキーワードを探して、根本的な問題を特定します。

## AIゲートウェイコンテナでのSSL証明書エラーとキーの逆シリアライズの問題 {#ssl-certificate-errors-and-key-de-serialization-issues-in-the-ai-gateway-container}

AIゲートウェイコンテナ内でDuoチャットを開始しようとすると、SSL証明書エラーとキーのデシリアライズの問題が発生する可能性があります。

システムでPEMファイルの読み込む際に問題が発生し、次のようなエラーが発生する可能性があります:

```plaintext
JWKError: Could not deserialize key data. The data may be in an incorrect format, the provided password may be incorrect, or it may be encrypted with an unsupported algorithm.
```

SSL証明書エラーを解決するには:

- 次の環境変数を使用して、Dockerコンテナに適切な証明書バンドルパスを設定します:
  - `SSL_CERT_FILE=/path/to/ca-bundle.pem`
  - `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

## エラー: モデルIDメタの呼び出しはサポートされていません {#error-invocation-of-model-id-meta-isnt-supported}

AIGWログでは、モデル識別子の形式が正しくない場合、次のエラーが表示されます:

```plaintext
Invocation of model ID meta.llama3-3-70b-instruct-v1:0 with on-demand throughput isn\u2019t supported. Retry your request with the ID or ARN of an inference profile that contains this model
```

`model identifier`の形式が`bedrock/<region>.<model-id>`であることを確認します。ここで:

- `<region>`はAWSリージョンです（`us`など）。
- `<model-id>`は完全なモデル識別子です。

例: `bedrock/us.meta.llama3-3-70b-instruct-v1:0`。正しい形式を使用するようにモデル設定を更新します。

## 一般的なDuoチャットエラーのトラブルシューティング {#troubleshooting-common-duo-chat-errors}

### エラーA1000 {#error-a1000}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`というエラーが表示されることがあります。

このエラーは、処理中にタイムアウトが発生した場合に発生します。リクエストをもう一度試してください。

### エラーA1001 {#error-a1001}

`I'm sorry, I can't generate a response. Please try again. Error code: A1001`というエラーが表示されることがあります。

このエラーは、AIゲートウェイへの接続に問題があったことを意味します。ネットワーク設定を確認し、GitLabインスタンスからAIゲートウェイにアクセスできることを確認する必要がある場合があります。

[セルフホストモデルのデバッグスクリプト](#use-debugging-scripts)を使用して、GitLabインスタンスからAIゲートウェイにアクセスできるかどうか、および予期どおりに動作するかどうかを検証します。

問題が解決しない場合は、GitLabサポートチームに問題をレポートしてください。

### エラーA1002 {#error-a1002}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1002`というエラーが表示されることがあります。

このエラーは、AIゲートウェイからイベントが返されないか、GitLabがイベントの解析中に失敗した場合に発生します。エラーがないか、[AIゲートウェイログ](logging.md)を確認してください。

### エラーA1003 {#error-a1003}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1003`というエラーが表示されることがあります。

このエラーは通常、モデルからAIゲートウェイへのストリーミングの問題が原因で発生します。この問題を解決するには、以下を実行します:

1. AIゲートウェイコンテナで、次のコマンドを実行します:

   ```shell
   curl --request 'POST' \
   'http://localhost:5052/v2/chat/agent' \
   --header 'accept: application/json' \
   --header 'Content-Type: application/json' \
   --header 'x-gitlab-enabled-instance-verbose-ai-logs: true' \
   --data '{
     "messages": [
       {
         "role": "user",
         "content": "Hello",
         "context": null,
         "current_file": null,
         "additional_context": []
       }
     ],
     "model_metadata": {
       "provider": "custom_openai",
       "name": "mistral",
       "endpoint": "<change here>",
       "api_key": "<change here>",
       "identifier": "<change here>"
     },
     "unavailable_resources": [],
     "options": {
       "agent_scratchpad": {
         "agent_type": "react",
         "steps": []
       }
     }
   }'
   ```

   ストリーミングが機能している場合、チャンク化された応答が表示されます。そうでない場合は、空の応答が表示される可能性があります。

1. 通常これはモデルのデプロイの問題であるため、具体的なエラーメッセージについては、[AIゲートウェイのログ](logging.md)を確認してください。

1. 接続を検証するには、AIゲートウェイコンテナで`AIGW_CUSTOM_MODELS__DISABLE_STREAMING`環境変数を設定して、ストリーミングを無効にします:

   ```shell
   docker run .... -e AIGW_CUSTOM_MODELS__DISABLE_STREAMING=true ...
   ```

### エラーA9999 {#error-a9999}

`I'm sorry, I can't generate a response. Please try again. Error code: A9999`というエラーが表示されることがあります。

このエラーは、ReActエージェントで不明なエラーが発生した場合に発生します。リクエストをもう一度試してください。問題が解決しない場合は、GitLabサポートチームにレポートしてください。

## 機能にアクセスできないか、機能ボタンが表示されない {#feature-not-accessible-or-feature-button-not-visible}

機能が動作しない場合、または機能ボタン（たとえば、**`/troubleshoot`**）が表示されない場合は、以下のようにします:

1. 機能の`unit_primitive`が、[`gitlab-cloud-connector` gemのセルフホストモデルのユニットプリミティブの一覧](https://gitlab.com/gitlab-org/cloud-connector/gitlab-cloud-connector/-/blob/main/config/services/self_hosted_models.yml)にリストされているかどうかを確認します。

   このファイルに機能が見つからない場合、それがアクセスできない理由である可能性があります。

1. オプション。機能がリストされていない場合は、GitLabインスタンスで以下を設定することにより、これが問題の原因であることを検証できます:

   ```shell
   CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1
   ```

   次に、GitLabを再起動し、機能にアクセスできるようになるかどうかを確認します。

   **Important**（重要）: トラブルシューティング後、このフラグを設定**without**（せずに）GitLabを再起動します。

   {{< alert type="warning" >}}

   **`CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1`を本番環境で使用しないでください**。開発環境は本番環境を厳密に反映する必要があり、隠れたフラグや内部専用の回避策はありません。

   {{< /alert >}}

1. この問題を解決するには、以下を実行します:
   - GitLabチームのメンバーである場合は、[`#g_custom_models` Slackチャンネル経由で、カスタムモデルチームに連絡してください](https://gitlab.enterprise.slack.com/archives/C06DCB3N96F)。
   - お客様の場合は、[GitLabサポート](https://about.gitlab.com/support/)を通じて問題をレポートしてください。

## 関連トピック {#related-topics}

- [GitLab Duoのトラブルシューティング](../../user/gitlab_duo_chat/troubleshooting.md)
- [サポートエンジニアプレイブックとよくある問題](support_engineer_playbook.md)
