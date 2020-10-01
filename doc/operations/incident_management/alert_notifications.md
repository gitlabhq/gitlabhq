---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Alert notifications

GitLab can react to alerts triggered from your applications. When an alert is
triggered in GitLab by [managed-Prometheus](../../user/project/integrations/prometheus.md#managed-prometheus-on-kubernetes)
or triggered using an external source and received with an integration, it's
important for a responder to be notified.

Responders can receive notifications using the methods described on this page.

## Slack notifications

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216326) in GitLab 13.1.

You can be alerted by a Slack message when a new alert has been triggered.

For setup information, see the [Slack Notifications Service docs](../../user/project/integrations/slack.md).

## Email notifications

If a project has been [configured to create incidents for triggered alerts](incidents.md#configure-incidents),
projects members with the _Owner_ or _Maintainer_ role will be sent an email
notification. To send additional email notifications to project members with the
Developer role:

1. Navigate to **Settings > Operations**.
1. Expand the **Incidents** section.
1. In the **Alert Integration** tab, select the **Send a separate email notification to Developers**
   check box.
1. Select **Save changes**.
