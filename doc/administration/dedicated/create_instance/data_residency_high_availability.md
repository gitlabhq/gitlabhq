---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Available AWS regions, data isolation, and high availability for GitLab Dedicated.
title: Data residency and high availability
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated provides data residency control and high availability capabilities
through your choice of AWS regions. You control where your data is stored and processed,
enabling you to meet regulatory requirements while maintaining enterprise-grade uptime.

Your GitLab Dedicated environment runs in a dedicated AWS account, completely isolated from
other tenants and GitLab.com. This single-tenant architecture gives you full control over
data location while GitLab manages the underlying infrastructure and ensures high availability
through proven reference architectures.

GitLab Dedicated uses a modified version of the
[Cloud Native Hybrid reference architecture](../../reference_architectures/_index.md#cloud-native-hybrid)
with high availability. Within your selected region, GitLab distributes your infrastructure
across multiple availability zones for redundancy. During onboarding, you can let GitLab
automatically select availability zones (recommended), or specify custom availability zone IDs
to align with your existing AWS infrastructure.

> [!note]
> GitLab Dedicated uses additional cloud provider services beyond the standard reference architectures
> to enhance security and stability. As a result, costs for GitLab Dedicated differ from standard
> reference architecture costs.

## Region selection

When you create your GitLab Dedicated instance, you select AWS regions for your primary deployment,
disaster recovery, and backups. Your region choices are permanent and cannot be changed after
provisioning. Choose regions based on data residency requirements, latency, and disaster recovery
strategy to ensure your instance meets compliance needs and protects against regional outages.

Primary region
: Your main deployment where your instance runs and users access GitLab.
  This is where your data is stored and must meet your data residency requirements.

Secondary region
: An optional AWS region for Geo-based disaster recovery. If your primary region becomes
  unavailable, you can fail over to your secondary region.

Backup region
: An optional AWS region where backups are replicated for additional redundancy.
  This can be the same as your primary or secondary region, or a different region for
  increased redundancy.

Consider these factors when selecting regions:

- Data residency and compliance: Your primary region is where your data is stored. Choose regions
  that meet your regulatory requirements. For example, GDPR compliance may require data to remain
  in the EU, while HIPAA compliance may require specific AWS regions.
- High availability and disaster recovery: Select secondary and backup regions to protect against
  regional outages. If your primary region becomes unavailable, you can fail over to your secondary
  region.
- Feature availability: Some GitLab Dedicated features like ClickHouse Cloud and AWS SES are only
  available in specific regions.
- Performance and latency: Select regions geographically close to your users and infrastructure
  to minimize latency and improve performance.
- Sustainability: If your organization has sustainability commitments, you can consider the carbon
  emissions of different regions. For low-emission region guidance, see how to
  [choose a region based on both business requirements and sustainability goals](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sus_sus_region_a2.html).

> [!note]
> Regions with limitations are clearly marked,
> and you must acknowledge the associated risks before selecting them.

### Supported regions

The following table shows all AWS regions supported by GitLab Dedicated. Any region in this table
can be used as your primary, secondary, or backup region.

> [!warning] US East (N. Virginia) dependency risk
> AWS hosts global identity and access management (IAM) services in the `us-east-1` region.
> An outage in `us-east-1` prevents GitLab from performing operations on tenants, including
> failover to secondary regions. Tenants with `us-east-1` as their primary region experience
> downtime that GitLab cannot mitigate during an outage.
> Consider selecting a different primary region to reduce this risk.

<!-- separator -->

> [!warning] Middle East regions temporarily unavailable
> Both `me-central-1` (UAE) and `me-south-1` (Bahrain) are currently unavailable due to
> significant infrastructure disruptions. Instances in these regions might experience prolonged
> downtime, service degradation, scaling failures, and failover issues.
> For more information, see the [AWS Health Dashboard](https://health.aws.amazon.com/health/status).
> To request access or discuss your options, submit a
> [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

You can deploy your instance in the following AWS regions:

| Region                    | Code             | ClickHouse Cloud                            | AWS SES                                     | Sustainability rating |
| ------------------------- | ---------------- | ------------------------------------------- | ------------------------------------------- | --------------------- |
| Africa (Cape Town)        | `af-south-1`     | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | F                     |
| Asia Pacific (Hong Kong)  | `ap-east-1`      | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | E                     |
| Asia Pacific (Hyderabad)  | `ap-south-2`     | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Jakarta)    | `ap-southeast-3` | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | F                     |
| Asia Pacific (Melbourne)  | `ap-southeast-4` | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | F                     |
| Asia Pacific (Mumbai)     | `ap-south-1`     | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Osaka)      | `ap-northeast-3` | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Seoul)      | `ap-northeast-2` | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Singapore)  | `ap-southeast-1` | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Sydney)     | `ap-southeast-2` | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Asia Pacific (Tokyo)      | `ap-northeast-1` | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Canada (Central)          | `ca-central-1`   | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | A+                    |
| Europe (Frankfurt)        | `eu-central-1`   | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | D                     |
| Europe (Ireland)          | `eu-west-1`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | D                     |
| Europe (London)           | `eu-west-2`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | B                     |
| Europe (Milan)            | `eu-south-1`     | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | C                     |
| Europe (Paris)            | `eu-west-3`      | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | A+                    |
| Europe (Spain)            | `eu-south-2`     | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | B                     |
| Europe (Stockholm)        | `eu-north-1`     | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | A+                    |
| Europe (Zurich)           | `eu-central-2`   | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | A+                    |
| Israel (Tel Aviv)         | `il-central-1`   | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Middle East (Bahrain)     | `me-south-1`     | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | E                     |
| Middle East (UAE)         | `me-central-1`   | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | D                     |
| South America (São Paulo) | `sa-east-1`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | B                     |
| US East (N. Virginia)     | `us-east-1`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | D                     |
| US East (Ohio)            | `us-east-2`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | D                     |
| US West (N. California)   | `us-west-1`      | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | C                     |
| US West (Oregon)          | `us-west-2`      | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | C                     |

