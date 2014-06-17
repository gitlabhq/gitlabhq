# Projects

### List projects

Get a list of projects accessible by the authenticated user.

```
GET /projects
```

```json
[
  {
    "id": 4,
    "description": null,
    "default_branch": "master",
    "public": false,
    "visibility_level": 0,
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13: 46: 02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "created_at": "2013-09-30T13: 46: 02Z",
    "last_activity_at": "2013-09-30T13: 46: 02Z",
    "namespace": {
      "created_at": "2013-09-30T13: 46: 02Z",
      "description": "",
      "id": 3,
      "name": "Diaspora",
      "owner_id": 1,
      "path": "diaspora",
      "updated_at": "2013-09-30T13: 46: 02Z"
    },
    "archived": false
  },
  {
    "id": 6,
    "description": null,
    "default_branch": "master",
    "public": false,
    "visibility_level": 0,
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "namespace": {
      "created_at": "2013-09-30T13:46:02Z",
      "description": "",
      "id": 4,
      "name": "Brightbox",
      "owner_id": 1,
      "path": "brightbox",
      "updated_at": "2013-09-30T13:46:02Z"
    },
    "archived": false
  }
]
```


#### List owned projects

Get a list of projects owned by the authenticated user.

```
GET /projects/owned
```

#### List ALL projects

Get a list of all GitLab projects (admin only).

```
GET /projects/all
```

### Get single project

Get a specific project, identified by project ID or NAMESPACE/PROJECT_NAME , which is owned by the authentication user.
If using namespaced projects call make sure that the NAMESPACE/PROJECT_NAME is URL-encoded, eg. `/api/v3/projects/diaspora%2Fdiaspora` (where `/` is represented by `%2F`).

```
GET /projects/:id
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project

```json
{
  "id": 3,
  "description": null,
  "default_branch": "master",
  "public": false,
  "visibility_level": 0,
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13: 46: 02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "created_at": "2013-09-30T13: 46: 02Z",
  "last_activity_at": "2013-09-30T13: 46: 02Z",
  "namespace": {
    "created_at": "2013-09-30T13: 46: 02Z",
    "description": "",
    "id": 3,
    "name": "Diaspora",
    "owner_id": 1,
    "path": "diaspora",
    "updated_at": "2013-09-30T13: 46: 02Z"
  },
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false
}
```

### Get project events

Get a project events for specific project.
Sorted from newest to latest

```
GET /projects/:id/events
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project

```json
[
  {
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 830,
    "target_type": "Issue",
    "author_id": 1,
    "data": null,
    "target_title": "Public project search field"
  },
  {
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
      "commits": [
        {
          "id": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
          "message": "Add simple search to projects in public area",
          "timestamp": "2013-05-13T18:18:08+00:00",
          "url": "https://dev.gitlab.org/gitlab/gitlabhq/commit/c5feabde2d8cd023215af4d2ceeb7a64839fc428",
          "author": {
            "name": "Dmitriy Zaporozhets",
            "email": "dmitriy.zaporozhets@gmail.com"
          }
        }
      ],
      "total_commits_count": 1
    },
    "target_title": null
  },
  {
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 840,
    "target_type": "Issue",
    "author_id": 1,
    "data": null,
    "target_title": "Finish & merge Code search PR"
  }
]
```


### Create project

Creates new project owned by user.

```
POST /projects
```

Parameters:

+ `name` (required) - new project name
+ `namespace_id` (optional) - namespace for the new project (defaults to user)
+ `description` (optional) - short project description
+ `issues_enabled` (optional)
+ `merge_requests_enabled` (optional)
+ `wiki_enabled` (optional) 
+ `snippets_enabled` (optional)
+ `public` (optional) - if `true` same as setting visibility_level = 20
+ `visibility_level` (optional)
* `import_url` (optional)


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
+ `issues_enabled` (optional)
+ `merge_requests_enabled` (optional)
+ `wiki_enabled` (optional) 
+ `snippets_enabled` (optional)
+ `public` (optional) - if `true` same as setting visibility_level = 20
+ `visibility_level` (optional)


## Remove project

Removes project with all resources(issues, merge requests etc)

```
DELETE /projects/:id
```

Parameters:

+ `id` (required) - The ID of a project


## Team members

### List project team members

Get a list of project team members.

```
GET /projects/:id/members
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `query` (optional) - Query string to search for members


### Get project team member

Gets a project team member.

```
GET /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `user_id` (required) - The ID of a user

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
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

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `user_id` (required) - The ID of a user to add
+ `access_level` (required) - Project access level


