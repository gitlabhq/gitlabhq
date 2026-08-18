---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 Package Protection Rules를 위한 REST API 문서입니다.
title: 보호된 패키지 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- `packages_protected_packages`이라는 이름의 [플래그와 함께](../administration/feature_flags/_index.md) GitLab 17.1에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151741). 기본적으로 비활성화됨.
- [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/472655) (GitLab 17.5)
- [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/472655) (GitLab 17.6) 기능 플래그 `packages_protected_packages` 제거됨.
- [추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180063) `minimum_access_level_for_delete` 속성 (GitLab 17.11) [기능 플래그 포함](../administration/feature_flags/_index.md) (이름: `packages_protected_packages_delete`) 기본적으로 비활성화됨.

{{< /history >}}

이 REST API를 사용하여 [패키지 보호 규칙](../user/packages/package_registry/package_protection_rules.md)을 관리합니다.

## 모든 패키지 보호 규칙 나열 {#list-all-package-protection-rules}

지정된 프로젝트의 모든 패키지 보호 규칙을 나열합니다.

```plaintext
GET /api/v4/projects/:id/packages/protection/rules
```

지원되는 속성:

| 속성                     | 유형            | 필수 | 설명                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | 정수 또는 문자열  | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

성공 시 [`200`](rest/troubleshooting.md#status-codes)을(를) 반환하고 패키지 보호 규칙 목록을 반환합니다.

다음 상태 코드를 반환할 수 있습니다:

- `200 OK`:  패키지 보호 규칙의 목록입니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자가 이 프로젝트의 패키지 보호 규칙을 나열할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules"
```

응답 예시:

```json
[
 {
  "id": 1,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-0",
  "package_type": "npm",
  "minimum_access_level_for_delete": "owner",
  "minimum_access_level_for_push": "maintainer"
 },
 {
  "id": 2,
  "project_id": 7,
  "package_name_pattern": "@flightjs/flight-package-1",
  "package_type": "npm",
  "minimum_access_level_for_delete": "owner",
  "minimum_access_level_for_push": "maintainer"
 }
]
```

## 패키지 보호 규칙 생성 {#create-a-package-protection-rule}

지정된 프로젝트의 패키지 보호 규칙을 생성합니다.

```plaintext
POST /api/v4/projects/:id/packages/protection/rules
```

지원되는 속성:

| 속성                             | 유형            | 필수 | 설명                    |
|---------------------------------------|-----------------|----------|--------------------------------|
| `id`                                  | 정수 또는 문자열  | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `package_name_pattern`                | 문자열          | 예      | 보호 규칙으로 보호되는 패키지 이름입니다. 예: `@my-scope/my-package-*` 와일드카드 문자 `*`가 허용됩니다. |
| `package_type`                        | 문자열          | 예      | 보호 규칙으로 보호되는 패키지 유형입니다. 예: `npm` |
| `minimum_access_level_for_delete`     | 문자열          | 예      | 패키지를 삭제하는 데 필요한 최소 GitLab 액세스 수준입니다. 유효한 값으로 `null`, `owner` 또는 `admin`를 포함합니다. 값이 `null`인 경우 기본 최소 액세스 수준은 `maintainer`입니다. `minimum_access_level_for_push`이 설정되지 않은 경우 제공해야 합니다. `packages_protected_packages_delete`이라는 기능 플래그 뒤에 있습니다. 기본적으로 비활성화됨. |
| `minimum_access_level_for_push`       | 문자열          | 예      | 패키지를 푸시하는 데 필요한 최소 GitLab 액세스 수준입니다. 유효한 값으로 `null`, `maintainer`, `owner` 또는 `admin`를 포함합니다. 값이 `null`인 경우 기본 최소 액세스 수준은 `developer`입니다. `minimum_access_level_for_delete`이 설정되지 않은 경우 제공해야 합니다. |

성공 시 [`201`](rest/troubleshooting.md#status-codes)을(를) 반환하고 생성된 패키지 보호 규칙을 반환합니다.

다음 상태 코드를 반환할 수 있습니다:

- `201 Created`:  패키지 보호 규칙이 성공적으로 생성되었습니다.
- `400 Bad Request`:  패키지 보호 규칙이 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자가 패키지 보호 규칙을 생성할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.
- `422 Unprocessable Entity`:  패키지 보호 규칙을 생성할 수 없습니다. 예를 들어 `package_name_pattern`이 이미 사용 중입니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules" \
  --data '{
       "package_name_pattern": "package-name-pattern-*",
       "package_type": "npm",
       "minimum_access_level_for_delete": "owner",
       "minimum_access_level_for_push": "maintainer"
    }'
```

## 패키지 보호 규칙 업데이트 {#update-a-package-protection-rule}

지정된 프로젝트의 패키지 보호 규칙을 업데이트합니다.

```plaintext
PATCH /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

지원되는 속성:

| 속성                             | 유형            | 필수 | 설명                    |
|---------------------------------------|-----------------|----------|--------------------------------|
| `id`                                  | 정수 또는 문자열  | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `package_protection_rule_id`          | 정수         | 예      | 업데이트할 패키지 보호 규칙의 ID입니다. |
| `package_name_pattern`                | 문자열          | 아니요       | 보호 규칙으로 보호되는 패키지 이름입니다. 예: `@my-scope/my-package-*` 와일드카드 문자 `*`가 허용됩니다. |
| `package_type`                        | 문자열          | 아니요       | 보호 규칙으로 보호되는 패키지 유형입니다. 예: `npm` |
| `minimum_access_level_for_delete`     | 문자열          | 아니요       | 패키지를 삭제하는 데 필요한 최소 GitLab 액세스 수준입니다. 유효한 값으로 `null`, `owner` 또는 `admin`를 포함합니다. 값이 `null`인 경우 기본 최소 액세스 수준은 `maintainer`입니다. `minimum_access_level_for_push`이 설정되지 않은 경우 제공해야 합니다. `packages_protected_packages_delete`이라는 기능 플래그 뒤에 있습니다. 기본적으로 비활성화됨. |
| `minimum_access_level_for_push`       | 문자열          | 아니요       | 패키지를 푸시하는 데 필요한 최소 GitLab 액세스 수준입니다. 유효한 값으로 `null`, `maintainer`, `owner` 또는 `admin`를 포함합니다. 값이 `null`인 경우 기본 최소 액세스 수준은 `developer`입니다. `minimum_access_level_for_delete`이 설정되지 않은 경우 제공해야 합니다. |

성공 시 [`200`](rest/troubleshooting.md#status-codes)을(를) 반환하고 업데이트된 패키지 보호 규칙을 반환합니다.

다음 상태 코드를 반환할 수 있습니다:

- `200 OK`:  패키지 보호 규칙이 성공적으로 패치되었습니다.
- `400 Bad Request`:  패치가 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자가 패키지 보호 규칙을 패치할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.
- `422 Unprocessable Entity`:  패키지 보호 규칙을 패치할 수 없습니다. 예를 들어 `package_name_pattern`이 이미 사용 중입니다.

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules/32" \
  --data '{
       "package_name_pattern": "new-package-name-pattern-*"
    }'
```

## 패키지 보호 규칙 삭제 {#delete-a-package-protection-rule}

지정된 프로젝트에서 패키지 보호 규칙을 삭제합니다.

```plaintext
DELETE /api/v4/projects/:id/packages/protection/rules/:package_protection_rule_id
```

지원되는 속성:

| 속성                     | 유형            | 필수 | 설명                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | 정수 또는 문자열  | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `package_protection_rule_id`  | 정수         | 예      | 삭제할 패키지 보호 규칙의 ID입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

다음 상태 코드를 반환할 수 있습니다:

- `204 No Content`:  패키지 보호 규칙이 성공적으로 삭제되었습니다.
- `400 Bad Request`:  `id` 또는 `package_protection_rule_id`이 누락되었거나 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자가 패키지 보호 규칙을 삭제할 권한이 없습니다.
- `404 Not Found`:  프로젝트 또는 패키지 보호 규칙을 찾을 수 없습니다.

요청 예시:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/packages/protection/rules/32"
```
