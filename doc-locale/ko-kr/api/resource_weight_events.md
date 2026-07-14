---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리소스 가중치 이벤트 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 이슈의 가중치 변경 이벤트에 액세스합니다.

## 이슈 {#issues}

### 모든 프로젝트 이슈 가중치 이벤트 나열 {#list-all-project-issue-weight-events}

단일 이슈의 모든 가중치 이벤트를 나열합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_weight_events
```

| 속성   | 유형           | 필수 | 설명                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid` | 정수        | 예      | 이슈의 IID                                                             |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_weight_events"
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
    "issue_id": 253,
    "weight": 3
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
    "issue_id": 253,
    "weight": 2
  }
]
```

### 단일 이슈 가중치 이벤트 검색 {#retrieve-single-issue-weight-event}

특정 프로젝트 이슈의 단일 가중치 이벤트를 검색합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_weight_events/:resource_weight_event_id
```

매개변수:

| 속성                     | 유형           | 필수 | 설명                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid`                   | 정수        | 예      | 이슈의 IID                                                             |
| `resource_weight_event_id`    | 정수        | 예      | 가중치 이벤트의 ID                                                     |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_weight_events/143"
```

응답 예시:

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
"issue_id": 253,
"weight": 2
}
```
