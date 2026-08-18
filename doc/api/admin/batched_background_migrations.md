---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to list, retrieve, pause, and resume batched background migrations.
title: Batched background migrations API
ignore_in_report: true
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Use this API to monitor and manage [batched background migrations](../../update/background_migrations.md).

Prerequisites:

- You must have administrator access to the instance.

## List the last 20 batched background migrations

List all batched background migrations.

```plaintext
GET /api/v4/admin/batched_background_migrations
```

Supported attributes:

| Attribute        | Type   | Required | Description |
|------------------|--------|----------|-------------|
| `database`       | string | No       | Name of the database. Defaults to `main`. |
| `job_class_name` | string | No       | Filter migrations by job class name. |

If successful, returns [`200 OK`](../rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                  | Type     | Description |
|----------------------------|----------|-------------|
| `column_name`              | string   | Name of the column the migration iterates over. |
| `created_at`               | datetime | Timestamp of when the migration was created. |
| `estimated_time_remaining` | string   | Estimated time until the migration completes. Sometimes null |
| `id`                       | integer  | ID of the batched background migration. |
| `job_class_name`           | string   | Name of the migration job class. |
| `progress`                 | float    | Completion percentage of the migration. |
| `status`                   | string   | Status of the migration. Can be `paused`, `active`, `finished`, `failed`, `finalizing`, or `finalized`. |
| `table_name`               | string   | Name of the table the migration iterates over. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/batched_background_migrations"
```

Example response:

```json
[
  {
    "id": 1234,
    "job_class_name": "CopyColumnUsingBackgroundMigrationJob",
    "table_name": "events",
    "column_name": "id",
    "status": "active",
    "progress": 50.0,
    "created_at": "2022-11-28T16:26:39+02:00",
    "estimated_time_remaining": "1 day"
  }
]
```

## Retrieve a batched background migration

Retrieve a batched background migration.

```plaintext
GET /api/v4/admin/batched_background_migrations/:id
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|------------|---------|----------|-------------|
| `id`       | integer | Yes      | ID of the batched background migration. |
| `database` | string  | No       | Name of the database. Defaults to `main`. |

If successful, returns [`200 OK`](../rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                  | Type     | Description |
|----------------------------|----------|-------------|
| `column_name`              | string   | Name of the column the migration iterates over. |
| `created_at`               | datetime | Timestamp of when the migration was created. |
| `estimated_time_remaining` | string   | Estimated time until the migration completes. |
| `id`                       | integer  | ID of the batched background migration. |
| `job_class_name`           | string   | Name of the migration job class. |
| `progress`                 | float    | Completion percentage of the migration. |
| `status`                   | string   | Status of the migration. Can be `paused`, `active`, `finished`, `failed`, `finalizing`, or `finalized`. |
| `table_name`               | string   | Name of the table the migration iterates over. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/batched_background_migrations/1234"
```

Example response:

```json
{
  "id": 1234,
  "job_class_name": "CopyColumnUsingBackgroundMigrationJob",
  "table_name": "events",
  "column_name": "id",
  "status": "active",
  "progress": 50.0,
  "created_at": "2022-11-28T16:26:39+02:00",
  "estimated_time_remaining": "1 day"
}
```

## Pause a batched background migration

Pause a batched background migration. You can pause only migrations with an `active` status.

```plaintext
PUT /api/v4/admin/batched_background_migrations/:id/pause
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|------------|---------|----------|-------------|
| `id`       | integer | Yes      | ID of the batched background migration. |
| `database` | string  | No       | Name of the database. Defaults to `main`. |

If successful, returns [`200 OK`](../rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                  | Type     | Description |
|----------------------------|----------|-------------|
| `column_name`              | string   | Name of the column the migration iterates over. |
| `created_at`               | datetime | Timestamp of when the migration was created. |
| `estimated_time_remaining` | string   | Estimated time until the migration completes. |
| `id`                       | integer  | ID of the batched background migration. |
| `job_class_name`           | string   | Name of the migration job class. |
| `progress`                 | float    | Completion percentage of the migration. |
| `status`                   | string   | Status of the migration. Can be `paused`, `active`, `finished`, `failed`, `finalizing`, or `finalized`. |
| `table_name`               | string   | Name of the table the migration iterates over. |

If the migration does not have an `active` status, returns [`422 Unprocessable Entity`](../rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/batched_background_migrations/1234/pause"
```

Example response:

```json
{
  "id": 1234,
  "job_class_name": "CopyColumnUsingBackgroundMigrationJob",
  "table_name": "events",
  "column_name": "id",
  "status": "paused",
  "progress": 50.0,
  "created_at": "2022-11-28T16:26:39+02:00",
  "estimated_time_remaining": "1 day"
}
```

## Resume a batched background migration

Resume a batched background migration. You can resume only migrations with a `paused` status.

```plaintext
PUT /api/v4/admin/batched_background_migrations/:id/resume
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|------------|---------|----------|-------------|
| `id`       | integer | Yes      | ID of the batched background migration. |
| `database` | string  | No       | Name of the database. Defaults to `main`. |

If successful, returns [`200 OK`](../rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                  | Type     | Description |
|----------------------------|----------|-------------|
| `column_name`              | string   | Name of the column the migration iterates over. |
| `created_at`               | datetime | Timestamp of when the migration was created. |
| `estimated_time_remaining` | string   | Estimated time until the migration completes. |
| `id`                       | integer  | ID of the batched background migration. |
| `job_class_name`           | string   | Name of the migration job class. |
| `progress`                 | float    | Completion percentage of the migration. |
| `status`                   | string   | Status of the migration. Can be `paused`, `active`, `finished`, `failed`, `finalizing`, or `finalized`. |
| `table_name`               | string   | Name of the table the migration iterates over. |

If the migration does not have a `paused` status, returns [`422 Unprocessable Entity`](../rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/batched_background_migrations/1234/resume"
```

Example response:

```json
{
  "id": 1234,
  "job_class_name": "CopyColumnUsingBackgroundMigrationJob",
  "table_name": "events",
  "column_name": "id",
  "status": "active",
  "progress": 50.0,
  "created_at": "2022-11-28T16:26:39+02:00",
  "estimated_time_remaining": "1 day"
}
```
