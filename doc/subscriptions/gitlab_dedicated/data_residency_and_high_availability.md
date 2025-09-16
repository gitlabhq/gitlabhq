---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Data residency, isolation, availability, and scalability.
title: Data residency and high availability
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated offers enterprise-grade infrastructure and performance in a secure and reliable deployment.

## Data residency

During [onboarding](../../administration/dedicated/create_instance/_index.md#step-2-create-your-gitlab-dedicated-instance), you select the AWS region for your instance deployment and data storage.

Some AWS regions have limited features and may not be available for production instances.

### Available AWS regions

GitLab Dedicated is available in select AWS regions that meet specific requirements, including support for io2 volumes.

The following regions are verified for use:

| Region | Code |
|--------|------|
| Africa (Cape Town) | `af-south-1` |
| Asia Pacific (Hyderabad) | `ap-south-2` |
| Asia Pacific (Jakarta) | `ap-southeast-3` |
| Asia Pacific (Mumbai) | `ap-south-1` |
| Asia Pacific (Osaka) | `ap-northeast-3` |
| Asia Pacific (Seoul) | `ap-northeast-2` |
| Asia Pacific (Singapore) | `ap-southeast-1` |
| Asia Pacific (Sydney) | `ap-southeast-2` |
| Asia Pacific (Tokyo) | `ap-northeast-1` |
| Canada (Central) | `ca-central-1` |
| Europe (Frankfurt) | `eu-central-1` |
| Europe (Ireland) | `eu-west-1` |
| Europe (London) | `eu-west-2` |
| Europe (Milan) | `eu-south-1` |
| Europe (Paris) | `eu-west-3` |
| Europe (Stockholm) | `eu-north-1` |
| Europe (Zurich) | `eu-central-2` |
| Israel (Tel Aviv) | `il-central-1` |
| Middle East (Bahrain) | `me-south-1` |
| South America (São Paulo) | `sa-east-1` |
| US East (Ohio) | `us-east-2` |
| US East (N. Virginia) | `us-east-1` |
| US West (N. California) | `us-west-1` |
| US West (Oregon) | `us-west-2` |

For more information about selecting low emission regions, see [Choose Region based on both business requirements and sustainability goals](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sus_sus_region_a2.html).

If you're interested in a region not listed here, contact your account representative or [GitLab Support](https://about.gitlab.com/support/) to inquire about availability.

### Secondary regions with limited support

When setting up GitLab Dedicated, you select a secondary region to host a failover instance for
disaster recovery. Some AWS regions are available only as secondary regions because they do not fully support certain AWS
features that GitLab Dedicated relies on. If GitLab initiates a failover to your secondary region during
a disaster recovery event or test, these limitations impact available features.

The following regions are verified for use as a secondary region but do not support AWS Simple Email Service (SES):

| Region | Code |
|--------|------|
| Asia Pacific (Hong Kong) | `ap-east-1` |
| Asia Pacific (Melbourne) | `ap-southeast-4` |
| Asia Pacific (Malaysia) | `ap-southeast-5` |
| Asia Pacific (Thailand) | `ap-southeast-7` |
| Canada West (Calgary) | `ca-west-1` |
| Europe (Spain) | `eu-south-2` |
| Mexico (Central) | `mx-central-1` |

Without SES support, you cannot send email notifications using the default configuration.
To maintain email functionality in these regions, set up an [external SMTP mail service](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service).

During onboarding, regions with these limitations are clearly marked. You must acknowledge the
associated risks before selecting one as your secondary region.

## Data isolation

As a single-tenant SaaS solution, GitLab Dedicated provides infrastructure-level isolation:

- Your environment is in an AWS account that is separate from other tenants.
- All necessary infrastructure required to host the GitLab application is contained in the account.
- Your data remains within the account boundary.
- Tenant environments are isolated from GitLab.com.

You administer the application while GitLab manages the underlying infrastructure.

## Availability and scalability

GitLab Dedicated uses modified versions of the [Cloud Native Hybrid reference architectures](../../administration/reference_architectures/_index.md#cloud-native-hybrid) with high availability.

During [onboarding](../../administration/dedicated/create_instance/_index.md#step-2-create-your-gitlab-dedicated-instance), GitLab matches you to the closest reference architecture size based on the number of users.

{{< alert type="note" >}}

While the reference architectures serve as a foundation for GitLab Dedicated environments, they are not exhaustive. Additional cloud provider services beyond the standard reference architectures are used to enhance security and stability. As a result, GitLab Dedicated costs differ from standard reference architecture costs.

{{< /alert >}}

## Disaster recovery

During [onboarding](../../administration/dedicated/create_instance/_index.md#step-2-create-your-gitlab-dedicated-instance),
you specify a secondary AWS region for data storage and recovery. Regular backups of all GitLab Dedicated datastores (including databases and Git repositories) are taken, tested, and stored in your chosen secondary region.

{{< alert type="note" >}}

Some secondary regions have [limited support](#secondary-regions-with-limited-support) for AWS features. These limitations may affect disaster recovery time frames and certain features in your failover instance.

{{< /alert >}}

You can also opt to store backup copies in a separate cloud region for increased redundancy.

For more information, see [disaster recovery for GitLab Dedicated](../../administration/dedicated/disaster_recovery.md).
