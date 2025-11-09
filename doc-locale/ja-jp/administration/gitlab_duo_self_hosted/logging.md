---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: セルフホストモデルのロギングを有効にします。
title: セルフホストモデルのロギングを有効にする
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
- GitLab 17.9で一般提供となりました。
- GitLabバージョン17.9で、UIからロギングのオン/オフを切り替える機能が追加されました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

GitLab Duo Self-Hostedの詳細なロギングにより、セルフホストモデルのパフォーマンスを監視し、問題をより効果的にデバッグできます。

## ロギングを有効にする {#enable-logging}

前提要件: 

- 管理者である必要があります。
- PremiumまたはUltimateプランのサブスクリプションが必要です。
- GitLab Duo Enterpriseアドオンが必要です。

ロギングを有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **設定の変更**セクションで、設定の変更を選択します。
1. **AIログの有効化**で、**Capture detailed information about AI-related activities and requests**（AI関連のアクティビティーとリクエストに関する詳細情報をキャプチャ）を選択します。
1. **変更を保存**を選択します。

これで、GitLabインスタンスのログにアクセスできるようになりました。

## GitLabインスタンスのログ {#logs-in-your-gitlab-installation}

ロギングの設定は、システムの操作に関する透明性を維持しながら、機密情報を保護するように設計されており、次のコンポーネントで構成されています:

- GitLabインスタンスへのリクエストをキャプチャするログ。
- ロギングの制御。
- `llm.log`ファイル

### GitLabインスタンスへのリクエストをキャプチャするログ {#logs-that-capture-requests-to-the-gitlab-instance}

とりわけ、`application.json`、`production_json.log`、`production.log`ファイルへのロギングは、GitLabインスタンスへのリクエストをキャプチャします:

- **Filtered Requests**（フィルタリングされたリクエスト）: これらのファイルのリクエストをログに記録しますが、（入力パラメータなどの）機密情報が**フィルタリング済み**されていることを確認します。これは、リクエストのメタデータ（たとえば、リクエストの種類、エンドポイント、応答ステータス）がキャプチャされる一方で、機密情報の漏洩を防ぐために、実際の入力データ（たとえば、クエリパラメータ、変数、コンテンツ）はログに記録されないことを意味します。
- **Example 1**（例1）: コード提案の補完リクエストの場合、ログは機密情報をフィルタリングしながら、リクエストの詳細をキャプチャします:

  ```json
  {
    "method": "POST",
    "path": "/api/graphql",
    "controller": "GraphqlController",
    "action": "execute",
    "status": 500,
    "params": [
      {"key": "query", "value": "[FILTERED]"},
      {"key": "variables", "value": "[FILTERED]"},
      {"key": "operationName", "value": "chat"}
    ],
    "exception": {
      "class": "NoMethodError",
      "message": "undefined method `id` for {:skip=>true}:Hash"
    },
    "time": "2024-08-28T14:13:50.328Z"
  }
  ```

  示されているように、エラー情報とリクエストの一般的な構造がログに記録されている一方で、機密情報の入力パラメータは`[FILTERED]`としてマークされています。

- **Example 2**（例2）: コード提案の補完リクエストの場合、ログは機密情報をフィルタリングしながら、リクエストの詳細もキャプチャします:

  ```json
  {
    "method": "POST",
    "path": "/api/v4/code_suggestions/completions",
    "status": 200,
    "params": [
      {"key": "prompt_version", "value": 1},
      {"key": "current_file", "value": {"file_name": "/test.rb", "language_identifier": "ruby", "content_above_cursor": "[FILTERED]", "content_below_cursor": "[FILTERED]"}},
      {"key": "telemetry", "value": []}
    ],
    "time": "2024-10-15T06:51:09.004Z"
  }
  ```

  示されているように、リクエストの一般的な構造がログに記録されている一方で、`content_above_cursor`や`content_below_cursor`などの機密情報の入力パラメータは、`[FILTERED]`としてマークされています。

### ロギング制御 {#logging-control}

