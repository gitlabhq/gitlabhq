---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limits on Groups API
description: Set rate limits on Groups API endpoints.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Configure Groups API rate limits

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152733) rate limit for groups and projects API in GitLab 17.1 with a [flag](../feature_flags/_index.md) named `rate_limit_groups_and_projects_api`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/461316) in GitLab 18.1. Feature flag `rate_limit_groups_and_projects_api` removed.

{{< /history >}}

Configure the rate limit for each IP address and user for requests to the following Groups API endpoints:

| Limit                                                           | Default | Interval |
|-----------------------------------------------------------------|---------|----------|
| [`GET /groups`](../../api/groups.md#list-groups)                | 200     | 1 minute |
| [`GET /groups/:id`](../../api/groups.md#get-a-single-group)     | 400     | 1 minute |
| [`GET /groups/:id/groups/shared`](../../api/groups.md#list-shared-groups) | 0     | 1 minute |
| [`GET /groups/:id/invited_groups`](../../api/groups.md#list-shared-groups) | 60     | 1 minute |
| [`GET /groups/:id/projects`](../../api/groups.md#list-projects) | 600     | 1 minute |
| [`POST /groups/:id/archive`](../../api/groups.md#archive-a-group) | 60    | 1 minute |

To change the rate limit:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Groups API rate limits**.
1. Change the value of any rate limit, or set a rate limit to `0` to disable it.
1. Select **Save changes**.

The rate limits:

- Apply to each authenticated user. If requests are not authenticated, rate limits apply to the IP address.
- Can be set to 0 to disable rate limiting.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 400 for `GET /groups/:id`, requests to the API endpoint that
exceed a rate of 400 per minute are blocked. Access to the endpoint is restored after one minute.

## Rate limit on listing group members

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/578527) in GitLab 18.6.

{{< /history >}}

A non-configurable rate limit is set on the [list all group members API endpoint](../../api/group_members.md#list-all-members-of-a-group-including-inherited-and-invited-members).

The rate limit:

- Defaults to 200 requests every minute.
- Applies for each group and user.

Requests over the rate limit are logged into the `auth.log` file.

For example, requests to the API endpoint that
exceed a rate of 200 requests per minute
are blocked. Access to the endpoint resumes after one minute.

## Configure rate limits on group archiving and unarchiving

{{< details >}}

- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481969) in GitLab 18.0 [with a flag](../feature_flags/_index.md) named `archive_group`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Configure a rate limit on requests to the following
group archiving endpoints:

```plaintext
POST /groups/:id/archive
POST /groups/:id/unarchive
```

To change the rate limit:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Groups API**.
1. In the **Maximum requests to the POST /groups/:id/archive and POST /groups/:id/unarchive API per minute per user or IP address** text box, enter a value.
1. Select **Save changes**.

The rate limit:

- Defaults to 60 requests every minute
- Apply to each authenticated user. If requests are not authenticated, rate limits apply to the IP address.
- Can be set to 0 to disable rate limits

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 60, requests to the API endpoint that
exceed a rate of 60 requests per minute
are blocked. Access to the endpoint resumes after one minute.

For more information on group archiving endpoints,
see [Archive a group](../../api/groups.md#archive-a-group).

## Configure rate limits on deleting group members

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420321) in GitLab 16.9.

{{< /history >}}

Configure the rate limit for each group and user for requests to the
[delete members endpoint](../../api/group_members.md#remove-a-member-from-a-group).

To change the rate limit:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Members API rate limit**.
1. In the **Maximum requests per minute per group / project** text box, enter a value.
1. Select **Save changes**.

The rate limit:

- Defaults to 60 requests every minute.
- Applies for each group and user.
- Can be set to 0 to disable the rate limit.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 60, requests to the API endpoint that exceed
a rate of 60 requests per a minute are blocked. Access to the endpoint is
restored after one minute.
