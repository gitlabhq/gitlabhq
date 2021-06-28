---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Group labels API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/21368) in GitLab 11.8.

This API supports managing [group labels](../user/project/labels.md#project-labels-and-group-labels).
It allows users to list, create, update, and delete group labels. Furthermore, users can subscribe to and
unsubscribe from group labels.

NOTE:
The `description_html` - was added to response JSON in [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21413).

## List group labels

Get all labels for a given group.

```plaintext
GET /groups/:id/labels
```

| Attribute     | Type           | Required | Description                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user.                                                               |
| `with_counts` | boolean        | no       | Whether or not to include issue and merge request counts. Defaults to `false`. _([Introduced in GitLab 12.2](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/31543))_ |
| `include_ancestor_groups` | boolean | no | Include ancestor groups. Defaults to `true`. |
| `include_descendant_groups` | boolean | no | Include descendant groups. Defaults to `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259024) in GitLab 13.6 |
| `only_group_labels` | boolean | no | Toggle to include only group labels or also project labels. Defaults to `true`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259024) in GitLab 13.6 |
| `search` | string | no | Keyword to filter labels by. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259024) in GitLab 13.6 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels?with_counts=true"
```

Example response:

```json
[
  {
    "id": 7,
    "name": "bug",
    "color": "#FF0000",
    "text_color" : "#FFFFFF",
    "description": null,
    "description_html": null,
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false
  },
  {
    "id": 4,
    "name": "feature",
    "color": "#228B22",
    "text_color" : "#FFFFFF",
    "description": null,
    "description_html": null,
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false
  }
]
```

## Get a single group label

Get a single label for a given group.

```plaintext
GET /groups/:id/labels/:label_id
```

| Attribute     | Type           | Required | Description                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user.                                                               |
| `label_id` | integer or string | yes | The ID or title of a group's label. |
| `include_ancestor_groups` | boolean | no | Include ancestor groups. Defaults to `true`. |
| `include_descendant_groups` | boolean | no | Include descendant groups. Defaults to `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259024) in GitLab 13.6 |
| `only_group_labels` | boolean | no | Toggle to include only group labels or also project labels. Defaults to `true`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259024) in GitLab 13.6 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

Example response:

```json
{
  "id": 7,
  "name": "bug",
  "color": "#FF0000",
  "text_color" : "#FFFFFF",
  "description": null,
  "description_html": null,
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false
}
```

## Create a new group label

Create a new group label for a given group.

```plaintext
POST /groups/:id/labels
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `name`        | string  | yes      | The name of the label        |
| `color`       | string  | yes      | The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the [CSS color names](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description` | string  | no       | The description of the label, |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"name": "Feature Proposal", "color": "#FFA500", "description": "Describes new ideas" }' \
     "https://gitlab.example.com/api/v4/groups/5/labels"
```

Example response:

```json
{
  "id": 9,
  "name": "Feature Proposal",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false
}
```

## Update a group label

Updates an existing group label. At least one parameter is required, to update the group label.

```plaintext
PUT /groups/:id/labels/:label_id
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes | The ID or title of a group's label. |
| `new_name`    | string  | no      | The new name of the label        |
| `color`       | string  | no      | The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB) or one of the [CSS color names](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description` | string  | no       | The description of the label. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"new_name": "Feature Idea" }' "https://gitlab.example.com/api/v4/groups/5/labels/Feature%20Proposal"
```

Example response:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false
}
```

NOTE:
An older endpoint `PUT /groups/:id/labels` with `name` in the parameters is still available, but deprecated.

## Delete a group label

Deletes a group label with a given name.

```plaintext
DELETE /groups/:id/labels/:label_id
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes | The ID or title of a group's label. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

NOTE:
An older endpoint `DELETE /groups/:id/labels` with `name` in the parameters is still available, but deprecated.

## Subscribe to a group label

Subscribes the authenticated user to a group label to receive notifications. If
the user is already subscribed to the label, the status code `304` is returned.

```plaintext
POST /groups/:id/labels/:label_id/subscribe
```

| Attribute  | Type              | Required | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes      | The ID or title of a group's label. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels/9/subscribe"
```

Example response:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": true
}
```

## Unsubscribe from a group label

Unsubscribes the authenticated user from a group label to not receive
notifications from it. If the user is not subscribed to the label, the status
code `304` is returned.

```plaintext
POST /groups/:id/labels/:label_id/unsubscribe
```

| Attribute  | Type              | Required | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `label_id` | integer or string | yes      | The ID or title of a group's label. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/labels/9/unsubscribe"
```

Example response:

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false
}
```
