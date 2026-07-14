---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 수준 보호 환경 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 14.0에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/215888). [`group_level_protected_environments` 플래그 뒤에 배포됨](../administration/feature_flags/_index.md), 기본적으로 비활성화되어 있습니다.
- [`group_level_protected_environments` 기능 플래그](https://gitlab.com/gitlab-org/gitlab/-/issues/331085)가 GitLab 14.3에서 제거되었습니다.
- GitLab 14.3에서 [일반적으로 사용 가능합니다](https://gitlab.com/gitlab-org/gitlab/-/issues/331085).

{{< /history >}}

이 API를 사용하여 [그룹 수준 보호 환경](../ci/environments/protected_environments.md#group-level-protected-environments)과 상호 작용할 수 있습니다.

> [!note]
> 보호 환경에 대해서는 [보호 환경 API](protected_environments.md)를 참조하세요.

## 유효한 액세스 수준 {#valid-access-levels}

액세스 수준은 `ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS` 메서드에 정의됩니다. 현재 다음 수준이 인식됩니다:

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## 모든 그룹 수준 보호 환경 나열 {#list-all-group-level-protected-environments}

지정된 그룹의 모든 보호 환경을 나열합니다.

```plaintext
GET /groups/:id/protected_environments
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 인증된 사용자가 유지 관리하는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/"
```

예시 응답:

```json
[
   {
      "name":"production",
      "deploy_access_levels":[
         {
            "id": 12,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
         }
      ],
      "required_approval_count": 0
   }
]
```

## 단일 보호 환경 검색 {#retrieve-a-single-protected-environment}

그룹에서 지정된 보호 환경을 검색합니다.

```plaintext
GET /groups/:id/protected_environments/:name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 인증된 사용자가 유지 관리하는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`    | 문자열 | 예    | 보호 환경의 [배포 계층](../ci/environments/_index.md#deployment-tier-of-environments)입니다. 가능한 값: `production`, `staging`, `testing`, `development`, 또는 `other`입니다.|

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/production"
```

예시 응답:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level":40,
         "access_level_description":"Maintainers",
         "user_id":null,
         "group_id":null
      }
   ],
   "required_approval_count": 0
}
```

## 단일 환경 보호 {#protect-a-single-environment}

단일 환경을 보호합니다.

```plaintext
POST /groups/:id/protected_environments
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 인증된 사용자가 유지 관리하는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`    | 문자열 | 예    | 보호 환경의 [배포 계층](../ci/environments/_index.md#deployment-tier-of-environments)입니다. 가능한 값: `production`, `staging`, `testing`, `development`, 또는 `other`입니다.|
| `deploy_access_levels`          | 배열          | 예 | 배포가 허용되는 액세스 수준의 배열이며, 각각 해시로 설명됩니다. 가능한 값: `user_id`, `group_id` 또는 `access_level`입니다. `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형태를 가집니다. |
| `approval_rules`                | 배열          | 아니요  | 승인이 허용되는 액세스 수준의 배열이며, 각각 해시로 설명됩니다. 가능한 값: `user_id`, `group_id` 또는 `access_level`입니다. `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형태를 가집니다. `required_approvals` 필드를 사용하여 지정된 항목의 필수 승인 수를 지정할 수도 있습니다. [승인 규칙 여러 개](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)를 참조하여 자세한 내용을 확인하세요. |

할당 가능한 `user_id`은 Maintainer 역할 이상을 가진 주어진 그룹에 속하는 사용자입니다. 할당 가능한 `group_id`은 주어진 그룹 아래의 하위 그룹입니다.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments" \
  --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}'
```

예시 응답:

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899826
      }
   ],
   "required_approval_count": 0
}
```

승인 규칙이 여러 개인 예:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/128/protected_environments" \
  --data '{
    "name": "production",
    "deploy_access_levels": [{"group_id": 138}],
    "approval_rules": [
      {"group_id": 134},
      {"group_id": 135, "required_approvals": 2}
    ]
  }'
```

이 구성에서 운영자 그룹 `"group_id": 138`은 QA 그룹 `"group_id": 134` 및 보안 그룹 `"group_id": 135`이 배포를 승인한 후에만 `production`에 배포 작업을 실행할 수 있습니다.

## 보호 환경 업데이트 {#update-a-protected-environment}

{{< history >}}

- GitLab 15.4에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/351854).

{{< /history >}}

단일 환경을 업데이트합니다.

```plaintext
PUT /groups/:id/protected_environments/:name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 인증된 사용자가 유지 관리하는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`    | 문자열 | 예    | 보호 환경의 [배포 계층](../ci/environments/_index.md#deployment-tier-of-environments)입니다. 가능한 값: `production`, `staging`, `testing`, `development`, 또는 `other`입니다.|
| `deploy_access_levels`          | 배열          | 아니요 | 배포가 허용되는 액세스 수준의 배열이며, 각각 해시로 설명됩니다. 가능한 값: `user_id`, `group_id` 또는 `access_level`입니다. `{user_id: integer}`, `{group_id: integer}` 또는 `{access_level: integer}` 형태를 가집니다. |
| `required_approval_count` | 정수        | 아니요       | 이 환경에 배포하는 데 필요한 승인 수입니다. |
| `approval_rules`                | 배열          | 아니요  | 승인이 허용되는 액세스 수준의 배열이며, 각각 해시로 설명됩니다. 가능한 값: `user_id`, `group_id`, 또는 `access_level`입니다. `{user_id: integer}`, `{group_id: integer}`, 또는 `{access_level: integer}` 형태를 가집니다. `required_approvals` 필드를 사용하여 지정된 항목의 필수 승인 수를 지정할 수도 있습니다. [승인 규칙 여러 개](../ci/environments/deployment_approvals.md#add-multiple-approval-rules)를 참조하여 자세한 내용을 확인하세요. |

업데이트하려면:

- **`user_id`**:  업데이트된 사용자가 Maintainer 역할 이상을 가진 주어진 그룹에 속하는지 확인하세요. 또한 해당 해시에서 `deploy_access_level` 또는 `approval_rule` 중 하나의 `id`를 전달해야 합니다.
- **`group_id`**:  업데이트된 그룹이 이 보호 환경이 속하는 그룹의 하위 그룹인지 확인하세요. 또한 해당 해시에서 `deploy_access_level` 또는 `approval_rule` 중 하나의 `id`를 전달해야 합니다.

삭제하려면:

- `_destroy`을 `true`로 설정하여 전달해야 합니다. 다음 예를 참조하세요.

### 예:  `deploy_access_level` 레코드 만들기 {#example-create-a-deploy_access_level-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"group_id": 9899829, "access_level": 40}]}'
```

예시 응답:

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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"id": 12, "group_id": 22034120}]}'
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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"id": 12, "_destroy": true}]}'
```

예시 응답:

```json
{
   "name": "production",
   "deploy_access_levels": [],
   "required_approval_count": 0
}
```

### 예:  `approval_rule` 레코드 만들기 {#example-create-an-approval_rule-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"group_id": 134, "required_approvals": 1}]}'
```

예시 응답:

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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"id": 38, "group_id": 135, "required_approvals": 2}]}'
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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"id": 38, "_destroy": true}]}'
```

예시 응답:

```json
{
   "name": "production",
   "approval_rules": []
}
```

## 단일 환경 보호 해제 {#unprotect-a-single-environment}

주어진 보호 환경을 보호 해제합니다.

```plaintext
DELETE /groups/:id/protected_environments/:name
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 인증된 사용자가 유지 관리하는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name`    | 문자열 | 예    | 보호 환경의 [배포 계층](../ci/environments/_index.md#deployment-tier-of-environments)입니다. 가능한 값: `production`, `staging`, `testing`, `development`, 또는 `other`입니다.|

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/staging"
```

응답은 200 코드를 반환해야 합니다.
