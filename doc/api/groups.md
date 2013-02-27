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

Return values:

+ `200 Ok` on success and list of groups
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if something fails


## Details of a group

Get all details of a group.

```
GET /groups/:id
```

Parameters:

+ `id` (required) - The ID of a group

Return values:

+ `200 Ok` on success and the details of a group
+ `401 Unauthorized` if user not authenticated
+ `404 Not Found` if group ID not found


## New group

Creates a new project group. Available only for admin.

```
POST /groups
```

Parameters:

+ `name` (required) - The name of the group
+ `path` (required) - The path of the group

Return valueS:

+ `201 Created` on success and the newly created group
+ `400 Bad Request` if one of the required attributes not given
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if something fails

