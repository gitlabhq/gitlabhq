---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パーソナルアクセストークンAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を操作します。

## すべてのパーソナルアクセストークンのリストを取得する {#list-all-personal-access-tokens}

{{< history >}}

- `created_after`、`created_before`、`last_used_after`、`last_used_before`、`revoked`、`search`、および`state`の各フィルターは、GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/362248)されました。

{{< /history >}}

認証を受けているユーザーがアクセスできる、すべてのパーソナルアクセストークンのリストを取得します。管理者の場合は、インスタンス内のすべてのパーソナルアクセストークンのリストが返されます。管理者以外の場合は、自分のパーソナルアクセストークンのすべてのリストが返されます。

```plaintext
GET /personal_access_tokens
GET /personal_access_tokens?created_after=2022-01-01T00:00:00
GET /personal_access_tokens?created_before=2022-01-01T00:00:00
GET /personal_access_tokens?last_used_after=2022-01-01T00:00:00
GET /personal_access_tokens?last_used_before=2022-01-01T00:00:00
GET /personal_access_tokens?revoked=true
GET /personal_access_tokens?search=name
GET /personal_access_tokens?state=inactive
GET /personal_access_tokens?user_id=1
```

サポートされている属性:

| 属性          | 型                | 必須 | 説明 |
| ------------------ | ------------------- | -------- | ----------- |
| `created_after`    | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より後に作成されたトークンを返します。 |
| `created_before`   | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より前に作成されたトークンを返します。 |
| `expires_after`    | 日付（ISO 8601）     | いいえ       | 定義されている場合、指定された時刻より後に有効期限が切れるトークンを返します。 |
| `expires_before`   | 日付（ISO 8601）     | いいえ       | 定義されている場合、指定された時刻より前に有効期限が切れるトークンを返します。 |
| `last_used_after`  | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より後に最終使用されたトークンを返します。 |
| `last_used_before` | 日時（ISO 8601） | いいえ       | 定義されている場合、指定された時刻より前に最終使用されたトークンを返します。 |
| `revoked`          | ブール値             | いいえ       | `true`の場合、失効したトークンのみを返します。 |
| `search`           | 文字列              | いいえ       | 定義されている場合、指定された値が名前に含まれるトークンを返します。 |
| `sort`             | 文字列              | いいえ       | 定義されている場合、指定された値で結果をソートします。使用できる値は、`created_asc`、`created_desc`、`expires_asc`、`expires_desc`、`last_used_asc`、`last_used_desc`、`name_asc`、`name_desc`です。 |
| `state`            | 文字列              | いいえ       | 定義されている場合、指定された状態のトークンを返します。使用できる値は、`active`と`inactive`です。 |
| `user_id`          | 整数または文字列   | いいえ       | 定義されている場合、指定されたユーザーが所有しているトークンを返します。管理者以外のユーザーは、自分のトークンのみをフィルターできます。 |

