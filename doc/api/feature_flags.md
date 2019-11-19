# Feature Flags API **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/9566) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.5.

API for accessing resources of [GitLab Feature Flags](../user/project/operations/feature_flags.md).

Users with Developer or higher [permissions](../user/permissions.md) can access Feature Flag API.

## Feature Flags pagination

By default, `GET` requests return 20 results at a time because the API results
are [paginated](README.md#pagination).

## List feature flags for a project

Gets all feature flags of the requested project.

```
GET /projects/:id/feature_flags
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).                                            |
| `scope`             | string           | no         | The condition of feature flags, one of: `enabled`, `disabled`.                                                              |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/feature_flags
```

Example response:

```json
[
   {
      "name":"merge_train",
      "description":"This feature is about merge train",
      "created_at":"2019-11-04T08:13:51.423Z",
      "updated_at":"2019-11-04T08:13:51.423Z",
      "scopes":[
         {
            "id":82,
            "active":false,
            "environment_scope":"*",
            "strategies":[
               {
                  "name":"default",
                  "parameters":{

                  }
               }
            ],
            "created_at":"2019-11-04T08:13:51.425Z",
            "updated_at":"2019-11-04T08:13:51.425Z"
         },
         {
            "id":83,
            "active":true,
            "environment_scope":"review/*",
            "strategies":[
               {
                  "name":"default",
                  "parameters":{

                  }
               }
            ],
            "created_at":"2019-11-04T08:13:51.427Z",
            "updated_at":"2019-11-04T08:13:51.427Z"
         },
         {
            "id":84,
            "active":false,
            "environment_scope":"production",
            "strategies":[
               {
                  "name":"default",
                  "parameters":{

                  }
               }
            ],
            "created_at":"2019-11-04T08:13:51.428Z",
            "updated_at":"2019-11-04T08:13:51.428Z"
         }
      ]
   },
   {
      "name":"new_live_trace",
      "description":"This is a new live trace feature",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[
         {
            "id":79,
            "active":false,
            "environment_scope":"*",
            "strategies":[
               {
                  "name":"default",
                  "parameters":{

                  }
               }
            ],
            "created_at":"2019-11-04T08:13:10.516Z",
            "updated_at":"2019-11-04T08:13:10.516Z"
         },
         {
            "id":80,
            "active":true,
            "environment_scope":"staging",
            "strategies":[
               {
                  "name":"default",
                  "parameters":{

                  }
               }
            ],
            "created_at":"2019-11-04T08:13:10.525Z",
            "updated_at":"2019-11-04T08:13:10.525Z"
         },
         {
            "id":81,
            "active":false,
            "environment_scope":"production",
            "strategies":[
               {
                  "name":"default",
                  "parameters":{

                  }
               }
            ],
            "created_at":"2019-11-04T08:13:10.527Z",
            "updated_at":"2019-11-04T08:13:10.527Z"
         }
      ]
   }
]
```

## New feature flag

Creates a new feature flag.

```
POST /projects/:id/feature_flags
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag. |
| `description`       | string           | no         | The description of the feature flag. |
| `scopes`            | JSON             | no         | The [feature flag specs](../user/project/operations/feature_flags.md#define-environment-specs) of the feature flag. |
| `scopes:environment_scope` | string           | no         | The [environment spec](../ci/environments.md#scoping-environments-with-specs). |
| `scopes:active`            | boolean          | no         | Whether the spec is active. |
| `scopes:strategies`        | JSON             | no         | The [strategies](../user/project/operations/feature_flags.md#feature-flag-strategies) of the feature flag spec. |

```bash
curl https://gitlab.example.com/api/v4/projects/1/feature_flags \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
    "name": "awesome_feature",
    "scopes": [{ "environment_scope": "*", "active": false, "strategies": [{ "name": "default", "parameters": {} }] },
               { "environment_scope": "production", "active": true, "strategies": [{ "name": "userWithId", "parameters": { "userIds": "1,2,3" } }] }]
}
EOF
```

Example response:

```json
{
   "name":"awesome_feature",
   "description":null,
   "created_at":"2019-11-04T08:32:27.288Z",
   "updated_at":"2019-11-04T08:32:27.288Z",
   "scopes":[
      {
         "id":85,
         "active":false,
         "environment_scope":"*",
         "strategies":[
            {
               "name":"default",
               "parameters":{

               }
            }
         ],
         "created_at":"2019-11-04T08:32:29.324Z",
         "updated_at":"2019-11-04T08:32:29.324Z"
      },
      {
         "id":86,
         "active":true,
         "environment_scope":"production",
         "strategies":[
            {
               "name":"userWithId",
               "parameters":{
                  "userIds":"1,2,3"
               }
            }
         ],
         "created_at":"2019-11-04T08:32:29.328Z",
         "updated_at":"2019-11-04T08:32:29.328Z"
      }
   ]
}
```

## Single feature flag

Gets a single feature flag.

```
GET /projects/:id/feature_flags/:name
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag.  |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/feature_flags/new_live_trace
```

Example response:

```json
{
   "name":"new_live_trace",
   "description":"This is a new live trace feature",
   "created_at":"2019-11-04T08:13:10.507Z",
   "updated_at":"2019-11-04T08:13:10.507Z",
   "scopes":[
      {
         "id":79,
         "active":false,
         "environment_scope":"*",
         "strategies":[
            {
               "name":"default",
               "parameters":{

               }
            }
         ],
         "created_at":"2019-11-04T08:13:10.516Z",
         "updated_at":"2019-11-04T08:13:10.516Z"
      },
      {
         "id":80,
         "active":true,
         "environment_scope":"staging",
         "strategies":[
            {
               "name":"default",
               "parameters":{

               }
            }
         ],
         "created_at":"2019-11-04T08:13:10.525Z",
         "updated_at":"2019-11-04T08:13:10.525Z"
      },
      {
         "id":81,
         "active":false,
         "environment_scope":"production",
         "strategies":[
            {
               "name":"default",
               "parameters":{

               }
            }
         ],
         "created_at":"2019-11-04T08:13:10.527Z",
         "updated_at":"2019-11-04T08:13:10.527Z"
      }
   ]
}
```

## Delete feature flag

Deletes a feature flag.

```
DELETE /projects/:id/feature_flags/:name
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag.  |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" --request DELETE https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature
```
