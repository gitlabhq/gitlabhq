# Projects


### Project visibility level

Project in GitLab has be either private, internal or public.
You can determine it by `visibility_level` field in project.

Constants for project visibility levels are next:

* Private. `visibility_level` is `0`.
  Project access must be granted explicitly for each user.

* Internal. `visibility_level` is `10`.
  The project can be cloned by any logged in user.

* Public. `visibility_level` is `20`.
  The project can be cloned without any authentication.


## List projects

Get a list of projects accessible by the authenticated user.

```
GET /projects
```

Parameters:

- `archived` (optional) - if passed, limit by archived status
- `visibility` (optional) - if passed, limit by visibility `public`, `internal`, `private`
- `order_by` (optional) - Return requests ordered by `id`, `name`, `path`, `created_at`, `updated_at` or `last_activity_at` fields. Default is `created_at`
- `sort` (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
- `search` (optional) - Return list of authorized projects according to a search criteria

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
    "tag_list": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "builds_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "created_at": "2013-09-30T13:46:02Z",
      "description": "",
      "id": 3,
      "name": "Diaspora",
      "owner_id": 1,
      "path": "diaspora",
      "updated_at": "2013-09-30T13:46:02Z"
    },
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_builds": true,
    "shared_with_groups": [],
    "only_allow_merge_if_build_succeeds": false,
    "request_access_enabled": false
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
    "tag_list": [
      "example",
      "puppet"
    ],
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
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "builds_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "created_at": "2013-09-30T13:46:02Z",
      "description": "",
      "id": 4,
      "name": "Brightbox",
      "owner_id": 1,
      "path": "brightbox",
      "updated_at": "2013-09-30T13:46:02Z"
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
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_builds": true,
    "shared_with_groups": [],
    "only_allow_merge_if_build_succeeds": false,
    "request_access_enabled": false
  }
]
```

### List owned projects

Get a list of projects which are owned by the authenticated user.

```
GET /projects/owned
```

Parameters:

- `archived` (optional) - if passed, limit by archived status
- `visibility` (optional) - if passed, limit by visibility `public`, `internal`, `private`
- `order_by` (optional) - Return requests ordered by `id`, `name`, `path`, `created_at`, `updated_at` or `last_activity_at` fields. Default is `created_at`
- `sort` (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
- `search` (optional) - Return list of authorized projects according to a search criteria

### List starred projects

Get a list of projects which are starred by the authenticated user.

```
GET /projects/starred
```

Parameters:

- `archived` (optional) - if passed, limit by archived status
- `visibility` (optional) - if passed, limit by visibility `public`, `internal`, `private`
- `order_by` (optional) - Return requests ordered by `id`, `name`, `path`, `created_at`, `updated_at` or `last_activity_at` fields. Default is `created_at`
- `sort` (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
- `search` (optional) - Return list of authorized projects according to a search criteria

### List ALL projects

Get a list of all GitLab projects (admin only).

```
GET /projects/all
```

Parameters:

- `archived` (optional) - if passed, limit by archived status
- `visibility` (optional) - if passed, limit by visibility `public`, `internal`, `private`
- `order_by` (optional) - Return requests ordered by `id`, `name`, `path`, `created_at`, `updated_at` or `last_activity_at` fields. Default is `created_at`
- `sort` (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
- `search` (optional) - Return list of authorized projects according to a search criteria

### Get single project

Get a specific project, identified by project ID or NAMESPACE/PROJECT_NAME, which is owned by the authenticated user.
If using namespaced projects call make sure that the NAMESPACE/PROJECT_NAME is URL-encoded, eg. `/api/v3/projects/diaspora%2Fdiaspora` (where `/` is represented by `%2F`).

```
GET /projects/:id
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project

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
  "tag_list": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "builds_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "created_at": "2013-09-30T13:46:02Z",
    "description": "",
    "id": 3,
    "name": "Diaspora",
    "owner_id": 1,
    "path": "diaspora",
    "updated_at": "2013-09-30T13:46:02Z"
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
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "shared_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "public_builds": true,
  "shared_with_groups": [
    {
      "group_id": 4,
      "group_name": "Twitter",
      "group_access_level": 30
    },
    {
      "group_id": 3,
      "group_name": "Gitlab Org",
      "group_access_level": 10
    }
  ],
  "only_allow_merge_if_build_succeeds": false,
  "request_access_enabled": false
}
```

### Get project events

Get the events for the specified project.
Sorted from newest to latest

```
GET /projects/:id/events
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project

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
    "target_title": "Public project search field",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/u/root"
    },
    "author_username": "root"
  },
  {
    "title": null,
    "project_id": 15,
    "action_name": "opened",
    "target_id": null,
    "target_type": null,
    "author_id": 1,
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/u/root"
    },
    "author_username": "john",
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
    "target_title": "Finish & merge Code search PR",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/u/root"
    },
    "author_username": "root"
  },
  {
    "title": null,
    "project_id": 15,
    "action_name": "commented on",
    "target_id": 1312,
    "target_type": "Note",
    "author_id": 1,
    "data": null,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "http://localhost:3000/u/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "upvote": false,
      "downvote": false,
      "noteable_id": 377,
      "noteable_type": "Issue"
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/u/root"
    },
    "author_username": "root"
  }
]
```

### Create project

Creates a new project owned by the authenticated user.

```
POST /projects
```

Parameters:

- `name` (required) - new project name
- `path` (optional) - custom repository name for new project. By default generated based on name
- `namespace_id` (optional) - namespace for the new project (defaults to user)
- `description` (optional) - short project description
- `issues_enabled` (optional)
- `merge_requests_enabled` (optional)
- `builds_enabled` (optional)
- `wiki_enabled` (optional)
- `snippets_enabled` (optional)
- `container_registry_enabled` (optional)
- `shared_runners_enabled` (optional)
- `public` (optional) - if `true` same as setting visibility_level = 20
- `visibility_level` (optional)
- `import_url` (optional)
- `public_builds` (optional)
- `only_allow_merge_if_build_succeeds` (optional)
- `lfs_enabled` (optional)
- `request_access_enabled` (optional) - Allow users to request member access.

### Create project for user

Creates a new project owned by the specified user. Available only for admins.

```
POST /projects/user/:user_id
```

Parameters:

- `user_id` (required) - user_id of owner
- `name` (required) - new project name
- `description` (optional) - short project description
- `issues_enabled` (optional)
- `merge_requests_enabled` (optional)
- `builds_enabled` (optional)
- `wiki_enabled` (optional)
- `snippets_enabled` (optional)
- `container_registry_enabled` (optional)
- `shared_runners_enabled` (optional)
- `public` (optional) - if `true` same as setting visibility_level = 20
- `visibility_level` (optional)
- `import_url` (optional)
- `public_builds` (optional)
- `only_allow_merge_if_build_succeeds` (optional)
- `lfs_enabled` (optional)
- `request_access_enabled` (optional) - Allow users to request member access.

### Edit project

Updates an existing project

```
PUT /projects/:id
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
- `name` (optional) - project name
- `path` (optional) - repository name for project
- `description` (optional) - short project description
- `default_branch` (optional)
- `issues_enabled` (optional)
- `merge_requests_enabled` (optional)
- `builds_enabled` (optional)
- `wiki_enabled` (optional)
- `snippets_enabled` (optional)
- `container_registry_enabled` (optional)
- `shared_runners_enabled` (optional)
- `public` (optional) - if `true` same as setting visibility_level = 20
- `visibility_level` (optional)
- `public_builds` (optional)
- `only_allow_merge_if_build_succeeds` (optional)
- `lfs_enabled` (optional)
- `request_access_enabled` (optional) - Allow users to request member access.

