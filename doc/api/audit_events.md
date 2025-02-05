---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Audit events API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Author Email added to the response body](https://gitlab.com/gitlab-org/gitlab/-/issues/386322) in GitLab 15.9.

## Instance audit events

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Use this API to retrieve instance audit events.

To retrieve audit events using the API, you must [authenticate yourself](rest/authentication.md) as an Administrator.

### Retrieve all instance audit events

> - Support for keyset pagination [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367528) in GitLab 15.11.
> - Entity type `Gitlab::Audit::InstanceScope` for instance audit events [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418185) in GitLab 16.2.

```plaintext
GET /audit_events
```

| Attribute | Type | Required | Description                                                                                                     |
| --------- | ---- | -------- |-----------------------------------------------------------------------------------------------------------------|
| `created_after` | string | no | Return audit events created on or after the given time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)               |
| `created_before` | string | no | Return audit events created on or before the given time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)              |
| `entity_type` | string | no | Return audit events for the given entity type. Valid values are: `User`, `Group`, `Project`, or `Gitlab::Audit::InstanceScope`. |
| `entity_id` | integer | no | Return audit events for the given entity ID. Requires `entity_type` attribute to be present.                    |

This endpoint supports both offset-based and [keyset-based](rest/_index.md#keyset-based-pagination) pagination. You should use keyset-based
pagination when requesting consecutive pages of results.

Read more on [pagination](rest/_index.md#pagination).

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
      "author_email": "admin@example.com",
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
      "author_email": "admin@example.com",
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
      "author_email": "admin@example.com",
      "target_id": 51,
      "target_type": "User",
      "target_details": "Andreas",
      "ip_address": null,
      "entity_path": "Andreas"
    },
    "created_at": "2019-08-22T16:34:25.639Z"
  },
  {
    "id": 4,
    "author_id": 43,
    "entity_id": 1,
    "entity_type": "Gitlab::Audit::InstanceScope",
    "details": {
      "author_name": "Administrator",
      "author_class": "User",
      "target_id": 32,
      "target_type": "AuditEvents::Streaming::InstanceHeader",
      "target_details": "unknown",
      "custom_message": "Created custom HTTP header with key X-arg.",
      "ip_address": "127.0.0.1",
      "entity_path": "gitlab_instance"
    },
    "ip_address": "127.0.0.1",
    "author_name": "Administrator",
    "entity_path": "gitlab_instance",
    "target_details": "unknown",
    "created_at": "2023-08-01T11:29:44.764Z",
    "target_type": "AuditEvents::Streaming::InstanceHeader",
    "target_id": 32,
    "event_type": "audit_events_streaming_instance_headers_create"
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
    "author_email": "admin@example.com",
    "target_id": "flightjs/flight",
    "target_type": "Project",
    "target_details": "flightjs/flight",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs/flight"
  },
  "created_at": "2019-08-30T07:00:41.885Z"
}
```

## Group audit events

> - Support for keyset pagination [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333968) in GitLab 15.2.

Use this API to retrieve group audit events.

A user with:

- The Owner role can retrieve group audit events of all users.
- The Developer or Maintainer role is limited to group audit events based on their individual actions.

This endpoint supports both offset-based and [keyset-based](rest/_index.md#keyset-based-pagination) pagination. Keyset-based
pagination is recommended when requesting consecutive pages of results.

### Retrieve all group audit events

> - Support for keyset pagination [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333968) in GitLab 15.2.

```plaintext
GET /groups/:id/audit_events
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `created_after` | string | no | Return group audit events created on or after the given time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ)`  |
| `created_before` | string | no | Return group audit events created on or before the given time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](rest/_index.md#pagination).

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
      "author_email": "admin@example.com",
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
      "author_email": "admin@example.com",
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
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
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
    "author_email": "admin@example.com",
    "target_id": "flightjs",
    "target_type": "Group",
    "target_details": "flightjs",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs"
  },
  "created_at": "2019-08-28T19:36:44.162Z"
}
```

## Project audit events

Use this API to retrieve project audit events.

A user with a Maintainer role (or above) can retrieve project audit events of all users.
A user with a Developer role is limited to project audit events based on their individual actions.

### Retrieve all project audit events

> - Support for keyset pagination [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367528) in GitLab 15.10.

```plaintext
GET /projects/:id/audit_events
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `created_after` | string | no | Return project audit events created on or after the given time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)  |
| `created_before` | string | no | Return project audit events created on or before the given time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |

By default, `GET` requests return 20 results at a time because the API results are paginated.
When requesting consecutive pages of results, you should use [keyset pagination](rest/_index.md#keyset-based-pagination).

Read more on [pagination](rest/_index.md#pagination).

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
        "change": "prevent merge request approval from committers",
        "from": "",
        "to": "true",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
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
          "author_email": "admin@example.com",
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

Only available to users with at least the Maintainer role for the project.

```plaintext
GET /projects/:id/audit_events/:audit_event_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
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
      "change": "prevent merge request approval from committers",
      "from": "",
      "to": "true",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": 7,
      "target_type": "Project",
      "target_details": "twitter/typeahead-js",
      "ip_address": "127.0.0.1",
      "entity_path": "twitter/typeahead-js"
  },
  "created_at": "2020-05-26T22:55:04.230Z"
}
```
