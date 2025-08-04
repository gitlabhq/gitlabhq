---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven Virtual Registry API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="flag" >}}

The availability of these endpoints is controlled by a feature flag.
For more information, see the history.
These endpoints are available in [beta](../policy/development_stages_support.md#beta).
Review the documentation carefully before you use them.

{{< /alert >}}

Use this API to create and manage Maven virtual registries, configure upstream registries, manage cache entries, and handle package downloads and uploads.

## Manage virtual registries

Use the following endpoints to create and manage Maven virtual registries.

### List all virtual registries

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Lists all Maven virtual registries for a group.

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/registries
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | string/integer | yes | The group ID or full group path. Must be a top-level group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/registries"
```

Example response:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "name": "my-virtual-registry",
    "description": "My virtual registry",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### Create a virtual registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Creates a Maven virtual registry for a group.

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/registries
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string/integer | yes | The group ID or full group path. Must be a top-level group. |
| `name` | string | yes | The name of the virtual registry. |
| `description` | string | no | The description of the virtual registry. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"name": "my-virtual-registry", "description": "My virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/registries"
```

Example response:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-virtual-registry",
  "description": "My virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Get a virtual registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Gets a specific Maven virtual registry.

```plaintext
GET /virtual_registries/packages/maven/registries/:id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the Maven virtual registry. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

Example response:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-virtual-registry",
  "description": "My virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Update a virtual registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189070) in GitLab 18.0 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Updates a specific Maven virtual registry.

```plaintext
PATCH /virtual_registries/packages/maven/registries/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the Maven virtual registry. |
| `name` | string | yes | The name of the virtual registry. |
| `description` | string | no | The description of the virtual registry. |

Example request:

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"name": "my-virtual-registry", "description": "My virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

If successful, returns a [`200 OK`](rest/troubleshooting.md#status-codes) status code.

### Delete a virtual registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

{{< alert type="warning" >}}

Deleting a virtual registry also deletes all associated upstream registries that are not shared with other virtual registries, along with their cache entries.

{{< /alert >}}

Deletes a specific Maven virtual registry.

```plaintext
DELETE /virtual_registries/packages/maven/registries/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the Maven virtual registry. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

### Delete cache entries for a virtual registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) in GitLab 18.2 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

Schedule all cache entries for deletion in all exclusive upstream registries for a Maven virtual registry. Cache entries are not scheduled for deletion for upstream registries that are associated with other virtual registries.

```plaintext
DELETE /virtual_registries/packages/maven/registries/:id/cache
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the Maven virtual registry. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/cache"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

## Manage upstream registries

Use the following endpoints to configure and manage upstream Maven registries.

### List all upstream registries for a top-level group

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/550728) in GitLab 18.3 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

Lists all upstream registries for a top-level group.

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/upstreams
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | string/integer | yes | The group ID or full group path. Must be a top-level group. |
| `page` | integer | no | The page number. Defaults to 1. |
| `per_page` | integer | no | The number of items per page. Defaults to 20. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/upstreams"
```

Example response:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://repo.maven.apache.org/maven2",
    "name": "Maven Central",
    "description": "Maven Central repository",
    "cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### List all upstream registries for a virtual registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Lists all upstream registries for a Maven virtual registry.

```plaintext
GET /virtual_registries/packages/maven/registries/:id/upstreams
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | integer | yes | The ID of the Maven virtual registry. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/upstreams"
```

Example response:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://repo.maven.apache.org/maven2",
    "name": "Maven Central",
    "description": "Maven Central repository",
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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Adds an upstream registry to a Maven virtual registry.

```plaintext
POST /virtual_registries/packages/maven/registries/:id/upstreams
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the Maven virtual registry. |
| `url` | string | yes | The URL of the upstream registry. |
| `username` | string | no | The username of the upstream registry. |
| `password` | string | no | The password of the upstream registry. |
| `cache_validity_hours` | integer | no | The cache validity period. Defaults to 24 hours. |

{{< alert type="note" >}}

You must include both the `username` and `password` in the request, or not at all. If not set, a public (anonymous) request is used to access the upstream.

{{< /alert >}}

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://repo.maven.apache.org/maven2", "name": "Maven Central", "description": "Maven Central repository", "username": <your_username>, "password": <your_password>, "cache_validity_hours": 48}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/upstreams"
```

Example response:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://repo.maven.apache.org/maven2",
  "name": "Maven Central",
  "description": "Maven Central repository",
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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Gets a specific upstream registry for a Maven virtual registry.

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the upstream registry. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

Example response:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://repo.maven.apache.org/maven2",
  "name": "Maven Central",
  "description": "Maven Central repository",
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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Updates a specific upstream registry for a Maven virtual registry.

```plaintext
PATCH /virtual_registries/packages/maven/upstreams/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the upstream registry. |
| `url` | string | no | The URL of the upstream registry. |
| `name` | string | no | The name of the upstream registry. |
| `description` | string | no | The description of the upstream registry. |
| `username` | string | no | The username of the upstream registry. |
| `password` | string | no | The password of the upstream registry. |
| `cache_validity_hours` | integer | no | The cache validity period. Defaults to 24 hours. |

{{< alert type="note" >}}

You must provide at least one of the optional parameters in your request.

The `username` and `password` must be provided together, or not at all. If not set, a public (anonymous) request is used to access the upstream.

{{< /alert >}}

Example request:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

If successful, returns a [`200 OK`](rest/troubleshooting.md#status-codes) status code.

### Update an upstream registry position

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186890) in GitLab 18.0 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Updates the position of an upstream registry in an ordered list for a Maven virtual registry.

```plaintext
PATCH /virtual_registries/packages/maven/registry_upstreams/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the upstream registry. |
| `position` | integer | yes | The position of the upstream registry. Between 1 and 20. |

Example request:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

If successful, returns a [`200 OK`](rest/troubleshooting.md#status-codes) status code.

### Delete an upstream registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Deletes a specific upstream registry for a Maven virtual registry.

```plaintext
DELETE /virtual_registries/packages/maven/upstreams/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the upstream registry. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

### Associate an upstream with a registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) in GitLab 18.1 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Associates an existing upstream registry with a Maven virtual registry.

```plaintext
POST /virtual_registries/packages/maven/registry_upstreams
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `registry_id` | integer | yes | The ID of the Maven virtual registry. |
| `upstream_id` | integer | yes | The ID of the Maven upstream registry. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"registry_id": 1, "upstream_id": 2}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams"
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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) in GitLab 18.1 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Removes the association between an upstream registry and a Maven virtual registry.

{{< alert type="warning" >}}

If this is the last association for the upstream, removal of the association deletes the upstream itself and all its cache entries.

{{< /alert >}}

```plaintext
DELETE /virtual_registries/packages/maven/registry_upstreams/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the registry upstream association. |

Example request:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

### Delete cache entries for an upstream registry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/538327) in GitLab 18.2 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

Schedules all cache entries for deletion for a specific upstream registry in a Maven virtual registry.

```plaintext
DELETE /virtual_registries/packages/maven/upstreams/:id/cache
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the upstream registry. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/cache"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

## Manage cache entries

Use the following endpoints to manage cache entries for a Maven virtual registry.

### List upstream registry cache entries

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162614) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Lists cache entries for a Maven upstream registry.

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/cache_entries
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | integer | yes | The ID of the upstream registry. |
| `search` | string | no | The search query for the relative path of the package (for example, `foo/bar/mypkg`). |
| `page` | integer | no | The page number. Defaults to 1. |
| `per_page` | integer | no | The number of items per page. Defaults to 20. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/cache_entries?search=foo/bar"
```

Example response:

```json
[
  {
    "id": "MTUgZm9vL2Jhci9teXBrZy8xLjAtU05BUFNIT1QvbXlwa2ctMS4wLVNOQVBTSE9ULmphcg==",
    "group_id": 5,
    "upstream_id": 1,
    "upstream_checked_at": "2024-05-30T12:28:27.855Z",
    "file_md5": "44f21d5190b5a6df8089f54799628d7e",
    "file_sha1": "74d101856d26f2db17b39bd22d3204021eb0bf7d",
    "size": 2048,
    "relative_path": "foo/bar/package-1.0.0.pom",
    "content_type": "application/xml",
    "upstream_etag": "\"686897696a7c876b7e\"",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### Delete an upstream registry cache entry

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162614) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Deletes a specific cache entry for a Maven upstream registry.

```plaintext
DELETE /virtual_registries/packages/maven/cache_entries/*id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string | yes | The base64-encoded upstream ID and relative path of the cache entry (for example, 'Zm9vL2Jhci9teXBrZy5wb20='). |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/cache_entries/Zm9vL2Jhci9teXBrZy5wb20="
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.

## Manage package operations

Use the following endpoints to manage package operations for a Maven virtual registry.

{{< alert type="warning" >}}

These endpoints are intended for internal use by GitLab, and generally not meant for manual consumption.

{{< /alert >}}

{{< alert type="note" >}}

These endpoints do not adhere to the [REST API authentication methods](rest/authentication.md).
For more information on which headers and token types are supported,
see [Maven virtual registry](../user/packages/virtual_registry/maven/_index.md). Undocumented authentication methods might be removed in the future.

{{< /alert >}}

### Download a package

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160891) in GitLab 17.3 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Downloads a package from a Maven virtual registry. To access this resource, you must [authenticate with the registry](../user/packages/package_registry/supported_functionality.md#authenticate-with-the-registry).

```plaintext
GET /virtual_registries/packages/maven/:id/*path
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | integer | yes | The ID of the Maven virtual registry. |
| `path` | string | yes | The full package path (for example, `foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/1/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" \
     --output mypkg-1.0-SNAPSHOT.jar
```

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and
the following response headers:

- `x-checksum-sha1`: SHA1 checksum of the file
- `x-checksum-md5`: MD5 checksum of the file
- `Content-Type`: The MIME type of the file
- `Content-Length`: The file size in bytes

### Upload a package

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163641) in GitLab 17.4 [with a flag](../administration/feature_flags/_index.md) named `virtual_registry_maven`. Disabled by default.
- Feature flag [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) to `maven_virtual_registry` in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/540276) from experiment to beta in GitLab 18.1.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432) in GitLab 18.2.

{{< /history >}}

Uploads a package to a Maven virtual registry. This endpoint is accessible only by [GitLab Workhorse](../development/workhorse/_index.md).

```plaintext
POST /virtual_registries/packages/maven/:id/*path/upload
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the Maven virtual registry. |
| `path` | string | yes | The full package path (for example, `foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`). |
| `file` | file | yes | The file being uploaded. |

Request headers:

- `Etag`: Entity tag for the file
- `GitLab-Workhorse-Send-Dependency-Content-Type`: Content type of the file
- `Upstream-GID`: Global ID of the target upstream

If successful, returns a [`200 OK`](rest/troubleshooting.md#status-codes) status code.
