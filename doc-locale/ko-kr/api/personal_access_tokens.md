---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 개인 액세스 토큰 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)과 상호작용합니다.

## 모든 개인 액세스 토큰 나열 {#list-all-personal-access-tokens}

{{< history >}}

- `created_after`, `created_before`, `last_used_after`, `last_used_before`, `revoked`, `search` 및 `state` 필터는 GitLab 15.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/362248)되었습니다.

{{< /history >}}

인증된 사용자가 액세스할 수 있는 모든 개인 액세스 토큰을 나열합니다. 관리자의 경우 인스턴스의 모든 개인 액세스 토큰을 반환합니다. 관리자가 아닌 경우 사용자의 모든 개인 액세스 토큰을 반환합니다.

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

지원되는 속성:

| 속성          | 유형                | 필수 | 설명 |
| ------------------ | ------------------- | -------- | ----------- |
| `created_after`    | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 생성된 토큰을 반환합니다. |
| `created_before`   | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 생성된 토큰을 반환합니다. |
| `expires_after`    | 날짜 (ISO 8601)     | 아니요       | 정의된 경우 지정된 시간 이후에 만료되는 토큰을 반환합니다. |
| `expires_before`   | 날짜 (ISO 8601)     | 아니요       | 정의된 경우 지정된 시간 이전에 만료되는 토큰을 반환합니다. |
| `last_used_after`  | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이후에 마지막으로 사용된 토큰을 반환합니다. |
| `last_used_before` | 날짜/시간 (ISO 8601) | 아니요       | 정의된 경우 지정된 시간 이전에 마지막으로 사용된 토큰을 반환합니다. |
| `revoked`          | 부울             | 아니요       | `true`인 경우 취소된 토큰만 반환합니다. |
| `search`           | 문자열              | 아니요       | 정의된 경우 이름에 지정된 값을 포함하는 토큰을 반환합니다. |
| `sort`             | 문자열              | 아니요       | 정의된 경우 지정된 값으로 결과를 정렬합니다. 가능한 값: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |
| `state`            | 문자열              | 아니요       | 정의된 경우 지정된 상태의 토큰을 반환합니다. 가능한 값: `active` 및 `inactive`. |
| `user_id`          | 정수 또는 문자열   | 아니요       | 정의된 경우 지정된 사용자가 소유한 토큰을 반환합니다. 관리자가 아닌 경우 자신의 토큰만 필터링할 수 있습니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens?user_id=3&created_before=2022-01-01"
```

응답 예시:

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

성공한 경우 토큰 목록을 반환합니다.

가능한 다른 응답:

- `401: Unauthorized` - 관리자가 아닌 사용자가 `user_id` 속성을 사용하여 다른 사용자를 필터링하는 경우입니다.

## 개인 액세스 토큰 검색 {#retrieve-a-personal-access-token}

{{< history >}}

- GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/362239)되었습니다.
- `404` HTTP 상태 코드는 GitLab 15.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93650)되었습니다.

{{< /history >}}

지정된 개인 액세스 토큰의 세부 정보를 검색합니다. 관리자는 모든 토큰의 세부 정보를 검색할 수 있습니다. 관리자가 아닌 경우 자신의 토큰의 세부 정보만 검색할 수 있습니다.

```plaintext
GET /personal_access_tokens/:id
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id` | 정수 또는 문자열 | 예 | 개인 액세스 토큰 또는 키워드 `self`의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<id>"
```

성공한 경우 토큰의 세부 정보를 반환합니다.

기타 가능한 응답:

- `401: Unauthorized` - 다음 중 하나인 경우입니다:
  - 토큰이 존재하지 않습니다.
  - 지정된 토큰에 액세스할 수 없습니다.
- `404: Not Found` - 사용자가 관리자이지만 토큰이 존재하지 않는 경우입니다.

### 자신의 정보 확인 {#self-inform}

{{< history >}}

- GitLab 15.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/373999)되었습니다.

{{< /history >}}

특정 개인 액세스 토큰의 세부 정보를 가져오는 대신 요청을 인증하는 데 사용한 개인 액세스 토큰의 세부 정보를 반환할 수도 있습니다. 이러한 세부 정보를 반환하려면 요청 URL에서 `self` 키워드를 사용해야 합니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

## 개인 액세스 토큰 생성 {#create-a-personal-access-token}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용자 토큰 API를 사용하여 개인 액세스 토큰을 생성할 수 있습니다. 자세한 내용은 다음 엔드포인트를 참조하세요:

- [개인 액세스 토큰 생성](user_tokens.md#create-a-personal-access-token)
- [사용자를 위한 개인 액세스 토큰 생성](user_tokens.md#create-a-personal-access-token-for-a-user)

## 개인 액세스 토큰 회전 {#rotate-a-personal-access-token}

{{< history >}}

- GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/403042)되었습니다.
- `expires_at` 속성은 GitLab 16.6에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/416795)되었습니다.

{{< /history >}}

지정된 개인 액세스 토큰을 회전합니다. 이전 토큰을 취소하고 일주일 후에 만료되는 새 토큰을 생성합니다. 관리자는 모든 사용자의 토큰을 취소할 수 있습니다. 관리자가 아닌 경우 자신의 토큰만 취소할 수 있습니다.

```plaintext
POST /personal_access_tokens/:id/rotate
```

