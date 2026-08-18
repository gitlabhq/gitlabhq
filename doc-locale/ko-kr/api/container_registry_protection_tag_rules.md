---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 컨테이너 레지스트리 보호 태그 규칙을 위한 REST API 설명서입니다.
title: 컨테이너 레지스트리 보호 태그 규칙 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/581199).

{{< /history >}}

이 API를 사용하여 [보호된 컨테이너 태그](../user/packages/container_registry/protected_container_tags.md)를 관리합니다.

## 컨테이너 레지스트리 보호 태그 규칙 나열 {#list-container-registry-protection-tag-rules}

프로젝트의 컨테이너 레지스트리 보호 태그 규칙 목록을 가져옵니다.

```plaintext
GET /api/v4/projects/:id/registry/protection/tag/rules
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명                                                                     |
|-----------|-------------------|----------|---------------------------------------------------------------------------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다.      |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|-----------|------|-------------|
| `id` | 정수 | 보호된 컨테이너 태그 규칙의 ID입니다. |
| `minimum_access_level_for_delete` | 문자열 | 태그를 삭제하는 데 필요한 최소 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. |
| `minimum_access_level_for_push` | 문자열 | 태그로 푸시하는 데 필요한 최소 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. |
| `project_id` | 정수 | 프로젝트의 ID입니다. |
| `tag_name_pattern` | 문자열 | 태그 이름 패턴입니다. 예를 들어 `v*-release` 또는 `latest`입니다. |

다음 상태 코드를 반환할 수 있습니다:

- `200 OK`:  보호 규칙 목록입니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자는 이 프로젝트의 보호 규칙을 나열할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules"
```

응답 예시:

```json
[
  {
    "id": 1,
    "project_id": 7,
    "tag_name_pattern": "v*-release",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
  {
    "id": 2,
    "project_id": 7,
    "tag_name_pattern": "latest",
    "minimum_access_level_for_push": "owner",
    "minimum_access_level_for_delete": "owner"
  }
]
```

## 컨테이너 레지스트리 보호 태그 규칙 생성 {#create-a-container-registry-protection-tag-rule}

{{< history >}}

- [GitLab 18.8에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/581199)됨.

{{< /history >}}

프로젝트의 컨테이너 레지스트리 보호 태그 규칙을 생성합니다.

```plaintext
POST /api/v4/projects/:id/registry/protection/tag/rules
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|-----------|------|----------|-------------|
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `tag_name_pattern` | 문자열 | 예 | 보호 규칙으로 보호되는 컨테이너 태그 이름 패턴입니다. 예를 들어, `v*-release`입니다. 와일드카드 문자 `*`가 허용됩니다. |
| `minimum_access_level_for_push` | 문자열 | 예 | 컨테이너 태그를 푸시하는 데 필요한 최소 GitLab 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. |
| `minimum_access_level_for_delete` | 문자열 | 예 | 컨테이너 태그를 삭제하는 데 필요한 최소 GitLab 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|-----------|------|-------------|
| `id` | 정수 | 컨테이너 태그 규칙의 고유 식별자입니다. |
| `project_id` | 정수 | 이 컨테이너 태그 규칙이 속한 프로젝트의 ID입니다. |
| `tag_name_pattern` | 문자열 | 컨테이너 태그 이름을 일치시키는 데 사용되는 글로브 패턴입니다. 예를 들어, `v*-release`입니다. |
| `minimum_access_level_for_push` | 문자열 | 이 패턴과 일치하는 컨테이너 태그를 푸시하는 데 필요한 최소 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. |
| `minimum_access_level_for_delete` | 문자열 | 이 패턴과 일치하는 컨테이너 태그를 삭제하는 데 필요한 최소 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. |

다음 상태 코드를 반환할 수 있습니다:

- `201 Created`:  보호 규칙이 성공적으로 생성되었습니다.
- `400 Bad Request`:  보호 규칙이 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자는 보호 규칙을 생성할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.
- `422 Unprocessable Entity`:  보호 규칙을 생성할 수 없습니다. 예를 들어 `tag_name_pattern`이 이미 사용 중이기 때문입니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules" \
  --data '{
        "tag_name_pattern": "v*-release",
        "minimum_access_level_for_push": "maintainer",
        "minimum_access_level_for_delete": "maintainer"
    }'
```

