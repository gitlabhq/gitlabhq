---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pages API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Endpoints for managing [GitLab Pages](../user/project/pages/_index.md).

The GitLab Pages feature must be enabled to use these endpoints. Find out more about [administering](../administration/pages/_index.md) and [using](../user/project/pages/_index.md) the feature.

## Unpublish Pages

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/498658) the minimum required role from administrator access to the Maintainer role in GitLab 17.9

Prerequisites:

- You must have at least the Maintainer role for the project.

Remove Pages.

```plaintext
DELETE /projects/:id/pages
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

```shell
curl --request 'DELETE' --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/2/pages"
```

## Get Pages settings for a project

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
| `id`      | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                                 | Type       | Description                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | string     | URL to access this project's Pages.                                                                                            |
| `is_unique_domain_enabled`                | boolean    | If [unique domain](../user/project/pages/introduction.md) is enabled.                                                        |
| `force_https`                             | boolean    | `true` if the project is set to force HTTPS.                                                                                      |
| `deployments[]`                           | array      | List of current active deployments.                                                                                          |
| `primary_domain`                          | string     | Primary domain to redirect all Pages requests to. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481334) in GitLab 17.8. |

| `deployments[]` attribute                 | Type       | Description                                                                                                                   |
| ----------------------------------------- | ---------- |-------------------------------------------------------------------------------------------------------------------------------|
| `created_at`                              | date       | Date deployment was created.                                                                                                  |
| `url`                                     | string     | URL for this deployment.                                                                                                      |
| `path_prefix`                             | string     | Path prefix of this deployment when using [parallel deployments](../user/project/pages/_index.md#parallel-deployments). |
| `root_directory`                          | string     | Root directory.                                                                                                               |

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
  ],
  "primary_domain": null
}
```

## Update Pages settings for a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147227) in GitLab 17.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/498658) the minimum required role from administrator access to the Maintainer role in GitLab 17.9

Prerequisites:

- You must have at least the Maintainer role for the project.

Update Pages settings for the project.

```plaintext
PATCH /projects/:id/pages
```

Supported attributes:

| Attribute                       | Type           | Required | Description                                                                                                         |
| --------------------------------| -------------- | -------- | --------------------------------------------------------------------------------------------------------------------|
| `id`                            | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)                                 |
| `pages_unique_domain_enabled`   | boolean        | No       | Whether to use unique domain                                                                                        |
| `pages_https_only`              | boolean        | No       | Whether to force HTTPs                                                                                              |
| `pages_primary_domain`          | string         | No       | Set the primary domain from the existing assigned domains to redirect all Pages requests to. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481334) in GitLab 17.8. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                                 | Type       | Description                                                                                                                  |
| ----------------------------------------- | ---------- | -----------------------                                                                                                      |
| `url`                                     | string     | URL to access this project's Pages.                                                                                            |
| `is_unique_domain_enabled`                | boolean    | If [unique domain](../user/project/pages/introduction.md) is enabled.                                                        |
| `force_https`                             | boolean    | `true` if the project is set to force HTTPS.                                                                                      |
| `deployments[]`                           | array      | List of current active deployments.                                                                                          |
| `primary_domain`                          | string     | Primary domain to redirect all Pages requests to. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481334) in GitLab 17.8. |

| `deployments[]` attribute                 | Type       | Description                                                                                                                   |
| ----------------------------------------- | ---------- |-------------------------------------------------------------------------------------------------------------------------------|
| `created_at`                              | date       | Date deployment was created.                                                                                                  |
| `url`                                     | string     | URL for this deployment.                                                                                                      |
| `path_prefix`                             | string     | Path prefix of this deployment when using [parallel deployments](../user/project/pages/_index.md#parallel-deployments). |
| `root_directory`                          | string     | Root directory.                                                                                                               |

Example request:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/pages" \
  --form 'pages_unique_domain_enabled=true' \
  --form 'pages_https_only=true' \
  --form 'pages_primary_domain=https://custom.example.com'
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
  ],
  "primary_domain": null
}
```
