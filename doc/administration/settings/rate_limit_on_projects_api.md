---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limits on Projects API
description: Set rate limits on Projects API endpoints.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Configure Projects API rate limits

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120445) in GitLab 16.0. Feature flag `rate_limit_for_unauthenticated_projects_api_access` removed.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421909) rate limit for the group and projects API in GitLab 17.1 with a [flag](../feature_flags/_index.md) named `rate_limit_groups_and_projects_api`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/461316) in GitLab 18.1. Feature flag `rate_limit_groups_and_projects_api` removed.

{{< /history >}}

Configure the rate limit for each IP address and user for requests to the following Projects API endpoints:

| Limit                                                                                                       | Default | Interval |
|-------------------------------------------------------------------------------------------------------------|---------|----------|
| [`GET /projects`](../../api/projects.md#list-all-projects) (unauthenticated requests)                       | 400     | 10 minutes |
| [`GET /projects`](../../api/projects.md#list-all-projects) (authenticated requests)                         | 2000    | 10 minutes |
| [`GET /projects/:id`](../../api/projects.md#get-a-single-project)                                           | 400     | 1 minute |
| [`GET /users/:user_id/projects`](../../api/projects.md#list-a-users-projects)                               | 300     | 1 minute |
| [`GET /users/:user_id/contributed_projects`](../../api/projects.md#list-projects-a-user-has-contributed-to) | 100     | 1 minute |
| [`GET /users/:user_id/starred_projects`](../../api/project_starring.md#list-projects-starred-by-a-user)     | 100     | 1 minute |

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md), in the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Projects API rate limits**.
1. Change the value of a rate limit, or set a rate limit to `0` to disable it.
1. Select **Save changes**.

The rate limits:

- Apply to each authenticated user. If requests are not authenticated, rate limits apply to the IP address.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 400 for `GET /projects/:id`, requests to the API endpoint that
exceed a rate of 400 requests per minute are blocked. Access to the endpoint is restored after one minute.

For more information about project API endpoints, see the [projects API](../../api/projects.md#list-all-projects).

## Configure rate limits on deleting project members

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420321) in GitLab 16.9.

{{< /history >}}

Configure the rate limit for each project and user for requests to the
[delete members endpoint](../../api/project_members.md#remove-a-member-from-a-project).

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md), in the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Members API rate limit**.
1. In the **Maximum requests per minute per group / project** text box, enter a value.
1. Select **Save changes**.

The rate limit:

- Defaults to 60 requests every minute
- Applies for each project and user.
- Can be set to 0 to disable the rate limit.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 60, requests to the API endpoint that exceed
a rate of 60 requests per minute are blocked. Access to the endpoint resumes
after one minute.

## Configure rate limits on listing project members

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/578527) in GitLab 18.6.

{{< /history >}}

Configure the rate limit for requests to the
[list project members endpoint](../../api/project_members.md#list-all-members-of-a-project).

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md), in the upper-right corner, select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Projects API**.
1. In the **Maximum requests to the GET /projects/:id/members/all API per minute per user or IP address** text box, enter a value.
1. Select **Save changes**.

The rate limit:

- Defaults to 200 requests every minute.
- Applies to each project and user.
- Can be set to 0 to disable rate limits.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 200, requests to the API endpoint that
exceed a rate of 200 requests per minute
are blocked. Access to the endpoint resumes after one minute.
