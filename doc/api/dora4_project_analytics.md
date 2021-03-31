---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, api
---

# DORA4 Analytics Project API **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/279039) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.7.

WARNING:
These endpoints are deprecated and will be removed in GitLab 14.0. Use the [DORA metrics API](dora/metrics.md) instead.

All methods require reporter authorization.

## List project deployment frequencies

Get a list of all project deployment frequencies, sorted by date:

```plaintext
GET /projects/:id/analytics/deployment_frequency?environment=:environment&from=:from&to=:to&interval=:interval
```

| Attribute    | Type   | Required | Description           |
|--------------|--------|----------|-----------------------|
| `id`         | string | yes      | The ID of the project |

| Parameter    | Type   | Required | Description           |
|--------------|--------|----------|-----------------------|
| `environment`| string | yes      | The name of the environment to filter by |
| `from`       | string | yes      | Datetime range to start from, inclusive, ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`) |
| `to`         | string | no       | Datetime range to end at, exclusive, ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`) |
| `interval`   | string | no       | The bucketing interval (`all`, `monthly`, `daily`) |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/analytics/deployment_frequency?environment=:environment&from=:from&to=:to&interval=:interval"
```

Example response:

```json
[
  {
    "from": "2017-01-01",
    "to": "2017-01-02",
    "value": 106
  },
  {
    "from": "2017-01-02",
    "to": "2017-01-03",
    "value": 55
  }
]
```
