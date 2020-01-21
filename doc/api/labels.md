# Labels API

NOTE: **Note:**
The `description_html` - was added to response JSON in [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/merge_requests/21413).

## List labels

Get all labels for a given project.

```
GET /projects/:id/labels
```

| Attribute     | Type           | Required | Description                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                                                              |
| `with_counts` | boolean        | no       | Whether or not to include issue and merge request counts. Defaults to `false`. _([Introduced in GitLab 12.2](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/31543))_ |
| `include_ancestor_groups` | boolean | no | Include ancestor groups. Defaults to `true`. |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/labels?with_counts=true
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
    "is_project_label": true
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
    "is_project_label": true
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
    "is_project_label": true
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
    "is_project_label": false
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
    "is_project_label": true
  }
]
```

## Get a single project label

Get a single label for a given project.

```
GET /projects/:id/labels/:label_id
```

| Attribute     | Type           | Required | Description                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                                                              |
| `label_id` | integer or string | yes | The ID or title of a group's label. |
| `include_ancestor_groups` | boolean | no | Include ancestor groups. Defaults to `true`. |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/labels/bug
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
  "is_project_label": true
}
```

## Create a new label

Creates a new label for the given repository with the given name and color.

```
POST /projects/:id/labels
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `name`        | string  | yes      | The name of the label        |
| `color`       | string  | yes      | The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the [CSS color names](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description` | string  | no       | The description of the label |
| `priority`    | integer | no       | The priority of the label. Must be greater or equal than zero or `null` to remove the priority. |

```bash
curl --data "name=feature&color=#5843AD" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/labels"
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
    "is_project_label": true
}
```

## Delete a label

Deletes a label with a given name.

```
DELETE /projects/:id/labels/:label_id
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`            | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes | The ID or title of a group's label. |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

NOTE: **Note:** An older endpoint `DELETE /projects/:id/labels` with `name` in the params is still available, but deprecated.

## Edit an existing label

Updates an existing label with new name or new color. At least one parameter
is required, to update the label.

```
PUT /projects/:id/labels/:label_id
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes | The ID or title of a group's label. |
| `new_name`      | string  | yes if `color` is not provided    | The new name of the label        |
| `color`         | string  | yes if `new_name` is not provided | The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the [CSS color names](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description`   | string  | no                                | The new description of the label |
| `priority`    | integer | no       | The new priority of the label. Must be greater or equal than zero or `null` to remove the priority. |

```bash
curl --request PUT --data "new_name=docs&color=#8E44AD&description=Documentation" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/labels/documentation"
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
  "is_project_label": true
}
```

NOTE: **Note:** An older endpoint `PUT /projects/:id/labels` with `name` or `label_id` in the params is still available, but deprecated.

## Promote a project label to a group label

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/25218) in GitLab 12.3.

Promotes a project label to a group label.

```
PUT /projects/:id/labels/:label_id/promote
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes | The ID or title of a group's label. |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/labels/documentation/promote"
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
  "subscribed": false
}
```

NOTE: **Note:** An older endpoint `PUT /projects/:id/labels/promote` with `name` in the params is still available, but deprecated.

## Subscribe to a label

Subscribes the authenticated user to a label to receive notifications.
If the user is already subscribed to the label, the status code `304`
is returned.

```
POST /projects/:id/labels/:label_id/subscribe
```

| Attribute  | Type              | Required | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes      | The ID or title of a project's label |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/labels/1/subscribe
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
  "is_project_label": true
}
```

## Unsubscribe from a label

Unsubscribes the authenticated user from a label to not receive notifications
from it. If the user is not subscribed to the label, the
status code `304` is returned.

```
POST /projects/:id/labels/:label_id/unsubscribe
```

| Attribute  | Type              | Required | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes      | The ID or title of a project's label |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/labels/1/unsubscribe
```
