## List projects

Get a list of projects owned by the authenticated user.

```
GET /projects
```

```json
[
  {
    "id": 3,
    "name": "rails",
    "description": null,
    "default_branch": "master",
    "owner": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "blocked": false,
      "created_at": "2012-05-23T08:00:58Z"
    },
    "private": true,
    "path": "rails",
    "path_with_namespace": "rails/rails",
    "issues_enabled": false,
    "merge_requests_enabled": false,
    "wall_enabled": true,
    "wiki_enabled": true,
    "created_at": "2012-05-23T08:05:02Z"
  },
  {
    "id": 5,
    "name": "gitlab",
    "description": null,
    "default_branch": "api",
    "owner": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "blocked": false,
      "created_at": "2012-05-23T08:00:58Z"
    },
    "private": true,
    "path": "gitlab",
    "path_with_namespace": "randx/gitlab",
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

+ `id` (required) - The ID of a project

```json
{
  "id": 5,
  "name": "gitlab",
  "description": null,
  "default_branch": "api",
  "owner": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:00:58Z"
  },
  "private": true,
  "path": "gitlab",
  "path_with_namespace": "randx/gitlab",
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

+ `id` (required) - The ID of a project
+ `query`         - Query string

## Get project team member

Get a project team member.

```
GET /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `user_id` (required) - The ID of a user

```json
{

  "id": 1,
  "username": "john_smith",
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

+ `id` (required) - The ID of a project
+ `user_id` (required) - The ID of a user to add
+ `access_level` (required) - Project access level

Will return status `201 Created` on success, or `404 Not found` on fail.

## Edit project team member

Update project team member to specified access level.

```
PUT /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `user_id` (required) - The ID of a team member
+ `access_level` (required) - Project access level

Will return status `200 OK` on success, or `404 Not found` on fail.

## Remove project team member

Removes user from project team.

```
DELETE /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `user_id` (required) - The ID of a team member

Status code `200` will be returned on success.

## List project hooks

Get list for project hooks

```
GET /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID of a project

Will return hooks with status `200 OK` on success, or `404 Not found` on fail.

## Get project hook

Get hook for project

```
GET /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `hook_id` (required) - The ID of a project hook

Will return hook with status `200 OK` on success, or `404 Not found` on fail.

## Add project hook

Add hook to project

```
POST /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID of a project
+ `url` (required) - The hook URL

Will return status `201 Created` on success, or `404 Not found` on fail.

## Edit project hook

Edit hook for project

```
PUT /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `hook_id` (required) - The ID of a project hook
+ `url` (required) - The hook URL

Will return status `201 Created` on success, or `404 Not found` on fail.


## Delete project hook

Delete hook from project

```
DELETE /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID of a project
+ `hook_id` (required) - The ID of hook to delete

Will return status `200 OK` on success, or `404 Not found` on fail.
