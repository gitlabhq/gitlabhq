---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: RunnerコントローラーAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< history >}}

- GitLab 18.9で`FF_USE_JOB_ROUTER`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229)されました。この機能は[実験的機能](../policy/development_stages_support.md)であり、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)の対象となります。
- `connected`フィールドがGitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/591615)されました。

{{< /history >}}

RunnerコントローラーAPIを使用すると、CI/CDジョブの受け入れ管理のためにRunnerコントローラーを管理できます。Runnerコントローラーはジョブルーターに接続し、カスタムポリシーに対してジョブを評価して、それらを受け入れるか拒否するかを決定します。このAPIは、Runnerコントローラーの作成、読み取り、更新、削除のためのエンドポイントを提供します。

前提条件: 

- GitLabインスタンスへの管理者アクセス権が必要です。

## すべてのRunnerコントローラーをリストする {#list-all-runner-controllers}

すべてのRunnerコントローラーをリストします。

```plaintext
GET /runner_controllers
```

応答:

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性          | 型         | 説明 |
|--------------------|--------------|-------------|
| `id`               | 整数      | Runnerコントローラーの固有識別子。 |
| `description`      | 文字列       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | Runnerコントローラーのステータス。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |
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

IDを指定して、特定のRunnerコントローラーの詳細を取得します。

```plaintext
GET /runner_controllers/:id
```

応答:

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性          | 型         | 説明 |
|--------------------|--------------|-------------|
| `id`               | 整数      | Runnerコントローラーの固有識別子。 |
| `description`      | 文字列       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | Runnerコントローラーのステータス。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |
| `connected`        | ブール値      | Runnerコントローラーが現在接続されているかどうか。Runnerコントローラーは、過去1時間以内にアクティブなトークンのいずれかを1つ以上使用した場合に接続されていると見なされます。 |
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
    "connected": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## Runnerコントローラーを登録する {#register-a-runner-controller}

新しいRunnerコントローラーを登録します。

```plaintext
POST /runner_controllers
```

サポートされている属性は以下のとおりです: 

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `description`      | 文字列       | いいえ       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | いいえ       | Runnerコントローラーのステータス。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |

応答:

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性          | 型         | 説明 |
|--------------------|--------------|-------------|
| `id`               | 整数      | Runnerコントローラーの固有識別子。 |
| `description`      | 文字列       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | Runnerコントローラーのステータス。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |
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

## Runnerコントローラーを更新する {#update-a-runner-controller}

IDを指定して、既存のRunnerコントローラーの詳細を更新します。

```plaintext
PUT /runner_controllers/:id
```

サポートされている属性は以下のとおりです: 

| 属性          | 型         | 必須 | 説明 |
|--------------------|--------------|----------|-------------|
| `description`      | 文字列       | いいえ       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | いいえ       | Runnerコントローラーのステータス。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性          | 型         | 説明 |
|--------------------|--------------|-------------|
| `id`               | 整数      | Runnerコントローラーの固有識別子。 |
| `description`      | 文字列       | Runnerコントローラーの説明。 |
| `state`            | 文字列       | Runnerコントローラーのステータス。有効な値は、`disabled`（デフォルト）、`enabled`、または`dry_run`です。 |
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

## Runnerコントローラーを削除する {#delete-a-runner-controller}

IDを指定して、特定のRunnerコントローラーを削除します。