Duoの設定ページから[AIログ](#enable-logging)のオンとオフを切り替えることで、これらのログのサブセットを制御できます。AIログをオフにすると、特定の操作のロギングが無効になります。

### `llm.log`ファイル {#the-llmlog-file}

[AIログ](#enable-logging)が有効になっている場合、GitLab Self-Managedインスタンスを通じて発生したコード生成イベントとチャットイベントは、[`llm.log`ログファイル](../logs/_index.md#llmlog)にキャプチャされます。ログファイルは、有効になっていない場合は何もキャプチャしません。コード補完のログは、AIゲートウェイに直接キャプチャされます。これらのログはGitLabに送信されず、GitLab Self-Managedインスタンスのインフラストラクチャでのみ表示されます。

- [`llm.log`内のログをローテーション、管理、エクスポート、および視覚化します](../logs/_index.md)。
- [ログファイルの場所を表示します（たとえば、ログを削除できるようにするため）。](../logs/_index.md#llm-input-and-output-logging)

### AIゲートウェイコンテナのログ {#logs-in-your-ai-gateway-container}

AIゲートウェイとGitLab DuoエージェントPlatformによって生成されたログの場所を指定するには、次を実行します:

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="your-signing-key" \
 -e AIGW_LOGGING__TO_FILE="aigateway.log" \
 -e DUO_WORKFLOW_LOGGING__TO_FILE="duo_agent_platform.log" \
 -v <your_aigateway_file_path>:aigateway.log \
 -v <your_duo_agent_platform_file_path>:duo_agent_platform.log \
 <image>
```

デフォルトでは、ログレベルは`INFO`に設定されています。ログレベルを`DEBUG`に変更するには、次を実行します:

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="your-signing-key" \
 -e AIGW_LOGGING__TO_FILE="aigateway.log" \
 -e DUO_WORKFLOW_LOGGING__TO_FILE="duo_agent_platform.log" \
 -e AIGW_LOGGING__LEVEL="DEBUG" \
 -e DUO_WORKFLOW_LOGGING__LEVEL="DEBUG" \
 -v <your_aigateway_file_path>:aigateway.log \
 -v <your_duo_agent_platform_file_path>:duo_agent_platform.log \
 <image>
```

さらに、`litellm`からのすべてのデバッグステートメントをログに記録するには、次の環境変数を追加します:

```shell
-e AIGW_LOGGING__ENABLE_LITELLM_LOGGING=true
```

ファイル名を指定しない場合、ログは出力にストリーミングされ、Dockerログを使用して管理することもできます。詳細については、[Docker Logsドキュメント](https://docs.docker.com/reference/cli/docker/container/logs/)を参照してください。

さらに、AIゲートウェイの実行の出力は、問題のデバッグに役立ちます。それらにアクセスするには:

- Dockerを使用する場合:

  ```shell
  docker logs <container-id>
  ```

- Kubernetesを使用する場合:

  ```shell
  kubectl logs <container-name>
  ```

これらのログをロギングソリューションにインジェストするには、ロギングプロバイダーのドキュメントを参照してください。

### ログ構造 {#logs-structure}

POSTリクエストが作成された場合（たとえば、`/chat/completions`エンドポイント）、サーバーはリクエストをログに記録します:

- ペイロード
- ヘッダー
- メタデータ

#### 1\.リクエストペイロード {#1-request-payload}

JSONペイロードには通常、次のフィールドが含まれています:

- `messages`: メッセージオブジェクトの配列。
  - 各メッセージオブジェクトには、以下が含まれています:
    - `content`: ユーザーの入力またはクエリを表す文字列。
    - `role`: メッセージ送信者のロールを示します（たとえば、`user`）。
- `model`: 使用するモデルを指定する文字列（たとえば、`mistral`）。
- `max_tokens`: 応答で生成するトークンの最大数を指定する整数。
- `n`: 生成する補完の数を示す整数。
- `stop`: 生成されたテキストの停止シーケンスを示す文字列の配列。
- `stream`: 応答をストリーミングする必要があるかどうかを示すブール値。
- `temperature`: 出力のランダム性を制御する浮動小数点数。

##### リクエスト例 {#example-request}

```json
{
    "messages": [
        {
            "content": "<s>[SUFFIX]None[PREFIX]# # build a hello world ruby method\n def say_goodbye\n    puts \"Goodbye, World!\"\n  end\n\ndef main\n  say_hello\n  say_goodbye\nend\n\nmain",
            "role": "user"
        }
    ],
    "model": "mistral",
    "max_tokens": 128,
    "n": 1,
    "stop": ["[INST]", "[/INST]", "[PREFIX]", "[MIDDLE]", "[SUFFIX]"],
    "stream": false,
    "temperature": 0.0
}
```

#### 2\.リクエストヘッダー {#2-request-headers}

リクエストヘッダーは、リクエストを行うクライアントに関する追加のコンテキストを提供します。キーヘッダーには、以下が含まれる場合があります:

- `Authorization`: APIアクセス用のベアラートークンが含まれています。
- `Content-Type`: リソースのメディアタイプを示します（たとえば、`JSON`）。
- `User-Agent`: リクエストを行っているクライアントソフトウェアに関する情報。
- `X-Stainless-`ヘッダー: クライアント環境に関する追加のメタデータを提供するさまざまなヘッダー。

##### リクエストヘッダーの例 {#example-request-headers}

```json
{
    "host": "0.0.0.0:4000",
    "accept-encoding": "gzip, deflate",
    "connection": "keep-alive",
    "accept": "application/json",
    "content-type": "application/json",
    "user-agent": "AsyncOpenAI/Python 1.51.0",
    "authorization": "Bearer <TOKEN>",
    "content-length": "364"
}
```

#### 3\.リクエストメタデータ {#3-request-metadata}

メタデータには、リクエストのコンテキストを記述するさまざまなフィールドが含まれています:

- `requester_metadata`: リクエスタに関する追加のメタデータ。
- `user_api_key`: リクエストに使用されるAPIキー（匿名化）。
- `api_version`: 使用されているAPIのバージョン。
- `request_timeout`: リクエストのタイムアウト期間。
- `call_id`: 呼び出しの固有識別子。

##### メタデータの例 {#example-metadata}

```json
{
    "user_api_key": "<ANONYMIZED_KEY>",
    "api_version": "1.48.18",
    "request_timeout": 600,
    "call_id": "e1aaa316-221c-498c-96ce-5bc1e7cb63af"
}
```

### レスポンス例 {#example-response}

サーバーは構造化されたモデル応答で応答します。次に例を示します: 

```python
Response: ModelResponse(
    id='chatcmpl-5d16ad41-c130-4e33-a71e-1c392741bcb9',
    choices=[
        Choices(
            finish_reason='stop',
            index=0,
            message=Message(
                content=' Here is the corrected Ruby code for your function:\n\n```ruby\ndef say_hello\n  puts "Hello, World!"\nend\n\ndef say_goodbye\n    puts "Goodbye, World!"\nend\n\ndef main\n  say_hello\n  say_goodbye\nend\n\nmain\n```\n\nIn your original code, the method names were misspelled as `say_hell` and `say_gobdye`. I corrected them to `say_hello` and `say_goodbye`. Also, there was no need for the prefix',
                role='assistant',
                tool_calls=None,
                function_call=None
            )
        )
    ],
    created=1728983827,
    model='mistral',
    object='chat.completion',
    system_fingerprint=None,
    usage=Usage(
        completion_tokens=128,
        prompt_tokens=69,
        total_tokens=197,
        completion_tokens_details=None,
        prompt_tokens_details=None
    )
)
```

### 推論サービスプロバイダーのログ {#logs-in-your-inference-service-provider}

GitLabは、推論サービスプロバイダーによって生成されたログを管理しません。ログの使用方法については、推論サービスプロバイダーのドキュメントを参照してください。

## GitLabとAIゲートウェイ環境でのロギングの動作 {#logging-behavior-in-gitlab-and-ai-gateway-environments}

GitLabは、`llm.log`を使用してAI関連のアクティビティーのロギング機能を提供します。これは、入力、出力、およびその他の関連情報をキャプチャします。ただし、ロギングの動作は、GitLabインスタンスとAIゲートウェイが**self-hosted**（セルフホスト）であるか、**cloud-connected**（クラウド接続）されているかによって異なります。

デフォルトでは、AI機能データの[データ保持ポリシー](../../user/gitlab_duo/data_usage.md#data-retention)をサポートするため、LLMのプロンプト入力と応答出力はログに含まれません。

## ロギングシナリオ {#logging-scenarios}

### GitLab Self-ManagedインスタンスとセルフホストモデルAIゲートウェイ {#gitlab-self-managed-and-self-hosted-ai-gateway}

この設定では、GitLabとAIゲートウェイの両方が顧客によってホストされています。

- **Logging Behavior**（ロギングの動作）: 完全なロギングが有効になり、すべてのプロンプト、入力、および出力がインスタンスの`llm.log`に記録されます。
- [AIログ](#enable-logging)が有効になっている場合、次の追加のデバッグ情報がログに記録されます:
  - 前処理されたプロンプト。
  - 最終的なプロンプト。
  - 追加のコンテキスト。
- **プライバシー**: GitLabとAIゲートウェイの両方がセルフホストされているため:
  - 顧客は、データの取り扱いを完全に制御できます。
  - 機密情報のロギングは、顧客の裁量で有効または無効にできます。

  {{< alert type="note" >}}

  AI機能がGitLab AIサードパーティベンダーモデルを使用している場合、[AIログが有効になっている](#enable-logging)場合でも、GitLabホストのAIゲートウェイに詳細なログは生成されません。これにより、機密情報の意図しない漏洩を防ぎます。

  {{< /alert >}}

### GitLab Self-ManagedインスタンスとGitLab管理のAIゲートウェイ（クラウド接続） {#gitlab-self-managed-and-gitlab-managed-ai-gateway-cloud-connected}

このシナリオでは、顧客はGitLabをホストしますが、AI処理のためにGitLab管理のAIゲートウェイに依存しています。

- **Logging Behavior**（ロギングの動作）: AIゲートウェイに送信されるプロンプトと入力は、個人を特定できる情報（PII）などの機密情報の漏洩を防ぐために、クラウド接続されたAIゲートウェイでは**not logged**（ログに記録されません）。
- **Expanded Logging**（拡張ロギング）: [AIログが有効になっている](#enable-logging)場合でも、機密情報の意図しない漏洩を回避するために、GitLab管理のAIゲートウェイに詳細なログは生成されません。
  - この設定では、ロギングは**minimal**（最小限）のままであり、拡張ロギング機能はデフォルトで無効になっています。
- **プライバシー**: この設定は、クラウド環境で機密情報がログに記録されないように設計されています。

## AIログ {#ai-logs}

[AIログ](#enable-logging)は、プロンプトや入力などの追加のデバッグ情報がログに記録されるかどうかを制御します。この設定は、AI関連のアクティビティーをモニタリングおよびデバッグするために不可欠です。

### デプロイ設定による動作 {#behavior-by-deployment-setup}

- **GitLab Self-Managed and self-hosted AI gateway**（GitLab Self-ManagedインスタンスとセルフホストモデルAIゲートウェイ）:
  - この設定により、セルフホストモデルインスタンスとAIゲートウェイの両方で`llm.log`への詳細なロギングが可能になり、AIモデルの入力と出力がキャプチャされます。
  - 機能がGitLabサードパーティベンダーモデルを使用している場合でも、クラウド接続されたAIゲートウェイでは、機密情報を保護するためにロギングは無効のままです。
- **GitLab Self-Managed and GitLab-managed AI gateway**（GitLab Self-ManagedインスタンスとGitLab管理のAIゲートウェイ）:
  - この設定により、GitLab Self-Managedインスタンスの`llm.log`への詳細なロギングが可能になります。
  - この設定は、GitLab管理のAIゲートウェイの拡張ロギングを有効に**not**（しません）。機密情報を保護するために、クラウド接続されたAIゲートウェイのロギングは無効のままです。

### クラウド接続されたAIゲートウェイでのロギング {#logging-in-cloud-connected-ai-gateways}

機密情報の潜在的なデータ漏洩を防ぐために、クラウド接続されたAIゲートウェイを使用する場合、拡張ロギング（プロンプトと入力を含む）は意図的に無効になっています。PIIの漏洩を防ぐことが優先事項です。

### AIゲートウェイとGitLab間のログの相互参照 {#cross-referencing-logs-between-the-ai-gateway-and-gitlab}

プロパティ`correlation_id`はすべてのリクエストに割り当てられ、リクエストに応答するさまざまなコンポーネント間でやり取りされます。詳細については、[相関IDを使用したログの検索に関するドキュメント](../logs/tracing_correlation_id.md)を参照してください。

相関IDは、AIゲートウェイとGitLabログにあります。ただし、モデルプロバイダーのログには存在しません。

#### 関連トピック {#related-topics}

- [jqを使用したGitLabログの解析中](../logs/log_parsing.md)
- [相関IDのログの検索](../logs/tracing_correlation_id.md#searching-your-logs-for-the-correlation-id)
