---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, api
---

# DORA4 Analytics Group API **(ULTIMATE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291747) in GitLab 13.9.
> - [Deployed behind a feature flag](../user/feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-dora4-analytics-group-api).

WARNING:
These endpoints are deprecated and will be removed in GitLab 14.0. Use the [DORA metrics API](dora/metrics.md) instead.

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

All methods require reporter authorization.

## List group deployment frequencies

Get a list of all group deployment frequencies:

```plaintext
GET /groups/:id/analytics/deployment_frequency?environment=:environment&from=:from&to=:to&interval=:interval
```

Attributes:

| Attribute    | Type   | Required | Description           |
|--------------|--------|----------|-----------------------|
| `id`         | string | yes      | The ID of the group. |

Parameters:

| Parameter    | Type   | Required | Description           |
|--------------|--------|----------|-----------------------|
| `environment`| string | yes      | The name of the environment to filter by. |
| `from`       | string | yes      | Datetime range to start from. Inclusive, ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`). |
| `to`         | string | no       | Datetime range to end at. Exclusive, ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`). |
| `interval`   | string | no       | The bucketing interval (`all`, `monthly`, `daily`). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/analytics/deployment_frequency?environment=:environment&from=:from&to=:to&interval=:interval"
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

## Enable or disable DORA4 Analytics Group API **(ULTIMATE SELF)**

DORA4 Analytics Group API is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:dora4_group_deployment_frequency_api)
```

To disable it:

```ruby
Feature.disable(:dora4_group_deployment_frequency_api)
```
