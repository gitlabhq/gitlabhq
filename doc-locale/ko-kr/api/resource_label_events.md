---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리소스 레이블 이벤트 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [레이블](../user/project/labels.md)이 이슈, 머지 리퀘스트 또는 에픽에 추가되었거나 제거된 경우 누가, 언제, 어떤 것인지 추적하는 리소스 레이블 이벤트를 검색합니다.

## 이슈 {#issues}

### 프로젝트 이슈 레이블 이벤트 목록 {#list-project-issue-label-events}

단일 이슈의 모든 레이블 이벤트를 나열합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_label_events
```

| 속성           | 유형             | 필수   | 설명  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid`         | 정수          | 예        | 이슈의 IID |

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
    "label": {
      "id": 73,
      "name": "a1",
      "color": "#34495E",
      "description": ""
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
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "label": {
      "id": 74,
      "name": "p1",
      "color": "#0033CC",
      "description": ""
    },
    "action": "remove"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_label_events"
```

### 단일 이슈 레이블 이벤트 검색 {#retrieve-a-single-issue-label-event}

특정 프로젝트 이슈에 대한 단일 레이블 이벤트를 검색합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_label_events/:resource_label_event_id
```

매개변수:

| 속성       | 유형           | 필수 | 설명 |
| --------------- | -------------- | -------- | ----------- |
| `id`            | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid`     | 정수        | 예      | 이슈의 IID |
| `resource_label_event_id` | 정수        | 예      | 레이블 이벤트의 ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_label_events/1"
```

## 에픽 {#epics}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Epics REST API는 GitLab 17.0에서 [지원 중단](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)되었으며 API의 v5에서 제거될 예정입니다. GitLab 17.4에서 18.0까지 [에픽의 새로운 모양](../user/group/epics/_index.md#epics-as-work-items)이 활성화되어 있는 경우, GitLab 18.1 이상에서는 대신 Work Items API를 사용합니다. 자세한 내용은 [에픽 API를 작업 항목으로 마이그레이션](graphql/epic_work_items_api_migration_guide.md)을 참조하세요. 이는 주요 변경 사항입니다.

### 그룹 에픽 레이블 이벤트 목록 {#list-group-epic-label-events}

단일 에픽의 모든 레이블 이벤트를 나열합니다.

```plaintext
GET /groups/:id/epics/:epic_id/resource_label_events
```

| 속성           | 유형             | 필수   | 설명  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `epic_id`           | 정수          | 예        | 에픽의 ID |

```json
[
  {
    "id": 106,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-19T11:43:01.746Z",
    "resource_type": "Epic",
    "resource_id": 33,
    "label": {
      "id": 73,
      "name": "a1",
      "color": "#34495E",
      "description": ""
    },
    "action": "add"
  },
  {
    "id": 107,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-19T11:43:01.746Z",
    "resource_type": "Epic",
    "resource_id": 33,
    "label": {
      "id": 37,
      "name": "glabel2",
      "color": "#A8D695",
      "description": ""
    },
    "action": "add"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/11/resource_label_events"
```

### 단일 에픽 레이블 이벤트 검색 {#retrieve-a-single-epic-label-event}

특정 그룹 에픽에 대한 단일 레이블 이벤트를 검색합니다.

```plaintext
GET /groups/:id/epics/:epic_id/resource_label_events/:resource_label_event_id
```

매개변수:

| 속성       | 유형           | 필수 | 설명 |
| --------------- | -------------- | -------- | ----------- |
| `id`            | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `epic_id`       | 정수        | 예      | 에픽의 ID |
| `resource_label_event_id` | 정수        | 예      | 레이블 이벤트의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/11/resource_label_events/107"
```

## 머지 리퀘스트 {#merge-requests}

### 프로젝트 머지 리퀘스트 레이블 이벤트 목록 {#list-project-merge-request-label-events}

단일 머지 리퀘스트의 모든 레이블 이벤트를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_label_events
```

| 속성           | 유형             | 필수   | 설명  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | 정수 또는 문자열   | 예        | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수          | 예        | 머지 리퀘스트의 IID |

```json
[
  {
    "id": 119,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T06:17:28.394Z",
    "resource_type": "MergeRequest",
    "resource_id": 28,
    "label": {
      "id": 74,
      "name": "p1",
      "color": "#0033CC",
      "description": ""
    },
    "action": "add"
  },
  {
    "id": 120,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T06:17:28.394Z",
    "resource_type": "MergeRequest",
    "resource_id": 28,
    "label": {
      "id": 41,
      "name": "project",
      "color": "#D1D100",
      "description": ""
    },
    "action": "add"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_label_events"
```

### 단일 머지 리퀘스트 레이블 이벤트 검색 {#retrieve-a-single-merge-request-label-event}

특정 프로젝트 머지 리퀘스트에 대한 단일 레이블 이벤트를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_label_events/:resource_label_event_id
```

매개변수:

| 속성           | 유형           | 필수 | 설명 |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수        | 예      | 머지 리퀘스트의 IID |
| `resource_label_event_id`     | 정수        | 예      | 레이블 이벤트의 ID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_label_events/120"
```
