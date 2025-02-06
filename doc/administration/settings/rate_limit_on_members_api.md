---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limit on Members API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140633) in GitLab 16.9.

You can configure the rate limit per group (or project) per user to the
[delete members API](../../api/members.md#remove-a-member-from-a-group-or-project).

To change the rate limit:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Members API rate limit**.
1. In the **Maximum requests per minute per group / project** text box, enter the new value.
1. Select **Save changes**.

The rate limit:

- Applies per group or project per user.
- Can be set to 0 to disable rate limiting.

The default value of the rate limit is `60`.

Requests over the rate limit are logged into the `auth.log` file.

For example, if you set a limit of 60, requests sent to the
[delete members API](../../api/members.md#remove-a-member-from-a-group-or-project) exceeding a rate of 300 per minute
are blocked. Access to the endpoint is allowed after one minute.
