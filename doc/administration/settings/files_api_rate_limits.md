---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure rate limits for the repository files API on GitLab Self-Managed."
title: Rate limits on Repository files API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The [Repository files API](../../api/repository_files.md) enables you to
fetch, create, update, and delete files in your repository. To improve the security
and durability of your web application, you can enforce
[rate limits](../../security/rate_limits.md) on this API. Any rate limits you
create for the Files API override the [general user and IP rate limits](user_and_ip_rate_limits.md).

## Define Files API rate limits

Rate limits for the Files API are disabled by default. When enabled, they supersede
the general user and IP rate limits for requests to the
[Repository files API](../../api/repository_files.md). You can keep any general user
and IP rate limits already in place, and increase or decrease the rate limits
for the Files API. No other new features are provided by this override.

Prerequisites:

- You must have administrator access to the instance.

To override the general user and IP rate limits for requests to the Repository files API:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Files API Rate Limits**.
1. Select the checkboxes for the types of rate limits you want to enable:
   - **Unauthenticated API request rate limit**
   - **Authenticated API request rate limit**
1. If you selected **unauthenticated**:
   1. Select the **Max unauthenticated API requests per period per IP**.
   1. Select the **Unauthenticated API rate limit period in seconds**.
1. If you selected **authenticated**:
   1. Select the **Max authenticated API requests per period per user**.
   1. Select the **Authenticated API rate limit period in seconds**.

## Related topics

- [Rate limits](../../security/rate_limits.md)
- [Repository files API](../../api/repository_files.md)
- [User and IP rate limits](user_and_ip_rate_limits.md)
