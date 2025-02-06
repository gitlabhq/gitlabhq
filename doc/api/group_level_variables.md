---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group-level Variables API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## List group variables

Get list of a group's variables.

```plaintext
GET /groups/:id/variables
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | The ID of a group or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "variable_type": "env_var",
        "value": "TEST_1",
        "protected": false,
        "masked": false,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    },
    {
        "key": "TEST_VARIABLE_2",
        "variable_type": "env_var",
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

## Show variable details

> - The `filter` parameter was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) in GitLab 16.9.

Get the details of a group's specific variable. If there are multiple variables with the same key,
use `filter` to select the correct `environment_scope`.

```plaintext
GET /groups/:id/variables/:key
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | The ID of a group or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `key`     | string         | Yes      | The `key` of a variable |
| `filter`  | hash           | No       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## Create variable

> - `masked_and_hidden` and `hidden` attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29674) in GitLab 17.4.

Create a new variable.

```plaintext
POST /groups/:id/variables
```

| Attribute                             | Type           | Required | Description |
|---------------------------------------|----------------|----------|-------------|
| `id`                                  | integer/string | Yes      | The ID of a group or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `key`                                 | string         | Yes      | The `key` of a variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed. |
| `value`                               | string         | Yes      | The `value` of a variable. |
| `description`                         | string         | No       | The `description` of the variable; must have no more than 255 characters. Default: `null`. |
| `environment_scope`                   | string         | No       | The [environment scope](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable) of a variable. Premium and Ultimate only. |
| `masked`                              | boolean        | No       | Whether the variable is masked. |
| `masked_and_hidden`                   | boolean        | No       | Whether the variable is masked and hidden. Default: `false` |
| `protected`                           | boolean        | No       | Whether the variable is protected. |
| `raw`                                 | boolean        | No       | Whether the variable is treated as a raw string. Default: `false`. When `true`, variables in the value are not [expanded](../ci/variables/_index.md#prevent-cicd-variable-expansion). |
| `variable_type`                       | string         | No       | The type of a variable. Available types are: `env_var` (default) and `file`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/1/variables" --form "key=NEW_VARIABLE" --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value",
    "variable_type": "env_var",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## Update variable

> - The `filter` parameter was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) in GitLab 16.9.

Update a group's variable. If there are multiple variables with the same key,
use `filter` to select the correct `environment_scope`.

```plaintext
PUT /groups/:id/variables/:key
```

| Attribute                             | Type           | Required | Description |
|---------------------------------------|----------------|----------|-------------|
| `id`                                  | integer/string | Yes      | The ID of a group or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `key`                                 | string         | Yes      | The `key` of a variable |
| `value`                               | string         | Yes      | The `value` of a variable |
| `description`                         | string         | No       | The description of the variable. Default: `null`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409641) in GitLab 16.2. |
| `environment_scope`                   | string         | No       | The [environment scope](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable) of a variable. Premium and Ultimate only. |
| `filter`                              | hash           | No       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |
| `masked`                              | boolean        | No       | Whether the variable is masked |
| `protected`                           | boolean        | No       | Whether the variable is protected |
| `raw`                                 | boolean        | No       | Whether the variable is treated as a raw string. Default: `false`. When `true`, variables in the value are not [expanded](../ci/variables/_index.md#prevent-cicd-variable-expansion). |
| `variable_type`                       | string         | No       | The type of a variable. Available types are: `env_var` (default) and `file` |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/1/variables/NEW_VARIABLE" --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": true,
    "hidden": false,
    "raw": true,
    "environment_scope": "*",
    "description": null
}
```

## Remove variable

> - The `filter` parameter was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) in GitLab 16.9.

Remove a group's variable. If there are multiple variables with the same key,
use `filter` to select the correct `environment_scope`.

```plaintext
DELETE /groups/:id/variables/:key
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | The ID of a group or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `key`     | string         | Yes      | The `key` of a variable |
| `filter`  | hash           | No       | Available filters: `[environment_scope]`. See the [`filter` parameter details](#the-filter-parameter). |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/1/variables/VARIABLE_1"
```

## The `filter` parameter

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) in GitLab 16.9.

When multiple variables have the same `key`, [GET](#show-variable-details), [PUT](#update-variable),
or [DELETE](#remove-variable) requests might return:

```plaintext
There are multiple variables with provided parameters. Please use 'filter[environment_scope]'.
```

Use `filter[environment_scope]` to select the variable with the matching `environment_scope` attribute.

For example:

- GET:

  ```shell
  curl --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1?filter[environment_scope]=production"
  ```

- PUT:

  ```shell
  curl --request PUT --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1?value=scoped-variable-updated-value&environment_scope=production&filter[environment_scope]=production"
  ```

- DELETE:

  ```shell
  curl --request DELETE --globoff --header "PRIVATE-TOKEN: <your_access_token>" \
       "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1?filter[environment_scope]=production"
  ```
