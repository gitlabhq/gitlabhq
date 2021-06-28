---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Epics API **(PREMIUM)**

> - Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.2.
> - Single-level Epics [were moved](https://gitlab.com/gitlab-org/gitlab/-/issues/37081) to [GitLab Premium](https://about.gitlab.com/pricing/) in 12.8.

Every API call to epic must be authenticated.

If a user is not a member of a private group, a `GET` request on that group results in a `404` status code.

If epics feature is not available a `403` status code is returned.

## Epic issues API

The [epic issues API](epic_issues.md) allows you to interact with issues associated with an epic.

## Milestone dates integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6448) in GitLab 11.3.

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

Read more on [pagination](index.md#pagination).

WARNING:
> `reference` attribute in response is deprecated in favour of `references`.
> Introduced in [GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354)

NOTE:
> `references.relative` is relative to the group that the epic is being requested. When epic is fetched from its origin group
> `relative` format would be the same as `short` format and when requested cross groups it is expected to be the same as `full` format.

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
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user               |
| `author_id`         | integer          | no         | Return epics created by the given user `id`                                                                                 |
| `labels`            | string           | no         | Return epics matching a comma separated list of labels names. Label names from the epic group or a parent group can be used |
| `with_labels_details` | boolean        | no         | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. Available in [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21413) and later |
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
| `my_reaction_emoji` | string           | no         | Return epics reacted by the authenticated user by the given emoji. `None` returns epics not given a reaction. `Any` returns epics given at least one reaction. Available in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31479) and later |

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
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/4",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/4/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7"
  }
  },
  {
  "id": 50,
  "iid": 35,
  "group_id": 17,
  "parent_id": 19,
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
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/17/epics/35",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/17/epics/35/issues",
      "group":"http://gitlab.example.com/api/v4/groups/17"
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
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user                |
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
  "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
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
  "subscribed": true,
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/5/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7"
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
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user                |
| `title`             | string           | yes        | The title of the epic |
| `labels`            | string           | no         | The comma separated list of labels |
| `description`       | string           | no         | The description of the epic. Limited to 1,048,576 characters.  |
| `confidential`      | boolean          | no         | Whether the epic should be confidential |
| `created_at`        | string           | no         | When the epic was created. Date time string, ISO 8601 formatted, for example `2016-03-11T03:45:40Z` . Requires administrator or project/group owner privileges ([available](https://gitlab.com/gitlab-org/gitlab/-/issues/255309) in GitLab 13.5 and later) |
| `start_date_is_fixed` | boolean        | no         | Whether start date should be sourced from `start_date_fixed` or from milestones (in GitLab 11.3 and later) |
| `start_date_fixed`  | string           | no         | The fixed start date of an epic (in GitLab 11.3 and later) |
| `due_date_is_fixed` | boolean          | no         | Whether due date should be sourced from `due_date_fixed` or from milestones (in GitLab 11.3 and later) |
| `due_date_fixed`    | string           | no         | The fixed due date of an epic (in GitLab 11.3 and later) |
| `parent_id`         | integer/string   | no         | The ID of a parent epic (in GitLab 11.11 and later) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics?title=Epic&description=Epic%20description"
```

Example response:

```json
{
  "id": 33,
  "iid": 6,
  "group_id": 7,
  "title": "Epic",
  "description": "Epic description",
  "state": "opened",
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
  "_links":{
    "self": "http://gitlab.example.com/api/v4/groups/7/epics/6",
    "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/6/issues",
    "group":"http://gitlab.example.com/api/v4/groups/7"
  }
}
```

## Update epic

Updates an epic.

NOTE:
Starting with GitLab [11.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6448), `start_date` and `end_date` should no longer be assigned
directly, as they now represent composite values. You can configure it via the `*_is_fixed` and
`*_fixed` fields instead.

```plaintext
PUT /groups/:id/epics/:epic_iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user                |
| `epic_iid`          | integer/string   | yes        | The internal ID of the epic  |
| `title`             | string           | no         | The title of an epic |
| `description`       | string           | no         | The description of an epic. Limited to 1,048,576 characters.  |
| `confidential`      | boolean          | no         | Whether the epic should be confidential |
| `labels`            | string           | no         | Comma-separated label names for an issue. Set to an empty string to unassign all labels. |
| `add_labels`        | string           | no         | Comma-separated label names to add to an issue. |
| `remove_labels`     | string           | no         | Comma-separated label names to remove from an issue. |
| `updated_at`        | string           | no         | When the epic was updated. Date time string, ISO 8601 formatted, for example `2016-03-11T03:45:40Z` . Requires administrator or project/group owner privileges ([available](https://gitlab.com/gitlab-org/gitlab/-/issues/255309) in GitLab 13.5 and later) |
| `start_date_is_fixed` | boolean        | no         | Whether start date should be sourced from `start_date_fixed` or from milestones (in GitLab 11.3 and later) |
| `start_date_fixed`  | string           | no         | The fixed start date of an epic (in GitLab 11.3 and later) |
| `due_date_is_fixed` | boolean          | no         | Whether due date should be sourced from `due_date_fixed` or from milestones (in GitLab 11.3 and later) |
| `due_date_fixed`    | string           | no         | The fixed due date of an epic (in GitLab 11.3 and later) |
| `state_event`       | string           | no         | State event for an epic. Set `close` to close the epic and `reopen` to reopen it (in GitLab 11.4 and later) |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5?title=New%20Title"
```

Example response:

```json
{
  "id": 33,
  "iid": 6,
  "group_id": 7,
  "title": "New Title",
  "description": "Epic description",
  "state": "opened",
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
  "downvotes": 0
}
```

## Delete epic

Deletes an epic

```plaintext
DELETE /groups/:id/epics/:epic_iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user                |
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
| `id`        | integer/string | yes   | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user  |
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
