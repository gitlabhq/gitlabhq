---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 액세스 토큰 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 프로젝트 액세스 토큰과 상호 작용합니다. 자세한 내용은 [프로젝트 액세스 토큰](../user/project/settings/project_access_tokens.md)을 참조하세요.

## 모든 프로젝트 액세스 토큰 나열 {#list-all-project-access-tokens}

{{< history >}}

- `state` 속성이 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)되었습니다.

{{< /history >}}

지정된 프로젝트의 모든 프로젝트 액세스 토큰을 나열합니다.

```plaintext
GET projects/:id/access_tokens
GET projects/:id/access_tokens?state=inactive
```

| 속성          | 유형                | 필수 | 설명 |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | 정수 또는 문자열   | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `created_after`    | 날짜-시간(ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 생성된 토큰을 반환합니다. |
| `created_before`   | 날짜-시간(ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 생성된 토큰을 반환합니다. |
| `expires_after`    | 날짜(ISO 8601)     | 아니요       | 정의된 경우 지정된 시간 이후에 만료되는 토큰을 반환합니다. |
| `expires_before`   | 날짜(ISO 8601)     | 아니요       | 정의된 경우 지정된 시간 이전에 만료되는 토큰을 반환합니다. |
| `last_used_after`  | 날짜-시간(ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 마지막으로 사용된 토큰을 반환합니다. |
| `last_used_before` | 날짜-시간(ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 마지막으로 사용된 토큰을 반환합니다. |
| `revoked`          | 부울             | 아니요       | `true`인 경우 해지된 토큰만 반환합니다. |
| `search`           | 문자열              | 아니요       | 정의된 경우 이름에 지정된 값을 포함하는 토큰을 반환합니다. |
| `sort`             | 문자열              | 아니요       | 정의된 경우 지정된 값으로 결과를 정렬합니다. 가능한 값: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`.|
| `state`            | 문자열              | 아니요       | 정의된 경우 지정된 상태로 토큰을 반환합니다. 가능한 값: `active` 및 `inactive`. |

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

## 프로젝트 액세스 토큰의 세부 정보 검색 {#retrieve-details-on-a-project-access-token}

프로젝트 액세스 토큰의 세부 정보를 검색합니다.

```plaintext
GET projects/:id/access_tokens/:token_id
```

| 속성  | 유형              | 필수 | 설명 |
| ---------- | ----------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `token_id` | 정수 또는 문자열 | 예      | ID |

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

## 프로젝트 액세스 토큰 생성 {#create-a-project-access-token}

{{< history >}}

- `expires_at` 속성 기본값이 GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120213)되었습니다.

{{< /history >}}

지정된 프로젝트에 대한 프로젝트 액세스 토큰을 생성합니다. 계정보다 높은 액세스 수준의 토큰을 생성할 수 없습니다. 예를 들어 유지 관리자 역할을 가진 사용자는 소유자 역할로 프로젝트 액세스 토큰을 생성할 수 없습니다.

이 엔드포인트에서는 개인 액세스 토큰을 사용해야 합니다. 프로젝트 액세스 토큰으로 인증할 수 없습니다. 이 기능을 추가하기 위한 [열린 기능 요청](https://gitlab.com/gitlab-org/gitlab/-/issues/359953)이 있습니다.

```plaintext
POST projects/:id/access_tokens
```

| 속성      | 유형              | 필수 | 설명 |
| -------------- | ----------------- | -------- | ----------- |
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`         | 문자열            | 예      | 토큰의 이름입니다. |
| `description`  | 문자열            | 아니요       | 프로젝트 액세스 토큰의 설명입니다. 최대:  255자. |
| `scopes`       | `Array[String]`   | 예      | 토큰에 사용 가능한 [범위](../user/project/settings/project_access_tokens.md#project-access-token-scopes)의 목록입니다. |
| `access_level` | 정수           | 아니요       | 토큰의 역할입니다. 가능한 값:  `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지 관리자), 그리고 `50` (소유자). 기본값: `40`. |
| `expires_at`   | 날짜              | 예      | ISO 형식(`YYYY-MM-DD`)의 토큰 만료 날짜입니다. 정의되지 않은 경우 날짜는 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 설정됩니다. |

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

## 프로젝트 액세스 토큰 회전 {#rotate-a-project-access-token}

{{< history >}}

- GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/403042)됨
- `expires_at` 속성이 GitLab 16.6에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/416795)되었습니다.

{{< /history >}}

프로젝트 액세스 토큰을 회전합니다. 이것은 즉시 이전 토큰을 해지하고 새 토큰을 생성합니다. 일반적으로 이 엔드포인트는 개인 액세스 토큰으로 인증하여 특정 프로젝트 액세스 토큰을 회전합니다. 프로젝트 액세스 토큰을 사용하여 자체 회전할 수도 있습니다. 자세한 내용은 [자체 회전](#self-rotate)을 참조하세요.

이전에 해지된 토큰을 회전하려고 시도하면 동일한 토큰 제품군의 모든 활성 토큰이 해지됩니다. 자세한 내용은 [자동 재사용 탐지](personal_access_tokens.md#automatic-reuse-detection)를 참조하세요.

전제 조건:

- 다른 프로젝트 액세스 토큰을 회전하려면 [`api` 범위](../user/profile/personal_access_tokens.md#personal-access-token-scopes)를 포함한 개인 액세스 토큰이 있어야 합니다.
- 프로젝트 액세스 토큰을 [자체 회전](#self-rotate) 하려면 토큰에 [`api` 또는 `self_rotate` 범위](../user/profile/personal_access_tokens.md#personal-access-token-scopes)가 있어야 합니다.

```plaintext
POST /projects/:id/access_tokens/:token_id/rotate
```

| 속성    | 유형              | 필수 | 설명 |
| ------------ | ----------------- | -------- | ----------- |
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `token_id`   | 정수 또는 문자열 | 예      | 프로젝트 액세스 토큰의 ID 또는 `self` 키워드입니다. |
| `expires_at` | 날짜              | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. 토큰에 만료 날짜가 필요한 경우 기본값은 1주입니다. 필수가 아닌 경우 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 기본값 설정됩니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>/rotate"
```

응답 예시:

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

성공하면 `200: OK`을 반환합니다.

가능한 다른 응답:

- 성공적으로 회전되지 않은 경우 `400: Bad Request`.
- 다음 조건 중 하나라도 해당하면 `401: Unauthorized`:
  - 토큰이 존재하지 않습니다.
  - 토큰이 만료되었습니다.
  - 토큰이 해지되었습니다.
  - 지정된 토큰에 액세스할 수 없습니다.
  - 프로젝트 액세스 토큰을 사용하여 다른 프로젝트 액세스 토큰을 회전하고 있습니다. 대신 [자체 회전](#self-rotate)을 참조하세요.
- 토큰이 자체 회전이 허용되지 않는 경우 `403: Forbidden`.
- 사용자가 관리자이지만 토큰이 존재하지 않는 경우 `404: Not Found`.
- 토큰이 프로젝트 액세스 토큰이 아닌 경우 `405: Method Not Allowed`.

### 자체 회전 {#self-rotate}

특정 프로젝트 액세스 토큰을 회전하는 대신 요청을 인증하는 데 사용한 동일한 프로젝트 액세스 토큰을 회전할 수 있습니다. 프로젝트 액세스 토큰을 자체 회전하려면 다음을 수행해야 합니다:

- [`api` 또는 `self_rotate` 범위](../user/profile/personal_access_tokens.md#personal-access-token-scopes)를 포함한 프로젝트 액세스 토큰을 회전합니다.
- 요청 URL에서 `self` 키워드를 사용합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_project_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/self/rotate"
```

## 프로젝트 액세스 토큰 해지 {#revoke-a-project-access-token}

지정된 프로젝트 액세스 토큰을 해지합니다.

```plaintext
DELETE projects/:id/access_tokens/:token_id
```

| 속성  | 유형              | 필수 | 설명 |
| ---------- | ----------------- | -------- | ----------- |
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `token_id` | 정수           | 예      | 프로젝트 액세스 토큰의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/access_tokens/<token_id>"
```

성공하면 `204 No content`을 반환합니다.

가능한 다른 응답:

- 성공적으로 해지되지 않은 경우 `400: Bad Request`.
- 액세스 토큰이 존재하지 않는 경우 `404: Not Found`.
