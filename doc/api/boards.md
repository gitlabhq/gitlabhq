---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project issue boards API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Every API call to [issue boards](../user/project/issue_board.md) must be authenticated.

If a user is not a member of a private project,
a `GET` request on that project results in a `404` status code.

## List project issue boards

Lists project issue boards in the given project.

```plaintext
GET /projects/:id/boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards"
```

Example response:

```json
[
  {
    "id" : 1,
    "name": "board1",
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

Another example response when no board has been activated or exist in the project:

```json
[]
```

## Show a single issue board

Get a single project issue board.

```plaintext
GET /projects/:id/boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `board_id` | integer | yes | The ID of a board. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards/1"
```

Example response:

```json
  {
    "id": 1,
    "name": "project issue board",
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

## Create an issue board

Creates a project issue board.

```plaintext
POST /projects/:id/boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `name` | string | yes | The name of the new board. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards?name=newboard"
```

Example response:

```json
  {
    "id": 1,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
    },
    "name": "newboard",
    "lists" : [],
    "group": null,
    "milestone": null,
    "assignee" : null,
    "labels" : [],
    "weight" : null
  }
```

## Update an issue board

Updates a project issue board.

```plaintext
PUT /projects/:id/boards/:board_id
```

| Attribute                    | Type           | Required | Description |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `board_id`                   | integer        | yes      | The ID of a board. |
| `name`                       | string         | no       | The new name of the board. |
| `assignee_id`                | integer        | no       | The assignee the board should be scoped to. Premium and Ultimate only. |
| `milestone_id`               | integer        | no       | The milestone the board should be scoped to. Premium and Ultimate only. |
| `labels`                     | string         | no       | Comma-separated list of label names which the board should be scoped to. Premium and Ultimate only. |
| `weight`                     | integer        | no       | The weight range from 0 to 9, to which the board should be scoped to. Premium and Ultimate only. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards/1?name=new_name&milestone_id=43&assignee_id=1&labels=Doing&weight=4"
```

Example response:

```json
  {
    "id": 1,
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
    "name": "new_name",
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

## Delete an issue board

Deletes a project issue board.

```plaintext
DELETE /projects/:id/boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `board_id` | integer | yes | The ID of a board. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards/1"
```

## List board lists in a project issue board

Get a list of the board's lists.
Does not include `open` and `closed` lists.

```plaintext
GET /projects/:id/boards/:board_id/lists
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `board_id` | integer | yes | The ID of a board. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards/1/lists"
```

Example response:

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

## Show a single board list

Get a single board list.

```plaintext
GET /projects/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `board_id` | integer | yes | The ID of a board. |
| `list_id`| integer | yes | The ID of a board's list. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1"
```

Example response:

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

## Create a board list

Creates a new issue board list.

```plaintext
POST /projects/:id/boards/:board_id/lists
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `board_id` | integer | yes | The ID of a board. |
| `label_id` | integer | no | The ID of a label. |
| `assignee_id` | integer | no | The ID of a user. Premium and Ultimate only. |
| `milestone_id` | integer | no | The ID of a milestone. Premium and Ultimate only. |

NOTE:
Label, assignee and milestone arguments are mutually exclusive,
that is, only one of them are accepted in a request.
Check the [issue board documentation](../user/project/issue_board.md)
for more information regarding the required license for each list type.

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards/1/lists?label_id=5"
```

Example response:

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

## Reorder a list in a board

Updates an existing issue board list. This call is used to change list position.

```plaintext
PUT /projects/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `board_id` | integer | yes | The ID of a board. |
| `list_id` | integer | yes | The ID of a board's list. |
| `position` | integer | yes | The position of the list. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1?position=2"
```

Example response:

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

## Delete a board list from a board

Only for administrators and project owners. Deletes a board list.

```plaintext
DELETE /projects/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `board_id` | integer | yes | The ID of a board. |
| `list_id` | integer | yes | The ID of a board's list. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1"
```
