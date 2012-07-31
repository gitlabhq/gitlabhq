## List projects

Get a list of authenticated user's projects.

```
GET /projects
```

```json
[
  {
    "id": 3,
    "code": "rails",
    "name": "rails",
    "description": null,
    "path": "rails",
    "default_branch": "master",
    "owner": {
      "id": 1,
      "email": "john@example.com",
      "name": "John Smith",
      "blocked": false,
      "created_at": "2012-05-23T08:00:58Z"
    },
    "private": true,
    "issues_enabled": false,
    "merge_requests_enabled": false,
    "wall_enabled": true,
    "wiki_enabled": true,
    "created_at": "2012-05-23T08:05:02Z"
  },
  {
    "id": 5,
    "code": "gitlab",
    "name": "gitlab",
    "description": null,
    "path": "gitlab",
    "default_branch": "api",
    "owner": {
      "id": 1,
      "email": "john@example.com",
      "name": "John Smith",
      "blocked": false,
      "created_at": "2012-05-23T08:00:58Z"
    },
    "private": true,
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wall_enabled": true,
    "wiki_enabled": true,
    "created_at": "2012-05-30T12:49:20Z"
  }
]
```

## Single project

Get an authenticated user's project.

```
GET /projects/:id
```

Parameters:

+ `id` (required) - The ID or code name of a project

```json
{
  "id": 5,
  "code": "gitlab",
  "name": "gitlab",
  "description": null,
  "path": "gitlab",
  "default_branch": "api",
  "owner": {
    "id": 1,
    "email": "john@example.com",
    "name": "John Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:00:58Z"
  },
  "private": true,
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wall_enabled": true,
  "wiki_enabled": true,
  "created_at": "2012-05-30T12:49:20Z"
}
```

## Project repository branches

Get a list of project repository branches sorted by name alphabetically.

```
GET /projects/:id/repository/branches
```

Parameters:

+ `id` (required) - The ID or code name of a project

```json
[
  {
    "name": "master",
    "commit": {
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "parents": [
        {
          "id": "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
        }
      ],
      "tree": "46e82de44b1061621357f24c05515327f2795a95",
      "message": "add projects API",
      "author": {
        "name": "John Smith",
        "email": "john@example.com"
      },
      "committer": {
        "name": "John Smith",
        "email": "john@example.com"
      },
      "authored_date": "2012-06-27T05:51:39-07:00",
      "committed_date": "2012-06-28T03:44:20-07:00"
    }
  }
]
```

Get a single project repository branch.

```
GET /projects/:id/repository/branches/:branch
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `branch` (required) - The name of the branch

```json
{
  "name": "master",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "parents": [
      {
        "id": "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      }
    ],
    "tree": "46e82de44b1061621357f24c05515327f2795a95",
    "message": "add projects API",
    "author": {
      "name": "John Smith",
      "email": "john@example.com"
    },
    "committer": {
      "name": "John Smith",
      "email": "john@example.com"
    },
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00"
  }
}
```

## Project repository tags

Get a list of project repository tags sorted by name in reverse alphabetical order.

```
GET /projects/:id/repository/tags
```

Parameters:

+ `id` (required) - The ID or code name of a project

```json
[
  {
    "name": "v1.0.0",
    "commit": {
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "parents": [

      ],
      "tree": "38017f2f189336fe4497e9d230c5bb1bf873f08d",
      "message": "Initial commit",
      "author": {
        "name": "John Smith",
        "email": "john@example.com"
      },
      "committer": {
        "name": "Jack Smith",
        "email": "jack@example.com"
      },
      "authored_date": "2012-05-28T04:42:42-07:00",
      "committed_date": "2012-05-28T04:42:42-07:00"
    }
  }
]
```

# Project Snippets

## List snippets

Not implemented.

## Single snippet

Get a project snippet.

```
GET /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `snippet_id` (required) - The ID of a project's snippet

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "author": {
    "id": 1,
    "email": "john@example.com",
    "name": "John Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z"
}
```

## Snippet content

Get a raw project snippet.

```
GET /projects/:id/snippets/:snippet_id/raw
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `snippet_id` (required) - The ID of a project's snippet

## New snippet

Create a new project snippet.

```
POST /projects/:id/snippets
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `title` (required) - The title of a snippet
+ `file_name` (required) - The name of a snippet file
+ `lifetime` (optional) - The expiration date of a snippet
+ `code` (required) - The content of a snippet

Will return created snippet with status `201 Created` on success, or `404 Not found` on fail.

## Edit snippet

Update an existing project snippet.

```
PUT /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `snippet_id` (required) - The ID of a project's snippet
+ `title` (optional) - The title of a snippet
+ `file_name` (optional) - The name of a snippet file
+ `lifetime` (optional) - The expiration date of a snippet
+ `code` (optional) - The content of a snippet

Will return updated snippet with status `200 OK` on success, or `404 Not found` on fail.

## Delete snippet

Delete existing project snippet.

```
DELETE /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `snippet_id` (required) - The ID of a project's snippet

Status code `200` will be returned on success.

## Raw blob content

Get the raw file contents for a file.

```
GET /projects/:id/repository/commits/:sha/blob
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `sha` (required) - The commit or branch name
+ `filepath` (required) - The path the file 

Will return the raw file contents.
