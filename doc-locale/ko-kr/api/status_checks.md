---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 외부 상태 확인을 위한 REST API에 대한 설명서입니다.
title: 외부 상태 확인 API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [외부 상태 확인](../user/project/merge_requests/status_checks.md)을(를) 관리합니다.

## 프로젝트 외부 상태 확인 서비스 검색 {#retrieve-project-external-status-check-services}

다음 엔드포인트를 사용하여 프로젝트의 외부 상태 확인 서비스에 대한 정보를 검색합니다:

```plaintext
GET /projects/:id/external_status_checks
```

**파라매터**:

| 특성           | 유형    | 필수 | 설명         |
|---------------------|---------|----------|---------------------|
| `id`                | 정수 | 예      | 프로젝트의 ID     |

```json
[
  {
    "id": 1,
    "name": "Compliance Tool",
    "project_id": 6,
    "external_url": "https://gitlab.com/example/compliance-tool",
    "hmac": true,
    "protected_branches": [
      {
        "id": 14,
        "project_id": 6,
        "name": "main",
        "created_at": "2020-10-12T14:04:50.787Z",
        "updated_at": "2020-10-12T14:04:50.787Z",
        "code_owner_approval_required": false
      }
    ]
  }
]
```

## 외부 상태 확인 서비스 생성 {#create-external-status-check-service}

다음 엔드포인트를 사용하여 프로젝트를 위한 새로운 외부 상태 확인 서비스를 생성합니다:

```plaintext
POST /projects/:id/external_status_checks
```

> [!warning]
> 외부 상태 확인은 모든 해당 머지 리퀘스트에 대한 정보를 정의된 외부 서비스로 전송합니다. 여기에는 기밀 머지 리퀘스트가 포함됩니다.

| 특성              | 유형             | 필수 | 설명                                    |
|------------------------|------------------|----------|------------------------------------------------|
| `id`                   | 정수          | 예      | 프로젝트의 ID                                |
| `name`                 | 문자열           | 예      | 외부 상태 확인 서비스의 표시 이름  |
| `external_url`         | 문자열           | 예      | 외부 상태 확인 서비스의 URL           |
| `shared_secret`        | 문자열           | 아니오       | 외부 상태 확인을 위한 HMAC 암호          |
| `protected_branch_ids` | `array<Integer>` | 아니오       | 규칙의 범위를 정하기 위한 보호된 브랜치의 ID |

## 외부 상태 확인 서비스 업데이트 {#update-external-status-check-service}

다음 엔드포인트를 사용하여 프로젝트의 기존 외부 상태 확인을 업데이트합니다:

```plaintext
PUT /projects/:id/external_status_checks/:check_id
```

| 특성              | 유형             | 필수 | 설명                                    |
|------------------------|------------------|----------|------------------------------------------------|
| `id`                   | 정수          | 예      | 프로젝트의 ID                                |
| `check_id`             | 정수          | 예      | 외부 상태 확인 서비스의 ID         |
| `name`                 | 문자열           | 아니오       | 외부 상태 확인 서비스의 표시 이름  |
| `external_url`         | 문자열           | 아니오       | 외부 상태 확인 서비스의 URL           |
| `shared_secret`        | 문자열           | 아니오       | 외부 상태 확인을 위한 HMAC 암호          |
| `protected_branch_ids` | `array<Integer>` | 아니오       | 규칙의 범위를 정하기 위한 보호된 브랜치의 ID |

## 외부 상태 확인 서비스 삭제 {#delete-external-status-check-service}

다음 엔드포인트를 사용하여 프로젝트의 외부 상태 확인 서비스를 삭제합니다:

```plaintext
DELETE /projects/:id/external_status_checks/:check_id
```

| 특성              | 유형           | 필수 | 설명                            |
|------------------------|----------------|----------|----------------------------------------|
| `check_id`             | 정수        | 예      | 외부 상태 확인 서비스의 ID |
| `id`                   | 정수        | 예      | 프로젝트의 ID                        |

## 머지 리퀘스트에 대한 모든 상태 확인 나열 {#list-all-status-checks-for-a-merge-request}

