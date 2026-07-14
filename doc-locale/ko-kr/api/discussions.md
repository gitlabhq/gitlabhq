---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Discussions API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [discussions](../user/discussions/_index.md)을 관리합니다. 여기에는 [comments, threads](../user/discussions/_index.md)와 객체의 변경 사항에 대한 시스템 notes가 포함됩니다(예: milestone이 변경될 때).

label notes를 관리하려면 [resource label events API](resource_label_events.md)를 사용하세요.

## API의 note 유형 이해 {#understand-note-types-in-the-api}

모든 discussion 유형이 API에서 동일하게 사용 가능한 것은 아닙니다:

- 참고: _root_에서 issue, , 또는 snippet에 남겨진 .
- Discussion:  종종 _스레드_라고 불리는 issue, merge request, commit 또는 snippet의 `DiscussionNotes` 모음.
- DiscussionNote:  issue, merge request, commit 또는 snippet의 discussion에 있는 개별 항목. `DiscussionNote` 유형의 항목은 Note API의 일부로 반환되지 않습니다. [Events API](events.md)에서는 사용할 수 없습니다.

## Discussions pagination {#discussions-pagination}

기본적으로 `GET` 요청은 API 결과가 paginated되기 때문에 한 번에 20개의 결과를 반환합니다.

