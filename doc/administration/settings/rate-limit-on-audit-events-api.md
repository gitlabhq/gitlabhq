---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Rate limit on audit events API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/605428) in GitLab 19.4.

{{< /history >}}

You can configure the per minute rate limit per user for requests to the
[instance audit events API](../../api/audit_events.md#instance-audit-events). The default is 200.

Requests over the rate limit are logged into the `auth.log` file.

The limit applies to both `GET /audit_events` and `GET /audit_events/:id`. For example, if you set
a limit of 200, requests to these endpoints that exceed a rate of 200 within one minute are
blocked. Access is restored after one minute.

## Change the rate limit

Prerequisites:

- Administrator access.

To change the rate limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Audit events API rate limits**.
1. Change the value of the rate limit. The rate limit is per minute per user.
   To disable the rate limit, set the value to `0`.
1. Select **Save changes**.
