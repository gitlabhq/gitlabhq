---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 토큰 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 개인 액세스 토큰 및 가장 토큰과 상호 작용합니다. 자세한 내용은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md) 및 [가장 토큰](rest/authentication.md#impersonation-tokens)을 참조하세요.

## 사용자를 위한 개인 액세스 토큰 생성 {#create-a-personal-access-token-for-a-user}

{{< history >}}

- `expires_at` 속성 기본값은 GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213)되었습니다.

{{< /history >}}

지정된 사용자를 위해 개인 액세스 토큰을 생성합니다.

토큰 값은 응답에 포함되지만 나중에 검색할 수 없습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:user_id/personal_access_tokens
```

지원되는 속성:

| 속성    | 유형    | 필수 | 설명 |
|:-------------|:--------|:---------|:------------|
| `user_id`    | 정수 | 예      | 사용자 계정의 ID입니다. |
| `name`       | 문자열  | 예      | 개인 액세스 토큰의 이름입니다. |
| `description`| 문자열  | 아니요       | 개인 액세스 토큰의 설명입니다. 최대:  255자입니다. |
| `expires_at` | 날짜    | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. 정의되지 않으면 날짜가 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 설정됩니다. |
| `scopes`     | 배열   | 예      | 승인된 범위의 배열입니다. 가능한 값 목록은 [개인 액세스 토큰 범위](../user/profile/personal_access_tokens.md#personal-access-token-scopes)를 참조하세요. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "expires_at=2017-04-04" \
  --data "scopes[]=api" \
  --url "https://gitlab.example.com/api/v4/users/42/personal_access_tokens"
```

응답 예시:

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

## 개인 액세스 토큰 생성 {#create-a-personal-access-token}

{{< history >}}

- [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131923).

{{< /history >}}

계정을 위한 개인 액세스 토큰을 생성합니다. 보안상의 이유로 토큰은:

- [`k8s_proxy` 및 `self_rotate` 범위](../user/profile/personal_access_tokens.md#personal-access-token-scopes)에 대해 제한됩니다.

토큰 값은 응답에 포함되지만 나중에 검색할 수 없습니다.

전제 조건:

- 인증을 받아야 합니다.

```plaintext
POST /user/personal_access_tokens
```

지원되는 속성:

| 속성    | 유형   | 필수 | 설명 |
|:-------------|:-------|:---------|:------------|
| `name`       | 문자열 | 예      | 개인 액세스 토큰의 이름입니다. |
| `description`| 문자열 | 아니요       | 개인 액세스 토큰의 설명입니다. 최대:  255자입니다. |
| `scopes`     | 배열  | 예      | 승인된 범위의 배열입니다. `k8s_proxy` 및 `self_rotate`만 허용됩니다. |
| `expires_at` | 날짜  | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. 정의되지 않으면 날짜가 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 설정됩니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "scopes[]=k8s_proxy" \
  --url "https://gitlab.example.com/api/v4/user/personal_access_tokens"
```

응답 예시:

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

## 사용자를 위한 모든 가장 토큰 나열 {#list-all-impersonation-tokens-for-a-user}

지정된 사용자를 위한 모든 가장 토큰을 나열합니다.

`page` 및 `per_page` [페이지 매김 매개변수](rest/_index.md#offset-based-pagination)를 사용하여 결과를 필터링합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
GET /users/:user_id/impersonation_tokens
```

지원되는 속성:

| 속성 | 유형    | 필수 | 설명 |
|:----------|:--------|:---------|:------------|
| `user_id` | 정수 | 예      | 사용자 계정의 ID |
| `state`   | 문자열  | 아니요       | 상태에 따라 토큰을 필터링합니다. 가능한 값: `all`, `active` 또는 `inactive`. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
```

응답 예시:

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

## 사용자를 위한 가장 토큰 검색 {#retrieve-an-impersonation-token-for-a-user}

지정된 사용자를 위한 가장 토큰을 검색합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
GET /users/:user_id/impersonation_tokens/:impersonation_token_id
```

지원되는 속성:

| 속성                | 유형    | 필수 | 설명 |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | 정수 | 예      | 사용자 계정의 ID |
| `impersonation_token_id` | 정수 | 예      | 가장 토큰의 ID |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/2"
```

응답 예시:

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

## 가장 토큰 생성 {#create-an-impersonation-token}

지정된 사용자를 위한 가장 토큰을 생성합니다. 이 토큰은 사용자를 대신하여 작동하는 데 사용되며 API 호출뿐만 아니라 Git 읽기 및 쓰기 작업을 수행할 수 있습니다. 이 토큰은 관련 사용자의 프로필 설정 페이지에 표시되지 않습니다.

토큰 값은 응답에 포함되지만 나중에 검색할 수 없습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
POST /users/:user_id/impersonation_tokens
```

지원되는 속성:

| 속성    | 유형    | 필수 | 설명 |
|:-------------|:--------|:---------|:------------|
| `user_id`    | 정수 | 예      | 사용자 계정의 ID |
| `name`       | 문자열  | 예      | 가장 토큰의 이름 |
| `description`| 문자열  | 아니요       | 가장 토큰의 설명 |
| `expires_at` | 날짜    | 예      | ISO 형식(`YYYY-MM-DD`)의 가장 토큰 만료 날짜입니다. 정의되지 않으면 날짜가 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 설정됩니다. |
| `scopes`     | 배열   | 예      | 승인된 범위의 배열입니다. 가능한 값 목록은 [개인 액세스 토큰 범위](../user/profile/personal_access_tokens.md#personal-access-token-scopes)를 참조하세요.  |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "name=mytoken" --data "expires_at=2017-04-04" \
  --data "scopes[]=api" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens"
```

응답 예시:

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

## 가장 토큰 취소 {#revoke-an-impersonation-token}

지정된 사용자를 위한 가장 토큰을 취소합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

```plaintext
DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id
```

지원되는 속성:

| 속성                | 유형    | 필수 | 설명 |
|:-------------------------|:--------|:---------|:------------|
| `user_id`                | 정수 | 예      | 사용자 계정의 ID |
| `impersonation_token_id` | 정수 | 예      | 가장 토큰의 ID |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/impersonation_tokens/1"
```
