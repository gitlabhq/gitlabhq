---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Alert Management Alerts API **(FREE)**

This is the documentation of Alert Management Alerts API.

NOTE:
This API is limited to metric images. For more API endpoints please refer to the [GraphQL API](graphql/reference/index.md#alertmanagementalert).

## List metric images

```plaintext
GET /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user  |
| `alert_iid` | integer | yes      | The internal ID of a project's alert |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images"
```

Example response:

```json
[
    {
        "id": 17,
        "created_at": "2020-11-12T20:07:58.156Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/alert_metric_image/file/17/sample_2054.png",
        "url": "example.com/metric",
        "url_text": "An example metric"
    },
    {
        "id": 18,
        "created_at": "2020-11-12T20:14:26.441Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/alert_metric_image/file/18/sample_2054.png",
        "url": "example.com/metric",
        "url_text": "An example metric"
    }
]
```
