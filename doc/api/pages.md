---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pages API

Endpoints for managing [GitLab Pages](https://about.gitlab.com/stages-devops-lifecycle/pages/).

The GitLab Pages feature must be enabled to use these endpoints. Find out more about [administering](../administration/pages/index.md) and [using](../user/project/pages/index.md) the feature.

## Unpublish pages

Remove pages. The user must have admin privileges.

```plaintext
DELETE /projects/:id/pages
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --request 'DELETE' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/2/pages"
```
