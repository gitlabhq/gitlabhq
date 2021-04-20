---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Legacy Feature Flags API **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9566) in GitLab Premium 12.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212318) to GitLab Free in 13.5.

WARNING:
This API is deprecated and [scheduled for removal in GitLab 14.0](https://gitlab.com/gitlab-org/gitlab/-/issues/213369). Use [this API](feature_flags.md) instead.

API for accessing resources of [GitLab Feature Flags](../operations/feature_flags.md).

Users with Developer or higher [permissions](../user/permissions.md) can access Feature Flag API.

## Feature Flags pagination

By default, `GET` requests return 20 results at a time because the API results
are [paginated](README.md#pagination).

## List feature flags for a project

Gets all feature flags of the requested project.

```plaintext
GET /projects/:id/feature_flags
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).                                            |
| `scope`             | string           | no         | The condition of feature flags, one of: `enabled`, `disabled`.                                                              |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/feature_flags"
```

Example response:

```json
[
   {
      "name":"merge_train",
      "description":"This feature is about merge train",
      "active": true,
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
      "active": true,
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

```plaintext
POST /projects/:id/feature_flags
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag.                                                          |
| `description`       | string           | no         | The description of the feature flag.                                                   |
| `active`            | boolean          | no         | The active state of the flag. Defaults to true. [Supported](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38350) in GitLab 13.3 and later. |
| `scopes`            | JSON             | no         | The feature flag specs of the feature flag.                                            |
| `scopes:environment_scope` | string    | no         | The environment spec.                                                                  |
| `scopes:active`     | boolean          | no         | Whether the spec is active.                                                            |
| `scopes:strategies` | JSON             | no         | The [strategies](../operations/feature_flags.md#feature-flag-strategies) of the feature flag spec. |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags" \
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
   "active": true,
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

```plaintext
GET /projects/:id/feature_flags/:name
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag.  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/feature_flags/new_live_trace"
```

Example response:

```json
{
   "name":"new_live_trace",
   "description":"This is a new live trace feature",
   "active": true,
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

```plaintext
DELETE /projects/:id/feature_flags/:name
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag.  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request DELETE "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```
