---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 컨테이너 레지스트리 보호 규칙을 위한 REST API 설명서입니다.
title: 컨테이너 레지스트리 보호 규칙 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155798) 되었으며 [플래그](../administration/feature_flags/_index.md)는 `container_registry_protected_containers`입니다. 기본적으로 비활성화됨.
- GitLab 17.8에서 [GitLab.com에 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/429074)되었습니다.
- GitLab 17.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/480385)합니다. 기능 플래그 `container_registry_protected_containers` 제거됨.

{{< /history >}}

이 API를 사용하여 [컨테이너 레지스트리 보호 규칙](../user/packages/container_registry/protected_container_tags.md)을 관리합니다.

## 모든 컨테이너 레지스트리 보호 규칙 나열 {#list-all-container-repository-protection-rules}

지정된 프로젝트의 모든 컨테이너 레지스트리 보호 규칙을 나열합니다.

```plaintext
GET /api/v4/projects/:id/registry/protection/repository/rules
```

지원되는 속성:

| 속성                     | 유형            | 필수 | 설명                    |
|-------------------------------|-----------------|----------|--------------------------------|
| `id`                          | 정수 또는 문자열  | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)를 반환하고 컨테이너 레지스트리 보호 규칙 목록을 표시합니다.

다음 상태 코드를 반환할 수 있습니다:

- `200 OK`:  보호 규칙 목록입니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자가 이 프로젝트의 보호 규칙을 나열할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules"
```

응답 예시:

```json
[
  {
    "id": 1,
    "project_id": 7,
    "repository_path_pattern": "flightjs/flight0",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
  {
    "id": 2,
    "project_id": 7,
    "repository_path_pattern": "flightjs/flight1",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  }
]
```

## 컨테이너 레지스트리 보호 규칙 생성 {#create-a-container-repository-protection-rule}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/457518)되었습니다.

{{< /history >}}

지정된 프로젝트에 대한 컨테이너 레지스트리 보호 규칙을 생성합니다.

```plaintext
POST /api/v4/projects/:id/registry/protection/repository/rules
```

지원되는 속성:

| 속성                         | 유형           | 필수 | 설명 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `repository_path_pattern`         | 문자열         | 예      | 보호 규칙으로 보호되는 컨테이너 레지스트리 경로 패턴입니다. 예를 들어 `flight/flight-*`입니다. 와일드카드 문자 `*`는 허용됩니다. |
| `minimum_access_level_for_delete` | 문자열         | 아니요       | 컨테이너 레지스트리에서 컨테이너 이미지를 삭제하는 데 필요한 최소 GitLab 액세스 수준입니다. 예를 들어 `maintainer`, `owner`, `admin`입니다. `minimum_access_level_for_push`가 설정되지 않을 때 제공해야 합니다. |
| `minimum_access_level_for_push`   | 문자열         | 아니요       | 컨테이너 레지스트리에 컨테이너 이미지를 푸시하는 데 필요한 최소 GitLab 액세스 수준입니다. 예를 들어 `maintainer`, `owner` 또는 `admin`입니다. `minimum_access_level_for_delete`가 설정되지 않을 때 제공해야 합니다. |

성공하면 [`201`](rest/troubleshooting.md#status-codes)를 반환하고 생성된 컨테이너 레지스트리 보호 규칙을 표시합니다.

다음 상태 코드를 반환할 수 있습니다:

- `201 Created`:  보호 규칙이 성공적으로 생성되었습니다.
- `400 Bad Request`:  보호 규칙이 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자가 보호 규칙을 생성할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.
- `422 Unprocessable Entity`:  보호 규칙을 생성할 수 없습니다. 예를 들어 `repository_path_pattern`가 이미 사용 중이기 때문입니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules" \
  --data '{
        "repository_path_pattern": "flightjs/flight-needs-to-be-a-unique-path",
        "minimum_access_level_for_push": "maintainer",
        "minimum_access_level_for_delete": "maintainer"
    }'
```

## 컨테이너 레지스트리 보호 규칙 업데이트 {#update-a-container-repository-protection-rule}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/457518)되었습니다.

{{< /history >}}

지정된 프로젝트에 대한 컨테이너 레지스트리 보호 규칙을 업데이트합니다.

```plaintext
PATCH /api/v4/projects/:id/registry/protection/repository/rules/:protection_rule_id
```

지원되는 속성:

| 속성                         | 유형           | 필수 | 설명 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `protection_rule_id`              | 정수        | 예      | 업데이트할 보호 규칙의 ID입니다. |
| `minimum_access_level_for_delete` | 문자열         | 아니요       | 컨테이너 레지스트리에서 컨테이너 이미지를 삭제하는 데 필요한 최소 GitLab 액세스 수준입니다. 예를 들어 `maintainer`, `owner`, `admin`입니다. `minimum_access_level_for_push`가 설정되지 않을 때 제공해야 합니다. 값을 설정 해제하려면 빈 문자열 `""`을 사용합니다. |
| `minimum_access_level_for_push`   | 문자열         | 아니요       | 컨테이너 레지스트리에 컨테이너 이미지를 푸시하는 데 필요한 최소 GitLab 액세스 수준입니다. 예를 들어 `maintainer`, `owner` 또는 `admin`입니다. `minimum_access_level_for_delete`가 설정되지 않을 때 제공해야 합니다. 값을 설정 해제하려면 빈 문자열 `""`을 사용합니다. |
| `repository_path_pattern`         | 문자열         | 아니요       | 보호 규칙으로 보호되는 컨테이너 레지스트리 경로 패턴입니다. 예를 들어 `flight/flight-*`입니다. 와일드카드 문자 `*`는 허용됩니다. |

성공하면 [`200`](rest/troubleshooting.md#status-codes)를 반환하고 업데이트된 보호 규칙을 표시합니다.

다음 상태 코드를 반환할 수 있습니다:

- `200 OK`:  보호 규칙이 성공적으로 업데이트되었습니다.
- `400 Bad Request`:  보호 규칙이 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자가 보호 규칙을 업데이트할 권한이 없습니다.
- `404 Not Found`:  프로젝트를 찾을 수 없습니다.
- `422 Unprocessable Entity`:  보호 규칙을 업데이트할 수 없습니다. 예를 들어 `repository_path_pattern`가 이미 사용 중이기 때문입니다.

요청 예시:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules/32" \
  --data '{
       "repository_path_pattern": "flight/flight-*"
    }'
```

## 컨테이너 레지스트리 보호 규칙 삭제 {#delete-a-container-repository-protection-rule}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/457518)되었습니다.

{{< /history >}}

지정된 컨테이너 레지스트리 보호 규칙을 삭제합니다.

```plaintext
DELETE /api/v4/projects/:id/registry/protection/repository/rules/:protection_rule_id
```

지원되는 속성:

| 속성            | 유형           | 필수 | 설명 |
|----------------------|----------------|----------|-------------|
| `id`                 | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `protection_rule_id` | 정수        | 예      | 삭제할 컨테이너 레지스트리 보호 규칙의 ID입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

다음 상태 코드를 반환할 수 있습니다:

- `204 No Content`:  보호 규칙이 성공적으로 삭제되었습니다.
- `400 Bad Request`:  `id` 또는 `protection_rule_id`이 누락되었거나 유효하지 않습니다.
- `401 Unauthorized`:  액세스 토큰이 유효하지 않습니다.
- `403 Forbidden`:  사용자가 보호 규칙을 삭제할 권한이 없습니다.
- `404 Not Found`:  프로젝트 또는 보호 규칙을 찾을 수 없습니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/repository/rules/1"
```