응답 예시:

```json
{
  "id": 1,
  "project_id": 7,
  "tag_name_pattern": "v*-release",
  "minimum_access_level_for_push": "maintainer",
  "minimum_access_level_for_delete": "maintainer"
}
```

## 컨테이너 레지스트리 보호 태그 규칙 업데이트 {#update-a-container-registry-protection-tag-rule}

{{< history >}}

- GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/581199).

{{< /history >}}

프로젝트의 컨테이너 레지스트리 보호 태그 규칙을 업데이트합니다.

```plaintext
PATCH /api/v4/projects/:id/registry/protection/tag/rules/:protection_rule_id
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|-----------|------|----------|-------------|
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `protection_rule_id` | 정수 | 예 | 업데이트할 보호 태그 규칙의 ID입니다. |
| `minimum_access_level_for_delete` | 문자열 | 아니요 | 컨테이너 태그를 삭제하는 데 필요한 최소 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. 값을 해제하려면 빈 문자열(`""`)을 사용합니다. |
| `minimum_access_level_for_push` | 문자열 | 아니요 | 컨테이너 태그를 푸시하는 데 필요한 최소 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. 값을 해제하려면 빈 문자열(`""`)을 사용합니다. |
| `tag_name_pattern` | 문자열 | 아니요 | 보호 규칙으로 보호되는 컨테이너 태그 이름 패턴입니다. 예를 들어, `v*-release`입니다. 와일드카드 문자 `*`가 허용됩니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성 | 유형 | 설명 |
|-----------|------|-------------|
| `id` | 정수 | 컨테이너 태그 규칙의 고유 식별자입니다. |
| `project_id` | 정수 | 이 컨테이너 태그 규칙이 속한 프로젝트의 ID입니다. |
| `tag_name_pattern` | 문자열 | 컨테이너 태그 이름을 일치시키는 데 사용되는 글로브 패턴입니다. 예를 들어, `v*-release`입니다. |
| `minimum_access_level_for_push` | 문자열 | 이 패턴과 일치하는 컨테이너 태그를 푸시하는 데 필요한 최소 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. |
| `minimum_access_level_for_delete` | 문자열 | 이 패턴과 일치하는 컨테이너 태그를 삭제하는 데 필요한 최소 액세스 수준입니다. 가능한 값: `maintainer`, `owner` 또는 `admin`. |

다음 상태 코드를 반환할 수 있습니다:

- `200 OK`:  보호 규칙이 성공적으로 업데이트되었습니다.
- `400 Bad Request`:  보호 규칙이 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자는 보호 규칙을 업데이트할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.
- `422 Unprocessable Entity`:  보호 규칙을 업데이트할 수 없습니다. 예를 들어 `tag_name_pattern`이 이미 사용 중이기 때문입니다.

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules/1" \
  --data '{
       "tag_name_pattern": "v*-stable"
    }'
```

응답 예시:

```json
{
  "id": 1,
  "project_id": 7,
  "tag_name_pattern": "v*-stable",
  "minimum_access_level_for_push": "maintainer",
  "minimum_access_level_for_delete": "maintainer"
}
```

## 컨테이너 레지스트리 보호 태그 규칙 삭제 {#delete-a-container-registry-protection-tag-rule}

{{< history >}}

- GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/581199).

{{< /history >}}

프로젝트에서 컨테이너 레지스트리 보호 태그 규칙을 삭제합니다.

```plaintext
DELETE /api/v4/projects/:id/registry/protection/tag/rules/:protection_rule_id
```

지원되는 속성:

| 속성 | 유형 | 필수 | 설명 |
|-----------|------|----------|-------------|
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `protection_rule_id` | 정수 | 예 | 삭제할 컨테이너 레지스트리 보호 태그 규칙의 ID입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

다음 상태 코드를 반환할 수 있습니다:

- `204 No Content`:  보호 규칙이 성공적으로 삭제되었습니다.
- `400 Bad Request`:  `id` 또는 `protection_rule_id`이 누락되었거나 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자는 보호 규칙을 삭제할 권한이 없습니다.
- `404 Not Found`:  프로젝트 또는 보호 규칙을 찾을 수 없습니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules/1"
```