| 속성 | 유형      | 필수 | 설명         |
|-----------|-----------|----------|---------------------|
| `id` | 정수 또는 문자열 | 예      | 개인 액세스 토큰 또는 키워드 `self`의 ID입니다. |
| `expires_at` | 날짜   | 아니요       | ISO 형식(`YYYY-MM-DD`)의 액세스 토큰 만료 날짜입니다. 토큰에 만료 날짜가 필요한 경우 기본값은 1주일입니다. 필수가 아닌 경우 [최대 허용 수명 제한](../user/profile/personal_access_tokens.md#access-token-expiration)으로 기본 설정됩니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>/rotate"
```

응답 예시:

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

성공하면 `200: OK`을(를) 반환합니다.

기타 가능한 응답:

- 회전하지 못한 경우 `400: Bad Request`입니다.
- 다음 조건 중 하나라도 참이면 `401: Unauthorized`입니다:
  - 토큰이 존재하지 않습니다.
  - 토큰이 만료되었습니다.
  - 토큰이 취소되었습니다.
  - 지정된 토큰에 액세스할 수 없습니다.
- 토큰이 자신을 회전할 수 없는 경우 `403: Forbidden`입니다.
- `404: Not Found` - 사용자가 관리자이지만 토큰이 존재하지 않는 경우입니다.
- 토큰이 개인 액세스 토큰이 아닌 경우 `405: Method Not Allowed`입니다.

### 자체 회전 {#self-rotate}

{{< history >}}

- GitLab 16.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/426779)되었습니다.

{{< /history >}}

특정 개인 액세스 토큰을 회전하는 대신 요청을 인증하는 데 사용한 동일한 개인 액세스 토큰도 회전할 수 있습니다. 개인 액세스 토큰을 자체 회전하려면 다음을 수행해야 합니다:

- [`api` 또는 `self_rotate` 범위를 가진](../user/profile/personal_access_tokens.md#personal-access-token-scopes) 개인 액세스 토큰을 회전합니다.
- 요청 URL에서 `self` 키워드를 사용합니다.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/rotate"
```

### 자동 재사용 감지 {#automatic-reuse-detection}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/395352)되었습니다.

{{< /history >}}

토큰을 회전하거나 취소하면 GitLab은 이전 토큰과 새 토큰 간의 관계를 자동으로 추적합니다. 새 토큰이 생성될 때마다 이전 토큰에 대한 연결이 만들어집니다. 이러한 연결된 토큰들은 토큰 패밀리를 형성합니다.

이미 취소된 액세스 토큰을 회전하려고 시도하면 동일한 토큰 패밀리의 활성 토큰이 모두 취소됩니다.

이 기능은 이전 토큰이 유출되거나 도용된 경우 GitLab을 보호하는 데 도움이 됩니다. 토큰 관계를 추적하고 이전 토큰을 사용할 때 액세스를 자동으로 취소하여 공격자가 손상된 토큰을 악용할 수 없습니다.

## 개인 액세스 토큰 취소 {#revoke-a-personal-access-token}

지정된 개인 액세스 토큰을 취소합니다. 관리자는 모든 사용자의 토큰을 취소할 수 있습니다. 관리자가 아닌 경우 자신의 토큰만 취소할 수 있습니다.

```plaintext
DELETE /personal_access_tokens/:id
```

| 속성 | 유형    | 필수 | 설명         |
|-----------|---------|----------|---------------------|
| `id` | 정수 또는 문자열 | 예 | 개인 액세스 토큰 또는 키워드 `self`의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/<personal_access_token_id>"
```

성공하면 `204: No Content`을(를) 반환합니다.

기타 가능한 응답:

- 취소되지 않으면 `400: Bad Request`.
- `401: Unauthorized` - 요청이 인증되지 않은 경우입니다.
- `403: Forbidden` - 요청이 허용되지 않은 경우입니다.

### 자체 취소 {#self-revoke}

{{< history >}}

- GitLab 15.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/350240)되었습니다. `api` 범위를 가진 토큰으로 제한됩니다.
- GitLab 15.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/369103)되었습니다. 모든 토큰이 이 엔드포인트를 사용할 수 있습니다.

{{< /history >}}

특정 개인 액세스 토큰을 취소하는 대신 요청을 인증하는 데 사용한 동일한 개인 액세스 토큰도 취소할 수 있습니다. 개인 액세스 토큰을 자체 취소하려면 요청 URL에서 `self` 키워드를 사용해야 합니다.

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self"
```

## 모든 토큰 연결 나열 {#list-all-token-associations}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/466046)되었습니다.

{{< /history >}}

요청을 인증하는 데 사용된 개인 액세스 토큰으로 액세스할 수 있는 모든 그룹 및 프로젝트를 나열합니다. 일반적으로 사용자가 구성원인 모든 그룹 또는 프로젝트를 포함합니다.

```plaintext
GET /personal_access_tokens/self/associations
GET /personal_access_tokens/self/associations?page=2
GET /personal_access_tokens/self/associations?min_access_level=40
```

지원되는 속성:

| 속성           | 유형     | 필수 | 설명                                                              |
|---------------------|----------|----------|--------------------------------------------------------------------------|
| `min_access_level`  | 정수  | 아니요       | 토큰이 최소한 지정된 액세스 수준을 가진 그룹 및 프로젝트로 제한합니다. 가능한 값:  `5` (최소 액세스), `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지보수자) 또는 `50` (소유자). |
| `page`              | 정수  | 아니요       | 검색할 페이지입니다. `1`로 기본값이 설정됩니다.                                       |
| `per_page`          | 정수  | 아니요       | 페이지당 반환할 레코드 수입니다. `20`로 기본값이 설정됩니다.                  |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/personal_access_tokens/self/associations"
```

응답 예시:

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

## 관련 항목 {#related-topics}

- [토큰 문제 해결](../security/tokens/token_troubleshooting.md)
