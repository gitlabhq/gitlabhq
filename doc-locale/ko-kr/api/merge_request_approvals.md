---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab에서 머지 리퀘스트 승인을 위한 REST API 설명서입니다.
title: 머지 리퀘스트 승인 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 엔드포인트 `/approvals` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) (GitLab 16.0)

{{< /history >}}

이 API를 사용하여 [머지 리퀘스트 승인](../user/project/merge_requests/approvals/_index.md)을 관리합니다.

모든 엔드포인트에는 인증이 필요합니다.

## 머지 리퀘스트 승인 {#approve-merge-request}

지정된 머지 리퀘스트를 승인합니다. 현재 인증된 사용자는 [적격 승인자](../user/project/merge_requests/approvals/rules.md#eligible-approvers)여야 합니다.

`sha` 매개변수는 머지 리퀘스트의 현재 버전을 승인하고 있음을 보장합니다. 정의된 경우 값은 머지 리퀘스트의 HEAD 커밋 SHA와 일치해야 합니다. 불일치하면 `409 Conflict` 응답이 반환됩니다. 이는 [머지 리퀘스트 수락](merge_requests.md#merge-a-merge-request) 동작과 일치합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approve
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approval_password` | 문자열            | 아니요       | 현재 사용자의 비밀번호입니다. 프로젝트 설정에서 [**Require user re-authentication to approve**](../user/project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve)가 활성화된 경우 필수입니다. 그룹 또는 GitLab Self-Managed 인스턴스가 SAML 인증을 강제하도록 구성된 경우 항상 실패합니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |
| `sha`               | 문자열            | 아니요       | 머지 리퀘스트의 `HEAD`입니다. |

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-09T21:32:14.105Z",
  "merge_status": "can_be_merged",
  "approvals_required": 2,
  "approvals_left": 0,
  "approved_by": [
    {
      "user": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/root"
      },
      "approved_at": "2016-06-10T04:21:41.050Z"
    },
    {
      "user": {
        "name": "Nico Cartwright",
        "username": "ryley",
        "id": 2,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/cf7ad14b34162a76d593e3affca2adca?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/ryley"
      },
      "approved_at": "2016-06-10T09:17:13.520Z"
    }
  ]
}
```

### 자동화된 머지 리퀘스트에서 승인 재설정 방지 {#prevent-approval-resets-in-automated-merge-requests}

API를 사용하여 머지 리퀘스트를 즉시 생성하고 승인하면 커밋이 완전히 처리되기 전에 자동화가 머지 리퀘스트를 승인할 수 있습니다. 기본적으로 머지 리퀘스트에 새 커밋을 추가하면 [기존 승인이 재설정](../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch)됩니다. 이 경우 머지 리퀘스트의 **활동** 영역에 다음과 같은 메시지 시퀀스가 표시됩니다:

- `(botname)`이(가) 5분 전에 이 머지 리퀘스트를 승인했습니다
- `(botname)`이(가) 5분 전에 1개의 커밋을 추가했습니다
- `(botname)`이(가) 5분 전에 브랜치로 푸시하여 `(botname)`의 승인을 재설정했습니다

자동화된 승인이 커밋 처리가 완료되기 전에 적용되지 않도록 하려면 자동화에 대기(또는 `sleep`) 함수를 추가해야 합니다:

- `detailed_merge_status` 특성이 `checking` 또는 `approvals_syncing` 상태가 아닙니다.
- 머지 리퀘스트 diff에 NULL이 아닌 `patch_id_sha`가 포함됩니다.

## 머지 리퀘스트 승인 취소 {#unapprove-a-merge-request}

지정된 머지 리퀘스트에서 현재 인증된 사용자의 승인을 제거합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unapprove
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

## 머지 리퀘스트의 승인 재설정 {#reset-approvals-for-a-merge-request}

지정된 머지 리퀘스트의 모든 승인을 재설정합니다.

유효한 프로젝트 또는 그룹 토큰이 있는 [봇 사용자](../user/project/settings/project_access_tokens.md#bot-users-for-projects)만 사용 가능합니다. 일반 사용자는 `401 Unauthorized` 응답을 받습니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/reset_approvals
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 내부 ID입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/reset_approvals"
```

## 프로젝트에 대한 승인 규칙 {#approval-rules-for-projects}

이러한 엔드포인트는 프로젝트 및 해당 승인 규칙에 적용됩니다. 모든 엔드포인트에는 인증이 필요합니다.

### 프로젝트에 대한 승인 구성 검색 {#retrieve-approval-configuration-for-a-project}

프로젝트에 대한 승인 구성을 검색합니다.

```plaintext
GET /projects/:id/approvals
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

```json
{
  "approvers": [], // Deprecated in GitLab 12.3, always returns empty
  "approver_groups": [], // Deprecated in GitLab 12.3, always returns empty
  "approvals_before_merge": 2, // Deprecated in GitLab 12.3, use Approval Rules instead
  "reset_approvals_on_push": true,
  "selective_code_owner_removals": false,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": true,
  "merge_requests_disable_committers_approval": false,
  "require_password_to_approve": true, // Deprecated in 16.9, use require_reauthentication_to_approve instead
  "require_reauthentication_to_approve": true
}
```

### 프로젝트에 대한 승인 구성 업데이트 {#update-approval-configuration-for-a-project}

프로젝트에 대한 승인 구성을 업데이트합니다. 현재 인증된 사용자는 [적격 승인자](../user/project/merge_requests/approvals/rules.md#eligible-approvers)여야 합니다.

```plaintext
POST /projects/:id/approvals
```

지원되는 속성:

| 속성                                        | 유형              | 필수 | 설명 |
|--------------------------------------------------|-------------------|----------|-------------|
| `id`                                             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approvals_before_merge` (더 이상 사용되지 않음)            | 정수           | 아니요       | 머지 리퀘스트를 병합하기 전에 필요한 승인의 수입니다. [GitLab 12.3에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/11132) 대신 [승인 규칙 생성](#create-an-approval-rule-for-a-project)합니다.  |
| `disable_overriding_approvers_per_merge_request` | 부울           | 아니요       | `true`이면 머지 리퀘스트에서 승인자의 재정의를 방지합니다. |
| `merge_requests_author_approval`                 | 부울           | 아니요       | `true`이면 저자는 자신의 머지 리퀘스트를 자체 승인할 수 있습니다. |
| `merge_requests_disable_committers_approval`     | 부울           | 아니요       | `true`이면 머지 리퀘스트에 커밋한 사용자는 이를 승인할 수 없습니다. |
| `require_password_to_approve` (더 이상 사용되지 않음)       | 부울           | 아니요       | `true`이면 승인자가 승인을 추가하기 전에 비밀번호로 인증해야 합니다. [GitLab 16.9에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/431346) `require_reauthentication_to_approve` 대신 사용합니다. |
| `require_reauthentication_to_approve`            | 부울           | 아니요       | `true`이면 승인자가 승인을 추가하기 전에 인증해야 합니다. [GitLab 17.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)됨. |
| `reset_approvals_on_push`                        | 부울           | 아니요       | `true`이면 푸시 시 승인이 재설정됩니다. |
| `selective_code_owner_removals`                  | 부울           | 아니요       | `true`이면 파일이 변경된 경우 코드 소유자의 승인을 재설정합니다. 이 필드를 사용하려면 `reset_approvals_on_push`가 `false`여야 합니다. |

```json
{
  "approvals_before_merge": 2, // Use Approval Rules instead
  "reset_approvals_on_push": true,
  "selective_code_owner_removals": false,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": false,
  "merge_requests_disable_committers_approval": false,
  "require_password_to_approve": true,
  "require_reauthentication_to_approve": true
}
```

### 프로젝트에 대한 모든 승인 규칙 나열 {#list-all-approval-rules-for-a-project}

지정된 프로젝트에 대한 모든 승인 규칙 및 관련 세부 정보를 나열합니다.

```plaintext
GET /projects/:id/approval_rules
```

승인 규칙 목록을 제한하려면 `page` 및 `per_page` [페이지 나누기](rest/_index.md#offset-based-pagination) 매개변수를 사용합니다.

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

응답 예시:

```json
[
  {
    "id": 1,
    "name": "security",
    "rule_type": "regular",
    "report_type": null,
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "applies_to_all_protected_branches": false,
    "protected_branches": [
      {
        "id": 1,
        "name": "main",
        "push_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "merge_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "unprotect_access_levels": [
          {
            "access_level": 40,
            "access_level_description": "Maintainers"
          }
        ],
        "code_owner_approval_required": "false"
      }
    ],
    "contains_hidden_groups": false,
  },
  {
    "id": 2,
    "name": "Coverage-Check",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "applies_to_all_protected_branches": false,
    "protected_branches": [
      {
        "id": 1,
        "name": "main",
        "push_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "merge_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "unprotect_access_levels": [
          {
            "access_level": 40,
            "access_level_description": "Maintainers"
          }
        ],
        "code_owner_approval_required": "false"
      }
    ],
    "contains_hidden_groups": false,
  }
]
```

응답의 각 객체에는 `eligible_approvers` 배열이 포함됩니다. 배열은 승인 규칙이 적용되는 머지 리퀘스트를 승인할 수 있는 사용자를 나열합니다. 적격 승인자는 규칙의 구성과 프로젝트 및 그룹 멤버십에 따라 다릅니다. 자세한 정보는 [적격 승인자](../user/project/merge_requests/approvals/rules.md#eligible-approvers)를 참조하세요.

### 프로젝트에 대한 승인 규칙 검색 {#retrieve-an-approval-rule-for-a-project}

프로젝트에 대한 지정된 승인 규칙에 대한 정보를 검색합니다.

```plaintext
GET /projects/:id/approval_rules/:approval_rule_id
```

지원되는 속성:

| 속성          | 유형              | 필수 | 설명 |
|--------------------|-------------------|----------|-------------|
| `id`               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approval_rule_id` | 정수           | 예      | 승인 규칙의 ID입니다. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "report_type": null,
  "eligible_approvers": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 3,
  "users": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### 프로젝트에 대한 승인 규칙 생성 {#create-an-approval-rule-for-a-project}

프로젝트에 대한 승인 규칙을 생성합니다.

`rule_type` 필드는 다음 규칙 유형을 지원합니다:

- `any_approver`:  `approvals_required`을 `0`으로 설정한 사전 구성된 기본 규칙입니다.
- `regular`:  일반 [머지 리퀘스트 승인 규칙](../user/project/merge_requests/approvals/rules.md)에 사용됩니다.
- `report_approver`:  GitLab이 구성되고 활성화된 [머지 리퀘스트 승인 정책](../user/application_security/policies/merge_request_approval_policies.md)에서 승인 규칙을 생성할 때 사용됩니다. 이 API를 사용하여 승인 규칙을 생성할 때 이 값을 사용하지 마세요.

```plaintext
POST /projects/:id/approval_rules
```

지원되는 속성:

| 속성                           | 유형              | 필수 | 설명 |
|-------------------------------------|-------------------|----------|-------------|
| `id`                                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approvals_required`                | 정수           | 예      | 이 규칙에 필요한 승인의 수입니다. |
| `name`                              | 문자열            | 예      | 승인 규칙의 이름입니다. 1024자로 제한됩니다. |
| `applies_to_all_protected_branches` | 부울           | 아니요       | `true`이면 규칙을 모든 보호된 브랜치에 적용하고 `protected_branch_ids` 특성을 무시합니다. |
| `group_ids`                         | 배열             | 아니요       | 승인자로 그룹의 ID입니다. |
| `protected_branch_ids`              | 배열             | 아니요       | 규칙 범위를 지정할 보호된 브랜치의 ID입니다. ID를 식별하려면 [보호된 브랜치 나열](protected_branches.md#list-protected-branches) API를 사용합니다. |
| `report_type`                       | 문자열            | 아니요       | 보고서 유형입니다. 규칙 유형이 `report_approver`일 때 필수입니다. 지원되는 보고서 유형은 `license_scanning` [(GitLab 15.9에서 더 이상 사용되지 않음)](../update/deprecations.md#license-check-and-the-policies-tab-on-the-license-compliance-page) 및 `code_coverage`입니다.   |
| `rule_type`                         | 문자열            | 아니요       | 규칙 유형입니다. 지원되는 값은 `any_approver`, `regular` 및 `report_approver`을 포함합니다. |
| `user_ids`                          | 배열             | 아니요       | 승인자로 사용자의 ID입니다. `usernames`과 함께 사용하면 두 사용자 목록을 모두 추가합니다. |
| `usernames`                         | 문자열 배열      | 아니요       | 승인자의 사용자 이름입니다. `user_ids`과 함께 사용하면 두 사용자 목록을 모두 추가합니다. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

필수 승인자 수를 0에서 늘리려면:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"name": "Any name", "rule_type": "any_approver", "approvals_required": 2}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/approval_rules"
```

또 다른 예는 사용자별 규칙을 생성하는 것입니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"name": "Name of your rule", "approvals_required": 3, "user_ids": [123, 456, 789]}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/approval_rules"
```

### 프로젝트에 대한 승인 규칙 업데이트 {#update-an-approval-rule-for-a-project}

프로젝트에 대한 지정된 승인 규칙을 업데이트합니다. 이 엔드포인트는 `group_ids`, `user_ids` 또는 `usernames` 특성에서 정의되지 않은 승인자 및 그룹을 제거합니다.

사용자가 보기 권한이 없는 숨겨진 그룹(비공개 그룹)이 `users` 또는 `groups` 매개변수에 없으면 기본적으로 유지됩니다. 제거하려면 `remove_hidden_groups`을 `true`로 설정합니다. 이렇게 하면 사용자가 승인 규칙을 업데이트할 때 숨겨진 그룹이 의도하지 않게 제거되지 않습니다.

```plaintext
PUT /projects/:id/approval_rules/:approval_rule_id
```

지원되는 속성:

| 속성                           | 유형              | 필수 | 설명 |
|-------------------------------------|-------------------|----------|-------------|
| `approval_rule_id`                  | 정수           | 예      | 승인 규칙의 ID입니다. |
| `id`                                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `applies_to_all_protected_branches` | 부울           | 아니요       | `true`이면 규칙을 모든 보호된 브랜치에 적용하고 `protected_branch_ids` 특성을 무시합니다. |
| `approvals_required`                | 정수           | 아니요       | 이 규칙에 필요한 승인의 수입니다. |
| `group_ids`                         | 배열             | 아니요       | 승인자로 그룹의 ID입니다. |
| `name`                              | 문자열            | 아니요       | 승인 규칙의 이름입니다. 1024자로 제한됩니다. |
| `protected_branch_ids`              | 배열             | 아니요       | 규칙 범위를 지정할 보호된 브랜치의 ID입니다. ID를 식별하려면 [보호된 브랜치 나열](protected_branches.md#list-protected-branches) API를 사용합니다. |
| `remove_hidden_groups`              | 부울           | 아니요       | `true`이면 승인 규칙에서 숨겨진 그룹을 제거합니다. |
| `user_ids`                          | 배열             | 아니요       | 승인자로 사용자의 ID입니다. `usernames`과 함께 사용하면 두 사용자 목록을 모두 추가합니다. |
| `usernames`                         | 문자열 배열      | 아니요       | 승인자의 사용자 이름입니다. `user_ids`과 함께 사용하면 두 사용자 목록을 모두 추가합니다. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "applies_to_all_protected_branches": false,
  "protected_branches": [
    {
      "id": 1,
      "name": "main",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### 프로젝트에 대한 승인 규칙 삭제 {#delete-an-approval-rule-for-a-project}

지정된 프로젝트에 대한 승인 규칙을 삭제합니다.

```plaintext
DELETE /projects/:id/approval_rules/:approval_rule_id
```

지원되는 속성:

| 속성          | 유형              | 필수 | 설명 |
|--------------------|-------------------|----------|-------------|
| `id`               | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approval_rule_id` | 정수           | 예      | 승인 규칙의 ID입니다. |

## 머지 리퀘스트에 대한 승인 규칙 {#approval-rules-for-a-merge-request}

이러한 엔드포인트는 개별 머지 리퀘스트에 적용됩니다. 모든 엔드포인트에는 인증이 필요합니다.

### 머지 리퀘스트에 대한 승인 상태 검색 {#retrieve-approval-state-for-a-merge-request}

지정된 머지 리퀘스트에 대한 승인 상태를 검색합니다.

응답에서 `approved_by`은 해당 승인이 승인 규칙을 충족하는지 여부와 관계없이 머지 리퀘스트의 모든 승인자에 대한 정보를 포함합니다. 머지 리퀘스트의 승인 규칙에 대한 더 자세한 정보와 수신한 승인이 해당 규칙을 충족하는지 여부는 [`/approval_state` 엔드포인트](#retrieve-approval-details-for-a-merge-request)를 참조하세요.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approvals
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-08T21:20:42.470Z",
  "merge_status": "cannot_be_merged",
  "approvals_required": 2,
  "approvals_left": 1,
  "approved_by": [
    {
      "user": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/root"
      },
      "approved_at": "2016-06-09T01:45:21.720Z"
    }
  ]
}
```

### 머지 리퀘스트에 대한 승인 세부 정보 검색 {#retrieve-approval-details-for-a-merge-request}

지정된 머지 리퀘스트에 대한 승인 세부 정보를 검색합니다.

사용자가 머지 리퀘스트에 대한 승인 규칙을 수정한 경우 응답에 다음이 포함됩니다:

- `approval_rules_overwritten`:  `true`이면 기본 승인 규칙이 수정되었음을 나타냅니다.
- `approved`:  `true`이면 관련 승인 규칙이 승인되었음을 나타냅니다.
- `approved_by`:  정의된 경우 관련 승인 규칙을 승인한 사용자의 세부 정보를 나타냅니다. 승인 규칙과 일치하지 않는 사용자는 반환되지 않습니다. 모든 승인 사용자를 반환하려면 [`/approvals` 엔드포인트](#retrieve-approval-state-for-a-merge-request)를 참조하세요.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_state
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

```json
{
  "approval_rules_overwritten": true,
  "rules": [
    {
      "id": 1,
      "name": "Ruby",
      "rule_type": "regular",
      "eligible_approvers": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "approvals_required": 2,
      "users": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "groups": [],
      "contains_hidden_groups": false,
      "approved_by": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "source_rule": null,
      "approved": true,
      "overridden": false
    }
  ]
}
```

### 머지 리퀘스트에 대한 모든 승인 규칙 나열 {#list-all-approval-rules-for-a-merge-request}

지정된 머지 리퀘스트에 대한 모든 승인 규칙 및 관련 세부 정보를 나열합니다.

`page` 및 `per_page` [페이지 나누기](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 승인 규칙 목록을 제한합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

```json
[
  {
    "id": 1,
    "name": "security",
    "rule_type": "regular",
    "report_type": null,
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "source_rule": null,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "contains_hidden_groups": false,
    "overridden": false
  },
  {
    "id": 2,
    "name": "Coverage-Check",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "source_rule": null,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "contains_hidden_groups": false,
    "overridden": false
  }
]
```

### 특정 머지 리퀘스트에 대한 승인 규칙 검색 {#retrieve-an-approval-rule-for-a-specific-merge-request}

특정 머지 리퀘스트에 대한 승인 규칙에 대한 정보를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approval_rule_id`  | 정수           | 예      | 승인 규칙의 ID입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "report_type": null,
  "eligible_approvers": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 3,
  "source_rule": null,
  "users": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### 머지 리퀘스트에 대한 승인 규칙 생성 {#create-an-approval-rule-for-a-merge-request}

특정 머지 리퀘스트에 대한 승인 규칙을 생성합니다. `approval_project_rule_id`이 프로젝트에서 기존 승인 규칙의 ID로 설정된 경우 이 엔드포인트:

- 프로젝트의 규칙에서 `name`, `users` 및 `groups`의 값을 복사합니다.
- 지정한 `approvals_required` 값을 사용합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

지원되는 속성:

| 속성                  | 유형              | 필수               | 설명                                                                  |
|----------------------------|-------------------|------------------------|------------------------------------------------------------------------------|
| `id`                       | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approvals_required`       | 정수           | 예 | 이 규칙에 필요한 승인의 수입니다.                              |
| `merge_request_iid`        | 정수           | 예 | 머지 리퀘스트의 IID입니다.                                                |
| `name`                     | 문자열            | 예 | 승인 규칙의 이름입니다. 1024자로 제한됩니다.                                               |
| `approval_project_rule_id` | 정수           | 아니요 | 프로젝트의 승인 규칙의 ID입니다.                                     |
| `group_ids`                | 배열             | 아니요 | 승인자로 그룹의 ID입니다.                                              |
| `user_ids`                 | 배열             | 아니요 | 승인자로 사용자의 ID입니다. `usernames`과 함께 사용하면 두 사용자 목록을 모두 추가합니다. |
| `usernames`                | 문자열 배열      | 아니요 | 승인자의 사용자 이름입니다. `user_ids`과 함께 사용하면 두 사용자 목록을 모두 추가합니다. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "source_rule": null,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### 머지 리퀘스트에 대한 승인 규칙 업데이트 {#update-an-approval-rule-for-a-merge-request}

머지 리퀘스트에 대한 지정된 승인 규칙을 업데이트합니다. 이 엔드포인트는 `group_ids`, `user_ids` 또는 `usernames` 특성에 포함되지 않은 승인자 및 그룹을 제거합니다.

`report_approver` 또는 `code_owner` 규칙은 시스템에서 생성되며 편집할 수 없습니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

지원되는 속성:

| 속성              | 유형              | 필수 | 설명 |
|------------------------|-------------------|----------|-------------|
| `id`                   | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approval_rule_id`     | 정수           | 예      | 승인 규칙의 ID입니다. |
| `merge_request_iid`    | 정수           | 예      | 머지 리퀘스트의 IID입니다. |
| `approvals_required`   | 정수           | 아니요       | 이 규칙에 필요한 승인의 수입니다. |
| `group_ids`            | 배열             | 아니요       | 승인자로 그룹의 ID입니다. |
| `name`                 | 문자열            | 아니요       | 승인 규칙의 이름입니다. 1024자로 제한됩니다. |
| `remove_hidden_groups` | 부울           | 아니요       | `true`이면 숨겨진 그룹을 제거합니다. |
| `user_ids`             | 배열             | 아니요       | 승인자로 사용자의 ID입니다. `usernames`과 함께 사용하면 두 사용자 목록을 모두 추가합니다. |
| `usernames`            | 문자열 배열      | 아니요       | 승인자의 사용자 이름입니다. `user_ids`과 함께 사용하면 두 사용자 목록을 모두 추가합니다. |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "source_rule": null,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### 머지 리퀘스트에 대한 승인 규칙 삭제 {#delete-an-approval-rule-for-a-merge-request}

지정된 머지 리퀘스트에 대한 승인 규칙을 삭제합니다.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

`report_approver` 또는 `code_owner` 규칙은 시스템에서 생성되며 편집할 수 없습니다.

지원되는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `approval_rule_id`  | 정수           | 예      | 승인 규칙의 ID입니다. |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID입니다. |

## 그룹에 대한 승인 규칙 {#approval-rules-for-groups}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 16.7에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/428051) [기능 플래그](../administration/feature_flags/_index.md) `approval_group_rules`로 이름 지정됨 기본적으로 비활성화됨. 이 기능은 [실험](../policy/development_stages_support.md)입니다.

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서 기본적으로 이 기능은 사용할 수 없습니다. 사용 가능하게 하려면 관리자가 `approval_group_rules`의 [기능 플래그를 활성화](../administration/feature_flags/_index.md)할 수 있습니다. GitLab.com 및 GitLab Dedicated에서는 이 기능을 사용할 수 없습니다. 이 기능은 프로덕션 사용 준비가 되지 않았습니다.

그룹 승인 규칙은 그룹에 속하는 프로젝트의 모든 보호된 브랜치에 적용됩니다.

### 그룹에 대한 모든 승인 규칙 나열 {#list-all-approval-rules-for-a-group}

{{< history >}}

- GitLab 16.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/440638)됨.

{{< /history >}}

지정된 그룹에 대한 모든 승인 규칙 및 관련 세부 정보를 나열합니다. 그룹 관리자로 제한됩니다.

`page` 및 `per_page` [페이지 나누기](rest/_index.md#offset-based-pagination) 매개변수를 사용하여 승인 규칙 목록을 제한합니다.

```plaintext
GET /groups/:id/approval_rules
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules"
```

응답 예시:

```json
[
  {
    "id": 2,
    "name": "rule1",
    "rule_type": "any_approver",
    "report_type": null,
    "eligible_approvers": [],
    "approvals_required": 3,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  },
  {
    "id": 3,
    "name": "rule2",
    "rule_type": "code_owner",
    "report_type": null,
    "eligible_approvers": [],
    "approvals_required": 2,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  },
  {
    "id": 4,
    "name": "rule2",
    "rule_type": "report_approver",
    "report_type": "code_coverage",
    "eligible_approvers": [],
    "approvals_required": 2,
    "users": [],
    "groups": [],
    "contains_hidden_groups": false,
    "protected_branches": [],
    "applies_to_all_protected_branches": true
  }
]

```

### 그룹에 대한 승인 규칙 생성 {#create-an-approval-rule-for-a-group}

그룹에 대한 승인 규칙을 생성합니다. 그룹 관리자로 제한됩니다.

API에서 승인 규칙을 작성할 때 `rule_type` 필드를 사용하지 마세요. 이 필드는 다음 규칙 유형을 지원합니다:

- `any_approver`:  `approvals_required`을 `0`으로 설정한 사전 구성된 기본 규칙입니다.
- `regular`:  일반 [머지 리퀘스트 승인 규칙](../user/project/merge_requests/approvals/rules.md)에 사용됩니다.
- `report_approver`:  GitLab이 구성되고 활성화된 [머지 리퀘스트 승인 정책](../user/application_security/policies/merge_request_approval_policies.md)에서 승인 규칙을 생성할 때 사용됩니다.

```plaintext
POST /groups/:id/approval_rules
```

지원되는 속성:

| 속성            | 유형              | 필수 | 설명 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `approvals_required` | 정수           | 예      | 이 규칙에 필요한 승인의 수입니다. |
| `name`               | 문자열            | 예      | 승인 규칙의 이름입니다. 1024자로 제한됩니다. |
| `group_ids`          | 배열             | 아니요       | 승인자로 그룹의 ID입니다. |
| `rule_type`          | 문자열            | 아니요       | 규칙 유형입니다. 지원되는 값은 `any_approver`, `regular` 및 `report_approver`을 포함합니다. |
| `user_ids`           | 배열             | 아니요       | 승인자로 사용자의 ID입니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules?name=security&approvals_required=2"
```

응답 예시:

```json
{
  "id": 5,
  "name": "security",
  "rule_type": "any_approver",
  "eligible_approvers": [],
  "approvals_required": 2,
  "users": [],
  "groups": [],
  "contains_hidden_groups": false,
  "protected_branches": [
    {
      "id": 5,
      "name": "master",
      "push_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "deploy_key_id": null,
          "user_id": null,
          "group_id": null
        }
      ],
      "merge_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "user_id": null,
          "group_id": null
        }
      ],
      "allow_force_push": false,
      "unprotect_access_levels": [],
      "code_owner_approval_required": false,
      "inherited": false
    }
  ],
  "applies_to_all_protected_branches": true
}
```

### 그룹에 대한 승인 규칙 업데이트 {#update-an-approval-rule-for-a-group}

{{< history >}}

- GitLab 16.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/440639)됨.

{{< /history >}}

그룹에 대한 승인 규칙을 업데이트합니다. 그룹 관리자로 제한됩니다.

API에서 승인 규칙을 작성할 때 `rule_type` 필드를 사용하지 마세요. 이 필드는 다음 규칙 유형을 지원합니다:

- `any_approver`:  `approvals_required`을 `0`으로 설정한 사전 구성된 기본 규칙입니다.
- `regular`:  일반 [머지 리퀘스트 승인 규칙](../user/project/merge_requests/approvals/rules.md)에 사용됩니다.
- `report_approver`:  GitLab이 구성되고 활성화된 [머지 리퀘스트 승인 정책](../user/application_security/policies/merge_request_approval_policies.md)에서 승인 규칙을 생성할 때 사용됩니다.

```shell
PUT /groups/:id/approval_rules/:approval_rule_id
```

지원되는 속성:

| 속성            | 유형              | 필수 | 설명 |
|----------------------|-------------------|----------|-------------|
| `approval_rule_id`   | 정수           | 예      | 승인 규칙의 ID입니다. |
| `id`                 | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `approvals_required` | 문자열            | 아니요       | 이 규칙에 필요한 승인의 수입니다. |
| `group_ids`          | 정수           | 아니요       | 승인자로 사용자의 ID입니다. |
| `name`               | 문자열            | 아니요       | 승인 규칙의 이름입니다. 1024자로 제한됩니다. |
| `rule_type`          | 배열             | 아니요       | 규칙 유형입니다. 지원되는 값은 `any_approver`, `regular` 및 `report_approver`을 포함합니다. |
| `user_ids`           | 배열             | 아니요       | 승인자로 그룹의 ID입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/29/approval_rules/5?name=security2&approvals_required=1"
```

응답 예시:

```json
{
  "id": 5,
  "name": "security2",
  "rule_type": "any_approver",
  "eligible_approvers": [],
  "approvals_required": 1,
  "users": [],
  "groups": [],
  "contains_hidden_groups": false,
  "protected_branches": [
    {
      "id": 5,
      "name": "master",
      "push_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "deploy_key_id": null,
          "user_id": null,
          "group_id": null
        }
      ],
      "merge_access_levels": [
        {
          "id": 5,
          "access_level": 40,
          "access_level_description": "Maintainers",
          "user_id": null,
          "group_id": null
        }
      ],
      "allow_force_push": false,
      "unprotect_access_levels": [],
      "code_owner_approval_required": false,
      "inherited": false
    }
  ],
  "applies_to_all_protected_branches": true
}
```
