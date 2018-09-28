# Features flags API

All methods require administrator authorization.

Notice that currently the API only supports boolean and percentage-of-time gate
values.

## List all features

Get a list of all persisted features, with its gate values.

```
GET /features
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/features
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

```
POST /features/:name
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | yes | Name of the feature to create or update |
| `value` | integer/string | yes | `true` or `false` to enable/disable, or an integer for percentage of time |
| `feature_group` | string | no | A Feature group name |
| `user` | string | no | A GitLab username |

Note that you can enable or disable a feature for both a `feature_group` and a
`user` with a single API call.

```bash
curl --data "value=30" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/features/new_library
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

## Delete a feature

Removes a feature gate. Response is equal when the gate exists, or doesn't.

```
DELETE /features/:name
```
