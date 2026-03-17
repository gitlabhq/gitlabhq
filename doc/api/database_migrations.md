---
stage: Data Access
group: Database Frameworks
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Database migrations API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123408) in GitLab 16.2.

{{< /history >}}

Use this API to manage GitLab database migrations.

Prerequisites:

- You must have administrator access to the instance.

## Mark a migration as successful

Marks pending migrations as successfully executed to prevent them from being executed by the `db:migrate` tasks.
Use this API to skip failing migrations after you determine they are safe to skip.

```plaintext
POST /api/v4/admin/migrations/:version/mark
```

| Attribute       | Type           | Required | Description                                                                                                                                                                                      |
|-----------------|----------------|----------|----------------------------------------------------------------------------------|
| `version`       | integer        | yes      | Version timestamp of the migration to be skipped                                 |
| `database`      | string         | no       | The database name for which the migration is skipped. Defaults to `main`.        |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/:version/mark"
```

## List pending migrations

Returns a list of all pending (not yet executed) migrations for a specified database.

```plaintext
GET /api/v4/admin/migrations/pending
```

| Attribute       | Type           | Required | Description                                                                      |
|-----------------|----------------|----------|-----------------------------------------------------------------------------------|
| `database`      | string         | no       | The database name to query. Defaults to `main`.                                  |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/admin/migrations/pending?database=main"
```

Example response:

```json
{
  "pending_migrations": [
    {
      "version": 20240101120000,
      "name": "create_users_table",
      "filename": "20240101120000_create_users_table.rb",
      "status": "pending"
    },
    {
      "version": 20240102150000,
      "name": "add_email_to_users",
      "filename": "20240102150000_add_email_to_users.rb",
      "status": "pending"
    }
  ],
  "database": "main",
  "total_pending": 2
}
```
