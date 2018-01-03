# Group-level Variables  API

> [Introduced][ce-34519] in GitLab 9.5

## List group variables

Get list of a group's variables.

```
GET /groups/:id/variables
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID of a group or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/groups/1/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "value": "TEST_1"
    },
    {
        "key": "TEST_VARIABLE_2",
        "value": "TEST_2"
    }
]
```

## Show variable details

Get the details of a group's specific variable.

```
GET /groups/:id/variables/:key
```

| Attribute | Type    | required | Description           |
|-----------|---------|----------|-----------------------|
| `id`      | integer/string | yes      | The ID of a group or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user   |
| `key`     | string  | yes      | The `key` of a variable |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/groups/1/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "value": "TEST_1"
}
```

## Create variable

Create a new variable.

```
POST /groups/:id/variables
```

| Attribute   | Type    | required | Description           |
|-------------|---------|----------|-----------------------|
| `id`        | integer/string | yes      | The ID of a group or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user   |
| `key`       | string  | yes      | The `key` of a variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed |
| `value`     | string  | yes      | The `value` of a variable |
| `protected` | boolean | no       | Whether the variable is protected |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/groups/1/variables" --form "key=NEW_VARIABLE" --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value",
    "protected": false
}
```

## Update variable

Update a group's variable.

```
PUT /groups/:id/variables/:key
```

| Attribute   | Type    | required | Description             |
|-------------|---------|----------|-------------------------|
| `id`        | integer/string | yes      | The ID of a group or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user     |
| `key`       | string  | yes      | The `key` of a variable   |
| `value`     | string  | yes      | The `value` of a variable |
| `protected` | boolean | no       | Whether the variable is protected |

```
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/groups/1/variables/NEW_VARIABLE" --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "protected": true
}
```

## Remove variable

Remove a group's variable.

```
DELETE /groups/:id/variables/:key
```

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer/string | yes      | The ID of a group or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user     |
| `key`     | string  | yes      | The `key` of a variable |

```
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/groups/1/variables/VARIABLE_1"
```

[ce-34519]: https://gitlab.com/gitlab-org/gitlab-ce/issues/34519
