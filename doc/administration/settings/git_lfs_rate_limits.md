---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure rate limits for Git LFS on GitLab Self-Managed."
title: Rate limits on Git LFS
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

[Git LFS (Large File Storage)](../../topics/git/lfs/_index.md) is a Git extension
for handling large files. If you use Git LFS in your repository, common Git operations
can generate many Git LFS requests. You can enforce
[general user and IP rate limits](../settings/user_and_ip_rate_limits.md), but you can also
override the general setting to enforce additional limits on Git LFS requests. This
override can improve the security and durability of your web application. Aside from
precedence, this configuration provides the same features as the general user and IP
rate limits.

## Configure Git LFS rate limits

Git LFS rate limits are disabled by default. If enabled and configured, these limits
supersede the [general user and IP rate limits](../settings/user_and_ip_rate_limits.md):

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Git LFS Rate Limits**.
1. Select **Enable authenticated Git LFS request rate limit**.
1. Enter a value for **Max authenticated Git LFS requests per period per user**.
1. Enter a value for **Authenticated Git LFS rate limit period in seconds**.
1. Select **Save changes**.

## Related topics

- [Rate limiting](../../security/rate_limits.md)
- [User and IP rate limits](../settings/user_and_ip_rate_limits.md)