If you need a region that is not listed, contact your account representative or
[GitLab Support](https://about.gitlab.com/support/).

#### ClickHouse Cloud

[Advanced analytical features](../../../integration/clickhouse.md) are only available in regions
that support ClickHouse Cloud. Check the supported regions table for ClickHouse availability.

What's included:

- A ClickHouse Cloud database deployed in your tenant's primary region
- AWS PrivateLink connectivity (not publicly accessible)
- Data encrypted in transit and at rest using AES 256 keys and transparent data encryption
- Automatic endpoint allowlisting when you
  [filter outbound requests](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)

Limitations:

- [Customer-managed encryption keys](../encryption.md#customer-managed-encryption) are not supported.
- No SLAs apply. Recovery time objective (RTO) and recovery point objective (RPO) are best efforts.

#### AWS SES

AWS Simple Email Service (SES) is used to send emails from your GitLab instance.
Check the supported regions table for SES availability in each region.

For regions without AWS SES support, you must set up an
[external SMTP mail service](../configure_instance/users_notifications.md#smtp-email-service).

#### Sustainability ratings

> [!note]
> Sustainability ratings are provided by Greenpixie, a third-party cloud sustainability company.
> These ratings do not reflect assessments made by GitLab.
> Ratings reflect data last updated February 4, 2026.

The sustainability rating shows each AWS region's carbon intensity.
Carbon intensity measures the amount of CO2 emitted per unit of electricity consumed (gCO2/kWh).
Use these ratings to choose environmentally responsible regions.

Rating scale:

- A+: Lowest carbon emissions
- A: ~4x-5x higher emissions than A+
- B: ~5x-20x higher emissions than A+
- C: ~20x-25x higher emissions than A+
- D: ~25x-30x higher emissions than A+
- E: ~30x-50x higher emissions than A+
- F: ~50x-300x higher emissions than A+

Greenpixie calculates these grades using long-term regional carbon intensity averages.
Grades help you make sustainable deployment decisions but don't reflect real-time conditions.

## Related topics

- [Create your GitLab Dedicated instance](_index.md)
- [Disaster recovery for GitLab Dedicated](../disaster_recovery.md)
