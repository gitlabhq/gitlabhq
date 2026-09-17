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

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248055) in GitLab 19.4 for the instance audit events API.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253781) in GitLab 19.5 for the project audit events API.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255336) in GitLab 19.5 for the group audit events API.

{{< /history >}}

You can configure rate limits for requests to three APIs:

- The [instance audit events API](../../api/audit_events.md#instance-audit-events). The rate limit
  is per minute per user. The default is 200.
- The [group audit events API](../../api/audit_events.md#group-audit-events). The rate limit is
  per minute per user per group. The default is 200.
- The [project audit events API](../../api/audit_events.md#project-audit-events). The rate limit is
  per minute per user per project. The default is 200.

Requests over any of these rate limits return a `429 Too Many Requests` status code and are logged into
the `auth.log` file.

- The instance audit events API rate limit applies to both `GET /audit_events` and
  `GET /audit_events/:id`.
- The group audit events API rate limit applies to both `GET /groups/:id/audit_events` and
  `GET /groups/:id/audit_events/:audit_event_id`.
- The project audit events API rate limit applies to both `GET /projects/:id/audit_events` and
  `GET /projects/:id/audit_events/:audit_event_id`.

For example, if you set a limit of 200, requests to these endpoints that exceed a rate of 200
within one minute are blocked. Access is restored after one minute.

## Change the rate limits

Prerequisites:

- Administrator access.

To change a rate limit:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Network**.
1. Expand **Audit events API rate limits**.
1. Change the value of the rate limit you want to update.
   To disable a rate limit, set the value to `0`.
1. Select **Save changes**.