단일 머지 리퀘스트에 적용되는 외부 상태 확인 서비스 및 해당 상태를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/status_checks
```

**파라매터**:

| 특성                | 유형    | 필수 | 설명                |
| ------------------------ | ------- | -------- | -------------------------- |
| `id`                     | 정수 | 예      | 프로젝트의 ID            |
| `merge_request_iid`      | 정수 | 예      | 머지 리퀘스트의 IID     |

```json
[
    {
        "id": 2,
        "name": "Service 1",
        "external_url": "https://gitlab.com/test-endpoint",
        "status": "passed"
    },
    {
        "id": 1,
        "name": "Service 2",
        "external_url": "https://gitlab.com/test-endpoint-2",
        "status": "pending"
    }
]
```

## 외부 상태 확인의 상태 설정 {#set-status-of-an-external-status-check}

{{< history >}}

- `failed` 및 `passed`에 대한 지원이 GitLab 15.0에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/353836)
- GitLab 16.5에서 `pending`에 대한 지원이 GitLab 16.5에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/413723)

{{< /history >}}

단일 머지 리퀘스트에 대한 외부 상태 확인의 상태를 설정하여 머지 리퀘스트가 외부 서비스에 의한 확인을 통과했음을 GitLab에 알립니다. 외부 확인의 상태를 설정하려면 사용된 개인 액세스 토큰이 머지 리퀘스트의 대상 프로젝트에서 Developer, Maintainer 또는 Owner 역할을 가진 사용자에게 속해야 합니다.

머지 리퀘스트 자체를 승인할 권리가 있는 모든 사용자로서 이 API 호출을 실행합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_check_responses
```

**파라매터**:

| 특성                  | 유형    | 필수 | 설명                                                                                       |
| -------------------------- | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                       | 정수 | 예      | 프로젝트의 ID                                                                                   |
| `merge_request_iid`        | 정수 | 예      | 머지 리퀘스트의 IID                                                                            |
| `sha`                      | 문자열  | 예      | `HEAD`의 소스 브랜치에서의 SHA                                                                |
| `external_status_check_id` | 정수 | 예      | 외부 상태 확인의 ID                                                                    |
| `status`                   | 문자열  | 아니오       | `pending`로 설정하여 확인을 보류 중으로 표시하거나, `passed`로 설정하여 확인을 통과하거나, `failed`로 설정하여 확인을 실패합니다 |

> [!note]
> `sha`는 머지 리퀘스트의 소스 브랜치의 `HEAD`에서의 SHA여야 합니다.

## 머지 리퀘스트에 대한 실패한 상태 확인 재시도 {#retry-failed-status-check-for-a-merge-request}

{{< history >}}

- GitLab 15.7에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/383200).

{{< /history >}}

