# Labels

## List labels

Get all labels for a given project.

```
GET /projects/:id/labels
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID of the project |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/1/labels
```

Example response:

```json
[
   {
      "name" : "bug",
      "color" : "#d9534f",
      "description": "Bug reported by user",
      "open_issues_count": 1,
      "closed_issues_count": 0,
      "open_merge_requests_count": 1,
      "subscribed": false,
      "priority": 10
   },
   {
      "color" : "#d9534f",
      "name" : "confirmed",
      "description": "Confirmed issue",
      "open_issues_count": 2,
      "closed_issues_count": 5,
      "open_merge_requests_count": 0,
      "subscribed": false,
      "priority": null
   },
   {
      "name" : "critical",
      "color" : "#d9534f",
      "description": "Critical issue. Need fix ASAP",
      "open_issues_count": 1,
      "closed_issues_count": 3,
      "open_merge_requests_count": 1,
      "subscribed": false,
      "priority": null
   },
   {
      "name" : "documentation",
      "color" : "#f0ad4e",
      "description": "Issue about documentation",
      "open_issues_count": 1,
      "closed_issues_count": 0,
      "open_merge_requests_count": 2,
      "subscribed": false,
      "priority": null
   },
   {
      "color" : "#5cb85c",
      "name" : "enhancement",
      "description": "Enhancement proposal",
      "open_issues_count": 1,
      "closed_issues_count": 0,
      "open_merge_requests_count": 1,
      "subscribed": false,
      "priority": null
   }
]
```

## Create a new label

Creates a new label for the given repository with the given name and color.

It returns 200 if the label was successfully created, 400 for wrong parameters
and 409 if the label already exists.

```
POST /projects/:id/labels
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`          | integer | yes      | The ID of the project        |
| `name`        | string  | yes      | The name of the label        |
| `color`       | string  | yes      | The color of the label in 6-digit hex notation with leading `#` sign |
| `description` | string  | no       | The description of the label |
| `priority`    | integer | no       | The priority of the label. Must be greater or equal than zero or `null` to remove the priority. |

```bash
curl --data "name=feature&color=#5843AD" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/labels"
```

Example response:

```json
{
   "name" : "feature",
   "color" : "#5843AD",
   "open_issues_count": 1,
   "closed_issues_count": 0,
   "open_merge_requests_count": 1,
   "description": null,
   "priority": null
}
```

## Delete a label

Deletes a label with a given name.

It returns 200 if the label was successfully deleted, 400 for wrong parameters
and 404 if the label does not exist.
In case of an error, an additional error message is returned.

```
DELETE /projects/:id/labels
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer | yes      | The ID of the project |
| `name`    | string  | yes      | The name of the label |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/labels?name=bug"
```

Example response:

```json
{
   "title" : "feature",
   "color" : "#5843AD",
   "description": "New feature proposal",
   "updated_at" : "2015-11-03T21:22:30.737Z",
   "template" : false,
   "project_id" : 1,
   "created_at" : "2015-11-03T21:22:30.737Z",
   "id" : 9,
   "priority": null
}
```

## Edit an existing label

Updates an existing label with new name or new color. At least one parameter
is required, to update the label.

It returns 200 if the label was successfully deleted, 400 for wrong parameters
and 404 if the label does not exist.
In case of an error, an additional error message is returned.

```
PUT /projects/:id/labels
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`            | integer | yes                               | The ID of the project            |
| `name`          | string  | yes                               | The name of the existing label   |
| `new_name`      | string  | yes if `color` is not provided    | The new name of the label        |
| `color`         | string  | yes if `new_name` is not provided | The new color of the label in 6-digit hex notation with leading `#` sign |
| `description`   | string  | no                                | The new description of the label |
| `priority`    | integer | no       | The new priority of the label. Must be greater or equal than zero or `null` to remove the priority. |


```bash
curl --request PUT --data "name=documentation&new_name=docs&color=#8E44AD&description=Documentation" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/labels"
```

Example response:

```json
{
   "color" : "#8E44AD",
   "name" : "docs",
   "description": "Documentation",
   "open_issues_count": 1,
   "closed_issues_count": 0,
   "open_merge_requests_count": 1,
   "priority": null
}
```

## Subscribe to a label

Subscribes the authenticated user to a label to receive notifications. If the
operation is successful, status code `201` together with the updated label is
returned. If the user is already subscribed to the label, the status code `304`
is returned. If the project or label is not found, status code `404` is
returned.

```
POST /projects/:id/labels/:label_id/subscription
```

| Attribute  | Type              | Required | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`       | integer           | yes      | The ID of a project                  |
| `label_id` | integer or string | yes      | The ID or title of a project's label |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/labels/1/subscription
```

Example response:

```json
{
    "name": "Docs",
    "color": "#cc0033",
    "description": "",
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": true,
    "priority": null
}
```

## Unsubscribe from a label

Unsubscribes the authenticated user from a label to not receive notifications
from it. If the operation is successful, status code `200` together with the
updated label is returned. If the user is not subscribed to the label, the
status code `304` is returned. If the project or label is not found, status code
`404` is returned.

```
DELETE /projects/:id/labels/:label_id/subscription
```

| Attribute  | Type              | Required | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`       | integer           | yes      | The ID of a project                  |
| `label_id` | integer or string | yes      | The ID or title of a project's label |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/labels/1/subscription
```

Example response:

```json
{
    "name": "Docs",
    "color": "#cc0033",
    "description": "",
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "priority": null
}
```
