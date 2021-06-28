---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Error Tracking settings API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34940) in GitLab 12.7.

## Error Tracking project settings

The project settings API allows you to retrieve the [Error Tracking](../operations/error_tracking.md)
settings for a project. Only for project maintainers.

### Get Error Tracking settings

```plaintext
GET /projects/:id/error_tracking/settings
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings"
```

Example response:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project"
}
```

### Enable or disable the Error Tracking project settings

The API allows you to enable or disable the Error Tracking settings for a project. Only for project maintainers.

```plaintext
PATCH /projects/:id/error_tracking/settings
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `active`  | boolean | yes      | Pass `true` to enable the already configured error tracking settings or `false` to disable it. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true"
```

Example response:

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project"
}
```
