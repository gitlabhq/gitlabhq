---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Set up alerts for Prometheus metrics **(FREE)**

After [configuring metrics for your CI/CD environment](index.md), you can set up
alerting for Prometheus metrics, and
[trigger actions from alerts](#trigger-actions-from-alerts) to notify
your team when environment performance falls outside of the boundaries you set.

## Prometheus cluster integrations

Alerts are not supported for [Prometheus cluster integrations](../../user/clusters/integrations.md).

## Trigger actions from alerts **(ULTIMATE)**

> - Introduced in GitLab 13.1: incidents are not created automatically by default .
> - Mapping common severity values from the alert payload ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50871) in GitLab 13.9.

Turn on creating [incidents](../incident_management/incidents.md) automatically whenever an alert is triggered.

Prerequisites:

- You must have at least the Maintainer role for the project.

To configure the actions:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Monitor**.
1. Expand the **Alerts** section, then select the **Alert settings** tab.
1. Select the **Create an incident** checkbox.
1. Optional. To customize the incident, from the **Incident template**, select a template to be
   appended to the [incident summary](../incident_management/incidents.md#summary).
   If the dropdown list is empty,
   [create an issue template](../../user/project/description_templates.md#create-an-issue-template) first.
1. Optional. To send [an email notification](../incident_management/paging.md#email-notifications-for-alerts), select the
   **Send a single email notification to Owners and Maintainers for new alerts** checkbox.
1. Select **Save changes**.

### Fields in automatically created incidents

Incidents [created automatically from an alert](#trigger-actions-from-alerts) are filled with
values extracted from the `alerts` field in the
[webhook payload](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config):

- Incident author: `GitLab Alert Bot`
- Incident title: Extracted from the alert payload fields `annotations/title`, `annotations/summary`, or `labels/alertname`.
- Incident description: Extracted from alert payload field `annotations/description`.
- Alert `Summary`: A list of properties from the alert's payload.
  - `starts_at`: Alert start time from the payload's `startsAt` field
  - `full_query`: Alert query extracted from the payload's `generatorURL` field
  - Optional list of attached annotations extracted from `annotations/*`
- Alert [GLFM](../../user/markdown.md): GitLab Flavored Markdown from the payload's `annotations/gitlab_incident_markdown` field.
- Alert severity:
  Extracted from the alert payload field `labels/severity`. Maps case-insensitive
  value to [Alert's severity](../incident_management/alerts.md#alert-severity):

  | Alert payload | Mapped to alert severity                                                    |
  | ------------- | --------------------------------------------------------------------------- |
  | Critical      | `critical`, `s1`, `p1`, `emergency`, `fatal`, or any value not in this list |
  | High          | `high`, `s2`, `p2`, `major`, `page`                                         |
  | Medium        | `medium`, `s3`, `p3`, `error`, `alert`                                      |
  | Low           | `low`, `s4`, `p4`, `warn`, `warning`                                        |
  | Info          | `info`, `s5`, `p5`, `debug`, `information`, `notice`                        |

To further customize the incident, you can add labels, mentions, or any other supported
[quick action](../../user/project/quick_actions.md) in the selected issue template,
which applies to all incidents. To limit quick actions or other information to
only specific types of alerts, use the `annotations/gitlab_incident_markdown` field.

GitLab tags each incident issue with the `incident` label automatically. If the label
does not yet exist, it's created automatically.

### Recovery alerts

The alert in GitLab is automatically resolved when Prometheus
sends a payload with the field `status` set to `resolved`.

You can also configure the associated [incident to be closed automatically](../incident_management/manage_incidents.md#automatically-close-incidents-via-recovery-alerts) when the alert resolves.
