---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Resource group API **(FREE)**

You can read more about [controlling the job concurrency with resource groups](../ci/resource_groups/index.md).

## Get all resource groups for a project

```plaintext
GET /projects/:id/resource_groups
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string     | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/resource_groups"
```

Example of response

```json
[
  {
    "id": 3,
    "key": "production",
    "process_mode": "unordered",
    "created_at": "2021-09-01T08:04:59.650Z",
    "updated_at": "2021-09-01T08:04:59.650Z"
  }
]
```

## Get a specific resource group

```plaintext
GET /projects/:id/resource_groups/:key
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string     | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `key`     | string  | yes      | The key of the resource group |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

Example of response

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "unordered",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:04:59.650Z"
}
```

## Edit an existing resource group

Updates an existing resource group's properties.

It returns `200` if the resource group was successfully updated. In case of an error, a status code `400` is returned.

```plaintext
PUT /projects/:id/resource_groups/:key
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`            | integer/string | yes                        | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user            |
| `key`           | string  | yes                               | The key of the resource group |
| `process_mode`  | string  | no                                | The process mode of the resource group. One of `unordered`, `oldest_first` or `newest_first`. Read [process modes](../ci/resource_groups/index.md#process-modes) for more information. |

```shell
curl --request PUT --data "process_mode=oldest_first" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

Example response:

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "oldest_first",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:13:38.679Z"
}
```
