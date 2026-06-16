---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: コード提案のためのREST APIに関するドキュメント。
title: コード提案API
---

このAPIを使用してGitLab Duoのコード提案にアクセスします。

## コード補完を生成する {#generate-code-completions}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 16.2で、`code_suggestions_completion_api`という名前の[フラグ付き](../administration/feature_flags/_index.md)で導入されました。デフォルトでは無効になっています。この機能は実験です。
- このエンドポイントを呼び出す前にJWTを生成する要件は、GitLab 16.3で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127863)されました。
- GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/416371)になりました。[機能フラグ`code_suggestions_completion_api`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138174)は削除されました。
- GitLab 17.1で、`code_suggestions_context`という名前の[フラグ付き](../administration/feature_flags/_index.md)で、`context`と`user_instruction`の属性が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)されました。デフォルトでは無効になっています。
- `context`と`user_instruction`の属性は、GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)されました。機能フラグ`code_suggestions_context`は削除されました。

{{< /history >}}

```plaintext
POST /code_suggestions/completions
```

> [!note]
> このエンドポイントは、ユーザーごとに1分間に60リクエストのレート制限を設けています。

AI抽象化レイヤーを使用して、コード補完を生成します。

このエンドポイントへのリクエストは、[AIゲートウェイ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md)にプロキシされます。

パラメータは以下のとおりです:

| 属性          | 型    | 必須 | 説明 |
|--------------------|---------|----------|-------------|
| `current_file`     | ハッシュ    | はい      | サジェストが生成されるファイルについて。属性この属性が受け入れる文字列のリストについては、[ファイルの属性](#file-attributes)を参照してください。 |
| `intent`           | 文字列  | いいえ       | 完了リクエストの目的。これは`completion`または`generation`のいずれかです。 |
| `stream`           | ブール値 | いいえ       | 応答を準備ができた時点でより小さなチャンクとしてストリーミングするかどうか（該当する場合）。デフォルトは`false`です。 |
| `project_path`     | 文字列  | いいえ       | プロジェクトのパス。 |
| `generation_type`  | 文字列  | いいえ       | 生成リクエストのイベントタイプ。これは`comment`、`empty_function`、または`small_file`のいずれかです。 |
| `context`          | 配列   | いいえ       | コード提案に使用される追加のコンテキスト。この属性が受け入れるパラメータのリストについては、[コンテキスト属性](#context-attributes)を参照してください。 |
| `user_instruction` | 文字列  | いいえ       | ユーザーのコード提案への指示。 |

### ファイル属性 {#file-attributes}

`current_file`属性は、以下の文字列を受け入れます:

- `file_name` - ファイル名。必須。
- `content_above_cursor` - 現在のカーソル位置より上のファイルコンテンツ。必須。
- `content_below_cursor` - 現在のカーソル位置より下のファイルコンテンツ。オプション。

### コンテキスト属性 {#context-attributes}

`context`属性は、以下の属性を持つ要素のリストを受け入れます:

- `type` - コンテキスト要素のタイプ。これは`file`または`snippet`のいずれかです。
- `name` - コンテキスト要素の名前。ファイルまたはコードスニペットの名前。
- `content` - コンテキスト要素のコンテンツ。ファイルまたは関数の本体。

リクエスト例: 

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --data '{
      "current_file": {
        "file_name": "car.py",
        "content_above_cursor": "class Car:\n    def __init__(self):\n        self.is_running = False\n        self.speed = 0\n    def increase_speed(self, increment):",
        "content_below_cursor": ""
      },
      "intent": "completion"
    }' \
  --url "https://gitlab.example.com/api/v4/code_suggestions/completions"
```

レスポンス例: 

```json
{
  "id": "id",
  "model": {
    "engine": "vertex-ai",
    "name": "code-gecko"
  },
  "object": "text_completion",
  "created": 1688557841,
  "choices": [
    {
      "text": "\n        if self.is_running:\n            self.speed += increment\n            print(\"The car's speed is now",
      "index": 0,
      "finish_reason": "length"
    }
  ]
}
```

## コード提案が有効になっていることを検証する {#validate-that-code-suggestions-is-enabled}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138814)されました。

{{< /history >}}

このエンドポイントを使用して、次のいずれかを検証することができます:

- プロジェクトで`code_suggestions`が有効になっている。
- プロジェクトのグループで、`code_suggestions`がそのネームスペースの設定で有効になっている。

```plaintext
POST code_suggestions/enabled
```

サポートされている属性は以下のとおりです: 

| 属性         | 型    | 必須 | 説明 |
| ----------------- | ------- | -------- | ----------- |
| `project_path`    | 文字列  | はい      | 検証するプロジェクトのパス。 |

成功した場合、以下を返します:

- 機能が有効な場合は[`200`](rest/troubleshooting.md#status-codes)。
- 機能が無効な場合は[`403`](rest/troubleshooting.md#status-codes)。

さらに、パスが空であるか、またはプロジェクトが存在しない場合は、[`404`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/code_suggestions/enabled" \
  --header "PRIVATE-TOKEN: <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "project_path": "group/project_name"
    }'
```

## AIゲートウェイへの直接接続詳細をフェッチする {#fetch-direct-connection-details-for-the-ai-gateway}

{{< history >}}

- GitLab 17.0で`code_suggestions_direct_completions`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/452044)されました。デフォルトでは無効になっています。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/456443)になりました。機能フラグ`code_suggestions_direct_completions`は削除されました。

{{< /history >}}

```plaintext
POST /code_suggestions/direct_access
```

> [!note]
> このエンドポイントは、ユーザーごとに5分間に10リクエストのレート制限を設けています。

IDEやクライアントがAIゲートウェイに`completion`リクエストを直接送信するために使用できる、ユーザー固有の接続詳細を返します。これには、AIゲートウェイにプロキシする必要があるヘッダーと、必須の認証トークンが含まれます。

リクエスト例: 

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/direct_access"
```

レスポンス例: 

```json
{
  "base_url": "http://0.0.0.0:5052",
  "token": "a valid token",
  "expires_at": 1713343569,
  "headers": {
    "X-Gitlab-Instance-Id": "292c3c7c-c5d5-48ec-b4bf-f00b724ce560",
    "X-Gitlab-Realm": "saas",
    "X-Gitlab-Global-User-Id": "Df0Jhs9xlbetQR8YoZCKDZJflhxO0ZBI8uoRzmpnd1w=",
    "X-Gitlab-Host-Name": "gitlab.example.com"
  }
}
```

## 接続詳細をフェッチする {#fetch-connection-details}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/555060)されました。

{{< /history >}}

```plaintext
POST /code_suggestions/connection_details
```

> [!note]
> このエンドポイントは、ユーザーごとに1分間に10リクエストのレート制限を設けています。

IDEやクライアントがテレメトリーに使用できる、ユーザー固有の接続詳細を返します。これには、ユーザーが接続しているGitLabインスタンスに関するメタデータが含まれます。

リクエスト例: 

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/code_suggestions/connection_details"
```

レスポンス例: 

```json
{
  "instance_id": "292c3c7c-c5d5-48ec-b4bf-f00b724ce560",
  "instance_version": "18.2",
  "realm": "saas",
  "global_user_id": "Df0Jhs9xlbetQR8YoZCKDZJflhxO0ZBI8uoRzmpnd1w=",
  "host_name": "gitlab.example.com",
  "feature_enablement_type": "duo_pro",
  "saas_duo_pro_namespace_ids": "1000000"
}
```
