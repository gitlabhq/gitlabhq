# Dependency Proxy API **(PREMIUM)**

## Purge the dependency proxy for a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11631) in GitLab 12.10.

Deletes the cached blobs for a group. This endpoint requires group admin access.

```plaintext
DELETE /groups/:id/dependency_proxy/cache
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/dependency_proxy/cache"
```