On success, method returns 200 with the updated project. If parameters are
invalid, 400 is returned.

### Fork project

Forks a project into the user namespace of the authenticated user or the one provided.

```
POST /projects/fork/:id
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of the project to be forked
- `namespace` (optional) - The ID or path of the namespace that the project will be forked to

### Star a project

Stars a given project. Returns status code `201` and the project on success and
`304` if the project is already starred.

```
POST /projects/:id/star
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID of the project or NAMESPACE/PROJECT_NAME |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/5/star"
```

Example response:

```json
{
  "id": 3,
  "description": null,
  "default_branch": "master",
  "public": false,
  "visibility_level": 10,
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "tag_list": [
    "example",
    "disapora project"
  ],
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "builds_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "created_at": "2013-09-30T13:46:02Z",
    "description": "",
    "id": 3,
    "name": "Diaspora",
    "owner_id": 1,
    "path": "diaspora",
    "updated_at": "2013-09-30T13:46:02Z"
  },
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "shared_runners_enabled": true,
  "forks_count": 0,
  "star_count": 1,
  "public_builds": true,
  "shared_with_groups": [],
  "only_allow_merge_if_build_succeeds": false,
  "request_access_enabled": false
}
```

### Unstar a project

Unstars a given project. Returns status code `200` and the project on success
and `304` if the project is not starred.

```
DELETE /projects/:id/star
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID of the project or NAMESPACE/PROJECT_NAME |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/5/star"
```

Example response:

```json
{
  "id": 3,
  "description": null,
  "default_branch": "master",
  "public": false,
  "visibility_level": 10,
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "tag_list": [
    "example",
    "disapora project"
  ],
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "builds_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "created_at": "2013-09-30T13:46:02Z",
    "description": "",
    "id": 3,
    "name": "Diaspora",
    "owner_id": 1,
    "path": "diaspora",
    "updated_at": "2013-09-30T13:46:02Z"
  },
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "shared_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "public_builds": true,
  "shared_with_groups": [],
  "only_allow_merge_if_build_succeeds": false,
  "request_access_enabled": false
}
```

### Archive a project

Archives the project if the user is either admin or the project owner of this project. This action is
idempotent, thus archiving an already archived project will not change the project.

Status code 201 with the project as body is given when successful, in case the user doesn't
have the proper access rights, code 403 is returned. Status 404 is returned if the project
doesn't exist, or is hidden to the user.

```
POST /projects/:id/archive
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID of the project or NAMESPACE/PROJECT_NAME |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/archive"
```

Example response:

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
  "tag_list": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "builds_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "created_at": "2013-09-30T13:46:02Z",
    "description": "",
    "id": 3,
    "name": "Diaspora",
    "owner_id": 1,
    "path": "diaspora",
    "updated_at": "2013-09-30T13:46:02Z"
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
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "shared_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "public_builds": true,
  "shared_with_groups": [],
  "only_allow_merge_if_build_succeeds": false,
  "request_access_enabled": false
}
```

