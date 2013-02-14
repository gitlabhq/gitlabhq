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


### Get single project

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

Return Values:

+ `200 Ok` if the project with given ID is found and the JSON response
+ `404 Not Found` if no project with ID found


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

Return values:

+ `201 Created` on success with the project data (see example at `GET /projects/:id`)
+ `400 Bad Request` if the required attribute name is not given
+ `403 Forbidden` if the user is not allowed to create a project, e.g. reached the project limit already
+ `404 Not Found` if something else fails


### List project members

Get a list of project team members.

```
GET /projects/:id/members
```

Parameters:

+ `id` (required) - The ID of a project
+ `query`         - Query string

Return Values:

+ `200 Ok` on success and a list of found team members
+ `404 Not Found` if project with ID not found


## Team members

### Get project team member

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

Return Values:

+ `200 Ok` on success and the team member, see example
+ `404 Not Found` if either the project or the team member could not be found


### Add project team member

Adds a user to a project team. This is an idempotent method and can be called multiple times
with the same parameters. Adding team membership to a user that is already a member does not
affect the membership.

```
POST /projects/:id/members
```

Parameters:

+ `id` (required) - The ID of a project
+ `user_id` (required) - The ID of a user to add
+ `access_level` (required) - Project access level

Return Values:

+ `200 Ok` on success and the added user, even if the user is already team member
+ `400 Bad Request` if the required attribute access_level is not given
+ `404 Not Found` if a resource can not be found, e.g. project with ID not available
+ `422 Unprocessable Entity` if an unknown access_level is given


### Edit project team member

Update project team member to specified access level.

```
PUT /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `user_id` (required) - The ID of a team member
+ `access_level` (required) - Project access level

Return Values:

+ `200 Ok` on succes and the modified team member
+ `400 Bad Request` if the required attribute access_level is not given
+ `404 Not Found` if a resource can not be found, e.g. project with ID not available
+ `422 Unprocessable Entity` if an unknown access_level is given


### Remove project team member

Removes user from project team.

```
DELETE /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `user_id` (required) - The ID of a team member

Return Values:

+ `200 Ok` on success
+ `404 Not Found` if either project or user can not be found

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

+ `id` (required) - The ID of a project

Return values:

+ `200 Ok` on success with a list of hooks
+ `404 Not Found` if project can not be found


### Get project hook

Get a specific hook for project.

```
GET /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `hook_id` (required) - The ID of a project hook

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "created_at": "2012-10-12T17:04:47Z"
}
```

Return values:

+ `200 Ok` on sucess and the hook with the given ID
+ `404 Not Found` if the hook can not be found


### Add project hook

Adds a hook to project.

```
POST /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID of a project
+ `url` (required) - The hook URL

Return values:

+ `201 Created` on success and the newly created hook
+ `400 Bad Request` if url is not given
+ `404 Not Found` if project with ID not found
+ `422 Unprocessable Entity` if the url is invalid (must begin with `http` or `https`)


### Edit project hook

Edits a hook for project.

```
PUT /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `hook_id` (required) - The ID of a project hook
+ `url` (required) - The hook URL

Return values:

+ `200 Ok` on success and the modified hook (see JSON response above)
+ `400 Bad Request` if the url attribute is not given
+ `404 Not Found` if project or hook can not be found
+ `422 Unprocessable Entity` if the url is invalid (must begin with `http` or `https`)


### Delete project hook

Removes a hook from project. This is an idempotent method and can be called multiple times.
Either the hook is available or not.

```
DELETE /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID of a project
+ `hook_id` (required) - The ID of hook to delete

Return values:

+ `200 Ok` on succes
+ `404 Not Found` if the project can not be found

Note the JSON response differs if the hook is available or not. If the project hook
is available before it is returned in the JSON response or an empty response is returned.
