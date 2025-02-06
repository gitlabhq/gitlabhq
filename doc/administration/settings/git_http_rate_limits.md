---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure rate limits on Git HTTP requests to GitLab Self-Managed."
title: Rate limits on Git HTTP
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112) in GitLab 17.0.

If you use Git HTTP in your repository,
common Git operations can generate many Git HTTP requests.
Some of these Git HTTP requests do not contain authentication parameter and
are considered unauthenticated. You can enforce rate limits on Git HTTP requests.
This can improve the security and durability of your web application.
[General user and IP rate limits](../settings/user_and_ip_rate_limits.md) aren't applied
to Git HTTP requests.

## Configure Git HTTP rate limits

Git HTTP rate limits are disabled by default. If enabled and configured, these limits
are applied to Git HTTP requests.

To configure Git HTTP rate limits:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Git HTTP rate limits**.
1. Select **Enable unauthenticated Git HTTP request rate limit**.
1. Enter a value for **Max unauthenticated Git HTTP requests per period per user**.
1. Enter a value for **Unauthenticated Git HTTP rate limit period in seconds**.
1. Select **Save changes**.

## Related topics

- [Rate limiting](../../security/rate_limits.md)
- [User and IP rate limits](../settings/user_and_ip_rate_limits.md)
