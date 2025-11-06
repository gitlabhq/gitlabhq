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

## Resource access

The **Resource access** section in Switchboard provides network information
needed to configure external services and firewalls to work with your GitLab Dedicated instance.

To view your resource access information:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select your tenant.
1. Select the **Configuration** tab.
1. Expand **Resource access**.
1. Under the relevant section, select **Copy to clipboard** ({{< icon name="copy-to-clipboard" >}}) next to the information you need.

### Application logs

The **Application logs** section displays:

- Logs S3 bucket name
- Log access ARNs

Use this information to:

- Access your application logs.
- Configure automated log processing and monitoring systems.
- Set up tools that need the specific S3 bucket name to retrieve logs.
- Meet compliance and auditing requirements.

To request access and access application logs, see [monitor your GitLab Dedicated instance](monitor.md).

### NAT gateway IP addresses

NAT gateway IP addresses typically remain consistent during standard operations
but can change when GitLab rebuilds your instance during disaster recovery.

Use this information to:

- Configure webhook receivers to accept incoming requests from your GitLab Dedicated instance.
- Set up allowlists for external services to accept connections from your GitLab Dedicated instance.

### Container registry

The **Container registry** section provides the FQDN (Fully Qualified Domain Name) for your 
instance's container registry S3 bucket.

Use this information to:

- Configure firewall rules that allow access to your GitLab container registry.
- Set up network policies that reference the registry storage location.

You should use the FQDN instead of IP addresses because:

- IP addresses for S3 buckets can change over time.
- FQDNs provide a stable reference point for network configuration.

## Contact information

The **Contact information** section shows the operational email addresses configured for
your GitLab Dedicated instance. These email addresses receive notifications about your instance, including:

- Emergency maintenance
- Incidents
- Other critical updates

To update your operational email addresses, see [manage email addresses for operational contacts](configure_instance/users_notifications.md#manage-email-addresses-for-operational-contacts).
