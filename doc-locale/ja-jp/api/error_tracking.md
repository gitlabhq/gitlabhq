---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: エラートラッキングAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトのError Tracking機能とやり取りします。詳細については、[Error Tracking](../operations/error_tracking.md)を参照してください。

前提要件: 

- メンテナーロール以上が必要です。

## Error Tracking設定を取得します {#get-error-tracking-settings}

指定されたプロジェクトのError Tracking設定を取得します。

```plaintext
GET /projects/:id/error_tracking/settings
```

| 属性 | 型    | 必須 | 説明           |
| --------- | ------- | -------- | --------------------- |
| `id`      | 整数 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings"
```

レスポンス例:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## Error Tracking設定を作成します {#create-error-tracking-settings}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393035/)されました。

{{< /history >}}

指定されたプロジェクトのError Tracking設定を作成します。

{{< alert type="note" >}}

このAPIは、[integrated error tracking](../operations/integrated_error_tracking.md)で使用する場合にのみ使用できます。

{{< /alert >}}

```plaintext
PUT /projects/:id/error_tracking/settings
```

サポートされている属性は以下のとおりです:

| 属性    | 型    | 必須 | 説明                                                                                                                                                     |
| ------------ | ------- |----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`         | 整数 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                            |
| `active`     | ブール値 | はい      | `true`を渡してError Tracking設定構成を有効にするか、`false`を渡して無効にします。                                                                        |
| `integrated` | ブール値 | はい      | `true`を渡して、統合されたError Trackingバックエンドを有効にします。 |

リクエスト例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true&integrated=true"
```

レスポンス例:

```json
{
  "active": true,
  "project_name": null,
  "sentry_external_url": null,
  "api_url": null,
  "integrated": true
}
```

## Error Trackingプロジェクト設定を有効化します {#activate-the-error-tracking-project-settings}

指定されたプロジェクトのError Tracking設定をアクティブ化または非アクティブ化します。

```plaintext
PATCH /projects/:id/error_tracking/settings
```

| 属性    | 型    | 必須 | 説明           |
| ------------ | ------- | -------- | --------------------- |
| `id`         | 整数 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `active`     | ブール値 | はい      | `true`を渡して、すでに構成されているError Tracking設定を有効にするか、`false`を渡して無効にします。 |
| `integrated` | ブール値 | いいえ       | `true`を渡して、統合されたError Trackingバックエンドを有効にします。 |

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true"
```

レスポンス例:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## すべてのプロジェクトクライアントキーを一覧表示します {#list-all-project-client-keys}

指定されたプロジェクトのすべての[integrated error tracking](../operations/integrated_error_tracking.md)クライアントキーをリストします。

```plaintext
GET /projects/:id/error_tracking/client_keys
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "active": true,
    "public_key": "glet_aa77551d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
  },
  {
    "id": 3,
    "active": true,
    "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
  }
]
```

## クライアントキーを作成します {#create-a-client-key}

指定されたプロジェクトの[integrated error tracking](../operations/integrated_error_tracking.md)クライアントキーを作成します。公開キーの属性は自動的に生成されます。

```plaintext
POST /projects/:id/error_tracking/client_keys
```

| 属性  | 型 | 必須 | 説明 |
| ---------  | ---- | -------- | ----------- |
| `id`       | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

レスポンス例:

```json
{
  "id": 3,
  "active": true,
  "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
  "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
}
```

## クライアントキーを削除します {#delete-a-client-key}

指定されたプロジェクトから[integrated error tracking](../operations/integrated_error_tracking.md)クライアントキーを削除します。

```plaintext
DELETE /projects/:id/error_tracking/client_keys/:key_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key_id`  | 整数 | はい | クライアントキーのID。 |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys/13"
```
