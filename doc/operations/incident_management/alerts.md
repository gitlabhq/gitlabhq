---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Create and manage alerts in GitLab

Users with at least Developer [permissions](../../user/permissions.md) can access
the Alert Management list at **{cloud-gear}** **Operations > Alerts** in your
project's sidebar. The Alert Management list displays alerts sorted by start time,
but you can change the sort order by clicking the headers in the Alert Management list.
([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217745) in GitLab 13.1.)

The alert list displays the following information:

![Alert List](img/alert_list_v13_1.png)

- **Search** - The alert list supports a simple free text search on the title,
  description, monitoring tool, and service fields.
  ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213884) in GitLab 13.1.)
- **Severity** - The current importance of a alert and how much attention it should
  receive. For a listing of all statuses, read [Alert Management severity](#alert-severity).
- **Start time** - How long ago the alert fired. This field uses the standard
  GitLab pattern of `X time ago`, but is supported by a granular date/time tooltip
  depending on the user's locale.
- **Alert description** - The description of the alert, which attempts to capture the most meaningful data.
- **Event count** - The number of times that an alert has fired.
- **Issue** - A link to the incident issue that has been created for the alert.
- **Status** - The current status of the alert:
  - **Triggered**: No one has begun investigation.
  - **Acknowledged**: Someone is actively investigating the problem.
  - **Resolved**: No further work is required.

TIP: **Tip:**
Check out a live example available from the
[`tanuki-inc` project page](https://gitlab-examples-ops-incident-setup-everyone-tanuki-inc.34.69.64.147.nip.io/)
in GitLab to examine alerts in action.

## Enable Alerts

NOTE: **Note:**
You need at least Maintainer [permissions](../../user/permissions.md) to enable
the Alerts feature.

There are several ways to accept alerts into your GitLab project.
Enabling any of these methods enables the Alert list. After configuring
alerts, visit **{cloud-gear}** **Operations > Alerts** in your project's sidebar
to view the list of alerts.

### Enable GitLab-managed Prometheus alerts

You can install the GitLab-managed Prometheus application on your Kubernetes
cluster. For more information, read
[Managed Prometheus on Kubernetes](../../user/project/integrations/prometheus.md#managed-prometheus-on-kubernetes).
When GitLab-managed Prometheus is installed, the Alerts list is also enabled.

To populate the alerts with data, read
[GitLab-Managed Prometheus instances](../metrics/alerts.md#managed-prometheus-instances).

### Enable external Prometheus alerts

You can configure an externally-managed Prometheus instance to send alerts
to GitLab. To set up this configuration, read the [configuring Prometheus](../metrics/alerts.md#external-prometheus-instances) documentation. Activating the external Prometheus
configuration also enables the Alerts list.

To populate the alerts with data, read
[External Prometheus instances](../metrics/alerts.md#external-prometheus-instances).

### Enable a Generic Alerts endpoint

GitLab provides the Generic Alerts endpoint so you can accept alerts from a third-party
alerts service. Read the
[instructions for toggling generic alerts](generic_alerts.md#setting-up-generic-alerts)
to add this option. After configuring the endpoint, the
Alerts list is enabled.

To populate the alerts with data, read [Customizing the payload](generic_alerts.md#customizing-the-payload) for requests to the alerts endpoint.

### Opsgenie integration **(PREMIUM)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3066) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.

A new way of monitoring Alerts via a GitLab integration is with
[Opsgenie](https://www.atlassian.com/software/opsgenie).

NOTE: **Note:**
If you enable the Opsgenie integration, you can't have other GitLab alert services,
such as [Generic Alerts](generic_alerts.md) or
Prometheus alerts, active at the same time.

To enable Opsgenie integration:

1. Sign in as a user with Maintainer or Owner [permissions](../../user/permissions.md).
1. Navigate to **{cloud-gear}** **Operations > Alerts**.
1. In the **Integrations** select box, select Opsgenie.
1. Click the **Active** toggle.
1. In the **API URL**, enter the base URL for your Opsgenie integration, such
   as `https://app.opsgenie.com/alert/list`.
1. Click **Save changes**.

After enabling the integration, navigate to the Alerts list page at
**{cloud-gear}** **Operations > Alerts**, and click **View alerts in Opsgenie**.

## Alert severity

Each level of alert contains a uniquely shaped and color-coded icon to help
you identify the severity of a particular alert. These severity icons help you
immediately identify which alerts you should prioritize investigating:

![Alert Management Severity System](img/alert_management_severity_v13_0.png)

Alerts contain one of the following icons:

| Severity | Icon | Color (hexadecimal) |
|---|---|---|
| Critical | **{severity-critical}** | `#8b2615` |
| High | **{severity-high}** | `#c0341d` |
| Medium | **{severity-medium}** | `#fca429` |
| Low | **{severity-low}** | `#fdbc60` |
| Info | **{severity-info}** | `#418cd8` |
| Unknown | **{severity-unknown}** | `#bababa` |
