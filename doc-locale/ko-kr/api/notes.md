---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 메모 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab 콘텐츠에 첨부된 주석과 시스템 레코드를 관리합니다. 다음을 수행할 수 있습니다.

- 이슈, 머지 리퀘스트, 에픽, 스니펫 및 커밋에 대한 주석을 만들고 수정합니다.
- [시스템에서 생성된 메모](../user/project/system_notes.md)를 검색하여 객체 변경 사항을 확인합니다.
- 결과를 정렬하고 페이지를 나눕니다.
- 기밀 및 내부 플래그로 표시 여부를 제어합니다.
- 속도 제한을 사용하여 남용을 방지합니다.

일부 시스템에서 생성된 메모는 별도의 리소스 이벤트로 추적됩니다:

- [리소스 레이블 이벤트](resource_label_events.md)
- [리소스 상태 이벤트](resource_state_events.md)
- [리소스 마일스톤 이벤트](resource_milestone_events.md)
- [리소스 가중치 이벤트](resource_weight_events.md)
- [리소스 반복 이벤트](resource_iteration_events.md)

기본적으로 `GET` 요청은 API 결과가 페이지를 나누기 때문에 한 번에 20개의 결과를 반환합니다. 자세한 내용은 [페이지 나누기](rest/_index.md#pagination)를 참조하세요.

## 리소스 이벤트 {#resource-events}

일부 시스템 메모는 이 API의 일부가 아니지만 별도의 이벤트로 기록됩니다:

- [리소스 레이블 이벤트](resource_label_events.md)
- [리소스 상태 이벤트](resource_state_events.md)
- [리소스 마일스톤 이벤트](resource_milestone_events.md)
- [리소스 가중치 이벤트](resource_weight_events.md)
- [리소스 반복 이벤트](resource_iteration_events.md)

## 메모 페이지 나누기 {#notes-pagination}

기본적으로 `GET` 요청은 API 결과가 페이지를 나누기 때문에 한 번에 20개의 결과를 반환합니다.

[페이지 나누기](rest/_index.md#pagination)에서 자세히 알아보세요.

## 속도 제한 {#rate-limits}

남용을 방지하기 위해 사용자가 분당 특정 개수의 `Create` 요청을 수행하도록 제한할 수 있습니다. 자세한 내용은 [메모 생성의 속도 제한](../administration/settings/rate_limit_on_notes_creation.md)을 참조하세요.

## 이슈 {#issues}

### 모든 이슈 메모 나열 {#list-all-issue-notes}

지정된 이슈의 모든 메모를 나열합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/notes
GET /projects/:id/issues/:issue_iid/notes?sort=asc&order_by=updated_at
GET /projects/:id/issues/:issue_iid/notes?activity_filter=only_comments
```

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid` | 정수           | 예      | 이슈의 IID |
| `activity_filter` | 문자열      | 아니오       | 활동 유형별로 메모를 필터링합니다. 유효한 값: `all_notes`, `only_comments`, `only_activity`입니다. 기본값은 `all_notes`입니다. |
| `sort`      | 문자열            | 아니오       | 이슈 메모를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `order_by`  | 문자열            | 아니오       | 이슈 메모를 `created_at` 또는 `updated_at` 필드로 정렬하여 반환합니다. 기본값은 `created_at`입니다. |

```json
[
  {
    "id": 302,
    "body": "closed",
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:22:45Z",
    "updated_at": "2013-10-02T10:22:45Z",
    "system": true,
    "noteable_id": 377,
    "noteable_type": "Issue",
    "project_id": 5,
    "noteable_iid": 377,
    "resolvable": false,
    "confidential": false,
    "internal": false,
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 305,
    "body": "Text of the comment\r\n",
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:56:03Z",
    "updated_at": "2013-10-02T09:56:03Z",
    "system": true,
    "noteable_id": 121,
    "noteable_type": "Issue",
    "project_id": 5,
    "noteable_iid": 121,
    "resolvable": false,
    "confidential": true,
    "internal": true,
    "imported": false,
    "imported_from": "none"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes"
```

### 이슈 메모 검색 {#retrieve-an-issue-note}

프로젝트 이슈의 지정된 메모를 검색합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id
```

매개 변수:

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid` | 정수           | 예      | 프로젝트 이슈의 IID |
| `note_id`   | 정수           | 예      | 이슈 메모의 ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/1"
```

### 이슈 메모 생성 {#create-an-issue-note}

지정된 프로젝트 이슈에 대한 메모를 생성합니다.

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

매개 변수:

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid`    | 정수           | 예      | 이슈의 IID입니다. |
| `body`         | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `confidential` | 부울           | 아니오       | **더 이상 사용되지 않음**:  GitLab 16.0에서 제거 예정이며 `internal`로 이름이 변경됩니다. 메모의 기밀 플래그입니다. 기본값은 false입니다. |
| `internal`     | 부울           | 아니오       | 메모의 내부 플래그입니다. 두 매개 변수가 모두 제출되면 `confidential`을 무시합니다. 기본값은 false입니다. |
| `created_at`   | 문자열            | 아니오       | ISO 8601 형식의 날짜 시간 문자열입니다. 1970-01-01 이후여야 합니다. 예: `2016-03-11T03:45:40Z` (관리자 또는 프로젝트/그룹 소유자 권한 필요) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note"
```

### 이슈 메모 업데이트 {#update-an-issue-note}

이슈의 지정된 메모를 업데이트합니다.

```plaintext
PUT /projects/:id/issues/:issue_iid/notes/:note_id
```

매개 변수:

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid`    | 정수           | 예      | 이슈의 IID입니다. |
| `note_id`      | 정수           | 예      | 메모의 ID입니다. |
| `body`         | 문자열            | 아니오       | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `confidential` | 부울           | 아니오       | **더 이상 사용되지 않음**:  GitLab 16.0에서 제거 예정입니다. 메모의 기밀 플래그입니다. 기본값은 false입니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636?body=note"
```

### 이슈 메모 삭제 {#delete-an-issue-note}

이슈의 기존 메모를 삭제합니다.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id
```

매개 변수:

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid` | 정수           | 예      | 이슈의 IID |
| `note_id`   | 정수           | 예      | 메모의 ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636"
```

## 스니펫 {#snippets}

스니펫 메모 API는 프로젝트 수준의 스니펫용으로 제공되며, 개인 스니펫용은 아닙니다.

### 모든 스니펫 메모 나열 {#list-all-snippet-notes}

지정된 스니펫의 모든 메모를 나열합니다. 스니펫 메모는 사용자가 스니펫에 게시할 수 있는 주석입니다.

```plaintext
GET /projects/:id/snippets/:snippet_id/notes
GET /projects/:id/snippets/:snippet_id/notes?sort=asc&order_by=updated_at
```

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `snippet_id` | 정수           | 예      | 프로젝트 스니펫의 ID |
| `sort`       | 문자열            | 아니오       | 스니펫 메모를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `order_by`   | 문자열            | 아니오       | 스니펫 메모를 `created_at` 또는 `updated_at` 필드로 정렬하여 반환합니다. 기본값은 `created_at`입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes"
```

### 스니펫 메모 검색 {#retrieve-a-snippet-note}

스니펫의 지정된 메모를 검색합니다.

```plaintext
GET /projects/:id/snippets/:snippet_id/notes/:note_id
```

매개 변수:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `snippet_id` | 정수           | 예      | 프로젝트 스니펫의 ID |
| `note_id`    | 정수           | 예      | 스니펫 메모의 ID |

```json
{
  "id": 302,
  "body": "closed",
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T09:22:45Z",
  "updated_at": "2013-10-02T10:22:45Z",
  "system": true,
  "noteable_id": 377,
  "noteable_type": "Issue",
  "project_id": 5,
  "noteable_iid": 377,
  "resolvable": false,
  "confidential": false,
  "internal": false,
  "imported": false,
  "imported_from": "none"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/11"
```

### 스니펫 메모 생성 {#create-a-snippet-note}

지정된 스니펫에 대한 새 메모를 생성합니다. 스니펫 메모는 스니펫에 대한 사용자 주석입니다. 본문에 이모지 반응만 포함된 메모를 생성하면 GitLab이 이 개체를 반환합니다.

```plaintext
POST /projects/:id/snippets/:snippet_id/notes
```

매개 변수:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `snippet_id` | 정수           | 예      | 스니펫의 ID |
| `body`       | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `created_at` | 문자열            | 아니오       | ISO 8601 형식의 날짜 시간 문자열입니다. 예: `2016-03-11T03:45:40Z` (관리자 또는 프로젝트/그룹 소유자 권한 필요) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note"
```

### 스니펫 메모 업데이트 {#update-a-snippet-note}

스니펫의 지정된 메모를 업데이트합니다.

```plaintext
PUT /projects/:id/snippets/:snippet_id/notes/:note_id
```

매개 변수:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `snippet_id` | 정수           | 예      | 스니펫의 ID |
| `note_id`    | 정수           | 예      | 스니펫 메모의 ID |
| `body`       | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/1659?body=note"
```

### 스니펫 메모 삭제 {#delete-a-snippet-note}

스니펫의 기존 메모를 삭제합니다.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/notes/:note_id
```

매개 변수:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `snippet_id` | 정수           | 예      | 스니펫의 ID |
| `note_id`    | 정수           | 예      | 메모의 ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/52/notes/1659"
```

## 머지 리퀘스트 {#merge-requests}

### 모든 머지 리퀘스트 메모 나열 {#list-all-merge-request-notes}

지정된 머지 리퀘스트의 모든 메모를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes
GET /projects/:id/merge_requests/:merge_request_iid/notes?sort=asc&order_by=updated_at
```

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수           | 예      | 프로젝트 머지 리퀘스트의 IID |
| `sort`              | 문자열            | 아니오       | 머지 리퀘스트 메모를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `order_by`          | 문자열            | 아니오       | 머지 리퀘스트 메모를 `created_at` 또는 `updated_at` 필드로 정렬하여 반환합니다. 기본값은 `created_at`입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes"
```

### 머지 리퀘스트 메모 검색 {#retrieve-a-merge-request-note}

머지 리퀘스트의 지정된 메모를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

매개 변수:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수           | 예      | 프로젝트 머지 리퀘스트의 IID |
| `note_id`           | 정수           | 예      | 머지 리퀘스트 메모의 ID |

```json
{
  "id": 301,
  "body": "Comment for MR",
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T08:57:14Z",
  "updated_at": "2013-10-02T08:57:14Z",
  "system": false,
  "noteable_id": 2,
  "noteable_type": "MergeRequest",
  "project_id": 5,
  "noteable_iid": 2,
  "resolvable": false,
  "confidential": false,
  "internal": false
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1"
```

### 머지 리퀘스트 메모 생성 {#create-a-merge-request-note}

지정된 머지 리퀘스트에 대한 메모를 생성합니다. 메모는 머지 리퀘스트의 특정 행에 첨부되지 않습니다. 더 세밀한 제어가 필요한 경우 커밋 API의 [커밋에 주석 게시](commits.md#post-comment-to-commit) 와 토론 API의 [머지 리퀘스트 diff에서 새 스레드 생성](discussions.md#create-a-new-thread-in-the-merge-request-diff)을 참조하세요.

본문에 이모지 반응만 포함된 메모를 생성하면 GitLab이 이 개체를 반환합니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/notes
```

매개 변수:

| 속성                     | 유형              | 필수 | 설명 |
|-------------------------------|-------------------|----------|-------------|
| `body`                        | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | 정수           | 예      | 프로젝트 머지 리퀘스트의 IID |
| `created_at`                  | 문자열            | 아니오       | ISO 8601 형식의 날짜 시간 문자열입니다. 예: `2016-03-11T03:45:40Z` (관리자 또는 프로젝트/그룹 소유자 권한 필요) |
| `internal`                    | 부울           | 아니오       | 메모의 내부 플래그입니다. 기본값은 false입니다. |
| `merge_request_diff_head_sha` | 문자열            | 아니오       | [`/merge`](../user/project/quick_actions.md#merge) 빠른 작업에 필요합니다. API 요청이 전송된 후 머지 리퀘스트가 업데이트되지 않았는지 확인하는 헤드 커밋의 SHA입니다. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes?body=note"
```

### 머지 리퀘스트 메모 업데이트 {#update-a-merge-request-note}

머지 리퀘스트의 지정된 메모를 업데이트합니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

매개 변수:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수           | 예      | 프로젝트 머지 리퀘스트의 IID |
| `note_id`           | 정수           | 아니오       | 메모의 ID |
| `body`              | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `confidential`      | 부울           | 아니오       | **더 이상 사용되지 않음**:  GitLab 16.0에서 제거 예정입니다. 메모의 기밀 플래그입니다. 기본값은 false입니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1?body=note"
```

### 머지 리퀘스트 메모 삭제 {#delete-a-merge-request-note}

머지 리퀘스트의 기존 메모를 삭제합니다.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

매개 변수:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수           | 예      | 머지 리퀘스트의 IID |
| `note_id`           | 정수           | 예      | 메모의 ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/7/notes/1602"
```

## 에픽 {#epics}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> 에픽 REST API는 GitLab 17.0에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) API의 v5에서 제거할 계획입니다. GitLab 17.4부터 18.0까지 [에픽의 새로운 모양](../user/group/epics/_index.md#epics-as-work-items)이 활성화되어 있고, GitLab 18.1 이상에서는 대신 Work Items API를 사용합니다. 자세한 내용은 [에픽 API를 work items로 마이그레이션](graphql/epic_work_items_api_migration_guide.md)을 참조하세요. 이 변경은 주요 변경 사항입니다.

### 모든 에픽 메모 나열 {#list-all-epic-notes}

지정된 에픽의 모든 메모를 나열합니다. 에픽 메모는 사용자가 에픽에 게시할 수 있는 주석입니다.

> [!note]
> 에픽 메모 API는 에픽 IID 대신 에픽 ID를 사용합니다. 에픽의 IID를 사용하면 GitLab이 404 오류를 반환하거나 잘못된 에픽의 메모를 반환합니다. [이슈 메모 API](#issues) 및 [머지 리퀘스트 메모 API](#merge-requests)와 다릅니다.

```plaintext
GET /groups/:id/epics/:epic_id/notes
GET /groups/:id/epics/:epic_id/notes?sort=asc&order_by=updated_at
```

| 속성  | 유형              | 필수 | 설명 |
|------------|-------------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `epic_id`  | 정수           | 예      | 그룹 에픽의 ID |
| `sort`     | 문자열            | 아니오       | 에픽 메모를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `order_by` | 문자열            | 아니오       | 에픽 메모를 `created_at` 또는 `updated_at` 필드로 정렬하여 반환합니다. 기본값은 `created_at`입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes"
```

### 에픽 메모 검색 {#retrieve-an-epic-note}

에픽의 지정된 메모를 검색합니다.

```plaintext
GET /groups/:id/epics/:epic_id/notes/:note_id
```

매개 변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `epic_id` | 정수           | 예      | 에픽의 ID |
| `note_id` | 정수           | 예      | 메모의 ID |

```json
{
  "id": 302,
  "body": "Epic note",
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T09:22:45Z",
  "updated_at": "2013-10-02T10:22:45Z",
  "system": true,
  "noteable_id": 11,
  "noteable_type": "Epic",
  "project_id": 5,
  "noteable_iid": 11,
  "resolvable": false,
  "confidential": false,
  "internal": false,
  "imported": false,
  "imported_from": "none"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1"
```

### 에픽 메모 생성 {#create-an-epic-note}

지정된 에픽에 대한 메모를 생성합니다. 에픽 메모는 사용자가 에픽에 게시할 수 있는 주석입니다. 본문에 이모지 반응만 포함된 메모를 생성하면 GitLab이 이 개체를 반환합니다.

```plaintext
POST /groups/:id/epics/:epic_id/notes
```

매개 변수:

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `body`         | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `epic_id`      | 정수           | 예      | 에픽의 ID |
| `id`           | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `confidential` | 부울           | 아니오       | **더 이상 사용되지 않음**:  GitLab 16.0에서 제거 예정이며 `internal`로 이름이 변경됩니다. 메모의 기밀 플래그입니다. 기본값은 `false`입니다. |
| `internal`     | 부울           | 아니오       | 메모의 내부 플래그입니다. 두 매개 변수가 모두 제출되면 `confidential`을 무시합니다. 기본값은 `false`입니다. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes?body=note"
```

### 에픽 메모 업데이트 {#update-an-epic-note}

에픽의 지정된 메모를 업데이트합니다.

```plaintext
PUT /groups/:id/epics/:epic_id/notes/:note_id
```

매개 변수:

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `epic_id`      | 정수           | 예      | 에픽의 ID |
| `note_id`      | 정수           | 예      | 메모의 ID |
| `body`         | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `confidential` | 부울           | 아니오       | **더 이상 사용되지 않음**:  GitLab 16.0에서 제거 예정입니다. 메모의 기밀 플래그입니다. 기본값은 false입니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1?body=note"
```

### 에픽 메모 삭제 {#delete-an-epic-note}

에픽의 기존 메모를 삭제합니다.

```plaintext
DELETE /groups/:id/epics/:epic_id/notes/:note_id
```

매개 변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `epic_id` | 정수           | 예      | 에픽의 ID |
| `note_id` | 정수           | 예      | 메모의 ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/52/notes/1659"
```

## 프로젝트 위키 {#project-wikis}

### 모든 프로젝트 위키 메모 나열 {#list-all-project-wiki-notes}

지정된 프로젝트 위키 페이지의 모든 메모를 나열합니다. 프로젝트 위키 메모는 사용자가 위키 페이지에 게시할 수 있는 주석입니다.

> [!note]
> 위키 페이지 메모 API는 위키 페이지 슬래그 대신 위키 페이지 메타 ID를 사용합니다. 페이지의 슬래그를 사용하면 GitLab이 404 오류를 반환합니다. [프로젝트 위키 API](wikis.md)에서 메타 ID를 검색할 수 있습니다.

```plaintext
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes?sort=asc&order_by=updated_at
```

매개 변수:

| 속성  | 유형              | 필수 | 설명 |
|------------|-------------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `sort`     | 문자열            | 아니오       | 위키 페이지 메모를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `order_by` | 문자열            | 아니오       | 위키 페이지 메모를 `created_at` 또는 `updated_at` 필드로 정렬하여 반환합니다. 기본값은 `created_at`입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes"
```

### 위키 페이지 메모 검색 {#retrieve-a-wiki-page-note}

지정된 위키 페이지의 단일 메모를 검색합니다.

```plaintext
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

매개 변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `note_id` | 정수           | 예      | 메모의 ID |

```json
{
  "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
  },
  "body": "foobar",
  "commands_changes": {},
  "confidential": false,
  "created_at": "2025-03-11T11:36:32.222Z",
  "id": 1218,
  "imported": false,
  "imported_from": "none",
  "internal": false,
  "noteable_id": 35,
  "noteable_iid": null,
  "noteable_type": "WikiPage::Meta",
  "project_id": 5,
  "resolvable": false,
  "system": false,
  "type": null,
  "updated_at": "2025-03-11T11:36:32.222Z"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218"
```

### 위키 페이지 메모 생성 {#create-a-wiki-page-note}

단일 위키 페이지에 대한 새 메모를 생성합니다. 위키 페이지 메모는 사용자가 위키 페이지에 게시할 수 있는 주석입니다.

```plaintext
POST /projects/:id/wiki_pages/:wiki_page_meta_id/notes
```

매개 변수:

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `body`         | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes?body=note"
```

### 위키 페이지 메모 업데이트 {#update-a-wiki-page-note}

위키 페이지의 기존 메모를 업데이트합니다.

```plaintext
PUT /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

매개 변수:

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `note_id`      | 정수           | 예      | 메모의 ID |
| `body`         | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218?body=note"
```

### 위키 페이지 메모 삭제 {#delete-a-wiki-page-note}

위키 페이지에서 메모를 삭제합니다.

```plaintext
DELETE /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

매개 변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `note_id` | 정수           | 예      | 메모의 ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218"
```

## 그룹 위키 {#group-wikis}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

### 그룹 위키 메모 나열 {#list-group-wiki-notes}

지정된 그룹 위키 페이지의 모든 메모를 나열합니다. 그룹 위키 메모는 사용자가 위키 페이지에 게시할 수 있는 주석입니다.

> [!note]
> 위키 페이지 메모 API는 위키 페이지 슬래그 대신 위키 페이지 메타 ID를 사용합니다. 페이지의 슬래그를 사용하면 GitLab이 404 오류를 반환합니다. [그룹 위키 API](group_wikis.md)에서 메타 ID를 검색할 수 있습니다.

```plaintext
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes?sort=asc&order_by=updated_at
```

| 속성  | 유형              | 필수 | 설명 |
|------------|-------------------|----------|-------------|
| `id`       | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `sort`     | 문자열            | 아니오       | 위키 페이지 메모를 `asc` 또는 `desc` 순서로 정렬하여 반환합니다. 기본값은 `desc`입니다. |
| `order_by` | 문자열            | 아니오       | 위키 페이지 메모를 `created_at` 또는 `updated_at` 필드로 정렬하여 반환합니다. 기본값은 `created_at`입니다. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes"
```

### 위키 페이지 메모 검색 {#retrieve-a-wiki-page-note-1}

위키 페이지의 지정된 메모를 검색합니다.

```plaintext
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

매개 변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `note_id` | 정수           | 예      | 메모의 ID |

```json
{
  "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
  },
  "body": "foobar",
  "commands_changes": {},
  "confidential": false,
  "created_at": "2025-03-11T11:36:32.222Z",
  "id": 1218,
  "imported": false,
  "imported_from": "none",
  "internal": false,
  "noteable_id": 35,
  "noteable_iid": null,
  "noteable_type": "WikiPage::Meta",
  "project_id": null,
  "resolvable": false,
  "system": false,
  "type": null,
  "updated_at": "2025-03-11T11:36:32.222Z"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218"
```

### 위키 페이지 메모 생성 {#create-a-wiki-page-note-1}

지정된 위키 페이지에 대한 메모를 생성합니다. 위키 페이지 메모는 사용자가 위키 페이지에 게시할 수 있는 주석입니다.

```plaintext
POST /groups/:id/wiki_pages/:wiki_page_meta_id/notes
```

매개 변수:

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `body`         | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `id`           | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes?body=note"
```

### 위키 페이지 메모 업데이트 {#update-a-wiki-page-note-1}

위키 페이지의 지정된 노트를 업데이트합니다.

```plaintext
PUT /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

매개 변수:

| 속성      | 유형              | 필수 | 설명 |
|----------------|-------------------|----------|-------------|
| `id`           | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `note_id`      | 정수           | 예      | 메모의 ID |
| `body`         | 문자열            | 예      | 메모의 콘텐츠입니다. 1,000,000만 자까지 제한됩니다. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218?body=note"
```

### 위키 페이지 메모 삭제 {#delete-a-wiki-page-note-1}

위키 페이지에서 메모를 삭제합니다.

```plaintext
DELETE /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

매개 변수:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | 정수           | 예      | 위키 페이지 메타의 ID |
| `note_id` | 정수           | 예      | 메모의 ID |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218"
```
