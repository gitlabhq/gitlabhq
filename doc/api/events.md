---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Events API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Filter parameters

### Actions

See [User contribution events](../user/profile/contributions_calendar.md#user-contribution-events) for available types for the `action` parameter.
These options are in lowercase.

### Target types

> - Support for epics [introduced](https://gitlab.com/groups/gitlab-org/-/epics/13056) in GitLab 17.3. Your administrator must have [enabled the new look for epics](../user/group/epics/epic_work_items.md).

Available target types for the `target_type` parameter are:

- `epic`. Your administrator must have [enabled the new look for epics](../user/group/epics/epic_work_items.md).
- `issue`.
- `milestone`.
- `merge_request`.
- `note` - Some notes on merge requests may be of the type `DiscussionNote`, instead of `Note`.
  `DiscussionNote` items are [not available using the API](discussions.md#understand-note-types-in-the-api).
- `project`.
- `snippet`.
- `user`.

These options are in lowercase.
Some epic features like child items, linked items, start dates, due dates, and health statuses are not available using the API.
Some discussions on merge requests may be of type `DiscussionNote`. These are not available using the API.

### Date formatting

Dates for the `before` and `after` parameters should be supplied in the following format:

```plaintext
YYYY-MM-DD
```

### Event Time Period Limit

For information about activity retention limits, see:

- [User activity time period limit](../user/profile/contributions_calendar.md#event-time-period-limit)
- [Project activity time period limit](../user/project/working_with_projects.md#event-time-period-limit)

## List currently authenticated user's events

Get a list of events for the authenticated user. Scope `read_user` or `api` is required.
Events associated with epics are not available using the API.

```plaintext
GET /events
```

Parameters:

| Attribute     | Type   | Required | Description                                                                                         |
|---------------|--------|----------|-----------------------------------------------------------------------------------------------------|
| `action`      | string | no       | Include only events of a particular [action type](#actions)                                         |
| `target_type` | string | no       | Include only events of a particular [target type](#target-types)                                    |
| `before`      | date   | no       | Include only events created before a particular date. [View how to format dates](#date-formatting). |
| `after`       | date   | no       | Include only events created after a particular date. [View how to format dates](#date-formatting).  |
| `scope`       | string | no       | Include all events across a user's projects.                                                        |
| `sort`        | string | no       | Sort events in `asc` or `desc` order by `created_at`. Default is `desc`.                            |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01&scope=all"
```

Example response:

```json
[
  {
    "id": 1,
    "title":null,
    "project_id":1,
    "action_name":"opened",
    "target_id":160,
    "target_iid":53,
    "target_type":"Issue",
    "author_id":25,
    "target_title":"Qui natus eos odio tempore et quaerat consequuntur ducimus cupiditate quis.",
    "created_at":"2017-02-09T10:43:19.667Z",
    "author":{
      "name":"User 3",
      "username":"user3",
      "id":25,
      "state":"active",
      "avatar_url":"http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/user3"
    },
    "author_username":"user3",
    "imported":false,
    "imported_from": "none"
  },
  {
    "id": 2,
    "title":null,
    "project_id":1,
    "action_name":"opened",
    "target_id":159,
    "target_iid":14,
    "target_type":"Issue",
    "author_id":21,
    "target_title":"Nostrum enim non et sed optio illo deleniti non.",
    "created_at":"2017-02-09T10:43:19.426Z",
    "author":{
      "name":"Test User",
      "username":"ted",
      "id":21,
      "state":"active",
      "avatar_url":"http://www.gravatar.com/avatar/80fb888c9a48b9a3f87477214acaa63f?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/ted"
    },
    "author_username":"ted",
    "imported":false,
    "imported_from": "none"
  }
]
```

### Get user contribution events

Get the contribution events for the specified user, sorted from newest to oldest. Scope `read_user` or `api` is required.
Events associated with epics are not available using API.

```plaintext
GET /users/:id/events
```

Parameters:

| Attribute     | Type    | Required | Description                                                                                         |
|---------------|---------|----------|-----------------------------------------------------------------------------------------------------|
| `id`          | integer | yes      | The ID or Username of the user                                                                      |
| `action`      | string  | no       | Include only events of a particular [action type](#actions)                                         |
| `target_type` | string  | no       | Include only events of a particular [target type](#target-types)                                    |
| `before`      | date    | no       | Include only events created before a particular date. [View how to format dates](#date-formatting). |
| `after`       | date    | no       | Include only events created after a particular date. [View how to format dates](#date-formatting).  |
| `sort`        | string  | no       | Sort events in `asc` or `desc` order by `created_at`. Default is `desc`.                            |
| `page`        | integer | no       | The page of results to return. Defaults to 1.                                                       |
| `per_page`    | integer | no       | The number of results per page. Defaults to 20.                                                     |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/:id/events"
```

Example response:

```json
[
  {
    "id": 3,
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 830,
    "target_iid": 82,
    "target_type": "Issue",
    "author_id": 1,
    "target_title": "Public project search field",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 4,
    "title": null,
    "project_id": 15,
    "action_name": "pushed",
    "target_id": null,
    "target_iid": null,
    "target_type": null,
    "author_id": 1,
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "john",
    "imported": false,
    "imported_from": "none",
    "push_data": {
      "commit_count": 1,
      "action": "pushed",
      "ref_type": "branch",
      "commit_from": "50d4420237a9de7be1304607147aec22e4a14af7",
      "commit_to": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "ref": "main",
      "commit_title": "Add simple search to projects in public area"
    },
    "target_title": null
  },
  {
    "id": 5,
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 840,
    "target_iid": 11,
    "target_type": "Issue",
    "author_id": 1,
    "target_title": "Finish & merge Code search PR",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 7,
    "title": null,
    "project_id": 15,
    "action_name": "commented on",
    "target_id": 1312,
    "target_iid": 61,
    "target_type": "Note",
    "author_id": 1,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "http://localhost:3000/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "noteable_id": 377,
      "noteable_type": "Issue"
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  }
]
```

## List a Project's visible events

NOTE:
This endpoint has been around longer than the others. Documentation was formerly located in the [Projects API pages](projects.md).

Get a list of visible events for a particular project.

```plaintext
GET /projects/:project_id/events
```

Parameters:

| Attribute     | Type           | Required | Description                                                                                         |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------|
| `project_id`  | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)                 |
| `action`      | string         | no       | Include only events of a particular [action type](#actions)                                         |
| `target_type` | string         | no       | Include only events of a particular [target type](#target-types)                                    |
| `before`      | date           | no       | Include only events created before a particular date. [View how to format dates](#date-formatting). |
| `after`       | date           | no       | Include only events created after a particular date. [View how to format dates](#date-formatting).  |
| `sort`        | string         | no       | Sort events in `asc` or `desc` order by `created_at`. Default is `desc`.                            |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:project_id/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01"
```

Example response:

```json
[
  {
    "id": 8,
    "title":null,
    "project_id":1,
    "action_name":"opened",
    "target_id":160,
    "target_iid":160,
    "target_type":"Issue",
    "author_id":25,
    "target_title":"Qui natus eos odio tempore et quaerat consequuntur ducimus cupiditate quis.",
    "created_at":"2017-02-09T10:43:19.667Z",
    "author":{
      "name":"User 3",
      "username":"user3",
      "id":25,
      "state":"active",
      "avatar_url":"http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/user3"
    },
    "author_username":"user3",
    "imported":false,
    "imported_from": "none"
  },
  {
    "id": 9,
    "title":null,
    "project_id":1,
    "action_name":"opened",
    "target_id":159,
    "target_iid":159,
    "target_type":"Issue",
    "author_id":21,
    "target_title":"Nostrum enim non et sed optio illo deleniti non.",
    "created_at":"2017-02-09T10:43:19.426Z",
    "author":{
      "name":"Test User",
      "username":"ted",
      "id":21,
      "state":"active",
      "avatar_url":"http://www.gravatar.com/avatar/80fb888c9a48b9a3f87477214acaa63f?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/ted"
    },
    "author_username":"ted",
    "imported":false,
    "imported_from": "none"
  },
  {
    "id": 10,
    "title": null,
    "project_id": 1,
    "action_name": "commented on",
    "target_id": 1312,
    "target_iid": 1312,
    "target_type": "Note",
    "author_id": 1,
    "data": null,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "https://gitlab.example.com/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "https://gitlab.example.com/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "noteable_id": 377,
      "noteable_type": "Issue",
      "noteable_iid": 377
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "https://gitlab.example.com/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  }
]
```
