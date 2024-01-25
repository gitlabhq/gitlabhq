---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Rate limit on Projects API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112283) in GitLab 15.10 with a [flag](../feature_flags.md) named `rate_limit_for_unauthenticated_projects_api_access`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/391922) on May 08, 2023.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119603) in GitLab 16.0 by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120445) in GitLab 16.0. Feature flag `rate_limit_for_unauthenticated_projects_api_access` removed.

You can configure the rate limit per IP address for unauthenticated requests to the [list all projects API](../../api/projects.md#list-all-projects).

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **Projects API rate limit**.
1. In the **Maximum requests per 10 minutes per IP address** text box, enter the new value.
1. Select **Save changes**.

The rate limit:

- Applies per IP address.
- Doesn't apply to authenticated requests.
- Can be set to 0 to disable rate limiting.

The default value of the rate limit is `400`.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 400, unauthenticated requests to the `GET /projects` API endpoint that
exceed a rate of 400 within 10 minutes are blocked. Access to the endpoint is restored after ten minutes have elapsed.
