---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 별칭 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [프로젝트 별칭](../user/project/working_with_projects.md#project-aliases)을 관리합니다. 프로젝트에 별칭을 만든 후 사용자는 별칭을 사용하여 리포지토리를 복제할 수 있으며, 이는 리포지토리를 마이그레이션할 때 도움이 됩니다.

모든 메서드는 관리자 권한이 필요합니다.

## 모든 프로젝트 별칭 나열 {#list-all-project-aliases}

모든 프로젝트 별칭 목록을 가져옵니다:

```plaintext
GET /project_aliases
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성    | 유형    | 설명 |
|--------------|---------|-------------|
| `id`         | 정수 | 프로젝트 별칭의 ID입니다. |
| `name`       | 문자열  | 별칭의 이름입니다. |
| `project_id` | 정수 | 연결된 프로젝트의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases"
```

응답 예시:

```json
[
  {
    "id": 1,
    "project_id": 1,
    "name": "gitlab-foss"
  },
  {
    "id": 2,
    "project_id": 2,
    "name": "gitlab"
  }
]
```

## 프로젝트 별칭 검색 {#retrieve-a-project-alias}

프로젝트 별칭의 세부 정보를 검색합니다:

```plaintext
GET /project_aliases/:name
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명           |
|-----------|--------|----------|-----------------------|
| `name`    | 문자열 | 예      | 별칭의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성    | 유형    | 설명 |
|--------------|---------|-------------|
| `id`         | 정수 | 프로젝트 별칭의 ID입니다. |
| `name`       | 문자열  | 별칭의 이름입니다. |
| `project_id` | 정수 | 연결된 프로젝트의 ID입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```

응답 예시:

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab"
}
```

## 프로젝트 별칭 만들기 {#create-a-project-alias}

프로젝트의 새 별칭을 추가합니다:

```plaintext
POST /project_aliases
```

지원되는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `name`       | 문자열            | 예      | 별칭의 이름입니다. 고유해야 합니다. |
| `project_id` | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 경로입니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성    | 유형    | 설명 |
|--------------|---------|-------------|
| `id`         | 정수 | 프로젝트 별칭의 ID입니다. |
| `name`       | 문자열  | 별칭의 이름입니다. |
| `project_id` | 정수 | 연결된 프로젝트의 ID입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=1" \
  --form "name=gitlab"
```

프로젝트 경로를 사용할 수도 있습니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=gitlab-org/gitlab" \
  --form "name=gitlab"
```

응답 예시:

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab"
}
```

## 프로젝트 별칭 삭제 {#delete-a-project-alias}

프로젝트 별칭을 제거합니다:

```plaintext
DELETE /project_aliases/:name
```

지원되는 속성:

| 속성 | 유형   | 필수 | 설명           |
|-----------|--------|----------|-----------------------|
| `name`    | 문자열 | 예      | 별칭의 이름입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```
