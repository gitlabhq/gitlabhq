---
stage: GitLab Dedicated
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Import and export rate limits
description: "Configure rate limit settings for your GitLab instance when importing or exporting projects or groups."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can configure the rate limits for file imports and exports of projects and groups, and for relations
exports used by [direct transfer](../../user/group/import/_index.md). For information on the default
rate limits, see [import and export rate limits](../instance_limits.md#import-and-export) and
[direct transfer limits](../instance_limits.md#direct-transfer-migration).

When a user exceeds a rate limit, it is logged in `auth.log`.

## Change an import or export rate limit

Prerequisites:

- Administrator access.

To change a rate limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Import and export rate limits**.
1. Change the value of any rate limit. The rate limits are per minute per user, not per IP address.
   The relations export rate limits are also per project or group.
   Set to `0` to disable a rate limit.
