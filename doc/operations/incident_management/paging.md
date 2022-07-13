---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Paging and notifications **(FREE)**

When there is a new alert or incident, it is important for a responder to be notified
immediately so they can triage and respond to the problem. Responders can receive
notifications using the methods described on this page.

## Slack notifications

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216326) in GitLab 13.1.

Responders can be paged via Slack using the
[Slack Notifications Service](../../user/project/integrations/slack.md), which you
can configure for new alerts and new incidents. After configuring, responders
receive a **single** page via Slack. To set up Slack notifications on your mobile
device, make sure to enable notifications for the Slack app on your phone so
you never miss a page.

## Email notifications for alerts

Email notifications are available in projects for triggered alerts. Project
members with the **Owner** or **Maintainer** roles have the option to receive
a single email notification for new alerts.

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Monitor**.
1. Expand **Alerts**.
1. On the **Alert settings** tab, select the
   **Send a single email notification to Owners and Maintainers for new alerts** checkbox.
1. Select **Save changes**.

[Update the alert's status](alerts.md#update-an-alerts-status) to manage email notifications for an alert.

## Paging **(PREMIUM)**

In projects that have an [escalation policy](escalation_policies.md) configured, on-call responders
can be automatically paged about critical problems through email.

### Escalating an alert

When an alert is triggered, it begins escalating to the on-call responders immediately.
For each escalation rule in the project's escalation policy, the designated on-call
responders receive one email when the rule fires. You can respond to a page
or stop alert escalations by [updating the alert's status](alerts.md#update-an-alerts-status).

### Escalating an incident

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5716) in GitLab 14.9 [with a flag](../../administration/feature_flags.md) named `incident_escalations`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) in GitLab 14.10.
> - [Feature flag `incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) removed in GitLab 15.1.

For incidents, paging on-call responders is optional for each individual incident.
To begin escalating the incident, [set the incident's escalation policy](incidents.md#change-escalation-policy).
For each escalation rule, the designated on-call responders receive one email when
the rule fires. You can respond to a page or stop incident escalations by
[updating the incident's status](incidents.md#change-incident-status) or, if applicable,
[unsetting the incident's escalation policy](incidents.md#change-escalation-policy).

To avoid duplicate pages, [incidents created from alerts](alerts.md#create-an-incident-from-an-alert) do not support independent escalation.
