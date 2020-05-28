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
    ]
  },
  {
    "name": "my_user_feature",
    "state": "on",
    "gates": [
      {
        "key": "percentage_of_actors",
        "value": 34
      }
    ]
  },
  {
    "name": "new_library",
    "state": "on",
    "gates": [
      {
        "key": "boolean",
        "value": true
      }
    ]
  }
]
```

## Set or create a feature

Set a feature's gate value. If a feature with the given name doesn't exist yet
it will be created. The value can be a boolean, or an integer to indicate
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
  ]
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
  ]
}
```

Rolls out the `my_user_feature` to `42%` of actors.

## Delete a feature

Removes a feature gate. Response is equal when the gate exists, or doesn't.

```plaintext
DELETE /features/:name
```
