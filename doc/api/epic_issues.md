---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Epic Issues API
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

Every API call to the epic issues API endpoint must be authenticated.

If a user is not a member of a group and the group is private, a `GET` request on that group
results in a `404` status code.

Epics are available only in GitLab [Premium and Ultimate](https://about.gitlab.com/pricing/).
If the Epics feature is not available, a `403` status code is returned.

## Epic Issues pagination

API results [are paginated](rest/_index.md#pagination). Requests that return
multiple issues default to returning 20 results at a time.

## List issues for an epic

Gets all issues that are assigned to an epic and the authenticated user has access to.

```plaintext
GET /groups/:id/epics/:epic_iid/issues
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | integer/string   | yes        | The internal ID of the epic.  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/"
```

Example response:

```json
[
  {
    "id": 76,
    "iid": 6,
    "project_id": 8,
    "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description" : "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2017-11-15T13:39:24.670Z",
    "updated_at": "2018-01-04T10:49:19.506Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 8,
      "title": "v2.0",
      "description": "In tempore culpa inventore quo accusantium.",
      "state": "closed",
      "created_at": "2017-11-15T13:39:13.825Z",
      "updated_at": "2017-11-15T13:39:13.825Z",
      "due_date": null,
      "start_date": null
    },
    "assignees": [{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    }],
    "assignee": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "author": {
      "id": 13,
      "name": "Michell Johns",
      "username": "chris_hahn",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/30e3b2122ccd6b8e45e8e14a3ffb58fc?s=80&d=identicon",
      "web_url": "http://localhost:3001/chris_hahn"
    },
    "user_notes_count": 8,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "_links":{
      "self": "http://localhost:3001/api/v4/projects/8/issues/6",
      "notes": "http://localhost:3001/api/v4/projects/8/issues/6/notes",
      "award_emoji": "http://localhost:3001/api/v4/projects/8/issues/6/award_emoji",
      "project": "http://localhost:3001/api/v4/projects/8"
    },
    "epic_issue_id": 2
  }
]
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

## Assign an issue to the epic

Creates an epic - issue association. If the issue in question belongs to another epic it is unassigned from that epic.

```plaintext
POST /groups/:id/epics/:epic_iid/issues/:issue_id
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | integer/string   | yes        | The internal ID of the epic.  |
| `issue_id`          | integer/string   | yes        | The ID of the issue.          |

```shell
curl --header POST "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/55"
```

Example response:

```json
{
  "id": 11,
  "epic": {
    "id": 30,
    "iid": 5,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null
  },
  "issue": {
    "id": 55,
    "iid": 13,
    "project_id": 8,
    "title": "Beatae laborum voluptatem voluptate eligendi ex accusamus.",
    "description": "Quam veritatis debitis omnis aliquam sit.",
    "state": "opened",
    "created_at": "2017-11-05T13:59:12.782Z",
    "updated_at": "2018-01-05T10:33:03.900Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 48,
      "iid": 6,
      "project_id": 8,
      "title": "Sprint - Sed sed maxime temporibus ipsa ullam qui sit.",
      "description": "Quos veritatis qui expedita sunt deleniti accusamus.",
      "state": "active",
      "created_at": "2017-11-05T13:59:12.445Z",
      "updated_at": "2017-11-05T13:59:12.445Z",
      "due_date": "2017-11-13",
      "start_date": "2017-11-05"
    },
    "assignees": [{
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    }],
    "assignee": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "author": {
      "id": 25,
      "name": "User 3",
      "username": "user3",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "http://localhost:3001/user3"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/13",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

## Remove an issue from the epic

Removes an epic - issue association.

```plaintext
DELETE /groups/:id/epics/:epic_iid/issues/:epic_issue_id
```

| Attribute           | Type             | Required   | Description                                                                                          |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | integer/string   | yes        | The internal ID of the epic.                |
| `epic_issue_id`     | integer/string   | yes        | The ID of the issue - epic association.     |

```shell
curl --header DELETE "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/11"
```

Example response:

```json
{
  "id": 11,
  "epic": {
    "id": 30,
    "iid": 5,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null
  },
  "issue": {
    "id": 223,
    "iid": 13,
    "project_id": 8,
    "title": "Beatae laborum voluptatem voluptate eligendi ex accusamus.",
    "description": "Quam veritatis debitis omnis aliquam sit.",
    "state": "opened",
    "created_at": "2017-11-05T13:59:12.782Z",
    "updated_at": "2018-01-05T10:33:03.900Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 48,
      "iid": 6,
      "project_id": 8,
      "title": "Sprint - Sed sed maxime temporibus ipsa ullam qui sit.",
      "description": "Quos veritatis qui expedita sunt deleniti accusamus.",
      "state": "active",
      "created_at": "2017-11-05T13:59:12.445Z",
      "updated_at": "2017-11-05T13:59:12.445Z",
      "due_date": "2017-11-13",
      "start_date": "2017-11-05"
    },
    "assignees": [{
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    }],
    "assignee": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "author": {
      "id": 25,
      "name": "User 3",
      "username": "user3",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "http://localhost:3001/user3"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/13",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
}
```

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

## Update epic - issue association

Updates an epic - issue association.

```plaintext
PUT /groups/:id/epics/:epic_iid/issues/:epic_issue_id
```

| Attribute           | Type             | Required   | Description                                                                                          |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | integer/string   | yes        | The internal ID of the epic.                |
| `epic_issue_id`     | integer/string   | yes        | The ID of the issue - epic association.     |
| `move_before_id`    | integer/string   | no         | The ID of the issue - epic association that should be placed before the link in the question.     |
| `move_after_id`     | integer/string   | no         | The ID of the issue - epic association that should be placed after the link in the question.     |

```shell
curl --header PUT "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/11?move_before_id=20"
```

Example response:

```json
[
  {
    "id": 30,
    "iid": 6,
    "project_id": 8,
    "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description" : "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2017-11-15T13:39:24.670Z",
    "updated_at": "2018-01-04T10:49:19.506Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 8,
      "title": "v2.0",
      "description": "In tempore culpa inventore quo accusantium.",
      "state": "closed",
      "created_at": "2017-11-15T13:39:13.825Z",
      "updated_at": "2017-11-15T13:39:13.825Z",
      "due_date": null,
      "start_date": null
    },
    "assignees": [{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    }],
    "assignee": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "author": {
      "id": 13,
      "name": "Michell Johns",
      "username": "chris_hahn",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/30e3b2122ccd6b8e45e8e14a3ffb58fc?s=80&d=identicon",
      "web_url": "http://localhost:3001/chris_hahn"
    },
    "user_notes_count": 8,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "_links":{
      "self": "http://localhost:3001/api/v4/projects/8/issues/6",
      "notes": "http://localhost:3001/api/v4/projects/8/issues/6/notes",
      "award_emoji": "http://localhost:3001/api/v4/projects/8/issues/6/award_emoji",
      "project": "http://localhost:3001/api/v4/projects/8"
    },
    "subscribed": true,
    "epic_issue_id": 11,
    "relative_position": 55
  }
]
```
