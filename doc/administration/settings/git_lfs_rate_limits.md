---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure rate limits for Git LFS on GitLab.
title: Rate limits on Git LFS
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

[Git LFS (Large File Storage)](../../topics/git/lfs/_index.md) is a Git extension
for handling large files. If you use Git LFS in your repository, common Git operations
can generate many Git LFS requests. You can enforce
[general user and IP rate limits](user_and_ip_rate_limits.md), but you can also
override the general setting to enforce additional limits on Git LFS requests. This
override can improve the security and durability of your web application.

## On GitLab.com

On GitLab.com, Git LFS requests are subject to
[authenticated web request rate limits](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom).
These limits are set to 1000 requests per minute per user.

Each Git LFS object uploaded or downloaded generates an HTTP request that counts toward
this limit.

{{< alert type="note" >}}

Projects with multiple large files may encounter an HTTP rate limit error.
This error occurs during cloning or pulling, when performed from a single IP address in automated
environments like CI/CD pipelines.

{{< /alert >}}

## On GitLab Self-Managed

Git LFS rate limits are disabled by default on GitLab Self-Managed instances.
Administrators can configure dedicated rate limits specifically
for Git LFS traffic. When enabled, these dedicated LFS rate limits override the default
[user and IP rate limits](user_and_ip_rate_limits.md).

### Configure Git LFS rate limits

Prerequisites:

- You must be an administrator for the instance.

To configure Git LFS rate limits:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Git LFS Rate Limits**.
1. Select **Enable authenticated Git LFS request rate limit**.
1. Enter a value for **Max authenticated Git LFS requests per period per user**.
1. Enter a value for **Authenticated Git LFS rate limit period in seconds**.
1. Select **Save changes**.

## Related topics

- [Rate limiting](../../security/rate_limits.md)
- [User and IP rate limits](user_and_ip_rate_limits.md)
