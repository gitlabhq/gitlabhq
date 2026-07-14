---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "에픽과 함께 이슈를 나열, 연결 및 연결 해제하려면 에픽 이슈 API를 사용합니다."
title: 에픽 이슈 API (더 이상 사용되지 않음)
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Epics REST API는 GitLab 17.0에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) API v5에서 제거될 예정입니다. GitLab 17.4에서 18.0까지 [에픽의 새로운 모양](../user/group/epics/_index.md#epics-as-work-items)이 활성화되어 있거나 GitLab 18.1 이상에서는 대신 Work Items API를 사용하세요. 자세한 내용은 [에픽 API를 작업 항목으로 마이그레이션](graphql/epic_work_items_api_migration_guide.md)을 참조하세요. 이는 주요 변경 사항입니다.

에픽 이슈 API 엔드포인트에 대한 모든 API 호출은 인증되어야 합니다.

사용자가 그룹의 멤버가 아니고 그룹이 비공개인 경우, 해당 그룹에 대한 `GET` 요청은 `404` 상태 코드를 반환합니다.

에픽은 GitLab [Premium과 Ultimate](https://about.gitlab.com/pricing/)에서만 사용할 수 있습니다. Epics 기능을 사용할 수 없는 경우 `403` 상태 코드가 반환됩니다.

## 에픽에 대한 모든 이슈 나열 {#list-all-issues-for-an-epic}

지정된 에픽에 할당된 모든 이슈를 나열합니다.

응답은 [페이지로 나뉘며](rest/_index.md#pagination) 기본적으로 20개의 결과를 반환합니다.

```plaintext
GET /groups/:id/epics/:epic_iid/issues
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 정수 또는 문자열   | 예        | 에픽의 내부 ID입니다.  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues"
```

응답 예시:

```json
[
  {
    "id": 76,
    "iid": 6,
    "project_id": 8,
    "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description" : "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2017-11-15T13:39:24.670Z",
    "updated_at": "2018-01-04T10:49:19.506Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 8,
      "title": "v2.0",
      "description": "In tempore culpa inventore quo accusantium.",
      "state": "closed",
      "created_at": "2017-11-15T13:39:13.825Z",
      "updated_at": "2017-11-15T13:39:13.825Z",
      "due_date": null,
      "start_date": null
    },
    "assignees": [{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    }],
    "assignee": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "author": {
      "id": 13,
      "name": "Michell Johns",
      "username": "chris_hahn",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/30e3b2122ccd6b8e45e8e14a3ffb58fc?s=80&d=identicon",
      "web_url": "http://localhost:3001/chris_hahn"
    },
    "user_notes_count": 8,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "_links":{
      "self": "http://localhost:3001/api/v4/projects/8/issues/6",
      "notes": "http://localhost:3001/api/v4/projects/8/issues/6/notes",
      "award_emoji": "http://localhost:3001/api/v4/projects/8/issues/6/award_emoji",
      "project": "http://localhost:3001/api/v4/projects/8"
    },
    "epic_issue_id": 2
  }
]
```

> [!note]
> `assignee` 열은 더 이상 사용되지 않습니다. 이제 단일 크기의 `assignees` 배열입니다.

## 에픽에 이슈 할당 {#assign-an-issue-to-an-epic}

지정된 에픽에 이슈를 할당합니다. 이슈가 이미 다른 에픽에 속해 있으면 먼저 해당 에픽에서 할당 해제됩니다.

```plaintext
POST /groups/:id/epics/:epic_iid/issues/:issue_id
```

| 속성           | 유형             | 필수   | 설명                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 정수 또는 문자열   | 예        | 에픽의 내부 ID입니다.  |
| `issue_id`          | 정수 또는 문자열   | 예        | 이슈의 ID입니다.          |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/55"
```

응답 예시:

```json
{
  "id": 11,
  "epic": {
    "id": 30,
    "iid": 5,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null
  },
  "issue": {
    "id": 55,
    "iid": 13,
    "project_id": 8,
    "title": "Beatae laborum voluptatem voluptate eligendi ex accusamus.",
    "description": "Quam veritatis debitis omnis aliquam sit.",
    "state": "opened",
    "created_at": "2017-11-05T13:59:12.782Z",
    "updated_at": "2018-01-05T10:33:03.900Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 48,
      "iid": 6,
      "project_id": 8,
      "title": "Sprint - Sed sed maxime temporibus ipsa ullam qui sit.",
      "description": "Quos veritatis qui expedita sunt deleniti accusamus.",
      "state": "active",
      "created_at": "2017-11-05T13:59:12.445Z",
      "updated_at": "2017-11-05T13:59:12.445Z",
      "due_date": "2017-11-13",
      "start_date": "2017-11-05"
    },
    "assignees": [{
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    }],
    "assignee": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "author": {
      "id": 25,
      "name": "User 3",
      "username": "user3",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "http://localhost:3001/user3"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/13",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
}
```

> [!note]
> `assignee` 열은 더 이상 사용되지 않습니다. 이제 단일 크기의 `assignees` 배열입니다.

## 에픽에서 이슈 제거 {#remove-an-issue-from-an-epic}

지정된 에픽에서 이슈를 제거합니다.

```plaintext
DELETE /groups/:id/epics/:epic_iid/issues/:epic_issue_id
```

| 속성           | 유형             | 필수   | 설명                                                                                          |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 정수 또는 문자열   | 예        | 에픽의 내부 ID입니다.                |
| `epic_issue_id`     | 정수 또는 문자열   | 예        | 에픽-이슈 연결의 ID입니다.     |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/11"
```

응답 예시:

```json
{
  "id": 11,
  "epic": {
    "id": 30,
    "iid": 5,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null
  },
  "issue": {
    "id": 223,
    "iid": 13,
    "project_id": 8,
    "title": "Beatae laborum voluptatem voluptate eligendi ex accusamus.",
    "description": "Quam veritatis debitis omnis aliquam sit.",
    "state": "opened",
    "created_at": "2017-11-05T13:59:12.782Z",
    "updated_at": "2018-01-05T10:33:03.900Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 48,
      "iid": 6,
      "project_id": 8,
      "title": "Sprint - Sed sed maxime temporibus ipsa ullam qui sit.",
      "description": "Quos veritatis qui expedita sunt deleniti accusamus.",
      "state": "active",
      "created_at": "2017-11-05T13:59:12.445Z",
      "updated_at": "2017-11-05T13:59:12.445Z",
      "due_date": "2017-11-13",
      "start_date": "2017-11-05"
    },
    "assignees": [{
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    }],
    "assignee": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "author": {
      "id": 25,
      "name": "User 3",
      "username": "user3",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "http://localhost:3001/user3"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/13",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
}
```

> [!note]
> `assignee` 열은 더 이상 사용되지 않습니다. 이제 단일 크기의 `assignees` 배열입니다.

## 에픽-이슈 연결 업데이트 {#update-an-epic-issue-association}

에픽-이슈 연결을 업데이트합니다.

```plaintext
PUT /groups/:id/epics/:epic_iid/issues/:epic_issue_id
```

| 속성           | 유형             | 필수   | 설명                                                                                          |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------|
| `id`                | 정수 또는 문자열   | 예        | 그룹의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 정수 또는 문자열   | 예        | 에픽의 내부 ID입니다.                |
| `epic_issue_id`     | 정수 또는 문자열   | 예        | 에픽-이슈 연결의 ID입니다.     |
| `move_before_id`    | 정수 또는 문자열   | 아니요         | 질문의 링크 앞에 배치해야 하는 에픽-이슈 연결의 ID입니다.     |
| `move_after_id`     | 정수 또는 문자열   | 아니요         | 질문의 링크 뒤에 배치해야 하는 에픽-이슈 연결의 ID입니다.     |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/11?move_before_id=20"
```

응답 예시:

```json
[
  {
    "id": 30,
    "iid": 6,
    "project_id": 8,
    "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description" : "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2017-11-15T13:39:24.670Z",
    "updated_at": "2018-01-04T10:49:19.506Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 8,
      "title": "v2.0",
      "description": "In tempore culpa inventore quo accusantium.",
      "state": "closed",
      "created_at": "2017-11-15T13:39:13.825Z",
      "updated_at": "2017-11-15T13:39:13.825Z",
      "due_date": null,
      "start_date": null
    },
    "assignees": [{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    }],
    "assignee": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "author": {
      "id": 13,
      "name": "Michell Johns",
      "username": "chris_hahn",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/30e3b2122ccd6b8e45e8e14a3ffb58fc?s=80&d=identicon",
      "web_url": "http://localhost:3001/chris_hahn"
    },
    "user_notes_count": 8,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "_links":{
      "self": "http://localhost:3001/api/v4/projects/8/issues/6",
      "notes": "http://localhost:3001/api/v4/projects/8/issues/6/notes",
      "award_emoji": "http://localhost:3001/api/v4/projects/8/issues/6/award_emoji",
      "project": "http://localhost:3001/api/v4/projects/8"
    },
    "subscribed": true,
    "epic_issue_id": 11,
    "relative_position": 55
  }
]
```
