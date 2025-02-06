---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Audit events
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
events GitLab provides, see [Audit event types](audit_event_types.md). For example:

- Generate a report of audit events to provide to an external auditor requesting proof of certain logging capabilities.
- Provide a report of all users showing their group and project memberships for a quarterly access review so the auditor can verify compliance with an organization's access management policy.

Audit events are retained indefinitely. Because there is no retention timeframe, all audit events are available.

## Prerequisites

To view specific types of audit events, you need a minimum role.

- To view the group audit events of all users in a group, you must have the [Owner role](../permissions.md#roles) for the group.
- To view the project audit events of all users in a project, you must have at least the [Maintainer role](../permissions.md#roles) for the project.
- To view the group and project audit events based on your own actions in a group or project, you must have at least the [Developer role](../permissions.md#roles)
  for the group or project.

Users with the [Auditor access level](../../administration/auditor_users.md) can see group and project events for all users.

## Viewing audit events

Audit events can be viewed at the group, project, instance, and sign-in level. Each level has different audit events which it logs.

### Sign-in audit events

Successful sign-in events are the only audit events available at all tiers. To see successful sign-in events:

1. On the left sidebar, select your avatar.
1. Select **Edit profile > Authentication log**.

After upgrading to a paid tier, you can also see successful sign-in events on audit event pages.

### Group audit events

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To view a group's audit events:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Audit events**.
1. Filter the audit events by the member of the project (user) who performed the action and date range.

Group audit events can also be accessed using the [group audit events API](../../api/audit_events.md#group-audit-events). Group audit event queries `created_after` and `created_before` parameters are limited to a maximum 30 day difference between the dates.

### Project audit events

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure > Audit events**.
1. Filter the audit events by the member of the project (user) who performed the action and date range.

Project audit events can also be accessed using the [project audit events API](../../api/audit_events.md#project-audit-events). Project audit event queries `created_after` and `created_before` parameters are limited to a maximum 30 day difference between the dates.

## Time zones

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/242014) in GitLab 15.7, GitLab UI shows dates and times in the user's local time zone instead of UTC.

The time zone used for audit events depends on where you view them:

- In GitLab UI, your local time zone (GitLab 15.7 and later) or UTC (GitLab 15.6 and earlier) is used.
- The [audit events API](../../api/audit_events.md) returns dates and times in UTC by default, or the
  [configured time zone](../../administration/timezone.md) on GitLab Self-Managed.
- In CSV exports, UTC is used.

## Contribute to audit events

If you don't see the event you want in any of the epics, you can either:

- Use the **Audit event proposal** issue template to
  [create an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Audit%20Event%20Proposal) to request it.
- [Add it yourself](../../development/audit_event_guide/_index.md).

## Administer topics

Instance administrators can [administer audit events](../../administration/audit_event_reports.md) from the **Admin** area.
