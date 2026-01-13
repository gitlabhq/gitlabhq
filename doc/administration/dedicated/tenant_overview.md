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

Use Switchboard to view your GitLab Dedicated instance details, maintenance windows, and configuration status.

## View your instance details

To access your instance details, sign in to [Switchboard](https://console.gitlab-dedicated.com/).

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
- Instance status
- Primary and secondary AWS regions for data storage, with their availability zone IDs
- Backup AWS region
- AWS account IDs for the tenant and hosted runners

## Tenant status indicators

The **Overview** page displays real-time status information about your GitLab Dedicated instance. This way, you can quickly understand whether your instance is operating normally or experiencing issues.

Status indicators communicate incidents affecting your instance. Switchboard displays one of three status states:

- Normal
- Service disruption
- Degraded performance

Switchboard does not display:

- Severity 3 or Severity 4 incidents: These incidents have minimal impact on your instance.
- Severity 1 or Severity 2 incidents in non-impacting lifecycle stages: Incidents being reviewed, documented, or canceled do not display.
- Merged incidents: If multiple alerts are consolidated into a single incident, only the primary incident displays.

> [!note]
>
> - Status indicators are informational only and are not factored into SLA calculations. Following an S1 or S2 incident, SLA evaluation follows the standard process.
> - Status updates might take a few moments to appear after an incident state changes while Switchboard syncs with the incident management platform. Updates typically appear within one to two minutes.
>

### Normal

The following status indicator appears: `Normal`

- What this status means: Your GitLab instance is operating as expected with no known issues.
- When this status appears: No active critical (S1) or high-severity (S2) incidents are affecting your instance.

### Degraded performance

The following status indicator appears: `Degraded performance. GitLab services may be slow or unresponsive for users.`

- What this status means: GitLab services might be slow or unresponsive for some or all users.
- When causes this status to appear: One or more active high-severity (S2) incidents are affecting your instance. Core GitLab functionality is significantly impacted.
- What GitLab is doing: GitLab Dedicated SREs are actively tracking, investigating, and working to resolve the issue.

### Service disruption

The following status indicator appears: `Service disruption. GitLab services may be unavailable for users.`

- What this status means: GitLab services might be unavailable for users.
- What causes this status to appear: One or more active critical (S1) incidents are affecting your instance. One or more services required to run GitLab are fully down.
- What GitLab is doing: GitLab Dedicated SREs are tracking, investigating, and working to restore full performance.

## Maintenance indicators

Maintenance indicators communicate details related to your scheduled maintenance window. Switchboard displays one of two maintenance states:

- Scheduled maintenance
- Emergency maintenance

The following status indicator appears: `Under maintenance. Users may experience disruptions with GitLab services.`

### Scheduled maintenance

- What this maintenance indicator means: Your instance is currently in a scheduled maintenance window.
  Brief disruptions might occur during maintenance. For more information, see [GitLab Dedicated maintenance operations](maintenance.md#access-during-maintenance).
- When this maintenance indicator appears: The scheduled maintenance indicator appears during your scheduled maintenance window.
- What GitLab is doing: Planned updates, patches, or infrastructure improvements are being conducted to keep your instance secure and up-to-date.

### Emergency maintenance

- What this maintenance indicator means: Your instance is undergoing emergency maintenance. Disruptions might occur during maintenance.
- When this maintenance indicator appears: The emergency maintenance indicator appears during [emergency maintenance procedures](maintenance.md#emergency-maintenance).
- What GitLab is doing: Critical, time-sensitive updates to keep your instance secure and available are being performed.

> [!note]
> If an incident occurs during maintenance, both the maintenance indicator and the instance status indicator appear.

### What to do if you have questions

If you see a degraded or disruption status, the GitLab team is already aware and working on the issue. You do not need to open a support ticket unless your workflows require specific assistance. Statuses automatically update as the incident progresses.

If you're experiencing issues but the status displays `Normal`, the issue might be specific to your configuration or usage patterns. In this case, open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and include details about what you're experiencing and when the behavior started.

### Related resources

- [GitLab incident severity definitions](https://handbook.gitlab.com/handbook/engineering/infrastructure/incident-management/#incident-severity)
- [GitLab Dedicated maintenance operations](maintenance.md)

## Maintenance windows

The **Maintenance windows** section displays the:

- Next scheduled maintenance window
- Most recent completed maintenance window
- Most recent emergency maintenance window (if applicable)
- Upcoming GitLab version upgrade

> [!note]
> Every Sunday night in UTC, Switchboard updates to display the planned GitLab version upgrades for the upcoming week's maintenance windows. For more information, see [Maintenance windows](maintenance.md#maintenance-windows).

## Hosted runners

The **Hosted runners** section shows the [hosted runners](hosted_runners.md) associated with your instance.

## Resource access

The **Resource access** section in Switchboard provides network information
needed to configure external services and firewalls to work with your GitLab Dedicated instance.

To view your resource access information:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
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

To manage access to and view application logs, see [access application logs for GitLab Dedicated](monitor.md).

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

## Custom domains

The **Custom domains** section displays configuration details for your custom domain setup.

The custom domain details include:

- GitLab instance domain: The custom domain for your GitLab instance.
- Registry domain: The custom domain for the container registry.
- KAS domain: The custom domain for the GitLab agent server for Kubernetes (KAS).

Use this information to:

- Verify your current custom domain configuration.
- Reference domains for external integrations.
- Copy configuration details for DNS management.

To view your custom domain details:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select the **Configuration** tab.
1. Expand **Custom domains**.

### DNSSEC details

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated for Government

{{< /details >}}

If your custom domain is configured with Cloudflare Web Application Firewall (WAF),
additional configuration details are displayed including Cloudflare nameservers
and DNSSEC parameters for FedRAMP compliance.

The additional details include:

- Cloudflare nameservers: DNS nameservers for Cloudflare-managed domains.
- Key tag: Numeric identifier for the DNSSEC key.
- Algorithm: Cryptographic algorithm used (typically 13 for ECDSA P-256 with SHA-256).
- Digest type: Hash algorithm used (typically 2 for SHA-256).
- Digest: Cryptographic hash of the public key.

Use these values to configure DNS delegation and DNSSEC validation with your DNS provider.

## Contact information

The **Contact information** section shows the operational email addresses configured for
your GitLab Dedicated instance. These email addresses receive notifications about your instance, including:

- Emergency maintenance
- Incidents
- Other critical updates

To update your operational email addresses,
see [manage email addresses for operational contacts](configure_instance/users_notifications.md#manage-email-addresses-for-operational-contacts).
