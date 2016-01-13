# Build Variables

## List project variables

Get list of variables of a project.

```
GET /projects/:id/variables
```

### Parameters

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| id        | integer | yes      | The ID of a project |

### Example of request

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/variables"
```

### Example of response

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

Get details of specifica variable of a project.

```
GET /projects/:id/variables/:key
```

### Parameters

| Attribute | Type    | required | Description           |
|-----------|---------|----------|-----------------------|
| id        | integer | yes      | The ID of a project   |
| key       | string  | yes      | The `key` of variable |

### Example of request

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/variables/TEST_VARIABLE_1"
```

### Example of response

```json
{
    "key": "TEST_VARIABLE_1",
    "value": "TEST_1"
}
```

## Create variable

Create new variable in project.

```
POST /projects/:id/variables
```

### Parameters

| Attribute | Type    | required | Description           |
|-----------|---------|----------|-----------------------|
| id        | integer | yes      | The ID of a project   |
| key       | string  | yes      | The `key` of variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed |
| value     | string  | yes      | The `value` of variable |

### Example of request

```
curl -X POST -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/variables" -F "key=NEW_VARIABLE" -F "value=new value"
```

### Example of response

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value"
}
```

## Update variable

Update variable.

```
PUT /projects/:id/variables/:key
```

### Parameters

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| id        | integer | yes      | The ID of a project     |
| key       | string  | yes      | The `key` of variable   |
| value     | string  | yes      | The `value` of variable |

### Example of request

```
curl -X PUT -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/variables/NEW_VARIABLE" -F "value=updated value"
```

### Example of response

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value"
}
```

## Remove variable

Remove variable.

```
DELETE /projects/:id/variables/:key
```

### Parameters

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| id        | integer | yes      | The ID of a project     |
| key       | string  | yes      | The `key` of variable   |

### Example of request

```
curl -X DELETE -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/variables/VARIABLE_1"
```

