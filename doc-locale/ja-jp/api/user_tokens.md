---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザートークンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、パーソナルアクセストークンと代理トークンを操作します。詳細については、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)と[代理トークン](rest/authentication.md#impersonation-tokens)を参照してください。

## ユーザーのパーソナルアクセストークンを作成する {#create-a-personal-access-token-for-a-user}

{{< history >}}

- `expires_at`属性のデフォルトは、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213)されました。

{{< /history >}}

指定されたユーザーのパーソナルアクセストークンを作成します。

トークン値は応答に含まれていますが、後で取得することはできません。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:user_id/personal_access_tokens
```

サポートされている属性は以下のとおりです:

| 属性    | 型    | 必須 | 説明 |
|:-------------|:--------|:---------|:------------|
| `user_id`    | 整数 | はい      | ユーザーアカウントのID |
| `name`       | 文字列  | はい      | パーソナルアクセストークンの名前。 |
| `description`| 文字列  | いいえ       | パーソナルアクセストークンの説明。最大値: 255文字 |
| `expires_at` | 日付    | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。未定義の場合、日付は[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)に設定されます。 |
| `scopes`     | 配列   | はい      | 承認されたスコープの配列。可能な値のリストについては、[パーソナルアクセストークンのスコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を参照してください。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "expires_at=2017-04-04" \
  --data "scopes[]=api" \
  --url "https://gitlab.example.com/api/v4/users/42/personal_access_tokens"
```

レスポンス例:

```json
{
    "id": 3,
    "name": "mytoken",
    "revoked": false,
    "created_at": "2020-10-14T11:58:53.526Z",
    "description": "Test Token description",
    "scopes": [
        "api"
    ],
    "user_id": 42,
    "active": true,
    "expires_at": "2020-12-31",
    "token": "<your_new_access_token>"
}
```

## パーソナルアクセストークンを作成する {#create-a-personal-access-token}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131923)されました。

{{< /history >}}

アカウントのパーソナルアクセストークンを作成します。セキュリティ上の理由から、トークンは以下に制限されます:

