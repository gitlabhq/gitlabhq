## List issues

Get all issues created by authenticed user.

```
GET /issues
```

```json
[
  {
    "id": 43,
    "project_id": 8,
    "title": "4xx/5xx pages",
    "description": "",
    "labels": [ ],
    "milestone": null,
    "assignee": null,
    "author": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "blocked": false,
      "created_at": "2012-05-23T08:00:58Z"
    },
    "closed": true,
    "updated_at": "2012-07-02T17:53:12Z",
    "created_at": "2012-07-02T17:53:12Z"
  },
  {
    "id": 42,
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
      "closed": false,
      "updated_at": "2012-07-04T13:42:48Z",
      "created_at": "2012-07-04T13:42:48Z"
    },
    "assignee": {
      "id": 2,
      "username": "jack_smith",
      "email": "jack@example.com",
      "name": "Jack Smith",
      "blocked": false,
      "created_at": "2012-05-23T08:01:01Z"
    },
    "author": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "blocked": false,
      "created_at": "2012-05-23T08:00:58Z"
    },
    "closed": false,
    "updated_at": "2012-07-12T13:43:19Z",
    "created_at": "2012-06-28T12:58:06Z"
  }
]
```

## List project issues

Get a list of project issues.

```
GET /projects/:id/issues
```

Parameters:

+ `id` (required) - The ID of a project

## Single issue

Get a project issue.

```
GET /projects/:id/issues/:issue_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of a project issue

```json
{
  "id": 42,
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
    "closed": false,
    "updated_at": "2012-07-04T13:42:48Z",
    "created_at": "2012-07-04T13:42:48Z"
  },
  "assignee": {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:01:01Z"
  },
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:00:58Z"
  },
  "closed": false,
  "updated_at": "2012-07-12T13:43:19Z",
  "created_at": "2012-06-28T12:58:06Z"
}
```

## New issue

Create a new project issue.

```
POST /projects/:id/issues
```

Parameters:

+ `id` (required) - The ID of a project
+ `title` (required) - The title of an issue
+ `description` (optional) - The description of an issue
+ `assignee_id` (optional) - The ID of a user to assign issue
+ `milestone_id` (optional) - The ID of a milestone to assign issue
+ `labels` (optional) - Comma-separated label names for an issue

Will return created issue with status `201 Created` on success, or `404 Not found` on fail.

## Edit issue

Update an existing project issue.

```
PUT /projects/:id/issues/:issue_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `issue_id` (required) - The ID of a project's issue
+ `title` (optional) - The title of an issue
+ `description` (optional) - The description of an issue
+ `assignee_id` (optional) - The ID of a user to assign issue
+ `milestone_id` (optional) - The ID of a milestone to assign issue
+ `labels` (optional) - Comma-separated label names for an issue
+ `closed` (optional) - The state of an issue (0 = false, 1 = true)

Will return updated issue with status `200 OK` on success, or `404 Not found` on fail.

