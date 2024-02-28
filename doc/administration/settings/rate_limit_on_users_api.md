---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Rate limits on Users API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78364) in GitLab 14.8.

You can configure the per user rate limit for requests to [Users API](../../api/users.md).

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **Users API rate limit**.
1. In the **Maximum requests per 10 minutes** text box, enter the new value.
1. Optional. In the **Users to exclude from the rate limit** box, list users allowed to exceed the limit.
1. Select **Save changes**.

This limit is:

- Applied independently per user.
- Not applied per IP address.

The default value is `300`.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 300, requests to the `GET /users/:id` API endpoint
exceeding a rate of 300 per 10 minutes are blocked. Access to the endpoint is allowed after ten minutes have elapsed.
