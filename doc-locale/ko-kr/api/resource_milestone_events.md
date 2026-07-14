---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리소스 마일스톤 이벤트 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 이슈 및 머지 리퀘스트의 마일스톤 이벤트와 상호작용합니다.

## 이슈 {#issues}

### 프로젝트 이슈 마일스톤 이벤트 나열 {#list-project-issue-milestone-events}

단일 이슈의 모든 마일스톤 이벤트를 나열합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_milestone_events
```

| 속성   | 유형           | 필수 | 설명                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid` | 정수        | 예      | 이슈의 IID                                                             |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_milestone_events"
```

응답 예시:

```json
[
  {
    "id": 142,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "add"
  },
  {
    "id": 143,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "remove"
  }
]
```

### 단일 이슈 마일스톤 이벤트 검색 {#retrieve-a-single-issue-milestone-event}

특정 프로젝트 이슈에 대한 단일 마일스톤 이벤트를 검색합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_milestone_events/:resource_milestone_event_id
```

매개변수:

| 속성                     | 유형           | 필수 | 설명                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `issue_iid`                   | 정수        | 예      | 이슈의 IID                                                             |
| `resource_milestone_event_id` | 정수        | 예      | 마일스톤 이벤트의 ID                                                     |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_milestone_events/1"
```

## 머지 리퀘스트 {#merge-requests}

### 프로젝트 머지 리퀘스트 마일스톤 이벤트 나열 {#list-project-merge-request-milestone-events}

단일 머지 리퀘스트의 모든 마일스톤 이벤트를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_milestone_events
```

| 속성           | 유형           | 필수 | 설명                                                                     |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수        | 예      | 머지 리퀘스트의 IID                                                      |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_milestone_events"
```

응답 예시:

```json
[
  {
    "id": 142,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "MergeRequest",
    "resource_id": 142,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "add"
  },
  {
    "id": 143,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "MergeRequest",
    "resource_id": 142,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "remove"
  }
]
```

### 단일 머지 리퀘스트 마일스톤 이벤트 검색 {#retrieve-a-single-merge-request-milestone-event}

특정 프로젝트 머지 리퀘스트에 대한 단일 마일스톤 이벤트를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_milestone_events/:resource_milestone_event_id
```

매개변수:

| 속성                     | 유형           | 필수 | 설명                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | 정수        | 예      | 머지 리퀘스트의 IID                                                      |
| `resource_milestone_event_id` | 정수        | 예      | 마일스톤 이벤트의 ID                                                     |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_milestone_events/120"
```
