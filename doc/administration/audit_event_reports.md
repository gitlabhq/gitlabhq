---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Audit event reports

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

A security audit is an in-depth analysis and review of your infrastructure, which is used to display
areas of concern and potentially hazardous practices. To assist with the audit process, GitLab provides
audit events which allow you to track a variety of different actions within GitLab.
GitLab can help owners and administrators respond to auditors by generating
comprehensive reports. These audit reports vary in scope, depending on the
needs.

For example, you can use audit events to track:

- Who changed the permission level of a particular user for a GitLab project, and when.
- Who added a new user or removed a user, and when.

These events can be used to in an audit to assess risk, strengthen security measures, respond to incidents, and adhere to compliance. For a complete list the audit
events GitLab provides, see [Audit event types](../administration/audit_event_types.md). For example:

- Generate a report of audit events to provide to an external auditor requesting proof of certain logging capabilities.
- Provide a report of all users showing their group and project memberships for a quarterly access review so the auditor can verify compliance with an organization's access management policy.

Audit events are retained indefinitely. Because there is no retention timeframe, all audit events are available.

## Prerequisites

To view specific types of audit events, you need a minimum role.

- To view the group audit events of all users in a group, you must have the [Owner role](../user/permissions.md#roles) for the group.
- To view the project audit events of all users in a project, you must have at least the [Maintainer role](../user/permissions.md#roles) for the project.
- To view the group and project audit events based on your own actions in a group or project, you must have at least the [Developer role](../user/permissions.md#roles)
  for the group or project.

Users with the [Auditor access level](auditor_users.md) can see group and project events for all users.

## Viewing audit events

Audit events can be viewed at the group, project, instance, and sign-in level. Each level has different audit events which it logs.

### Group audit events

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

To view a group's audit events:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. Filter the audit events by the member of the project (user) who performed the action and date range.

Group audit events can also be accessed using the [Group Audit Events API](../api/audit_events.md#group-audit-events). Group audit event queries `created_after` and `created_before` parameters are limited to a maximum 30 day difference between the dates.

### Project audit events

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Audit events**.
1. Filter the audit events by the member of the project (user) who performed the action and date range.

Project audit events can also be accessed using the [Project Audit Events API](../api/audit_events.md#project-audit-events). Project audit event queries `created_after` and `created_before` parameters are limited to a maximum 30 day difference between the dates.

### Instance audit events

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

You can view audit events from user actions across an entire GitLab instance.
To view instance audit events:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Monitoring > Audit Events**.
1. Filter by the following:
   - Member of the project (user) who performed the action
   - Group
   - Project
   - Date Range

Instance audit events can also be accessed using the [Instance Audit Events API](../api/audit_events.md#instance-audit-events). Instance audit event queries are limited to a maximum of 30 days.

### Sign-in audit events

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Successful sign-in events are the only audit events available at all tiers. To see successful sign-in events:

1. On the left sidebar, select your avatar.
1. Select **Edit profile > Authentication log**.

After upgrading to a paid tier, you can also see successful sign-in events on audit event pages.

## Exporting audit events

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1449) in GitLab 13.4.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/285441) in GitLab 13.7.
> - Entity type `Gitlab::Audit::InstanceScope` for instance audit events [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418185) in GitLab 16.2.

You can export the current view (including filters) of your instance audit events as a
CSV(comma-separated values) file. To export the instance audit events to CSV:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Monitoring > Audit Events**.
1. Select the available search filters.
1. Select **Export as CSV**.

A download confirmation dialog then appears for you to download the CSV file. The exported CSV is limited
to a maximum of 100000 events. The remaining records are truncated when this limit is reached.

### Audit event CSV encoding

The exported CSV file is encoded as follows:

- `,` is used as the column delimiter
- `"` is used to quote fields if necessary.
- `\n` is used to separate rows.

The first row contains the headers, which are listed in the following table along
with a description of the values:

| Column                | Description                                                                        |
| --------------------- | ---------------------------------------------------------------------------------- |
| **ID**                | Audit event `id`.                                                                  |
| **Author ID**         | ID of the author.                                                                  |
| **Author Name**       | Full name of the author.                                                           |
| **Entity ID**         | ID of the scope.                                                                   |
| **Entity Type**       | Type of the scope (`Project`, `Group`, `User`, or `Gitlab::Audit::InstanceScope`). |
| **Entity Path**       | Path of the scope.                                                                 |
| **Target ID**         | ID of the target.                                                                  |
| **Target Type**       | Type of the target.                                                                |
| **Target Details**    | Details of the target.                                                             |
| **Action**            | Description of the action.                                                         |
| **IP Address**        | IP address of the author who performed the action.                                 |
| **Created At (UTC)**  | Formatted as `YYYY-MM-DD HH:MM:SS`.                                                |

All items are sorted by `created_at` in ascending order.

## User impersonation

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/536) in GitLab 13.0.
> - Impersonation session events included in group audit events in GitLab 14.8.

When a user is [impersonated](../administration/admin_area.md#user-impersonation), their actions are logged as audit events with the following additional details:

- Audit events include information about the impersonating administrator.
- Extra audit events are recorded for the start and end of the administrator's impersonation session.

![Audit event with impersonated user](img/impersonated_audit_events_v15_7.png)

## Time zones

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/242014) in GitLab 15.7, GitLab UI shows dates and times in the user's local time zone instead of UTC.

The time zone used for audit events depends on where you view them:

- In GitLab UI, your local time zone (GitLab 15.7 and later) or UTC (GitLab 15.6 and earlier) is used.
- The [Audit Events API](../api/audit_events.md) returns dates and times in UTC by default, or the
  [configured time zone](timezone.md) on a self-managed GitLab instance.
- In CSV exports, UTC is used.

## Contribute to audit events

If you don't see the event you want in any of the epics, you can either:

- Use the **Audit Event Proposal** issue template to
  [create an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Audit%20Event%20Proposal) to request it.
- [Add it yourself](../development/audit_event_guide/index.md).
