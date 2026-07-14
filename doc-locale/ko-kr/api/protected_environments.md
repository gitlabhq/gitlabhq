---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보호 환경 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [보호 환경](../ci/environments/protected_environments.md)과 상호작용합니다.

> [!note]
> 그룹 수준 보호 환경에 대한 자세한 내용은 [그룹 수준 보호 환경 API](group_protected_environments.md)를 참조하세요.

## 유효한 액세스 수준 {#valid-access-levels}

액세스 수준은 `ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS` 메서드에서 정의됩니다. 현재 다음 수준이 인식됩니다:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## 그룹 상속 유형 {#group-inheritance-types}

그룹 상속을 사용하면 배포 액세스 수준 및 액세스 규칙에서 상속된 그룹 멤버십을 고려할 수 있습니다. 그룹 상속 유형은 `ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE`에서 정의됩니다. 다음 유형이 인식됩니다:

```plaintext
0 => Direct group membership only (default)
1 => All inherited groups
```

## 보호 환경 나열 {#list-protected-environments}

프로젝트에서 보호 환경 목록을 가져옵니다:

```plaintext
GET /projects/:id/protected_environments
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/"
```

응답 예시:

```json
[
   {
      "name":"production",
      "deploy_access_levels":[
         {
            "id": 12,
            "access_level":40,
            "access_level_description":"Maintainers",
            "user_id":null,
            "group_id":null,
            "group_inheritance_type": 0
         }
      ],
      "required_approval_count": 0
   }
]
```

## 단일 보호 환경 가져오기 {#get-a-single-protected-environment}

단일 보호 환경을 가져옵니다:

```plaintext
GET /projects/:id/protected_environments/:name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `name` | 문자열 | 예 | 보호 환경의 이름 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/production"
```

응답 예시:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 0
}
```

## 단일 환경 보호 {#protect-a-single-environment}

단일 환경을 보호합니다:

```plaintext
POST /projects/:id/protected_environments
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                            | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`                          | 문자열         | 예 | 환경의 이름입니다. |
| `deploy_access_levels`          | 배열          | 예 | 배포가 허용된 액세스 수준의 배열(각각 해시로 설명됨). |
| `approval_rules`                | 배열          | 아니요  | 승인이 허용된 액세스 수준의 배열(각각 해시로 설명됨). [승인 규칙](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)을 참조하세요. |

`deploy_access_levels` 및 `approval_rules` 배열의 요소는 `user_id`, `group_id` 또는 `access_level` 중 하나여야 하며 `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식을 사용합니다. 선택적으로 각 항목에 `group_inheritance_type`를 [유효한 그룹 상속 유형](#group-inheritance-types) 중 하나로 지정할 수 있습니다.

각 사용자는 프로젝트에 대한 액세스 권한이 있어야 하고 각 그룹은 [이 프로젝트를 공유](../user/project/members/sharing_projects_groups.md)해야 합니다.

```shell
curl --header 'Content-Type: application/json' \
     --request POST \
     --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}], "approval_rules": [{"group_id": 134}, {"group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments"
```

응답 예시:

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899826,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 0,
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 134,
         "access_level": null,
         "access_level_description": "qa-group",
         "required_approvals": 1,
         "group_inheritance_type": 0
      },
      {
         "id": 39,
         "user_id": null,
         "group_id": 135,
         "access_level": null,
         "access_level_description": "security-group",
         "required_approvals": 2,
         "group_inheritance_type": 0
      }
   ]
}
```

## 보호 환경 업데이트 {#update-a-protected-environment}

{{< history >}}

- GitLab 15.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/351854).

{{< /history >}}

단일 환경을 업데이트합니다.

```plaintext
PUT /projects/:id/protected_environments/:name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`                            | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`                          | 문자열         | 예 | 환경의 이름입니다. |
| `deploy_access_levels`          | 배열          | 아니요  | 배포가 허용된 액세스 수준의 배열(각각 해시로 설명됨). |
| `approval_rules`                | 배열          | 아니요  | 승인이 허용된 액세스 수준의 배열(각각 해시로 설명됨). 자세한 내용은 [승인 규칙](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)을 참조하세요. |

`deploy_access_levels` 및 `approval_rules` 배열의 요소는 `user_id`, `group_id` 또는 `access_level` 중 하나여야 하며 `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형식을 사용합니다. 선택적으로 각 항목에 `group_inheritance_type`를 [유효한 그룹 상속 유형](#group-inheritance-types) 중 하나로 지정할 수 있습니다.

업데이트하려면:

- **`user_id`**:  업데이트된 사용자가 프로젝트에 액세스할 수 있는지 확인합니다. `id`의 `deploy_access_level` 또는 `approval_rule` 중 하나를 각각의 해시에 전달해야 합니다.
- **`group_id`**:  업데이트된 그룹이 [이 프로젝트를 공유](../user/project/members/sharing_projects_groups.md)하는지 확인합니다. `id`의 `deploy_access_level` 또는 `approval_rule` 중 하나를 각각의 해시에 전달해야 합니다.

삭제하려면:

- `_destroy`을 `true`로 설정하여 전달해야 합니다. 다음 예제를 참조하세요.

### 예:  `deploy_access_level` 레코드 생성 {#example-create-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"group_id": 9899829, access_level: 40}]' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

응답 예시:

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899829,
         "group_inheritance_type": 1
      }
   ],
   "required_approval_count": 0
}
```

### 예:  `deploy_access_level` 레코드 업데이트 {#example-update-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"id": 12, "group_id": 22034120}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 22034120,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 2
}
```

### 예:  `deploy_access_level` 레코드 삭제 {#example-delete-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"id": 12, "_destroy": true}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

응답 예시:

```json
{
   "name": "production",
   "deploy_access_levels": [],
   "required_approval_count": 0
}
```

### 예:  `approval_rule` 레코드 생성 {#example-create-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"group_id": 134, "required_approvals": 1}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

응답 예시:

```json
{
   "name": "production",
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 134,
         "access_level": null,
         "access_level_description": "qa-group",
         "required_approvals": 1,
         "group_inheritance_type": 0
      }
   ]
}
```

### 예:  `approval_rule` 레코드 업데이트 {#example-update-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"id": 38, "group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

```json
{
   "name": "production",
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 135,
         "access_level": null,
         "access_level_description": "security-group",
         "required_approvals": 2,
         "group_inheritance_type": 0
      }
   ]
}
```

### 예:  `approval_rule` 레코드 삭제 {#example-delete-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"id": 38, "_destroy": true}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

응답 예시:

```json
{
   "name": "production",
   "approval_rules": []
}
```

## 단일 환경 보호 해제 {#unprotect-a-single-environment}

주어진 보호 환경의 보호를 해제합니다:

```plaintext
DELETE /projects/:id/protected_environments/:name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `name` | 문자열 | 예 | 보호 환경의 이름. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/staging"
```
