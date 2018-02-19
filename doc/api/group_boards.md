# Group Issue Boards API

Every API call to group boards must be authenticated.

If a user is not a member of a group and the group is private, a `GET`
request will result in `404` status code.

## Group Board

Lists Issue Boards in the given group.

```
GET /groups/:id/boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards
```

Example response:

```json
[
  {
    "id": 1,
    "group_id": 5,
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

## Single board

Gets a single board.

```
GET /groups/:id/boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards/1
```

Example response:

```json
  {
    "id": 1,
    "group_id": 5,
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

## List board lists

Get a list of the board's lists.
Does not include `backlog` and `closed` lists

```
GET /groups/:id/boards/:board_id/lists
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards/1/lists
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

## Single board list

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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1
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

## New board list

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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards/1/lists?label_id=5
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

## Edit board list

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
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/group/5/boards/1/lists/1?position=2
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

## Delete a board list

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
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1
```
