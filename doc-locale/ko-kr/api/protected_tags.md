---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보호된 태그 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [보호된 태그](../user/project/protected_tags.md)를 관리합니다.

## 유효한 액세스 수준 {#valid-access-levels}

다음 액세스 수준이 인식됩니다:

- `0`:  액세스 권한 없음
- `30`:  개발자 역할
- `40`:  유지관리자 역할

## 보호된 태그 나열 {#list-protected-tags}

{{< history >}}

- 배포 키 정보가 GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846)되었습니다.

{{< /history >}}

프로젝트에서 [보호된 태그](../user/project/protected_tags.md)의 목록을 가져옵니다. 이 함수는 페이지 매김 매개변수 `page`와 `per_page`를 사용하여 보호된 태그 목록을 제한합니다.

```plaintext
GET /projects/:id/protected_tags
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명                                                                      |
|-----------|-------------------|----------|----------------------------------------------------------------------------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다.       |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                         | 유형    | 설명 |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | 배열   | 액세스 수준 구성 생성의 배열입니다. |
| `create_access_levels[].access_level`             | 정수 | 태그를 생성하는 액세스 수준입니다. |
| `create_access_levels[].access_level_description` | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `create_access_levels[].deploy_key_id`            | 정수 | 생성 액세스 권한이 있는 배포 키의 ID입니다. |
| `create_access_levels[].group_id`                 | 정수 | 생성 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `create_access_levels[].id`                       | 정수 | 액세스 수준 구성 생성의 ID입니다. |
| `create_access_levels[].user_id`                  | 정수 | 생성 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `name`                                            | 문자열  | 보호된 태그의 이름입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags"
```

응답 예시:

```json
[
  {
    "name": "release-1-0",
    "create_access_levels": [
      {
        "id":1,
        "access_level": 40,
        "access_level_description": "Maintainers"
      },
      {
        "id": 2,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1
      }
    ]
  }
]
```

## 보호된 태그 또는 와일드카드 보호된 태그 가져오기 {#get-a-protected-tag-or-wildcard-protected-tag}

단일 보호된 태그 또는 와일드카드 보호된 태그를 가져옵니다.

```plaintext
GET /projects/:id/protected_tags/:name
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`    | 문자열            | 예      | 태그 또는 와일드카드의 이름입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                         | 유형    | 설명 |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | 배열   | 액세스 수준 구성 생성의 배열입니다. |
| `create_access_levels[].access_level`             | 정수 | 태그를 생성하는 액세스 수준입니다. |
| `create_access_levels[].access_level_description` | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `create_access_levels[].deploy_key_id`            | 정수 | 생성 액세스 권한이 있는 배포 키의 ID입니다. |
| `create_access_levels[].group_id`                 | 정수 | 생성 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `create_access_levels[].id`                       | 정수 | 액세스 수준 구성 생성의 ID입니다. |
| `create_access_levels[].user_id`                  | 정수 | 생성 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `name`                                            | 문자열  | 보호된 태그의 이름입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags/release-1-0"
```

응답 예시:

```json
{
  "name": "release-1-0",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ]
}
```

## 리포지토리 태그 보호 {#protect-a-repository-tag}

{{< history >}}

- `deploy_key_id` 구성이 GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166866)되었습니다.
- `deploy_key_id` 구성이 GitLab 18.10에서 GitLab Premium에서 GitLab Free로 [이동](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542)되었습니다.

{{< /history >}}

와일드카드 보호된 태그를 사용하여 단일 리포지토리 태그 또는 여러 프로젝트 리포지토리 태그를 보호합니다.

```plaintext
POST /projects/:id/protected_tags
```

지원되는 속성:

| 속성             | 유형              | 필수 | 설명 |
|-----------------------|-------------------|----------|-------------|
| `id`                  | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`                | 문자열            | 예      | 태그 또는 와일드카드의 이름입니다. |
| `allowed_to_create`   | 배열             | 아니요       | 태그를 생성할 수 있는 액세스 수준의 배열입니다. 각각은 `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` 또는 `{access_level: integer}`의 형식의 해시로 설명됩니다. `user_id`, `group_id` 및 `access_level`은(는) Premium 및 Ultimate만 해당합니다. |
| `create_access_level` | 정수           | 아니요       | 생성할 수 있는 액세스 수준입니다. 기본값은 `40`(유지관리자 역할)입니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성                                         | 유형    | 설명 |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | 배열   | 액세스 수준 구성 생성의 배열입니다. |
| `create_access_levels[].access_level`             | 정수 | 태그를 생성하는 액세스 수준입니다. |
| `create_access_levels[].access_level_description` | 문자열  | 액세스 수준에 대한 사람이 읽을 수 있는 설명입니다. |
| `create_access_levels[].deploy_key_id`            | 정수 | 생성 액세스 권한이 있는 배포 키의 ID입니다. |
| `create_access_levels[].group_id`                 | 정수 | 생성 액세스 권한이 있는 그룹의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `create_access_levels[].id`                       | 정수 | 액세스 수준 구성 생성의 ID입니다. |
| `create_access_levels[].user_id`                  | 정수 | 생성 액세스 권한이 있는 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `name`                                            | 문자열  | 보호된 태그의 이름입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags" \
  --data '{
   "allowed_to_create" : [
      {
         "user_id" : 1
      },
      {
         "access_level" : 30
      }
   ],
   "create_access_level" : 30,
   "name" : "*-stable"
}'
```

응답 예시:

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ]
}
```

### 사용자 및 그룹 액세스 예 {#example-with-user-and-group-access}

`allowed_to_create` 배열의 요소는 `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` 또는 `{access_level: integer}`의 형식을 따릅니다. 각 사용자는 프로젝트에 대한 액세스 권한이 있어야 하고 각 그룹은 [이 프로젝트를 공유](../user/project/members/sharing_projects_groups.md)해야 합니다. 이러한 액세스 수준은 보호된 태그 액세스에 대한 더 세분화된 제어를 제공합니다. 자세한 내용은 [보호된 태그에 그룹 추가](../user/project/protected_tags.md#add-a-group-to-protected-tags)를 참조하세요.

이 요청 예는 특정 사용자 및 그룹에 생성 액세스 권한이 있는 보호된 태그를 생성하는 방법을 보여줍니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags" \
  --data "name=*-stable" \
  --data "allowed_to_create[][user_id]=10" \
  --data "allowed_to_create[][group_id]=20"
```

이 응답 예에는 다음이 포함됩니다:

- 이름이 `"*-stable"`인 보호된 태그입니다.
- ID `1`가 있는 `create_access_levels`(ID `10`인 사용자용)입니다.
- ID `2`가 있는 `create_access_levels`(ID `20`인 그룹용)입니다.

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": null,
      "user_id": 10,
      "group_id": null,
      "access_level_description": "Administrator"
    },
    {
      "id": 2,
      "access_level": null,
      "user_id": null,
      "group_id": 20,
      "access_level_description": "Example Create Group"
    }
  ]
}
```

## 리포지토리 태그 보호 해제 {#unprotect-repository-tags}

주어진 보호된 태그 또는 와일드카드 보호된 태그의 보호를 해제합니다.

```plaintext
DELETE /projects/:id/protected_tags/:name
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`    | 문자열            | 예      | 태그의 이름입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags/*-stable"
```

## 관련 항목 {#related-topics}

- [Tags API](tags.md) (모든 태그용)
- [Tags](../user/project/repository/tags/_index.md) 사용자 설명서
- [보호된 태그](../user/project/protected_tags.md) 사용자 설명서
