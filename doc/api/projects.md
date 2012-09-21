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
+ `description` (optional) - short project description
+ `default_branch` (optional) - 'master' by default
+ `issues_enabled` (optional) - enabled by default
+ `wall_enabled` (optional) - enabled by default
+ `merge_requests_enabled` (optional) - enabled by default
+ `wiki_enabled` (optional) - enabled by default

Will return created project with status `201 Created` on success, or `404 Not
found` on fail.

## List project team members

Get a list of project team members.

```
GET /projects/:id/members
```

Parameters:

+ `id` (required) - The ID or code name of a project

## Get project team member

Get a project team member.

```
GET /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `user_id` (required) - The ID of a user

```json
{

  "id": 1,
  "email": "john@example.com",
  "name": "John Smith",
  "blocked": false,
  "created_at": "2012-05-23T08:00:58Z",
  "access_level": 40
}
```

## Add project team member

Add a user to a project team.

```
POST /projects/:id/members
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `user_id` (required) - The ID of a user to add
+ `access_level` (required) - Project access level

Will return status `201 Created` on success, or `404 Not found` on fail.

## Edit project team member

Update project team member to specified access level.

```
PUT /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `user_id` (required) - The ID of a team member
+ `access_level` (required) - Project access level

Will return status `200 OK` on success, or `404 Not found` on fail.

## Remove project team member

Removes user from project team.

```
DELETE /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `user_id` (required) - The ID of a team member

Status code `200` will be returned on success.

## Get project hooks

Get hooks for project

```
GET /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID or code name of a project

Will return hooks with status `200 OK` on success, or `404 Not found` on fail.

## Add project hook

Add hook to project

```
POST /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `url` (required) - The hook URL

Will return status `201 Created` on success, or `404 Not found` on fail.

## Delete project hook

Delete hook from project

```
DELETE /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `hook_id` (required) - The ID of hook to delete

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

## Project repository commits

Get a list of repository commits in a project.

```
GET /projects/:id/repository/commits
```

Parameters:

+ `id` (required) - The ID or code name of a project
+ `ref_name` (optional) - The name of a repository branch or tag

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dzaporozhets@sphereconsultinginc.com",
    "created_at": "2012-09-20T11:50:22+03:00"
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2012-09-20T09:06:12+03:00"
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

