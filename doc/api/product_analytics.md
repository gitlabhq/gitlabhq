---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Product analytics API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced in GitLab 15.4 [with a flag](../administration/feature_flags/_index.md) named `cube_api_proxy`. Disabled by default.
- `cube_api_proxy` removed and replaced with `product_analytics_internal_preview` in GitLab 15.10.
- `product_analytics_internal_preview` replaced with `product_analytics_dashboards` in GitLab 15.11.
- `product_analytics_dashboards` [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/398653) by default in GitLab 16.11.
- Feature flag `product_analytics_dashboards` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/454059) in GitLab 17.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167296) to beta in GitLab 17.5 [with a flag](../administration/feature_flags/_index.md) named `product_analytics_features`.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is not ready for production use.

{{< /alert >}}

Use this API to track user behavior and application usage.

{{< alert type="note" >}}

Make sure to define the `cube_api_base_url` and `cube_api_key` application settings first using [the API](settings.md).

{{< /alert >}}

## Send query request to Cube

Generate an access token that can be used to query the Cube API. For example:

```plaintext
POST /projects/:id/product_analytics/request/load
POST /projects/:id/product_analytics/request/dry-run
```

| Attribute       | Type             | Required | Description                                                                                 |
|-----------------|------------------| -------- |---------------------------------------------------------------------------------------------|
| `id`            | integer          | yes      | The ID of a project that the current user has read access to.                               |
| `include_token` | boolean          | no       | Whether to include the access token in the response. (Only required for funnel generation.) |

### Request body

The body of the load request must be a valid Cube query.

{{< alert type="note" >}}

When measuring `TrackedEvents`, you must use `TrackedEvents.*` for `dimensions` and `timeDimensions`. The same rule applies when measuring `Sessions`.

{{< /alert >}}

#### Tracked events example

```json
{
  "query": {
    "measures": [
      "TrackedEvents.count"
    ],
    "timeDimensions": [
      {
        "dimension": "TrackedEvents.utcTime",
        "dateRange": "This week"
      }
    ],
    "order": [
      [
        "TrackedEvents.count",
        "desc"
      ],
      [
        "TrackedEvents.docPath",
        "desc"
      ],
      [
        "TrackedEvents.utcTime",
        "asc"
      ]
    ],
    "dimensions": [
      "TrackedEvents.docPath"
    ],
    "limit": 23
  },
  "queryType": "multi"
}
```

#### Sessions example

```json
{
  "query": {
    "measures": [
      "Sessions.count"
    ],
    "timeDimensions": [
      {
        "dimension": "Sessions.startAt",
        "granularity": "day"
      }
    ],
    "order": {
      "Sessions.startAt": "asc"
    },
    "limit": 100
  },
  "queryType": "multi"
}
```

## Send metadata request to Cube

Return Cube Metadata for the Analytics data. For example:

```plaintext
GET /projects/:id/product_analytics/request/meta
```

| Attribute | Type             | Required | Description                                                   |
| --------- |------------------| -------- |---------------------------------------------------------------|
| `id`      | integer          | yes      | The ID of a project that the current user has read access to. |
