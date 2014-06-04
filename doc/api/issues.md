# Issues

## List issues

Get all issues created by authenticated user. This function takes pagination parameters
`page` and `per_page` to restrict the list of issues.

```
GET /issues
```

```json
[
  {
    "id": 43,
    "iid": 3,
    "project_id": 8,
    "title": "4xx/5xx pages",
    "description": "",
    "labels": [],
    "milestone": null,
    "assignee": null,
    "author": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "state": "active",
      "created_at": "2012-05-23T08:00:58Z"
    },
    "state": "closed",
    "updated_at": "2012-07-02T17:53:12Z",
    "created_at": "2012-07-02T17:53:12Z"
  },
  {
    "id": 42,
    "iid": 4,
    "project_id": 8,
    "title": "Add user settings",
    "description": "",
    "labels": [
      "feature"
    ],
    "milestone": {
      "id": 1,
      "title": "v1.0",
      "description": "",
      "due_date": "2012-07-20",
      "state": "reopenend",
      "updated_at": "2012-07-04T13:42:48Z",
      "created_at": "2012-07-04T13:42:48Z"
    },
    "assignee": {
      "id": 2,
      "username": "jack_smith",
      "email": "jack@example.com",
      "name": "Jack Smith",
      "state": "active",
      "created_at": "2012-05-23T08:01:01Z"
    },
    "author": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "state": "active",
      "created_at": "2012-05-23T08:00:58Z"
    },
    "state": "opened",
    "updated_at": "2012-07-12T13:43:19Z",
    "created_at": "2012-06-28T12:58:06Z"
  }
]
```

## List project issues

Get a list of project issues. This function accepts pagination parameters `page` and `per_page`
to return the list of project issues.

```
GET /projects/:id/issues
```

Parameters:

- `id` (required) - The ID of a project

## Single issue

Gets a single project issue.

```
GET /projects/:id/issues/:issue_id
```

Parameters:

- `id` (required) - The ID of a project
- `issue_id` (required) - The ID of a project issue

```json
{
  "id": 42,
  "iid": 3,
  "project_id": 8,
  "title": "Add user settings",
  "description": "",
  "labels": [
    "feature"
  ],
  "milestone": {
    "id": 1,
    "title": "v1.0",
    "description": "",
    "due_date": "2012-07-20",
    "state": "closed",
    "updated_at": "2012-07-04T13:42:48Z",
    "created_at": "2012-07-04T13:42:48Z"
  },
  "assignee": {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "state": "active",
    "created_at": "2012-05-23T08:01:01Z"
  },
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "state": "opened",
  "updated_at": "2012-07-12T13:43:19Z",
  "created_at": "2012-06-28T12:58:06Z"
}
```

## New issue

Creates a new project issue.

```
POST /projects/:id/issues
```

Parameters:

- `id` (required) - The ID of a project
- `title` (required) - The title of an issue
- `description` (optional) - The description of an issue
- `assignee_id` (optional) - The ID of a user to assign issue
- `milestone_id` (optional) - The ID of a milestone to assign issue
- `labels` (optional) - Comma-separated label names for an issue

## Edit issue

Updates an existing project issue. This function is also used to mark an issue as closed.

```
PUT /projects/:id/issues/:issue_id
```

Parameters:

- `id` (required) - The ID of a project
- `issue_id` (required) - The ID of a project's issue
- `title` (optional) - The title of an issue
- `description` (optional) - The description of an issue
- `assignee_id` (optional) - The ID of a user to assign issue
- `milestone_id` (optional) - The ID of a milestone to assign issue
- `labels` (optional) - Comma-separated label names for an issue
- `state_event` (optional) - The state event of an issue ('close' to close issue and 'reopen' to reopen it)

## Delete existing issue (**Deprecated**)

The function is deprecated and returns a `405 Method Not Allowed` error if called. An issue gets now closed and is done by calling `PUT /projects/:id/issues/:issue_id` with parameter `closed` set to 1.

```
DELETE /projects/:id/issues/:issue_id
```

Parameters:

- `id` (required) - The project ID
- `issue_id` (required) - The ID of the issue

## Comments on issues

Comments are done via the notes resource.
