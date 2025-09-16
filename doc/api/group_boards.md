---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group issue boards API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Every API call to [group issue boards](../user/project/issue_board.md#group-issue-boards) must be authenticated.

If a user is not a member of a group and the group is private, a `GET`
request results in `404` status code.

## List all group issue boards in a group

Lists issue boards in the given group.

```plaintext
GET /groups/:id/boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards"
```

Example response:

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

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) see
different parameters, due to the ability to have multiple group boards.

Example response:

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

## Single group issue board

Gets a single group issue board.

```plaintext
GET /groups/:id/boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `board_id` | integer | yes | The ID of a board. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

Example response:

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

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) see
different parameters, due to the ability to have multiple group issue boards.

Example response:

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

## Create a group issue board

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Creates a group issue board.

```plaintext
POST /groups/:id/boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `name` | string | yes | The name of the new board. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards?name=newboard"
```

Example response:

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

## Update a group issue board

Updates a group issue board.

```plaintext
PUT /groups/:id/boards/:board_id
```

| Attribute                    | Type           | Required | Description |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `board_id`                   | integer        | yes      | The ID of a board. |
| `name`                       | string         | no       | The new name of the board. |
| `hide_backlog_list`          | boolean        | no       | Hide the Open list. |
| `hide_closed_list`           | boolean        | no       | Hide the Closed list. |
| `assignee_id`                | integer        | no       | The assignee the board should be scoped to. Premium and Ultimate only. |
| `milestone_id`               | integer        | no       | The milestone the board should be scoped to. Premium and Ultimate only. |
| `labels`                     | string         | no       | Comma-separated list of label names which the board should be scoped to. Premium and Ultimate only. |
| `weight`                     | integer        | no       | The weight range from 0 to 9, to which the board should be scoped to. Premium and Ultimate only. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1?name=new_name&milestone_id=44&assignee_id=1&labels=GroupLabel&weight=4"
```

Example response:

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

## Delete a group issue board

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Deletes a group issue board.

```plaintext
DELETE /groups/:id/boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `board_id` | integer | yes | The ID of a board. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

## List group issue board lists

Get a list of the board's lists.
Does not include `open` and `closed` lists

```plaintext
GET /groups/:id/boards/:board_id/lists
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `board_id` | integer | yes | The ID of a board. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1/lists"
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

## Single group issue board list

Get a single board list.

```plaintext
GET /groups/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `board_id` | integer | yes | The ID of a board. |
| `list_id` | integer | yes | The ID of a board's list. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
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
  "position" : 1
}
```

## New group issue board list

Creates an issue board list.

```plaintext
POST /groups/:id/boards/:board_id/lists
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `board_id` | integer | yes | The ID of a board. |
| `label_id` | integer | no | The ID of a label. |
| `assignee_id` | integer | no | The ID of a user. Premium and Ultimate only. |
| `milestone_id` | integer | no | The ID of a milestone. Premium and Ultimate only. |
| `iteration_id` | integer | no | The ID of a iteration. Premium and Ultimate only. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/12/lists?milestone_id=7"
```

Example response:

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

## Edit group issue board list

Updates an existing issue board list. This call is used to change list position.

```plaintext
PUT /groups/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`            | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `board_id` | integer | yes | The ID of a board. |
| `list_id` | integer | yes | The ID of a board's list. |
| `position` | integer | yes | The position of the list. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/group/5/boards/1/lists/1?position=2"
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
  "position" : 1
}
```

## Delete a group issue board list

Only for administrators and group owners. Deletes the board list in question.

```plaintext
DELETE /groups/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `board_id` | integer | yes | The ID of a board. |
| `list_id` | integer | yes | The ID of a board's list. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
```
