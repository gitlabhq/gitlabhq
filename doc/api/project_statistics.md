---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project statistics API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to retrieve statistics about a [project](../user/project/_index.md).
All endpoints require authentication.

You must have read access to the repository. [Personal access tokens](../user/profile/personal_access_tokens.md)
must have the `read_api` scope. [Group access tokens](../user/group/settings/group_access_tokens.md)
can use the Reporter role and the `read_api` scope.

This API retrieves the number of times the project is either cloned or pulled
with the HTTP method. SSH fetches are not included.

## Get the statistics of the last 30 days

Get the clone and pull statistics for a project for the last 30 days.

```plaintext
GET /projects/:id/statistics
```

Supported attributes:

| Attribute | Type              | Required | Description                                                                    |
|-----------|-------------------|----------|--------------------------------------------------------------------------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).     |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute              | Type    | Description |
|------------------------|---------|-------------|
| `fetches`              | object  | Fetch statistics for the project. |
| `fetches.days`         | array   | Array of daily fetch statistics. |
| `fetches.days[].count` | integer | Number of fetches for the specific date. |
| `fetches.days[].date`  | string  | Date in ISO format (`YYYY-MM-DD`). |
| `fetches.total`        | integer | Total number of fetches for the last 30 days. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/statistics"
```

Example response:

```json
{
  "fetches": {
    "total": 50,
    "days": [
      {
        "count": 10,
        "date": "2018-01-10"
      },
      {
        "count": 10,
        "date": "2018-01-09"
      },
      {
        "count": 10,
        "date": "2018-01-08"
      },
      {
        "count": 10,
        "date": "2018-01-07"
      },
      {
        "count": 10,
        "date": "2018-01-06"
      }
    ]
  }
}
```