リクエストの例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens?user_id=3&created_before=2022-01-01"
```

応答の例:

```json
[
    {
        "id": 4,
        "name": "Test Token",
        "revoked": false,
        "created_at": "2020-07-23T14:31:47.729Z",
        "description": "Test Token description",
        "scopes": [
            "api"
        ],
        "user_id": 3,
        "last_used_at": "2021-10-06T17:58:37.550Z",
        "active": true,
        "expires_at": null
    }
]
```

成功した場合、トークンのリストを返します。

その他の発生しうる応答:

- 管理者以外のユーザーが`user_id`属性を使用して他のユーザーをフィルターした場合は`401: Unauthorized`。

## パーソナルアクセストークンの詳細を取得する {#get-details-on-a-personal-access-token}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/362239)されました。
- `404` HTTPステータスコードは、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93650)されました。

{{< /history >}}

指定されたパーソナルアクセストークンの詳細を取得します。管理者は、任意のトークンの詳細を取得できます。管理者以外のユーザーは、自分のトークンの詳細のみを取得できます。

```plaintext
GET /personal_access_tokens/:id
```

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id` | 整数または文字列 | はい | パーソナルアクセストークン、またはキーワード`self`のID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<id>"
```

成功した場合、トークンの詳細を返します。

その他の発生しうる応答:

- 次のいずれかの場合は`401: Unauthorized`:
  - トークンが存在しない。
  - 指定されたトークンへのアクセス権がない。
- ユーザーが管理者であるにもかかわらずトークンが存在しない場合は`404: Not Found`。

### 自己通知 {#self-inform}

{{< history >}}

- GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/373999)されました。

{{< /history >}}

特定のパーソナルアクセストークンの詳細を取得する代わりに、リクエストの認証に使用したパーソナルアクセストークンの詳細を返すこともできます。これらの詳細を返すには、リクエストURLで`self`キーワードを使用する必要があります。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

## パーソナルアクセストークンを作成する {#create-a-personal-access-token}

{{< details >}}

- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザートークンAPIを使用して、パーソナルアクセストークンを作成できます。詳細については、次のエンドポイントを参照してください。

- [パーソナルアクセストークンを作成する](user_tokens.md#create-a-personal-access-token)
- [ユーザーのパーソナルアクセストークンを作成する](user_tokens.md#create-a-personal-access-token-for-a-user)

## パーソナルアクセストークンをローテーションする {#rotate-a-personal-access-token}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/403042)されました。
- `expires_at`属性は、GitLab 16.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/416795)されました。

{{< /history >}}

指定されたパーソナルアクセストークンをローテーションします。これにより、以前のトークンは失効し、1週間後に有効期限が切れる新しいトークンが作成されます。管理者は、任意のユーザーのトークンを失効させることができます。管理者以外のユーザーは、自分のトークンのみを失効させることができます。

```plaintext
POST /personal_access_tokens/:id/rotate
```

| 属性 | 型      | 必須 | 説明         |
|-----------|-----------|----------|---------------------|
| `id` | 整数または文字列 | はい      | パーソナルアクセストークン、またはキーワード`self`のID。 |
| `expires_at` | 日付   | いいえ       | ISO形式（`YYYY-MM-DD`）のアクセストークンの有効期限。トークンに有効期限が必要な場合、デフォルトは1週間です。不要な場合、デフォルトは[最大許容ライフタイムの制限](../user/profile/personal_access_tokens.md#access-token-expiration)です。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>/rotate"
```

応答の例:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

成功した場合、`200: OK`を返します。

その他の発生しうる応答:

- ローテーションが正常に完了しなかった場合は`400: Bad Request`。
- 次のいずれかの条件に該当する場合は`401: Unauthorized`。
  - トークンが存在しない。
  - トークンの有効期限が切れた。
  - トークンが失効した。
  - 指定されたトークンへのアクセス権がない。
- トークンがローテーションを許可されていない場合は`403: Forbidden`。
- ユーザーが管理者であるにもかかわらずトークンが存在しない場合は`404: Not Found`。
- トークンがパーソナルアクセストークンでない場合は`405: Method Not Allowed`。

### 自己ローテーション {#self-rotate}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/426779)されました。

{{< /history >}}

特定のパーソナルアクセストークンをローテーションする代わりに、リクエストの認証に使用したものと同じパーソナルアクセストークンをローテーションすることもできます。パーソナルアクセストークンを自己ローテーションするには、次のことを行う必要があります。

