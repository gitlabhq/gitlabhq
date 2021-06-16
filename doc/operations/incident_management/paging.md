---
stage: Monitor
group: Monitor
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

## Email notifications

Email notifications are available in projects for triggered alerts. Project
members with the **Owner** or **Maintainer** roles have the option to receive
a single email notification for new alerts.

1. Navigate to **Settings > Monitor**.
1. Expand the **Alerts** section.
1. In the **Integration settings** tab, select the checkbox
   **Send a single email notification to Owners and Maintainers for new alerts**.
1. Select **Save changes**.

## Paging **(PREMIUM)**

In projects that have an [on-call schedule](oncall_schedules.md) configured, on-call responders are
paged through email for triggered alerts. The on-call responder(s) receive one email for triggered
alerts.
