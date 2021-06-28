---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, api
---

# Project-level Variables API

## List project variables

Get list of a project's variables.

```plaintext
GET /projects/:id/variables
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID of a project or [URL-encoded NAMESPACE/PROJECT_NAME of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "variable_type": "env_var",
        "value": "TEST_1"
    },
    {
        "key": "TEST_VARIABLE_2",
        "variable_type": "env_var",
        "value": "TEST_2"
    }
]
```

## Show variable details

Get the details of a project's specific variable.

```plaintext
GET /projects/:id/variables/:key
```

| Attribute | Type    | required | Description           |
|-----------|---------|----------|-----------------------|
| `id`      | integer/string | yes      | The ID of a project or [URL-encoded NAMESPACE/PROJECT_NAME of the project](index.md#namespaced-path-encoding) owned by the authenticated user   |
| `key`     | string  | yes      | The `key` of a variable |
| `filter`  | hash    | no       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": true
}
```

## Create variable

Create a new variable.

```plaintext
POST /projects/:id/variables
```

| Attribute           | Type    | required | Description           |
|---------------------|---------|----------|-----------------------|
| `id`                | integer/string | yes      | The ID of a project or [URL-encoded NAMESPACE/PROJECT_NAME of the project](index.md#namespaced-path-encoding) owned by the authenticated user   |
| `key`               | string  | yes      | The `key` of a variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed |
| `value`             | string  | yes      | The `value` of a variable |
| `variable_type`     | string  | no       | The type of a variable. Available types are: `env_var` (default) and `file` |
| `protected`         | boolean | no       | Whether the variable is protected. Default: `false` |
| `masked`            | boolean | no       | Whether the variable is masked. Default: `false` |
| `environment_scope` | string  | no       | The `environment_scope` of the variable. Default: `*` |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/variables" --form "key=NEW_VARIABLE" --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value",
    "protected": false,
    "variable_type": "env_var",
    "masked": false,
    "environment_scope": "*"
}
```

## Update variable

Update a project's variable.

```plaintext
PUT /projects/:id/variables/:key
```

| Attribute           | Type    | required | Description             |
|---------------------|---------|----------|-------------------------|
| `id`                | integer/string | yes      | The ID of a project or [URL-encoded NAMESPACE/PROJECT_NAME of the project](index.md#namespaced-path-encoding) owned by the authenticated user     |
| `key`               | string  | yes      | The `key` of a variable   |
| `value`             | string  | yes      | The `value` of a variable |
| `variable_type`     | string  | no       | The type of a variable. Available types are: `env_var` (default) and `file` |
| `protected`         | boolean | no       | Whether the variable is protected |
| `masked`            | boolean | no       | Whether the variable is masked |
| `environment_scope` | string  | no       | The `environment_scope` of the variable |
| `filter`            | hash    | no       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/variables/NEW_VARIABLE" --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": false,
    "environment_scope": "*"
}
```

## Remove variable

Remove a project's variable.

```plaintext
DELETE /projects/:id/variables/:key
```

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer/string | yes      | The ID of a project or [URL-encoded NAMESPACE/PROJECT_NAME of the project](index.md#namespaced-path-encoding) owned by the authenticated user     |
| `key`     | string  | yes      | The `key` of a variable |
| `filter`  | hash    | no       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1"
```

## The `filter` parameter

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34490) in GitLab 13.2.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/227052) in GitLab 13.4.

This parameter is used for filtering by attributes, such as `environment_scope`.

Example usage:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1?filter[environment_scope]=production"
```
