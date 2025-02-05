---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Feature flags API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9566) in GitLab Premium 12.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212318) to GitLab Free in 13.5.

API for accessing resources of [GitLab feature flags](../operations/feature_flags.md).

Users with at least the Developer [role](../user/permissions.md) can access the feature flag API.

## Feature flags pagination

By default, `GET` requests return 20 results at a time because the API results
are [paginated](rest/_index.md#pagination).

## List feature flags for a project

Gets all feature flags of the requested project.

```plaintext
GET /projects/:id/feature_flags
```

| Attribute           | Type             | Required   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                                            |
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
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:51.423Z",
      "updated_at":"2019-11-04T08:13:51.423Z",
      "scopes":[],
      "strategies": [
        {
          "id": 1,
          "name": "userWithId",
          "parameters": {
            "userIds": "user1"
          },
          "scopes": [
            {
              "id": 1,
              "environment_scope": "production"
            }
          ],
          "user_list": null
        }
      ]
   },
   {
      "name":"new_live_trace",
      "description":"This is a new live trace feature",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[],
      "strategies": [
        {
          "id": 2,
          "name": "default",
          "parameters": {},
          "scopes": [
            {
              "id": 2,
              "environment_scope": "staging"
            }
          ],
          "user_list": null
        }
      ]
   },
   {
      "name":"user_list",
      "description":"This feature is about user list",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[],
      "strategies": [
        {
          "id": 2,
          "name": "gitlabUserList",
          "parameters": {},
          "scopes": [
            {
              "id": 2,
              "environment_scope": "staging"
            }
          ],
          "user_list": {
            "id": 1,
            "iid": 1,
            "name": "My user list",
            "user_xids": "user1,user2,user3"
          }
        }
      ]
   }
]
```

## Get a single feature flag

Gets a single feature flag.

```plaintext
GET /projects/:id/feature_flags/:feature_flag_name
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).       |
| `feature_flag_name` | string           | yes        | The name of the feature flag.                                                          |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```

Example response:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T19:56:33.119Z",
  "updated_at": "2020-05-13T19:56:33.119Z",
  "scopes": [],
  "strategies": [
    {
      "id": 36,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 37,
          "environment_scope": "production"
        }
      ],
      "user_list": null
    }
  ]
}
```

## Create a feature flag

Creates a new feature flag.

```plaintext
POST /projects/:id/feature_flags
```

| Attribute           | Type             | Required   | Description                                                                                                                                                                                                                                                                              |
| ------------------- | ---------------- | ---------- |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).                                                                                                                                                                                                     |
| `name`              | string           | yes        | The name of the feature flag.                                                                                                                                                                                                                                                            |
| `version`           | string           | yes        | **Deprecated** The version of the feature flag. Must be `new_version_flag`. Omit to create a Legacy feature flag.                                                                                                                                                                        |
| `description`       | string           | no         | The description of the feature flag.                                                                                                                                                                                                                                                     |
| `active`            | boolean          | no         | The active state of the flag. Defaults to true.                                                                                                                                                                                                                                          |
| `strategies`        | array of strategy JSON objects | no         | The feature flag [strategies](../operations/feature_flags.md#feature-flag-strategies).                                                                                                                                                                                     |
| `strategies:name`   | JSON             | no         | The strategy name. Can be `default`, `gradualRolloutUserId`, `userWithId`, or `gitlabUserList`. In [GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/36380) and later, can be [`flexibleRollout`](https://docs.getunleash.io/user_guide/activation_strategy/#gradual-rollout). |
| `strategies:parameters` | JSON         | no         | The strategy parameters.                                                                                                                                                                                                                                                                 |
| `strategies:scopes` | JSON             | no         | The scopes for the strategy.                                                                                                                                                                                                                                                             |
| `strategies:scopes:environment_scope` | string | no | The environment scope of the scope.                                                                                                                                                                                                                                                      |
| `strategies:user_list_id` | integer/string | no     | The ID of the feature flag user list. If strategy is `gitlabUserList`.                                                                                                                                                                                                                   |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
  "name": "awesome_feature",
  "version": "new_version_flag",
  "strategies": [{ "name": "default", "parameters": {}, "scopes": [{ "environment_scope": "production" }] }]
}
EOF
```

Example response:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T19:56:33.119Z",
  "updated_at": "2020-05-13T19:56:33.119Z",
  "scopes": [],
  "strategies": [
    {
      "id": 36,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 37,
          "environment_scope": "production"
        }
      ]
    }
  ]
}
```

## Update a feature flag

Updates a feature flag.

```plaintext
PUT /projects/:id/feature_flags/:feature_flag_name
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).   |
| `feature_flag_name` | string           | yes        | The current name of the feature flag.                                                  |
| `description`       | string           | no         | The description of the feature flag.                                                   |
| `active`            | boolean          | no         | The active state of the flag.                                                          |
| `name`              | string           | no         | The new name of the feature flag.                                                      |
| `strategies`        | array of strategy JSON objects | no         | The feature flag [strategies](../operations/feature_flags.md#feature-flag-strategies). |
| `strategies:id`     | JSON             | no         | The feature flag strategy ID.                                                          |
| `strategies:name`   | JSON             | no         | The strategy name.                                                                     |
| `strategies:_destroy` | boolean         | no         | Delete the strategy when true.                                                        |
| `strategies:parameters` | JSON         | no         | The strategy parameters.                                                               |
| `strategies:scopes` | JSON             | no         | The scopes for the strategy.                                                           |
| `strategies:scopes:id` | JSON          | no         | The environment scope ID.                                                              |
| `strategies:scopes:environment_scope` | string | no | The environment scope of the scope.                                                    |
| `strategies:scopes:_destroy` | boolean | no | Delete the scope when true.                                                                    |
| `strategies:user_list_id` | integer/string | no     | The ID of the feature flag user list. If strategy is `gitlabUserList`.                 |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
  "strategies": [{ "name": "gradualRolloutUserId", "parameters": { "groupId": "default", "percentage": "25" }, "scopes": [{ "environment_scope": "staging" }] }]
}
EOF
```

Example response:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T20:10:32.891Z",
  "updated_at": "2020-05-13T20:10:32.891Z",
  "scopes": [],
  "strategies": [
    {
      "id": 38,
      "name": "gradualRolloutUserId",
      "parameters": {
        "groupId": "default",
        "percentage": "25"
      },
      "scopes": [
        {
          "id": 40,
          "environment_scope": "staging"
        }
      ]
    },
    {
      "id": 37,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 39,
          "environment_scope": "production"
        }
      ]
    }
  ]
}
```

## Delete a feature flag

Deletes a feature flag.

```plaintext
DELETE /projects/:id/feature_flags/:feature_flag_name
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).       |
| `feature_flag_name` | string           | yes        | The name of the feature flag.                                                          |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request DELETE "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```