- [`api`スコープまたは`self_rotate`スコープ](../user/profile/personal_access_tokens.md#personal-access-token-scopes)を使用して、パーソナルアクセストークンをローテーションします。
- リクエストURLで`self`キーワードを使用します。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/rotate"
```

### 自動再利用検出 {#automatic-reuse-detection}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/395352)されました。

{{< /history >}}

トークンをローテーションするか失効させると、GitLabは古いトークンと新しいトークンの関係を自動的に追跡します。新しいトークンが生成されるたびに、以前のトークンへの接続が確立されます。これらの接続されたトークンは、トークンファミリーを形成します。

すでに失効しているアクセストークンをAPIを使用してローテーションしようとすると、同じトークンファミリーのアクティブなトークンはすべて失効します。

この機能は、古いトークンが漏洩したり、盗まれたりした場合に、GitLabを保護するのに役立ちます。トークンの関係を追跡し、古いトークンが使用されたときにアクセスを自動的に失効させることで、攻撃者は不正なトークンを悪用できなくなります。

## パーソナルアクセストークンを失効させる {#revoke-a-personal-access-token}

指定されたパーソナルアクセストークンを失効させます。管理者は、任意のユーザーのトークンを失効させることができます。管理者以外のユーザーは、自分のトークンのみを失効させることができます。

```plaintext
DELETE /personal_access_tokens/:id
```

| 属性 | 型    | 必須 | 説明         |
|-----------|---------|----------|---------------------|
| `id` | 整数または文字列 | はい | パーソナルアクセストークン、またはキーワード`self`のID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>"
```

成功した場合、`204: No Content`を返します。

その他の発生しうる応答:

- 正常に失効しなかった場合は`400: Bad Request`。
- リクエストが承認されていない場合は`401: Unauthorized`。
- リクエストが許可されていない場合は`403: Forbidden`。

### 自己失効 {#self-revoke}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350240)されました。`api`スコープを持つトークンに制限されます。
- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369103)されました。すべてのトークンがこのエンドポイントを使用できます。

{{< /history >}}

特定のパーソナルアクセストークンを失効させる代わりに、リクエストの認証に使用したものと同じパーソナルアクセストークンを失効させることもできます。パーソナルアクセストークンを自己失効させるには、リクエストURLで`self`キーワードを使用する必要があります。

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

## すべてのトークン関連付けのリストを取得する {#list-all-token-associations}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/466046)されました。

{{< /history >}}

リクエストの認証に使用したパーソナルアクセストークンからアクセスできる、すべてのグループとプロジェクトのリストを取得します。通常、リストには、ユーザーがメンバーになっているグループまたはプロジェクトが含まれます。

```plaintext
GET /personal_access_tokens/self/associations
GET /personal_access_tokens/self/associations?page=2
GET /personal_access_tokens/self/associations?min_access_level=40
```

サポートされている属性:

| 属性           | 型     | 必須 | 説明                                                              |
|---------------------|----------|----------|--------------------------------------------------------------------------|
| `min_access_level`  | 整数  | いいえ       | 現在のユーザーの最小[ロール（`access_level`）](members.md#roles)で制限します。 |
| `page`              | 整数  | いいえ       | 取得するページ。`1`がデフォルトです。                                       |
| `per_page`          | 整数  | いいえ       | ページごとに返すレコード数。`20`がデフォルトです。                  |

リクエストの例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/associations"
```

応答の例:

```json
{
    "groups": [
        {
        "id": 1,
        "web_url": "http://gitlab.example.com/groups/test",
        "name": "Test",
        "parent_id": null,
        "organization_id": 1,
        "access_levels": 20,
        "visibility": "public"
        },
        {
        "id": 3,
        "web_url": "http://gitlab.example.com/groups/test/test_private",
        "name": "Test Private",
        "parent_id": 1,
        "organization_id": 1,
        "access_levels": 50,
        "visibility": "test_private"
        }
    ],
    "projects": [
        {
            "id": 1337,
            "description": "Leet.",
            "name": "Test Project",
            "name_with_namespace": "Test / Test Project",
            "path": "test-project",
            "path_with_namespace": "Test/test-project",
            "created_at": "2024-07-02T13:37:00.123Z",
            "access_levels": {
                "project_access_level": null,
                "group_access_level": 20
            },
            "visibility": "private",
            "web_url": "http://gitlab.example.com/test/test_project",
            "namespace": {
                "id": 1,
                "name": "Test",
                "path": "Test",
                "kind": "group",
                "full_path": "Test",
                "parent_id": null,
                "avatar_url": null,
                "web_url": "http://gitlab.example.com/groups/test"
            }
        }
    ]
}
```

## 関連トピック {#related-topics}

- [トークンのトラブルシューティング](../security/tokens/token_troubleshooting.md)
