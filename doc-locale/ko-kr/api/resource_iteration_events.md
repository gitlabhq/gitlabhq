---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리소스 반복 이벤트 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [반복 이벤트](../user/group/iterations/_index.md)에 접근합니다.

## 이슈 {#issues}

### 프로젝트 이슈 반복 이벤트 나열 {#list-project-issue-iteration-events}

단일 이슈의 모든 반복 이벤트 목록을 가져옵니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_iteration_events
```

| 특성   | 유형           | 필수 | 설명                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid` | 정수        | 예      | 이슈의 IID                                                             |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_iteration_events"
```

예제 응답:

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
    "iteration":   {
      "id": 50,
      "iid": 9,
      "group_id": 5,
      "title": "Iteration I",
      "description": "Ipsum Lorem",
      "state": 1,
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null
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
    "iteration":   {
      "id": 53,
      "iid": 13,
      "group_id": 5,
      "title": "Iteration II",
      "description": "Ipsum Lorem ipsum",
      "state": 2,
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null
    },
    "action": "remove"
  }
]
```

### 이슈 반복 이벤트 검색 {#retrieve-an-issue-iteration-event}

지정된 프로젝트 이슈의 단일 반복 이벤트를 검색합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_iteration_events/:resource_iteration_event_id
```

매개 변수:

| 특성                     | 유형           | 필수 | 설명                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid`                   | 정수        | 예      | 이슈의 IID                                                             |
| `resource_iteration_event_id` | 정수        | 예      | 반복 이벤트의 ID                                                     |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_iteration_events/143"
```

예제 응답:

```json
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
  "iteration":   {
    "id": 53,
    "iid": 13,
    "group_id": 5,
    "title": "Iteration II",
    "description": "Ipsum Lorem ipsum",
    "state": 2,
    "created_at": "2020-01-27T05:07:12.573Z",
    "updated_at": "2020-01-27T05:07:12.573Z",
    "due_date": null,
    "start_date": null
  },
  "action": "remove"
}
```
