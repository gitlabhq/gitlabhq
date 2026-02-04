---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: RunnerコントローラーAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< history >}}

- GitLab 18.9で`FF_USE_JOB_ROUTER`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229)されました。この機能は[実験](../policy/development_stages_support.md)であり、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)の対象となります。

{{< /history >}}

RunnerコントローラーAPIを使用すると、GitLab Runnerジョブのオーケストレーションとアドミッションコントロール用のRunnerコントローラーを管理できます。このAPIは、Runnerコントローラーを作成、読み取り、更新、削除するためのエンドポイントを提供します。

前提条件: 

- GitLabインスタンスへの管理者アクセス権が必要です。

## すべてのRunnerコントローラーを一覧表示する {#list-all-runner-controllers}

すべてのRunnerコントローラーを一覧表示します。

```plaintext
GET /runner_controllers
```

応答:

成功した場合、次のレスポンス属性を持つ[`200 OK`](rest/troubleshooting.md#status-codes)を返します:

| 属性          | 型         | 説明 |
|--------------------|--------------|-------------|
| `id`               | 整数      | Runnerコントローラーの固有識別子。 |
| `description`      | 文字列       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | Runnerコントローラーの状態。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |
| `created_at`       | 日時     | Runnerコントローラーが作成された日時。 |
| `updated_at`       | 日時     | Runnerコントローラーが最後に更新された日時。 |

リクエスト例: 

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

レスポンス例:

```json
[
    {
        "id": 1,
        "description": "Runner controller",
        "state": "enabled",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "description": "Another runner controller",
        "state": "disabled",
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## 単一のRunnerコントローラーを取得する {#retrieve-a-single-runner-controller}

特定のRunnerコントローラーのIDによる詳細を取得します。

```plaintext
GET /runner_controllers/:id
```

応答:

成功した場合、次のレスポンス属性を持つ[`200 OK`](rest/troubleshooting.md#status-codes)を返します:

| 属性          | 型         | 説明 |
|--------------------|--------------|-------------|
| `id`               | 整数      | Runnerコントローラーの固有識別子。 |
| `description`      | 文字列       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | Runnerコントローラーの状態。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |
| `created_at`       | 日時     | Runnerコントローラーが作成された日時。 |
| `updated_at`       | 日時     | Runnerコントローラーが最後に更新された日時。 |

リクエスト例: 

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1"
```

レスポンス例:

```json
{
    "id": 1,
    "description": "Runner controller",
    "state": "enabled",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## Runnerコントローラーを登録 {#register-a-runner-controller}

新しいRunnerコントローラーを登録します。

```plaintext
POST /runner_controllers
```

サポートされている属性: 

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `description`      | 文字列       | いいえ       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | いいえ       | Runnerコントローラーの状態。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |

応答:

成功した場合、次のレスポンス属性を持つ[`201 Created`](rest/troubleshooting.md#status-codes)を返します:

| 属性          | 型         | 説明 |
|--------------------|--------------|-------------|
| `id`               | 整数      | Runnerコントローラーの固有識別子。 |
| `description`      | 文字列       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | Runnerコントローラーの状態。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |
| `created_at`       | 日時     | Runnerコントローラーが作成された日時。 |
| `updated_at`       | 日時     | Runnerコントローラーが最後に更新された日時。 |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "New runner controller", "state": "dry_run"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

レスポンス例:

```json
{
    "id": 3,
    "description": "New runner controller",
    "state": "dry_run",
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-05T00:00:00Z"
}
```

## Runnerコントローラーを更新 {#update-a-runner-controller}

IDで既存のRunnerコントローラーの詳細を更新します。

```plaintext
PUT /runner_controllers/:id
```

サポートされている属性: 

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `description`      | 文字列       | いいえ       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | いいえ       | Runnerコントローラーの状態。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |

成功した場合、次のレスポンス属性を持つ[`200 OK`](rest/troubleshooting.md#status-codes)を返します:

| 属性          | 型         | 説明 |
|--------------------|--------------|-------------|
| `id`               | 整数      | Runnerコントローラーの固有識別子。 |
| `description`      | 文字列       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | Runnerコントローラーの状態。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |
| `created_at`       | 日時     | Runnerコントローラーが作成された日時。 |
| `updated_at`       | 日時     | Runnerコントローラーが最後に更新された日時。 |

リクエスト例: 

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Updated runner controller", "state": "enabled"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

レスポンス例:

```json
{
    "id": 3,
    "description": "Updated runner controller",
    "state": "enabled",
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-06T00:00:00Z"
}
```

## Runnerコントローラーを削除 {#delete-a-runner-controller}

IDで特定のRunnerコントローラーを削除します。

```plaintext
DELETE /runner_controllers/:id
```

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```
