## List projects

Get a list of projects owned by the authenticated user.

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

Get a specific project, identified by project ID, which is owned by the authentication user.

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

## Create project

Create new project owned by user

```
POST /projects
```

Parameters:

+ `name` (required) - new project name
+ `code` (optional) - new project code, uses project name if not set
+ `path` (optional) - new project path, uses project name if not set
+ `description (optional) - short project description
+ `default_branch` (optional) - 'master' by default
+ `issues_enabled` (optional) - enabled by default
+ `wall_enabled` (optional) - enabled by default
+ `merge_requests_enabled` (optional) - enabled by default
+ `wiki_enabled` (optional) - enabled by default

Will return created project with status `201 Created` on success, or `404 Not
found` on fail.

## Get project users

Get users and access roles for existing project

```
GET /projects/:id/users
```

Parameters:

+ `id` (required) - The ID or code name of a project

Will return users and their access roles with status `200 OK` on success, or `404 Not found` on fail.

## Add project users

Add users to exiting project

```
POST /projects/:id/users
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `user_ids` (required) - The ID list of users to add
+ `project_access` (required) - Project access level

Will return status `201 Created` on success, or `404 Not found` on fail.

## Update project users access level

Update existing users to specified access level

```
PUT /projects/:id/users
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `user_ids` (required) - The ID list of users to add
+ `project_access` (required) - Project access level

Will return status `200 OK` on success, or `404 Not found` on fail.

## Delete project users

Delete users from exiting project

```
DELETE /projects/:id/users
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `user_ids` (required) - The ID list of users to add

Will return status `200 OK` on success, or `404 Not found` on fail.

## Project repository branches

Get a list of repository branches from a project, sorted by name alphabetically.

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

Get a list of repository tags from a project, sorted by name in reverse alphabetical order.

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

