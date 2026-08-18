---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiq background jobs
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Configure Sidekiq job size limits and the time zone used to evaluate cron job schedules.

Prerequisites:

- Administrator access.

To access these settings:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Preferences**.
1. Expand **Sidekiq Background Jobs**.

## Job size limits

[Sidekiq](../sidekiq/_index.md) stores jobs in
Redis. To avoid excessive Redis memory usage, GitLab:

- Compresses job arguments before storing them in Redis.
- Rejects jobs that exceed the specified threshold limit after compression.

To adjust the compression threshold or size limit, update the values.
To disable compression, select the **Track** mode.

### Available settings

| Setting                                   | Default          | Description                                                                                                                                                                   |
|-------------------------------------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Limiting mode                             | Compress         | This mode compresses the jobs at the specified threshold and rejects them if they exceed the specified limit after compression.                                               |
| Sidekiq job compression threshold (bytes) | 100 000 (100 KB) | When the size of arguments exceeds this threshold, they are compressed before being stored in Redis.                                                                          |
| Sidekiq job size limit (bytes)            | 0                | The jobs exceeding this size after compression are rejected. This avoids excessive memory usage in Redis leading to instability. Setting it to 0 prevents rejecting jobs.     |

After you change these values, [restart Sidekiq](../restart_gitlab.md).

## Cron jobs time zone

By default, GitLab evaluates cron job schedules in the instance time zone, which is UTC
unless configured otherwise. To run cron jobs in a different time zone, set a time zone
override.

To set the time zone:

1. From the **Cron jobs time zone** dropdown list, select a time zone, or select
   **System default** to use the instance time zone.

After you change this value, [restart Sidekiq](../restart_gitlab.md).
