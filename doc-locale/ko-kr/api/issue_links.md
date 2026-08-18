---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 REST API 이슈 링크에 대한 설명서입니다.
title: 이슈 링크 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 간단한 "relates to" 관계가 [GitLab Free 13.4로 이동](https://gitlab.com/gitlab-org/gitlab/-/issues/212329)했습니다.

{{< /history >}}

이 API를 사용하여 [이슈 링크](../user/project/issues/related_issues.md)를 관리합니다.

## 모든 이슈 링크 나열 {#list-all-issue-links}

지정된 이슈에 대한 모든 [연결된 이슈](../user/project/issues/related_issues.md)를 관계 생성 시간(오름차순)으로 정렬하여 나열합니다. 이슈는 사용자 권한 부여에 따라 필터링됩니다.

```plaintext
GET /projects/:id/issues/:issue_iid/links
```

매개변수:

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈 내부 ID |

```json
[
  {
    "id" : 84,
    "iid" : 14,
    "issue_link_id": 1,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null,
    "link_type": "relates_to",
    "link_created_at": "2016-01-07T12:44:33.959Z",
    "link_updated_at": "2016-01-07T12:44:33.959Z"
  }
]
```

## 이슈 링크 검색 {#retrieve-an-issue-link}

{{< history >}}

- GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88228)되었습니다.
- `id` 응답 속성이 GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/585093)되었습니다.

{{< /history >}}

지정된 이슈 링크에 대한 세부 정보를 검색합니다.

```plaintext
GET /projects/:id/issues/:issue_iid/links/:issue_link_id
```

지원되는 속성:

| 속성       | 유형           | 필수               | 설명                                                                 |
|-----------------|----------------|------------------------|-----------------------------------------------------------------------------|
| `id`            | 정수 또는 문자열 | 예 | ID 또는 [프로젝트의 URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `issue_iid`     | 정수        | 예 | 프로젝트의 이슈 내부 ID입니다.                                           |
| `issue_link_id` | 정수 또는 문자열 | 예 | 이슈 링크 ID입니다.                                                |

응답 본문 속성:

| 속성      | 유형   | 설명                                                                               |
|:---------------|:-------|:------------------------------------------------------------------------------------------|
| `id`           | 정수 | 이슈 링크의 ID입니다.                                                                     |
| `source_issue` | 객체 | 관계의 소스 이슈에 대한 세부 정보입니다.                                          |
| `target_issue` | 객체 | 관계의 대상 이슈에 대한 세부 정보입니다.                                          |
| `link_type`    | 문자열 | 관계의 유형입니다. 가능한 값은 `relates_to`, `blocks` 및 `is_blocked_by`입니다. |

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/84/issues/14/links/1"
```

응답 예시:

```json
{
  "id": 1,
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```

## 이슈 링크 생성 {#create-an-issue-link}

{{< history >}}

- `id` 응답 속성이 GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/585093)되었습니다.

{{< /history >}}

두 이슈 간에 양방향 관계를 생성합니다. 사용자는 성공하려면 두 이슈를 모두 업데이트할 수 있어야 합니다.

```plaintext
POST /projects/:id/issues/:issue_iid/links
```

| 속성           | 유형           | 필수 | 설명                          |
|---------------------|----------------|----------|--------------------------------------|
| `id`                | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths) |
| `issue_iid`         | 정수        | 예      | 프로젝트의 이슈 내부 ID |
| `target_project_id` | 정수 또는 문자열 | 예      | 대상 프로젝트의 프로젝트 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)  |
| `target_issue_iid`  | 정수 또는 문자열 | 예      | 대상 프로젝트의 이슈 내부 ID |
| `link_type`         | 문자열         | 아니요       | 관계의 유형(`relates_to`, `blocks`, `is_blocked_by`)이며, 기본값은 `relates_to`)입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/1/links?target_project_id=5&target_issue_iid=1"
```

응답 예시:

```json
{
  "id": 1,
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```

## 이슈 링크 삭제 {#delete-an-issue-link}

{{< history >}}

- `id` 응답 속성이 GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/585093)되었습니다.

{{< /history >}}

지정된 이슈 링크를 삭제하고 양방향 관계를 제거합니다.

```plaintext
DELETE /projects/:id/issues/:issue_iid/links/:issue_link_id
```

| 속성   | 유형    | 필수 | 설명                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL 인코딩된 경로](rest/_index.md#namespaced-paths)  |
| `issue_iid` | 정수 | 예      | 프로젝트의 이슈 내부 ID |
| `issue_link_id` | 정수 또는 문자열 | 예      | 이슈 링크 관계의 ID |
| `link_type` | 문자열  | 아니요 | 관계의 유형(`relates_to`, `blocks`, `is_blocked_by`)이며, 기본값은 `relates_to` |

```json
{
  "id": 1,
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```
