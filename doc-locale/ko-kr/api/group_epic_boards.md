---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 에픽 보드 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9에서 [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/385903).

{{< /history >}}

이 API를 사용하여 [그룹 에픽 보드](../user/group/epics/epic_boards.md)를 관리합니다. 이 API에 대한 모든 요청은 인증되어야 합니다.

사용자가 그룹의 멤버가 아니고 그룹이 비공개인 경우, `GET` 요청으로 인해 `404` 상태 코드가 반환됩니다.

## 그룹의 모든 에픽 보드 나열 {#list-all-epic-boards-in-a-group}

지정된 그룹의 모든 에픽 보드를 나열합니다.

```plaintext
GET /groups/:id/epic_boards
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예 | 인증된 사용자가 액세스할 수 있는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epic_boards"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "group epic board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "labels": [
      {
        "id": 1,
        "title": "Board Label",
        "color": "#c21e56",
        "description": "label applied to the epic board",
        "group_id": 5,
        "project_id": null,
        "template": false,
        "text_color": "#FFFFFF",
        "created_at": "2023-01-27T10:40:59.738Z",
        "updated_at": "2023-01-27T10:40:59.738Z"
      }
    ],
    "lists": [
      {
        "id": 1,
        "label": {
          "id": 69,
          "name": "Testing",
          "color": "#F0AD4E",
          "description": null
        },
        "position": 1,
        "list_type": "label"
      },
      {
        "id": 2,
        "label": {
          "id": 70,
          "name": "Ready",
          "color": "#FF0000",
          "description": null
        },
        "position": 2,
        "list_type": "label"
      },
      {
        "id": 3,
        "label": {
          "id": 71,
          "name": "Production",
          "color": "#FF5F00",
          "description": null
        },
        "position": 3,
        "list_type": "label"
      }
    ]
  }
]
```

## 그룹 에픽 보드 검색 {#retrieve-a-group-epic-board}

지정된 그룹 에픽 보드를 검색합니다.

```plaintext
GET /groups/:id/epic_boards/:board_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 인증된 사용자가 액세스할 수 있는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `board_id` | 정수 | 예 | 에픽 보드의 ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epic_boards/1"
```

응답 예시:

```json
  {
    "id": 1,
    "name": "group epic board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "labels": [
      {
        "id": 1,
        "title": "Board Label",
        "color": "#c21e56",
        "description": "label applied to the epic board",
        "group_id": 5,
        "project_id": null,
        "template": false,
        "text_color": "#FFFFFF",
        "created_at": "2023-01-27T10:40:59.738Z",
        "updated_at": "2023-01-27T10:40:59.738Z"
      }
    ],
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "id": 69,
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1,
        "list_type": "label"
      },
      {
        "id" : 2,
        "label" : {
          "id": 70,
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "list_type": "label"
      },
      {
        "id" : 3,
        "label" : {
          "id": 71,
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "list_type": "label"
      }
    ]
  }
```

## 그룹 에픽 보드 목록 나열 {#list-group-epic-board-lists}

{{< history >}}

- GitLab 15.9에서 [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/385904).

{{< /history >}}

지정된 보드의 모든 그룹 에픽 보드 목록을 나열합니다. `open` 및 `closed` 목록은 포함되지 않습니다.

```plaintext
GET /groups/:id/epic_boards/:board_id/lists
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 인증된 사용자가 액세스할 수 있는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `board_id` | 정수 | 예 | 에픽 보드의 ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epic_boards/1/lists"
```

응답 예시:

```json
[
  {
    "id" : 1,
    "label" : {
      "name" : "Testing",
      "color" : "#F0AD4E",
      "description" : null
    },
    "position" : 1,
    "list_type" : "label",
    "collapsed" : false
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2,
    "list_type" : "label",
    "collapsed" : false
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3,
    "list_type" : "label",
    "collapsed" : false
  }
]
```

## 그룹 에픽 보드 목록 검색 {#retrieve-a-group-epic-board-list}

{{< history >}}

- GitLab 15.9에서 [소개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/385904).

{{< /history >}}

지정된 그룹 에픽 보드 목록을 검색합니다.

```plaintext
GET /groups/:id/epic_boards/:board_id/lists/:list_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 인증된 사용자가 액세스할 수 있는 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `board_id` | 정수 | 예 | 에픽 보드의 ID |
| `list_id` | 정수 | 예 | 에픽 보드의 목록 ID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epic_boards/1/lists/1"
```

응답 예시:

```json
{
  "id" : 1,
  "label" : {
    "name" : "Testing",
    "color" : "#F0AD4E",
    "description" : null
  },
  "position" : 1,
  "list_type" : "label",
  "collapsed" : false
}
```
