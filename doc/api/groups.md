# Groups

Every API call to groups must be authenticated. If a user is not a member of a
group or the group contains at least one private project, all API calls return
a 403 status code.

## Namespaces in groups

By default, groups only get 20 namespaces at a time because the API results are
paginated.

To get more (up to 100), pass the following as an argument to the API call:

```
/groups?per_page=100
```

And to switch pages add:
```
/groups?per_page=100&page=2
```

## List project groups

Get a list of a user's groups. Admins get a list of all groups.

```
GET /groups
```

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups
```

Example response:

```json
[
   {
      "id" : 3,
      "name" : "Gitlab Org",
      "description" : "Quae magnam libero provident non illum quidem vel fugit.",
      "path" : "gitlab-org",
      "avatar_url" : null,
      "web_url" : "http://gitlab.example.com/groups/gitlab-org"
   },
]
```

## Details of a group

Get all details of a group by searching by name or by path.

Every authenticated user can see the details of a group if there are no private
projects in it.

```
GET /groups/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID or path of a group |

Example response:

```json
[
{
  "web_url" : "http://gitlab.example.com/groups/gitlab-org",
  "description" : "Quae magnam libero provident non illum quidem vel fugit.",
  "name" : "Gitlab Org",
  "avatar_url" : null,
  "path" : "gitlab-org",
  "id" : 3,
  "projects" : [
     {
        "tag_list" : [],
        "path" : "gitlab-test",
        "forks_count" : 0,
        "default_branch" : "master",
        "wiki_enabled" : true,
        "last_activity_at" : "2015-09-15T18:34:17.834Z",
        "http_url_to_repo" : "http://gitlab.example.com/gitlab-org/gitlab-test.git",
        "archived" : false,
        "id" : 5,
        "star_count" : 0,
        "avatar_url" : null,
        "path_with_namespace" : "gitlab-org/gitlab-test",
        "web_url" : "http://gitlab.example.com/gitlab-org/gitlab-test",
        "merge_requests_enabled" : true,
        "name_with_namespace" : "Gitlab Org / Gitlab Test",
        "creator_id" : 1,
        "snippets_enabled" : false,
        "public" : true,
        "issues_enabled" : true,
        "namespace" : {
           "avatar" : {
              "url" : null
           },
           "owner_id" : null,
           "path" : "gitlab-org",
           "name" : "Gitlab Org",
           "created_at" : "2015-09-15T18:24:44.162Z",
           "updated_at" : "2015-09-15T18:24:44.162Z",
           "description" : "Quae magnam libero provident non illum quidem vel fugit.",
           "id" : 3
        },
        "name" : "Gitlab Test",
        "created_at" : "2015-09-15T18:27:31.969Z",
        "ssh_url_to_repo" : "axil@gitlab.example.com:gitlab-org/gitlab-test.git",
        "visibility_level" : 20,
        "description" : "Veritatis harum culpa perferendis odit voluptates vel et."
     },
]
```

## New group

Creates a new group. Available only for users who can create groups.

```
POST /groups
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | yes | The name of the group |
| `path` | string | yes | The path of the group |
| `description` | string | no | The group's description |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/groups?path=my-group&name=My%20group"
```

Example response:

```json
{
   "web_url" : "https://gitlab.example.com/groups/my-group",
   "id" : 33,
   "avatar_url" : null,
   "description" : "",
   "name" : "My group",
   "path" : "my-group"
}
```

## Transfer project to group

Transfer a project to a Group namespace. Available only for admins.

```
POST  /groups/:id/projects/:project_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`         | integer | yes | The ID of a group |
| `project_id` | integer | yes | The ID of a project |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/2/projects/9
```

Example response:

```json
{
   "owner_id" : null,
   "path" : "gitlab-org",
   "created_at" : "2015-09-15T18:24:44.162Z",
   "avatar" : {
      "url" : null
   },
   "updated_at" : "2015-09-15T18:24:44.162Z",
   "id" : 3,
   "description" : "Quae magnam libero provident non illum quidem vel fugit.",
   "name" : "Gitlab Org"
}
```

## Remove group

Removes a group and all its projects.

```
DELETE /groups/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or path of a group |

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/my-group
```

Example response:

```json
{
   "avatar" : {
      "url" : null
   },
   "created_at" : "2015-10-29T12:29:50.407Z",
   "updated_at" : "2015-10-29T12:29:50.407Z",
   "description" : "",
   "path" : "my-group",
   "name" : "My group",
   "id" : 33,
   "owner_id" : null
}
```

## Search for group

Get all groups that match a string in their name or path.

```
GET /groups?search=foobar
```

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/groups?search=gitlab"
```

Example response:

```json
[
   {
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/groups/gitlab-org",
      "path" : "gitlab-org",
      "name" : "Gitlab Org",
      "id" : 3,
      "description" : "Quae magnam libero provident non illum quidem vel fugit."
   }
]
```

## Group members

**Group access levels**

The group access levels are defined in the `Gitlab::Access` module. Currently,
these levels are recognized:

```
GUEST     = 10
REPORTER  = 20
DEVELOPER = 30
MASTER    = 40
OWNER     = 50
```

### List group members

Get a list of group members viewable by the authenticated user.

```
GET /groups/:id/members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of a group |

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/3/members
```

Example response:

```json
[
   {
      "username" : "peyton",
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/u/peyton",
      "state" : "active",
      "id" : 11,
      "name" : "Sarai Walter",
      "access_level" : 20
   },
   {
      "access_level" : 20,
      "name" : "Mallie Jacobs",
      "id" : 5,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/u/hazle",
      "avatar_url" : null,
      "username" : "hazle"
   },
]
```

### Add group member

Adds a user to the list of group members.

```
POST /groups/:id/members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of a group |
| `user_id` | integer | yes | The ID of a user to add |
| `access_level` | integer | yes | The access level a user will have |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/groups/3/members?user_id=7&access_level=30"
```

Example response:

```json
{
   "web_url" : "https://gitlab.example.com/u/laurine",
   "username" : "laurine",
   "state" : "active",
   "id" : 7,
   "access_level" : 30,
   "name" : "Dr. Meta Fritsch",
   "avatar_url" : null
}
```

### Edit group team member

Updates a group team member to a specified access level.

```
PUT /groups/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of a group |
| `user_id` | integer | yes | The ID of a user to add |
| `access_level` | integer | yes | The group access level a user will have |

```bash
curl -X POST -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/groups/3/members/7?access_level=20"
```

Example response:

```json
{
   "web_url" : "https://gitlab.example.com/u/laurine",
   "username" : "laurine",
   "state" : "active",
   "id" : 7,
   "access_level" : 20,
   "name" : "Dr. Meta Fritsch",
   "avatar_url" : null
}
```

### Remove user from group

Removes a user from a group.

```
DELETE /groups/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of a group |
| `user_id` | integer | yes | The ID of a user to add |

```bash
curl -X DELETE -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/groups/3/members/7"
```

Example response:

```json
{
   "source_type" : "Namespace",
   "invite_accepted_at" : null,
   "updated_at" : "2015-10-29T15:11:59.687Z",
   "notification_level" : 3,
   "id" : 60,
   "invite_token" : null,
   "access_level" : 10,
   "created_at" : "2015-10-29T15:02:39.659Z",
   "created_by_id" : 26,
   "invite_email" : null,
   "user_id" : 7,
   "source_id" : 3
}
```
