---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
title: Events API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [도입](https://gitlab.com/groups/gitlab-org/-/epics/13056)된 `epics` 대상 유형이 GitLab 17.3에 추가되었습니다.

{{< /history >}}

이 API를 사용하여 이벤트 활동을 검토합니다. 이벤트는 프로젝트 참여, 이슈 댓글, MR에 변경 사항 푸시 또는 에픽 종료 등 다양한 작업을 포함할 수 있습니다.

활동 보관 제한에 대한 정보는 다음을 참조하십시오:

- [사용자 활동 기간 제한](../user/profile/contributions_calendar.md#event-time-period-limit)
- [프로젝트 활동 기간 제한](../user/project/working_with_projects.md#view-project-activity)

이 API에는 에픽, 머지 리퀘스트 및 대량 푸시 이벤트와 관련된 제한이 있습니다:

- 에픽의 하위 항목, 연결된 항목, 시작 날짜, 기한 및 상태 같은 일부 기능은 API에서 반환되지 않습니다.
- 일부 머지 리퀘스트 댓글은 대신 `DiscussionNote` 유형을 사용할 수 있습니다. 이 대상 유형은 [API에서 지원되지 않습니다](discussions.md#understand-note-types-in-the-api).
- 푸시가 [푸시 이벤트 활동 제한](../administration/settings/push_event_activities_limit.md)을 초과할 때 생성된 대량 푸시 이벤트는 제한된 세부 정보로 반환됩니다: `commit_count: 0`, 푸시된 ref 수를 표시하는 `ref_count`, 개별 커밋 특성에 대한 `null` 값(`commit_from`, `commit_to`, `ref`, `commit_title`).

## 모든 이벤트 나열 {#list-all-events}

인증된 사용자의 모든 이벤트를 나열합니다. 에픽 또는 머지 리퀘스트와 연결된 이벤트는 반환하지 않습니다. 제한된 커밋 세부 정보가 있는 대량 푸시 이벤트를 반환합니다.

전제 조건:

- 액세스 토큰에 `read_user` 또는 `api` 범위가 있어야 합니다.

```plaintext
GET /events
```

매개변수:

| 매개변수     | 유형            | 필수 | 설명 |
| ------------- | --------------- | -------- | ----------- |
| `action`      | 문자열          | 아니요       | 지정된 [작업 유형](../user/profile/contributions_calendar.md#user-contribution-events)으로 이벤트를 반환합니다. |
| `target_type` | 문자열          | 아니요       | 지정된 이벤트를 반환합니다. 가능한 값: `epic`, `issue`, `merge_request`, `milestone`, `note`, `project`, `snippet` 및 `user`. |
| `before`      | 날짜 (ISO 8601) | 아니요       | 지정된 날짜 이전에 생성된 이벤트를 반환합니다. |
| `after`       | 날짜 (ISO 8601) | 아니요       | 지정된 날짜 이후에 생성된 이벤트를 반환합니다. |
| `scope`       | 문자열          | 아니요       | 사용자의 프로젝트 전체에서 모든 이벤트를 포함합니다. |
| `sort`        | 문자열          | 아니요       | 생성 날짜별로 결과를 정렬하는 방향입니다. 가능한 값: `asc`, `desc`. 기본값: `desc`. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01&scope=all"
```

응답 예시:

```json
[
  {
    "id": 1,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 160,
    "target_iid": 53,
    "target_type": "Issue",
    "author_id": 25,
    "target_title": "Qui natus eos odio tempore et quaerat consequuntur ducimus cupiditate quis.",
    "created_at": "2017-02-09T10:43:19.667Z",
    "author": {
      "name": "User 3",
      "username": "user3",
      "id": 25,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/user3"
    },
    "author_username": "user3",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 2,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 159,
    "target_iid": 14,
    "target_type": "Issue",
    "author_id": 21,
    "target_title": "Nostrum enim non et sed optio illo deleniti non.",
    "created_at": "2017-02-09T10:43:19.426Z",
    "author": {
      "name": "Test User",
      "username": "ted",
      "id": 21,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/80fb888c9a48b9a3f87477214acaa63f?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/ted"
    },
    "author_username": "ted",
    "imported": false,
    "imported_from": "none"
  }
]
```

## 사용자의 기여 이벤트 검색 {#retrieve-contribution-events-for-a-user}

지정된 사용자의 기여 이벤트를 검색합니다. 에픽 또는 머지 리퀘스트와 연결된 이벤트는 반환하지 않습니다. 제한된 커밋 세부 정보가 있는 대량 푸시 이벤트를 반환합니다.

전제 조건:

- 액세스 토큰에 `read_user` 또는 `api` 범위가 있어야 합니다.

```plaintext
GET /users/:id/events
```

매개변수:

| 매개변수     | 유형            | 필수 | 설명 |
| ------------- | --------------- | -------- | ----------- |
| `id`          | 정수         | 예      | 사용자의 ID 또는 사용자 이름입니다. |
| `action`      | 문자열          | 아니요       | 지정된 [작업 유형](../user/profile/contributions_calendar.md#user-contribution-events)으로 이벤트를 반환합니다. |
| `target_type` | 문자열          | 아니요       | 지정된 이벤트를 반환합니다. 가능한 값: `epic`, `issue`, `merge_request`, `milestone`, `note`, `project`, `snippet` 및 `user`. |
| `before`      | 날짜 (ISO 8601) | 아니요       | 지정된 날짜 이전에 생성된 이벤트를 반환합니다. |
| `after`       | 날짜 (ISO 8601) | 아니요       | 지정된 날짜 이후에 생성된 이벤트를 반환합니다. |
| `sort`        | 문자열          | 아니요       | 생성 날짜별로 결과를 정렬하는 방향입니다. 가능한 값: `asc`, `desc`. 기본값: `desc`. |
| `page`        | 정수         | 아니요       | 지정된 결과 페이지를 반환합니다. 기본값: `1`. |
| `per_page`    | 정수         | 아니요       | 페이지당 결과 수입니다. 기본값: `20`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/:id/events"
```

응답 예시:

```json
[
  {
    "id": 3,
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 830,
    "target_iid": 82,
    "target_type": "Issue",
    "author_id": 1,
    "target_title": "Public project search field",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 4,
    "title": null,
    "project_id": 15,
    "action_name": "pushed",
    "target_id": null,
    "target_iid": null,
    "target_type": null,
    "author_id": 1,
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "john",
    "imported": false,
    "imported_from": "none",
    "push_data": {
      "commit_count": 1,
      "action": "pushed",
      "ref_type": "branch",
      "commit_from": "50d4420237a9de7be1304607147aec22e4a14af7",
      "commit_to": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "ref": "main",
      "commit_title": "Add simple search to projects in public area"
    },
    "target_title": null
  },
  {
    "id": 5,
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 840,
    "target_iid": 11,
    "target_type": "Issue",
    "author_id": 1,
    "target_title": "Finish & merge Code search PR",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 7,
    "title": null,
    "project_id": 15,
    "action_name": "commented on",
    "target_id": 1312,
    "target_iid": 61,
    "target_type": "Note",
    "author_id": 1,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "http://localhost:3000/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "noteable_id": 377,
      "noteable_type": "Issue"
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  }
]
```

## 프로젝트의 모든 표시된 이벤트 나열 {#list-all-visible-events-for-a-project}

지정된 프로젝트의 모든 표시된 이벤트를 나열합니다. 푸시가 [푸시 이벤트 활동 제한](../administration/settings/push_event_activities_limit.md)을 초과할 때 생성된 대량 푸시 이벤트를 제한된 커밋 세부 정보로 반환합니다: `commit_count: 0`, 푸시된 ref 수를 표시하는 `ref_count`, 개별 커밋 특성에 대한 `null` 값.

```plaintext
GET /projects/:project_id/events
```

매개변수:

| 매개변수     | 유형            | 필수 | 설명 |
| ------------- | --------------- | -------- | ----------- |
| `project_id`  | 정수 또는 문자열  | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `action`      | 문자열          | 아니요       | 지정된 [작업 유형](../user/profile/contributions_calendar.md#user-contribution-events)으로 이벤트를 반환합니다. |
| `target_type` | 문자열          | 아니요       | 지정된 이벤트를 반환합니다. 가능한 값: `epic`, `issue`, `merge_request`, `milestone`, `note`, `project`, `snippet` 및 `user`. |
| `before`      | 날짜 (ISO 8601) | 아니요       | 지정된 날짜 이전에 생성된 이벤트를 반환합니다. |
| `after`       | 날짜 (ISO 8601) | 아니요       | 지정된 날짜 이후에 생성된 이벤트를 반환합니다. |
| `sort`        | 문자열          | 아니요       | 생성 날짜별로 결과를 정렬하는 방향입니다. 가능한 값: `asc`, `desc`. 기본값: `desc`. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:project_id/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01"
```

응답 예시:

```json
[
  {
    "id": 8,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 160,
    "target_iid": 160,
    "target_type": "Issue",
    "author_id": 25,
    "target_title": "Qui natus eos odio tempore et quaerat consequuntur ducimus cupiditate quis.",
    "created_at": "2017-02-09T10:43:19.667Z",
    "author": {
      "name": "User 3",
      "username": "user3",
      "id": 25,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/user3"
    },
    "author_username": "user3",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 9,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 159,
    "target_iid": 159,
    "target_type": "Issue",
    "author_id": 21,
    "target_title": "Nostrum enim non et sed optio illo deleniti non.",
    "created_at": "2017-02-09T10:43:19.426Z",
    "author": {
      "name": "Test User",
      "username": "ted",
      "id": 21,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/80fb888c9a48b9a3f87477214acaa63f?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/ted"
    },
    "author_username": "ted",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 10,
    "title": null,
    "project_id": 1,
    "action_name": "commented on",
    "target_id": 1312,
    "target_iid": 1312,
    "target_type": "Note",
    "author_id": 1,
    "data": null,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "https://gitlab.example.com/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "https://gitlab.example.com/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "noteable_id": 377,
      "noteable_type": "Issue",
      "noteable_iid": 377
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "https://gitlab.example.com/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  }
]
```
