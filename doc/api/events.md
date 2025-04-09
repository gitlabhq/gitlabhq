---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Events API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to review event activity. Events can include a wide range of actions including things
like joining projects, commenting on issues, pushing changes to MRs, or closing epics.

For information about activity retention limits, see:

- [User activity time period limit](../user/profile/contributions_calendar.md#event-time-period-limit)
- [Project activity time period limit](../user/project/working_with_projects.md#event-time-period-limit)

## List all events

Lists all events for the currently authenticated user. Does not return events associated with epics.

Prerequisites:

- Your access token must have either the `read_user` or `api` scope.

```plaintext
GET /events
```

Parameters:

| Parameter     | Type            | Required | Description |
| ------------- | --------------- | -------- | ----------- |
| `action`      | string          | no       | If defined, returns events with the specified [action type](../user/profile/contributions_calendar.md#user-contribution-events). |
| `target_type` | string          | no       | If defined, returns events with the specified [target type](#target-type). |
| `before`      | date (ISO 8601) | no       | If defined, returns tokens created before the specified date. |
| `after`       | date (ISO 8601) | no       | If defined, returns tokens created after the specified date. |
| `scope`       | string          | no       | Include all events across a user's projects. |
| `sort`        | string          | no       | Direction to sort the results by creation date. Possible values: `asc`, `desc`. Default: `desc`. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01&scope=all"
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

## Get contribution events for a user

Gets the contribution events for a specified user. Does not return events associated with epics.

Prerequisites:

- Your access token must have either the `read_user` or `api` scope.

```plaintext
GET /users/:id/events
```

Parameters:

| Parameter     | Type            | Required | Description |
| ------------- | --------------- | -------- | ----------- |
| `id`          | integer         | yes      | ID or Username of a user. |
| `action`      | string          | no       | If defined, returns events with the specified [action type](../user/profile/contributions_calendar.md#user-contribution-events). |
| `target_type` | string          | no       | If defined, returns events with the specified [target type](#target-type). |
| `before`      | date (ISO 8601) | no       | If defined, returns tokens created before the specified date. |
| `after`       | date (ISO 8601) | no       | If defined, returns tokens created after the specified date. |
| `sort`        | string          | no       | Direction to sort the results by creation date. Possible values: `asc`, `desc`. Default: `desc`. |
| `page`        | integer         | no       | Returns the specified results page. Default: `1`. |
| `per_page`    | integer         | no       | Number of results per page. Default: `20`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/:id/events"
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

## List all visible events for a project

Lists all visible events for a specified project.

```plaintext
GET /projects/:project_id/events
```

Parameters:

| Parameter     | Type            | Required | Description |
| ------------- | --------------- | -------- | ----------- |
| `project_id`  | integer/string  | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a project. |
| `action`      | string          | no       | If defined, returns events with the specified [action type](../user/profile/contributions_calendar.md#user-contribution-events). |
| `target_type` | string          | no       | If defined, returns events with the specified [target type](#target-type). |
| `before`      | date (ISO 8601) | no       | If defined, returns tokens created before the specified date. |
| `after`       | date (ISO 8601) | no       | If defined, returns tokens created after the specified date. |
| `sort`        | string          | no       | Direction to sort the results by creation date. Possible values: `asc`, `desc`. Default: `desc`. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:project_id/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01"
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

## Target type

{{< history >}}

- [Added](https://gitlab.com/groups/gitlab-org/-/epics/13056) `epics` in GitLab 17.3.

{{< /history >}}

You can filter the results to return events from a specific target type. Possible values are:

- `epic`<sup>1</sup>
- `issue`
- `merge_request`
- `milestone`
- `note`<sup>2</sup>
- `project`
- `snippet`
- `user`

**Footnotes:**

1. You must enable the [new look for epics](../user/group/epics/epic_work_items.md). Some epic features like child items, linked items, start dates, due dates, and health statuses are not returned by the API.
1. Some merge request notes may instead use the `DiscussionNote` type. This target type is [not supported by the API](discussions.md#understand-note-types-in-the-api).
