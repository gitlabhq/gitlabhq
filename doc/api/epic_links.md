---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Epic Links API
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
The Epics REST API was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) in GitLab 17.0
and is planned for removal in v5 of the API.
In GitLab 17.4 or later, if your administrator [enabled the new look for epics](../user/group/epics/epic_work_items.md), use the
[Work Items API](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items/) instead. For more information, see the [guide how to migrate your existing APIs](graphql/epic_work_items_api_migration_guide.md).
This change is a breaking change.

Manages parent-child [epic relationships](../user/group/epics/manage_epics.md#multi-level-child-epics).

Every API call to `epic_links` must be authenticated.

If a user is not a member of a private group, a `GET` request on that
group results in a `404` status code.

Multi-level Epics are available only in [GitLab Ultimate](https://about.gitlab.com/pricing/).
If the Multi-level Epics feature is not available, a `403` status code is returned.

## List epics related to a given epic

Gets all child epics of an epic.

```plaintext
GET /groups/:id/epics/:epic_iid/epics
```

| Attribute  | Type           | Required | Description                                                                                                   |
| ---------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `epic_iid` | integer        | yes      | The internal ID of the epic.                                                                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5/epics/"
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
    "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
    "start_date_from_inherited_source": null,
    "end_date": "2018-07-31",                 //deprecated in favor of due_date
    "due_date": "2018-07-31",
    "due_date_is_fixed": false,
    "due_date_fixed": null,
    "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
    "due_date_from_inherited_source": "2018-07-31",
    "created_at": "2018-07-17T13:36:22.770Z",
    "updated_at": "2018-07-18T12:22:05.239Z",
    "labels": []
  }
]
```

## Assign a child epic

Creates an association between two epics, designating one as the parent epic and the other as the child epic. A parent epic can have multiple child epics. If the new child epic already belonged to another epic, it is unassigned from that previous parent.

```plaintext
POST /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| Attribute       | Type           | Required | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)      |
| `epic_iid`      | integer        | yes      | The internal ID of the epic.                                                                                       |
| `child_epic_id` | integer        | yes      | The global ID of the child epic. Internal ID can't be used because they can conflict with epics from other groups. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5/epics/6"
```

Example response:

```json
{
  "id": 6,
  "iid": 38,
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
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "labels": []
}
```

## Create and assign a child epic

Creates a new epic and associates it with provided parent epic. The response is LinkedEpic object.

```plaintext
POST /groups/:id/epics/:epic_iid/epics
```

| Attribute       | Type           | Required | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)      |
| `epic_iid`      | integer        | yes      | The internal ID of the (future parent) epic.                                                                       |
| `title`         | string         | yes      | The title of a newly created epic.                                                                                 |
| `confidential`  | boolean        | no       | Whether the epic should be confidential. Parameter is ignored if `confidential_epics` feature flag is disabled. Defaults to the confidentiality state of the parent epic.  |

```shell
curl --request POST --header  "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5/epics?title=Newpic"
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

```plaintext
PUT /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| Attribute        | Type           | Required | Description                                                                                                        |
| ---------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`             | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths).     |
| `epic_iid`       | integer        | yes      | The internal ID of the epic.                                                                                       |
| `child_epic_id`  | integer        | yes      | The global ID of the child epic. Internal ID can't be used because they can conflict with epics from other groups. |
| `move_before_id` | integer        | no       | The global ID of a sibling epic that should be placed before the child epic.                                       |
| `move_after_id`  | integer        | no       | The global ID of a sibling epic that should be placed after the child epic.                                        |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5"
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
    "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
    "start_date_from_inherited_source": null,
    "end_date": "2018-07-31",                 //deprecated in favor of due_date
    "due_date": "2018-07-31",
    "due_date_is_fixed": false,
    "due_date_fixed": null,
    "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
    "due_date_from_inherited_source": "2018-07-31",
    "created_at": "2018-07-17T13:36:22.770Z",
    "updated_at": "2018-07-18T12:22:05.239Z",
    "labels": []
  }
]
```

## Unassign a child epic

Unassigns a child epic from a parent epic.

```plaintext
DELETE /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| Attribute       | Type           | Required | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths).     |
| `epic_iid`      | integer        | yes      | The internal ID of the epic.                                                                                       |
| `child_epic_id` | integer        | yes      | The global ID of the child epic. Internal ID can't be used because they can conflict with epics from other groups. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5"
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
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "labels": []
}
```
