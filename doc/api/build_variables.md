# Build Variables

## Variables keys

All variable keys must contains only letters, digits and '\_'. They must also be no longer than 255 characters.

## List project variables

Get list of variables of a project.

```
GET /projects/:id/variables
```

Parameters:

- `id` (required) - The ID of a project

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

Parameters:

- `id` (required) - The ID of a project
- `key` (required) - The `key` of variable

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

Parameters:

- `id` (required) - The ID of a project
- `key` (required) - The `key` for variable
- `value` (required) - The `value` for variable

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

Parameters:

- `id` (required) - The ID of a project
- `key` (required) - The `key` for variable
- `value` (required) - The `value` for variable

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

Parameters:

- `id` (required) - The ID of a project
- `key` (required) - The `key` for variable

