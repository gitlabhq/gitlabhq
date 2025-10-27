---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dependency Proxy API
description: Documentation for the REST API for the GitLab dependency proxy.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage the [dependency proxy](../user/packages/dependency_proxy/_index.md).

## Purge the dependency proxy for a group

Schedules for deletion the cached manifests and blobs for a group. This endpoint requires the
Owner role for the group.

```plaintext
DELETE /groups/:id/dependency_proxy/cache
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer or string | yes | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |

Example request:

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/groups/5/dependency_proxy/cache"
```