- [`k8s_proxy`および`self_rotate`スコープに制限されています](../user/profile/personal_access_tokens.md#personal-access-token-scopes)。

トークン値は応答に含まれていますが、後で取得することはできません。

前提要件: 

- 認証済みである必要があります。

```plaintext
POST /user/personal_access_tokens
```

サポートされている属性:

| 属性    | 型   | 必須 | 説明 |
|:-------------|:-------|:---------|:------------|
| `name`       | 文字列 | はい      | パーソナルアクセストークンの名前。 |
| `description`| 文字列 | いいえ       | パーソナルアクセストークンの説明。最大値: 255文字 |
| `scopes`     | 配列  | はい      | 承認されたスコープの配列。`k8s_proxy`と`self_rotate`のみを受け入れます。 |
| `expires_at` | 配列  | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。未定義の場合、日付は[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)に設定されます。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "scopes[]=k8s_proxy" \
  --url "https://gitlab.example.com/api/v4/user/personal_access_tokens"
```

レスポンス例:

```json
{
    "id": 3,
    "name": "mytoken",
    "revoked": false,
    "created_at": "2020-10-14T11:58:53.526Z",
    "description": "Test Token description",
    "scopes": [
        "k8s_proxy"
    ],
    "user_id": 42,
    "active": true,
    "expires_at": "2020-10-15",
    "token": "<your_new_access_token>"
}
```

## ユーザーの代理トークンをすべてリスト表示する {#list-all-impersonation-tokens-for-a-user}

指定されたユーザーの代理トークンをすべてリスト表示します。

結果をフィルタリングするには、`page`および`per_page` [ページネーションパラメータ](rest/_index.md#offset-based-pagination)を使用します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
GET /users/:user_id/impersonation_tokens
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `user_id` | 整数 | はい      | ユーザーアカウントのID |
| `state`   | 文字列  | いいえ       | トークンを状態に基づいてフィルタリングします。使用可能な値: `all`、`active`、または`inactive`。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
```

レスポンス例:

```json
[
   {
      "active" : true,
      "user_id" : 2,
      "scopes" : [
         "api"
      ],
      "revoked" : false,
      "name" : "mytoken",
      "description": "Test Token description",
      "id" : 2,
      "created_at" : "2017-03-17T17:18:09.283Z",
      "impersonation" : true,
      "expires_at" : "2017-04-04",
      "last_used_at": "2017-03-24T09:44:21.722Z"
   },
   {
      "active" : false,
      "user_id" : 2,
      "scopes" : [
         "read_user"
      ],
      "revoked" : true,
      "name" : "mytoken2",
      "description": "Test Token description",
      "created_at" : "2017-03-17T17:19:28.697Z",
      "id" : 3,
      "impersonation" : true,
      "expires_at" : "2017-04-14",
      "last_used_at": "2017-03-24T09:44:21.722Z"
   }
]
```

## ユーザーの代理トークンを取得する {#get-an-impersonation-token-for-a-user}

指定されたユーザーの代理トークンを取得します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
GET /users/:user_id/impersonation_tokens/:impersonation_token_id
```

サポートされている属性は以下のとおりです:

| 属性                | 型    | 必須 | 説明 |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | 整数 | はい      | ユーザーアカウントのID |
| `impersonation_token_id` | 整数 | はい      | 代理トークンのID |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/2"
```

レスポンス例:

```json
{
   "active" : true,
   "user_id" : 2,
   "scopes" : [
      "api"
   ],
   "revoked" : false,
   "name" : "mytoken",
   "description": "Test Token description",
   "id" : 2,
   "created_at" : "2017-03-17T17:18:09.283Z",
   "impersonation" : true,
   "expires_at" : "2017-04-04"
}
```

## 代理トークンを作成する {#create-an-impersonation-token}

指定されたユーザーの代理トークンを作成します。これらのトークンは、ユーザーの代わりに行動するために使用され、APIコールだけでなく、Gitの読み取りと書き込みのアクションも実行できます。これらのトークンは、関連付けられたユーザーのプロフィールの設定ページには表示されません。

トークン値は応答に含まれていますが、後で取得することはできません。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
POST /users/:user_id/impersonation_tokens
```

サポートされている属性は以下のとおりです:

| 属性    | 型    | 必須 | 説明 |
|:-------------|:--------|:---------|:------------|
| `user_id`    | 整数 | はい      | ユーザーアカウントのID |
| `name`       | 文字列  | はい      | 代理トークンの名前 |
| `description`| 文字列  | いいえ       | 代理トークンの説明 |
| `expires_at` | 日付    | はい      | ISO形式(`YYYY-MM-DD`)の代理トークンの有効期限。未定義の場合、日付は[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)に設定されます。 |
| `scopes`     | 配列   | はい      | 承認されたスコープの配列。可能な値の一覧については、[パーソナルアクセストークンのスコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を参照してください。  |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "expires_at=2017-04-04" \
  --data "scopes[]=api" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
```

レスポンス例:

```json
{
   "id" : 2,
   "revoked" : false,
   "user_id" : 2,
   "scopes" : [
      "api"
   ],
   "token" : "<impersonation_token>",
   "active" : true,
   "impersonation" : true,
   "name" : "mytoken",
   "description": "Test Token description",
   "created_at" : "2017-03-17T17:18:09.283Z",
   "expires_at" : "2017-04-04"
}
```

## 代理トークンを失効させる {#revoke-an-impersonation-token}

指定されたユーザーの代理トークンを失効させます。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

```plaintext
DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id
```

サポートされている属性は以下のとおりです:

| 属性                | 型    | 必須 | 説明 |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | 整数 | はい      | ユーザーアカウントのID |
| `impersonation_token_id` | 整数 | はい      | 代理トークンのID |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/1"
```
