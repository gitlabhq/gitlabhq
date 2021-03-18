---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Dashboard annotations API **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29089) in GitLab 12.10 behind a disabled feature flag.

Metrics dashboard annotations allow you to indicate events on your graphs at a single point in time or over a time span.

## Create a new annotation

```plaintext
POST /environments/:id/metrics_dashboard/annotations/
POST /clusters/:id/metrics_dashboard/annotations/
```

Parameters:

| Attribute      | Type           | Required | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `dashboard_path` | string        | yes      | ID of the dashboard which needs to be annotated. Treated as a CGI-escaped path, and automatically un-escaped.  |
| `starting_at` | string        | yes      | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Timestamp marking start point of annotation.   |
| `ending_at` | string        | no      | Date time string, ISO 8601 formatted, such as `2016-03-11T03:45:40Z`. Timestamp marking end point of annotation. When not supplied, an annotation displays as a single event at the start point.  |
| `description` | string        | yes      | Description of the annotation.  |

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/environments/1/metrics_dashboard/annotations" \
 --data-urlencode "dashboard_path=.gitlab/dashboards/custom_metrics.yml" \
 --data-urlencode "starting_at=2016-03-11T03:45:40Z" \
 --data-urlencode "description=annotation description"
```

Example Response:

```json
{
  "id": 4,
  "starting_at": "2016-04-08T03:45:40.000Z",
  "ending_at": null,
  "dashboard_path": ".gitlab/dashboards/custom_metrics.yml",
  "description": "annotation description",
  "environment_id": 1,
  "cluster_id": null
}
```
