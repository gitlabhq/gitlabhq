---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 할 일 목록 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [할 일 항목](../user/todos.md)과 상호작용합니다.

## 모든 할 일 항목 나열 {#list-all-to-do-items}

모든 할 일 항목을 나열합니다. 필터를 적용하지 않으면 현재 사용자의 모든 보류 중인 할 일 항목을 반환합니다. 다양한 필터를 통해 사용자는 요청을 세분화할 수 있습니다.

```plaintext
GET /todos
```

매개변수:

| 속성 | 유형 | 필수 | 설명                                                                                                                                                                                        |
| --------- | ---- | -------- |----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `action` | 문자열 | 아니요 | 필터링할 작업입니다. `assigned`, `mentioned`, `build_failed`, `marked`, `approval_required`, `unmergeable`, `directly_addressed`, `merge_train_removed` 또는 `member_access_requested`일 수 있습니다. |
| `author_id` | 정수 | 아니요 | 작성자의 ID                                                                                                                                                                                |
| `project_id` | 정수 | 아니요 | 프로젝트의 ID                                                                                                                                                                                |
| `group_id` | 정수 | 아니요 | 그룹의 ID                                                                                                                                                                                  |
| `state` | 문자열 | 아니요 | 할 일 항목의 상태입니다. `pending` 또는 `done`일 수 있습니다                                                                                                                                     |
| `type` | 문자열 | 아니요 | 할 일 항목의 유형입니다. `Issue`, `MergeRequest`, `Commit`, `Epic`, `DesignManagement::Design`, `AlertManagement::Alert`, `Project`, `Namespace`, `Vulnerability` 또는 `WikiPage::Meta`일 수 있습니다.  |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/todos"
```

응답 예시:

```json
[
  {
    "id": 102,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
    },
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "action_name": "marked",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "pending",
    "created_at": "2016-06-17T07:52:35.225Z",
    "updated_at": "2016-06-17T07:52:35.225Z"
  },
  {
    "id": 98,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
    },
    "author": {
      "name": "Maxie Medhurst",
      "username": "craig_rutherford",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/craig_rutherford"
    },
    "action_name": "assigned",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "pending",
    "created_at": "2016-06-17T07:49:24.624Z",
    "updated_at": "2016-06-17T07:49:24.624Z"
  }
]
```

## 할 일 항목을 완료됨으로 표시 {#mark-a-to-do-item-as-done}

현재 사용자를 위해 ID로 지정된 단일 보류 중인 할 일 항목을 완료됨으로 표시합니다. 완료됨으로 표시된 할 일 항목이 응답으로 반환됩니다.

```plaintext
POST /todos/:id/mark_as_done
```

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 | 예 | 할 일 항목의 ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/todos/130/mark_as_done"
```

응답 예시:

```json
{
    "id": 102,
    "project": {
      "id": 2,
      "name": "Gitlab Ce",
      "name_with_namespace": "Gitlab Org / Gitlab Ce",
      "path": "gitlab-foss",
      "path_with_namespace": "gitlab-org/gitlab-foss"
    },
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "action_name": "marked",
    "target_type": "MergeRequest",
    "target": {
      "id": 34,
      "iid": 7,
      "project_id": 2,
      "title": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
      "description": "Et ea et omnis illum cupiditate. Dolor aspernatur tenetur ducimus facilis est nihil. Quo esse cupiditate molestiae illo corrupti qui quidem dolor.",
      "state": "opened",
      "created_at": "2016-06-17T07:49:24.419Z",
      "updated_at": "2016-06-17T07:52:43.484Z",
      "target_branch": "tutorials_git_tricks",
      "source_branch": "DNSBL_docs",
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "name": "Maxie Medhurst",
        "username": "craig_rutherford",
        "id": 12,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/craig_rutherford"
      },
      "assignee": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
      },
      "source_project_id": 2,
      "target_project_id": 2,
      "labels": [],
      "draft": false,
      "work_in_progress": false,
      "milestone": {
        "id": 32,
        "iid": 2,
        "project_id": 2,
        "title": "v1.0",
        "description": "Assumenda placeat ea voluptatem voluptate qui.",
        "state": "active",
        "created_at": "2016-06-17T07:47:34.163Z",
        "updated_at": "2016-06-17T07:47:34.163Z",
        "due_date": null
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "subscribed": true,
      "user_notes_count": 7
    },
    "target_url": "https://gitlab.example.com/gitlab-org/gitlab-foss/-/merge_requests/7",
    "body": "Dolores in voluptatem tenetur praesentium omnis repellendus voluptatem quaerat.",
    "state": "done",
    "created_at": "2016-06-17T07:52:35.225Z",
    "updated_at": "2016-06-17T07:52:35.225Z"
}
```

## 모든 할 일 항목을 완료됨으로 표시 {#mark-all-to-do-items-as-done}

현재 사용자를 위해 모든 보류 중인 할 일 항목을 완료됨으로 표시합니다. HTTP 상태 코드 `204`을 빈 응답과 함께 반환합니다.

```plaintext
POST /todos/mark_as_done
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/todos/mark_as_done"
```
