---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 멤버 역할 API
description: "사용자 지정 역할을 사용하여 GitLab.com 그룹 또는 GitLab Self-Managed 인스턴스의 멤버 역할을 관리합니다. 사용자 지정 멤버 역할을 프로그래밍 방식으로 나열, 생성 및 삭제합니다."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [GitLab 15.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96996) [`customizable_roles` 플래그 뒤에 배포됨](../administration/feature_flags/_index.md) (기본적으로 사용 안 함).
- [GitLab 15.9에서 기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810)
- [GitLab 16.0에서 읽기 취약성 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114734)
- [GitLab 16.1에서 관리 취약성 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121534)
- [GitLab 16.3에서 읽기 종속성 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126247)
- [GitLab 16.3에서 이름 및 설명 필드 추가됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423)
- [GitLab 16.4에서 관리 머지 리퀘스트 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128302) [플래그 포함](../administration/feature_flags/_index.md) 이름 `admin_merge_request`. 기본적으로 비활성화됨.
- [기능 플래그 `admin_merge_request` GitLab 16.5에서 제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132578)
- [GitLab 16.5에서 관리 그룹 멤버 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131914) [플래그 포함](../administration/feature_flags/_index.md) 이름 `admin_group_member`. 기본적으로 비활성화됨. 기능 플래그가 GitLab 16.6에서 제거되었습니다.
- [GitLab 16.5에서 프로젝트 액세스 토큰 관리 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132342) [플래그 포함](../administration/feature_flags/_index.md) 이름 `manage_project_access_tokens`. 기본적으로 비활성화됨.
- [GitLab 16.7에서 프로젝트 보관 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134998)
- [GitLab 16.8에서 프로젝트 삭제 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139696)
- [GitLab 16.8에서 그룹 액세스 토큰 관리 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140115)
- [GitLab 16.8에서 Terraform 상태 관리 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140759)
- GitLab Self-Managed에서 인스턴스 차원의 사용자 지정 역할을 생성 및 제거할 수 있도록 허용 [GitLab 16.9에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141562)

{{< /history >}}

이 API를 사용하여 GitLab.com 그룹 또는 전체 GitLab Self-Managed 인스턴스의 멤버 역할과 상호 작용합니다.

## 인스턴스 멤버 역할 관리 {#manage-instance-member-roles}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- 관리자로 [인증합니다](rest/authentication.md).

### 모든 인스턴스 멤버 역할 가져오기 {#get-all-instance-member-roles}

인스턴스의 모든 멤버 역할을 가져옵니다.

```plaintext
GET /member_roles
```

요청 예시:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/member_roles"
```

응답 예시:

```json
[
  {
    "id": 2,
    "name": "Instance custom role",
    "description": "Custom guest that can read code",
    "group_id": null,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": false,
    "read_vulnerability": false,
    "remove_group": false,
    "remove_project": false
  }
]
```

### 인스턴스 멤버 역할 생성 {#create-an-instance-member-role}

인스턴스 차원의 멤버 역할을 생성합니다.

```plaintext
POST /member_roles
```

지원되는 특성:

| 특성 | 유형 | 필수 | 설명 |
|:----------|:--------|:---------|:-------------------------------------|
| `name`         | 문자열         | 예      | 멤버 역할의 이름입니다. |
| `description`  | 문자열         | 아니오       | 멤버 역할의 설명입니다. |
| `base_access_level` | 정수   | 예      | 구성된 역할의 기본 액세스 수준입니다. 유효한 값은 `10` (게스트), `15` (플래너), `20` (리포터), `25` (보안 관리자), `30` (개발자), `40` (유지 보수자) 또는 `50` (소유자)입니다.|
| `admin_cicd_variables` | 부울 | 아니오       | CI/CD 변수를 생성, 읽기, 업데이트 및 삭제할 수 있는 권한입니다. |
| `admin_compliance_framework` | 부울 | 아니오       | 규정 준수 프레임워크를 관리할 수 있는 권한입니다. |
| `admin_group_member` | 부울 | 아니오       | 그룹의 멤버를 추가, 제거 및 할당할 수 있는 권한입니다. |
| `admin_merge_request` | 부울 | 아니오       | 머지 리퀘스트를 승인할 수 있는 권한입니다. |
| `admin_push_rules` | 부울 | 아니오       | 그룹 또는 프로젝트 수준에서 리포지토리의 푸시 규칙을 구성할 수 있는 권한입니다. |
| `admin_terraform_state` | 부울 | 아니오       | 프로젝트 terraform 상태를 관리할 수 있는 권한입니다. |
| `admin_vulnerability` | 부울 | 아니오       | 상태 및 이슈 연결을 포함하여 취약성 객체를 편집할 수 있는 권한입니다. |
| `admin_web_hook` | 부울 | 아니오       | 웹후크를 관리할 수 있는 권한입니다. |
| `archive_project` | 부울 | 아니오       | 프로젝트를 보관할 수 있는 권한입니다. |
| `manage_deploy_tokens` | 부울 | 아니오       | 배포 토큰을 관리할 수 있는 권한입니다. |
| `manage_group_access_tokens` | 부울 | 아니오       | 그룹 액세스 토큰을 관리할 수 있는 권한입니다. |
| `manage_merge_request_settings` | 부울 | 아니오       | 머지 리퀘스트 설정을 구성할 수 있는 권한입니다. |
| `manage_project_access_tokens` | 부울 | 아니오       | 프로젝트 액세스 토큰을 관리할 수 있는 권한입니다. |
| `manage_security_policy_link` | 부울 | 아니오       | 보안 정책 프로젝트를 연결할 수 있는 권한입니다. |
| `read_code`           | 부울 | 아니오       | 프로젝트 코드를 읽을 수 있는 권한입니다. |
| `read_runners`     | 부울 | 아니오       | 프로젝트 러너를 볼 수 있는 권한입니다. |
| `read_dependency`     | 부울 | 아니오       | 프로젝트 종속성을 읽을 수 있는 권한입니다. |
| `read_vulnerability`  | 부울 | 아니오       | 프로젝트 취약성을 읽을 수 있는 권한입니다. |
| `remove_group` | 부울 | 아니오       | 그룹을 삭제하거나 복원할 수 있는 권한입니다. |
| `remove_project` | 부울 | 아니오       | 프로젝트를 삭제할 수 있는 권한입니다. |

사용 가능한 권한에 대한 자세한 내용은 [사용자 지정 권한](../user/custom_roles/abilities.md)을 참조하세요.

요청 예시:

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"name" : "Custom guest (instance)", "base_access_level" : 10, "read_code" : true}' \
  --url "https://gitlab.example.com/api/v4/member_roles"
```