### Edit project team member

Updates project team member to a specified access level.

```
PUT /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `user_id` (required) - The ID of a team member
+ `access_level` (required) - Project access level


### Remove project team member

Removes user from project team.

```
DELETE /projects/:id/members/:user_id
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
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

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project


### Get project hook

Get a specific hook for project.

```
GET /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `hook_id` (required) - The ID of a project hook

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "project_id": 3,
  "push_events": "true",
  "issues_events": "true",
  "merge_requests_events": "true",
  "created_at": "2012-10-12T17:04:47Z"
}
```


### Add project hook

Adds a hook to project.

```
POST /projects/:id/hooks
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `url` (required) - The hook URL
+ `push_events` - Trigger hook on push events
+ `issues_events` - Trigger hook on issues events
+ `merge_requests_events` - Trigger hook on merge_requests events


### Edit project hook

Edits a hook for project.

```
PUT /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `hook_id` (required) - The ID of a project hook
+ `url` (required) - The hook URL
+ `push_events` - Trigger hook on push events
+ `issues_events` - Trigger hook on issues events
+ `merge_requests_events` - Trigger hook on merge_requests events


### Delete project hook

Removes a hook from project. This is an idempotent method and can be called multiple times.
Either the hook is available or not.

```
DELETE /projects/:id/hooks/:hook_id
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
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

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project

```json
[
  {
    "name": "async",
    "commit": {
      "id": "a2b702edecdf41f07b42653eb1abe30ce98b9fca",
      "parents": [
        {
          "id": "3f94fc7c85061973edc9906ae170cc269b07ca55"
        }
      ],
      "tree": "c68537c6534a02cc2b176ca1549f4ffa190b58ee",
      "message": "give caolan credit where it's due (up top)",
      "author": {
        "name": "Jeremy Ashkenas",
        "email": "jashkenas@example.com"
      },
      "committer": {
        "name": "Jeremy Ashkenas",
        "email": "jashkenas@example.com"
      },
      "authored_date": "2010-12-08T21:28:50+00:00",
      "committed_date": "2010-12-08T21:28:50+00:00"
    },
    "protected": false
  },
  {
    "name": "gh-pages",
    "commit": {
      "id": "101c10a60019fe870d21868835f65c25d64968fc",
      "parents": [
        {
          "id": "9c15d2e26945a665131af5d7b6d30a06ba338aaa"
        }
      ],
      "tree": "fb5cc9d45da3014b17a876ad539976a0fb9b352a",
      "message": "Underscore.js 1.5.2",
      "author": {
        "name": "Jeremy Ashkenas",
        "email": "jashkenas@example.com"
      },
      "committer": {
        "name": "Jeremy Ashkenas",
        "email": "jashkenas@example.com"
      },
      "authored_date": "2013-09-07T12: 58: 21+00: 00",
      "committed_date": "2013-09-07T12: 58: 21+00: 00"
    },
    "protected": false
  }
]
```

### List single branch

Lists a specific branch of a project.

```
GET /projects/:id/repository/branches/:branch
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `branch` (required) - The name of the branch.


### Protect single branch

Protects a single branch of a project.

```
PUT /projects/:id/repository/branches/:branch/protect
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `branch` (required) - The name of the branch.


### Unprotect single branch

Unprotects a single branch of a project.

```
PUT /projects/:id/repository/branches/:branch/unprotect
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
+ `branch` (required) - The name of the branch.


## Admin fork relation

Allows modification of the forked relationship between existing projects. . Available only for admins.

### Create a forked from/to relation between existing projects.

```
POST /projects/:id/fork/:forked_from_id
```

Parameters:

+ `id` (required) - The ID of the project
+ `forked_from_id:` (required) - The ID of the project that was forked from

### Delete an existing forked from relationship

```
DELETE /projects/:id/fork
```

Parameter:

+ `id` (required) - The ID of the project


## Search for projects by name

Search for projects by name which are public or the calling user has access to

```
GET /projects/search/:query
```

Parameters:

+   query (required) - A string contained in the project name
+   per_page (optional) - number of projects to return per page
+   page (optional) - the page to retrieve


## Labels

### List project labels

Get a list of project labels.

```
GET /projects/:id/labels
```

Parameters:

+ `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project

```json
[
  {
    "name": "feature"
  },
  {
    "name": "bug"
  }
]
```
