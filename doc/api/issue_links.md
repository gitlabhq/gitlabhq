---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Issue links API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - The simple "relates to" relationship [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212329) to GitLab Free in 13.4.

## List issue relations

Get a list of a given issue's [linked issues](../user/project/issues/related_issues.md),
sorted by the relationship creation datetime (ascending).
Issues are filtered according to the user authorizations.

```plaintext
GET /projects/:id/issues/:issue_iid/links
```

Parameters:

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |

```json
[
  {
    "id" : 84,
    "iid" : 14,
    "issue_link_id": 1,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null,
    "link_type": "relates_to",
    "link_created_at": "2016-01-07T12:44:33.959Z",
    "link_updated_at": "2016-01-07T12:44:33.959Z"
  }
]
```

## Get an issue link

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88228) in GitLab 15.1.

Gets details about an issue link.

```plaintext
GET /projects/:id/issues/:issue_iid/links/:issue_link_id
```

Supported attributes:

| Attribute       | Type           | Required               | Description                                                                 |
|-----------------|----------------|------------------------|-----------------------------------------------------------------------------|
| `id`            | integer/string | Yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | Yes | Internal ID of a project's issue.                                           |
| `issue_link_id` | integer/string | Yes | ID of an issue relationship.                                                |

Response body attributes:

| Attribute      | Type   | Description                                                                               |
|:---------------|:-------|:------------------------------------------------------------------------------------------|
| `source_issue` | object | Details of the source issue of the relationship.                                          |
| `target_issue` | object | Details of the target issue of the relationship.                                          |
| `link_type`    | string | Type of the relationship. Possible values are `relates_to`, `blocks` and `is_blocked_by`. |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/84/issues/14/links/1"
```

Example response:

```json
{
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```

## Create an issue link

Creates a two-way relation between two issues. The user must be allowed to
update both issues to succeed.

```plaintext
POST /projects/:id/issues/:issue_iid/links
```

| Attribute           | Type           | Required | Description                          |
|---------------------|----------------|----------|--------------------------------------|
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `issue_iid`         | integer        | yes      | The internal ID of a project's issue |
| `target_project_id` | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) of a target project  |
| `target_issue_iid`  | integer/string | yes      | The internal ID of a target project's issue |
| `link_type`         | string         | no       | The type of the relation (`relates_to`, `blocks`, `is_blocked_by`), defaults to `relates_to`). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/issues/1/links?target_project_id=5&target_issue_iid=1"
```

Example response:

```json
{
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```

## Delete an issue link

Deletes an issue link, thus removes the two-way relationship.

```plaintext
DELETE /projects/:id/issues/:issue_iid/links/:issue_link_id
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)  |
| `issue_iid` | integer | yes      | The internal ID of a project's issue |
| `issue_link_id` | integer/string | yes      | The ID of an issue relationship |
| `link_type` | string  | no | The type of the relation (`relates_to`, `blocks`, `is_blocked_by`), defaults to `relates_to` |

```json
{
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```
