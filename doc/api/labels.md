---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project labels API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `archived` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4233) in GitLab 18.3 [with a flag](../administration/feature_flags/_index.md) named `labels_archive`. Disabled by default.

{{< /history >}}

Use this API to manage [project labels](../user/project/labels.md).

For group labels, use the [group labels API](group_labels.md).

## List labels

Get all labels for a given project.

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

```plaintext
GET /projects/:id/labels
```

| Attribute     | Type           | Required | Description                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)                                                              |
| `with_counts` | boolean        | no       | Whether or not to include issue and merge request counts. Defaults to `false`. |
| `include_ancestor_groups` | boolean | no | Include ancestor groups. Defaults to `true`. |
| `search` | string | no | Keyword to filter labels by. |
| `archived` | boolean | no | Whether the label is archived. Returns all labels, when not set. Requires the `labels_archive` feature flag to be enabled. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels?with_counts=true"
```

Example response:

```json
[
  {
    "id" : 1,
    "name" : "bug",
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "description": "Bug reported by user",
    "description_html": "Bug reported by user",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 1,
    "subscribed": false,
    "priority": 10,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 4,
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "name" : "confirmed",
    "description": "Confirmed issue",
    "description_html": "Confirmed issue",
    "open_issues_count": 2,
    "closed_issues_count": 5,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "priority": null,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 7,
    "name" : "critical",
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "description": "Critical issue. Need fix ASAP",
    "description_html": "Critical issue. Need fix ASAP",
    "open_issues_count": 1,
    "closed_issues_count": 3,
    "open_merge_requests_count": 1,
    "subscribed": false,
    "priority": null,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 8,
    "name" : "documentation",
    "color" : "#f0ad4e",
    "text_color" : "#FFFFFF",
    "description": "Issue about documentation",
    "description_html": "Issue about documentation",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 2,
    "subscribed": false,
    "priority": null,
    "is_project_label": false,
    "archived": false
  },
  {
    "id" : 9,
    "color" : "#5cb85c",
    "text_color" : "#FFFFFF",
    "name" : "enhancement",
    "description": "Enhancement proposal",
    "description_html": "Enhancement proposal",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 1,
    "subscribed": true,
    "priority": null,
    "is_project_label": true,
    "archived": false
  }
]
```

## Get a single project label

Get a single label for a given project.

```plaintext
GET /projects/:id/labels/:label_id
```

| Attribute     | Type           | Required | Description                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)                                                              |
| `label_id` | integer or string | yes | The ID or title of a project's label. |
| `include_ancestor_groups` | boolean | no | Include ancestor groups. Defaults to `true`. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

Example response:

```json
{
  "id" : 1,
  "name" : "bug",
  "color" : "#d9534f",
  "text_color" : "#FFFFFF",
  "description": "Bug reported by user",
  "description_html": "Bug reported by user",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 1,
  "subscribed": false,
  "priority": 10,
  "is_project_label": true,
  "archived": false
}
```

## Create a new label

Creates a new label for the given repository with the given name and color.

```plaintext
POST /projects/:id/labels
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | integer or string    | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `name`        | string  | yes      | The name of the label        |
| `color`       | string  | yes      | The color of the label given in 6-digit hex notation with leading '#' sign (for example, #FFAABB) or one of the [CSS color names](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description` | string  | no       | The description of the label |
| `priority`    | integer | no       | The priority of the label. Must be greater or equal than zero or `null` to remove the priority. |
| `archived`    | boolean | no       | Whether the label is archived. Defaults to `false`. Requires the `labels_archive` feature flag to be enabled. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels" \
  --data "name=feature&color=#5843AD"
```

Example response:

```json
{
  "id" : 10,
  "name" : "feature",
  "color" : "#5843AD",
  "text_color" : "#FFFFFF",
  "description":null,
  "description_html":null,
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

## Delete a label

Deletes a label with a given name.

```plaintext
DELETE /projects/:id/labels/:label_id
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`            | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `label_id` | integer or string | yes | The ID or title of a group's label. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

{{< alert type="note" >}}

An older endpoint `DELETE /projects/:id/labels` with `name` in the parameters is still available, but deprecated.

{{< /alert >}}

## Edit an existing label

Updates an existing label with new name or new color. At least one parameter
is required, to update the label.

```plaintext
PUT /projects/:id/labels/:label_id
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | integer or string    | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `label_id` | integer or string | yes | The ID or title of a group's label. |
| `new_name`      | string  | yes if `color` is not provided    | The new name of the label        |
| `color`         | string  | yes if `new_name` is not provided | The color of the label given in 6-digit hex notation with leading '#' sign (for example, #FFAABB) or one of the [CSS color names](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description`   | string  | no                                | The new description of the label |
| `priority`    | integer | no       | The new priority of the label. Must be greater or equal than zero or `null` to remove the priority. |
| `archived`    | boolean | no       | Whether the label is archived. Requires the `labels_archive` feature flag to be enabled. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/documentation" \
  --data "new_name=docs&color=#8E44AD&description=Documentation"
```

Example response:

```json
{
  "id" : 8,
  "name" : "docs",
  "color" : "#8E44AD",
  "text_color" : "#FFFFFF",
  "description": "Documentation",
  "description_html": "Documentation",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 2,
  "subscribed": false,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

{{< alert type="note" >}}

An older endpoint `PUT /projects/:id/labels` with `name` or `label_id` in the parameters is still available, but deprecated.

{{< /alert >}}

## Promote a project label to a group label

Promotes a project label to a group label. The label keeps its ID.

```plaintext
PUT /projects/:id/labels/:label_id/promote
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | integer or string    | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `label_id` | integer or string | yes | The ID or title of a group's label. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/documentation/promote"
```

Example response:

```json
{
  "id" : 8,
  "name" : "documentation",
  "color" : "#8E44AD",
  "description": "Documentation",
  "description_html": "Documentation",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 2,
  "subscribed": false,
  "archived": false
}
```

{{< alert type="note" >}}

An older endpoint `PUT /projects/:id/labels/promote` with `name` in the parameters is still available, but deprecated.

{{< /alert >}}

## Subscribe to a label

Subscribes the authenticated user to a label to receive notifications.
If the user is already subscribed to the label, the status code `304`
is returned.

```plaintext
POST /projects/:id/labels/:label_id/subscribe
```

| Attribute  | Type              | Required | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | integer or string    | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `label_id` | integer or string | yes      | The ID or title of a project's label |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/labels/1/subscribe"
```

Example response:

```json
{
  "id" : 1,
  "name" : "bug",
  "color" : "#d9534f",
  "text_color" : "#FFFFFF",
  "description": "Bug reported by user",
  "description_html": "Bug reported by user",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 1,
  "subscribed": true,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

## Unsubscribe from a label

Unsubscribes the authenticated user from a label to not receive notifications
from it. If the user is not subscribed to the label, the
status code `304` is returned.

```plaintext
POST /projects/:id/labels/:label_id/unsubscribe
```

| Attribute  | Type              | Required | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | integer or string    | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `label_id` | integer or string | yes      | The ID or title of a project's label |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/labels/1/unsubscribe"
```
