---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Feature flags API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This API is for managing Flipper-based [feature flags used in development of GitLab](../development/feature_flags/_index.md).

All methods require administrator authorization.

Notice that the API only supports boolean and percentage-of-time gate
values.

## List all features

Get a list of all persisted features, with its gate values.

```plaintext
GET /features
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/features"
```

Example response:

```json
[
  {
    "name": "experimental_feature",
    "state": "off",
    "gates": [
      {
        "key": "boolean",
        "value": false
      }
    ],
    "definition": null
  },
  {
    "name": "my_user_feature",
    "state": "on",
    "gates": [
      {
        "key": "percentage_of_actors",
        "value": 34
      }
    ],
    "definition": {
      "name": "my_user_feature",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
      "group": "group::ci",
      "type": "development",
      "default_enabled": false
    }
  },
  {
    "name": "new_library",
    "state": "on",
    "gates": [
      {
        "key": "boolean",
        "value": true
      }
    ],
    "definition": null
  }
]
```

## List all feature definitions

Get a list of all feature definitions.

```plaintext
GET /features/definitions
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/features/definitions"
```

Example response:

```json
[
  {
    "name": "geo_pages_deployment_replication",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68662",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/337676",
    "milestone": "14.3",
    "log_state_changes": null,
    "type": "development",
    "group": "group::geo",
    "default_enabled": true
  }
]
```

## Set or create a feature

Set a feature's gate value. If a feature with the given name doesn't exist yet,
it's created. The value can be a boolean, or an integer to indicate
percentage of time.

WARNING:
Before you enable a feature still in development, you should understand the [security and stability risks](../administration/feature_flags.md#risks-when-enabling-features-still-in-development).

```plaintext
POST /features/:name
```

| Attribute       | Type           | Required | Description                                                                                                                                                                                      |
|-----------------|----------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`          | string         | yes      | Name of the feature to create or update                                                                                                                                                          |
| `value`         | integer/string | yes      | `true` or `false` to enable/disable, or an integer for percentage of time                                                                                                                        |
| `key`           | string         | no       | `percentage_of_actors` or `percentage_of_time` (default)                                                                                                                                         |
| `feature_group` | string         | no       | A [Feature group](../development/feature_flags/_index.md#feature-groups) name                                                                                                                                                                             |
| `user`          | string         | no       | A GitLab username or comma-separated multiple usernames                                                                                                                                          |
| `group`         | string         | no       | A GitLab group's path, for example `gitlab-org`, or comma-separated multiple group paths                                                                                                         |
| `namespace`     | string         | no       | A GitLab group or user namespace's path, for example `john-doe`, or comma-separated multiple namespace paths. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353117) in GitLab 15.0. |
| `project`       | string         | no       | A projects path, for example `gitlab-org/gitlab-foss`, or comma-separated multiple project paths                                                                                                 |
| `repository`    | string         | no       | A repository path, for example `gitlab-org/gitlab-test.git`, `gitlab-org/gitlab-test.wiki.git`, , `snippets/21.git`, to name a few. Use comma to separate multiple repository paths              |
| `force`         | boolean        | no       | Skip feature flag validation checks, such as a YAML definition                                                                                                                                   |

You can enable or disable a feature for a `feature_group`, a `user`,
a `group`, a `namespace`, a `project`, and a `repository` in a single API call.

```shell
curl --data "value=30" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/features/new_library"
```

Example response:

```json
{
  "name": "new_library",
  "state": "conditional",
  "gates": [
    {
      "key": "boolean",
      "value": false
    },
    {
      "key": "percentage_of_time",
      "value": 30
    }
  ],
  "definition": {
    "name": "my_user_feature",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
    "group": "group::ci",
    "type": "development",
    "default_enabled": false
  }
}
```

### Set percentage of actors rollout

Rollout to percentage of actors.

```plaintext
POST https://gitlab.example.com/api/v4/features/my_user_feature?private_token=<your_access_token>
Content-Type: application/x-www-form-urlencoded
value=42&key=percentage_of_actors&
```

Example response:

```json
{
  "name": "my_user_feature",
  "state": "conditional",
  "gates": [
    {
      "key": "boolean",
      "value": false
    },
    {
      "key": "percentage_of_actors",
      "value": 42
    }
  ],
  "definition": {
    "name": "my_user_feature",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
    "group": "group::ci",
    "type": "development",
    "default_enabled": false
  }
}
```

Rolls out the `my_user_feature` to `42%` of actors.

## Delete a feature

Removes a feature gate. Response is equal when the gate exists, or doesn't.

```plaintext
DELETE /features/:name
```
