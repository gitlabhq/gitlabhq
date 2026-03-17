---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ユーザーのフォローとフォロー解除API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、ユーザーアカウントのフォロワーアクションを実行します。詳細については、[ユーザーをフォロー](../user/profile/_index.md#follow-users)を参照してください。

## ユーザーをフォローする {#follow-a-user}

指定されたユーザーアカウントをフォローします。

```plaintext
POST /users/:id/follow
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/follow"
```

レスポンス例: 

```json
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
  "web_url": "http://localhost:3000/john_smith"
}
```

## ユーザーのフォローを解除する {#unfollow-a-user}

指定されたユーザーアカウントのフォローを解除します。

```plaintext
POST /users/:id/unfollow
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/unfollow"
```

## ユーザーをフォローしているすべてのアカウントを一覧表示する {#list-all-accounts-that-follow-a-user}

指定されたユーザーをフォローしているすべてのユーザーアカウントを一覧表示します。

```plaintext
GET /users/:id/followers
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/followers"
```

レスポンス例: 

```json
[
  {
    "id": 2,
    "name": "Lennie Donnelly",
    "username": "evette.kilback",
    "state": "active",
    "locked": false,
    "avatar_url": "https://www.gravatar.com/avatar/7955171a55ac4997ed81e5976287890a?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/evette.kilback"
  },
  {
    "id": 4,
    "name": "Serena Bradtke",
    "username": "cammy",
    "state": "active",
    "locked": false,
    "avatar_url": "https://www.gravatar.com/avatar/a2daad869a7b60d3090b7b9bef4baf57?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/cammy"
  }
]
```

## ユーザーがフォローしているすべてのアカウントを一覧表示する {#list-all-accounts-followed-by-a-user}

指定されたユーザーがフォローしているすべてのユーザーアカウントを一覧表示します。

```plaintext
GET /users/:id/following
```

サポートされている属性は以下のとおりです: 

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーアカウントのID |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/following"
```
