---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: View information about your GitLab Dedicated instance with Switchboard.
title: View GitLab Dedicated instance details
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Monitor your GitLab Dedicated instance details, maintenance windows, and configuration status in Switchboard.

## View your instance details

To access your instance details:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select your tenant.

The **Overview** page displays:

- Any pending configuration changes
- When the instance was updated
- Instance details
- Maintenance windows
- Hosted runners
- Customer communication

## Tenant overview

The top section shows important information about your tenant, including:

- Tenant name and URL
- [Repository storage](create_instance/storage_types.md#repository-storage)
- Current GitLab version
- Reference architecture
- Maintenance window
- Primary and secondary AWS regions for data storage, with their availability zone IDs
- Backup AWS region
- AWS account IDs for the tenant and hosted runners

## Maintenance windows

The **Maintenance windows** section displays the:

- Next scheduled maintenance window
- Most recent completed maintenance window
- Most recent emergency maintenance window (if applicable)
- Upcoming GitLab version upgrade

{{< alert type="note" >}}

Each Sunday night in UTC, Switchboard updates to display the planned GitLab version upgrades for the upcoming week's maintenance windows. For more information, see [Maintenance windows](maintenance.md#maintenance-windows).

{{< /alert >}}

## Hosted runners

The **Hosted runners** section shows the [hosted runners](hosted_runners.md) associated with your instance.

## NAT IP addresses

NAT gateway IP addresses typically remain consistent during standard operations but might change occasionally, such as when GitLab needs to rebuild your instance during disaster recovery.

You need to know your NAT gateway IP addresses in cases like:

- Configuring webhook receivers to accept incoming requests from your GitLab Dedicated instance.
- Setting up allowlists for external services to accept connections from your GitLab Dedicated instance.

### View your NAT gateway IP addresses

To view the current NAT gateway IP addresses for your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select your tenant.
1. Select the **Configuration** tab.
1. Under **Tenant Details**, find your **NAT gateways**.

## Customer communication

The **Customer communication** section shows the **Operational email addresses** configured for your GitLab Dedicated instance. These email addresses receive notifications about your instance, including:

- Emergency maintenance
- Incidents
- Other critical updates

You cannot turn off notifications for operational email addresses.

To update your customer communication information, [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
