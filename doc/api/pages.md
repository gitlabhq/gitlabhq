---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Pages API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Endpoints for managing [GitLab Pages](../user/project/pages/index.md).

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

## Get pages settings for a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/436932) in GitLab 16.8.

Prerequisites:

- You must have at least the Maintainer role for the project.

List Pages settings for the project.

```plaintext
GET /projects/:id/pages
```

Supported attributes:

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user |

If successful, returns [`200`](rest/index.md#status-codes) and the following
response attributes:

| Attribute                                 | Type       | Description                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | string     | URL to access this project pages.                                                                                            |
| `is_unique_domain_enabled`                | boolean    | If [unique domain](../user/project/pages/introduction.md) is enabled.                                                        |
| `force_https`                             | boolean    | `true` if the project is set to force HTTPS.                                                                                      |
| `deployments[]`                           | array      | List of current active deployments.                                                                                          |

| `deployments[]` attribute                 | Type       | Description                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `created_at`                              | date       | Date deployment was created.                                                                                                 |
| `url`                                     | string     | URL for this deployment.                                                                                                     |
| `path_prefix`                             | string     | Path prefix of this deployment when using [multiple deployments](../user/project/pages/index.md#create-multiple-deployments). |
| `root_directory`                          | string     | Root directory.                                                                                                              |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/2/pages"
```

Example response:

```json
{
  "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010",
  "is_unique_domain_enabled": true,
  "force_https": false,
  "deployments": [
    {
      "created_at": "2024-01-05T18:58:14.916Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/",
      "path_prefix": "",
      "root_directory": null
    },
    {
      "created_at": "2024-01-05T18:58:46.042Z",
      "url": "http://html-root-4160ce5f0e9a6c90ccb02755b7fc80f5a2a09ffbb1976cf80b653.pages.gdk.test:3010/mr3",
      "path_prefix": "mr3",
      "root_directory": null
    }
  ]
}
```
