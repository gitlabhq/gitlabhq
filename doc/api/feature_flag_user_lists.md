---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Feature flag user lists API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/205409) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.10.
- [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212318) to GitLab Free in 13.5.

{{< /history >}}

Use this API to interact with GitLab feature flags for [user lists](../operations/feature_flags.md#user-list).

Prerequisites:

- You must have at least the Developer role.

{{< alert type="note" >}}

To interact with feature flags for all users, see the [Feature flag API](feature_flags.md).

{{< /alert >}}

## List all feature flag user lists for a project

Gets all feature flag user lists for the requested project.

```plaintext
GET /projects/:id/feature_flags_user_lists
```

Use the `page` and `per_page` [pagination](rest/_index.md#offset-based-pagination) parameters to
control the pagination of results.

| Attribute | Type           | Required | Description                                                                      |
| --------- | -------------- | -------- | -------------------------------------------------------------------------------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`  | string         | no       | Return user lists matching the search criteria.                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists"
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
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).       |
| `name`              | string           | yes        | The name of the list. |
| `user_xids`         | string           | yes        | A comma-separated list of external user IDs. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists" \
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

Use the `page` and `per_page` [pagination](rest/_index.md#offset-based-pagination) parameters to
control the pagination of results.

| Attribute           | Type             | Required   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).       |
| `iid`               | integer or string   | yes        | The internal ID of the project's feature flag user list.                               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
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
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).       |
| `iid`               | integer or string   | yes        | The internal ID of the project's feature flag user list.                               |
| `name`              | string           | no         | The name of the list.                                                          |
| `user_xids`         | string           | no         | A comma-separated list of external user IDs.                                                    |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1" \
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
| `id`                | integer or string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).       |
| `iid`               | integer or string   | yes        | The internal ID of the project's feature flag user list                                |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```
