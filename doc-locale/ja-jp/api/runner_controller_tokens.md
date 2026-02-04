---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: RunnerコントローラートークンAPI
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

RunnerコントローラートークンAPIを使用すると、Runnerコントローラーの認証トークンを管理できます。Runnerコントローラーはこれらのトークンを使用して、GitLabインスタンスで認証を行い、Runnerを管理します。このAPIは、トークンを作成、一覧表示、ローテーション、失効するためのエンドポイントを提供します。

前提条件: 

- GitLabインスタンスへの管理者アクセス権が必要です。

## すべてのRunnerコントローラートークンを一覧表示する {#list-all-runner-controller-tokens}

すべてのRunnerコントローラートークンを一覧表示します。

```plaintext
GET /runner_controllers/:id/tokens
```

パラメータは以下のとおりです。

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `id`               | 整数      | はい      | RunnerコントローラーのID。 |

応答:

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性               | 型    | 説明 |
|-------------------------|---------|-------------|
| `id`                    | 整数 | Runnerコントローラートークンの固有識別子。 |
| `runner_controller_id`  | 整数 | 関連付けられたRunnerコントローラーのID。 |
| `description`           | 文字列  | トークンの説明。 |
| `created_at`            | 日時| トークンが作成された日時。 |
| `updated_at`            | 日時| トークンが最後に更新された日時。 |

リクエスト例: 

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens"
```

レスポンス例:

```json
[
    {
        "id": 1,
        "runner_controller_id": 1,
        "description": "Token for runner controller",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "runner_controller_id": 1,
        "description": "Another token for runner controller",
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## 単一のRunnerコントローラートークンを取得する {#retrieve-a-single-runner-controller-token}

IDで特定のRunnerコントローラートークンの詳細を取得します。

```plaintext
GET /runner_controllers/:id/tokens/:token_id
```

パラメータは以下のとおりです。

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `id`               | 整数      | はい      | RunnerコントローラーのID。 |
| `token_id`         | 整数      | はい      | RunnerコントローラートークンのID。 |

応答:

成功した場合、次のフィールドを含む[`200 OK`](rest/troubleshooting.md#status-codes)を返します:

| 属性               | 型    | 説明 |
|-------------------------|---------|-------------|
| `id`                    | 整数 | Runnerコントローラートークンの固有識別子。 |
| `runner_controller_id`  | 整数 | 関連付けられたRunnerコントローラーのID。 |
| `description`           | 文字列  | トークンの説明。 |
| `created_at`            | 日時| トークンが作成された日時。 |
| `updated_at`            | 日時| トークンが最後に更新された日時。 |

リクエスト例: 

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id"
```

レスポンス例:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## Runnerコントローラートークンを作成する {#create-a-runner-controller-token}

新しいRunnerコントローラートークンを作成します。

```plaintext
POST /runner_controllers/:id/tokens
```

パラメータは以下のとおりです。

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `id`               | 整数      | はい      | RunnerコントローラーのID。 |

サポートされている属性: 

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `description`      | 文字列       | はい      | トークンの説明。 |

応答:

成功した場合、次の属性を持つ[`201 Created`](rest/troubleshooting.md#status-codes)を返します:

| 属性               | 型    | 説明 |
|-------------------------|---------|-------------|
| `id`                    | 整数 | Runnerコントローラートークンの固有識別子。 |
| `runner_controller_id`  | 整数 | 関連付けられたRunnerコントローラーのID。 |
| `description`           | 文字列  | トークンの説明。 |
| `created_at`            | 日時| トークンが作成された日時。 |
| `updated_at`            | 日時| トークンが最後に更新された日時。 |
| `token`                 | 文字列  | 認証に使用される実際のトークン値。 |

リクエスト例: 

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --header "Content-Type: application/json" \
    --data '{"description": "Token for runner controller"}' \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens"
```

レスポンス例:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z",
    "token": "glrct-<token>"
}
```

## Runnerコントローラートークンを失効させる {#revoke-a-runner-controller-token}

既存のRunnerコントローラートークンを失効させます。

```plaintext
DELETE /runner_controllers/:id/tokens/:token_id
```

パラメータは以下のとおりです。

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `id`               | 整数      | はい      | RunnerコントローラーのID。 |
| `token_id`         | 整数      | はい      | RunnerコントローラートークンのID。 |

成功した場合は、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id"
```

## Runnerコントローラートークンをローテーションする {#rotate-a-runner-controller-token}

既存のRunnerコントローラートークンをローテーションします。

```plaintext
POST /runner_controllers/:id/tokens/:token_id/rotate
```

パラメータは以下のとおりです。

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `id`               | 整数      | はい      | RunnerコントローラーのID。 |
| `token_id`         | 整数      | はい      | RunnerコントローラートークンのID。 |

応答:

成功した場合、次の属性を持つ[`200 OK`](rest/troubleshooting.md#status-codes)を返します:

| 属性               | 型    | 説明 |
|-------------------------|---------|-------------|
| `id`                    | 整数 | Runnerコントローラートークンの固有識別子。 |
| `runner_controller_id`  | 整数 | 関連付けられたRunnerコントローラーのID。 |
| `description`           | 文字列  | トークンの説明。 |
| `created_at`            | 日時| トークンが作成された日時。 |
| `updated_at`            | 日時| トークンが最後に更新された日時。 |
| `token`                 | 文字列  | 認証に使用される実際のトークン値。 |

リクエスト例: 

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id/rotate"
```

レスポンス例:

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z",
    "token": "glrct-<token>"
}
```
