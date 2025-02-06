---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project-level CI/CD variables API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## List project variables

Get list of a project's variables.

```plaintext
GET /projects/:id/variables
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables"
```

Example response:

```json
[
    {
        "variable_type": "env_var",
        "key": "TEST_VARIABLE_1",
        "value": "TEST_1",
        "protected": false,
        "masked": true,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    },
    {
        "variable_type": "env_var",
        "key": "TEST_VARIABLE_2",
        "value": "TEST_2",
        "protected": false,
        "masked": false,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    }
]
```

## Get a single variable

Get the details of a single variable. If there are multiple variables with the same key,
use `filter` to select the correct `environment_scope`.

```plaintext
GET /projects/:id/variables/:key
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`     | string         | Yes      | The `key` of a variable |
| `filter`  | hash           | No       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables/TEST_VARIABLE_1"
```

Example response:

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": true,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## Create a variable

> - `masked_and_hidden` and `hidden` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29674) in GitLab 17.4.

Create a new variable. If a variable with the same `key` already exists, the new variable
must have a different `environment_scope`. Otherwise, GitLab returns a message similar to:
`VARIABLE_NAME has already been taken`.

```plaintext
POST /projects/:id/variables
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`               | string         | Yes      | The `key` of a variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed |
| `value`             | string         | Yes      | The `value` of a variable |
| `description`       | string         | No       | The description of the variable. Default: `null`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409641) in GitLab 16.2. |
| `environment_scope` | string         | No       | The `environment_scope` of the variable. Default: `*` |
| `masked`            | boolean        | No       | Whether the variable is masked. Default: `false` |
| `masked_and_hidden` | boolean        | No       | Whether the variable is masked and hidden. Default: `false` |
| `protected`         | boolean        | No       | Whether the variable is protected. Default: `false` |
| `raw`               | boolean        | No       | Whether the variable is treated as a raw string. Default: `false`. When `true`, variables in the value are not [expanded](../ci/variables/_index.md#prevent-cicd-variable-expansion). |
| `variable_type`     | string         | No       | The type of a variable. Available types are: `env_var` (default) and `file` |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/variables" --form "key=NEW_VARIABLE" --form "value=new value"
```

Example response:

```json
{
    "variable_type": "env_var",
    "key": "NEW_VARIABLE",
    "value": "new value",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## Update a variable

Update a project's variable. If there are multiple variables with the same key,
use `filter` to select the correct `environment_scope`.

```plaintext
PUT /projects/:id/variables/:key
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`               | string         | Yes      | The `key` of a variable |
| `value`             | string         | Yes      | The `value` of a variable |
| `description`       | string         | No       | The description of the variable. Default: `null`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409641) in GitLab 16.2. |
| `environment_scope` | string         | No       | The `environment_scope` of the variable |
| `filter`            | hash           | No       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |
| `masked`            | boolean        | No       | Whether the variable is masked |
| `protected`         | boolean        | No       | Whether the variable is protected |
| `raw`               | boolean        | No       | Whether the variable is treated as a raw string. Default: `false`. When `true`, variables in the value are not [expanded](../ci/variables/_index.md#prevent-cicd-variable-expansion). |
| `variable_type`     | string         | No       | The type of a variable. Available types are: `env_var` (default) and `file` |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/variables/NEW_VARIABLE" --form "value=updated value"
```

Example response:

```json
{
    "variable_type": "env_var",
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "protected": true,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": "null"
}
```

## Delete a variable

Delete a project's variable. If there are multiple variables with the same key,
use `filter` to select the correct `environment_scope`.

```plaintext
DELETE /projects/:id/variables/:key
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`     | string         | Yes      | The `key` of a variable |
| `filter`  | hash           | No       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1"
```

## The `filter` parameter

When multiple variables have the same `key`, [GET](#get-a-single-variable), [PUT](#update-a-variable),
or [DELETE](#delete-a-variable) requests might return:

```plaintext
There are multiple variables with provided parameters. Please use 'filter[environment_scope]'.
```

Use `filter[environment_scope]` to select the variable with the matching `environment_scope` attribute.

For example:

- GET:

  ```shell
  curl --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1?filter[environment_scope]=production"
  ```

- PUT:

  ```shell
  curl --request PUT --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1?value=scoped-variable-updated-value&environment_scope=production&filter[environment_scope]=production"
  ```

- DELETE:

  ```shell
  curl --request DELETE --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1?filter[environment_scope]=production"
  ```
