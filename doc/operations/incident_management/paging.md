---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Paging and notifications
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When there is a new alert or incident, it is important for a responder to be notified
immediately so they can triage and respond to the problem. Responders can receive
notifications using the methods described on this page.

## Slack notifications

The GitLab for Slack app can be used to receive important incident notifications.

When [the GitLab for Slack app is configured](slack.md), incident responders are notified in Slack
every time a new incident is declared. To ensure you don't miss any important incident notifications
on your mobile device, enable notifications for Slack on your phone.

## Email notifications for alerts

Email notifications are available in projects for triggered alerts. Project
members with the **Owner** or **Maintainer** roles have the option to receive
a single email notification for new alerts.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Monitor**.
1. Expand **Alerts**.
1. On the **Alert settings** tab, select the
   **Send a single email notification to Owners and Maintainers for new alerts** checkbox.
1. Select **Save changes**.

[Update the alert's status](alerts.md#change-an-alerts-status) to manage email notifications for an alert.

## Paging

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

In projects that have an [escalation policy](escalation_policies.md) configured, on-call responders
can be automatically paged about critical problems through email.

### Escalating an alert

When an alert is triggered, it begins escalating to the on-call responders immediately.
For each escalation rule in the project's escalation policy, the designated on-call
responders receive one email when the rule fires. You can respond to a page
or stop alert escalations by [updating the alert's status](alerts.md#change-an-alerts-status).

### Escalating an incident

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5716) in GitLab 14.9 [with a flag](../../administration/feature_flags.md) named `incident_escalations`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) in GitLab 14.10.
> - [Feature flag `incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) removed in GitLab 15.1.

For incidents, paging on-call responders is optional for each individual incident.

To begin escalating the incident, [set the incident's escalation policy](manage_incidents.md#change-escalation-policy).

For each escalation rule, the designated on-call responders receive one email when
the rule fires. Respond to a page or stop incident escalations by
[changing the incident's status](manage_incidents.md#change-status) or
changing the incident's escalation policy back to **No escalation policy**.

In GitLab 15.1 and earlier, [incidents created from alerts](manage_incidents.md#from-an-alert)
do not support independent escalation. In [GitLab 15.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/356057),
all incidents can be escalated independently.
