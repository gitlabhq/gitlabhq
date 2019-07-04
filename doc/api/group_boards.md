# Group Issue Boards API

Every API call to group boards must be authenticated.

If a user is not a member of a group and the group is private, a `GET`
request will result in `404` status code.

## List all group issue boards in a group

Lists Issue Boards in the given group.

```
GET /groups/:id/boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards
```

Example response:

```json
[
  {
    "id": 1,
    "name:": "group issue board",
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12
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

Users on GitLab [Premium, Silver, or higher](https://about.gitlab.com/pricing/) will see
different parameters, due to the ability to have multiple group boards.

Example response:

```json
[
  {
    "id": 1,
    "name:": "group issue board",
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12
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

```
GET /groups/:id/boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards/1
```

Example response:

```json
  {
    "id": 1,
    "name:": "group issue board",
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12
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

Users on GitLab [Premium, Silver, or higher](https://about.gitlab.com/pricing/) will see
different parameters, due to the ability to have multiple group issue boards.s

Example response:

```json
  {
    "id": 1,
    "name:": "group issue board",
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12
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

## Create a group issue board **[PREMIUM]**

Creates a Group Issue Board.

```
POST /groups/:id/boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the new board |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards?name=newboard
```

Example response:

```json
  {
    "id": 1,
    "name": "newboard",
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12
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

## Update a group issue board **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/5954) in GitLab 11.1.

Updates a Group Issue Board.

```
PUT /groups/:id/boards/:board_id
```

| Attribute           | Type           | Required | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id`          | integer        | yes      | The ID of a board |
| `name`              | string         | no       | The new name of the board |
| `assignee_id`       | integer        | no       | The assignee the board should be scoped to |
| `milestone_id`      | integer        | no       | The milestone the board should be scoped to |
| `labels`            | string         | no       | Comma-separated list of label names which the board should be scoped to |
| `weight`            | integer        | no       | The weight range from 0 to 9, to which the board should be scoped to |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards/1?name=new_name&milestone_id=44&assignee_id=1&labels=GroupLabel&weight=4
```

Example response:

```json
  {
    "id": 1,
    "project": null,
    "lists": [],
    "name": "new_name",
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

## Delete a group issue board **[PREMIUM]**

Deletes a Group Issue Board.

```
DELETE /groups/:id/boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards/1
```

## List group issue board lists

Get a list of the board's lists.
Does not include `open` and `closed` lists

```
GET /groups/:id/boards/:board_id/lists
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards/1/lists
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

```
GET /groups/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |
| `list_id` | integer | yes | The ID of a board's list |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1
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

Creates a new Issue Board list.

```
POST /groups/:id/boards/:board_id/lists
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |
| `label_id` | integer | yes | The ID of a label |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards/1/lists?label_id=5
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

## Edit group issue board list

Updates an existing Issue Board list. This call is used to change list position.

```
PUT /groups/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`            | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |
| `list_id` | integer | yes | The ID of a board's list |
| `position` | integer | yes | The position of the list |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/group/5/boards/1/lists/1?position=2
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

Only for admins and group owners. Soft deletes the board list in question.

```
DELETE /groups/:id/boards/:board_id/lists/:list_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |
| `list_id` | integer | yes | The ID of a board's list |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1
```
