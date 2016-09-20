# Groups

## List groups

Get a list of groups. (As user: my groups, as admin: all groups)

```
GET /groups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group"
  }
]
```

You can search for groups by name or path, see below.


## List a group's projects

Get a list of projects in this group.

```
GET /groups/:id/projects
```

Parameters:

- `archived` (optional) - if passed, limit by archived status
- `visibility` (optional) - if passed, limit by visibility `public`, `internal`, `private`
- `order_by` (optional) - Return requests ordered by `id`, `name`, `path`, `created_at`, `updated_at` or `last_activity_at` fields. Default is `created_at`
- `sort` (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
- `search` (optional) - Return list of authorized projects according to a search criteria
- `ci_enabled_first` - Return projects ordered by ci_enabled flag. Projects with enabled GitLab CI go first

```json
[
  {
    "id": 9,
    "description": "foo",
    "default_branch": "master",
    "tag_list": [],
    "public": false,
    "archived": false,
    "visibility_level": 10,
    "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
    "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
    "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
    "name": "Html5 Boilerplate",
    "name_with_namespace": "Experimental / Html5 Boilerplate",
    "path": "html5-boilerplate",
    "path_with_namespace": "h5bp/html5-boilerplate",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "builds_enabled": true,
    "snippets_enabled": true,
    "created_at": "2016-04-05T21:40:50.169Z",
    "last_activity_at": "2016-04-06T16:52:08.432Z",
    "shared_runners_enabled": true,
    "creator_id": 1,
    "namespace": {
      "id": 5,
      "name": "Experimental",
      "path": "h5bp",
      "owner_id": null,
      "created_at": "2016-04-05T21:40:49.152Z",
      "updated_at": "2016-04-07T08:07:48.466Z",
      "description": "foo",
      "avatar": {
        "url": null
      },
      "share_with_group_lock": false,
      "visibility_level": 10
    },
    "avatar_url": null,
    "star_count": 1,
    "forks_count": 0,
    "open_issues_count": 3,
    "public_builds": true,
    "shared_with_groups": [],
    "request_access_enabled": false
  }
]
```

## Details of a group

Get all details of a group.

```
GET /groups/:id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or path of a group |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/4
```

Example response:

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility_level": 20,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "projects": [
    {
      "id": 7,
      "description": "Voluptas veniam qui et beatae voluptas doloremque explicabo facilis.",
      "default_branch": "master",
      "tag_list": [],
      "public": true,
      "archived": false,
      "visibility_level": 20,
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/typeahead-js.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/typeahead-js.git",
      "web_url": "https://gitlab.example.com/twitter/typeahead-js",
      "name": "Typeahead.Js",
      "name_with_namespace": "Twitter / Typeahead.Js",
      "path": "typeahead-js",
      "path_with_namespace": "twitter/typeahead-js",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "builds_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:25.578Z",
      "last_activity_at": "2016-06-17T07:47:25.881Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "owner_id": null,
        "created_at": "2016-06-17T07:47:24.216Z",
        "updated_at": "2016-06-17T07:47:24.216Z",
        "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
        "avatar": {
          "url": null
        },
        "share_with_group_lock": false,
        "visibility_level": 20
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_builds": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    },
    {
      "id": 6,
      "description": "Aspernatur omnis repudiandae qui voluptatibus eaque.",
      "default_branch": "master",
      "tag_list": [],
      "public": false,
      "archived": false,
      "visibility_level": 10,
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/flight.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/flight.git",
      "web_url": "https://gitlab.example.com/twitter/flight",
      "name": "Flight",
      "name_with_namespace": "Twitter / Flight",
      "path": "flight",
      "path_with_namespace": "twitter/flight",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "builds_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:24.661Z",
      "last_activity_at": "2016-06-17T07:47:24.838Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "owner_id": null,
        "created_at": "2016-06-17T07:47:24.216Z",
        "updated_at": "2016-06-17T07:47:24.216Z",
        "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
        "avatar": {
          "url": null
        },
        "share_with_group_lock": false,
        "visibility_level": 20
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 8,
      "public_builds": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "shared_projects": [
    {
      "id": 8,
      "description": "Velit eveniet provident fugiat saepe eligendi autem.",
      "default_branch": "master",
      "tag_list": [],
      "public": false,
      "archived": false,
      "visibility_level": 0,
      "ssh_url_to_repo": "git@gitlab.example.com:h5bp/html5-boilerplate.git",
      "http_url_to_repo": "https://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "https://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "H5bp / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "builds_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:27.089Z",
      "last_activity_at": "2016-06-17T07:47:27.310Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "H5bp",
        "path": "h5bp",
        "owner_id": null,
        "created_at": "2016-06-17T07:47:26.621Z",
        "updated_at": "2016-06-17T07:47:26.621Z",
        "description": "Id consequatur rem vel qui doloremque saepe.",
        "avatar": {
          "url": null
        },
        "share_with_group_lock": false,
        "visibility_level": 20
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 4,
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
      ]
    }
  ]
}
```

## New group

Creates a new project group. Available only for users who can create groups.

```
POST /groups
```

Parameters:

- `name` (required) - The name of the group
- `path` (required) - The path of the group
- `description` (optional) - The group's description
- `visibility_level` (optional) - The group's visibility. 0 for private, 10 for internal, 20 for public.
- `lfs_enabled` (optional)      - Enable/disable Large File Storage (LFS) for the projects in this group
- `request_access_enabled` (optional) - Allow users to request member access.

## Transfer project to group

Transfer a project to the Group namespace. Available only for admin

```
POST  /groups/:id/projects/:project_id
```

Parameters:

- `id` (required) - The ID or path of a group
- `project_id` (required) - The ID of a project

## Update group

Updates the project group. Only available to group owners and administrators.

```
PUT /groups/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the group |
| `name` | string | no | The name of the group |
| `path` | string | no | The path of the group |
| `description` | string | no | The description of the group |
| `visibility_level` | integer | no | The visibility level of the group. 0 for private, 10 for internal, 20 for public. |
| `lfs_enabled` (optional) | boolean | no | Enable/disable Large File Storage (LFS) for the projects in this group |
| `request_access_enabled` | boolean | no | Allow users to request member access. |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/groups/5?name=Experimental"

```

Example response:

```json
{
  "id": 5,
  "name": "Experimental",
  "path": "h5bp",
  "description": "foo",
  "visibility_level": 10,
  "avatar_url": null,
  "web_url": "http://gitlab.example.com/groups/h5bp",
  "request_access_enabled": false,
  "projects": [
    {
      "id": 9,
      "description": "foo",
      "default_branch": "master",
      "tag_list": [],
      "public": false,
      "archived": false,
      "visibility_level": 10,
      "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
      "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "Experimental / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "builds_enabled": true,
      "snippets_enabled": true,
      "created_at": "2016-04-05T21:40:50.169Z",
      "last_activity_at": "2016-04-06T16:52:08.432Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "Experimental",
        "path": "h5bp",
        "owner_id": null,
        "created_at": "2016-04-05T21:40:49.152Z",
        "updated_at": "2016-04-07T08:07:48.466Z",
        "description": "foo",
        "avatar": {
          "url": null
        },
        "share_with_group_lock": false,
        "visibility_level": 10
      },
      "avatar_url": null,
      "star_count": 1,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_builds": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ]
}
```

## Remove group

Removes group with all projects inside.

```
DELETE /groups/:id
```

Parameters:

- `id` (required) - The ID or path of a user group

## Search for group

Get all groups that match your string in their name or path.

```
GET /groups?search=foobar
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group"
  }
]
```

## Group members

Please consult the [Group Members](members.md) documentation.

## Namespaces in groups

By default, groups only get 20 namespaces at a time because the API results are paginated.

To get more (up to 100), pass the following as an argument to the API call:
```
/groups?per_page=100
```

And to switch pages add:
```
/groups?per_page=100&page=2
```
