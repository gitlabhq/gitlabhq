---
stage: Analyze
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Product analytics API **(ULTIMATE)**

> Introduced in GitLab 15.4 [with a flag](../administration/feature_flags.md) named `cube_api_proxy`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `cube_api_proxy`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

NOTE:
Make sure to define the `cube_api_base_url` and `cube_api_key` application settings first using [the API](settings.md).

## Send query request to Cube

Generate an access token that can be used to query the Cube API. For example:

```plaintext
POST /projects/:id/product_analytics/request/load
POST /projects/:id/product_analytics/request/dry-run
```

| Attribute | Type             | Required | Description                                                   |
| --------- |------------------| -------- |---------------------------------------------------------------|
| `id`      | integer          | yes      | The ID of a project that the current user has read access to. |

### Request body

The body of the load request must be a valid Cube query.

```json
{
  "query": {
    "measures": [
      "Jitsu.count"
    ],
    "timeDimensions": [
      {
        "dimension": "Jitsu.utcTime",
        "dateRange": "This week"
      }
    ],
    "order": [
      [
        "Jitsu.count",
        "desc"
      ],
      [
        "Jitsu.docPath",
        "desc"
      ],
      [
        "Jitsu.utcTime",
        "asc"
      ]
    ],
    "dimensions": [
      "Jitsu.docPath"
    ],
    "limit": 23
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

## List a project's funnels

List all funnels for a project. For example:

```plaintext
GET /projects/:id/product_analytics/funnels
```

| Attribute | Type             | Required | Description                                                        |
| --------- |------------------| -------- |--------------------------------------------------------------------|
| `id`      | integer          | yes      | The ID of a project that the current user has the Developer role for. |
