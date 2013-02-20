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
    "public": true,
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

Return values:

+ `200 Ok` on success and a list of projects
+ `401 Unauthorized` if the user is not allowed to access projects


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
  "public": true,
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

+ `201 Created` on success and the added user is returned, even if the user is already team member
+ `400 Bad Request` if the required attribute access_level is not given
+ `401 Unauthorized` if the user is not allowed to add a new team member
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
+ `401 Unauthorized` if the user is not allowed to modify a team member
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
+ `401 Unauthorized` if user is not allowed to remove a team member
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
+ `401 Unauthorized` if user is not allowed to get list of hooks
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
DELETE /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `hook_id` (required) - The ID of hook to delete

Return values:

+ `200 Ok` on succes
+ `404 Not Found` if the project can not be found

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

Return values:

+ `200 Ok` on success and a list of branches
+ `404 Not Found` if project is not found


### List single branch

Lists a specific branch of a project.

```
GET /projects/:id/repository/branches/:branch
```

Parameters:

+ `id` (required) - The ID of the project.
+ `branch` (required) - The name of the branch.

Return values:

+ `200 Ok` on success
+ `404 Not Found` if either project with ID or branch could not be found


### Protect single branch

Protects a single branch of a project.

```
PUT /projects/:id/repository/branches/:branch/protect
```

Parameters:

+ `id` (required) - The ID of the project.
+ `branch` (required) - The name of the branch.

Return values:

+ `200 Ok` on success
+ `404 Not Found` if either project or branch could not be found


### Unprotect single branch

Unprotects a single branch of a project.

```
PUT /projects/:id/repository/branches/:branch/unprotect
```

Parameters:

+ `id` (required) - The ID of the project.
+ `branch` (required) - The name of the branch.

Return values:

+ `200 Ok` on success
+ `404 Not Found` if either project or branch could not be found


### List tags

Lists all tags of a project.

```
GET /projects/:id/repository/tags
```

Parameters:

+ `id` (required) - The ID of the project

Return values:

+ `200 Ok` on success and a list of tags
+ `404 Not Found` if project with id not found


### List commits

Lists all commits with pagination. If the optional `ref_name` name is not given the commits of
the default branch (usually master) are returned.

```
GET /projects/:id/repository/commits
```

Parameters:

+ `id` (required) - The Id of the project
+ `ref_name` (optional) - The name of a repository branch or tag
+ `page` (optional) - The page of commits to return (`0` default)
+ `per_page` (optional) - The number of commits per page (`20` default)

Returns values:

+ `200 Ok` on success and a list with commits
+ `404 Not Found` if project with id or the branch with `ref_name` not found


## Snippets

### List snippets

Lists the snippets of a project.

```
GET /projects/:id/snippets
```

Parameters:

+ `id` (required) - The ID of the project

Return values:

+ `200 Ok` on success and the list of snippets
+ `404 Not Found` if project with id not found


### List single snippet

Lists a single snippet of a project

```
GET /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID of the project
+ `snippet_id` (required) - The ID of the snippet

Return values:

+ `200 Ok` on success and the project snippet
+ `404 Not Found` if project ID or snippet ID not found


### Create snippet

Creates a new project snippet.

```
POST /projects/:id/snippets
```

Parameters:

+ `id` (required) - The ID of the project
+ `title` (required) - The title of the new snippet
+ `file_name` (required) - The file name of the snippet
+ `code` (required) - The content of the snippet
+ `lifetime` (optional) - The expiration date of a snippet

Return values:

+ `201 Created` on success and the new snippet
+ `400 Bad Request` if one of the required attributes is missing
+ `401 Unauthorized` if it is not allowed to post a new snippet
+ `404 Not Found` if the project ID is not found


### Update snippet

Updates an existing project snippet.

```
PUT /projects/:id/snippets/:snippet_id
```

Parameters:

+ `id` (required) - The ID of the project
+ `snippet_id` (required) - The id of the project snippet
+ `title` (optional) - The new title of the project snippet
+ `file_name` (optional) - The new file name of the project snippet
+ `lifetime` (optional) - The new expiration date of the snippet
+ `code` (optional) - The content of the snippet

Return values:

+ `200 Ok` on success and the content of the updated snippet
+ `401 Unauthorized` if the user is not allowed to modify the snippet
+ `404 Not Found` if project ID or snippet ID is not found


## Delete snippet

Deletes a project snippet. This is an idempotent function call and returns `200 Ok`
even if the snippet with the id is not available.

```
DELETE /projects/:id/snippets/:snippet_id
```

Paramaters:

+ `id` (required) - The ID of the project
+ `snippet_id` (required) - The ID of the snippet

Return values:

+ `200 Ok` on success, if the snippet got deleted it is returned, if not available then an empty JSON response
+ `401 Unauthorized` if the user is not allowed to remove the snippet
+ `404 Not Found` if the project ID not found
