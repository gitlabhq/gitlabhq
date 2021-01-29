---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Features flags API

This API is for managing Flipper-based [feature flags used in development of GitLab](../development/feature_flags/index.md).

All methods require administrator authorization.

Notice that currently the API only supports boolean and percentage-of-time gate
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
    "name": "api_kaminari_count_with_limit",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/23931",
    "rollout_issue_url": null,
    "milestone": "11.8",
    "type": "ops",
    "group": "group::ecosystem",
    "default_enabled": false
  },
  {
    "name": "marginalia",
    "introduced_by_url": null,
    "rollout_issue_url": null,
    "milestone": null,
    "type": "ops",
    "group": null,
    "default_enabled": false
  }
]
```

## Set or create a feature

Set a feature's gate value. If a feature with the given name doesn't exist yet,
it's created. The value can be a boolean, or an integer to indicate
percentage of time.

```plaintext
POST /features/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | yes | Name of the feature to create or update |
| `value` | integer/string | yes | `true` or `false` to enable/disable, or an integer for percentage of time |
| `key` | string | no | `percentage_of_actors` or `percentage_of_time` (default) |
| `feature_group` | string | no | A Feature group name |
| `user` | string | no | A GitLab username |
| `group` | string | no | A GitLab group's path, for example `gitlab-org` |
| `project` | string | no | A projects path, for example `gitlab-org/gitlab-foss` |
| `force` | boolean | no | Skip feature flag validation checks, such as a YAML definition |

Note that you can enable or disable a feature for a `feature_group`, a `user`,
a `group`, and a `project` in a single API call.

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
