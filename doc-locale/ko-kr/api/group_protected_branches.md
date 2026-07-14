---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 수준의 보호된 브랜치 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/500250) GitLab 17.6입니다. 기능 플래그 `group_protected_branches` 제거됨.

{{< /history >}}

이 API를 사용하여 그룹의 모든 프로젝트에 상속되는 [보호된 브랜치 설정](../user/project/repository/branches/protected.md#in-a-group)을 관리합니다. 그룹 보호된 브랜치는 [유효한 액세스 수준](#valid-access-levels)만 지원합니다. 개별 사용자와 그룹은 지정할 수 없습니다.

> [!warning]
> 보호된 브랜치 설정은 최상위 그룹으로만 제한됩니다.

## 유효한 액세스 수준 {#valid-access-levels}

액세스 수준은 `ProtectedRefAccess.allowed_access_levels` 메서드에 정의됩니다. 다음과 같은 수준이 인식됩니다:

```plaintext
0  => No access
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## 보호된 브랜치 나열 {#list-protected-branches}

그룹에서 보호된 브랜치의 목록을 가져옵니다. 와일드카드가 설정된 경우, 해당 와일드카드와 일치하는 브랜치의 정확한 이름 대신 반환됩니다.

```plaintext
GET /groups/:id/protected_branches
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `search` | 문자열 | 아니요 | 검색할 보호된 브랜치의 이름 또는 이름의 일부입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches"
```

예시 응답:

```json
[
  {
    "id": 1,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  {
    "id": 1,
    "name": "release/*",
    "push_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  ...
]
```

## 단일 보호된 브랜치 또는 와일드카드 보호된 브랜치 가져오기 {#get-a-single-protected-branch-or-wildcard-protected-branch}

단일 보호된 브랜치 또는 와일드카드 보호된 브랜치를 가져옵니다.

```plaintext
GET /groups/:id/protected_branches/:name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name` | 문자열 | 예 | 브랜치 또는 와일드카드의 이름입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/main"
```

예시 응답:

```json
{
  "id": 1,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

## 리포지토리 브랜치 보호 {#protect-repository-branches}

와일드카드 보호된 브랜치를 사용하여 단일 리포지토리 브랜치를 보호합니다.

```plaintext
POST /groups/:id/protected_branches
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

| 속성                                    | 유형 | 필수 | 설명 |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`                                       | 문자열         | 예 | 브랜치 또는 와일드카드의 이름입니다. |
| `allow_force_push`                           | 부울        | 아니요  | 푸시 액세스 권한이 있는 모든 사용자가 강제 푸시할 수 있도록 허용합니다. 기본값: `false`. |
| `allowed_to_merge`                           | 배열          | 아니요  | 병합할 수 있는 액세스 수준의 배열입니다. 각 항목은 `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식의 해시로 설명됩니다. |
| `allowed_to_push`                            | 배열          | 아니요  | 푸시할 수 있는 액세스 수준의 배열입니다. 각 항목은 `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식의 해시로 설명됩니다. |
| `allowed_to_unprotect`                       | 배열          | 아니요  | 보호 해제할 수 있는 액세스 수준의 배열입니다. 각 항목은 `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식의 해시로 설명됩니다. |
| `code_owner_approval_required`               | 부울        | 아니요  | 이 브랜치가 [`CODEOWNERS` 파일](../user/project/codeowners/_index.md)의 항목과 일치하면 푸시를 방지합니다. 기본값: `false`. |
| `merge_access_level`                         | 정수        | 아니요  | 병합할 수 있는 액세스 수준입니다. 기본값: `40`, 유지관리자 역할입니다. |
| `push_access_level`                          | 정수        | 아니요  | 푸시할 수 있는 액세스 수준입니다. 기본값: `40`, 유지관리자 역할입니다. |
| `unprotect_access_level`                     | 정수        | 아니요  | 보호 해제할 수 있는 액세스 수준입니다. 기본값: `40`, 유지관리자 역할입니다. |

예시 응답:

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### 액세스 수준의 예시 {#example-with-access-levels}

액세스 수준을 사용하여 그룹 보호된 브랜치를 구성합니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_push": [{"access_level": 30}],
    "allowed_to_merge": [{
        "access_level": 30
      },{
        "access_level": 40
      }
    ]}'
    --url "https://gitlab.example.com/api/v4/groups/5/protected_branches"
```

예시 응답:

```json
{
    "id": 5,
    "name": "main",
    "push_access_levels": [
        {
            "id": 1,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "merge_access_levels": [
        {
            "id": 1,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        },
        {
            "id": 2,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "unprotect_access_levels": [
        {
            "id": 1,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
}
```

## 리포지토리 브랜치 보호 해제 {#unprotect-repository-branches}

주어진 보호된 브랜치 또는 와일드카드 보호된 브랜치를 보호 해제합니다.

```plaintext
DELETE /groups/:id/protected_branches/:name
```

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/*-stable"
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name` | 문자열 | 예 | 브랜치의 이름입니다. |

예시 응답:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

## 보호된 브랜치 업데이트 {#update-a-protected-branch}

보호된 브랜치를 업데이트합니다.

```plaintext
PATCH /groups/:id/protected_branches/:name
```

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

| 속성                                    | 유형           | 필수 | 설명                                                                                                                          |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다.                       |
| `name`                                       | 문자열         | 예      | 브랜치의 이름입니다.                                                                                                               |
| `allow_force_push`                           | 부울        | 아니요       | 사용하도록 설정하면, 이 브랜치로 푸시할 수 있는 멤버는 강제 푸시도 수행할 수 있습니다.                                                               |
| `allowed_to_push`                            | 배열          | 아니요       | 푸시 액세스 수준의 배열입니다. 각 항목은 해시로 설명됩니다.                                                                          |
| `allowed_to_merge`                           | 배열          | 아니요       | 병합 액세스 수준의 배열입니다. 각 항목은 해시로 설명됩니다.                                                                         |
| `allowed_to_unprotect`                       | 배열          | 아니요       | 보호 해제 액세스 수준의 배열입니다. 각 항목은 해시로 설명됩니다.                                                                     |
| `code_owner_approval_required`               | 부울        | 아니요       | 이 브랜치가 [`CODEOWNERS` 파일](../user/project/codeowners/_index.md)의 항목과 일치하면 푸시를 방지합니다. 기본값: `false`. |

`allowed_to_push`, `allowed_to_merge` 및 `allowed_to_unprotect` 배열의 요소는 `{access_level: integer}` 형식이어야 합니다. 각 액세스 수준은 [유효한 액세스 수준](#valid-access-levels)의 유효한 값이어야 합니다.

- 액세스 수준을 업데이트하려면 각각의 해시에서 `id` of the `access_level`를 전달해야 합니다.
- 액세스 수준을 삭제하려면 `_destroy`을 `true`로 설정해야 합니다. 다음 예를 참조하세요.

### 예시: `push_access_level` 레코드 생성 {#example-create-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{access_level: 40}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

예시 응답:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### 예시: `push_access_level` 레코드 업데이트 {#example-update-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "access_level": 0}]' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

예시 응답:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 0,
         "access_level_description": "No One",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### 예시: `push_access_level` 레코드 삭제 {#example-delete-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "_destroy": true}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

예시 응답:

```json
{
   "name": "main",
   "push_access_levels": []
}
```
