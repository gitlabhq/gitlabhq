---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure rate limits on Git HTTP requests to GitLab Self-Managed.
title: Rate limits on Git HTTP
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112) in GitLab 17.0.

{{< /history >}}

If you use Git HTTP in your repository, common Git operations can generate many Git HTTP requests.
Some of these Git HTTP requests do not contain authentication parameters, and are considered
unauthenticated requests. Enforcing rate limits on Git HTTP requests can improve the security and
durability of your web application.

{{< alert type="note" >}}

[General user and IP rate limits](user_and_ip_rate_limits.md) aren't applied to Git HTTP requests.

{{< /alert >}}

## Configure Git HTTP rate limits

GitLab disables rate limits on Git HTTP requests by default. If you enable and configure these limits,
GitLab applies them to Git HTTP requests:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Git HTTP rate limits**.
1. Select **Enable unauthenticated Git HTTP request rate limit**.
1. Enter a value for **Max unauthenticated Git HTTP requests per period per user**.
1. Enter a value for **Unauthenticated Git HTTP rate limit period in seconds**.
1. Select **Save changes**.

## Related topics

- [Rate limiting](../../security/rate_limits.md)
- [User and IP rate limits](user_and_ip_rate_limits.md)