응답 예시:

```json
{
  "id": 3,
  "name": "Custom guest (instance)",
  "group_id": null,
  "description": null,
  "base_access_level": 10,
  "admin_cicd_variables": false,
  "admin_compliance_framework": false,
  "admin_group_member": false,
  "admin_merge_request": false,
  "admin_push_rules": false,
  "admin_terraform_state": false,
  "admin_vulnerability": false,
  "admin_web_hook": false,
  "archive_project": false,
  "manage_deploy_tokens": false,
  "manage_group_access_tokens": false,
  "manage_merge_request_settings": false,
  "manage_project_access_tokens": false,
  "manage_security_policy_link": false,
  "read_code": true,
  "read_runners": false,
  "read_dependency": false,
  "read_vulnerability": false,
  "remove_group": false,
  "remove_project": false
}
```

### 인스턴스 멤버 역할 삭제 {#delete-an-instance-member-role}

인스턴스에서 멤버 역할을 삭제합니다.

```plaintext
DELETE /member_roles/:member_role_id
```

지원되는 특성:

| 특성 | 유형 | 필수 | 설명 |
|:----------|:--------|:---------|:-------------------------------------|
| `member_role_id` | 정수 | 예   | 멤버 역할의 ID입니다. |

성공하면 [`204`](rest/troubleshooting.md#status-codes) 및 빈 응답을 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/member_roles/1"
```

## 그룹 멤버 역할 관리 {#manage-group-member-roles}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

### 모든 그룹 멤버 역할 가져오기 {#get-all-group-member-roles}

```plaintext
GET /groups/:id/member_roles
```

지원되는 특성:

| 특성 | 유형 | 필수 | 설명 |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |

요청 예시:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

응답 예시:

```json
[
  {
    "id": 2,
    "name": "Guest + read code",
    "description": "Custom guest that can read code",
    "group_id": 84,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": false,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": false,
    "read_vulnerability": false,
    "remove_group": false,
    "remove_project": false
  },
  {
    "id": 3,
    "name": "Guest + security",
    "description": "Custom guest that can read and administer security entities",
    "group_id": 84,
    "base_access_level": 10,
    "admin_cicd_variables": false,
    "admin_compliance_framework": false,
    "admin_group_member": false,
    "admin_merge_request": false,
    "admin_push_rules": false,
    "admin_terraform_state": false,
    "admin_vulnerability": true,
    "admin_web_hook": false,
    "archive_project": false,
    "manage_deploy_tokens": false,
    "manage_group_access_tokens": false,
    "manage_merge_request_settings": false,
    "manage_project_access_tokens": false,
    "manage_security_policy_link": false,
    "read_code": true,
    "read_runners": false,
    "read_dependency": true,
    "read_vulnerability": true,
    "remove_group": false,
    "remove_project": false
  }
]
```

### 그룹에 멤버 역할 추가 {#add-a-member-role-to-a-group}

{{< history >}}

- 사용자 지정 역할을 생성할 때 이름 및 설명을 추가할 수 있는 기능 [GitLab 16.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126423)

{{< /history >}}

그룹에 멤버 역할을 추가합니다. 그룹의 루트 수준에서만 멤버 역할을 추가할 수 있습니다.

```plaintext
POST /groups/:id/member_roles
```

매개 변수:

| 특성 | 유형                | 필수 | 설명 |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | 정수 또는 문자열      | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `admin_cicd_variables` | 부울 | 아니오       | CI/CD 변수를 생성, 읽기, 업데이트 및 삭제할 수 있는 권한입니다. |
| `admin_compliance_framework` | 부울 | 아니오       | 규정 준수 프레임워크를 관리할 수 있는 권한입니다. |
| `admin_group_member` | 부울 | 아니오       | 그룹의 멤버를 추가, 제거 및 할당할 수 있는 권한입니다. |
| `admin_merge_request` | 부울 | 아니오       | 머지 리퀘스트를 승인할 수 있는 권한입니다. |
| `admin_push_rules` | 부울 | 아니오       | 그룹 또는 프로젝트 수준에서 리포지토리의 푸시 규칙을 구성할 수 있는 권한입니다. |
| `admin_terraform_state` | 부울 | 아니오       | 프로젝트 terraform 상태를 관리할 수 있는 권한입니다. |
| `admin_vulnerability` | 부울 | 아니오       | 프로젝트 취약성을 관리할 수 있는 권한입니다. |
| `admin_web_hook` | 부울 | 아니오       | 웹후크를 관리할 수 있는 권한입니다. |
| `archive_project` | 부울 | 아니오       | 프로젝트를 보관할 수 있는 권한입니다. |
| `manage_deploy_tokens` | 부울 | 아니오       | 배포 토큰을 관리할 수 있는 권한입니다. |
| `manage_group_access_tokens` | 부울 | 아니오       | 그룹 액세스 토큰을 관리할 수 있는 권한입니다. |
| `manage_merge_request_settings` | 부울 | 아니오       | 머지 리퀘스트 설정을 구성할 수 있는 권한입니다. |
| `manage_project_access_tokens` | 부울 | 아니오       | 프로젝트 액세스 토큰을 관리할 수 있는 권한입니다. |
| `manage_security_policy_link` | 부울 | 아니오       | 보안 정책 프로젝트를 연결할 수 있는 권한입니다. |
| `read_code`           | 부울 | 아니오       | 프로젝트 코드를 읽을 수 있는 권한입니다. |
| `read_runners`     | 부울 | 아니오       | 프로젝트 러너를 볼 수 있는 권한입니다. |
| `read_dependency`     | 부울 | 아니오       | 프로젝트 종속성을 읽을 수 있는 권한입니다. |
| `read_vulnerability`  | 부울 | 아니오       | 프로젝트 취약성을 읽을 수 있는 권한입니다. |
| `remove_group` | 부울 | 아니오       | 그룹을 삭제하거나 복원할 수 있는 권한입니다. |
| `remove_project` | 부울 | 아니오       | 프로젝트를 삭제할 수 있는 권한입니다. |

요청 예시:

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"name" : "Custom guest", "base_access_level" : 10, "read_code" : true}' \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles"
```

응답 예시:

```json
{
  "id": 3,
  "name": "Custom guest",
  "description": null,
  "group_id": 84,
  "base_access_level": 10,
  "admin_cicd_variables": false,
  "admin_compliance_framework": false,
  "admin_group_member": false,
  "admin_merge_request": false,
  "admin_push_rules": false,
  "admin_terraform_state": false,
  "admin_vulnerability": false,
  "admin_web_hook": false,
  "archive_project": false,
  "manage_deploy_tokens": false,
  "manage_group_access_tokens": false,
  "manage_merge_request_settings": false,
  "manage_project_access_tokens": false,
  "manage_security_policy_link": false,
  "read_code": true,
  "read_runners": false,
  "read_dependency": false,
  "read_vulnerability": false,
  "remove_group": false,
  "remove_project": false
}
```

GitLab 16.3 이상에서는 API를 사용하여 다음 작업을 수행할 수 있습니다:

- 사용자 지정 역할을 생성할 때 이름(필수) 및 설명(선택 사항)을 추가합니다 [.](../user/custom_roles/_index.md#create-a-custom-member-role)
- 기존 사용자 지정 역할의 이름 및 설명을 업데이트합니다.

### 그룹의 멤버 역할 제거 {#remove-member-role-of-a-group}

그룹의 멤버 역할을 삭제합니다.

```plaintext
DELETE /groups/:id/member_roles/:member_role_id
```

| 특성 | 유형 | 필수 | 설명 |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `member_role_id` | 정수 | 예   | 멤버 역할의 ID입니다. |

성공하면 [`204`](rest/troubleshooting.md#status-codes) 및 빈 응답을 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/84/member_roles/1"
```
