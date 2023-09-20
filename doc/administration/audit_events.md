---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Audit events **(PREMIUM ALL)**

Use audit events to track important events, including who performed the related action and when.
You can use audit events to track, for example:

- Who changed the permission level of a particular user for a GitLab project, and when.
- Who added a new user or removed a user, and when.

Audit events are similar to the [log system](logs/index.md).

The GitLab API, database, and `audit_json.log` record many audit events. Some audit events are only available through
[streaming audit events](audit_event_streaming.md).

You can also generate an [audit report](audit_reports.md) of audit events.

NOTE:
You can't configure a retention policy for audit events, but epic
[7917](https://gitlab.com/groups/gitlab-org/-/epics/7917) proposes to change this.

## Time zones

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/242014) in GitLab 15.7, GitLab UI shows dates and times in the user's local time zone instead of UTC.

The time zone used for audit events depends on where you view them:

- In GitLab UI, your local time zone (GitLab 15.7 and later) or UTC (GitLab 15.6 and earlier) is used.
- The [Audit Events API](../api/audit_events.md) returns dates and times in UTC by default, or the
  [configured time zone](timezone.md) on a self-managed GitLab instance.
- In `audit_json.log`, UTC is used.
- In CSV exports, UTC is used.

## View audit events

Depending on the events you want to view, at a minimum you must have:

- For group audit events of all users in the group, the Owner role for the group.
- For project audit events of all users in the project, the Maintainer role for the project.
- For group and project audit events based on your own actions, the Developer role for the group or project.
- [Auditor users](auditor_users.md) can see group and project events for all users.

You can view audit events scoped to a group or project.

To view a group's audit events:

1. Go to the group.
1. On the left sidebar, select **Secure > Audit events**.

Group events do not include project audit events. Group events can also be accessed using the
[Group Audit Events API](../api/audit_events.md#group-audit-events). Group event queries are limited to a maximum of 30
days.

To view a project's audit events:

1. Go to the project.
1. On the left sidebar, select **Secure > Audit events**.

Project events can also be accessed using the [Project Audit Events API](../api/audit_events.md#project-audit-events).
Project event queries are limited to a maximum of 30 days.

## View instance audit events **(PREMIUM SELF)**

You can view audit events from user actions across an entire GitLab instance.

To view instance audit events:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. On the left sidebar, select **Monitoring > Audit Events**.

### Export to CSV

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1449) in GitLab 13.4.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/285441) in GitLab 13.7.
> - Entity type `Gitlab::Audit::InstanceScope` for instance audit events [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418185) in GitLab 16.2.

You can export the current view (including filters) of your instance audit events as a CSV file. To export the instance
audit events to CSV:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. On the left sidebar, select **Monitoring > Audit Events**.
1. Select the available search [filters](#filter-audit-events).
1. Select **Export as CSV**.

The exported file:

- Is sorted by `created_at` in ascending order.
- Is limited to a maximum of 100 000 events. The remaining records are truncated when this limit is reached.

Data is encoded with:

- Comma as the column delimiter.
- `"` to quote fields if necessary.
- New lines separate rows.

The first row contains the headers, which are listed in the following table along with a description of the values:

| Column               | Description                                                        |
|:---------------------|:-------------------------------------------------------------------|
| **ID**               | Audit event `id`.                                                  |
| **Author ID**        | ID of the author.                                                  |
| **Author Name**      | Full name of the author.                                           |
| **Entity ID**        | ID of the scope.                                                   |
| **Entity Type**      | Type of the scope (`Project`, `Group`, `User`, or `Gitlab::Audit::InstanceScope`). |
| **Entity Path**      | Path of the scope.                                                 |
| **Target ID**        | ID of the target.                                                  |
| **Target Type**      | Type of the target.                                                |
| **Target Details**   | Details of the target.                                             |
| **Action**           | Description of the action.                                         |
| **IP Address**       | IP address of the author who performed the action.                 |
| **Created At (UTC)** | Formatted as `YYYY-MM-DD HH:MM:SS`.                                |

## View sign-in events **(FREE ALL)**

Successful sign-in events are the only audit events available at all tiers. To see successful sign-in events:

1. On the left sidebar, select your avatar.
1. Select **Edit profile > Authentication log**.

After upgrading to a paid tier, you can also see successful sign-in events on audit event pages.

## Filter audit events

From audit events pages, different filters are available depending on the page you're on.

| Audit event page | Available filter                                                                                                       |
|:-----------------|:-----------------------------------------------------------------------------------------------------------------------|
| Project          | User (member of the project) who performed the action.                                                                 |
| Group            | User (member of the group) who performed the action.                                                                   |
| Instance         | Group, project, or user.                                                                                               |
| All              | Date range buttons and pickers (maximum range of 31 days). Default is from the first day of the month to today's date. |

## User impersonation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/536) in GitLab 13.0.
> - Impersonation session events included in group audit events in GitLab 14.8.

When a user is [impersonated](../administration/admin_area.md#user-impersonation), their actions are logged as audit events
with additional details:

- Audit events include information about the impersonating administrator. These audit events are visible in audit event
  pages depending on the audit event type (group, project, or user).
- Extra audit events are recorded for the start and end of the administrator's impersonation session. These audit events
  are visible as:
  - Instance audit events.
  - Group audit events for all groups the user belongs to. For performance reasons, group audit events are limited to
    the oldest 20 groups you belong to.

![Audit event with impersonated user](img/impersonated_audit_events_v15_7.png)

## Available audit events

For a list of available audit events, see [Audit event types](../administration/audit_event_streaming/audit_event_types.md).

## Unsupported events

Some events are not tracked in audit events. The following epics and issues propose support for more events:

- [Project settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/474).
- [Group settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/475).
- [Instance-level settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/476).
- [Deployment Approval activity](https://gitlab.com/gitlab-org/gitlab/-/issues/354782).
- [Approval rules processing by a non GitLab user](https://gitlab.com/gitlab-org/gitlab/-/issues/407384).

If you don't see the event you want in any of the epics, you can either:

- Use the **Audit Event Proposal** issue template to
  [create an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Audit%20Event%20Proposal) to
  request it.
- [Add it yourself](../development/audit_event_guide/index.md).
