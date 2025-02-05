---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Epics API (deprecated)
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
The Epics REST API was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) in GitLab 17.0
and is planned for removal in v5 of the API.
In GitLab 17.4 or later, if your administrator [enabled the new look for epics](../user/group/epics/epic_work_items.md), use the
[Work Items API](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/work_items/) instead. For more information, see the [guide how to migrate your existing APIs](graphql/epic_work_items_api_migration_guide.md).
This change is a breaking change.

Every API call to epic must be authenticated.

If a user is not a member of a private group, a `GET` request on that group results in a `404` status code.

If epics feature is not available a `403` status code is returned.

## Epic issues API

The [epic issues API](epic_issues.md) allows you to interact with issues associated with an epic.

## Milestone dates integration

Because start date and due date can be dynamically sourced from related issue milestones,
additional fields are shown when user has edit permission. These include two boolean
fields `start_date_is_fixed` and `due_date_is_fixed`, and four date fields `start_date_fixed`,
`start_date_from_inherited_source`, `due_date_fixed` and `due_date_from_inherited_source`.

- `end_date` has been deprecated in favor of `due_date`.
- `start_date_from_milestones` has been deprecated in favor of `start_date_from_inherited_source`
- `due_date_from_milestones` has been deprecated in favor of `due_date_from_inherited_source`

## Epics pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](rest/_index.md#pagination).

WARNING:
In [GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) and later,
the `reference` attribute in responses is deprecated in favor of `references`.

NOTE:
`references.relative` is relative to the group that the epic is being requested from. When an epic
is fetched from its origin group, the `relative` format is the same as the `short` format.
When an epic is requested across groups, the `relative` format is expected to be the same as the `full` format.

## List epics for a group

Gets all epics of the requested group and its subgroups.

