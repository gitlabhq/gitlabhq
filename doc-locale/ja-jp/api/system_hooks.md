---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: システムフックAPI
description: "REST APIを使用してシステムフックを設定および管理します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このAPIを使用して、[システムフック](../administration/system_hooks.md)を管理します。システムフックは、グループ内のすべてのプロジェクトとサブグループに影響を与える[グループWebhook](group_webhooks.md) 、および単一のプロジェクトに限定される[プロジェクトWebhook](project_webhooks.md)とは異なります。

前提要件: 

- 管理者である必要があります。

## システムフックのURLエンドポイントを設定する {#configure-a-url-endpoint-for-system-hooks}

システムフックのURLエンドポイントを設定するには、次の手順を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **システムフック**（`/admin/hooks`）を選択します。

## システムフックを一覧表示 {#list-system-hooks}

すべてのシステムフックのリストを取得します。

```plaintext
GET /hooks
```

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks"
```

レスポンス例:

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "name": "Hook name",
    "description": "Hook description",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true,
    "url_variables": []
  }
]
```

## システムフックを取得 {#get-system-hook}

IDでシステムフックを取得します。

```plaintext
GET /hooks/:id
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 整数 | はい      | フックのID。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/1"
```

レスポンス例:

```json
{
  "id": 1,
  "url": "https://gitlab.example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "created_at": "2016-10-31T12:32:15.192Z",
  "push_events": true,
  "tag_push_events": false,
  "merge_requests_events": true,
  "repository_update_events": true,
  "enable_ssl_verification": true,
  "url_variables": []
}
```

## 新しいシステムフックを追加 {#add-new-system-hook}

新しいシステムフックを追加します。

```plaintext
POST /hooks
```

| 属性                   | 型    | 必須 | 説明 |
|-----------------------------|---------|----------|-------------|
| `url`                       | 文字列  | はい      | フックのURL。 |
| `branch_filter_strategy`    | 文字列  | いいえ       | ブランチでプッシュイベントをフィルタリングします指定できる値は、`wildcard`（デフォルト）、`regex`、および`all_branches`です。 |
| `description`               | 文字列  | いいえ       | フックの説明。([導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)はGitLab 17.1からです。) |
| `enable_ssl_verification`   | ブール値 | いいえ       | フックをトリガーするときにSSL検証を実行します。 |
| `merge_requests_events`     | ブール値 | いいえ       | マージリクエストイベントでフックをトリガーします。 |
| `name`                      | 文字列  | いいえ       | フックの名前。([導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)はGitLab 17.1からです。) |
| `push_events`               | ブール値 | いいえ       | trueの場合、プッシュイベントでフックが起動します。 |
| `push_events_branch_filter` | 文字列  | いいえ       | 一致するブランチのプッシュイベントでのみフックをトリガーします。 |
| `repository_update_events`  | ブール値 | いいえ       | リポジトリ更新イベントでフックをトリガーします。 |
| `tag_push_events`           | ブール値 | いいえ       | trueの場合、新しいタグがプッシュされるとフックが起動します。 |
| `token`                     | 文字列  | いいえ       | 受信したペイロードを検証するためのシークレットトークン。レスポンスでは返されません。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks?url=https://gitlab.example.com/hook"
```

レスポンス例:

```json
[
  {
    "id":1,
    "url":"https://gitlab.example.com/hook",
    "name": "Hook name",
    "description": "Hook description",
    "created_at":"2016-10-31T12:32:15.192Z",
    "push_events":true,
    "tag_push_events":false,
    "merge_requests_events": true,
    "repository_update_events": true,
    "enable_ssl_verification":true,
    "url_variables": []
  }
]
```

## システムフックを更新 {#update-system-hook}

既存のシステムフックを更新します。

```plaintext
PUT /hooks/:hook_id
```

| 属性                   | 型    | 必須 | 説明 |
|-----------------------------|---------|----------|-------------|
| `hook_id`                   | 整数 | はい      | システムフックのID。 |
| `branch_filter_strategy`    | 文字列  | いいえ       | ブランチでプッシュイベントをフィルタリングします指定できる値は、`wildcard`（デフォルト）、`regex`、および`all_branches`です。 |
| `enable_ssl_verification`   | ブール値 | いいえ       | フックをトリガーするときにSSL検証を実行します。 |
| `merge_requests_events`     | ブール値 | いいえ       | マージリクエストイベントでフックをトリガーします。 |
| `push_events`               | ブール値 | いいえ       | trueの場合、プッシュイベントでフックが起動します。 |
| `push_events_branch_filter` | 文字列  | いいえ       | 一致するブランチのプッシュイベントでのみフックをトリガーします。 |
| `repository_update_events`  | ブール値 | いいえ       | リポジトリ更新イベントでフックをトリガーします。 |
| `tag_push_events`           | ブール値 | いいえ       | trueの場合、新しいタグがプッシュされるとフックが起動します。 |
| `token`                     | 文字列  | いいえ       | 受信したペイロードを検証するためのシークレットトークン。これはレスポンスで返されません。 |
| `url`                       | 文字列  | いいえ       | フックのURL。 |

## システムフックをテスト {#test-system-hook}

モッキングデータでシステムフックを実行します。

```plaintext
POST /hooks/:id
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 整数 | はい      | フックのID。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/1"
```

レスポンスは常にモッキングデータです:

```json
{
   "project_id" : 1,
   "owner_email" : "example@gitlabhq.com",
   "owner_name" : "Someone",
   "name" : "Ruby",
   "path" : "ruby",
   "event_name" : "project_create"
}
```

## システムフックを削除 {#delete-system-hook}

システムフックを削除します。

```plaintext
DELETE /hooks/:id
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 整数 | はい      | フックのID。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/hooks/2"
```

## URL変数を設定 {#set-a-url-variable}

```plaintext
PUT /hooks/:hook_id/url_variables/:key
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `hook_id` | 整数 | はい      | システムフックのID。 |
| `key`     | 文字列  | はい      | URL変数のキー。 |
| `value`   | 文字列  | はい      | URL変数の値。 |

成功すると、このエンドポイントはレスポンスコード`204 No Content`を返します。

## URL変数を削除 {#delete-a-url-variable}

```plaintext
DELETE /hooks/:hook_id/url_variables/:key
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 整数           | はい      | システムフックのID。 |
| `key`     | 文字列            | はい      | URL変数のキー。 |

成功すると、このエンドポイントはレスポンスコード`204 No Content`を返します。
