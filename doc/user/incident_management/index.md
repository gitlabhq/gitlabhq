---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Incident Management

GitLab offers solutions for handling incidents in your applications and services,
such as setting up Prometheus alerts, displaying metrics, and sending notifications.

## Configure incidents **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4925) in GitLab Ultimate 11.11.

You can enable or disable Incident Management features in the GitLab user interface
to create issues when alerts are triggered:

1. Navigate to **{settings}** **Settings > Operations > Incidents** and expand
   **Incidents**:

   ![Incident Management Settings](img/incident_management_settings.png)

1. For GitLab versions 11.11 and greater, you can select the **Create an issue**
   checkbox to create an issue based on your own
   [issue templates](../project/description_templates.md#creating-issue-templates).
   For more information, see
   [Trigger actions from alerts](../../operations/metrics/alerts.md#trigger-actions-from-alerts-ultimate) **(ULTIMATE)**.
1. To create issues from alerts, select the template in the **Issue Template**
   select box.
1. To send [separate email notifications](#notify-developers-of-alerts) to users
   with [Developer permissions](../permissions.md), select
   **Send a separate email notification to Developers**.
1. Click **Save changes**.

Appropriately configured alerts include an
[embedded chart](../../operations/metrics/embed.md#embedding-metrics-based-on-alerts-in-incident-issues)
for the query corresponding to the alert. You can also configure GitLab to
[close issues](../../operations/metrics/alerts.md#trigger-actions-from-alerts-ultimate)
when you receive notification that the alert is resolved.

### Notify developers of alerts

GitLab can react to the alerts triggered from your applications and services
by creating issues and alerting developers through email. By default, GitLab
sends these emails to [owners and maintainers](../permissions.md) of the project.
These emails contain details of the alert, and a link for more information.

To send separate email notifications to users with
[Developer permissions](../permissions.md), see [Configure incidents](#configure-incidents-ultimate).

## Configure PagerDuty integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/119018) in GitLab 13.3.

You can set up a webhook with PagerDuty to automatically create a GitLab issue
for each PagerDuty incident. This configuration requires you to make changes
in both PagerDuty and GitLab:

1. Sign in as a user with Maintainer [permissions](../permissions.md).
1. Navigate to **{settings}** **Settings > Operations > Incidents** and expand **Incidents**.
1. Select the **PagerDuty integration** tab:

   ![PagerDuty incidents integration](img/pagerduty_incidents_integration_13_3.png)

1. Activate the integration, and save the changes in GitLab.
1. Copy the value of **Webhook URL** for use in a later step.
1. Follow the steps described in the
   [PagerDuty documentation](https://support.pagerduty.com/docs/webhooks)
   to add the webhook URL to a PagerDuty webhook integration.

To confirm the integration is successful, trigger a test incident from PagerDuty to
confirm that a GitLab issue is created from the incident.

## Configure Prometheus alerts

You can set up Prometheus alerts in:

- [GitLab-managed Prometheus](../../operations/metrics/alerts.md) installations.
- [Self-managed Prometheus](../../operations/metrics/alerts.md#external-prometheus-instances) installations.

Prometheus alerts are created by the special Alert Bot user. You can't remove this
user, but it does not count toward your license limit.

## Configure external generic alerts

GitLab can accept alerts from any source through a generic webhook receiver. When
[configuring the generic alerts integration](../project/integrations/generic_alerts.md),
GitLab creates a unique endpoint which receives a JSON-formatted, customizable payload.

## Embed metrics in incidents and issues

You can embed metrics anywhere [GitLab Markdown](../markdown.md) is used, such as descriptions,
comments on issues, and merge requests. Embedding metrics helps you share them
when discussing incidents or performance issues. You can output the dashboard directly
into any issue, merge request, epic, or any other Markdown text field in GitLab
by [copying and pasting the link to the metrics dashboard](../../operations/metrics/embed.md#embedding-gitlab-managed-kubernetes-metrics).

You can embed both
[GitLab-hosted metrics](../../operations/metrics/embed.md) and
[Grafana metrics](../../operations/metrics/embed_grafana.md)
in incidents and issue templates.

### Context menu

You can view more details about an embedded metrics panel from the context menu.
To access the context menu, click the **{ellipsis_v}** **More actions** dropdown box
above the upper right corner of the panel. For a list of options, see
[Chart context menu](../../operations/metrics/dashboards/index.md#chart-context-menu).

#### View logs from metrics panel

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/201846) in GitLab Ultimate 12.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25455) to [GitLab Core](https://about.gitlab.com/pricing/) 12.9.

Viewing logs from a metrics panel can be useful if you're triaging an application
incident and need to [explore logs](../../operations/metrics/dashboards/index.md#chart-context-menu)
from across your application. These logs help you understand what is affecting
your application's performance and resolve any problems.

## Integrate incidents with Slack

Slack slash commands allow you to control GitLab and view GitLab content without leaving Slack.

Learn how to [set up Slack slash commands](../project/integrations/slack_slash_commands.md)
and how to [use the available slash commands](../../integration/slash_commands.md).

## Integrate issues with Zoom

GitLab enables you to [associate a Zoom meeting with an issue](../project/issues/associate_zoom_meeting.md)
for synchronous communication during incident management. After starting a Zoom
call for an incident, you can associate the conference call with an issue. Your
team members can join the Zoom call without requesting a link.