```plaintext
GET /groups/:id/epics
GET /groups/:id/epics?author_id=5
GET /groups/:id/epics?labels=bug,reproduced
GET /groups/:id/epics?state=opened
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)               |
| `author_id`         | integer          | no         | Return epics created by the given user `id`                                                                                 |
| `author_username`   | string           | no         | Return epics created by the user with the given `username`. |
| `labels`            | string           | no         | Return epics matching a comma-separated list of labels names. Label names from the epic group or a parent group can be used |
| `with_labels_details` | boolean        | no         | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |
| `order_by`          | string           | no         | Return epics ordered by `created_at`, `updated_at`, or `title` fields. Default is `created_at`                              |
| `sort`              | string           | no         | Return epics sorted in `asc` or `desc` order. Default is `desc`                                                             |
| `search`            | string           | no         | Search epics against their `title` and `description`                                                                        |
| `state`             | string           | no         | Search epics against their `state`, possible filters: `opened`, `closed` and `all`, default: `all`                          |
| `created_after`     | datetime         | no         | Return epics created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | no         | Return epics created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_after`     | datetime         | no         | Return epics updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | no         | Return epics updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `include_ancestor_groups` | boolean    | no         | Include epics from the requested group's ancestors. Default is `false`                                                      |
| `include_descendant_groups` | boolean  | no         | Include epics from the requested group's descendants. Default is `true`                                                     |
| `my_reaction_emoji` | string           | no         | Return epics reacted by the authenticated user by the given emoji. `None` returns epics not given a reaction. `Any` returns epics given at least one reaction. |
| `not` | Hash | no | Return epics that do not match the parameters supplied. Accepts: `author_id`, `author_username` and `labels`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics"
```

Example response:

```json
[
  {
  "id": 29,
  "iid": 4,
  "group_id": 7,
  "parent_id": 23,
  "parent_iid": 3,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/4",
  "reference": "&4",
  "references": {
    "short": "&4",
    "relative": "&4",
    "full": "test&4"
  },
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/kam"
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
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/4",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/4/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7",
      "parent":"http://gitlab.example.com/api/v4/groups/7/epics/3"
  }
  },
  {
  "id": 50,
  "iid": 35,
  "group_id": 17,
  "parent_id": 19,
  "parent_iid": 1,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "web_url": "http://gitlab.example.com/groups/test/sample/-/epics/35",
  "reference": "&4",
  "references": {
    "short": "&4",
    "relative": "sample&4",
    "full": "test/sample&4"
  },
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/kam"
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
  "closed_at": "2018-08-18T12:22:05.239Z",
  "imported": false,
  "imported_from": "none",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/17/epics/35",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/17/epics/35/issues",
      "group":"http://gitlab.example.com/api/v4/groups/17",
      "parent":"http://gitlab.example.com/api/v4/groups/17/epics/1"
  }
  }
]
```

## Single epic

Gets a single epic

```plaintext
GET /groups/:id/epics/:epic_iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | integer/string   | yes        | The internal ID of the epic.  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5"
```

Example response:

```json
{
  "id": 30,
  "iid": 5,
  "group_id": 7,
  "parent_id": null,
  "parent_iid": null,
  "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/5",
  "reference": "&5",
  "references": {
    "short": "&5",
    "relative": "&5",
    "full": "test&5"
  },
  "author":{
    "id": 7,
    "name": "Pamella Huel",
    "username": "arnita",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/arnita"
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
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "subscribed": true,
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/5/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7",
      "parent": null
  }
}
```

## New epic

Creates a new epic.

NOTE:
Starting with GitLab [11.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6448), `start_date` and `end_date` should no longer be assigned
directly, as they now represent composite values. You can configure it via the `*_is_fixed` and
`*_fixed` fields instead.

```plaintext
POST /groups/:id/epics
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                |
| `title`             | string           | yes        | The title of the epic |
| `labels`            | string           | no         | The comma-separated list of labels |
| `description`       | string           | no         | The description of the epic. Limited to 1,048,576 characters.  |
| `color`             | string           | no         | The color of the epic. Behind a feature flag named `epic_highlight_color` (disabled by default) |
| `confidential`      | boolean          | no         | Whether the epic should be confidential |
| `created_at`        | string           | no         | When the epic was created. Date time string, ISO 8601 formatted, for example `2016-03-11T03:45:40Z` . Requires administrator or project/group owner privileges |
| `start_date_is_fixed` | boolean        | no         | Whether start date should be sourced from `start_date_fixed` or from milestones |
| `start_date_fixed`  | string           | no         | The fixed start date of an epic |
| `due_date_is_fixed` | boolean          | no         | Whether due date should be sourced from `due_date_fixed` or from milestones |
| `due_date_fixed`    | string           | no         | The fixed due date of an epic |
| `parent_id`         | integer/string   | no         | The ID of a parent epic |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics?title=Epic&description=Epic%20description&parent_id=29"
```

Example response:

```json
{
  "id": 33,
  "iid": 6,
  "group_id": 7,
  "parent_id": 29,
  "parent_iid": 4,
  "title": "Epic",
  "description": "Epic description",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/6",
  "reference": "&6",
  "references": {
    "short": "&6",
    "relative": "&6",
    "full": "test&6"
  },
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
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
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
    "self": "http://gitlab.example.com/api/v4/groups/7/epics/6",
    "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/6/issues",
    "group":"http://gitlab.example.com/api/v4/groups/7",
    "parent": "http://gitlab.example.com/api/v4/groups/7/epics/4"
  }
}
```

## Update epic

Updates an epic.

```plaintext
PUT /groups/:id/epics/:epic_iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | integer/string   | yes        | The internal ID of the epic  |
| `add_labels`        | string           | no         | Comma-separated label names to add to an issue. |
| `confidential`      | boolean          | no         | Whether the epic should be confidential |
| `description`       | string           | no         | The description of an epic. Limited to 1,048,576 characters.  |
| `due_date_fixed`    | string           | no         | The fixed due date of an epic |
| `due_date_is_fixed` | boolean          | no         | Whether due date should be sourced from `due_date_fixed` or from milestones |
| `labels`            | string           | no         | Comma-separated label names for an issue. Set to an empty string to unassign all labels. |
| `parent_id`         | integer/string   | no         | The ID of a parent epic. |
| `remove_labels`     | string           | no         | Comma-separated label names to remove from an issue. |
| `start_date_fixed`  | string           | no         | The fixed start date of an epic |
| `start_date_is_fixed` | boolean        | no         | Whether start date should be sourced from `start_date_fixed` or from milestones |
| `state_event`       | string           | no         | State event for an epic. Set `close` to close the epic and `reopen` to reopen it |
| `title`             | string           | no         | The title of an epic |
| `updated_at`        | string           | no         | When the epic was updated. Date time string, ISO 8601 formatted, for example `2016-03-11T03:45:40Z` . Requires administrator or project/group owner privileges |
| `color`             | string           | no         | The color of the epic. Behind a feature flag named `epic_highlight_color` (disabled by default) |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5?title=New%20Title&parent_id=29"
```

Example response:

```json
{
  "id": 33,
  "iid": 6,
  "group_id": 7,
  "parent_id": 29,
  "parent_iid": 4,
  "title": "New Title",
  "description": "Epic description",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/6",
  "reference": "&6",
  "references": {
    "short": "&6",
    "relative": "&6",
    "full": "test&6"
  },
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
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
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf"
}
```

## Delete epic

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/452189) in GitLab 16.11. In GitLab 16.10 and earlier, if you delete an epic, all its child epics and their descendants are deleted as well. If needed, you can remove child epics from the parent epic before you delete it.

Deletes an epic

```plaintext
DELETE /groups/:id/epics/:epic_iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | integer/string   | yes        | The internal ID of the epic.  |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5"
```

## Create a to-do item

Manually creates a to-do item for the current user on an epic. If
there already exists a to-do item for the user on that epic, status code `304` is
returned.

```plaintext
POST /groups/:id/epics/:epic_iid/todo
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes   | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)  |
| `epic_iid` | integer | yes          | The internal ID of a group's epic |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5/todo"
```

Example response:

```json
{
  "id": 112,
  "group": {
    "id": 1,
    "name": "Gitlab",
    "path": "gitlab",
    "kind": "group",
    "full_path": "base/gitlab",
    "parent_id": null
  },
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "action_name": "marked",
  "target_type": "epic",
  "target": {
    "id": 30,
    "iid": 5,
    "group_id": 1,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author":{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/arnita"
    },
    "web_url": "http://gitlab.example.com/groups/test/-/epics/5",
    "reference": "&5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "test&5"
    },
    "start_date": null,
    "end_date": null,
    "created_at": "2018-01-21T06:21:13.165Z",
    "updated_at": "2018-01-22T12:41:41.166Z",
    "closed_at": "2018-08-18T12:22:05.239Z"
  },
  "target_url": "https://gitlab.example.com/groups/epics/5",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```
