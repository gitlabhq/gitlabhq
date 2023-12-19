---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Pages API **(FREE ALL)**

Endpoints for managing [GitLab Pages](https://about.gitlab.com/stages-devops-lifecycle/pages/).

The GitLab Pages feature must be enabled to use these endpoints. Find out more about [administering](../administration/pages/index.md) and [using](../user/project/pages/index.md) the feature.

## Unpublish Pages

Prerequisites:

- You must have administrator access to the instance.

Remove Pages.

```plaintext
DELETE /projects/:id/pages
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --request 'DELETE' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/2/pages"
```
