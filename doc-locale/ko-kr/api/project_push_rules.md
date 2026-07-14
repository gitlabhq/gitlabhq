---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 푸시 규칙 API
description: "프로젝트 푸시 규칙을 관리하여 커밋 표준을 적용하고, 메시지의 유효성을 검사하며, 비밀을 방지하고, 리포지토리 작업을 제어합니다."
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 프로젝트 [푸시 규칙](../user/project/repository/push_rules.md)을 관리합니다.

> [!note]
> GitLab은 푸시 규칙의 모든 정규식에 [RE2 구문](https://github.com/google/re2/wiki/Syntax)을 사용합니다.

## 프로젝트의 푸시 규칙 검색 {#retrieve-the-push-rules-of-a-project}

지정된 프로젝트의 푸시 규칙을 검색합니다.

```plaintext
GET /projects/:id/push_rule
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 반환합니다:

| 속성                       | 유형    | 설명 |
|---------------------------------|---------|-------------|
| `author_email_regex`            | 문자열  | 모든 커밋 작성자 이메일이 이 정규식과 일치해야 합니다. |
| `branch_name_regex`             | 문자열  | 모든 브랜치 이름이 이 정규식과 일치해야 합니다. |
| `commit_committer_check`        | 부울 | `true`인 경우, 사용자는 커밋 작성자 이메일이 자신의 확인된 이메일 중 하나일 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_committer_name_check`   | 부울 | `true`인 경우, 사용자는 커밋 작성자 이름이 GitLab 계정 이름과 일치할 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_message_negative_regex` | 문자열  | 이 정규식과 일치하는 커밋 메시지는 허용되지 않습니다. |
| `commit_message_regex`          | 문자열  | 모든 커밋 메시지가 이 정규식과 일치해야 합니다. |
| `created_at`                    | 문자열  | 푸시 규칙이 생성된 날짜 및 시간입니다. |
| `deny_delete_tag`               | 부울 | `true`인 경우, 태그 삭제를 거부합니다. |
| `file_name_regex`               | 문자열  | 커밋된 모든 파일 이름이 이 정규식과 일치하지 않아야 합니다. |
| `id`                            | 정수 | 푸시 규칙의 ID입니다. |
| `max_file_size`                 | 정수 | 최대 파일 크기(MB)입니다. |
| `member_check`                  | 부울 | `true`인 경우, 커밋을 기존 GitLab 사용자로 제한합니다. |
| `prevent_secrets`               | 부울 | `true`인 경우, GitLab은 비밀을 포함할 가능성이 있는 모든 파일을 거부합니다. |
| `project_id`                    | 정수 | 프로젝트의 ID입니다. |
| `reject_non_dco_commits`        | 부울 | `true`인 경우, DCO 인증되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`       | 부울 | `true`인 경우, 서명되지 않은 커밋을 거부합니다. |

프로젝트에 대해 푸시 규칙이 구성되지 않은 경우, HTTP `200 OK`을 반환하고 응답 본문으로 리터럴 문자열 `"null"`을 반환합니다.

> [!note]
> 이는 [그룹 푸시 규칙 API](group_push_rules.md#retrieve-the-push-rules-of-a-group)와 다르며, `404 Not Found` 오류를 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```

모든 설정이 비활성화된 상태로 푸시 규칙이 구성될 때의 응답 예제:

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "ssh\\:\\/\\/",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": null,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": null,
  "reject_non_dco_commits": null
}
```

다음 속성이 비활성화되면 `null` 대신 `false`을 반환합니다:

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

프로젝트에 대해 푸시 규칙이 구성되지 않았을 때의 응답 예제:

```plaintext
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 4

null
```

이것은 리터럴 문자열 `"null"`(4자)을 반환하며, JSON `null` 값은 반환하지 않습니다.

## 프로젝트에 푸시 규칙 추가 {#add-push-rules-to-a-project}

지정된 프로젝트에 푸시 규칙을 추가합니다.

```plaintext
POST /projects/:id/push_rule
```

지원되는 속성:

| 속성                       | 유형              | 필수 | 설명 |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `author_email_regex`            | 문자열            | 아니요       | 모든 커밋 작성자 이메일이 이 정규식과 일치해야 합니다. |
| `branch_name_regex`             | 문자열            | 아니요       | 모든 브랜치 이름이 이 정규식과 일치해야 합니다. |
| `commit_committer_check`        | 부울           | 아니요       | `true`인 경우, 사용자는 커밋 작성자 이메일이 자신의 확인된 이메일 중 하나일 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_committer_name_check`   | 부울           | 아니요       | `true`인 경우, 사용자는 커밋 작성자 이름이 GitLab 계정 이름과 일치할 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_message_negative_regex` | 문자열            | 아니요       | 이 정규식과 일치하는 커밋 메시지는 허용되지 않습니다. |
| `commit_message_regex`          | 문자열            | 아니요       | 모든 커밋 메시지가 이 정규식과 일치해야 합니다. |
| `deny_delete_tag`               | 부울           | 아니요       | `true`인 경우, 태그 삭제를 거부합니다. |
| `file_name_regex`               | 문자열            | 아니요       | 커밋된 모든 파일 이름이 이 정규식과 일치하지 않아야 합니다. |
| `max_file_size`                 | 정수           | 아니요       | 최대 파일 크기(MB)입니다. |
| `member_check`                  | 부울           | 아니요       | `true`인 경우, 커밋을 기존 GitLab 사용자로 제한합니다. |
| `prevent_secrets`               | 부울           | 아니요       | `true`인 경우, GitLab은 비밀을 포함할 가능성이 있는 모든 파일을 거부합니다. |
| `reject_non_dco_commits`        | 부울           | 아니요       | `true`인 경우, DCO 인증되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`       | 부울           | 아니요       | `true`인 경우, 서명되지 않은 커밋을 거부합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 반환합니다:

| 속성                       | 유형    | 설명 |
|---------------------------------|---------|-------------|
| `author_email_regex`            | 문자열  | 모든 커밋 작성자 이메일이 이 정규식과 일치해야 합니다. |
| `branch_name_regex`             | 문자열  | 모든 브랜치 이름이 이 정규식과 일치해야 합니다. |
| `commit_committer_check`        | 부울 | `true`인 경우, 사용자는 커밋 작성자 이메일이 자신의 확인된 이메일 중 하나일 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_committer_name_check`   | 부울 | `true`인 경우, 사용자는 커밋 작성자 이름이 GitLab 계정 이름과 일치할 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_message_negative_regex` | 문자열  | 이 정규식과 일치하는 커밋 메시지는 허용되지 않습니다. |
| `commit_message_regex`          | 문자열  | 모든 커밋 메시지가 이 정규식과 일치해야 합니다. |
| `created_at`                    | 문자열  | 푸시 규칙이 생성된 날짜 및 시간입니다. |
| `deny_delete_tag`               | 부울 | `true`인 경우, 태그 삭제를 거부합니다. |
| `file_name_regex`               | 문자열  | 커밋된 모든 파일 이름이 이 정규식과 일치하지 않아야 합니다. |
| `id`                            | 정수 | 푸시 규칙의 ID입니다. |
| `max_file_size`                 | 정수 | 최대 파일 크기(MB)입니다. |
| `member_check`                  | 부울 | `true`인 경우, 커밋을 기존 GitLab 사용자로 제한합니다. |
| `prevent_secrets`               | 부울 | `true`인 경우, GitLab은 비밀을 포함할 가능성이 있는 모든 파일을 거부합니다. |
| `project_id`                    | 정수 | 프로젝트의 ID입니다. |
| `reject_non_dco_commits`        | 부울 | `true`인 경우, DCO 인증되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`       | 부울 | `true`인 경우, 서명되지 않은 커밋을 거부합니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule" \
  --data "commit_message_regex=Fixes \\d+\\..*" \
  --data "deny_delete_tag=false"
```

응답 예시:

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## 프로젝트의 푸시 규칙 업데이트 {#update-push-rules-of-a-project}

지정된 프로젝트의 푸시 규칙을 업데이트합니다.

```plaintext
PUT /projects/:id/push_rule
```

지원되는 속성:

| 속성                       | 유형              | 필수 | 설명 |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `author_email_regex`            | 문자열            | 아니요       | 모든 커밋 작성자 이메일이 이 정규식과 일치해야 합니다. |
| `branch_name_regex`             | 문자열            | 아니요       | 모든 브랜치 이름이 이 정규식과 일치해야 합니다. |
| `commit_committer_check`        | 부울           | 아니요       | `true`인 경우, 사용자는 커밋 작성자 이메일이 자신의 확인된 이메일 중 하나일 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_committer_name_check`   | 부울           | 아니요       | `true`인 경우, 사용자는 커밋 작성자 이름이 GitLab 계정 이름과 일치할 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_message_negative_regex` | 문자열            | 아니요       | 이 정규식과 일치하는 커밋 메시지는 허용되지 않습니다. |
| `commit_message_regex`          | 문자열            | 아니요       | 모든 커밋 메시지가 이 정규식과 일치해야 합니다. |
| `deny_delete_tag`               | 부울           | 아니요       | `true`인 경우, 태그 삭제를 거부합니다. |
| `file_name_regex`               | 문자열            | 아니요       | 커밋된 모든 파일 이름이 이 정규식과 일치하지 않아야 합니다. |
| `max_file_size`                 | 정수           | 아니요       | 최대 파일 크기(MB)입니다. |
| `member_check`                  | 부울           | 아니요       | `true`인 경우, 커밋을 기존 GitLab 사용자로 제한합니다. |
| `prevent_secrets`               | 부울           | 아니요       | `true`인 경우, GitLab은 비밀을 포함할 가능성이 있는 모든 파일을 거부합니다. |
| `reject_non_dco_commits`        | 부울           | 아니요       | `true`인 경우, DCO 인증되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`       | 부울           | 아니요       | `true`인 경우, 서명되지 않은 커밋을 거부합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성을 반환합니다:

| 속성                       | 유형    | 설명 |
|---------------------------------|---------|-------------|
| `author_email_regex`            | 문자열  | 모든 커밋 작성자 이메일이 이 정규식과 일치해야 합니다. |
| `branch_name_regex`             | 문자열  | 모든 브랜치 이름이 이 정규식과 일치해야 합니다. |
| `commit_committer_check`        | 부울 | `true`인 경우, 사용자는 커밋 작성자 이메일이 자신의 확인된 이메일 중 하나일 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_committer_name_check`   | 부울 | `true`인 경우, 사용자는 커밋 작성자 이름이 GitLab 계정 이름과 일치할 때만 이 리포지토리에 커밋을 푸시할 수 있습니다. |
| `commit_message_negative_regex` | 문자열  | 이 정규식과 일치하는 커밋 메시지는 허용되지 않습니다. |
| `commit_message_regex`          | 문자열  | 모든 커밋 메시지가 이 정규식과 일치해야 합니다. |
| `created_at`                    | 문자열  | 푸시 규칙이 생성된 날짜 및 시간입니다. |
| `deny_delete_tag`               | 부울 | `true`인 경우, 태그 삭제를 거부합니다. |
| `file_name_regex`               | 문자열  | 커밋된 모든 파일 이름이 이 정규식과 일치하지 않아야 합니다. |
| `id`                            | 정수 | 푸시 규칙의 ID입니다. |
| `max_file_size`                 | 정수 | 최대 파일 크기(MB)입니다. |
| `member_check`                  | 부울 | `true`인 경우, 커밋을 기존 GitLab 사용자로 제한합니다. |
| `prevent_secrets`               | 부울 | `true`인 경우, GitLab은 비밀을 포함할 가능성이 있는 모든 파일을 거부합니다. |
| `project_id`                    | 정수 | 프로젝트의 ID입니다. |
| `reject_non_dco_commits`        | 부울 | `true`인 경우, DCO 인증되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`       | 부울 | `true`인 경우, 서명되지 않은 커밋을 거부합니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule" \
  --data "commit_message_regex=Fixes \\d+\\..*" \
  --data "deny_delete_tag=true"
```

응답 예시:

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "",
  "branch_name_regex": "",
  "deny_delete_tag": true,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## 프로젝트의 푸시 규칙 삭제 {#delete-the-push-rules-of-a-project}

지정된 프로젝트의 모든 푸시 규칙을 삭제합니다.

```plaintext
DELETE /projects/:id/push_rule
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)을 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```
