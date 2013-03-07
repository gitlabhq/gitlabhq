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
        "owner_id": 18
    }
]
```


## Details of a group

Get all details of a group.

```
GET /groups/:id
```

Parameters:

+ `id` (required) - The ID of a group


## New group

Creates a new project group. Available only for admin.

```
POST /groups
```

Parameters:

+ `name` (required) - The name of the group
+ `path` (required) - The path of the group

## Transfer project to group

Transfer a project to the Group namespace. Available only for admin

```
POST  /groups/:id/projects/:project_id
```

Parameters:
+ `id` (required) - The ID of a group
+ `project_id (required) - The ID of a project
