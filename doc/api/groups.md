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
      "created_at": "2013-09-30T13: 46: 02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "builds_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "created_at": "2013-09-30T13: 46: 02Z",
    "last_activity_at": "2013-09-30T13: 46: 02Z",
    "creator_id": 3,
    "namespace": {
      "created_at": "2013-09-30T13: 46: 02Z",
      "description": "",
      "id": 3,
      "name": "Diaspora",
      "owner_id": 1,
      "path": "diaspora",
      "updated_at": "2013-09-30T13: 46: 02Z"
    },
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png"
  }
]
```

## Details of a group

Get all details of a group.

```
GET /groups/:id
```

Parameters:

- `id` (required) - The ID or path of a group

## New group

Creates a new project group. Available only for users who can create groups.

```
POST /groups
```

Parameters:

- `name` (required) - The name of the group
- `path` (required) - The path of the group
- `description` (optional) - The group's description
- `membership_lock` (optional, boolean) - Prevent adding new members to project membership within this group
- `share_with_group_lock` (optional, boolean) - Prevent sharing a project with another group within this group

## Update group

Updates a project group. Available only for users who can manage this group.

```
PUT /groups/:id
```

Parameters:

- `name` (required) - The name of the group
- `path` (required) - The path of the group
- `description` (optional) - The group's description
- `membership_lock` (optional, boolean) - Prevent adding new members to project membership within this group
- `share_with_group_lock` (optional, boolean) - Prevent sharing a project with another group within this group
- `visibility_level` (optional) - The group's visibility. 0 for private, 10 for internal, 20 for public.

## Transfer project to group

Transfer a project to the Group namespace. Available only for admin

```
POST  /groups/:id/projects/:project_id
```

Parameters:

- `id` (required) - The ID or path of a group
- `project_id` (required) - The ID of a project

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

**Group access levels**

The group access levels are defined in the `Gitlab::Access` module. Currently, these levels are recognized:

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

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "email": "ray@smith.org",
    "name": "Raymond Smith",
    "state": "active",
    "created_at": "2012-10-22T14:13:35Z",
    "access_level": 30
  },
  {
    "id": 2,
    "username": "john_doe",
    "email": "joh@doe.org",
    "name": "John Doe",
    "state": "active",
    "created_at": "2012-10-22T14:13:35Z",
    "access_level": 30
  }
]
```

### Add group member

Adds a user to the list of group members.

```
POST /groups/:id/members
```

Parameters:

- `id` (required) - The ID or path of a group
- `user_id` (required) - The ID of a user to add
- `access_level` (required) - Project access level

### Edit group team member

Updates a group team member to a specified access level.

```
PUT /groups/:id/members/:user_id
```

Parameters:

- `id` (required) - The ID of a group
- `user_id` (required) - The ID of a group member
- `access_level` (required) - Project access level

### Remove user team member

Removes user from user team.

```
DELETE /groups/:id/members/:user_id
```

Parameters:

- `id` (required) - The ID or path of a user group
- `user_id` (required) - The ID of a group member

### Add LDAP group link

Adds LDAP group link

```
POST /groups/:id/ldap_group_links
```

Parameters:

- `id` (required) - The ID of a group
- `cn` (required) - The CN of a LDAP group
- `group_access` (required) - Minimum access level for members of the LDAP group
- `provider` (required) - LDAP provider for the LDAP group (when using several providers) 

### Delete LDAP group link

Deletes a LDAP group link

```
DELETE /groups/:id/ldap_group_links/:cn
```

Parameters:

- `id` (required) - The ID of a group
- `cn` (required) - The CN of a LDAP group

Deletes a LDAP group link for a specific LDAP provider

```
DELETE /groups/:id/ldap_group_links/:provider/:cn
```

Parameters:

- `id` (required) - The ID of a group
- `cn` (required) - The CN of a LDAP group
- `provider` (required) - Name of a LDAP provider

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
