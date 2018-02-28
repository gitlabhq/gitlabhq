# Project-level Variables  API

## List project variables

Get list of a project's variables.

```
GET /projects/:id/variables
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables"
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

Get the details of a project's specific variable.

```
GET /projects/:id/variables/:key
```

| Attribute | Type    | required | Description           |
|-----------|---------|----------|-----------------------|
| `id`      | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user   |
| `key`     | string  | yes      | The `key` of a variable |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables/TEST_VARIABLE_1"
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
POST /projects/:id/variables
```

| Attribute   | Type    | required | Description           |
|-------------|---------|----------|-----------------------|
| `id`        | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user   |
| `key`       | string  | yes      | The `key` of a variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed |
| `value`     | string  | yes      | The `value` of a variable |
| `protected` | boolean | no       | Whether the variable is protected |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables" --form "key=NEW_VARIABLE" --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value",
    "protected": false
}
```

## Update variable

Update a project's variable.

```
PUT /projects/:id/variables/:key
```

| Attribute   | Type    | required | Description             |
|-------------|---------|----------|-------------------------|
| `id`        | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user     |
| `key`       | string  | yes      | The `key` of a variable   |
| `value`     | string  | yes      | The `value` of a variable |
| `protected` | boolean | no       | Whether the variable is protected |

```
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables/NEW_VARIABLE" --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "protected": true
}
```

## Remove variable

Remove a project's variable.

```
DELETE /projects/:id/variables/:key
```

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user     |
| `key`     | string  | yes      | The `key` of a variable |

```
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1"
```
