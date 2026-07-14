---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 머지 리퀘스트 승인 설정을 위한 REST API 설명서입니다.
title: 머지 리퀘스트 승인 설정 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 그룹 및 프로젝트 [머지 리퀘스트 승인 설정](../user/project/merge_requests/approvals/settings.md)을 관리합니다. 모든 엔드포인트는 인증이 필요합니다.

## 그룹 MR 승인 설정 {#group-mr-approval-settings}

전제 조건:

- 그룹에서 Owner 역할이 있어야 합니다.

### 그룹의 MR 승인 설정 검색 {#retrieve-mr-approval-settings-for-a-group}

지정된 그룹의 머지 리퀘스트 승인 설정을 검색합니다.

```plaintext
GET /groups/:id/merge_request_approval_setting
```

매개변수:

| 속성        | 유형           | 필수 | 설명 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/merge_request_approval_setting"
```

응답 예시:

```json
{
  "allow_author_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

### 그룹 MR 승인 설정 업데이트 {#update-group-mr-approval-settings}

그룹의 머지 리퀘스트 승인 설정을 업데이트합니다.

```plaintext
PUT /groups/:id/merge_request_approval_setting
```

매개변수:

| 속성                                            | 유형              | 필수 | 설명 |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `allow_author_approval`                              | 부울           | 아니요       | 작성자가 머지 리퀘스트를 자체 승인할 수 있도록 허용하거나 방지합니다. `true`는 작성자가 자체 승인할 수 있음을 의미합니다. |
| `allow_committer_approval`                           | 부울           | 아니요       | 커밋터가 머지 리퀘스트를 자체 승인하도록 허용하거나 방지합니다. |
| `allow_overrides_to_approver_list_per_merge_request` | 부울           | 아니요       | 머지 리퀘스트당 승인자를 재정의하도록 허용하거나 방지합니다. |
| `retain_approvals_on_push`                           | 부울           | 아니요       | 새로운 푸시에서 승인 횟수를 유지합니다. |
| `require_reauthentication_to_approve`                | 부울           | 아니요       | 승인을 추가하기 전에 승인자가 인증하도록 요구합니다. [GitLab 17.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/merge_request_approval_setting?allow_author_approval=false"
```

응답 예시:

```json
{
  "allow_author_approval": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

## 프로젝트 MR 승인 설정 {#project-mr-approval-settings}

전제 조건:

- 프로젝트에서 Maintainer 역할이 있어야 합니다.

### 프로젝트의 MR 승인 설정 검색 {#retrieve-mr-approval-settings-for-a-project}

지정된 프로젝트의 머지 리퀘스트 승인 설정을 검색합니다.

```plaintext
GET /projects/:id/merge_request_approval_setting
```

매개변수:

| 속성        | 유형           | 필수 | 설명 |
|:-----------------|:---------------|:---------|:------------|
| `id`             | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/merge_request_approval_setting"
```

응답 예시:

```json
{
  "allow_author_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": true,
    "inherited_from": "group"
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

### 프로젝트 MR 승인 설정 업데이트 {#update-project-mr-approval-settings}

프로젝트의 머지 리퀘스트 승인 설정을 업데이트합니다.

```plaintext
PUT /projects/:id/merge_request_approval_setting
```

매개변수:

| 속성                                            | 유형              | 필수 | 설명 |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `allow_author_approval`                              | 부울           | 아니요       | 작성자가 머지 리퀘스트를 자체 승인할 수 있도록 허용하거나 방지합니다. `true`는 작성자가 자체 승인할 수 있음을 의미합니다. |
| `allow_committer_approval`                           | 부울           | 아니요       | 커밋터가 머지 리퀘스트를 자체 승인하도록 허용하거나 방지합니다. |
| `allow_overrides_to_approver_list_per_merge_request` | 부울           | 아니요       | 머지 리퀘스트당 승인자를 재정의하도록 허용하거나 방지합니다. |
| `retain_approvals_on_push`                           | 부울           | 아니요       | 새로운 푸시에서 승인 횟수를 유지합니다. |
| `selective_code_owner_removals`                      | 부울           | 아니요       | 파일이 변경된 경우 코드 소유자로부터 승인을 초기화합니다. 이 필드를 사용하려면 `retain_approvals_on_push` 필드를 비활성화해야 합니다. |
| `require_reauthentication_to_approve`                | 부울           | 아니요       | 승인을 추가하기 전에 승인자가 인증하도록 요구합니다. [GitLab 17.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/431346)입니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/merge_request_approval_setting?allow_author_approval=false"
```

응답 예시:

```json
{
  "allow_author_approval": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```
