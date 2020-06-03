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
   [Taking Action on Incidents](../project/integrations/prometheus.md#taking-action-on-incidents-ultimate) **(ULTIMATE)**.
1. To create issues from alerts, select the template in the **Issue Template**
   select box.
1. To send [separate email notifications](#notify-developers-of-alerts) to users
   with [Developer permissions](../permissions.md), select
   **Send a separate email notification to Developers**.
1. Click **Save changes**.

Appropriately configured alerts include an
[embedded chart](../project/integrations/prometheus.md#embedding-metrics-based-on-alerts-in-incident-issues)
for the query corresponding to the alert. You can also configure GitLab to
[close issues](../project/integrations/prometheus.md#taking-action-on-incidents-ultimate)
when you receive notification that the alert is resolved.

### Notify developers of alerts

GitLab can react to the alerts triggered from your applications and services
by creating issues and alerting developers through email. By default, GitLab
sends these emails to [owners and maintainers](../permissions.md) of the project.
These emails contain details of the alert, and a link for more information.

To send separate email notifications to users with
[Developer permissions](../permissions.md), see [Configure incidents](#configure-incidents-ultimate).

## Configure Prometheus alerts

You can set up Prometheus alerts in:

- [GitLab-managed Prometheus](../project/integrations/prometheus.md#setting-up-alerts-for-prometheus-metrics) installations.
- [Self-managed Prometheus](../project/integrations/prometheus.md#external-prometheus-instances) installations.

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
by [copying and pasting the link to the metrics dashboard](../project/integrations/prometheus.md#embedding-gitlab-managed-kubernetes-metrics).

You can embed both
[GitLab-hosted metrics](../project/integrations/prometheus.md#embedding-metric-charts-within-gitlab-flavored-markdown) and
[Grafana metrics](../project/integrations/prometheus.md#embedding-grafana-charts)
in incidents and issue templates.

### Context menu

You can view more details about an embedded metrics panel from the context menu.
To access the context menu, click the **{ellipsis_v}** **More actions** dropdown box
above the upper right corner of the panel. The options are:

- [View logs](#view-logs-from-metrics-panel).
- **Download CSV** - Data from embedded charts can be
  [downloaded as CSV](../project/integrations/prometheus.md#downloading-data-as-csv).

#### View logs from metrics panel

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/201846) in GitLab Ultimate 12.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25455) to [GitLab Core](https://about.gitlab.com/pricing/) 12.9.

Viewing logs from a metrics panel can be useful if you're triaging an application
incident and need to [explore logs](../project/integrations/prometheus.md#view-logs-ultimate)
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
