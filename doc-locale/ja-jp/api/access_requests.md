---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループおよびプロジェクトのアクセスリクエストAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループおよびプロジェクトのアクセスリクエストを操作します。

## グループまたはプロジェクトのすべてのアクセスリクエストをリスト表示 {#list-all-access-requests-for-a-group-or-project}

指定されたグループまたはプロジェクトに対して、認証済みユーザーが表示できるすべてのアクセスリクエストをリスト表示します。

```plaintext
GET /groups/:id/access_requests
GET /projects/:id/access_requests
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

レスポンス例: 

```json
[
 {
   "id": 1,
   "username": "raymond_smith",
   "name": "Raymond Smith",
   "state": "active",
   "locked": false,
   "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/1/avatar.png",
   "web_url": "https://gitlab.com/raymond_smith",
   "requested_at": "2024-10-22T14:13:35Z"
 },
 {
   "id": 2,
   "username": "john_doe",
   "name": "John Doe",
   "state": "active",
   "locked": false,
   "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/2/avatar.png",
   "web_url": "https://gitlab.com/john_doe",
   "requested_at": "2024-10-22T14:13:35Z"
 }
]
```

## グループまたはプロジェクトへのアクセスをリクエストする {#request-access-to-a-group-or-project}

指定されたグループまたはプロジェクトへの認証済みユーザーのアクセスをリクエストします。

```plaintext
POST /groups/:id/access_requests
POST /projects/:id/access_requests
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | そのIDまたは[グループまたはプロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths) |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

レスポンス例: 

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "created_at": "2012-10-22T14:13:35Z",
  "requested_at": "2012-10-22T14:13:35Z"
}
```

## アクセスリクエストを承認する {#approve-an-access-request}

指定されたグループまたはプロジェクト内の指定されたユーザーのアクセスリクエストを承認します。

```plaintext
PUT /groups/:id/access_requests/:user_id/approve
PUT /projects/:id/access_requests/:user_id/approve
```

| 属性      | 型           | 必須 | 説明 |
|----------------|----------------|----------|-------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `user_id`      | 整数        | はい      | アクセスリクエスタのユーザーID |
| `access_level` | 整数        | いいえ       | 有効な[アクセスレベル](../user/permissions.md#default-roles)。使用可能な値: `0` (アクセスなし), `5` (最小アクセス), `10` (ゲスト), `15` (プランナー), `20` (レポーター), `25` (セキュリティマネージャー), `30` (デベロッパー), `40` (メンテナー), `50` (オーナー)。デフォルトは`30`です。 |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id/approve?access_level=20"
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id/approve?access_level=20"
```

レスポンス例: 

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "created_at": "2012-10-22T14:13:35Z",
  "access_level": 20
}
```

## アクセスリクエストを拒否する {#deny-an-access-request}

指定されたグループまたはプロジェクト内の指定されたユーザーのアクセスリクエストを拒否します。

```plaintext
DELETE /groups/:id/access_requests/:user_id
DELETE /projects/:id/access_requests/:user_id
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `user_id` | 整数        | はい      | アクセスリクエスタのユーザーID |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"  \
  --url "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id"
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id"
```
