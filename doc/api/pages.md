# Pages API

Endpoints for managing [GitLab Pages](https://about.gitlab.com/product/pages/).

The GitLab Pages feature must be enabled to use these endpoints. Find out more about [administering](../administration/pages/index.md) and [using](../user/project/pages/index.md) the feature.

## Unpublish pages

Remove pages. The user must have admin priviledges.

```text
DELETE /projects/:id/pages
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --request 'DELETE' --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/2/pages
```
