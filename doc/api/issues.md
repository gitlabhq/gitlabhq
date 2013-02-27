## List issues

Get all issues created by authenticed user. This function takes pagination parameters
`page` and `per_page` to restrict the list of issues.

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

Return values:

+ `200 Ok` on success and the list of issues
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if something fails



## List project issues

Get a list of project issues. This function accepts pagination parameters `page` and `per_page`
to return the list of project issues.

```
GET /projects/:id/issues
```

Parameters:

+ `id` (required) - The ID of a project

Return values:

+ `200 Ok` on success and the list of project issues
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


## Single issue

Gets a single project issue.

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

Return values:

+ `200 Ok` on success and the list of project issues
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID or issue ID not found


## New issue

Creates a new project issue.

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

Return values:

+ `201 Created` on success and the newly created project issue
+ `400 Bad Request` if the required attribute title is not given
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


## Edit issue

Updates an existing project issue. This function is also used to mark an issue as closed.

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

Return values:

+ `200 Ok` on success and the update project issue
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID or issue ID not found


## Delete existing issue (**Deprecated**)

The function is deprecated and returns a `405 Method Not Allowed`
error if called. An issue gets now closed and is done by calling `PUT /projects/:id/issues/:issue_id` with
parameter `closed` set to 1.

```
DELETE /projects/:id/issues/:issue_id
```

Parameters:

+ `id` (required) - The project ID
+ `issue_id` (required) - The ID of the issue

Return values:

+ `405 Method Not Allowed` is always returned, because the function is deprecated
