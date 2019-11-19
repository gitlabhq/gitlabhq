# Feature Flag Specs API **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/9566) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.5.

The API for creating, updating, reading and deleting [Feature Flag Specs](../user/project/operations/feature_flags.md#define-environment-specs).
Automation engineers benefit from this API by being able to modify Feature Flag Specs without accessing user interface.
To manage the [Feature Flag](../user/project/operations/feature_flags.md) resources via public API, please refer to the [Feature Flags API](feature_flags.md) document.

Users with Developer or higher [permissions](../user/permissions.md) can access Feature Flag Specs API.

## List all effective feature flag specs under the specified environment

Get all effective feature flag specs under the specified [environment](../ci/environments.md).

For instance, there are two specs, `staging` and `production`, for a feature flag.
When you pass `production` as a parameter to this endpoint, the system returns
the `production` feature flag spec only.

```
GET /projects/:id/feature_flag_scopes
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `environment`       | string           | yes        | The [environment](../ci/environments.md) name |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/feature_flag_scopes?environment=production
```

Example response:

```json
[
  {
    "id": 88,
    "active": true,
    "environment_scope": "production",
    "strategies": [
      {
        "name": "userWithId",
        "parameters": {
          "userIds": "1,2,3"
        }
      }
    ],
    "created_at": "2019-11-04T08:36:41.327Z",
    "updated_at": "2019-11-04T08:36:41.327Z",
    "name": "awesome_feature"
  },
  {
    "id": 82,
    "active": true,
    "environment_scope": "*",
    "strategies": [
      {
        "name": "default",
        "parameters": {}
      }
    ],
    "created_at": "2019-11-04T08:13:51.425Z",
    "updated_at": "2019-11-04T08:39:45.751Z",
    "name": "merge_train"
  },
  {
    "id": 81,
    "active": false,
    "environment_scope": "production",
    "strategies": [
      {
        "name": "default",
        "parameters": {}
      }
    ],
    "created_at": "2019-11-04T08:13:10.527Z",
    "updated_at": "2019-11-04T08:13:10.527Z",
    "name": "new_live_trace"
  }
]
```

## List all specs of a feature flag

Get all specs of a feature flag.

```
GET /projects/:id/feature_flags/:name/scopes
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag. |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/feature_flags/new_live_trace/scopes
```

Example response:

```json
[
  {
    "id": 79,
    "active": false,
    "environment_scope": "*",
    "strategies": [
      {
        "name": "default",
        "parameters": {}
      }
    ],
    "created_at": "2019-11-04T08:13:10.516Z",
    "updated_at": "2019-11-04T08:13:10.516Z"
  },
  {
    "id": 80,
    "active": true,
    "environment_scope": "staging",
    "strategies": [
      {
        "name": "default",
        "parameters": {}
      }
    ],
    "created_at": "2019-11-04T08:13:10.525Z",
    "updated_at": "2019-11-04T08:13:10.525Z"
  },
  {
    "id": 81,
    "active": false,
    "environment_scope": "production",
    "strategies": [
      {
        "name": "default",
        "parameters": {}
      }
    ],
    "created_at": "2019-11-04T08:13:10.527Z",
    "updated_at": "2019-11-04T08:13:10.527Z"
  }
]
```

## New feature flag spec

Creates a new feature flag spec.

```
POST /projects/:id/feature_flags/:name/scopes
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag. |
| `environment_scope` | string           | yes        | The [environment spec](../ci/environments.md#scoping-environments-with-specs) of the feature flag. |
| `active`            | boolean          | yes        | Whether the spec is active. |
| `strategies`        | json             | yes        | The [strategies](../user/project/operations/feature_flags.md#feature-flag-strategies) of the feature flag spec. |

```bash
curl https://gitlab.example.com/api/v4/projects/1/feature_flags/new_live_trace/scopes \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
    "environment_scope": "*",
    "active": false,
    "strategies": [{ "name": "default", "parameters": {} }]
}
EOF
```

Example response:

```json
{
  "id": 81,
  "active": false,
  "environment_scope": "*",
  "strategies": [
    {
      "name": "default",
      "parameters": {}
    }
  ],
  "created_at": "2019-11-04T08:13:10.527Z",
  "updated_at": "2019-11-04T08:13:10.527Z"
}
```

## Single feature flag spec

Gets a single feature flag spec.

```
GET /projects/:id/feature_flags/:name/scopes/:environment_scope
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag.  |
| `environment_scope` | string           | yes        | The URL-encoded [environment spec](../ci/environments.md#scoping-environments-with-specs) of the feature flag.  |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/feature_flags/new_live_trace/scopes/production
```

Example response:

```json
{
  "id": 81,
  "active": false,
  "environment_scope": "production",
  "strategies": [
    {
      "name": "default",
      "parameters": {}
    }
  ],
  "created_at": "2019-11-04T08:13:10.527Z",
  "updated_at": "2019-11-04T08:13:10.527Z"
}
```

## Edit feature flag spec

Updates an existing feature flag spec.

```
PUT /projects/:id/feature_flags/:name/scopes/:environment_scope
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag. |
| `environment_scope` | string           | yes        | The URL-encoded [environment spec](../ci/environments.md#scoping-environments-with-specs) of the feature flag.  |
| `active`            | boolean          | yes        | Whether the spec is active. |
| `strategies`        | json             | yes        | The [strategies](../user/project/operations/feature_flags.md#feature-flag-strategies) of the feature flag spec. |

```bash
curl https://gitlab.example.com/api/v4/projects/1/feature_flags/new_live_trace/scopes/production \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
    "active": true,
    "strategies": [{ "name": "userWithId", "parameters": { "userIds": "1,2,3" } }]
}
EOF
```

Example response:

```json
{
  "id": 81,
  "active": true,
  "environment_scope": "production",
  "strategies": [
    {
      "name": "userWithId",
      "parameters": { "userIds": "1,2,3" }
    }
  ],
  "created_at": "2019-11-04T08:13:10.527Z",
  "updated_at": "2019-11-04T08:13:10.527Z"
}
```

## Delete feature flag spec

Deletes a feature flag spec.

```
DELETE /projects/:id/feature_flags/:name/scopes/:environment_scope
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag.  |
| `environment_scope` | string           | yes        | The URL-encoded [environment spec](../ci/environments.md#scoping-environments-with-specs) of the feature flag.  |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" --request DELETE https://gitlab.example.com/api/v4/projects/1/feature_flags/new_live_trace/scopes/production
```
