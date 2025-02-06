---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure rate limits on Git SSH operations on GitLab Self-Managed."
title: Rate limits on Git SSH operations
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Available by default](https://gitlab.com/gitlab-org/gitlab/-/issues/367998) in GitLab 15.8. [Feature flag](../feature_flags.md) `rate_limit_gitlab_shell` removed.

GitLab applies rate limits to Git operations that use SSH by user account and project. When the rate limit is exceeded, GitLab rejects
further connection requests from that user for the project.

The rate limit applies at the Git command ([plumbing](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)) level.
Each command has a rate limit of 600 per minute. For example:

- `git push` has a rate limit of 600 per minute.
- `git pull` has its own rate limit of 600 per minute.

Because the same commands are shared by `git-upload-pack`, `git pull`, and `git clone`, they share a rate limit.

## Configure GitLab Shell operation limit

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123761) in GitLab 16.2.

`Git operations using SSH` is enabled by default. Defaults to 600 per user per minute.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Git SSH operations rate limit**.
1. Enter a value for **Maximum number of Git operations per minute**.
   - To disable the rate limit, set it to `0`.
1. Select **Save changes**.