### Unarchive a project

Unarchives the project if the user is either admin or the project owner of this project. This action is
idempotent, thus unarchiving an non-archived project will not change the project.

Status code 201 with the project as body is given when successful, in case the user doesn't
have the proper access rights, code 403 is returned. Status 404 is returned if the project
doesn't exist, or is hidden to the user.

```
POST /projects/:id/unarchive
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID of the project or NAMESPACE/PROJECT_NAME |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/unarchive"
```

Example response:

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
  "tag_list": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "builds_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "created_at": "2013-09-30T13:46:02Z",
    "description": "",
    "id": 3,
    "name": "Diaspora",
    "owner_id": 1,
    "path": "diaspora",
    "updated_at": "2013-09-30T13:46:02Z"
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
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "shared_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "public_builds": true,
  "shared_with_groups": [],
  "only_allow_merge_if_build_succeeds": false,
  "request_access_enabled": false
}
```

### Remove project

Removes a project including all associated resources (issues, merge requests etc.)

```
DELETE /projects/:id
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of the project to be forked

## Uploads

### Upload a file

Uploads a file to the specified project to be used in an issue or merge request description, or a comment.

```
POST /projects/:id/uploads
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of the project to be forked
- `file` (required) - The file to be uploaded

```json
{
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

**Note**: The returned `url` is relative to the project path.
In Markdown contexts, the link is automatically expanded when the format in `markdown` is used.


## Project members

Please consult the [Project Members](members.md) documentation.

### Share project with group

Allow to share project with group.

```
POST /projects/:id/share
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of the project to be forked
- `group_id` (required) - The ID of a group
- `group_access` (required) - Level of permissions for sharing
- `expires_at` - Share expiration date in ISO 8601 format: 2016-09-26

## Hooks

Also called Project Hooks and Webhooks.
These are different for [System Hooks](system_hooks.md) that are system wide.

### List project hooks

Get a list of project hooks.

```
GET /projects/:id/hooks
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project

### Get project hook

Get a specific hook for a project.

```
GET /projects/:id/hooks/:hook_id
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
- `hook_id` (required) - The ID of a project hook

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "project_id": 3,
  "push_events": true,
  "issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "build_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "enable_ssl_verification": true,
  "created_at": "2012-10-12T17:04:47Z"
}
```

### Add project hook

Adds a hook to a specified project.

```
POST /projects/:id/hooks
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
- `url` (required) - The hook URL
- `push_events` - Trigger hook on push events
- `issues_events` - Trigger hook on issues events
- `merge_requests_events` - Trigger hook on merge_requests events
- `tag_push_events` - Trigger hook on push_tag events
- `note_events` - Trigger hook on note events
- `build_events` - Trigger hook on build events
- `pipeline_events` - Trigger hook on pipeline events
- `wiki_page_events` - Trigger hook on wiki page events
- `enable_ssl_verification` - Do SSL verification when triggering the hook

### Edit project hook

Edits a hook for a specified project.

```
PUT /projects/:id/hooks/:hook_id
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
- `hook_id` (required) - The ID of a project hook
- `url` (required) - The hook URL
- `push_events` - Trigger hook on push events
- `issues_events` - Trigger hook on issues events
- `merge_requests_events` - Trigger hook on merge_requests events
- `tag_push_events` - Trigger hook on push_tag events
- `note_events` - Trigger hook on note events
- `build_events` - Trigger hook on build events
- `pipeline_events` - Trigger hook on pipeline events
- `wiki_page_events` - Trigger hook on wiki page events
- `enable_ssl_verification` - Do SSL verification when triggering the hook

### Delete project hook

Removes a hook from a project. This is an idempotent method and can be called multiple times.
Either the hook is available or not.

```
DELETE /projects/:id/hooks/:hook_id
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
- `hook_id` (required) - The ID of hook to delete

Note the JSON response differs if the hook is available or not. If the project hook
is available before it is returned in the JSON response or an empty response is returned.

## Branches

For more information please consult the [Branches](branches.md) documentation.

### List branches

Lists all branches of a project.

```
GET /projects/:id/repository/branches
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project

```json
[
  {
    "name": "async",
    "commit": {
      "id": "a2b702edecdf41f07b42653eb1abe30ce98b9fca",
      "parent_ids": [
        "3f94fc7c85061973edc9906ae170cc269b07ca55"
      ],
      "message": "give Caolan credit where it's due (up top)",
      "author_name": "Jeremy Ashkenas",
      "author_email": "jashkenas@example.com",
      "authored_date": "2010-12-08T21:28:50+00:00",
      "committer_name": "Jeremy Ashkenas",
      "committer_email": "jashkenas@example.com",
      "committed_date": "2010-12-08T21:28:50+00:00"
    },
    "protected": false,
    "developers_can_push": false,
    "developers_can_merge": false
  },
  {
    "name": "gh-pages",
    "commit": {
      "id": "101c10a60019fe870d21868835f65c25d64968fc",
      "parent_ids": [
          "9c15d2e26945a665131af5d7b6d30a06ba338aaa"
      ],
      "message": "Underscore.js 1.5.2",
      "author_name": "Jeremy Ashkenas",
      "author_email": "jashkenas@example.com",
      "authored_date": "2013-09-07T12:58:21+00:00",
      "committer_name": "Jeremy Ashkenas",
      "committer_email": "jashkenas@example.com",
      "committed_date": "2013-09-07T12:58:21+00:00"
    },
    "protected": false,
    "developers_can_push": false,
    "developers_can_merge": false
  }
]
```

### Single branch

A specific branch of a project.

```
GET /projects/:id/repository/branches/:branch
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
- `branch` (required) - The name of the branch.
- `developers_can_push` - Flag if developers can push to the branch.
- `developers_can_merge` - Flag if developers can merge to the branch.

### Protect single branch

Protects a single branch of a project.

```
PUT /projects/:id/repository/branches/:branch/protect
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
- `branch` (required) - The name of the branch.

### Unprotect single branch

Unprotects a single branch of a project.

```
PUT /projects/:id/repository/branches/:branch/unprotect
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of a project
- `branch` (required) - The name of the branch.

## Admin fork relation

Allows modification of the forked relationship between existing projects. Available only for admins.

### Create a forked from/to relation between existing projects.

```
POST /projects/:id/fork/:forked_from_id
```

Parameters:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of the project to be forked
- `forked_from_id:` (required) - The ID of the project that was forked from

### Delete an existing forked from relationship

```
DELETE /projects/:id/fork
```

Parameter:

- `id` (required) - The ID or NAMESPACE/PROJECT_NAME of the project to be forked

## Search for projects by name

Search for projects by name which are accessible to the authenticated user.

```
GET /projects/search/:query
```

Parameters:

- `query` (required) - A string contained in the project name
- `per_page` (optional) - number of projects to return per page
- `page` (optional) - the page to retrieve
- `order_by` (optional) - Return requests ordered by `id`, `name`, `created_at` or `last_activity_at` fields
- `sort` (optional) - Return requests sorted in `asc` or `desc` order
