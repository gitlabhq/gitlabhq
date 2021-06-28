---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Feature flag user lists API **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/205409) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.10.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212318) to GitLab Free in 13.5.

API for accessing GitLab Feature Flag User Lists.

Users with Developer or higher [permissions](../user/permissions.md) can access the Feature Flag User Lists API.

NOTE:
`GET` requests return twenty results at a time because the API results
are [paginated](index.md#pagination). You can change this value.

## List all feature flag user lists for a project

Gets all feature flag user lists for the requested project.

```plaintext
GET /projects/:id/feature_flags_user_lists
```

| Attribute | Type           | Required | Description                                                                      |
| --------- | -------------- | -------- | -------------------------------------------------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `search`  | string         | no       | Return user lists matching the search criteria.                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists"
```

Example response:

```json
[
   {
      "name": "user_list",
      "user_xids": "user1,user2",
      "id": 1,
      "iid": 1,
      "project_id": 1,
      "created_at": "2020-02-04T08:13:51.423Z",
      "updated_at": "2020-02-04T08:13:51.423Z"
   },
   {
      "name": "test_users",
      "user_xids": "user3,user4,user5",
      "id": 2,
      "iid": 2,
      "project_id": 1,
      "created_at": "2020-02-04T08:13:10.507Z",
      "updated_at": "2020-02-04T08:13:10.507Z"
   }
]
```

## Create a feature flag user list

Creates a feature flag user list.

```plaintext
POST /projects/:id/feature_flags_user_lists
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).       |
| `name`              | string           | yes        | The name of the feature flag. |
| `user_xids`         | string           | yes        | A comma separated list of user IDs. |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
    "name": "my_user_list",
    "user_xids": "user1,user2,user3"
}
EOF
```

Example response:

```json
{
   "name": "my_user_list",
   "user_xids": "user1,user2,user3",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:32:27.288Z",
   "updated_at": "2020-02-04T08:32:27.288Z"
}
```

## Get a feature flag user list

Gets a feature flag user list.

```plaintext
GET /projects/:id/feature_flags_user_lists/:iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).       |
| `iid`               | integer/string   | yes        | The internal ID of the project's feature flag user list.                               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```

Example response:

```json
{
   "name": "my_user_list",
   "user_xids": "123,456",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:13:10.507Z",
   "updated_at": "2020-02-04T08:13:10.507Z"
}
```

## Update a feature flag user list

Updates a feature flag user list.

```plaintext
PUT /projects/:id/feature_flags_user_lists/:iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).       |
| `iid`               | integer/string   | yes        | The internal ID of the project's feature flag user list.                               |
| `name`              | string           | no         | The name of the feature flag.                                                          |
| `user_xids`         | string           | no         | A comma separated list of user IDs.                                                    |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --request PUT \
     --data @- << EOF
{
    "user_xids": "user2,user3,user4"
}
EOF
```

Example response:

```json
{
   "name": "my_user_list",
   "user_xids": "user2,user3,user4",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:32:27.288Z",
   "updated_at": "2020-02-05T09:33:17.179Z"
}
```

## Delete feature flag user list

Deletes a feature flag user list.

```plaintext
DELETE /projects/:id/feature_flags_user_lists/:iid
```

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).       |
| `iid`               | integer/string   | yes        | The internal ID of the project's feature flag user list                                |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request DELETE "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```
