---
stage: GitLab Dedicated
group: Environment Automation
description: Data residency, isolation, availability, and scalability.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Data residency and high availability
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

GitLab Dedicated offers enterprise-grade infrastructure and performance in a secure and reliable deployment.

## Data residency

During [onboarding](../../administration/dedicated/create_instance.md#step-2-create-your-gitlab-dedicated-instance), you select the AWS region for your instance deployment and data storage.

Some AWS regions have limited features and may not be available for production instances.

### Available AWS regions

GitLab Dedicated is available in select AWS regions that meet specific requirements, including support for io2 volumes.

The following regions are verified for use:

- Asia Pacific (Mumbai)
- Asia Pacific (Seoul)
- Asia Pacific (Singapore)
- Asia Pacific (Sydney)
- Asia Pacific (Tokyo)
- Canada (Central)
- Europe (Frankfurt)
- Europe (Ireland)
- Europe (London)
- Europe (Stockholm)
- US East (Ohio)
- US East (N. Virginia)
- US West (N. California)
- US West (Oregon)
- Middle East (Bahrain)

For more information about selecting low emission regions, see [Choose Region based on both business requirements and sustainability goals](https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sus_sus_region_a2.html).

If you're interested in a region not listed here, contact your account representative or [GitLab Support](https://about.gitlab.com/support/) to inquire about availability.

## Data isolation

As a single-tenant SaaS solution, GitLab Dedicated provides infrastructure-level isolation:

- Your environment is in an AWS account that is separate from other tenants.
- All necessary infrastructure required to host the GitLab application is contained in the account.
- Your data remains within the account boundary.
- Tenant environments are isolated from GitLab.com.

You administer the application while GitLab manages the underlying infrastructure.

## Availability and scalability

GitLab Dedicated uses modified versions of the [Cloud Native Hybrid reference architectures](../../administration/reference_architectures/_index.md#cloud-native-hybrid) with high availability.

During [onboarding](../../administration/dedicated/create_instance.md#step-2-create-your-gitlab-dedicated-instance), GitLab matches you to the closest reference architecture size based on the number of users.

NOTE:
While the reference architectures serve as a foundation for GitLab Dedicated environments, they are not exhaustive. Additional cloud provider services beyond the standard reference architectures are used to enhance security and stability. As a result, GitLab Dedicated costs differ from standard reference architecture costs.

For more information, see the [Current Service Level Objective](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/#current-service-level-objective).

## Disaster recovery

During [onboarding](../../administration/dedicated/create_instance.md#step-2-create-your-gitlab-dedicated-instance),
you specify a secondary AWS region for data storage and recovery. Regular backups of all GitLab Dedicated datastores (including databases and Git repositories) are taken, tested, and stored in your chosen secondary region.

You can also opt to store backup copies in a separate cloud region for increased redundancy.

For more information, including Recovery Point Objective (RPO) and Recovery Time Objective (RTO) targets, see the [disaster recovery plan](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/#disaster-recovery-plan).
