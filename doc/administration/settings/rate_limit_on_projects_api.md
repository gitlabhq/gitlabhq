---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limit on Projects API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112283) in GitLab 15.10 with a [flag](../feature_flags.md) named `rate_limit_for_unauthenticated_projects_api_access`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/391922) on May 08, 2023.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119603) in GitLab 16.0 by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120445) in GitLab 16.0. Feature flag `rate_limit_for_unauthenticated_projects_api_access` removed.
> - Rate limit for group and projects API [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152733) in GitLab 17.1. with a [flag](../feature_flags.md) named `rate_limit_groups_and_projects_api`. Disabled by default.

You can configure the rate limit per IP address and per user for requests to the following [projects API](../../api/projects.md#list-all-projects).

| Limit                                                                                                     | Default | Interval   |
|-----------------------------------------------------------------------------------------------------------|---------|------------|
| [GET /projects](../../api/projects.md#list-all-projects) (unauthenticated requests)                       | 400     | 10 minutes |
| [GET /projects](../../api/projects.md#list-all-projects) (authenticated requests)                         | 2000    | 10 minutes |
| [GET /projects/:id](../../api/projects.md#get-a-single-project)                                             | 400     | 1 minute   |
| [GET /users/:user_id/projects](../../api/projects.md#list-a-users-projects)                               | 300     | 1 minute   |
| [GET /users/:user_id/contributed_projects](../../api/projects.md#list-projects-a-user-has-contributed-to) | 100     | 1 minute   |
| [GET /users/:user_id/starred_projects](../../api/project_starring.md#list-projects-starred-by-a-user)             | 100     | 1 minute   |

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Projects API rate limits**.
1. Change the value of any rate limit. The rate limits are per minute per user for authenticated requests and per IP address unauthenticated requests.
   Set to `0` to disable a rate limit.
1. Select **Save changes**.

The rate limits:

- Apply per user if the user is authenticated.
- Apply per IP address if the user is unauthenticated.
- Can be set to 0 to disable rate limiting.
- Are behind the `rate_limit_groups_and_projects_api` except for the unauthenticated requests to the `GET /projects` API.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 400 for `GET /projects/:id`, requests to the API endpoint that
exceed a rate of 400 within 1 minutes are blocked. Access to the endpoint is restored after one minutes have elapsed.
