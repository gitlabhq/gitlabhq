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
    "name:": "group issue board",
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "path": "documentcloud",
      "owner_id": null,
      "created_at": "2018-05-07T06:52:45.788Z",
      "updated_at": "2018-07-03T06:48:17.005Z",
      "description": "Consequatur aut a aperiam ut.",
      "avatar": {
        "url": null
      },
      "membership_lock": false,
      "share_with_group_lock": false,
      "visibility_level": 20,
      "request_access_enabled": false,
      "ldap_sync_status": "ready",
      "ldap_sync_error": null,
      "ldap_sync_last_update_at": null,
      "ldap_sync_last_successful_update_at": null,
      "ldap_sync_last_sync_at": null,
      "lfs_enabled": null,
      "parent_id": null,
      "shared_runners_minutes_limit": null,
      "repository_size_limit": null,
      "require_two_factor_authentication": false,
      "two_factor_grace_period": 48,
      "plan_id": null,
      "project_creation_level": 2,
      "runners_token": "rgeeL-nv4wa9YdRvuMid"
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
    "name:": "group issue board",
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "path": "documentcloud",
      "owner_id": null,
      "created_at": "2018-05-07T06:52:45.788Z",
      "updated_at": "2018-07-03T06:48:17.005Z",
      "description": "Consequatur aut a aperiam ut.",
      "avatar": {
        "url": null
      },
      "membership_lock": false,
      "share_with_group_lock": false,
      "visibility_level": 20,
      "request_access_enabled": false,
      "ldap_sync_status": "ready",
      "ldap_sync_error": null,
      "ldap_sync_last_update_at": null,
      "ldap_sync_last_successful_update_at": null,
      "ldap_sync_last_sync_at": null,
      "lfs_enabled": null,
      "parent_id": null,
      "shared_runners_minutes_limit": null,
      "repository_size_limit": null,
      "require_two_factor_authentication": false,
      "two_factor_grace_period": 48,
      "plan_id": null,
      "project_creation_level": 2,
      "runners_token": "rgeeL-nv4wa9YdRvuMid"
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

## Create a board

Creates a board.

```
POST /groups/:id/boards
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name` | string | yes | The name of the new board |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards?name=newboard
```

Example response:

```json
  {
    "id": 1,
    "name": "newboard",
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "path": "documentcloud",
      "owner_id": null,
      "created_at": "2018-05-07T06:52:45.788Z",
      "updated_at": "2018-07-03T06:48:17.005Z",
      "description": "Consequatur aut a aperiam ut.",
      "avatar": {
        "url": null
      },
      "membership_lock": false,
      "share_with_group_lock": false,
      "visibility_level": 20,
      "request_access_enabled": false,
      "ldap_sync_status": "ready",
      "ldap_sync_error": null,
      "ldap_sync_last_update_at": null,
      "ldap_sync_last_successful_update_at": null,
      "ldap_sync_last_sync_at": null,
      "lfs_enabled": null,
      "parent_id": null,
      "shared_runners_minutes_limit": null,
      "repository_size_limit": null,
      "require_two_factor_authentication": false,
      "two_factor_grace_period": 48,
      "plan_id": null,
      "project_creation_level": 2,
      "runners_token": "rgeeL-nv4wa9YdRvuMid"
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

## Update a board

> [Introduced][ee-5954] in GitLab 11.1.

Updates a board.

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
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards/1?name=new_name&milestone_id=44&assignee_id=1&labels=GroupLabel&weight=4
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
      "path": "documentcloud",
      "owner_id": null,
      "created_at": "2018-05-07T06:52:45.788Z",
      "updated_at": "2018-07-03T06:48:17.005Z",
      "description": "Consequatur aut a aperiam ut.",
      "avatar": {
        "url": null
      },
      "membership_lock": false,
      "share_with_group_lock": false,
      "visibility_level": 20,
      "request_access_enabled": false,
      "ldap_sync_status": "ready",
      "ldap_sync_error": null,
      "ldap_sync_last_update_at": null,
      "ldap_sync_last_successful_update_at": null,
      "ldap_sync_last_sync_at": null,
      "lfs_enabled": null,
      "parent_id": null,
      "shared_runners_minutes_limit": null,
      "repository_size_limit": null,
      "require_two_factor_authentication": false,
      "two_factor_grace_period": 48,
      "plan_id": null,
      "project_creation_level": 2,
      "runners_token": "rgeeL-nv3wa6YdRvuMid"
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

## Delete a board

Deletes a board.

```
DELETE /groups/:id/boards/:board_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `board_id` | integer | yes | The ID of a board |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/boards/1
```

## List board lists

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

[ee-5954]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/5954
