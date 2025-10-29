---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Container virtual registry API
description: Create and manage virtual registries for the container registry, and configure upstream container registries.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/548794) in GitLab 18.5 [with a flag](../administration/feature_flags/_index.md) named `container_virtual_registries`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of these endpoints is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Use this API to:

- Create and manage virtual registries for the container registry.
- Configure upstream container registries.
- Manage cached container images and manifests.

## Manage virtual registries

Use the following endpoints to create and manage virtual registries for the container registry.

### List all virtual registries

Lists all container virtual registries for a group.

```plaintext
GET /groups/:id/-/virtual_registries/container/registries
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | string or integer | Yes | The group ID or full-group path. Must be a top-level group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/registries"
```

Example response:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "name": "my-container-virtual-registry",
    "description": "My container virtual registry",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### Create a virtual registry

Creates a container virtual registry for a group.

```plaintext
POST /groups/:id/-/virtual_registries/container/registries
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string or integer | Yes | The group ID or full-group path. Must be a top-level group. |
| `name` | string | Yes | The name of the virtual registry. |
| `description` | string | No | The description of the virtual registry. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"name": "my-container-virtual-registry", "description": "My container virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/registries"
```

Example response:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-container-virtual-registry",
  "description": "My container virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Get a virtual registry

Gets a specific container virtual registry.

```plaintext
GET /virtual_registries/container/registries/:id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the container virtual registry. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

Example response:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-container-virtual-registry",
  "description": "My container virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstreams": [
    {
      "id": 2,
      "position": 1,
      "upstream_id": 2
    }
  ]
}
```

### Update a virtual registry

Updates a specific container virtual registry.

```plaintext
PATCH /virtual_registries/container/registries/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the container virtual registry. |
| `description` | string | No | The description of the virtual registry. |
| `name` | string | No | The name of the virtual registry. |

{{< alert type="note" >}}

You must provide at least one of the optional parameters (`name` or `description`) in your request.

{{< /alert >}}

Example request:

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"name": "my-container-virtual-registry", "description": "My container virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

If successful, returns a [`200 OK`](rest/troubleshooting.md#status-codes) status code.

### Delete a virtual registry

{{< alert type="warning" >}}

When you delete a virtual registry, you also delete all associated upstream registries that are not shared with other virtual registries, along with their cached container images and manifests.

{{< /alert >}}

Deletes a specific container virtual registry.

```plaintext
DELETE /virtual_registries/container/registries/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the container virtual registry. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

## Manage upstream registries

Use the following endpoints to configure and manage upstream container registries.

### List all upstream registries for a top-level group

Lists all upstream container registries for a top-level group.

```plaintext
GET /groups/:id/-/virtual_registries/container/upstreams
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | string or integer | Yes | The group ID or full-group path. Must be a top-level group. |
| `page` | integer | No | The page number. Defaults to 1. |
| `per_page` | integer | No | The number of items per page. Defaults to 20. |
| `upstream_name` | string | No | The name of the upstream registry for fuzzy search filtering by name. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/upstreams"
```

Example response:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://registry-1.docker.io",
    "name": "Docker Hub",
    "description": "Docker Hub registry",
    "cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### List all upstream registries for a virtual registry

Lists all upstream registries for a container virtual registry.

```plaintext
GET /virtual_registries/container/registries/:id/upstreams
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | integer | Yes | The ID of the container virtual registry. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/upstreams"
```

Example response:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://registry-1.docker.io",
    "name": "Docker Hub",
    "description": "Docker Hub registry",
    "cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "registry_upstream": {
      "id": 1,
      "registry_id": 1,
      "position": 1
    }
  }
]
```

### Create an upstream registry

Adds an upstream container registry to a container virtual registry.

```plaintext
POST /virtual_registries/container/registries/:id/upstreams
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the container virtual registry. |
| `url` | string | Yes | The URL of the upstream container registry. |
| `name` | string | Yes | The name of the upstream registry. |
| `cache_validity_hours` | integer | No | The cache validity period for container images. Defaults to 24 hours. |
| `description` | string | No | The description of the upstream registry. |
| `password` | string | No | The password of the upstream registry. |
| `username` | string | No | The username of the upstream registry. |

{{< alert type="note" >}}

You must include both the `username` and `password` in the request, or not at all. If not set, a public (anonymous) request is used to access the upstream.

You cannot add two upstreams with the same URL and credentials (`username` and `password`) to the same top-level group. Instead, you can either:

- Set different credentials for each upstream with the same URL.
- Associate an upstream with multiple virtual registries.

{{< /alert >}}

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io", "name": "Docker Hub", "description": "Docker Hub registry", "username": "<your_username>", "password": "<your_password>", "cache_validity_hours": 48}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/upstreams"
```

Example response:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://registry-1.docker.io",
  "name": "Docker Hub",
  "description": "Docker Hub registry",
  "cache_validity_hours": 48,
  "username": "user",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstream": {
    "id": 1,
    "registry_id": 1,
    "position": 1
  }
}
```

