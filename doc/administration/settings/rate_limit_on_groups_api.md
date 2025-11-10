---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limit on Groups API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Rate limit for groups and projects API [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152733) in GitLab 17.1. with a [flag](../feature_flags/_index.md) named `rate_limit_groups_and_projects_api`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/461316) in GitLab 18.1. Feature flag `rate_limit_groups_and_projects_api` removed.

{{< /history >}}

You can configure the per minute rate limit per IP address and per user for requests to the following [groups API](../../api/groups.md).

| Limit                                                           | Default |
|-----------------------------------------------------------------|---------|
| [`GET /groups`](../../api/groups.md#list-groups)                | 200     |
| [`GET /groups/:id`](../../api/groups.md#get-a-single-group)     | 400     |
| [`GET /groups/:id/projects`](../../api/groups.md#list-projects) | 600     |

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Groups API rate limits**.
1. Change the value of any rate limit. The rate limits are per minute per user for authenticated requests and per IP address unauthenticated requests.
   Set to `0` to disable a rate limit.
1. Select **Save changes**.

The rate limits:

- Apply per user if the user is authenticated.
- Apply per IP address if the user is unauthenticated.
- Can be set to 0 to disable rate limiting.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 400 for `GET /groups/:id`, requests to the API endpoint that
exceed a rate of 400 within 1 minutes are blocked. Access to the endpoint is restored after one minutes have elapsed.
