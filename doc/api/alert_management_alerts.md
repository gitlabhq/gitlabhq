---
stage: Service Management
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Alert Management alerts API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The Alert Management alerts API is limited to metric images. For more API endpoints, see the
[GraphQL API](graphql/reference/index.md#alertmanagementalert).

## Upload metric image

```plaintext
POST /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `alert_iid` | integer | yes      | The internal ID of a project's alert. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"  --form 'file=@/path/to/file.png' \
--form 'url=http://example.com' --form 'url_text=Example website' "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images"
```

Example response:

```json
{
    "id": 17,
    "created_at": "2020-11-12T20:07:58.156Z",
    "filename": "sample_2054",
    "file_path": "/uploads/-/system/alert_metric_image/file/17/sample_2054.png",
    "url": "https://example.com/metric",
    "url_text": "An example metric"
}
```

## List metric images

```plaintext
GET /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `alert_iid` | integer | yes      | The internal ID of a project's alert. |

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
        "url": "https://example.com/metric",
        "url_text": "An example metric"
    },
    {
        "id": 18,
        "created_at": "2020-11-12T20:14:26.441Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/alert_metric_image/file/18/sample_2054.png",
        "url": "https://example.com/metric",
        "url_text": "An example metric"
    }
]
```

## Update metric image

```plaintext
PUT /projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `alert_iid` | integer | yes      | The internal ID of a project's alert. |
| `image_id` | integer | yes      | The ID of the image. |
| `url` | string | no      | The URL to view more metrics information. |
| `url_text` | string | no      | A description of the image or URL. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request PUT  --form 'url=http://example.com' --form 'url_text=Example website' "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images/1"
```

Example response:

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/alert_metric_image/file/23/file.png",
    "url": "https://example.com/metric",
    "url_text": "An example metric"
}
```

## Delete metric image

```plaintext
DELETE /projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id
```

| Attribute   | Type    | Required | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `alert_iid` | integer | yes      | The internal ID of a project's alert. |
| `image_id` | integer | yes      | The ID of the image. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request DELETE "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images/1"
```

Can return the following status codes:

- `204 No Content`: if the image was deleted successfully.
- `422 Unprocessable`: if the image could not be deleted.
