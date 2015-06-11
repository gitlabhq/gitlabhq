# Groups

## List project groups

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