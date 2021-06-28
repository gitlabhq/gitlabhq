---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Project statistics API **(FREE)**

Every API call to [project](../user/project/index.md) statistics must be authenticated.

## Get the statistics of the last 30 days

Retrieving the statistics requires write access to the repository.
Currently only HTTP fetches statistics are returned.
Fetches statistics includes both clones and pulls count and are HTTP only, SSH fetches are not included.

```plaintext
GET /projects/:id/statistics
```

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `id`      | integer / string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |

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
