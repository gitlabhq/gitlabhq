# Epic Links API **(ULTIMATE)**

>**Note:**
> This endpoint was [introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/9188) in GitLab 11.8.

Manages parent-child [epic relationships](../user/group/epics/index.md#multi-level-child-epics).

Every API call to `epic_links` must be authenticated.

If a user is not a member of a group and the group is private, a `GET` request on that group will result to a `404` status code.

Epics are available only in the [Ultimate/Gold tier](https://about.gitlab.com/pricing/). If the epics feature is not available, a `403` status code will be returned.

## List epics related to a given epic

Gets all child epics of an epic.

```
GET /groups/:id/epics/:epic_iid/epics
```

| Attribute  | Type           | Required | Description                                                                                                   |
| ---------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `epic_iid` | integer        | yes      | The internal ID of the epic.                                                                                  |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/1/epics/5/epics/
```

Example response:

```json
[
  {
    "id": 29,
    "iid": 6,
    "group_id": 1,
    "parent_id": 5,
    "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "start_date": null,
    "start_date_is_fixed": false,
    "start_date_fixed": null,
    "start_date_from_milestones": null,
    "end_date": "2018-07-31",
    "due_date": "2018-07-31",
    "due_date_is_fixed": false,
    "due_date_fixed": null,
    "due_date_from_milestones": "2018-07-31",
    "created_at": "2018-07-17T13:36:22.770Z",
    "updated_at": "2018-07-18T12:22:05.239Z",
    "labels": []
  }
]
```

## Assign a child epic

Creates an association between two epics, designating one as the parent epic and the other as the child epic. A parent epic can have multiple child epics. If the new child epic already belonged to another epic, it is unassigned from that previous parent.

```
POST /groups/:id/epics/:epic_iid/epics
```

| Attribute       | Type           | Required | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `epic_iid`      | integer        | yes      | The internal ID of the epic.                                                                                       |
| `child_epic_id` | integer        | yes      | The global ID of the child epic. Internal ID can't be used because they can conflict with epics from other groups. |

```bash
curl --header POST "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/1/epics/5/epics/6
```

Example response:

```json
{
  "id": 6,
  "iid": 38,
  "group_id": 1,
  "parent_id": 5
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,
  "end_date": "2018-07-31",
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "labels": []
}
```

## Create and assign a child epic

Creates a a new epic and associates it with provided parent epic. The response is LinkedEpic object.

```
POST /groups/:id/epics/:epic_iid/epics
```

| Attribute       | Type           | Required | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user      |
| `epic_iid`      | integer        | yes      | The internal ID of the (future parent) epic.                                                                                       |
| `title`         | string         | yes      | The title of a newly created epic. |

```bash
curl --header POST "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/1/epics/5/epics?title=Newpic
```

Example response:

```json
{
  "id": 24,
  "iid": 2,
  "title": "child epic",
  "group_id": 49,
  "parent_id": 23,
  "has_children": false,
  "has_issues": false,
  "reference":  "&2",
  "url": "http://localhost/groups/group16/-/epics/2",
  "relation_url": "http://localhost/groups/group16/-/epics/1/links/24"
}
```

## Re-order a child epic

```
PUT /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| Attribute        | Type           | Required | Description                                                                                                        |
| ---------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`             | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user.     |
| `epic_iid`       | integer        | yes      | The internal ID of the epic.                                                                                       |
| `child_epic_id`  | integer        | yes      | The global ID of the child epic. Internal ID can't be used because they can conflict with epics from other groups. |
| `move_before_id` | integer        | no       | The global ID of a sibling epic that should be placed before the child epic.                                       |
| `move_after_id`  | integer        | no       | The global ID of a sibling epic that should be placed after the child epic.                                        |

```bash
curl --header PUT "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5
```

Example response:

```json
[
  {
    "id": 29,
    "iid": 6,
    "group_id": 1,
    "parent_id": 5,
    "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "start_date": null,
    "start_date_is_fixed": false,
    "start_date_fixed": null,
    "start_date_from_milestones": null,
    "end_date": "2018-07-31",
    "due_date": "2018-07-31",
    "due_date_is_fixed": false,
    "due_date_fixed": null,
    "due_date_from_milestones": "2018-07-31",
    "created_at": "2018-07-17T13:36:22.770Z",
    "updated_at": "2018-07-18T12:22:05.239Z",
    "labels": []
  }
]
```

## Unassign a child epic

Unassigns a child epic from a parent epic.

```
DELETE /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| Attribute       | Type           | Required | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user.     |
| `epic_iid`      | integer        | yes      | The internal ID of the epic.                                                                                       |
| `child_epic_id` | integer        | yes      | The global ID of the child epic. Internal ID can't be used because they can conflict with epics from other groups. |

```bash
curl --header DELETE "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5
```

Example response:

```json
{
  "id": 5,
  "iid": 38,
  "group_id": 1,
  "parent_id": null,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,
  "end_date": "2018-07-31",
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "labels": []
}
```