[pagination](rest/_index.md#pagination)에 대해 자세히 읽어보세요.

## Issues {#issues}

### 모든 issue discussion 항목 나열 {#list-all-issue-discussion-items}

프로젝트의 지정된 issue에 대한 모든 discussion 항목을 나열합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/discussions
```

지원하는 속성:

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `issue_iid` | 정수           | 예      | issue의 IID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성               | 유형    | 설명 |
|-------------------------|---------|-------------|
| `id`                    | 문자열  | discussion의 ID. |
| `individual_note`       | 부울 | `true`이면 개별 note 또는 discussion의 일부. |
| `notes`                 | 배열   | discussion의 note 객체 배열. |
| `notes[].id`            | 정수 | note의 ID. |
| `notes[].type`          | 문자열  | note의 유형(`DiscussionNote` 또는 `null`). |
| `notes[].body`          | 문자열  | note의 내용. |
| `notes[].author`        | 객체  | note의 작성자. |
| `notes[].created_at`    | 문자열  | note가 생성된 시간(ISO 8601 형식). |
| `notes[].updated_at`    | 문자열  | note가 마지막으로 업데이트된 시간(ISO 8601 형식). |
| `notes[].system`        | 부울 | `true`이면 시스템 note. |
| `notes[].noteable_id`   | 정수 | noteable 객체의 ID. |
| `notes[].noteable_type` | 문자열  | noteable 객체의 유형. |
| `notes[].project_id`    | 정수 | 프로젝트의 ID. |
| `notes[].resolvable`    | 부울 | `true`이면 note를 해결할 수 있습니다. |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions"
```

응답 예시:

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### issue discussion 항목 검색 {#retrieve-an-issue-discussion-item}

프로젝트 issue의 지정된 discussion 항목을 검색합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/discussions/:discussion_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 정수            | 예      | discussion 항목의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `issue_iid`     | 정수           | 예      | issue의 IID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 와 [List issue discussion items](#list-all-issue-discussion-items)와 동일한 응답 속성을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>"
```

### issue 생성 {#create-an-issue-thread}

단일 프로젝트 issue에 새로운 스레드를 생성합니다. note를 생성하는 것과 유사하지만 나중에 다른 comments(replies)를 추가할 수 있습니다.

```plaintext
POST /projects/:id/issues/:issue_iid/discussions
```

지원하는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `body`       | 문자열            | 예      | 스레드의 내용. |
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `issue_iid`  | 정수           | 예      | issue의 IID. |
| `created_at` | 문자열            | 아니요       | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes) 와 [List issue discussion items](#list-all-issue-discussion-items)와 동일한 응답 속성을 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions?body=comment"
```

### issue 스레드에 note 추가 {#add-a-note-to-an-issue-thread}

스레드에 새로운 note를 추가합니다. 이를 통해 [단일 comment에서 스레드 생성](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment)할 수도 있습니다.

> [!note]
> System notes에는 notes를 추가할 수 없습니다. 이를 수행하려고 하면 `400 Bad Request` 오류가 반환됩니다.

```plaintext
POST /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `body`          | 문자열            | 예      | note 또는 reply의 내용. |
| `discussion_id` | 정수            | 예      | 스레드의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `issue_iid`     | 정수           | 예      | issue의 IID. |
| `created_at`    | 문자열            | 아니요       | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes?body=comment"
```

### issue 스레드 note 업데이트 {#update-an-issue-thread-note}

issue의 기존 스레드 note를 업데이트합니다.

```plaintext
PUT /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `body`          | 문자열            | 예      | note 또는 reply의 내용. |
| `discussion_id` | 정수            | 예      | 스레드의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `issue_iid`     | 정수           | 예      | issue의 IID. |
| `note_id`       | 정수           | 예      | 스레드 note의 ID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 업데이트된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### issue 스레드 note 삭제 {#delete-an-issue-thread-note}

issue의 기존 스레드 note를 삭제합니다.

```plaintext
DELETE /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 정수            | 예      | discussion의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `issue_iid`     | 정수           | 예      | issue의 IID. |
| `note_id`       | 정수           | 예      | discussion note의 ID. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes/<note_id>"
```

## Snippets {#snippets}

### 모든 snippet discussion 항목 나열 {#list-all-snippet-discussion-items}

프로젝트의 지정된 snippet에 대한 모든 discussion 항목을 나열합니다.

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions
```

지원하는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `snippet_id` | 정수           | 예      | snippet의 ID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 와 [List issue discussion items](#list-all-issue-discussion-items)와 동일한 응답 속성(`noteable_type`는 `Snippet`로 설정됨)을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions"
```

응답 예시:

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### snippet discussion 항목 검색 {#retrieve-a-snippet-discussion-item}

프로젝트 snippet의 지정된 discussion 항목을 검색합니다.

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions/:discussion_id
```

지원하는 속성:

| 속성       | 유형           | 필수 | 설명 |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | 정수         | 예      | discussion 항목의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `snippet_id`    | 정수        | 예      | snippet의 ID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 와 [List snippet discussion items](#list-all-snippet-discussion-items)와 동일한 응답 속성을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>"
```

### snippet 생성 {#create-a-snippet-thread}

단일 프로젝트 snippet에 새로운 스레드를 생성합니다. note를 생성하는 것과 유사하지만 나중에 다른 comments(replies)를 추가할 수 있습니다.

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions
```

지원하는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `body`       | 문자열            | 예      | discussion의 내용. |
| `id`         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `snippet_id` | 정수           | 예      | snippet의 ID. |
| `created_at` | 문자열            | 아니요       | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 discussion 객체를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions?body=comment"
```

### snippet 스레드에 note 추가 {#add-a-note-to-a-snippet-thread}

스레드에 새로운 note를 추가합니다.

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `body`          | 문자열            | 예      | note 또는 reply의 내용. |
| `discussion_id` | 정수            | 예      | 스레드의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `snippet_id`    | 정수           | 예      | snippet의 ID. |
| `created_at`    | 문자열            | 아니요       | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes?body=comment"
```

### snippet 스레드 note 업데이트 {#update-a-snippet-thread-note}

snippet의 기존 스레드 note를 업데이트합니다.

```plaintext
PUT /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성       | 유형           | 필수 | 설명 |
| --------------- | -------------- | -------- | ----------- |
| `body`          | 문자열         | 예      | note 또는 reply의 내용. |
| `discussion_id` | 정수         | 예      | 스레드의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `note_id`       | 정수        | 예      | 스레드 note의 ID. |
| `snippet_id`    | 정수        | 예      | snippet의 ID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 업데이트된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### snippet 스레드 note 삭제 {#delete-a-snippet-thread-note}

snippet의 기존 스레드 note를 삭제합니다.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 정수            | 예      | discussion의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `note_id`       | 정수           | 예      | discussion note의 ID. |
| `snippet_id`    | 정수           | 예      | snippet의 ID. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes/<note_id>"
```

## Epics {#epics}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Epics REST API는 GitLab 17.0에서 [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)되었으며 API의 v5에서 제거될 예정입니다. 이 변경 사항은 breaking change입니다.
>
> 대신 Work Items API를 사용하세요:
>
> - GitLab 17.4 to 18.0:  [epics의 새로운 모습](../user/group/epics/_index.md#epics-as-work-items)이 활성화되었을 때 필수입니다.
> - GitLab 18.1 이상:  모든 설치에 필수입니다.
>
> 자세한 내용은 [API migration guide](graphql/epic_work_items_api_migration_guide.md)를 참조하세요.

### 모든 epic discussion 항목 나열 {#list-all-epic-discussion-items}

단일 epic의 모든 discussion 항목을 나열합니다.

```plaintext
GET /groups/:id/epics/:epic_id/discussions
```

지원하는 속성:

| 속성 | 유형              | 필수 | 설명 |
|-----------|-------------------|----------|-------------|
| `epic_id` | 정수           | 예      | 에픽의 ID. |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 와 [List issue discussion items](#list-all-issue-discussion-items)와 동일한 응답 속성(`noteable_type`는 `Epic`로 설정됨)을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions"
```

응답 예시:

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### epic discussion 항목 검색 {#retrieve-an-epic-discussion-item}

그룹 epic의 지정된 discussion 항목을 검색합니다.

```plaintext
GET /groups/:id/epics/:epic_id/discussions/:discussion_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 정수            | 예      | discussion 항목의 ID. |
| `epic_id`       | 정수           | 예      | 에픽의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 와 [List epic discussion items](#list-all-epic-discussion-items)와 동일한 응답 속성을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>"
```

### epic 생성 {#create-an-epic-thread}

단일 그룹 epic에 새로운 스레드를 생성합니다. note를 생성하는 것과 유사하지만 나중에 다른 comments(replies)를 추가할 수 있습니다.

```plaintext
POST /groups/:id/epics/:epic_id/discussions
```

지원하는 속성:

| 속성    | 유형              | 필수 | 설명 |
|--------------|-------------------|----------|-------------|
| `body`       | 문자열            | 예      | 스레드의 내용. |
| `epic_id`    | 정수           | 예      | 에픽의 ID. |
| `id`         | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `created_at` | 문자열            | 아니요       | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 discussion 객체를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions?body=comment"
```

### epic 스레드에 note 추가 {#add-a-note-to-an-epic-thread}

스레드에 새로운 note를 추가합니다. 이를 통해 [단일 comment에서 스레드 생성](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment)할 수도 있습니다.

```plaintext
POST /groups/:id/epics/:epic_id/discussions/:discussion_id/notes
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `body`          | 문자열            | 예      | note 또는 reply의 내용. |
| `discussion_id` | 정수            | 예      | 스레드의 ID. |
| `epic_id`       | 정수           | 예      | 에픽의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `created_at`    | 문자열            | 아니요       | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes?body=comment"
```

### epic 스레드 note 업데이트 {#update-an-epic-thread-note}

epic의 기존 스레드 note를 업데이트합니다.

```plaintext
PUT /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `body`          | 문자열            | 예      | note 또는 reply의 내용. |
| `discussion_id` | 정수            | 예      | 스레드의 ID. |
| `epic_id`       | 정수           | 예      | 에픽의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `note_id`       | 정수           | 예      | 스레드 note의 ID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 업데이트된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### epic 스레드 note 삭제 {#delete-an-epic-thread-note}

epic의 기존 스레드 note를 삭제합니다.

```plaintext
DELETE /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | 정수            | 예      | 스레드의 ID. |
| `epic_id`       | 정수           | 예      | 에픽의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `note_id`       | 정수           | 예      | 스레드 note의 ID. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes/<note_id>"
```

## Merge requests {#merge-requests}

### 모든 merge request discussion 항목 나열 {#list-all-merge-request-discussion-items}

지정된 merge request의 모든 discussion 항목을 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions
```

지원하는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | 정수           | 예      | merge request의 IID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성               | 유형    | 설명 |
|-------------------------|---------|-------------|
| `id`                    | 문자열  | discussion의 ID. |
| `individual_note`       | 부울 | `true`이면 개별 note 또는 discussion의 일부. |
| `notes`                 | 배열   | discussion의 note 객체 배열. |
| `notes[].id`            | 정수 | note의 ID. |
| `notes[].type`          | 문자열  | note의 유형(`DiscussionNote`, `DiffNote`, 또는 `null`). |
| `notes[].body`          | 문자열  | note의 내용. |
| `notes[].author`        | 객체  | note의 작성자. |
| `notes[].created_at`    | 문자열  | note가 생성된 시간(ISO 8601 형식). |
| `notes[].updated_at`    | 문자열  | note가 마지막으로 업데이트된 시간(ISO 8601 형식). |
| `notes[].system`        | 부울 | `true`이면 시스템 note. |
| `notes[].noteable_id`   | 정수 | noteable 객체의 ID. |
| `notes[].noteable_type` | 문자열  | noteable 객체의 유형. |
| `notes[].project_id`    | 정수 | 프로젝트의 ID. |
| `notes[].resolved`      | 부울 | `true`이면 note가 해결됨(merge requests만 해당). |
| `notes[].resolvable`    | 부울 | `true`이면 note를 해결할 수 있습니다. |
| `notes[].resolved_by`   | 객체  | note를 해결한 사용자. |
| `notes[].resolved_at`   | 문자열  | note가 해결된 시간(ISO 8601 형식). |
| `notes[].position`      | 객체  | diff notes의 위치 정보. |
| `notes[].suggestions`   | 배열   | note의 suggestion 객체 배열. |

Diff comments는 위치 정보도 포함합니다:

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
```

응답 예시:

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null,
        "resolved_at": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  }
]
```

Diff comments도 위치를 포함합니다:

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": "DiffNote",
        "body": "diff comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "commit_id": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
        "position": {
          "base_sha": "b5d6e7b1613fca24d250fa8e5bc7bcc3dd6002ef",
          "start_sha": "7c9c2ead8a320fb7ba0b4e234bd9529a2614e306",
          "head_sha": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
          "old_path": "package.json",
          "new_path": "package.json",
          "position_type": "text",
          "old_line": 27,
          "new_line": 27,
          "line_range": {
            "start": {
              "line_code": "588440f66559714280628a4f9799f0c4eb880a4a_10_10",
              "type": "new",
              "old_line": null,
              "new_line": 10
            },
            "end": {
              "line_code": "588440f66559714280628a4f9799f0c4eb880a4a_11_11",
              "type": "old",
              "old_line": 11,
              "new_line": 11
            }
          }
        },
        "resolved": false,
        "resolvable": true,
        "resolved_by": null,
        "suggestions": [
          {
            "id": 1,
            "from_line": 27,
            "to_line": 27,
            "appliable": true,
            "applied": false,
            "from_content": "x",
            "to_content": "b"
          }
        ]
      }
    ]
  }
]
```

### merge request discussion 항목 검색 {#retrieve-a-merge-request-discussion-item}

프로젝트 merge request의 지정된 discussion 항목을 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

지원하는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 문자열            | 예      | discussion 항목의 ID. |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | 정수           | 예      | merge request의 IID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 와 [List merge request discussion items](#list-all-merge-request-discussion-items)와 동일한 응답 속성을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>"
```

### merge request 생성 {#create-a-merge-request-thread}

단일 프로젝트 merge request에 새로운 스레드를 생성합니다. note를 생성하는 것과 유사하지만 나중에 다른 comments(replies)를 추가할 수 있습니다. 다른 접근 방식은 Commits API의 [Post comment to commit](commits.md#post-comment-to-commit) 과 Notes API의 [Create a merge request note](notes.md#create-a-merge-request-note)를 참조하세요.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions
```

모든 comments에 대한 지원하는 속성:

| 속성                 | 유형              | 필수                             | 설명 |
|---------------------------|-------------------|--------------------------------------|-------------|
| `body`                    | 문자열            | 예                                  | 스레드의 내용. |
| `id`                      | 정수 또는 문자열 | 예                                  | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `merge_request_iid`       | 정수           | 예                                  | merge request의 IID. |
| `commit_id`               | 문자열            | 아니요                                   | 이 discussion을 시작할 commit를 참조하는 SHA. |
| `created_at`              | 문자열            | 아니요                                   | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |
| `position`                | hash              | 아니요                                   | diff note를 생성할 때 위치. |
| `position[base_sha]`      | 문자열            | 예(`position*` 제공된 경우)     | 소스 브랜치의 base commit SHA. |
| `position[head_sha]`      | 문자열            | 예(`position*` 제공된 경우)     | 이 merge request의 HEAD를 참조하는 SHA. |
| `position[start_sha]`     | 문자열            | 예(`position*` 제공된 경우)     | 대상 브랜치의 commit를 참조하는 SHA. |
| `position[position_type]` | 문자열            | 예(position* 제공된 경우)       | 위치 참조의 유형. 허용되는 값: `text`, `image`, 또는 `file`. `file` GitLab 16.4에서 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423046). |
| `position[new_path]`      | 문자열            | 예(위치 유형이 `text`인 경우) | 변경 후 파일 경로. |
| `position[old_path]`      | 문자열            | 예(위치 유형이 `text`인 경우) | 변경 전 파일 경로. |
| `position[new_line]`      | 정수           | 아니요                                   | `text` diff notes의 경우 변경 후 줄 번호. |
| `position[old_line]`      | 정수           | 아니요                                   | `text` diff notes의 경우 변경 전 줄 번호. |
| `position[line_range]`    | hash              | 아니요                                   | multi-line diff note의 줄 범위. |
| `position[width]`         | 정수           | 아니요                                   | `image` diff notes의 경우 이미지의 너비. |
| `position[height]`        | 정수           | 아니요                                   | `image` diff notes의 경우 이미지의 높이. |
| `position[x]`             | float             | 아니요                                   | `image` diff notes의 경우 X 좌표. |
| `position[y]`             | float             | 아니요                                   | `image` diff notes의 경우 Y 좌표. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 discussion 객체를 반환합니다.

#### overview 페이지에 새로운 스레드 생성 {#create-a-new-thread-on-the-overview-page}

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions?body=comment"
```

#### merge request diff에 새로운 스레드 생성 {#create-a-new-thread-in-the-merge-request-diff}

- `position[old_path]`과 `position[new_path]`는 필수이며 변경 전후의 파일 경로를 참조해야 합니다.
- merge request diff에서 추가된 줄(녹색으로 강조)에 스레드를 생성하려면 `position[new_line]`을 사용하고 `position[old_line]`을 포함하지 마세요.
- merge request diff에서 제거된 줄(빨간색으로 강조)에 스레드를 생성하려면 `position[old_line]`을 사용하고 `position[new_line]`을 포함하지 마세요.
- 변경되지 않은 줄에 스레드를 생성하려면 해당 줄에 대해 `position[new_line]`과 `position[old_line]`을 모두 포함하세요. 파일의 이전 변경 사항이 줄 번호를 변경한 경우 이 위치들이 동일하지 않을 수 있습니다. 수정에 대한 discussion은 [issue 32516](https://gitlab.com/gitlab-org/gitlab/-/issues/325161)을 참조하세요.
- 잘못된 `base`, `head`, `start`, 또는 `SHA` 매개변수를 지정하면 [issue #296829](https://gitlab.com/gitlab-org/gitlab/-/issues/296829)에 설명된 버그가 발생할 수 있습니다.

새로운 스레드를 생성하려면:

1. [최신 merge request 버전 가져오기](merge_requests.md#retrieve-merge-request-diff-versions):

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/versions"
   ```

1. 최신 버전의 세부 정보를 확인하세요. 이는 응답 배열에 먼저 나열됩니다.

   ```json
   [
     {
       "id": 164560414,
       "head_commit_sha": "f9ce7e16e56c162edbc9e480108041cf6b0291fe",
       "base_commit_sha": "5e6dffa282c5129aa67cd227a0429be21bfdaf80",
       "start_commit_sha": "5e6dffa282c5129aa67cd227a0429be21bfdaf80",
       "created_at": "2021-03-30T09:18:27.351Z",
       "merge_request_id": 93958054,
       "state": "collected",
       "real_size": "2"
     },
     "previous versions are here"
   ]
   ```

1. 새로운 diff 스레드를 생성합니다. 이 예는 추가된 줄에 스레드를 생성합니다:

   ```shell
   curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --form 'position[position_type]=text' \
     --form 'position[base_sha]=<use base_commit_sha from the versions response>' \
     --form 'position[head_sha]=<use head_commit_sha from the versions response>' \
     --form 'position[start_sha]=<use start_commit_sha from the versions response>' \
     --form 'position[new_path]=file.js' \
     --form 'position[old_path]=file.js' \
     --form 'position[new_line]=18' \
     --form 'body=test comment body' \
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
   ```

#### multiline comments의 매개변수 {#parameters-for-multiline-comments}

multiline comments에만 해당하는 지원하는 속성:

| 속성                                | 유형    | 필수 | 설명 |
|------------------------------------------|---------|----------|-------------|
| `position[line_range][end][line_code]`   | 문자열  | 예      | 끝 줄의 [Line code](#line-code). |
| `position[line_range][end][type]`        | 문자열  | 예      | 이 commit에서 추가된 줄의 경우 `new`을 사용하고, 그 외의 경우 `old`를 사용합니다. |
| `position[line_range][end][old_line]`    | 정수 | 아니요       | 끝 줄의 이전 줄 번호. |
| `position[line_range][end][new_line]`    | 정수 | 아니요       | 끝 줄의 새 줄 번호. |
| `position[line_range][start][line_code]` | 문자열  | 예      | 시작 줄의 [Line code](#line-code). |
| `position[line_range][start][type]`      | 문자열  | 예      | 이 commit에서 추가된 줄의 경우 `new`을 사용하고, 그 외의 경우 `old`를 사용합니다. |
| `position[line_range][start][old_line]`  | 정수 | 아니요       | 시작 줄의 이전 줄 번호. |
| `position[line_range][start][new_line]`  | 정수 | 아니요       | 시작 줄의 새 줄 번호. |
| `position[line_range][end]`              | hash    | 아니요       | Multiline note 끝 줄. |
| `position[line_range][start]`            | hash    | 아니요       | Multiline note 시작 줄. |

`line_range` 속성 내의 `old_line`과 `new_line` 매개변수는 multi-line comments의 범위를 표시합니다. 예를 들어, "Comment on lines +296 to +297".

#### Line code {#line-code}

line code의 형식은 `<SHA>_<old>_<new>`입니다. 예: `adc83b19e793491b1c6ea0fd8b46cd9f32e292fc_5_5`

- `<SHA>`은 파일명의 SHA1 hash입니다.
- `<old>`은 변경 전 줄 번호입니다.
- `<new>`은 변경 후 줄 번호입니다.

예를 들어, commit(`<COMMIT_ID>`)이 README에서 줄 463을 삭제하는 경우 이전 파일의 줄 463을 참조하여 삭제에 대해 comment할 수 있습니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Very clever to remove this unnecessary line!" \
  --form "path=README" \
  --form "line=463" \
  --form "line_type=old" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

commit(`<COMMIT_ID>`)이 `hello.rb`에 줄 157을 추가하면 새 파일의 줄 157을 참조하여 추가에 대해 comment할 수 있습니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=This is brilliant!" \
  --form "path=hello.rb" \
  --form "line=157" \
  --form "line_type=new" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

### merge request 스레드 해결 {#resolve-a-merge-request-thread}

merge request의 discussion 스레드를 해결하거나 다시 열기.

전제 조건:

- Developer, Maintainer, 또는 Owner 역할이 있거나 검토 중인 변경 사항의 작성자여야 합니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

지원하는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 문자열            | 예      | 스레드의 ID. |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | 정수           | 예      | merge request의 IID. |
| `resolved`          | 부울           | 예      | `true`이면 discussion을 해결하거나 다시 열기. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 업데이트된 discussion 객체를 반환합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>?resolved=true"
```

### merge request 스레드에 note 추가 {#add-note-to-a-merge-request-thread}

스레드에 새로운 note를 추가합니다. 이를 통해 [단일 comment에서 스레드 생성](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment)할 수도 있습니다.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes
```

지원하는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `body`              | 문자열            | 예      | note 또는 reply의 내용. |
| `discussion_id`     | 문자열            | 예      | 스레드의 ID. |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | 정수           | 예      | merge request의 IID. |
| `created_at`        | 문자열            | 아니요       | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes?body=comment"
```

### merge request 스레드 note 업데이트 {#update-a-merge-request-thread-note}

merge request의 지정된 스레드 note를 업데이트하거나 해결합니다.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 문자열            | 예      | 스레드의 ID. |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | 정수           | 예      | merge request의 IID. |
| `note_id`           | 정수           | 예      | 스레드 note의 ID. |
| `body`              | 문자열            | 아니요       | note 또는 reply의 내용. `body` 또는 `resolved` 중 정확히 하나를 설정해야 합니다. |
| `resolved`          | 부울           | 아니요       | note를 해결하거나 다시 열기. `body` 또는 `resolved` 중 정확히 하나를 설정해야 합니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 업데이트된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

note 해결:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>?resolved=true"
```

### merge request 스레드 note 삭제 {#delete-a-merge-request-thread-note}

merge request의 기존 스레드 note를 삭제합니다.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성           | 유형              | 필수 | 설명 |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | 문자열            | 예      | 스레드의 ID. |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | 정수           | 예      | merge request의 IID. |
| `note_id`           | 정수           | 예      | 스레드 note의 ID. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>"
```

## Commits {#commits}

### 모든 커밋 discussion 항목 나열 {#list-all-commit-discussion-items}

지정된 commit의 모든 discussion 항목을 나열합니다.

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions
```

지원하는 속성:

| 속성   | 유형              | 필수 | 설명 |
|-------------|-------------------|----------|-------------|
| `commit_id` | 문자열            | 예      | 커밋의 SHA. |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 와 [List issue discussion items](#list-all-issue-discussion-items)와 동일한 응답 속성(`noteable_type`는 `Commit`로 설정됨)을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions"
```

응답 예시:

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

diff 주석에는 위치 정보도 포함됩니다:

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": "DiffNote",
        "body": "diff comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "position": {
          "base_sha": "b5d6e7b1613fca24d250fa8e5bc7bcc3dd6002ef",
          "start_sha": "7c9c2ead8a320fb7ba0b4e234bd9529a2614e306",
          "head_sha": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
          "old_path": "package.json",
          "new_path": "package.json",
          "position_type": "text",
          "old_line": 27,
          "new_line": 27
        },
        "resolvable": false
      }
    ]
  }
]
```

### 커밋 스레드 항목 검색 {#retrieve-a-commit-discussion-item}

프로젝트 커밋에 대한 지정된 스레드 항목을 검색합니다.

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions/:discussion_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `commit_id`     | 문자열            | 예      | 커밋의 SHA. |
| `discussion_id` | 문자열            | 예      | discussion 항목의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes) 과 [커밋 스레드 항목 나열](#list-all-commit-discussion-items)과 동일한 응답 속성을 반환합니다.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>"
```

### 커밋 스레드 만들기 {#create-a-commit-thread}

단일 프로젝트 커밋에 새로운 스레드를 만듭니다. note를 생성하는 것과 유사하지만 나중에 다른 comments(replies)를 추가할 수 있습니다.

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions
```

지원하는 속성:

| 속성                 | 유형              | 필수                         | 설명 |
|---------------------------|-------------------|----------------------------------|-------------|
| `body`                    | 문자열            | 예                              | 스레드의 내용. |
| `commit_id`               | 문자열            | 예                              | 커밋의 SHA. |
| `id`                      | 정수 또는 문자열 | 예                              | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `created_at`              | 문자열            | 아니요                               | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |
| `position`                | hash              | 아니요                               | diff note를 생성할 때 위치. |
| `position[base_sha]`      | 문자열            | 예(`position*` 제공된 경우) | 상위 커밋의 SHA입니다. |
| `position[head_sha]`      | 문자열            | 예(`position*` 제공된 경우) | 이 커밋의 SHA입니다. `commit_id`과 동일합니다. |
| `position[start_sha]`     | 문자열            | 예(`position*` 제공된 경우) | 상위 커밋의 SHA입니다. |
| `position[position_type]` | 문자열            | 예(`position*` 제공된 경우) | 위치 참조의 유형. 허용되는 값: `text`, `image`, 또는 `file`. `file` GitLab 16.4에서 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423046). |
| `position[new_path]`      | 문자열            | 아니요                               | 변경 후 파일 경로. |
| `position[new_line]`      | 정수           | 아니요                               | 변경 후 라인 번호입니다. |
| `position[old_path]`      | 문자열            | 아니요                               | 변경 전 파일 경로. |
| `position[old_line]`      | 정수           | 아니요                               | 변경 전 라인 번호입니다. |
| `position[height]`        | 정수           | 아니요                               | `image` diff 주석의 경우 이미지 높이입니다. |
| `position[width]`         | 정수           | 아니요                               | `image` diff 주석의 경우 이미지 너비입니다. |
| `position[x]`             | 정수           | 아니요                               | `image` diff notes의 경우 X 좌표. |
| `position[y]`             | 정수           | 아니요                               | `image` diff notes의 경우 Y 좌표. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 discussion 객체를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions?body=comment"
```

API 요청을 생성하는 규칙은 [머지 리퀘스트 diff에 새로운 스레드 만들기](#create-a-new-thread-in-the-merge-request-diff)와 동일합니다. 예외사항:

- `base_sha`
- `head_sha`
- `start_sha`

### 커밋 스레드에 주석 추가 {#add-note-to-a-commit-thread}

스레드에 새로운 note를 추가합니다.

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `body`          | 문자열            | 예      | note 또는 reply의 내용. |
| `commit_id`     | 문자열            | 예      | 커밋의 SHA. |
| `discussion_id` | 문자열            | 예      | 스레드의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `created_at`    | 문자열            | 아니요       | `2016-03-11T03:45:40Z`와 같이 ISO 8601 형식의 날짜 시간 문자열. 관리자 또는 프로젝트/그룹 소유자 권한이 필요합니다. |

성공하면 [`201 Created`](rest/troubleshooting.md#status-codes)와 생성된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes?body=comment"
```

### 커밋 스레드 주석 업데이트 {#update-a-commit-thread-note}

커밋의 지정된 스레드 주석을 업데이트하거나 해결합니다.

```plaintext
PUT /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `body`          | 문자열            | 아니요       | 주석의 내용입니다. |
| `commit_id`     | 문자열            | 예      | 커밋의 SHA. |
| `discussion_id` | 문자열            | 예      | 스레드의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `note_id`       | 정수           | 예      | 스레드 note의 ID. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 업데이트된 note 객체를 반환합니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

note 해결:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>?resolved=true"
```

### 커밋 스레드 주석 삭제 {#delete-a-commit-discussion-note}

커밋의 기존 스레드 주석을 삭제합니다.

```plaintext
DELETE /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

지원하는 속성:

| 속성       | 유형              | 필수 | 설명 |
|-----------------|-------------------|----------|-------------|
| `commit_id`     | 문자열            | 예      | 커밋의 SHA. |
| `discussion_id` | 문자열            | 예      | 스레드의 ID. |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL-encoded path](rest/_index.md#namespaced-paths). |
| `note_id`       | 정수           | 예      | 스레드 note의 ID. |

성공하면 [`204 No Content`](rest/troubleshooting.md#status-codes)를 반환합니다.

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>"
```
