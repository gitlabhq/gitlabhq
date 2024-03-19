---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Dependency Proxy API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

## Purge the dependency proxy for a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11631) in GitLab 12.10.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) from GitLab Premium to GitLab Free in 13.6.

Schedules for deletion the cached manifests and blobs for a group. This endpoint requires the
Owner role for the group.

```plaintext
DELETE /groups/:id/dependency_proxy/cache
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/dependency_proxy/cache"
```
