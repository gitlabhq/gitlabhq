---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group epic boards API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385903) in GitLab 15.9.

Every API call to [group epic boards](../user/group/epics/epic_boards.md) must be authenticated.

If a user is not a member of a group and the group is private, a `GET`
request results in `404` status code.

## List all epic boards in a group

Lists epic boards in the given group.

```plaintext
GET /groups/:id/epic_boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) accessible by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epic_boards"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "group epic board",
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

## Single group epic board

Gets a single group epic board.

```plaintext
GET /groups/:id/epic_boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) accessible by the authenticated user |
| `board_id` | integer | yes | The ID of an epic board |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epic_boards/1"
```

Example response:

```json
  {
    "id": 1,
    "name": "group epic board",
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

## List group epic board lists

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385904) in GitLab 15.9.

Gets a list of the epic board's lists.
Does not include `open` and `closed` lists.

```plaintext
GET /groups/:id/epic_boards/:board_id/lists
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) accessible by the authenticated user |
| `board_id` | integer | yes | The ID of an epic board |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epic_boards/1/lists"
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

## Single group epic board list

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385904) in GitLab 15.9.

Gets a single board list.

```plaintext
GET /groups/:id/epic_boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) accessible by the authenticated user |
| `board_id` | integer | yes | The ID of an epic board |
| `list_id` | integer | yes | The ID of an epic board's list |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/epic_boards/1/lists/1"
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
  "list_type" : "label",
  "collapsed" : false
}
```
