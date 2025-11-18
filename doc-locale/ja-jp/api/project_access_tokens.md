---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトアクセストークンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトアクセストークンを操作します。詳細については、[プロジェクトアクセストークン](../user/project/settings/project_access_tokens.md)を参照してください。

## すべてのプロジェクトアクセストークンのリストを取得する {#list-all-project-access-tokens}

{{< history >}}

- `state`属性は、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)されました。

{{< /history >}}

指定されたプロジェクトのすべてのプロジェクトアクセストークンのリストを取得します。

```plaintext
GET projects/:id/access_tokens
GET projects/:id/access_tokens?state=inactive
```

| 属性          | 型                | 必須 | 説明 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 整数または文字列   | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `created_after`    | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より後に作成されたトークンを返します。 |
| `created_before`   | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より前に作成されたトークンを返します。 |
| `expires_after`    | 日付（ISO 8601）     | いいえ       | 定義されている場合、指定された時刻より後に有効期限が切れるトークンを返します。 |
| `expires_before`   | 日付（ISO 8601）     | いいえ       | 定義されている場合、指定された時刻より前に有効期限が切れるトークンを返します。 |
| `last_used_after`  | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より後に最終使用されたトークンを返します。 |
| `last_used_before` | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より前に最終使用されたトークンを返します。 |
| `revoked`          | ブール値             | いいえ       | `true`の場合、失効したトークンのみを返します。 |
| `search`           | 文字列              | いいえ       | 定義されている場合、指定された値が名前に含まれたトークンを返します。 |
| `sort`             | 文字列              | いいえ       | 定義されている場合、指定された値で結果を並べ替えます。使用できる値は、`created_asc`、`created_desc`、`expires_asc`、`expires_desc`、`last_used_asc`、`last_used_desc`、`name_asc`、`name_desc`です。|
| `state`            | 文字列              | いいえ       | 定義されている場合、指定された状態のトークンを返します。使用できる値は、`active`と`inactive`です。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens"
```

```json
[
   {
      "user_id" : 141,
      "scopes" : [
         "api"
      ],
      "name" : "token",
      "expires_at" : "2021-01-31",
      "id" : 42,
      "active" : true,
      "created_at" : "2021-01-20T22:11:48.151Z",
      "description": "Test Token description",
      "last_used_at" : null,
      "revoked" : false,
      "access_level" : 40
   },
   {
      "user_id" : 141,
      "scopes" : [
         "read_api"
      ],
      "name" : "token-2",
      "expires_at" : "2021-01-31",
      "id" : 43,
      "active" : false,
      "created_at" : "2021-01-21T12:12:38.123Z",
      "description": "Test Token description",
      "revoked" : true,
      "last_used_at" : "2021-02-13T10:34:57.178Z",
      "access_level" : 40
   }
]
```

## プロジェクトアクセストークンの詳細を取得する {#get-details-on-a-project-access-token}

プロジェクトアクセストークンの詳細を取得します。

```plaintext
GET projects/:id/access_tokens/:token_id
```

| 属性  | 型              | 必須 | 説明 |
| ---------- | ----------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `token_id` | 整数または文字列 | はい      | ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
```

```json
{
   "user_id" : 141,
   "scopes" : [
      "api"
   ],
   "name" : "token",
   "expires_at" : "2021-01-31",
   "id" : 42,
   "active" : true,
   "created_at" : "2021-01-20T22:11:48.151Z",
   "description": "Test Token description",
   "revoked" : false,
   "access_level": 40,
   "last_used_at": "2022-03-15T11:05:42.437Z"
}
```

## プロジェクトアクセストークンを作成する {#create-a-project-access-token}

{{< history >}}

- `expires_at`属性のデフォルトは、GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213)されました。

{{< /history >}}

指定されたプロジェクトのプロジェクトアクセストークンを作成します。自分のアカウントよりもレベルが高いアクセスレベルでトークンを作成することはできません。たとえば、メンテナーロールのユーザーは、オーナーロールでプロジェクトアクセストークンを作成できません。

