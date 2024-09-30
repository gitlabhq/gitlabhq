---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User follow and unfollow API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can [follow and unfollow a user](../user/profile/index.md#follow-users) by using the REST API. You can also get the
details of who a user is following, and who is following them.

## Follow a user

Follow a user.

```plaintext
POST /users/:id/follow
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user to follow |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/users/3/follow"
```

Example response:

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

## Unfollow a user

Unfollow a user.

```plaintext
POST /users/:id/unfollow
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user to unfollow |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/users/3/unfollow"
```

## Get the followers of a user

Get the followers of a user.

```plaintext
GET /users/:id/followers
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>"  "https://gitlab.example.com/users/3/followers"
```

Example response:

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

## Get the users that a user is following

Get the list of users being followed by a user.

```plaintext
GET /users/:id/following
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>"  "https://gitlab.example.com/users/3/following"
```