단일 머지 리퀘스트에 대해 지정된 실패한 외부 상태 확인을 재시도합니다. 머지 리퀘스트가 변경되지 않았더라도 이 엔드포인트는 머지 리퀘스트의 현재 상태를 정의된 외부 서비스로 다시 전송합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_checks/:external_status_check_id/retry
```

**파라매터**:

| 특성                  | 유형    | 필수 | 설명                           |
| -------------------------- | ------- | -------- | ------------------------------------- |
| `id`                       | 정수 | 예      | 프로젝트의 ID                       |
| `merge_request_iid`        | 정수 | 예      | 머지 리퀘스트의 IID                |
| `external_status_check_id` | 정수 | 예      | 실패한 외부 상태 확인의 ID |

## 응답 {#response}

성공한 경우 상태 코드는 202입니다.

```json
{
    "message": "202 Accepted"
}
```

상태 확인이 이미 통과한 경우 상태 코드는 422입니다

```json
{
    "message": "External status check must be failed"
}
```

## 외부 서비스로 전송된 예제 페이로드 {#example-payload-sent-to-external-service}

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "email": "[REDACTED]"
  },
  "project": {
    "id": 6,
    "name": "Flight",
    "description": "Ipsa minima est consequuntur quisquam.",
    "web_url": "http://example.com/flightjs/Flight",
    "avatar_url": null,
    "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
    "git_http_url": "http://example.com/flightjs/Flight.git",
    "namespace": "Flightjs",
    "visibility_level": 20,
    "path_with_namespace": "flightjs/Flight",
    "default_branch": "main",
    "ci_config_path": null,
    "homepage": "http://example.com/flightjs/Flight",
    "url": "ssh://example.com/flightjs/Flight.git",
    "ssh_url": "ssh://example.com/flightjs/Flight.git",
    "http_url": "http://example.com/flightjs/Flight.git"
  },
  "object_attributes": {
    "assignee_id": null,
    "author_id": 1,
    "created_at": "2022-12-07 07:53:43 UTC",
    "description": "",
    "head_pipeline_id": 558,
    "id": 144,
    "iid": 4,
    "last_edited_at": null,
    "last_edited_by_id": null,
    "merge_commit_sha": null,
    "merge_error": null,
    "merge_params": {
      "force_remove_source_branch": "1"
    },
    "merge_status": "can_be_merged",
    "merge_user_id": null,
    "merge_when_pipeline_succeeds": false,
    "milestone_id": null,
    "source_branch": "root-main-patch-30152",
    "source_project_id": 6,
    "state_id": 1,
    "target_branch": "main",
    "target_project_id": 6,
    "time_estimate": 0,
    "title": "Update README.md",
    "updated_at": "2022-12-07 07:53:43 UTC",
    "updated_by_id": null,
    "url": "http://example.com/flightjs/Flight/-/merge_requests/4",
    "source": {
      "id": 6,
      "name": "Flight",
      "description": "Ipsa minima est consequuntur quisquam.",
      "web_url": "http://example.com/flightjs/Flight",
      "avatar_url": null,
      "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
      "git_http_url": "http://example.com/flightjs/Flight.git",
      "namespace": "Flightjs",
      "visibility_level": 20,
      "path_with_namespace": "flightjs/Flight",
      "default_branch": "main",
      "ci_config_path": null,
      "homepage": "http://example.com/flightjs/Flight",
      "url": "ssh://example.com/flightjs/Flight.git",
      "ssh_url": "ssh://example.com/flightjs/Flight.git",
      "http_url": "http://example.com/flightjs/Flight.git"
    },
    "target": {
      "id": 6,
      "name": "Flight",
      "description": "Ipsa minima est consequuntur quisquam.",
      "web_url": "http://example.com/flightjs/Flight",
      "avatar_url": null,
      "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
      "git_http_url": "http://example.com/flightjs/Flight.git",
      "namespace": "Flightjs",
      "visibility_level": 20,
      "path_with_namespace": "flightjs/Flight",
      "default_branch": "main",
      "ci_config_path": null,
      "homepage": "http://example.com/flightjs/Flight",
      "url": "ssh://example.com/flightjs/Flight.git",
      "ssh_url": "ssh://example.com/flightjs/Flight.git",
      "http_url": "http://example.com/flightjs/Flight.git"
    },
    "last_commit": {
      "id": "141be9714669a4c1ccaa013c6a7f3e462ff2a40f",
      "message": "Update README.md",
      "title": "Update README.md",
      "timestamp": "2022-12-07T07:52:11+00:00",
      "url": "http://example.com/flightjs/Flight/-/commit/141be9714669a4c1ccaa013c6a7f3e462ff2a40f",
      "author": {
        "name": "Administrator",
        "email": "admin@example.com"
      }
    },
    "work_in_progress": false,
    "total_time_spent": 0,
    "time_change": 0,
    "human_total_time_spent": null,
    "human_time_change": null,
    "human_time_estimate": null,
    "assignee_ids": [
    ],
    "reviewer_ids": [
    ],
    "labels": [
    ],
    "state": "opened",
    "blocking_discussions_resolved": true,
    "first_contribution": false,
    "detailed_merge_status": "mergeable"
  },
  "labels": [
  ],
  "changes": {
  },
  "repository": {
    "name": "Flight",
    "url": "ssh://example.com/flightjs/Flight.git",
    "description": "Ipsa minima est consequuntur quisquam.",
    "homepage": "http://example.com/flightjs/Flight"
  },
  "external_approval_rule": {
    "id": 1,
    "name": "QA",
    "external_url": "https://example.com/"
  }
}
```

## 관련 항목 {#related-topics}

- [외부 상태 확인](../user/project/merge_requests/status_checks.md)