```plaintext
DELETE /runner_controllers/:id
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

## Runnerコントローラーのスコープ {#runner-controller-scopes}

Runnerコントローラーのスコープは、Runnerコントローラーが入場管理のために評価するジョブを定義します。Runnerコントローラーは、入場リクエストを受信するために少なくとも1つのスコープを持つ必要があります。スコープがない場合、コントローラーはその状態が`enabled`または`dry_run`であっても非アクティブのままです。

Runnerコントローラーのスコープは、相互に排他的な2つのスコープタイプをサポートしています:

- **Instance scope**: Runnerコントローラーは、GitLabインスタンス内のすべてのRunnerのジョブを評価します。
- **Runner scope**: Runnerコントローラーは、特定のインスタンスRunnerに対してのみジョブを評価します。

Runnerコントローラーは、インスタンススコープを持つことも、1つ以上のRunnerスコープを持つこともできますが、両方を持つことはできません。

> [!note]
> 利用可能なインスタンスおよびRunnerスコープのみです。追加のスコープタイプ（グループ、プロジェクト）は[イシュー586419](https://gitlab.com/gitlab-org/gitlab/-/issues/586419)で提案されています。

### Runnerコントローラーのすべてのスコープを一覧表示する {#list-all-scopes-for-a-runner-controller}

特定のRunnerコントローラー用に設定されたすべてのスコープを一覧表示します:

```plaintext
GET /runner_controllers/:id/scopes
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明                              |
|-----------|---------|----------|------------------------------------------|
| `id`      | 整数 | はい      | RunnerコントローラーのID。         |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                              | 型         | 説明                                               |
|----------------------------------------|--------------|-----------------------------------------------------------|
| `instance_level_scopings`              | オブジェクト配列 | Runnerコントローラーのインスタンススコープのリスト。 |
| `instance_level_scopings[].created_at` | 日時     | スコープが作成された日時。           |
| `instance_level_scopings[].updated_at` | 日時     | スコープが最後に更新された日時。      |
| `runner_level_scopings`                | オブジェクト配列 | RunnerコントローラーのRunnerスコープのリスト。  |
| `runner_level_scopings[].runner_id`    | 整数      | RunnerのID。                                     |
| `runner_level_scopings[].created_at`   | 日時     | スコープが作成された日時。           |
| `runner_level_scopings[].updated_at`   | 日時     | スコープが最後に更新された日時。      |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes"
```

レスポンス例: 

```json
{
    "instance_level_scopings": [
        {
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z"
        }
    ],
    "runner_level_scopings": []
}
```

### インスタンススコープを追加 {#add-instance-scope}

Runnerコントローラーにインスタンススコープを追加します。追加すると、RunnerコントローラーはGitLabインスタンス内のすべてのRunnerに対してジョブを評価します。

Runnerコントローラーは1つのインスタンススコープのみを持つことができます。インスタンススコープがすでに存在する場合、このエンドポイントはエラーを返します。

```plaintext
POST /runner_controllers/:id/scopes/instance
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明                              |
|-----------|---------|----------|------------------------------------------|
| `id`      | 整数 | はい      | RunnerコントローラーのID。         |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性               | 型     | 説明                                          |
|-------------------------|----------|------------------------------------------------------|
| `created_at`            | 日時 | スコープが作成された日時。      |
| `updated_at`            | 日時 | スコープが最後に更新された日時。 |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/instance"
```

レスポンス例: 

```json
{
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
}
```

### インスタンススコープを削除 {#remove-instance-scope}

Runnerコントローラーからインスタンススコープを削除します。

```plaintext
DELETE /runner_controllers/:id/scopes/instance
```

サポートされている属性は以下のとおりです: 

| 属性     | 型    | 必須 | 説明                                          |
|---------------|---------|----------|------------------------------------------------------|
| `id`          | 整数 | はい      | RunnerコントローラーのID。                     |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/instance"
```

### Runnerスコープを追加 {#add-runner-scope}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/586417)されました。

{{< /history >}}

RunnerコントローラーにRunnerスコープを追加します。追加すると、Runnerコントローラーは指定されたRunnerに対してのみジョブを評価します。

インスタンススコープを持つRunnerコントローラーは、Runnerスコープを持つことはできません。Runnerスコープを追加する前にインスタンススコープを削除してください。

```plaintext
POST /runner_controllers/:id/scopes/runners/:runner_id
```

サポートされている属性は以下のとおりです: 

| 属性   | 型    | 必須 | 説明                      |
|-------------|---------|----------|----------------------------------|
| `id`        | 整数 | はい      | RunnerコントローラーのID。 |
| `runner_id` | 整数 | はい      | RunnerのID。インスタンスRunnerである必要があります。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性    | 型     | 説明                                          |
|--------------|----------|------------------------------------------------------|
| `runner_id`  | 整数  | RunnerのID。                                |
| `created_at` | 日時 | スコープが作成された日時。      |
| `updated_at` | 日時 | スコープが最後に更新された日時。 |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/runners/5"
```

レスポンス例: 

```json
{
    "runner_id": 5,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
}
```

### Runnerスコープを削除 {#remove-runner-scope}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/586417)されました。

{{< /history >}}

RunnerコントローラーからRunnerスコープを削除します。

```plaintext
DELETE /runner_controllers/:id/scopes/runners/:runner_id
```

サポートされている属性は以下のとおりです: 

| 属性   | 型    | 必須 | 説明                      |
|-------------|---------|----------|----------------------------------|
| `id`        | 整数 | はい      | RunnerコントローラーのID。 |
| `runner_id` | 整数 | はい      | RunnerのID。            |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/runners/5"
```
