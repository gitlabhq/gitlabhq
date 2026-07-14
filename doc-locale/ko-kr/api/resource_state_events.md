---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리소스 상태 이벤트 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 이슈, 머지 리퀘스트 및 에픽에 대한 상태 변경 이벤트와 상호 작용합니다.

이 API는 리소스의 초기 상태(`created` 또는 `opened`)를 추적하지 않습니다. 닫히거나 다시 열리지 않은 리소스의 경우 빈 목록이 반환됩니다.

## 이슈 {#issues}

### 프로젝트 이슈 상태 이벤트 나열 {#list-project-issue-state-events}

단일 이슈의 모든 상태 이벤트를 나열합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events
```

| 특성   | 유형           | 필수 | 설명                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid` | 정수        | 예      | 이슈의 IID                                                             |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_state_events"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### 단일 이슈 상태 이벤트 검색 {#retrieve-a-single-issue-state-event}

특정 프로젝트 이슈의 단일 상태 이벤트를 검색합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events/:resource_state_event_id
```

매개 변수:

| 특성                     | 유형           | 필수 | 설명                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid`                   | 정수        | 예      | 이슈의 IID                                                             |
| `resource_state_event_id`     | 정수        | 예      | 상태 이벤트의 ID                                                     |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_state_events/143"
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
  "resource_type": "Issue",
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```

## 머지 리퀘스트 {#merge-requests}

### 프로젝트 머지 리퀘스트 상태 이벤트 나열 {#list-project-merge-request-state-events}

단일 머지 리퀘스트의 모든 상태 이벤트를 나열합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_state_events
```

| 특성           | 유형           | 필수 | 설명                                                                     |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 정수        | 예      | 머지 리퀘스트의 IID                                                      |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_state_events"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### 단일 머지 리퀘스트 상태 이벤트 검색 {#retrieve-a-single-merge-request-state-event}

특정 프로젝트 머지 리퀘스트의 단일 상태 이벤트를 검색합니다.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_state_events/:resource_state_event_id
```

매개 변수:

| 특성                     | 유형           | 필수 | 설명                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | 정수        | 예      | 머지 리퀘스트의 IID                                                      |
| `resource_state_event_id`     | 정수        | 예      | 상태 이벤트의 ID                                                     |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_state_events/120"
```

응답 예시:

```json
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
  "created_at": "2018-08-21T14:38:20.077Z",
  "resource_type": "MergeRequest",
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```

## 에픽 {#epics}

{{< history >}}

- [GitLab 15.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97554)

{{< /history >}}

> [!warning]
> Epics REST API는 GitLab 17.0에서 [지원 중단되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) API의 v5에서 제거될 예정입니다. GitLab 17.4부터 18.0까지 [에픽의 새로운 모양](../user/group/epics/_index.md#epics-as-work-items)이 활성화되어 있으면 GitLab 18.1 이상에서는 대신 Work Items API를 사용합니다. 자세한 내용은 [에픽 API를 작업 항목으로 마이그레이션](graphql/epic_work_items_api_migration_guide.md)을 참조하세요. 이 변경은 주요 변경 사항입니다.

### 그룹 에픽 상태 이벤트 나열 {#list-group-epic-state-events}

단일 에픽의 모든 상태 이벤트를 나열합니다.

```plaintext
GET /groups/:id/epics/:epic_id/resource_state_events
```

| 특성   | 유형           | 필수 | 설명                                                                    |
|-------------| -------------- | -------- |--------------------------------------------------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)   |
| `epic_id`   | 정수        | 예      | 에픽의 ID                                                              |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/resource_state_events"
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
    "resource_type": "Epic",
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_type": "Epic",
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### 단일 에픽 상태 이벤트 검색 {#retrieve-a-single-epic-state-event}

단일 에픽 상태 이벤트를 검색합니다.

```plaintext
GET /groups/:id/epics/:epic_id/resource_state_events/:resource_state_event_id
```

매개 변수:

| 특성                 | 유형           | 필수 | 설명                                                                   |
|---------------------------| -------------- | -------- |-------------------------------------------------------------------------------|
| `id`                      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)  |
| `epic_id`                 | 정수        | 예      | 에픽의 ID                                                           |
| `resource_state_event_id` | 정수        | 예      | 상태 이벤트의 ID                                                       |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/resource_state_events/143"
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
  "resource_type": "Epic",
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```
