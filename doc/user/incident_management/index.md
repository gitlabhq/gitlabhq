---
description: "GitLab - Incident Management. GitLab offers solutions for handling incidents in your applications and services"
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Incident Management

GitLab offers solutions for handling incidents in your applications and services,
from setting up an alert with Prometheus, to receiving a notification via a
monitoring tool like Slack, and automatically setting up Zoom calls with your
support team.

## Configuring incidents **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/4925) in GitLab Ultimate 11.11.

The Incident Management features can be enabled and disabled via your project's
**Settings > Operations > Incidents**.

![Incident Management Settings](img/incident_management_settings.png)

### Automatically create issues from alerts

GitLab issues can automatically be created as a result of an alert notification.
An issue created this way will contain the error information to help you further
debug it.

### Issue templates

You can create your own [issue templates](../project/description_templates.md#creating-issue-templates)
that can be [used within Incident Management](../project/integrations/prometheus.md#taking-action-on-incidents-ultimate).

To select your issue template for use within Incident Management:

1. Visit your project's **Settings > Operations > Incidents**.
1. Select the template from the **Issue Template** dropdown.

## Alerting

GitLab can react to the alerts that your applications and services may be
triggering by automatically creating issues, and alerting developers via email.

The emails will be sent to [owners and maintainers](../permissions.md) of the project and will contain details on the alert as well as a link to see more information.

### Prometheus alerts

Prometheus alerts can be set up in both:

- [GitLab-managed Prometheus](../project/integrations/prometheus.md#setting-up-alerts-for-prometheus-metrics) and
- [Self-managed Prometheus](../project/integrations/prometheus.md#external-prometheus-instances) installations.

#### Alert Bot user

Behind the scenes, Prometheus alerts are created by the special Alert Bot user creating issues. This user cannot be removed but does not count toward the license limit count.

### Alert endpoint

GitLab can accept alerts from any source via a generic webhook receiver. When
you set up the generic alerts integration, a unique endpoint will
be created which can receive a payload in JSON format.

[Read more on setting this up, including how to customize the payload](../project/integrations/generic_alerts.md).

### Recovery alerts

GitLab can [automatically close issues](../project/integrations/prometheus.md#taking-action-on-incidents-ultimate)
that have been automatically created when you receive notification that the
alert is resolved.

## Embedded metrics

Metrics can be embedded anywhere where GitLab Markdown is used, for example,
descriptions and comments on issues and merge requests.

This can be useful for when you're sharing metrics, such as for discussing
an incident or performance issues, so you can output the dashboard directly
into any issue, merge request, epic, or any other Markdown text field in GitLab
by simply [copying and pasting the link to the metrics dashboard](../project/integrations/prometheus.md#embedding-gitlab-managed-kubernetes-metrics).

TIP: **Tip:**
Both GitLab-hosted and Grafana metrics can also be
[embedded in issue templates](../project/integrations/prometheus.md#embedding-metrics-in-issue-templates).

### GitLab-hosted metrics

Learn how to embed [GitLab hosted metric charts](../project/integrations/prometheus.md#embedding-metric-charts-within-gitlab-flavored-markdown).

#### Context menu

From each of the embedded metrics panels, you can access more details
about the data you are viewing from a context menu.

You can access the context menu by clicking the **{ellipsis_v}** **More actions**
dropdown box above the upper right corner of the panel:

The options are:

- [View logs](#view-logs)
- [Download CSV](#download-csv)

##### View logs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/201846) in GitLab Ultimate 12.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25455) to [GitLab Core](https://about.gitlab.com/pricing/) 12.9.

This can be useful if you are triaging an application incident and need to
[explore logs](../project/integrations/prometheus.md#view-logs-ultimate)
from across your application. It also helps you to understand
what is affecting your application's performance and quickly resolve any problems.

##### Download CSV

Data from embedded charts can be [downloaded as CSV](../project/integrations/prometheus.md#downloading-data-as-csv).

### Grafana metrics

Learn how to embed [Grafana hosted metric charts](../project/integrations/prometheus.md#embedding-grafana-charts).

## Slack integration

Slack slash commands allow you to control GitLab and view content right inside
Slack, without having to leave it.

Learn how to [set up Slack slash commands](../project/integrations/slack_slash_commands.md)
and how to [use them](../../integration/slash_commands.md).

### Slash commands

Please refer to a list of [available slash commands](../../integration/slash_commands.md) and associated descriptions.

## Zoom in issues

In order to communicate synchronously for incidents management, GitLab allows you to
associate a Zoom meeting with an issue. Once you start a Zoom call for a fire-fight,
you need a way to associate the conference call with an issue, so that your team
members can join swiftly without requesting a link.

Read more how to [add or remove a zoom meeting](../project/issues/associate_zoom_meeting.md).

### Configuring Incidents

Incident Management features can be easily enabled & disabled via the Project settings page. Head to Project -> Settings -> Operations -> Incidents.

#### Auto-creation

You can automatically create GitLab issues from an Alert notification. Issues created this way contain error information to help you debug the error. Appropriately configured alerts include an [embedded chart](../project/integrations/prometheus.md#embedding-metrics-based-on-alerts-in-incident-issues) for the query corresponding to the alert.
