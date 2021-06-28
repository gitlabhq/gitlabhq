---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Audit Events API

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/121) in GitLab 12.4.

## Instance Audit Events **(PREMIUM SELF)**

The Audit Events API allows you to retrieve [instance audit events](../administration/audit_events.md#instance-events).
This API cannot retrieve group or project audit events.

To retrieve audit events using the API, you must [authenticate yourself](index.md#authentication) as an Administrator.

### Retrieve all instance audit events

```plaintext
GET /audit_events
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `created_after` | string | no | Return audit events created on or after the given time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ  |
| `created_before` | string | no | Return audit events created on or before the given time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ |
| `entity_type` | string | no | Return audit events for the given entity type. Valid values are: `User`, `Group`, or `Project`.  |
| `entity_id` | integer | no | Return audit events for the given entity ID. Requires `entity_type` attribute to be present. |

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](index.md#pagination).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/audit_events"
```

Example response:

```json
[
  {
    "id": 1,
    "author_id": 1,
    "entity_id": 6,
    "entity_type": "Project",
    "details": {
      "custom_message": "Project archived",
      "author_name": "Administrator",
      "target_id": "flightjs/flight",
      "target_type": "Project",
      "target_details": "flightjs/flight",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs/flight"
    },
    "created_at": "2019-08-30T07:00:41.885Z"
  },
  {
    "id": 2,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "add": "group",
      "author_name": "Administrator",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-27T18:36:44.162Z"
  },
  {
    "id": 3,
    "author_id": 51,
    "entity_id": 51,
    "entity_type": "User",
    "details": {
      "change": "email address",
      "from": "hello@flightjs.com",
      "to": "maintainer@flightjs.com",
      "author_name": "Andreas",
      "target_id": 51,
      "target_type": "User",
      "target_details": "Andreas",
      "ip_address": null,
      "entity_path": "Andreas"
    },
    "created_at": "2019-08-22T16:34:25.639Z"
  }
]
```

### Retrieve single instance audit event

```plaintext
GET /audit_events/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the audit event |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/audit_events/1"
```

Example response:

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 6,
  "entity_type": "Project",
  "details": {
    "custom_message": "Project archived",
    "author_name": "Administrator",
    "target_id": "flightjs/flight",
    "target_type": "Project",
    "target_details": "flightjs/flight",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs/flight"
  },
  "created_at": "2019-08-30T07:00:41.885Z"
}
```

## Group Audit Events **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34078) in GitLab 12.5.

The Group Audit Events API allows you to retrieve [group audit events](../administration/audit_events.md#group-events).
This API cannot retrieve project audit events.

A user with a Owner role (or above) can retrieve group audit events of all users.
A user with a Developer or Maintainer role is limited to group audit events based on their individual actions.

### Retrieve all group audit events

```plaintext
GET /groups/:id/audit_events
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `created_after` | string | no | Return group audit events created on or after the given time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ  |
| `created_before` | string | no | Return group audit events created on or before the given time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ |

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](index.md#pagination).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/groups/60/audit_events"
```

Example response:

```json
[
  {
    "id": 2,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "custom_message": "Group marked for deletion",
      "author_name": "Administrator",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-28T19:36:44.162Z"
  },
  {
    "id": 1,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "add": "group",
      "author_name": "Administrator",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-27T18:36:44.162Z"
  }
]
```

### Retrieve a specific group audit event

Only available to group owners and administrators.

```plaintext
GET /groups/:id/audit_events/:audit_event_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `audit_event_id` | integer | yes | The ID of the audit event |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/groups/60/audit_events/2"
```

Example response:

```json
{
  "id": 2,
  "author_id": 1,
  "entity_id": 60,
  "entity_type": "Group",
  "details": {
    "custom_message": "Group marked for deletion",
    "author_name": "Administrator",
    "target_id": "flightjs",
    "target_type": "Group",
    "target_details": "flightjs",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs"
  },
  "created_at": "2019-08-28T19:36:44.162Z"
}
```

## Project Audit Events **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/219238) in GitLab 13.1.

The Project Audit Events API allows you to retrieve [project audit events](../administration/audit_events.md#project-events).

A user with a Maintainer role (or above) can retrieve project audit events of all users.
A user with a Developer role is limited to project audit events based on their individual actions.

### Retrieve all project audit events

```plaintext
GET /projects/:id/audit_events
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `created_after` | string | no | Return project audit events created on or after the given time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ  |
| `created_before` | string | no | Return project audit events created on or before the given time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ |

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](index.md#pagination).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/projects/7/audit_events"
```

Example response:

```json
[
  {
    "id": 5,
    "author_id": 1,
    "entity_id": 7,
    "entity_type": "Project",
    "details": {
        "change": "prevent merge request approval from reviewers",
        "from": "",
        "to": "true",
        "author_name": "Administrator",
        "target_id": 7,
        "target_type": "Project",
        "target_details": "twitter/typeahead-js",
        "ip_address": "127.0.0.1",
        "entity_path": "twitter/typeahead-js"
    },
    "created_at": "2020-05-26T22:55:04.230Z"
  },
  {
      "id": 4,
      "author_id": 1,
      "entity_id": 7,
      "entity_type": "Project",
      "details": {
          "change": "prevent merge request approval from authors",
          "from": "false",
          "to": "true",
          "author_name": "Administrator",
          "target_id": 7,
          "target_type": "Project",
          "target_details": "twitter/typeahead-js",
          "ip_address": "127.0.0.1",
          "entity_path": "twitter/typeahead-js"
      },
      "created_at": "2020-05-26T22:55:04.218Z"
  }
]
```

### Retrieve a specific project audit event

Only available to project maintainers or owners.

```plaintext
GET /projects/:id/audit_events/:audit_event_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `audit_event_id` | integer | yes | The ID of the audit event |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/projects/7/audit_events/5"
```

Example response:

```json
{
  "id": 5,
  "author_id": 1,
  "entity_id": 7,
  "entity_type": "Project",
  "details": {
      "change": "prevent merge request approval from reviewers",
      "from": "",
      "to": "true",
      "author_name": "Administrator",
      "target_id": 7,
      "target_type": "Project",
      "target_details": "twitter/typeahead-js",
      "ip_address": "127.0.0.1",
      "entity_path": "twitter/typeahead-js"
  },
  "created_at": "2020-05-26T22:55:04.230Z"
}
```
