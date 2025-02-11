---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Manage incidents
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Ability to add an [incident](_index.md) to an iteration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347153) in GitLab 17.0.

This page collects instructions for all the things you can do with [incidents](incidents.md) or in relation to them.

## Create an incident

You can create an incident manually or automatically.

## Add an incident to an iteration

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To add an incident to an [iteration](../../user/group/iterations/_index.md):

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues** or **Monitor > Incidents**, then select your incident to view it.
1. On the right sidebar, in the **Iteration** section, select **Edit**.
1. From the dropdown list, select the iteration to add this incident to.
1. Select any area outside the dropdown list.

Alternatively, you can use the `/iteration` [quick action](../../user/project/quick_actions.md#issues-merge-requests-and-epics).

### From the Incidents page

Prerequisites:

- You must have at least the Reporter role for the project.

To create an incident from the **Incidents** page:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Monitor > Incidents**.
1. Select **Create incident**.

### From the Issues page

Prerequisites:

- You must have at least the Reporter role for the project.

To create an incident from the **Issues** page:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues**, and select **New issue**.
1. From the **Type** dropdown list, select **Incident**. Only fields relevant to
   incidents are available on the page.
1. Select **Create issue**.

### From an alert

Create an incident issue when viewing an [alert](alerts.md).
The incident description is populated from the alert.

Prerequisites:

- You must have at least the Developer role for the project.

To create an incident from an alert:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Monitor > Alerts**.
1. Select your desired alert.
1. Select **Create incident**.

After an incident is created, to view it from the alert, select **View incident**.

When you [close an incident](#close-an-incident) linked to an alert, GitLab
[changes the alert's status](alerts.md#change-an-alerts-status) to **Resolved**.
You are then credited with the alert's status change.

### Automatically, when an alert is triggered

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

In the project settings, you can turn on [creating an incident automatically](alerts.md#trigger-actions-from-alerts)
whenever an alert is triggered.

### Using the PagerDuty webhook

> - [PagerDuty V3 Webhook](https://support.pagerduty.com/docs/webhooks) support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383029) in GitLab 15.7.

You can set up a webhook with PagerDuty to automatically create a GitLab incident
for each PagerDuty incident. This configuration requires you to make changes
in both PagerDuty and GitLab.

Prerequisites:

- You must have at least the Maintainer role for the project.

To set up a webhook with PagerDuty:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Monitor**
1. Expand **Incidents**.
1. Select the **PagerDuty integration** tab.
1. Turn on the **Active** toggle.
1. Select **Save integration**.
1. Copy the value of **Webhook URL** for use in a later step.
1. To add the webhook URL to a PagerDuty webhook integration, follow the steps described in the [PagerDuty documentation](https://support.pagerduty.com/docs/webhooks#manage-v3-webhook-subscriptions).

To confirm the integration is successful, trigger a test incident from PagerDuty to
check if a GitLab incident is created from the incident.

## View a list of incidents

To view a list of the [incidents](incidents.md#incidents-list):

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Monitor > Incidents**.

To view an incident's [details page](incidents.md#incident-details), select it from the list.

### Who can view an incident

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) the minimum user role from Reporter to Planner in GitLab 17.7.

Whether you can view an incident depends on the [project visibility level](../../user/public_access.md) and
the incident's confidentiality status:

- Public project and a non-confidential incident: Anyone can view the incident.
- Private project and non-confidential incident: You must have at least the Guest role for the project.
- Confidential incident (regardless of project visibility): You must have at least the Planner role for the project.

## Assign to a user

Assign incidents to users that are actively responding.

Prerequisites:

- You must have at least the Reporter role for the project.

To assign a user:

1. In an incident, on the right sidebar, next to **Assignees**, select **Edit**.
1. From the dropdown list, select one or [multiple users](../../user/project/issues/multiple_assignees_for_issues.md) to add as **assignees**.
1. Select any area outside the dropdown list.

## Change severity

See the [incidents list](incidents.md#incidents-list) topic for a full description of the severity levels available.

Prerequisites:

- You must have at least the Reporter role for the project.

To change an incident's severity:

1. In an incident, on the right sidebar, next to **Severity**, select **Edit**.
1. From the dropdown list, select the new severity.

You can also change the severity using the `/severity` [quick action](../../user/project/quick_actions.md).

## Change status

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5716) in GitLab 14.9 [with a flag](../../administration/feature_flags.md) named `incident_escalations`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) in GitLab 14.10.
> - [Feature flag `incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) removed in GitLab 15.1.

Prerequisites:

- You must have at least the Developer role for the project.

To change the status of an incident:

1. In an incident, on the right sidebar, next to **Status**, select **Edit**.
1. From the dropdown list, select the new severity.

**Triggered** is the default status for new incidents.

### As an on-call responder

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

On-call responders can respond to [incident pages](paging.md#escalating-an-incident)
by changing the status.

Changing the status has the following effects:

- To **Acknowledged**: limits on-call pages based on the project's [escalation policy](escalation_policies.md).
- To **Resolved**: silences all on-call pages for the incident.
- From **Resolved** to **Triggered**: restarts the incident escalating.

In GitLab 15.1 and earlier, changing the status of an [incident created from an alert](#from-an-alert)
also changes the alert status. In [GitLab 15.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/356057),
the alert status is independent and does not change when the incident status changes.

## Change escalation policy

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Prerequisites:

- You must have at least the Developer role for the project.

To change the escalation policy of an incident:

1. In an incident, on the right sidebar, next to **Escalation policy**, select **Edit**.
1. From the dropdown list, select the escalation policy.

By default, new incidents do not have an escalation policy selected.

Selecting an escalation policy [changes the incident status](#change-status) to **Triggered** and begins
[escalating the incident to on-call responders](paging.md#escalating-an-incident).

In GitLab 15.1 and earlier, the escalation policy for [incidents created from alerts](#from-an-alert)
reflects the alert's escalation policy and cannot be changed. In [GitLab 15.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/356057),
the incident escalation policy is independent and can be changed.

## Close an incident

Prerequisites:

- You must have at least the Reporter role for the project.

To close an incident, in the upper-right corner, select **Incident actions** (**{ellipsis_v}**) and then **Close incident**.

When you close an incident that is linked to an [alert](alerts.md),
the linked alert's status changes to **Resolved**.
You are then credited with the alert's status change.

### Automatically close incidents via recovery alerts

Turn on closing an incident automatically when GitLab receives a recovery alert
from a HTTP or Prometheus webhook.

Prerequisites:

- You must have at least the Maintainer role for the project.

To configure the setting:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Monitor**.
1. Expand the **Incidents** section.
1. Select the **Automatically close associated incident** checkbox.
1. Select **Save changes**.

When GitLab receives a [recovery alert](integrations.md#recovery-alerts), it closes the associated incident.
This action is recorded as a system note on the incident indicating that it
was closed automatically by the GitLab Alert bot.

## Delete an incident

Prerequisites:

- You must have the Owner role for a project.

To delete an incident:

1. In an incident, select **Incident actions** (**{ellipsis_v}**).
1. Select **Delete incident**.

Alternatively:

1. In an incident, select **Edit title and description** (**{pencil}**).
1. Select **Delete incident**.

## Other actions

Because incidents in GitLab are built on top of [issues](../../user/project/issues/_index.md),
they have the following actions in common:

- [Add a to-do item](../../user/todos.md#create-a-to-do-item)
- [Add labels](../../user/project/labels.md#assign-and-unassign-labels)
- [Assign a milestone](../../user/project/milestones/_index.md#assign-a-milestone-to-an-issue-or-merge-request)
- [Make an incident confidential](../../user/project/issues/confidential_issues.md)
- [Set a due date](../../user/project/issues/due_dates.md)
- [Toggle notifications](../../user/profile/notifications.md#edit-notification-settings-for-issues-merge-requests-and-epics)
- [Track time spent](../../user/project/time_tracking.md)
