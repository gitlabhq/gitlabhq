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
GitLab can enforce rate limits on both authenticated and unauthenticated Git HTTP requests to improve
the security and durability of your web application.

{{< alert type="note" >}}

[General user and IP rate limits](user_and_ip_rate_limits.md) aren't applied to Git HTTP requests.

{{< /alert >}}

## Configure unauthenticated Git HTTP rate limits

GitLab disables rate limits on unauthenticated Git HTTP requests by default.

To apply rate limits to Git HTTP requests that do not contain authentication
parameters, enable and configure these limits:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Git HTTP rate limits**.
1. Select **Enable unauthenticated Git HTTP request rate limit**.
1. Enter a value for **Max unauthenticated Git HTTP requests per period per user**.
1. Enter a value for **Unauthenticated Git HTTP rate limit period in seconds**.
1. Select **Save changes**.

## Configure authenticated Git HTTP rate limits

{{< history >}}

- Authenticated Git HTTP rate limits [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552) in GitLab 18.1 [with a flag](../../administration/feature_flags/_index.md) named `git_authenticated_http_limit`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab disables rate limits on authenticated Git HTTP requests by default.

To apply rate limits to Git HTTP requests that contain authentication
parameters, enable and configure these limits:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Git HTTP rate limits**.
1. Select **Enable authenticated Git HTTP request rate limit**.
1. Enter a value for **Max authenticated Git HTTP requests per period per user**.
1. Enter a value for **Authenticated Git HTTP rate limit period in seconds**.
1. Select **Save changes**.

## Related topics

- [Rate limiting](../../security/rate_limits.md)
- [User and IP rate limits](user_and_ip_rate_limits.md)