### Get an upstream registry

Gets a specific upstream container registry for a container virtual registry.

```plaintext
GET /virtual_registries/container/upstreams/:id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the upstream registry. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

Example response:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://registry-1.docker.io",
  "name": "Docker Hub",
  "description": "Docker Hub registry",
  "cache_validity_hours": 24,
  "username": "user",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstreams": [
    {
      "id": 1,
      "registry_id": 1,
      "position": 1
    }
  ]
}
```

### Update an upstream registry

Updates a specific upstream container registry for a container virtual registry.

```plaintext
PATCH /virtual_registries/container/upstreams/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the upstream registry. |
| `cache_validity_hours` | integer | No | The cache validity period for container images. Defaults to 24 hours. |
| `description` | string | No | The description of the upstream registry. |
| `name` | string | No | The name of the upstream registry. |
| `password` | string | No | The password of the upstream registry. |
| `url` | string | No | The URL of the upstream registry. |
| `username` | string | No | The username of the upstream registry. |

{{< alert type="note" >}}

You must provide at least one of the optional parameters in your request.

The `username` and `password` must be provided together, or not at all. If not set, a public (anonymous) request is used to access the upstream.

{{< /alert >}}

Example request:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

If successful, returns a [`200 OK`](rest/troubleshooting.md#status-codes) status code.

### Update an upstream registry position

Updates the position of an upstream container registry in an ordered list for a container virtual registry.

```plaintext
PATCH /virtual_registries/container/registry_upstreams/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the upstream registry association. |
| `position` | integer | Yes | The position of the upstream registry. Between 1 and 20. |

Example request:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams/1"
```

If successful, returns a [`200 OK`](rest/troubleshooting.md#status-codes) status code.

### Delete an upstream registry

Deletes a specific upstream container registry for a container virtual registry.

```plaintext
DELETE /virtual_registries/container/upstreams/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the upstream registry. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

### Associate an upstream with a registry

Associates an existing upstream container registry with a container virtual registry.

```plaintext
POST /virtual_registries/container/registry_upstreams
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `registry_id` | integer | Yes | The ID of the container virtual registry. |
| `upstream_id` | integer | Yes | The ID of the container upstream registry. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"registry_id": 1, "upstream_id": 2}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams"
```

Example response:

```json
{
  "id": 5,
  "registry_id": 1,
  "upstream_id": 2,
  "position": 2
}
```

### Disassociate an upstream from a registry

Removes the association between an upstream container registry and a container virtual registry.

```plaintext
DELETE /virtual_registries/container/registry_upstreams/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | Yes | The ID of the upstream registry association. |

Example request:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams/1"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

## Manage cache entries

Use the following endpoints to manage cached container images and manifests for a container virtual registry.

### List upstream registry cache entries

Lists cached container images and manifests for a container upstream registry.

```plaintext
GET /virtual_registries/container/upstreams/:id/cache_entries
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | integer | Yes | The ID of the upstream registry. |
| `page` | integer | No | The page number. Defaults to 1. |
| `per_page` | integer | No | The number of items per page. Defaults to 20. |
| `search` | string | No | The search query for the relative path of the container image (for example, `library/nginx`). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/cache_entries?search=library/nginx"
```

Example response:

```json
[
  {
    "id": "MTUgbGlicmFyeS9uZ2lueC9tYW5pZmVzdC9zaGEyNTY6YWJjZGVmZ2hpams=",
    "group_id": 5,
    "upstream_id": 1,
    "upstream_checked_at": "2024-05-30T12:28:27.855Z",
    "file_md5": "44f21d5190b5a6df8089f54799628d7e",
    "file_sha1": "74d101856d26f2db17b39bd22d3204021eb0bf7d",
    "size": 2048,
    "relative_path": "library/nginx/manifests/latest",
    "content_type": "application/vnd.docker.distribution.manifest.v2+json",
    "upstream_etag": "\"686897696a7c876b7e\"",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "downloads_count": 5,
    "downloaded_at": "2024-06-05T14:58:32.855Z"
  }
]
```

### Delete an upstream registry cache entry

Deletes a specific cached container image or manifest for a container upstream registry.

```plaintext
DELETE /virtual_registries/container/cache_entries/*id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string | Yes | The cache entry ID which is the base64-encoded upstream ID and relative path of the cache entry (for example, 'bGlicmFyeS9uZ2lueC9tYW5pZmVzdHMvbGF0ZXN0'). |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/cache_entries/bGlicmFyeS9uZ2lueC9tYW5pZmVzdHMvbGF0ZXN0"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.
