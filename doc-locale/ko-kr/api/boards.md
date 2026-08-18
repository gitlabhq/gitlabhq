---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 이슈 보드 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [이슈 보드](../user/project/issue_board.md)를 관리합니다. 이 API에 대한 모든 호출에는 인증이 필요합니다.

사용자가 프라이빗 프로젝트의 멤버가 아닌 경우, 해당 프로젝트에 대한 `GET` 요청은 `404` 상태 코드를 반환합니다.

## 모든 프로젝트 이슈 보드 나열 {#list-all-project-issue-boards}

지정된 프로젝트의 모든 이슈 보드를 나열합니다.

```plaintext
GET /projects/:id/boards
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards"
```

응답 예시:

```json
[
  {
    "id" : 1,
    "name": "board1",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
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
        "position" : 1,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric": null
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      }
    ]
  }
]
```

프로젝트에서 보드가 활성화되지 않았거나 존재하지 않는 경우의 응답 예시:

```json
[]
```

## 이슈 보드 검색 {#retrieve-an-issue-board}

프로젝트에서 지정된 이슈 보드를 검색합니다.

```plaintext
GET /projects/:id/boards/:board_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1"
```

응답 예시:

```json
  {
    "id": 1,
    "name": "project issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
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
        "position" : 1,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      }
    ]
  }
```

## 이슈 보드 생성 {#create-an-issue-board}

지정된 프로젝트에서 이슈 보드를 생성합니다.

```plaintext
POST /projects/:id/boards
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `name` | 문자열 | 예 | 새 보드의 이름입니다. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards" \
  --data "name=newboard"
```

응답 예시:

```json
  {
    "id": 1,
    "name": "newboard",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
    },
    "lists" : [],
    "group": null,
    "milestone": null,
    "assignee" : null,
    "labels" : [],
    "weight" : null
  }
```

## 이슈 보드 업데이트 {#update-an-issue-board}

프로젝트에서 지정된 이슈 보드를 업데이트합니다.

```plaintext
PUT /projects/:id/boards/:board_id
```

| 속성                    | 유형           | 필수 | 설명 |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | 정수 또는 문자열 | 예      | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id`                   | 정수        | 예      | 보드의 ID입니다. |
| `name`                       | 문자열         | 아니요       | 보드의 새 이름입니다. |
| `hide_backlog_list`          | 부울        | 아니요       | 열기 목록을 숨깁니다. |
| `hide_closed_list`           | 부울        | 아니요       | 닫힘 목록을 숨깁니다. |
| `assignee_id`                | 정수        | 아니요       | 보드가 범위를 지정해야 하는 담당자입니다. Premium 및 Ultimate만 해당합니다. |
| `milestone_id`               | 정수        | 아니요       | 보드가 범위를 지정해야 하는 마일스톤입니다. Premium 및 Ultimate만 해당합니다. |
| `labels`                     | 문자열         | 아니요       | 보드가 범위를 지정해야 하는 레이블 이름의 쉼표로 구분된 목록입니다. Premium 및 Ultimate만 해당합니다. |
| `weight`                     | 정수        | 아니요       | 보드가 범위를 지정해야 하는 0에서 9 사이의 가중치 범위입니다. Premium 및 Ultimate만 해당합니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1" \
  --data "name=new_name&milestone_id=43&assignee_id=1&labels=Doing&weight=4"
```

응답 예시:

```json
  {
    "id": 1,
    "name": "new_name",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "created_at": "2018-07-03T05:48:49.982Z",
      "default_branch": null,
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "ssh_url_to_repo": "ssh://user@example.com/diaspora/diaspora-project-site.git",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site",
      "readme_url": null,
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "last_activity_at": "2018-07-03T05:48:49.982Z"
    },
    "lists": [],
    "group": null,
    "milestone": {
      "id": 43,
      "iid": 1,
      "project_id": 15,
      "title": "Milestone 1",
      "description": "Milestone 1 desc",
      "state": "active",
      "created_at": "2018-07-03T06:36:42.618Z",
      "updated_at": "2018-07-03T06:36:42.618Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://example.com/root/board1/milestones/1"
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
      "id": 10,
      "name": "Doing",
      "color": "#5CB85C",
      "description": null
    }],
    "weight": 4
  }
```

## 이슈 보드 삭제 {#delete-an-issue-board}

프로젝트에서 지정된 이슈 보드를 삭제합니다.

```plaintext
DELETE /projects/:id/boards/:board_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1"
```

## 이슈 보드의 모든 보드 목록 나열 {#list-all-board-lists-in-an-issue-board}

지정된 이슈 보드의 모든 목록을 나열합니다. `open` 및 `closed` 목록은 포함되지 않습니다.

```plaintext
GET /projects/:id/boards/:board_id/lists
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists"
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
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2,
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3,
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  }
]
```

## 보드 목록 검색 {#retrieve-a-board-list}

이슈 보드에서 지정된 목록을 검색합니다.

```plaintext
GET /projects/:id/boards/:board_id/lists/:list_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |
| `list_id`| 정수 | 예 | 보드의 목록 ID입니다. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## 보드 목록 생성 {#create-a-board-list}

새 이슈 보드 목록을 생성합니다.

```plaintext
POST /projects/:id/boards/:board_id/lists
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |
| `label_id` | 정수 | 아니요 | 레이블의 ID입니다. |
| `assignee_id` | 정수 | 아니요 | 사용자의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `milestone_id` | 정수 | 아니요 | 마일스톤의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `iteration_id` | 정수 | 아니요 | 반복의 ID입니다. Premium 및 Ultimate만 해당합니다. |

> [!note]
> 레이블, 담당자 및 마일스톤 인수는 상호 배타적입니다. 즉, 요청에서 이들 중 하나만 허용됩니다. 각 목록 유형에 필요한 라이선스에 대한 자세한 내용은 [이슈 보드 설명서](../user/project/issue_board.md)를 확인하세요.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists" \
  --data "label_id=5"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## 보드 목록 업데이트 {#update-a-board-list}

이슈 보드에서 지정된 목록의 위치를 업데이트합니다.

```plaintext
PUT /projects/:id/boards/:board_id/lists/:list_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |
| `list_id` | 정수 | 예 | 보드의 목록 ID입니다. |
| `position` | 정수 | 예 | 목록의 위치입니다. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1" \
  --data "position=2"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## 보드에서 보드 목록 삭제 {#delete-a-board-list-from-a-board}

이슈 보드에서 지정된 목록을 삭제합니다.

전제 조건:

- 다음 중 하나를 수행합니다.
  - 프로젝트에 대한 플래너, Reporter, 보안 관리자, Developer, Maintainer 또는 Owner 역할입니다.
  - 관리자 액세스 권한이 있어야 합니다.

```plaintext
DELETE /projects/:id/boards/:board_id/lists/:list_id
```

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `id` | 정수 또는 문자열 | 예 | 프로젝트의 ID 또는 [URL로 인코딩된 경로](rest/_index.md#namespaced-paths)입니다. |
| `board_id` | 정수 | 예 | 보드의 ID입니다. |
| `list_id` | 정수 | 예 | 보드의 목록 ID입니다. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1"
```
