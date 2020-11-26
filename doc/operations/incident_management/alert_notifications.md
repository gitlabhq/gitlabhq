---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Paging and notifications

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

Email notifications are available in projects that have been
[configured to create incidents automatically](incidents.md#create-incidents-automatically)
for triggered alerts. Project members with the **Owner** or **Maintainer** roles are
sent an email notification automatically. (This is not configurable.) To optionally
send additional email notifications to project members with the **Developer** role:

1. Navigate to **Settings > Operations**.
1. Expand the **Incidents** section.
1. In the **Alert Integration** tab, select the **Send a separate email notification to Developers**
   check box.
1. Select **Save changes**.
