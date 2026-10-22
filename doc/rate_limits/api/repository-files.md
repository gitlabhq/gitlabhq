---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configure rate limits for the repository files API.
title: Repository files API rate limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The [Repository files API](../../api/repository_files.md) enables you to
fetch, create, update, and delete files in your repository. To improve the security
and durability of your web application, you can enforce
[rate limits](../_index.md) on this API. Any rate limits you
create for the Files API override the [general user and IP rate limits](../../administration/settings/user_and_ip_rate_limits.md).

## Define Files API rate limits

Rate limits for the Files API are disabled by default. When enabled, they supersede
the general user and IP rate limits for requests to the
[Repository files API](../../api/repository_files.md). You can keep any general user
and IP rate limits already in place, and increase or decrease the rate limits
for the Files API. No other new features are provided by this override.

Prerequisites:

- You must have administrator access to the instance.

To override the general user and IP rate limits for requests to the Repository files API:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
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

## Configure file blame rate limits

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/261912) in GitLab 19.6.

{{< /history >}}

The [file blame endpoint](../../api/repository_files.md#retrieve-file-blame-history-from-a-repository)
and the GraphQL `blame` field on `RepositoryBlob` share these rate limits. For GraphQL, each blob in a query counts as one request.
These limits apply in addition to the Files API rate limits, and are enabled by default.

| Request type    | Default limit             | Applies to            | Application setting |
|-----------------|---------------------------|-----------------------|---------------------|
| Authenticated   | 400 requests every minute | Each user and project | `project_repositories_blame_limit` |
| Unauthenticated | 400 requests every minute | Each IP address       | `project_repositories_blame_unauthenticated_limit` |

To change a limit, use the [application settings API](../../api/settings.md#available-settings).
Set a limit to `0` to disable it.

## Related topics

- [Rate limits](../_index.md)
- [Repository files API](../../api/repository_files.md)
- [User and IP rate limits](../../administration/settings/user_and_ip_rate_limits.md)