このエンドポイントでパーソナルアクセストークンを使用する必要があります。プロジェクトアクセストークンで認証することはできません。この機能を追加するための[オープン機能リクエスト](https://gitlab.com/gitlab-org/gitlab/-/issues/359953)があります。

```plaintext
POST projects/:id/access_tokens
```

| 属性      | 型              | 必須 | 説明 |
| -------------- | ----------------- | -------- | ----------- |
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`         | 文字列            | はい      | トークンの名前。 |
| `description`  | 文字列            | いいえ       | プロジェクトアクセストークンの説明。 |
| `scopes`       | `Array[String]`   | はい      | トークンで使用可能な[スコープ](../user/project/settings/project_access_tokens.md#scopes-for-a-project-access-token)のリスト。 |
| `access_level` | 整数           | いいえ       | トークンのロール。使用可能な値: `10`（ゲスト）、`15`（プランナー）、`20`（レポーター）、`30`（デベロッパー）、`40`（メンテナー）、および`50`（オーナー）。デフォルト値: `40`。 |
| `expires_at`   | 日付              | はい      | ISO形式（`YYYY-MM-DD`）のトークンの有効期限。未定義の場合、日付は[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)に設定されます。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_personal_access_token>" \
  --header "Content-Type:application/json" \
  --data '{ "name":"test_token", "scopes":["api", "read_repository"], "expires_at":"2021-01-31", "access_level":30 }' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens"
```

```json
{
   "scopes" : [
      "api",
      "read_repository"
   ],
   "active" : true,
   "name" : "test",
   "revoked" : false,
   "created_at" : "2021-01-21T19:35:37.921Z",
   "description": "Test Token description",
   "user_id" : 166,
   "id" : 58,
   "expires_at" : "2021-01-31",
   "token" : "D4y...Wzr",
   "access_level": 30
}
```

## プロジェクトアクセストークンをローテーションする {#rotate-a-project-access-token}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/403042)されました。
- `expires_at`属性は、GitLab 16.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/416795)されました。

{{< /history >}}

プロジェクトアクセストークンをローテーションします。これにより、以前のトークンが直ちに失効し、新しいトークンが作成されます。通常、このエンドポイントは、パーソナルアクセストークンで認証することで、特定のプロジェクトアクセストークンをローテーションします。プロジェクトアクセストークンを使用して、そのトークン自体をローテーションすることもできます。詳細については、[自己ローテーション](#self-rotate)を参照してください。

このエンドポイントを使用して、以前に失効したトークンをローテーションしようとすると、同じトークンファミリーのアクティブなトークンはすべて失効します。詳細については、[自動再利用の検出](personal_access_tokens.md#automatic-reuse-detection)を参照してください。

前提要件:

- 別のプロジェクトアクセストークンをローテーションするには、[`api`スコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を持つパーソナルアクセストークンが必要です。
- プロジェクトアクセストークンを[自己ローテーション](#self-rotate)するには、トークンが[`api`スコープまたは`self_rotate`スコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を持っている必要があります。

```plaintext
POST /projects/:id/access_tokens/:token_id/rotate
```

| 属性    | 型              | 必須 | 説明 |
| ------------ | ----------------- | -------- | ----------- |
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `token_id`   | 整数または文字列 | はい      | プロジェクトアクセストークンのIDまたはキーワード`self`。 |
| `expires_at` | 日付              | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。トークンに有効期限が必要な場合、デフォルトは1週間です。不要な場合、デフォルトは[最大許容ライフタイム制限](../user/profile/personal_access_tokens.md#access-token-expiration)になります。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>/rotate"
```

応答例:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test project access token",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "access_level": 30,
    "token": "s3cr3t"
}
```

成功すると、`200: OK`を返します。

その他の発生しうる応答:

- ローテーションが正常に完了しなかった場合は`400: Bad Request`。
- 次のいずれかの条件に該当する場合は`401: Unauthorized`。
  - トークンが存在しない。
  - トークンの有効期限が切れた。
  - トークンが失効した。
  - 指定されたトークンへのアクセス権がない。
  - プロジェクトアクセストークンを使用して、別のプロジェクトアクセストークンをローテーションしている。代わりに、[自己ローテーション](#self-rotate)を参照してください。
- トークンがそれ自体をローテーションすることを許可されていない場合は`403: Forbidden`。
- ユーザーが管理者であるが、トークンが存在しない場合は`404: Not Found`。
- トークンがプロジェクトアクセストークンでない場合は`405: Method Not Allowed`。

### 自己ローテーション {#self-rotate}

特定のプロジェクトアクセストークンをローテーションする代わりに、リクエストの認証に使用したものと同じプロジェクトアクセストークンをローテーションすることができます。プロジェクトアクセストークンを自己ローテーションするには、次のことを行う必要があります。

- [`api`スコープまたは`self_rotate`スコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を使用して、プロジェクトアクセストークンをローテーションします。
- リクエストURLで`self`キーワードを使用します。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_project_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/self/rotate"
```

## プロジェクトアクセストークンを失効させる {#revoke-a-project-access-token}

指定されたプロジェクトアクセストークンを失効させます。

```plaintext
DELETE projects/:id/access_tokens/:token_id
```

| 属性  | 型              | 必須 | 説明 |
| ---------- | ----------------- | -------- | ----------- |
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `token_id` | 整数           | はい      | プロジェクトアクセストークンのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
```

成功すると、`204 No content`を返します。

その他の発生しうる応答:

- 正常に失効しなかった場合は`400: Bad Request`。
- アクセストークンが存在しない場合は`404: Not Found`。
