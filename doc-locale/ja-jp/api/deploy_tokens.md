---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: デプロイトークンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[デプロイトークン](../user/project/deploy_tokens/_index.md)を操作します。

## すべてのデプロイトークンをリスト表示する {#list-all-deploy-tokens}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabインスタンス全体のすべてのデプロイトークンをリスト表示します。このエンドポイントには管理者アクセスが必要です。

```plaintext
GET /deploy_tokens
```

パラメータは以下のとおりです:

| 属性 | 型     | 必須               | 説明 |
|-----------|----------|------------------------|-------------|
| `active`  | ブール値  | いいえ | アクティブステータスで制限します。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/deploy_tokens"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

## プロジェクトデプロイトークン {#project-deploy-tokens}

プロジェクトデプロイトークンAPIエンドポイントには、プロジェクトのメンテナーまたはオーナーロールが必要です。

### プロジェクトデプロイトークンをリスト表示する {#list-project-deploy-tokens}

プロジェクトのデプロイトークンをリスト表示します。

```plaintext
GET /projects/:id/deploy_tokens
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須               | 説明 |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `active`       | ブール値        | いいえ | アクティブステータスで制限します。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deploy_tokens"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### プロジェクトデプロイトークンを取得する {#retrieve-a-project-deploy-token}

単一プロジェクトのデプロイトークンをIDで取得する。

```plaintext
GET /projects/:id/deploy_tokens/:token_id
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須               | 説明 |
| ---------- | -------------- | ---------------------- | ----------- |
| `id`       | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `token_id` | 整数        | はい | デプロイトークンのID |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deploy_tokens/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "MyToken",
  "username": "gitlab+deploy-token-1",
  "expires_at": "2020-02-14T00:00:00.000Z",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository",
    "read_registry"
  ]
}
```

### プロジェクトデプロイトークンを作成する {#create-a-project-deploy-token}

プロジェクトデプロイトークンを作成します。

```plaintext
POST /projects/:id/deploy_tokens
```

パラメータは以下のとおりです:

| 属性    | 型             | 必須               | 説明 |
| ------------ | ---------------- | ---------------------- | ----------- |
| `id`         | 整数または文字列   | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`       | 文字列           | はい | 新規デプロイトークンの名前 |
| `scopes`     | 文字列の配列 | はい | デプロイトークンのスコープを示します。`read_repository`、`read_registry`、`write_registry`、`read_package_registry`、`write_package_registry`、`read_virtual_registry`、または`write_virtual_registry`のいずれか1つ以上である必要があります。 |
| `expires_at` | 日時         | いいえ | デプロイトークンの有効期限。値が指定されていない場合、有効期限は設定されません。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `username`   | 文字列           | いいえ | デプロイトークンのユーザー名。デフォルトは`gitlab+deploy-token-{n}`です。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "scopes": ["read_repository"]}' \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository"
  ]
}
```

### プロジェクトデプロイトークンを削除する {#delete-a-project-deploy-token}

プロジェクトからデプロイトークンを削除します。

```plaintext
DELETE /projects/:id/deploy_tokens/:token_id
```

パラメータは以下のとおりです:

| 属性  | 型           | 必須               | 説明 |
| ---------- | -------------- | ---------------------- | ----------- |
| `id`       | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `token_id` | 整数        | はい | デプロイトークンのID |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/13"
```

## グループデプロイトークン {#group-deploy-tokens}

グループのメンテナーまたはオーナーロールを持つユーザーは、グループデプロイトークンをリスト表示できます。グループのオーナーのみが、グループデプロイトークンを作成および削除できます。

### グループデプロイトークンをリスト表示する {#list-group-deploy-tokens}

グループのデプロイトークンをリスト表示します。

```plaintext
GET /groups/:id/deploy_tokens
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須               | 説明 |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | 整数または文字列 | はい | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `active`       | ブール値        | いいえ | アクティブステータスで制限します。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url"https://gitlab.example.com/api/v4/groups/1/deploy_tokens"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### グループデプロイトークンを取得する {#retrieve-a-group-deploy-token}

単一グループのグループデプロイトークンをIDで取得する。

```plaintext
GET /groups/:id/deploy_tokens/:token_id
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須               | 説明 |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | 整数または文字列 | はい | IDまたはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `token_id`  | 整数        | はい | デプロイトークンのID |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/deploy_tokens/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "MyToken",
  "username": "gitlab+deploy-token-1",
  "expires_at": "2020-02-14T00:00:00.000Z",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository",
    "read_registry"
  ]
}
```

### グループデプロイトークンを作成する {#create-a-group-deploy-token}

グループデプロイトークンを作成します。

```plaintext
POST /groups/:id/deploy_tokens
```

パラメータは以下のとおりです:

| 属性    | 型 | 必須  | 説明 |
| ------------ | ---- | --------- | ----------- |
| `id`         | 整数または文字列   | はい | IDまたはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`       | 文字列           | はい | 新規デプロイトークンの名前 |
| `scopes`     | 文字列の配列 | はい | デプロイトークンのスコープを示します。`read_repository`、`read_registry`、`write_registry`、`read_package_registry`、または`write_package_registry`のいずれか1つ以上である必要があります。 |
| `expires_at` | 日時         | いいえ | デプロイトークンの有効期限。値が指定されていない場合、有効期限は設定されません。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `username`   | 文字列           | いいえ | デプロイトークンのユーザー名。デフォルトは`gitlab+deploy-token-{n}`です。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "scopes": ["read_repository"]}' \
  --url "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_registry"
  ]
}
```

### グループデプロイトークンを削除する {#delete-a-group-deploy-token}

グループからデプロイトークンを削除します。

```plaintext
DELETE /groups/:id/deploy_tokens/:token_id
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須               | 説明 |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | 整数または文字列 | はい | IDまたはグループの[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `token_id`  | 整数        | はい | デプロイトークンのID |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/13"
```
