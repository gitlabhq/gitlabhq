---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Instance-level CI/CD variables API **(FREE SELF)**

## List all instance variables

Get the list of all instance-level variables.

```plaintext
GET /admin/ci/variables
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/admin/ci/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "variable_type": "env_var",
        "value": "TEST_1",
        "protected": false,
        "masked": false,
        "raw": false
    },
    {
        "key": "TEST_VARIABLE_2",
        "variable_type": "env_var",
        "value": "TEST_2",
        "protected": false,
        "masked": false,
        "raw": false
    }
]
```

## Show instance variable details

Get the details of a specific instance-level variable.

```plaintext
GET /admin/ci/variables/:key
```

| Attribute | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `key`     | string  | Yes      | The `key` of a variable |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/admin/ci/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false,
    "raw": false
}
```

## Create instance variable

Create a new instance-level variable.

The [maximum number of instance-level variables](../administration/instance_limits.md#number-of-instance-level-variables) can be changed.

```plaintext
POST /admin/ci/variables
```

| Attribute       | Type    | Required | Description |
|-----------------|---------|----------|-------------|
| `key`           | string  | Yes      | The `key` of a variable. Maximum of 255 characters, only `A-Z`, `a-z`, `0-9`, and `_` are allowed. |
| `value`         | string  | Yes      | The `value` of a variable. Maximum of 10,000 characters. |
| `variable_type` | string  | No       | The type of a variable. Available types are: `env_var` (default) and `file`. |
| `protected`     | boolean | No       | Whether the variable is protected. |
| `masked`        | boolean | No       | Whether the variable is masked. |
| `raw`           | boolean | No       | Whether the variable is expandable. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/admin/ci/variables" --form "key=NEW_VARIABLE" --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value",
    "variable_type": "env_var",
    "protected": false,
    "masked": false,
    "raw": false
}
```

## Update instance variable

Update an instance-level variable.

```plaintext
PUT /admin/ci/variables/:key
```

| Attribute       | Type    | Required | Description |
|-----------------|---------|----------|-------------|
| `key`           | string  | Yes      | The `key` of a variable. Maximum of 255 characters, only `A-Z`, `a-z`, `0-9`, and `_` are allowed. |
| `value`         | string  | Yes      | The `value` of a variable. Maximum of 10,000 characters. |
| `variable_type` | string  | No       | The type of a variable. Available types are: `env_var` (default) and `file`. |
| `protected`     | boolean | No       | Whether the variable is protected. |
| `masked`        | boolean | No       | Whether the variable is masked. |
| `raw`           | boolean | No       | Whether the variable is expandable. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/admin/ci/variables/NEW_VARIABLE" --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": true,
    "raw": true
}
```

## Remove instance variable

Remove an instance-level variable.

```plaintext
DELETE /admin/ci/variables/:key
```

| Attribute | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `key`     | string | Yes      | The `key` of a variable |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/admin/ci/variables/VARIABLE_1"
```
