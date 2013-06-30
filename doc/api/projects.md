## Projects

### List projects

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
    "public": true,
    "path": "rails",
    "path_with_namespace": "rails/rails",
    "issues_enabled": false,
    "merge_requests_enabled": false,
    "wall_enabled": true,
    "wiki_enabled": true,
    "created_at": "2012-05-23T08:05:02Z",
    "last_activity_at": "2012-05-23T08:05:02Z"
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
    "public": true,
    "path": "gitlab",
    "path_with_namespace": "randx/gitlab",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wall_enabled": true,
    "wiki_enabled": true,
    "created_at": "2012-05-30T12:49:20Z",
    "last_activity_at": "2012-05-23T08:05:02Z"
  }
]
```


### Get single project

Get a specific project, identified by project ID or NAME, which is owned by the authentication user.
Currently namespaced projects cannot retrieved by name.

```
GET /projects/:id
```

Parameters:

+ `id` (required) - The ID or NAME of a project

```json
{
  "id": 5,
  "name": "gitlab",
  "name_with_namespace": "GitLab / gitlabhq",
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
  "public": true,
  "path": "gitlab",
  "path_with_namespace": "randx/gitlab",
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wall_enabled": true,
  "wiki_enabled": true,
  "created_at": "2012-05-30T12:49:20Z",
  "last_activity_at": "2012-05-23T08:05:02Z"
}
```

### Get project events

Get a project events for specific project.
Sorted from newest to latest

```
GET /projects/:id/events
```

Parameters:

+ `id` (required) - The ID or NAME of a project

```json

[{
  "title": null,
  "project_id": 15,
  "action_name": "closed",
  "target_id": 830,
  "target_type": "Issue",
  "author_id": 1,
  "data": null,
  "target_title": "Public project search field"
}, {
  "title": null,
  "project_id": 15,
  "action_name": "opened",
  "target_id": null,
  "target_type": null,
  "author_id": 1,
  "data": {
    "before": "50d4420237a9de7be1304607147aec22e4a14af7",
    "after": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
    "ref": "refs/heads/master",
    "user_id": 1,
    "user_name": "Dmitriy Zaporozhets",
    "repository": {
      "name": "gitlabhq",
      "url": "git@dev.gitlab.org:gitlab/gitlabhq.git",
      "description": "GitLab: self hosted Git management software. \r\nDistributed under the MIT License.",
      "homepage": "https://dev.gitlab.org/gitlab/gitlabhq"
    },
    "commits": [{
      "id": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "message": "Add simple search to projects in public area",
      "timestamp": "2013-05-13T18:18:08+00:00",
      "url": "https://dev.gitlab.org/gitlab/gitlabhq/commit/c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "author": {
        "name": "Dmitriy Zaporozhets",
        "email": "dmitriy.zaporozhets@gmail.com"
      }
    }],
    "total_commits_count": 1
  },
  "target_title": null
}, {
  "title": null,
  "project_id": 15,
  "action_name": "closed",
  "target_id": 840,
  "target_type": "Issue",
  "author_id": 1,
  "data": null,
  "target_title": "Finish & merge Code search PR"
}]
```


### Create project

Creates new project owned by user.

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

**Project access levels**

The project access levels are defined in the `user_project.rb` class. Currently, these levels are recoginized:

```
  GUEST     = 10
  REPORTER  = 20
  DEVELOPER = 30
  MASTER    = 40
```


### Create project for user

Creates a new project owned by user. Available only for admins.

```
POST /projects/user/:user_id
```

Parameters:

+ `user_id` (required) - user_id of owner
+ `name` (required) - new project name
+ `description` (optional) - short project description
+ `default_branch` (optional) - 'master' by default
+ `issues_enabled` (optional) - enabled by default
+ `wall_enabled` (optional) - enabled by default
+ `merge_requests_enabled` (optional) - enabled by default
+ `wiki_enabled` (optional) - enabled by default



## Team members

### List project team members

Get a list of project team members.

```
GET /projects/:id/members
```

Parameters:

+ `id` (required) - The ID or NAME of a project
+ `query` (optional) - Query string to search for members


### Get project team member

Gets a project team member.

```
GET /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or NAME of a project
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


### Add project team member

Adds a user to a project team. This is an idempotent method and can be called multiple times
with the same parameters. Adding team membership to a user that is already a member does not
affect the existing membership.

```
POST /projects/:id/members
```

Parameters:

+ `id` (required) - The ID or NAME of a project
+ `user_id` (required) - The ID of a user to add
+ `access_level` (required) - Project access level


### Edit project team member

Updates project team member to a specified access level.

```
PUT /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or NAME of a project
+ `user_id` (required) - The ID of a team member
+ `access_level` (required) - Project access level


### Remove project team member

Removes user from project team.

```
DELETE /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or NAME of a project
+ `user_id` (required) - The ID of a team member

This method is idempotent and can be called multiple times with the same parameters.
Revoking team membership for a user who is not currently a team member is considered success.
Please note that the returned JSON currently differs slightly. Thus you should not
rely on the returned JSON structure.


## Hooks

### List project hooks

Get list of project hooks.

```
GET /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID or NAME of a project


### Get project hook

Get a specific hook for project.

```
GET /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID or NAME of a project
+ `hook_id` (required) - The ID of a project hook

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "created_at": "2012-10-12T17:04:47Z"
}
```


### Add project hook

Adds a hook to project.

```
POST /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID or NAME of a project
+ `url` (required) - The hook URL


### Edit project hook

Edits a hook for project.

```
PUT /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID or NAME of a project
+ `hook_id` (required) - The ID of a project hook
+ `url` (required) - The hook URL


### Delete project hook

Removes a hook from project. This is an idempotent method and can be called multiple times.
Either the hook is available or not.

```
DELETE /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID or NAME of a project
+ `hook_id` (required) - The ID of hook to delete

Note the JSON response differs if the hook is available or not. If the project hook
is available before it is returned in the JSON response or an empty response is returned.


## Branches

### List branches

Lists all branches of a project.

```
GET /projects/:id/repository/branches
```

Parameters:

+ `id` (required) - The ID of the project


### List single branch

Lists a specific branch of a project.

```
GET /projects/:id/repository/branches/:branch
```

Parameters:

+ `id` (required) - The ID of the project.
+ `branch` (required) - The name of the branch.


### Protect single branch

Protects a single branch of a project.

```
PUT /projects/:id/repository/branches/:branch/protect
```

Parameters:

+ `id` (required) - The ID of the project.
+ `branch` (required) - The name of the branch.


### Unprotect single branch

Unprotects a single branch of a project.

```
PUT /projects/:id/repository/branches/:branch/unprotect
```

Parameters:

+ `id` (required) - The ID of the project.
+ `branch` (required) - The name of the branch.

