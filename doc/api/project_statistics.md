---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Project statistics API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Every API call to [project](../user/project/_index.md) statistics must be authenticated.
Retrieving these statistics requires read access to the repository.

For use with a [personal access token](../user/profile/personal_access_tokens.md),
use a token with `read_api` scope. For a [group access token](../user/group/settings/group_access_tokens.md),
you can use Reporter role and `read_api` scope.

This API retrieves the number of times the project is either cloned or pulled
with the HTTP method. SSH fetches are not included.

## Get the statistics of the last 30 days

```plaintext
GET /projects/:id/statistics
```

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

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
