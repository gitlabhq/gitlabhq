---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コード提案のREST APIに関するドキュメント。
title: コード提案API
---

このAPIを使用して、[コード提案](../user/project/repository/code_suggestions/_index.md)機能にアクセスします。

## コード補完を生成 {#generate-code-completions}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 16.2で`code_suggestions_completion_api`という名前の[フラグ](../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは無効になっています。この機能は実験です。
- このエンドポイントを呼び出す前にJSON Webトークンを生成する必要があった要件は、GitLab 16.3で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127863)。
- GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/416371)になりました。[機能フラグ`code_suggestions_completion_api`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138174)は削除されました。
- `context`および`user_instruction`属性は、GitLab 17.1で`code_suggestions_context`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)されました。デフォルトでは無効になっています。
- `context`と`user_instruction`の属性は、GitLab 18.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)されました。機能フラグ`code_suggestions_context`は削除されました。

{{< /history >}}

```plaintext
POST /code_suggestions/completions
```

{{< alert type="note" >}}

このエンドポイントは、各ユーザーに対して1分あたり60リクエストにレート制限されています。

{{< /alert >}}

人工知能の抽象化レイヤーを使用して、コード補完を生成します。

このエンドポイントへのリクエストは、[AIゲートウェイ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md)にプロキシされます。

パラメータは以下のとおりです:

| 属性          | 型    | 必須 | 説明 |
|--------------------|---------|----------|-------------|
| `current_file`     | ハッシュ    | はい      | コード提案が生成されているファイルの属性。この属性が受け入れる文字列のリストについては、[ファイルの属性](#file-attributes)を参照してください。 |
| `intent`           | 文字列  | いいえ       | コード補完リクエストの目的。これは、`completion`または`generation`のいずれかです。 |
| `stream`           | ブール値 | いいえ       | 応答を、準備ができ次第、より小さいチャンクとしてストリーミングするかどうか（該当する場合）。デフォルトは`false`です。 |
| `project_path`     | 文字列  | いいえ       | プロジェクトのパス。 |
| `generation_type`  | 文字列  | いいえ       | 生成リクエストのイベントのタイプ。これは、`comment`、`empty_function`、または`small_file`にすることができます。 |
| `context`          | 配列   | いいえ       | コード提案に使用される追加のコンテキスト。この属性が受け入れるパラメータのリストについては、[コンテキストの属性](#context-attributes)を参照してください。 |
| `user_instruction` | 文字列  | いいえ       | コード提案に関するユーザーの指示。 |

### ファイルの属性 {#file-attributes}

`current_file`属性は、次の文字列を受け入れます:

- `file_name` - ファイル名。必須。
- `content_above_cursor` - 現在のカーソル位置より上のファイルの内容。必須。
- `content_below_cursor` - 現在のカーソル位置より下のファイルの内容。オプション。

### コンテキストの属性 {#context-attributes}

`context`属性は、次の属性を持つ要素のリストを受け入れます:

- `type` - コンテキスト要素のタイプ。これは、`file`または`snippet`のいずれかです。
- `name` - コンテキスト要素の名前。ファイルまたはスニペットの名前。
- `content` - コンテキスト要素の内容。ファイルまたは関数の本文。

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

このエンドポイントを使用して、以下を検証します:

- プロジェクトで`code_suggestions`が有効になっている。
- プロジェクトのグループのネームスペース設定で`code_suggestions`が有効になっている。

```plaintext
POST code_suggestions/enabled
```

サポートされている属性は以下のとおりです:

| 属性         | 型    | 必須 | 説明 |
| ----------------- | ------- | -------- | ----------- |
| `project_path`    | 文字列  | はい      | 検証するプロジェクトのパス。 |

成功した場合、以下を返します:

- 機能が有効な場合は、[`200`](rest/troubleshooting.md#status-codes)。
- 機能が無効になっている場合は[`403`](rest/troubleshooting.md#status-codes)。

さらに、パスが空であるか、プロジェクトが存在しない場合は[`404`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/code_suggestions/enabled" \
  --header "Private-Token: <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "project_path": "group/project_name"
    }' \

```

## AIゲートウェイの直接接続の詳細をフェッチする {#fetch-direct-connection-details-for-the-ai-gateway}

{{< history >}}

- GitLab 17.0で`code_suggestions_direct_completions`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/452044)されました。デフォルトでは無効になっています。
- GitLab 17.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/456443)になりました。機能フラグ`code_suggestions_direct_completions`は削除されました。

{{< /history >}}

```plaintext
POST /code_suggestions/direct_access
```

{{< alert type="note" >}}

このエンドポイントは、各ユーザーに対して5分あたり10リクエストにレート制限されています。

{{< /alert >}}

IDE/クライアントが`completion`リクエストをAIゲートウェイに直接送信するために使用できるユーザー固有の接続詳細を返します。これには、AIゲートウェイにプロキシする必要があるヘッダーと、必要な認証トークンが含まれます。

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

## 接続の詳細をフェッチする {#fetch-connection-details}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/555060)されました。

{{< /history >}}

```plaintext
POST /code_suggestions/connection_details
```

{{< alert type="note" >}}

このエンドポイントは、各ユーザーに対して1分あたり10リクエストにレート制限されています。

{{< /alert >}}

ユーザーが接続されているGitLabインスタンスに関するメタデータなど、テレメトリ用にIDE/クライアントで使用できるユーザー固有の接続の詳細を返します。

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
