---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Check instance health and find maintenance windows for your GitLab Dedicated instance in Switchboard.
title: GitLab Dedicated instance details
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

The Switchboard **Overview** page shows the current state of your GitLab Dedicated instance,
including its status and maintenance schedule. Sign in to
[Switchboard](https://console.gitlab-dedicated.com/) to view your instance details.

The page displays:

- Instance status
- Tenant URL
- GitLab version
- Reference architecture
- [Total purchased storage](create_instance/storage_types.md#total-purchased-storage)
- Maintenance window
- Primary AWS region and availability zone IDs
- Secondary AWS region and availability zone IDs
- Backup AWS region
- Tenant AWS account ID
- Hosted runners (if configured)

## Maintenance

Switchboard displays a maintenance indicator when your instance is undergoing maintenance.
Both maintenance types display the **Under maintenance** status.

| Maintenance type          | When it appears |
| ------------------------- | --------------- |
| **Scheduled maintenance** | During your scheduled maintenance window. For more information, see [access during maintenance](maintenance.md#access-during-maintenance). |
| **Emergency maintenance** | During unplanned, urgent maintenance outside your scheduled window. For more information, see [emergency maintenance](maintenance.md#emergency-maintenance). |

If an incident occurs during maintenance, both the maintenance indicator and the instance
status indicator appear.

The **Overview** page also displays these details:

- Next scheduled maintenance window and upcoming GitLab version upgrade
- Most recent completed maintenance window
- Most recent emergency maintenance window (if applicable)

Every Friday morning in UTC, Switchboard updates to display the planned GitLab version upgrades
for the upcoming week's maintenance windows.
For more information, see [maintenance windows](maintenance.md#maintenance-windows).

## Instance health

On the Switchboard **Health** page, you can see the overall status of your instance and the
availability of individual GitLab services included in your SLA.

| Status                   | Severity | Impact                                                      | Description |
| ------------------------ | -------- | ----------------------------------------------------------- | ----------- |
| **Normal**               | None     | No active incidents.                                        | No known issues with your GitLab instance. |
| **Degraded performance** | S2       | Core GitLab functionality is significantly impacted.        | GitLab services may be slow or unresponsive. |
| **Service disruption**   | S1       | One or more services required to run GitLab are fully down. | GitLab services may be unavailable. |
| **Under maintenance**    | N/A      | Maintenance is in progress.                                 | GitLab services may be disrupted. |

The following incidents do not appear in Switchboard:

- S3 and S4 incidents, which have minimal impact on your instance.
- Incidents in non-impacting lifecycle stages, such as incidents being reviewed,
  documented, or canceled.
- Merged incidents, where only the primary incident displays when multiple alerts are
  consolidated.

Status indicators are informational only and are not factored into SLA calculations.
Status updates typically appear within one to two minutes of an incident state change.

If you see a **Degraded performance** or **Service disruption** status, the GitLab team is
already aware and working on the issue. You do not need to open a support ticket unless your
workflows require specific assistance. Statuses automatically update as the incident progresses.

If you are experiencing issues but the status displays **Normal**, the issue might be specific
to your configuration or usage patterns. Open a
[support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
and include details about what you are experiencing and when the behavior started.

In the **Covered experiences** section, you can see the current availability status, measured
from user traffic, for the services defined as
[covered experiences](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/service-level-agreement/#covered-experiences) in the GitLab SLA:

- Issues
- Merge requests
- Git operations (push, pull, fetch, and clone over HTTPS and SSH)
- Container registry operations
- Package registry operations
- API requests (programmatic access to the services in this list)

Availability data can differ from declared incidents. Each service shows one of the
following states:

- **Normal**: The service is available.
- **Degraded availability**: The service has reduced availability.
- **Under maintenance**: Your instance is in a maintenance window. All services show this state
  until maintenance ends.
- **Insufficient data**: There is not enough traffic to measure the service's availability.
- **No data yet**: No availability data is reported for the service.

When availability data is present, you can also see when it was last updated.

If no availability data exists for your instance yet, the **Covered experiences** section
displays **No data yet** instead of the list of services.

> [!note]
> This page is informational only. It does not determine compliance with the SLA or your
> eligibility for service credits. To request service credits, follow the
> [credit request process](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/service-level-agreement/#credit-request-process)
> in the SLA for GitLab Dedicated.

## Switchboard customer API

You can retrieve your instance's SLA status programmatically with the Switchboard API.
The API is available to Switchboard users with tenant administrator access,
and returns data only for the instances you have access to.

The API has a single endpoint that returns the same instance health data the Switchboard
**Health** page displays:

- The overall status of your instance.
- The availability status of each covered experience.
- A `data_as_of` timestamp that indicates when the data was last refreshed.

You authenticate through Switchboard using an interactive browser sign-in.
You can refresh the access token programmatically for up to 30 days without signing in again,
after which you must sign in through the browser again.

> [!note]
> API responses are point-in-time snapshots. The API does not return historical or aggregated
> availability data, and is not intended for alerting. The API does not determine compliance
> with the SLA or your eligibility for service credits.

### Access the API reference

The API reference, including an authentication walkthrough and a glossary of status values, is
available only to authenticated Switchboard users.

To access the API reference:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. In the sidebar, select **Help**.
1. Select **API documentation**.

## Related topics

- [GitLab Dedicated maintenance operations](maintenance.md)
- [Hosted runners for GitLab Dedicated](hosted_runners.md)
- [GitLab Dedicated network access and security](configure_instance/network_security.md)
