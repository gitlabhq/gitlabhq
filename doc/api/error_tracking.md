# Error Tracking settings API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/34940) in GitLab 12.7.

## Error Tracking project settings

The project settings API allows you to retrieve the Error Tracking settings for a project. Only for project maintainers.

### Get Error Tracking settings

```
GET /projects/:id/error_tracking/settings
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/error_tracking/settings
```

Example response:

```json
{
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project"
}
```
