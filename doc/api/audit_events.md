# Audit Events API **(PREMIUM ONLY)**

The Audit Events API allows you to retrieve [instance audit events](../administration/audit_events.md#instance-events-premium-only).

To retrieve audit events using the API, you must [authenticate yourself](README.html#authentication) as an Administrator.

## Retrieve all instance audit events

```
GET /audit_events
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `created_after` | string | no | Return audit events created on or after the given time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ  |
| `created_before` | string | no | Return audit events created on or before the given time. Format: ISO 8601 YYYY-MM-DDTHH:MM:SSZ |
| `entity_type` | string | no | Return audit events for the given entity type. Valid values are: `User`, `Group`, or `Project`.  |
| `entity_id` | boolean | no | Return audit events for the given entity ID. Requires `entity_type` attribute to be present. |

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](README.md#pagination).

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://primary.example.com/api/v4/audit_events
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

## Retrieve single instance audit event

```
GET /audit_events/:id
```

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://primary.example.com/api/v4/audit_events/1
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
