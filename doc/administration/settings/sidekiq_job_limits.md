---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sidekiq job size limits
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

[Sidekiq](../sidekiq/_index.md) jobs get stored in
Redis. To avoid excessive memory for Redis, we:

- Compress job arguments before storing them in Redis.
- Reject jobs that exceed the specified threshold limit after compression.

To access Sidekiq job size limits:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Preferences**.
1. Expand **Sidekiq job size limits**.
1. Adjust the compression threshold or size limit. The compression can
   be disabled by selecting the **Track** mode.

## Available settings

| Setting                                   | Default          | Description                                                                                                                                                                   |
|-------------------------------------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Limiting mode                             | Compress         | This mode compresses the jobs at the specified threshold and rejects them if they exceed the specified limit after compression.                                               |
| Sidekiq job compression threshold (bytes) | 100 000 (100 KB) | When the size of arguments exceeds this threshold, they are compressed before being stored in Redis.                                                                          |
| Sidekiq job size limit (bytes)            | 0                | The jobs exceeding this size after compression are rejected. This avoids excessive memory usage in Redis leading to instability. Setting it to 0 prevents rejecting jobs.     |

After changing these values, [restart Sidekiq](../restart_gitlab.md).
