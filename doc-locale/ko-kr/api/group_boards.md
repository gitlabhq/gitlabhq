---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 이슈 보드 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [이슈 보드](../user/project/issue_board.md#group-issue-boards)를 관리합니다. 이 API에 대한 모든 호출에는 인증이 필요합니다.

사용자가 그룹의 멤버가 아니고 그룹이 비공개인 경우, `GET` 요청은 `404` 상태 코드를 반환합니다.

## 그룹의 모든 그룹 이슈 보드 나열 {#list-all-group-issue-boards-in-a-group}

지정된 그룹의 모든 그룹 이슈 보드를 나열합니다.

```plaintext
GET /groups/:id/boards
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards"
```

응답 예시:

```json
[
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
]
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자는 여러 그룹 보드를 사용할 수 있으므로 다른 매개변수를 봅니다.

응답 예시:

```json
[
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
]
```

## 그룹 이슈 보드 검색 {#retrieve-a-group-issue-board}

지정된 그룹 이슈 보드를 검색합니다.

```plaintext
GET /groups/:id/boards/:board_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

응답 예시:

```json
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자는 여러 그룹 이슈 보드를 사용할 수 있으므로 다른 매개변수를 봅니다.

응답 예시:

```json
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
```

## 그룹 이슈 보드 생성 {#create-a-group-issue-board}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

지정된 그룹에 대한 그룹 이슈 보드를 생성합니다.

```plaintext
POST /groups/:id/boards
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `name` | 문자열 | 예 | 새 보드의 이름입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards?name=newboard"
```

응답 예시:

```json
  {
    "id": 1,
    "name": "newboard",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": null,
    "lists" : [],
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone": null,
    "assignee" : null,
    "labels" : [],
    "weight" : null
  }
```

## 그룹 이슈 보드 업데이트 {#update-a-group-issue-board}

지정된 그룹 이슈 보드를 업데이트합니다.

```plaintext
PUT /groups/:id/boards/:board_id
```

| 속성                    | 유형           | 필수 | 설명 |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id`                   | 정수        | 예      | 보드의 ID입니다. |
| `name`                       | 문자열         | 아니요       | 보드의 새로운 이름입니다. |
| `hide_backlog_list`          | 부울        | 아니요       | 열린 목록을 숨깁니다. |
| `hide_closed_list`           | 부울        | 아니요       | 닫힌 목록을 숨깁니다. |
| `assignee_id`                | 정수        | 아니요       | 보드가 범위지정해야 할 담당자입니다. Premium 및 Ultimate만 해당합니다. |
| `milestone_id`               | 정수        | 아니요       | 보드가 범위지정해야 할 마일스톤입니다. Premium 및 Ultimate만 해당합니다. |
| `labels`                     | 문자열         | 아니요       | 보드가 범위지정해야 할 레이블 이름의 쉼표로 구분된 목록입니다. Premium 및 Ultimate만 해당합니다. |
| `weight`                     | 정수        | 아니요       | 보드가 범위지정해야 할 0에서 9 사이의 가중치 범위입니다. Premium 및 Ultimate만 해당합니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1?name=new_name&milestone_id=44&assignee_id=1&labels=GroupLabel&weight=4"
```

응답 예시:

```json
  {
    "id": 1,
    "name": "new_name",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": null,
    "lists": [],
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone": {
      "id": 44,
      "iid": 1,
      "group_id": 5,
      "title": "Group Milestone",
      "description": "Group Milestone Desc",
      "state": "active",
      "created_at": "2018-07-03T07:15:19.271Z",
      "updated_at": "2018-07-03T07:15:19.271Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://example.com/groups/documentcloud/-/milestones/1"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://example.com/root"
    },
    "labels": [{
      "id": 11,
      "name": "GroupLabel",
      "color": "#428BCA",
      "description": ""
    }],
    "weight": 4
  }
```

## 그룹 이슈 보드 삭제 {#delete-a-group-issue-board}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

지정된 그룹 이슈 보드를 삭제합니다.

```plaintext
DELETE /groups/:id/boards/:board_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

## 그룹 이슈 보드 목록 나열 {#list-group-issue-board-lists}

지정된 보드의 모든 그룹 이슈 보드 목록을 나열합니다. `open` 및 `closed` 목록을 포함하지 않습니다.

```plaintext
GET /groups/:id/boards/:board_id/lists
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists"
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
    "position" : 1
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3
  }
]
```

## 그룹 이슈 보드 목록 검색 {#retrieve-a-group-issue-board-list}

지정된 그룹 이슈 보드 목록을 검색합니다.

```plaintext
GET /groups/:id/boards/:board_id/lists/:list_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |
| `list_id` | 정수 | 예 | 보드 목록의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
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
  "position" : 1
}
```

## 그룹 이슈 보드 목록 생성 {#create-a-group-issue-board-list}

지정된 보드의 그룹 이슈 보드 목록을 생성합니다.

```plaintext
POST /groups/:id/boards/:board_id/lists
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |
| `label_id` | 정수 | 아니요 | 레이블의 ID입니다. |
| `assignee_id` | 정수 | 아니요 | 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `milestone_id` | 정수 | 아니요 | 마일스톤의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `iteration_id` | 정수 | 아니요 | 반복의 ID입니다. Premium 및 Ultimate만 해당합니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/12/lists?milestone_id=7"
```

응답 예시:

```json
{
  "id": 9,
  "label": null,
  "position": 0,
  "milestone": {
    "id": 7,
    "iid": 3,
    "group_id": 12,
    "title": "Milestone with due date",
    "description": "",
    "state": "active",
    "created_at": "2017-09-03T07:16:28.596Z",
    "updated_at": "2017-09-03T07:16:49.521Z",
    "due_date": null,
    "start_date": null,
    "web_url": "https://gitlab.example.com/groups/issue-reproduce/-/milestones/3"
  }
}
```

## 그룹 이슈 보드 목록 업데이트 {#update-a-group-issue-board-list}

지정된 그룹 이슈 보드 목록을 업데이트합니다. 이 호출은 목록 위치를 변경하는 데 사용됩니다.

```plaintext
PUT /groups/:id/boards/:board_id/lists/:list_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id`            | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |
| `list_id` | 정수 | 예 | 보드 목록의 ID입니다. |
| `position` | 정수 | 예 | 목록의 위치입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1?position=2"
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
  "position" : 1
}
```

## 그룹 이슈 보드 목록 삭제 {#delete-a-group-issue-board-list}

지정된 그룹 이슈 보드 목록을 삭제합니다. 관리자 및 그룹 소유자만 해당합니다.

```plaintext
DELETE /groups/:id/boards/:board_id/lists/:list_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |
| `list_id` | 정수 | 예 | 보드 목록의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
```
