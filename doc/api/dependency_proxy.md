---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dependency Proxy API

## Purge the dependency proxy for a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11631) in GitLab 12.10.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) to [GitLab Free](https://about.gitlab.com/pricing/) in GitLab 13.6.

Deletes the cached manifests and blobs for a group. This endpoint requires the [Owner role](../user/permissions.md)
for the group.

WARNING:
[A bug exists](https://gitlab.com/gitlab-org/gitlab/-/issues/277161) for this API.

```plaintext
DELETE /groups/:id/dependency_proxy/cache
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/dependency_proxy/cache"
```
