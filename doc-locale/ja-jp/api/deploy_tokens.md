---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: デプロイトークンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[デプロイトークン](../user/project/deploy_tokens/_index.md)を操作します。

## すべてのデプロイトークンをリスト表示 {#list-all-deploy-tokens}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabインスタンス全体のすべてのデプロイトークンのリストを取得します。このエンドポイントには、管理者アクセスが必要です。

```plaintext
GET /deploy_tokens
```

パラメータは以下のとおりです:

| 属性 | 型     | 必須               | 説明 |
|-----------|----------|------------------------|-------------|
| `active`  | ブール値  | いいえ | アクティブなステータスで制限します。 |

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

プロジェクトデプロイトークンAPIエンドポイントには、プロジェクトのメンテナーロール以上が必要です。

### プロジェクトデプロイトークンの一覧 {#list-project-deploy-tokens}

プロジェクトのデプロイトークンのリストを取得します。

```plaintext
GET /projects/:id/deploy_tokens
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須               | 説明 |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `active`       | ブール値        | いいえ | アクティブなステータスで制限します。 |

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

### プロジェクトデプロイトークンの取得 {#get-a-project-deploy-token}

IDで単一のプロジェクトのデプロイトークンを取得します。

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

### プロジェクトデプロイトークンの作成 {#create-a-project-deploy-token}

プロジェクトの新しいデプロイトークンを作成します。

```plaintext
POST /projects/:id/deploy_tokens
```

パラメータは以下のとおりです:

| 属性    | 型             | 必須               | 説明 |
| ------------ | ---------------- | ---------------------- | ----------- |
| `id`         | 整数または文字列   | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`       | 文字列           | はい | 新しいデプロイトークンの名前 |
| `scopes`     | 文字列の配列 | はい | デプロイトークンスコープを示します。`read_repository`、`read_registry`、`write_registry`、`read_package_registry`、`write_package_registry`、`read_virtual_registry`、または`write_virtual_registry`のいずれか1つ以上である必要があります。 |
| `expires_at` | 日時         | いいえ | デプロイトークンの有効期限。値が指定されていない場合、有効期限は有効期限切れになりません。ISO 8601形式 (`2019-03-15T08:00:00Z`) で指定します。 |
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

### プロジェクトデプロイトークンを削除 {#delete-a-project-deploy-token}

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

グループのメンテナーロール以上のユーザー名を持つユーザー名は、グループデプロイトークンをリストできます。グループのオーナーのみが、グループデプロイトークンを作成および削除できます。

### グループデプロイトークンの一覧 {#list-group-deploy-tokens}

グループのデプロイトークンのリストを取得

```plaintext
GET /groups/:id/deploy_tokens
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須               | 説明 |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | 整数または文字列 | はい | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `active`       | ブール値        | いいえ | アクティブなステータスで制限します。 |

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

### グループデプロイトークンの取得 {#get-a-group-deploy-token}

IDで単一のグループのデプロイトークンを取得します。

```plaintext
GET /groups/:id/deploy_tokens/:token_id
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須               | 説明 |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | 整数または文字列 | はい | グループのIDまたは[URLエンコード](rest/_index.md#namespaced-paths)されたパス |
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

### グループデプロイトークンを作成 {#create-a-group-deploy-token}

グループの新しいデプロイトークンを作成します。

```plaintext
POST /groups/:id/deploy_tokens
```

パラメータは以下のとおりです:

| 属性    | 型 | 必須  | 説明 |
| ------------ | ---- | --------- | ----------- |
| `id`         | 整数または文字列   | はい | グループのIDまたは[URLエンコード](rest/_index.md#namespaced-paths)されたパス |
| `name`       | 文字列           | はい | 新しいデプロイトークンの名前 |
| `scopes`     | 文字列の配列 | はい | デプロイトークンスコープを示します。`read_repository`、`read_registry`、`write_registry`、`read_package_registry`、または`write_package_registry`のいずれか1つ以上である必要があります。 |
| `expires_at` | 日時         | いいえ | デプロイトークンの有効期限。値が指定されていない場合、有効期限は有効期限切れになりません。ISO 8601形式 (`2019-03-15T08:00:00Z`) で指定します。 |
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

### グループデプロイトークンを削除 {#delete-a-group-deploy-token}

グループからデプロイトークンを削除します。

```plaintext
DELETE /groups/:id/deploy_tokens/:token_id
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須               | 説明 |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | 整数または文字列 | はい | グループのIDまたは[URLエンコード](rest/_index.md#namespaced-paths)されたパス |
| `token_id`  | 整数        | はい | デプロイトークンのID |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/13"
```
