---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Instance-level CI/CD variables API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14108) in GitLab 13.0
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/218249) in GitLab 13.2.

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
        "masked": false
    },
    {
        "key": "TEST_VARIABLE_2",
        "variable_type": "env_var",
        "value": "TEST_2",
        "protected": false,
        "masked": false
    }
]
```

## Show instance variable details

Get the details of a specific instance-level variable.

```plaintext
GET /admin/ci/variables/:key
```

| Attribute | Type    | required | Description           |
|-----------|---------|----------|-----------------------|
| `key`     | string  | yes      | The `key` of a variable |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/admin/ci/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false
}
```

## Create instance variable

Create a new instance-level variable.

[In GitLab 13.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/216097), the maximum number of allowed instance-level variables can be changed.

```plaintext
POST /admin/ci/variables
```

| Attribute       | Type    | required | Description           |
|-----------------|---------|----------|-----------------------|
| `key`           | string  | yes      | The `key` of a variable. Max 255 characters, only `A-Z`, `a-z`, `0-9`, and `_` are allowed. |
| `value`         | string  | yes      | The `value` of a variable. 10,000 characters allowed ([GitLab 13.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/220028)). |
| `variable_type` | string  | no       | The type of a variable. Available types are: `env_var` (default) and `file`. |
| `protected`     | boolean | no       | Whether the variable is protected. |
| `masked`        | boolean | no       | Whether the variable is masked. |

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
    "masked": false
}
```

## Update instance variable

Update an instance-level variable.

```plaintext
PUT /admin/ci/variables/:key
```

| Attribute       | Type    | required | Description             |
|-----------------|---------|----------|-------------------------|
| `key`           | string  | yes      | The `key` of a variable.   |
| `value`         | string  | yes      | The `value` of a variable. 10,000 characters allowed ([GitLab 13.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/220028)). |
| `variable_type` | string  | no       | The type of a variable. Available types are: `env_var` (default) and `file`. |
| `protected`     | boolean | no       | Whether the variable is protected. |
| `masked`        | boolean | no       | Whether the variable is masked. |

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
    "masked": true
}
```

## Remove instance variable

Remove an instance-level variable.

```plaintext
DELETE /admin/ci/variables/:key
```

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `key`     | string  | yes      | The `key` of a variable |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/admin/ci/variables/VARIABLE_1"
```
