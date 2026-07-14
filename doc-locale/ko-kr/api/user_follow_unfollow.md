---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 팔로우 및 언팔로우 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 사용자 계정에 대한 팔로워 작업을 수행합니다. 자세한 내용은 [사용자 팔로우](../user/profile/_index.md#follow-users)를 참조하세요.

## 사용자 팔로우 {#follow-a-user}

지정된 사용자 계정을 팔로우합니다.

```plaintext
POST /users/:id/follow
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/follow"
```

응답 예시:

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

## 사용자 언팔로우 {#unfollow-a-user}

지정된 사용자 계정을 언팔로우합니다.

```plaintext
POST /users/:id/unfollow
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/unfollow"
```

## 사용자를 팔로우하는 모든 계정 나열 {#list-all-accounts-that-follow-a-user}

지정된 사용자를 팔로우하는 모든 사용자 계정을 나열합니다.

```plaintext
GET /users/:id/followers
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/followers"
```

응답 예시:

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

## 사용자가 팔로우하는 모든 계정 나열 {#list-all-accounts-followed-by-a-user}

지정된 사용자가 팔로우하는 모든 사용자 계정을 나열합니다.

```plaintext
GET /users/:id/following
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `id`      | 정수 | 예      | 사용자 계정의 ID |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/users/3/following"
```
