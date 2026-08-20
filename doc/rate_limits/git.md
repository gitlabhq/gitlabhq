---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configure rate limits on Git HTTP, Git LFS, and Git SSH operations.
title: Rate limits on Git operations
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Common Git operations, like clones, fetches, and pushes, can generate many requests in a short time.
Rate limits on Git HTTP, Git LFS, and Git SSH operations protect the security and durability of your
GitLab instance.
Each of these limits works differently with the
[general user and IP rate limits](../administration/settings/user_and_ip_rate_limits.md).
Each section explains how.

## Git HTTP

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112) in GitLab 17.0.

{{< /history >}}

If you use Git HTTP in your repository, common Git operations can generate many Git HTTP requests.
GitLab can enforce rate limits on both authenticated and unauthenticated Git HTTP requests to improve
the security and durability of your web application.

> [!note]
> [General user and IP rate limits](../administration/settings/user_and_ip_rate_limits.md) aren't
> applied to Git HTTP requests.

### Git HTTP on GitLab.com

On GitLab.com, Git HTTP requests are subject to
[Git HTTPS request rate limits](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom).

### Configure unauthenticated Git HTTP rate limits

GitLab disables rate limits on unauthenticated Git HTTP requests by default.

Prerequisites:

- You must have administrator access.

To apply rate limits to Git HTTP requests that do not contain authentication
parameters, enable and configure these limits:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Git HTTP rate limits**.
1. Select **Enable unauthenticated Git HTTP request rate limit**.
1. Enter a value for **Max unauthenticated Git HTTP requests per period per user**.
1. Enter a value for **Unauthenticated Git HTTP rate limit period in seconds**.
1. Select **Save changes**.

### Configure authenticated Git HTTP rate limits

{{< history >}}

- Authenticated Git HTTP rate limits [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552) in GitLab 18.1 [with a feature flag](../administration/feature_flags/_index.md) named `git_authenticated_http_limit`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/543768) in GitLab 18.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/561577) in GitLab 18.4. Feature flag `git_authenticated_http_limit` removed.

{{< /history >}}

GitLab disables rate limits on authenticated Git HTTP requests by default.

Prerequisites:

- You must have administrator access.

To apply rate limits to Git HTTP requests that contain authentication
parameters, enable and configure these limits:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Git HTTP rate limits**.
1. Select **Enable authenticated Git HTTP request rate limit**.
1. Enter a value for **Max authenticated Git HTTP requests per period per user**.
1. Enter a value for **Authenticated Git HTTP rate limit period in seconds**.
1. Select **Save changes**.

If required, you can
[allow specific users to bypass authenticated request rate limiting](../administration/settings/user_and_ip_rate_limits.md#allow-specific-users-to-bypass-authenticated-request-rate-limiting).

## Git LFS

[Git Large File Storage (LFS)](../topics/git/lfs/_index.md) is a Git extension for handling large
files.
Repositories that use Git LFS can generate a large number of LFS requests.
You can enforce
[general user and IP rate limits](../administration/settings/user_and_ip_rate_limits.md), but you can
also override the general setting to enforce additional limits on Git LFS requests. This
override can improve the security and durability of your web application.

### Git LFS on GitLab.com

On GitLab.com, Git LFS requests are subject to
[authenticated web request rate limits](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom).
These limits are set to 1000 requests per minute per user.

Each Git LFS object uploaded or downloaded generates an HTTP request that counts toward
this limit.

> [!note]
> Projects with multiple large files may encounter an HTTP rate limit error.
> This error occurs during cloning or pulling, when performed from a single IP address in automated
> environments like CI/CD pipelines.

### Configure Git LFS rate limits

Git LFS rate limits are disabled by default on GitLab Self-Managed instances.
Administrators can configure dedicated rate limits specifically
for Git LFS traffic. When enabled, these dedicated LFS rate limits override the default
[user and IP rate limits](../administration/settings/user_and_ip_rate_limits.md).

Prerequisites:

- You must be an administrator for the instance.

To configure Git LFS rate limits:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Git LFS Rate Limits**.
1. Select **Enable authenticated Git LFS request rate limit**.
1. Enter a value for **Max authenticated Git LFS requests per period per user**.
1. Enter a value for **Authenticated Git LFS rate limit period in seconds**.
1. Select **Save changes**.

## Git SSH operations

GitLab applies rate limits to Git operations that use SSH by user account and project. When a user
exceeds the rate limit, GitLab rejects further connection requests from that user for the project.

The rate limit applies at the Git command ([plumbing](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)) level.
By default, each command has a rate limit of 600 per minute. For example:

- `git push` has a rate limit of 600 per minute.
- `git pull` has its own rate limit of 600 per minute.

The `git-upload-pack`, `git pull`, and `git clone` commands share a rate limit because they share commands.

> [!note]
> [General user and IP rate limits](../administration/settings/user_and_ip_rate_limits.md) are not
> applied to Git SSH operations. SSH traffic reaches GitLab through the internal API, so it counts
> only against this limit.

### Git SSH operations on GitLab.com

On GitLab.com, Git SSH operations use the default rate limit of 600 operations each minute.
You cannot change this limit.

### Configure the GitLab Shell operation limit

`Git operations using SSH` is enabled by default. Defaults to 600 per user per minute.

Prerequisites:

- Administrator access.

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Git SSH operations rate limit**.
1. Enter a value for **Maximum number of Git operations per minute**.
   - To disable the rate limit, set it to `0`.
1. Select **Save changes**.

## Related topics

- [Rate limits](_index.md)
- [User and IP rate limits](../administration/settings/user_and_ip_rate_limits.md)
- [Non-configurable rate limits](non_configurable.md)
