---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Issue links API **(FREE)**

> The simple "relates to" relationship [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212329) to [GitLab Free](https://about.gitlab.com/pricing/) in 13.4.

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
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
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

## Create an issue link

Creates a two-way relation between two issues. The user must be allowed to
update both issues to succeed.

```plaintext
POST /projects/:id/issues/:issue_iid/links
```

| Attribute           | Type           | Required | Description                          |
|---------------------|----------------|----------|--------------------------------------|
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `issue_iid`         | integer        | yes      | The internal ID of a project's issue |
| `target_project_id` | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) of a target project  |
| `target_issue_iid`  | integer/string | yes      | The internal ID of a target project's issue |
| `link_type`         | string         | no       | The type of the relation ("relates_to", "blocks", "is_blocked_by"), defaults to "relates_to"). |

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
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
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
