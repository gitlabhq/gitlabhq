---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Available AWS regions, data isolation, and high availability capabilities for GitLab Dedicated.
title: Data residency and high availability
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated provides data residency control, infrastructure isolation,
and high availability through single-tenant AWS deployments.

## Data isolation

GitLab Dedicated isolates your data and infrastructure from other tenants through single-tenant architecture:

- Your environment runs in an AWS account separate from other tenants.
- All infrastructure required to host GitLab is contained within your account boundary.
- Your data remains within your account and is isolated from GitLab.com.
- You administer the application while GitLab manages the underlying infrastructure.

## Data residency

During [onboarding](_index.md#step-2-create-your-gitlab-dedicated-instance),
you select AWS regions for your instance deployment, data storage,
and disaster recovery to meet compliance, performance, and availability requirements.

### Primary regions

You can deploy your instance in the following AWS regions:

| Region                    | Code | ClickHouse Cloud |
| ------------------------- | ---- | ---------------- |
| Africa (Cape Town)        | `af-south-1` | {{< icon name="check-circle-filled" >}} Yes |
| Asia Pacific (Hyderabad)  | `ap-south-2` | {{< icon name="dash-circle" >}} No |
| Asia Pacific (Jakarta)    | `ap-southeast-3` | {{< icon name="dash-circle" >}} No |
| Asia Pacific (Mumbai)     | `ap-south-1` | {{< icon name="check-circle-filled" >}} Yes |
| Asia Pacific (Osaka)      | `ap-northeast-3` | {{< icon name="dash-circle" >}} No |
| Asia Pacific (Seoul)      | `ap-northeast-2` | {{< icon name="check-circle-filled" >}} Yes |
| Asia Pacific (Singapore)  | `ap-southeast-1` | {{< icon name="check-circle-filled" >}} Yes |
| Asia Pacific (Sydney)     | `ap-southeast-2` | {{< icon name="check-circle-filled" >}} Yes |
| Asia Pacific (Tokyo)      | `ap-northeast-1` | {{< icon name="check-circle-filled" >}} Yes |
| Canada (Central)          | `ca-central-1` | {{< icon name="check-circle-filled" >}} Yes |
| Europe (Frankfurt)        | `eu-central-1` | {{< icon name="check-circle-filled" >}} Yes |
| Europe (Ireland)          | `eu-west-1` | {{< icon name="check-circle-filled" >}} Yes |
| Europe (London)           | `eu-west-2` | {{< icon name="check-circle-filled" >}} Yes |
| Europe (Milan)            | `eu-south-1` | {{< icon name="dash-circle" >}} No |
| Europe (Paris)            | `eu-west-3` | {{< icon name="dash-circle" >}} No |
| Europe (Stockholm)        | `eu-north-1` | {{< icon name="check-circle-filled" >}} Yes |
| Europe (Zurich)           | `eu-central-2` | {{< icon name="dash-circle" >}} No |
| Israel (Tel Aviv)         | `il-central-1` | {{< icon name="dash-circle" >}} No |
| Middle East (Bahrain)     | `me-south-1` | {{< icon name="dash-circle" >}} No |
| South America (São Paulo) | `sa-east-1` | {{< icon name="check-circle-filled" >}} Yes |
| US East (Ohio)            | `us-east-2` | {{< icon name="check-circle-filled" >}} Yes |
| US East (N. Virginia)     | `us-east-1` | {{< icon name="check-circle-filled" >}} Yes |
| US West (N. California)   | `us-west-1` | {{< icon name="dash-circle" >}} No |
| US West (Oregon)          | `us-west-2` | {{< icon name="check-circle-filled" >}} Yes |

For low emission region guidance,
see [choose a region based on both business requirements and sustainability goals](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sus_sus_region_a2.html).

If you need a region that isn't listed, contact your account representative or [GitLab Support](https://about.gitlab.com/support/).

#### ClickHouse Cloud

ClickHouse Cloud provides [advanced analytical features](../../../integration/clickhouse.md)
and is only available in specific AWS regions.

If you select a primary region that doesn't support ClickHouse Cloud,
advanced analytical features are not available for your instance.

GitLab Dedicated instances in supported regions include a ClickHouse Cloud database deployed in your tenant's
primary region. The database connects through AWS PrivateLink and is not publicly accessible.
Your data is encrypted in transit and at rest using cloud provider-managed AES 256 keys and 
transparent data encryption.

When you configure your GitLab Dedicated instance to
[filter outbound requests](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains),
the ClickHouse endpoint address is automatically added to the allowlist.

ClickHouse on GitLab Dedicated has the following limitations:

- [Bring your own key (BYOK)](../encryption.md#bring-your-own-key-byok) is not supported.
- No SLAs apply. Recovery time objective (RTO) and recovery point objective (RPO) are best efforts.

### Secondary regions with limited support

You can select AWS regions as secondary regions for disaster recovery,
but they don't support all AWS features that GitLab Dedicated uses.
Some features are unavailable if failover occurs to your secondary region.

The following regions are available only as secondary regions and don't support AWS Simple Email Service (SES):

| Region                   | Code |
| ------------------------ | ---- |
| Asia Pacific (Hong Kong) | `ap-east-1` |
| Asia Pacific (Melbourne) | `ap-southeast-4` |
| Asia Pacific (Malaysia)  | `ap-southeast-5` |
| Asia Pacific (Thailand)  | `ap-southeast-7` |
| Canada West (Calgary)    | `ca-west-1` |
| Europe (Spain)           | `eu-south-2` |
| Mexico (Central)         | `mx-central-1` |

Without SES support, you cannot send email notifications using the default configuration.
To maintain email functionality in these regions,
set up an [external SMTP mail service](../configure_instance/users_notifications.md#smtp-email-service).

During onboarding, regions with limitations are clearly marked.
You must acknowledge the associated risks before selecting one as your secondary region.

## Availability and scalability

GitLab Dedicated uses modified versions of the
[Cloud Native Hybrid reference architectures](../../../administration/reference_architectures/_index.md#cloud-native-hybrid)
with high availability configurations.

GitLab matches your instance to the closest reference architecture size based on your number of users.

{{< alert type="note" >}}

GitLab Dedicated environments use additional cloud provider services beyond
the standard reference architectures to enhance security and stability.
As a result, GitLab Dedicated costs differ from standard reference architecture costs.

{{< /alert >}}

## Related topics

- [Disaster recovery for GitLab Dedicated](../disaster_recovery.md)
- [GitLab Dedicated architecture](../architecture.md)
