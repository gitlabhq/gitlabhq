---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 푸시 규칙을 사용하여 리포지토리에서 허용하는 Git 커밋의 내용과 형식을 제어합니다. 커밋 메시지의 표준을 설정하고 비밀 정보나 자격 증명이 실수로 추가되는 것을 차단합니다.
title: 그룹 푸시 규칙 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 그룹에서 새로 생성된 프로젝트를 위해 [그룹 푸시 규칙](../user/project/repository/push_rules.md#group-push-rules)을 관리합니다.

전제 조건:

- 그룹의 소유자 역할을 가지거나 인스턴스의 관리자여야 합니다.

## 그룹의 푸시 규칙 검색 {#retrieve-the-push-rules-of-a-group}

지정된 그룹의 푸시 규칙을 검색합니다.

```plaintext
GET /groups/:id/push_rule
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 표시합니다:

| 속성                         | 유형    | 설명 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 문자열  | 이 정규식과 일치하는 커밋 작성자 이메일만 허용합니다. |
| `branch_name_regex`               | 문자열  | 이 정규식과 일치하는 브랜치 이름만 허용합니다. |
| `commit_committer_check`          | 부울 | `true`이면 커밋터 이메일이 자신의 확인된 이메일 중 하나인 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_committer_name_check`     | 부울 | `true`이면 커밋 작성자 이름이 GitLab 계정 이름과 일치하는 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_message_negative_regex`   | 문자열  | 이 정규식과 일치하는 커밋 메시지를 거부합니다. |
| `commit_message_regex`            | 문자열  | 이 정규식과 일치하는 커밋 메시지만 허용합니다. |
| `created_at`                      | 문자열  | 푸시 규칙이 생성된 날짜 및 시간입니다. |
| `deny_delete_tag`                 | 부울 | `true`이면 태그 삭제를 거부합니다. |
| `file_name_regex`                 | 문자열  | 이 정규식과 일치하는 파일 이름을 거부합니다. |
| `id`                              | 정수 | 푸시 규칙의 ID입니다. |
| `max_file_size`                   | 정수 | 허용되는 최대 파일 크기(MB)입니다. |
| `member_check`                    | 부울 | `true`이면 GitLab 사용자만이 커밋을 작성할 수 있습니다. |
| `prevent_secrets`                 | 부울 | `true`이면 비밀 정보를 포함할 가능성이 있는 파일을 거부합니다. |
| `reject_non_dco_commits`          | 부울 | `true`이면 DCO 인증이 되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`         | 부울 | `true`이면 서명되지 않은 커밋을 거부합니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/push_rule"
```

모든 설정이 비활성화된 상태로 푸시 규칙이 구성될 때의 응답 예시:

```json
{
  "id": 1,
  "created_at": "2020-08-17T19:09:19.580Z",
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": "[a-z]",
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": "(exe)$",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "max_file_size": 0,
  "commit_committer_check": null,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": null,
  "reject_non_dco_commits": null
}
```

푸시 규칙이 그룹에 대해 구성되지 않은 경우 [`404 Not Found`](rest/troubleshooting.md#status-codes)를 반환합니다:

```json
{
  "message": "404 Not Found"
}
```

> [!note]
> 이는 푸시 규칙이 구성되지 않았을 때 HTTP `200 OK`와 문자 그대로 `"null"`를 반환하는 [프로젝트 푸시 규칙 API](project_push_rules.md#retrieve-the-push-rules-of-a-project)와 다릅니다.

비활성화되면 일부 부울 속성은 `false` 대신 `null`를 반환합니다. 예를 들어:

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

## 그룹에 푸시 규칙 추가 {#add-push-rules-to-a-group}

지정된 그룹에 푸시 규칙을 추가합니다. 지금까지 푸시 규칙을 정의하지 않은 경우에만 사용합니다.

```plaintext
POST /groups/:id/push_rule
```

지원되는 속성:

| 속성                         | 유형           | 필수 | 설명 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 정수 또는 문자열 | 예   | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `author_email_regex`              | 문자열         | 아니요       | 이 속성에 제공된 정규식과 일치하는 커밋 작성자 이메일만 허용합니다. 예를 들어 `@my-company.com$`입니다. |
| `branch_name_regex`               | 문자열         | 아니요       | 이 속성에 제공된 정규식과 일치하는 브랜치 이름만 허용합니다. 예를 들어 `(feature\|hotfix)\/.*`입니다. |
| `commit_committer_check`          | 부울        | 아니요       | `true`이면 커밋터 이메일이 자신의 확인된 이메일 중 하나인 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_committer_name_check`     | 부울        | 아니요       | `true`이면 커밋 작성자 이름이 GitLab 계정 이름과 일치하는 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_message_negative_regex`   | 문자열         | 아니요       | 이 속성에 제공된 정규식과 일치하는 커밋 메시지를 거부합니다. 예를 들어 `ssh\:\/\/`입니다. |
| `commit_message_regex`            | 문자열         | 아니요       | `true`이면 이 속성에 제공된 정규식과 일치하는 커밋 메시지만 허용합니다. 예를 들어 `Fixed \d+\..*`입니다. |
| `deny_delete_tag`                 | 부울        | 아니요       | 태그 삭제를 거부합니다. |
| `file_name_regex`                 | 문자열         | 아니요       | 이 속성에 제공된 정규식과 일치하는 파일 이름을 거부합니다. 예를 들어 `(jar\|exe)$`입니다. |
| `max_file_size`                   | 정수        | 아니요       | 허용되는 최대 파일 크기(MB)입니다. |
| `member_check`                    | 부울        | 아니요       | `true`이면 GitLab 사용자만이 커밋을 작성할 수 있습니다. |
| `prevent_secrets`                 | 부울        | 아니요       | `true`이면 [비밀 정보를 포함](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml)할 가능성이 있는 파일을 거부합니다. |
| `reject_non_dco_commits`          | 부울        | 아니요       | `true`이면 DCO 인증이 되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`         | 부울        | 아니요       | `true`이면 서명되지 않은 커밋을 거부합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 표시합니다:

| 속성                         | 유형    | 설명 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 문자열  | 이 정규식과 일치하는 커밋 작성자 이메일만 허용합니다. |
| `branch_name_regex`               | 문자열  | 이 정규식과 일치하는 브랜치 이름만 허용합니다. |
| `commit_committer_check`          | 부울 | `true`이면 커밋터 이메일이 자신의 확인된 이메일 중 하나인 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_committer_name_check`     | 부울 | `true`이면 커밋 작성자 이름이 GitLab 계정 이름과 일치하는 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_message_negative_regex`   | 문자열  | 이 정규식과 일치하는 커밋 메시지를 거부합니다. |
| `commit_message_regex`            | 문자열  | `true`이면 이 정규식과 일치하는 커밋 메시지만 허용합니다. |
| `created_at`                      | 문자열  | 푸시 규칙이 생성된 날짜 및 시간입니다. |
| `deny_delete_tag`                 | 부울 | `true`이면 태그 삭제를 거부합니다. |
| `file_name_regex`                 | 문자열  | 이 정규식과 일치하는 파일 이름을 거부합니다. |
| `id`                              | 정수 | 푸시 규칙의 ID입니다. |
| `max_file_size`                   | 정수 | 허용되는 최대 파일 크기(MB)입니다. |
| `member_check`                    | 부울 | `true`이면 GitLab 사용자만이 커밋을 작성할 수 있습니다. |
| `prevent_secrets`                 | 부울 | `true`이면 비밀 정보를 포함할 가능성이 있는 파일을 거부합니다. |
| `reject_non_dco_commits`          | 부울 | `true`이면 DCO 인증이 되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`         | 부울 | `true`이면 서명되지 않은 커밋을 거부합니다. |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule?prevent_secrets=true"
```

응답 예시:

```json
{
  "id": 1,
  "created_at": "2020-08-31T15:53:00.073Z",
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": null,
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": true,
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": null,
  "max_file_size": 100
}
```

## 그룹의 푸시 규칙 업데이트 {#update-push-rules-of-a-group}

지정된 그룹의 푸시 규칙을 업데이트합니다.

```plaintext
PUT /groups/:id/push_rule
```

지원되는 속성:

| 속성                         | 유형           | 필수 | 설명 |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | 정수 또는 문자열 | 예   | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `author_email_regex`              | 문자열         | 아니요       | 이 속성에 제공된 정규식과 일치하는 커밋 작성자 이메일만 허용합니다. 예를 들어 `@my-company.com$`입니다. |
| `branch_name_regex`               | 문자열         | 아니요       | 이 속성에 제공된 정규식과 일치하는 브랜치 이름만 허용합니다. 예를 들어 `(feature\|hotfix)\/.*`입니다. |
| `commit_committer_check`          | 부울        | 아니요       | `true`이면 커밋터 이메일이 자신의 확인된 이메일 중 하나인 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_committer_name_check`     | 부울        | 아니요       | `true`이면 커밋 작성자 이름이 GitLab 계정 이름과 일치하는 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_message_negative_regex`   | 문자열         | 아니요       | 이 속성에 제공된 정규식과 일치하는 커밋 메시지를 거부합니다. 예를 들어 `ssh\:\/\/`입니다. |
| `commit_message_regex`            | 문자열         | 아니요       | `true`이면 이 속성에 제공된 정규식과 일치하는 커밋 메시지만 허용합니다. 예를 들어 `Fixed \d+\..*`입니다. |
| `deny_delete_tag`                 | 부울        | 아니요       | `true`이면 태그 삭제를 거부합니다. |
| `file_name_regex`                 | 문자열         | 아니요       | 이 속성에 제공된 정규식과 일치하는 파일 이름을 거부합니다. 예를 들어 `(jar\|exe)$`입니다. |
| `max_file_size`                   | 정수        | 아니요       | 허용되는 최대 파일 크기(MB)입니다. |
| `member_check`                    | 부울        | 아니요       | `true`이면 GitLab 사용자만이 커밋을 작성할 수 있습니다. |
| `prevent_secrets`                 | 부울        | 아니요       | `true`이면 [비밀 정보를 포함](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml)할 가능성이 있는 파일을 거부합니다. |
| `reject_non_dco_commits`          | 부울        | 아니요       | `true`이면 DCO 인증이 되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`         | 부울        | 아니요       | `true`이면 서명되지 않은 커밋을 거부합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)를 반환하고 다음 응답 속성을 표시합니다:

| 속성                         | 유형    | 설명 |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | 문자열  | 이 정규식과 일치하는 커밋 작성자 이메일만 허용합니다. |
| `branch_name_regex`               | 문자열  | 이 정규식과 일치하는 브랜치 이름만 허용합니다. |
| `commit_committer_check`          | 부울 | `true`이면 커밋터 이메일이 자신의 확인된 이메일 중 하나인 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_committer_name_check`     | 부울 | `true`이면 커밋 작성자 이름이 GitLab 계정 이름과 일치하는 경우에만 사용자로부터의 커밋을 허용합니다. |
| `commit_message_negative_regex`   | 문자열  | 이 정규식과 일치하는 커밋 메시지를 거부합니다. |
| `commit_message_regex`            | 문자열  | `true`이면 이 정규식과 일치하는 커밋 메시지만 허용합니다. |
| `created_at`                      | 문자열  | 푸시 규칙이 생성된 날짜 및 시간입니다. |
| `deny_delete_tag`                 | 부울 | `true`이면 태그 삭제를 거부합니다. |
| `file_name_regex`                 | 문자열  | 이 정규식과 일치하는 파일 이름을 거부합니다. |
| `id`                              | 정수 | 푸시 규칙의 ID입니다. |
| `max_file_size`                   | 정수 | 허용되는 최대 파일 크기(MB)입니다. |
| `member_check`                    | 부울 | `true`이면 GitLab 사용자만이 커밋을 작성할 수 있습니다. |
| `prevent_secrets`                 | 부울 | `true`이면 비밀 정보를 포함할 가능성이 있는 파일을 거부합니다. |
| `reject_non_dco_commits`          | 부울 | `true`이면 DCO 인증이 되지 않은 커밋을 거부합니다. |
| `reject_unsigned_commits`         | 부울 | `true`이면 서명되지 않은 커밋을 거부합니다. |

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule?member_check=true"
```

응답 예시:

```json
{
  "id": 19,
  "created_at": "2020-08-31T15:53:00.073Z",
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": null,
  "deny_delete_tag": false,
  "member_check": true,
  "prevent_secrets": false,
  "author_email_regex": "^[A-Za-z0-9.]+@staging.gitlab.com$",
  "file_name_regex": null,
  "max_file_size": 100
}
```

## 그룹의 푸시 규칙 삭제 {#delete-the-push-rules-of-a-group}

지정된 그룹의 모든 푸시 규칙을 삭제합니다.

```plaintext
DELETE /groups/:id/push_rule
```

지원되는 속성:

| 속성 | 유형           | 필수 | 설명 |
|-----------|----------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)을 반환하고 응답 본문이 없습니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule"
```
