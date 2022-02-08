---
type: reference, howto
stage: Protect
group: Container Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Threat Monitoring **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14707) in GitLab 12.9.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/7476) in GitLab 14.8, and planned for [removal](https://gitlab.com/groups/gitlab-org/-/epics/7477) in GitLab 15.0.

WARNING:
Threat Monitoring is in its end-of-life process. It's [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/7476)
for use in GitLab 14.8, and planned for [removal](https://gitlab.com/groups/gitlab-org/-/epics/7477)
in GitLab 15.0.

The **Threat Monitoring** page provides alerts and metrics
for the GitLab application runtime security features. You can access
these by navigating to your project's **Security & Compliance > Threat
Monitoring** page.

GitLab supports statistics for the following security features:

- [Container Network Policies](../../../topics/autodevops/stages.md#network-policy)

## Container Network Policy Alert list

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3438) in GitLab 13.9.

The policy alert list displays your policy's alert activity. You can sort the list by these columns:

- Date and time
- Events
- Status

You can filter the list with the **Policy Name** filter and the **Status** filter at the top. Use
the selector menu in the **Status** column to set the status for each alert:

- Unreviewed
- In review
- Resolved
- Dismissed

By default, the list doesn't display resolved or dismissed alerts.

![Policy Alert List](img/threat_monitoring_policy_alert_list_v14_3.png)

Clicking an alert's row opens the alert drawer, which shows more information about the alert. A user
can also create an incident from the alert and update the alert status in the alert drawer.

Clicking an alert's name takes the user to the [alert details page](../../../operations/incident_management/alerts.md#alert-details-page).
