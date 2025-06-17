---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Available features and benefits.
title: GitLab Dedicated for Government
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated for Government is a fully isolated, single-tenant SaaS solution that is:

- Hosted and managed by GitLab, Inc.
- Deployed on [AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html) in the US West region.

GitLab Dedicated for Government removes the overhead of platform management to increase your operational efficiency, reduce risk, and enhance the speed and agility of your organization. Each GitLab Dedicated for Government instance is highly available with disaster recovery. GitLab teams fully manage the maintenance and operations of each isolated instance, so customers can access our latest product improvements while meeting the most complex compliance standards. It is built on the same tech stack as GitLab Dedicated and adapted for US government usage.

It's the offering of choice for government agencies and related organizations that need to meet government standards such as FedRAMP compliance.

## Available features

### Data residency

GitLab Dedicated for Government is available in AWS GovCloud and meets US data residency requirements.

### Advanced search

{{< details >}}

- Status: Beta

{{< /details >}}

GitLab Dedicated for Government uses [advanced search](../../user/search/advanced_search.md).

### Availability and scalability

GitLab Dedicated for Government leverages modified versions of the [cloud native hybrid reference architectures](../../administration/reference_architectures/_index.md#cloud-native-hybrid) with high availability enabled. When [onboarding](../../administration/dedicated/create_instance/_index.md#step-2-create-your-gitlab-dedicated-instance), GitLab matches you to the closest reference architecture size based on your number of users.

{{< alert type="note" >}}

The published [reference architectures](../../administration/reference_architectures/_index.md) act as a starting point in defining the cloud resources deployed inside GitLab Dedicated for Government environments, but they are not comprehensive. GitLab Dedicated leverages additional Cloud Provider services beyond what's included in the standard reference architectures for enhanced security and stability of the environment. Therefore, GitLab Dedicated for Government costs differ from standard reference architecture costs.

{{< /alert >}}

#### Disaster recovery

GitLab Dedicated regularly backs up all datastores, including databases and Git repositories. These backups are tested and stored securely. For added redundancy, you can store backup copies in a separate cloud region.

### Security

#### Authentication and authorization

{{< details >}}

- Status: Beta

{{< /details >}}

GitLab Dedicated for Government supports instance-level [SAML OmniAuth](../../integration/saml.md). Your GitLab Dedicated instance acts as the service provider, and you must provide the necessary [configuration](../../integration/saml.md#configure-saml-support-in-gitlab) for GitLab to communicate with your IdP.

SAML [request signing](../../integration/saml.md#sign-saml-authentication-requests-optional), [group sync](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync), and [SAML groups](../../integration/saml.md#configure-users-based-on-saml-group-membership) are supported. For more information on how to configure SAML for your instance, see [SAML](../../administration/dedicated/configure_instance/saml.md).

#### Encryption

Data is encrypted at rest and in transit using the latest encryption standards.

#### SMTP

{{< details >}}

- Status: Beta

{{< /details >}}

Email sent from GitLab Dedicated uses [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/). The connection to Amazon SES is encrypted.

To send application email using an SMTP server instead of Amazon SES, you can [configure your own email service](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service).

#### Isolation

As a single-tenant SaaS solution, GitLab Dedicated for Government provides infrastructure-level isolation of your GitLab environment. Your environment is placed into a separate AWS account from other tenants. This AWS account contains all of the underlying infrastructure necessary to host the GitLab application and your data stays within the account boundary. You administer the application while GitLab manages the underlying infrastructure. Tenant environments are also completely isolated from GitLab.com.

#### Access controls

GitLab Dedicated for Government implements strict access controls to protect your environment:

- Follows the principle of least privilege, which grants only the minimum permissions necessary.
- Places tenant AWS accounts under a top-level GitLab Dedicated for Government AWS parent organization.
- Restricts access to the AWS organization to select GitLab team members.
- Implements comprehensive security policies and access requests for user accounts.
- Uses a single Hub account for automated actions and emergency access.
- Uses the GitLab Dedicated Control Plane with the Hub account to perform automated actions over tenant accounts.

GitLab Dedicated engineers do not have direct access to customer tenant environments.
In [break glass](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/blob/main/engineering/breaking_glass.md)
situations, where access to resources in the tenant environment is required to
address a high-severity issue, GitLab engineers must go through the Hub account
to manage those resources. This is done with an approval process, and after permission
is granted, the engineer assumes an IAM role on a temporary basis to access
tenant resources through the Hub account. All actions in the hub account and
tenant account are logged to CloudTrail.

Inside tenant accounts, GitLab leverages Intrusion Detection and Malware Scanning capabilities from AWS GuardDuty. Infrastructure logs are monitored by the GitLab Security Incident Response Team to detect anomalous events.

### Maintenance

GitLab leverages one weekly maintenance window to keep your instance up to date, fix security issues, and ensure the overall reliability and performance of your environment.

#### Upgrades

GitLab performs monthly upgrades to your instance with the latest patch release during your preferred [maintenance window](../../administration/dedicated/maintenance.md#maintenance-windows) tracking one release behind the latest GitLab release. For example, if the latest version of GitLab available is 16.8, GitLab Dedicated runs on 16.7.

#### Unscheduled maintenance

GitLab may conduct [unscheduled maintenance](../../administration/dedicated/maintenance.md#emergency-maintenance) to address high-severity issues affecting the security, availability, or reliability of your instance.

### Application

GitLab Dedicated for Government comes with the GitLab Self-Managed [Ultimate feature set](https://about.gitlab.com/pricing/feature-comparison/) with the exception of the [unsupported features](#unavailable-features) listed below.

## Unavailable features

### Application features

The following GitLab application features are not available:

- LDAP, smart card, or Kerberos authentication
- Multiple login providers
- FortiAuthenticator, or FortiToken 2FA
- Reply-by email
- Service Desk
- Some GitLab Duo AI capabilities
  - View the [list of AI features to see which ones are supported](../../user/ai_features.md).
  - For more information, see [category direction - GitLab Dedicated](https://about.gitlab.com/direction/gitlab_dedicated/#supporting-ai-features-on-gitlab-dedicated).
- Features other than [available features](#available-features) that must be configured outside of the GitLab user interface
- Any functionality or feature behind a Feature Flag that is toggled `off` by default.

The following features will not be supported:

- Mattermost
- [Server-side Git hooks](../../administration/server_hooks.md).
  GitLab Dedicated for Government is a SaaS service, and access to the underlying infrastructure is only available to GitLab Inc. team members. Due to the nature of server side configuration, there is a possible security concern of running arbitrary code on Dedicated services, as well as the possible impact that can have on the service SLA. Use the alternative [push rules](../../user/project/repository/push_rules.md) or [webhooks](../../user/project/integrations/webhooks.md) instead.

### Operational features

The following operational features are not available:

- Geo
- Self-serve purchasing and configuration
- Multiple login providers
- Support for deploying to non-AWS cloud providers, such as GCP or Azure
- Switchboard
- Pre-Production instance

### Feature flags

GitLab uses [feature flags](../../administration/feature_flags.md) to support the development and rollout of new or experimental features.
In GitLab Dedicated for Government:

- Features behind feature flags that are **enabled by default** are available.
- Features behind feature flags that are **disabled by default** are not available and cannot be enabled by administrators.

Features behind flags that are disabled by default are not ready for production use and therefore unsafe for GitLab Dedicated for Government.

When a feature becomes generally available and the flag is enabled or removed, the feature becomes available in GitLab Dedicated for Government in the same GitLab version.

## Service Level Agreement

The following Service Level Agreement (SLA) targets are defined for GitLab Dedicated for Government:

- Recovery Point Objective (RPO) target: 4 hours.
- Recovery Time Objective (RTO) target: There is no target for RTO. Service is restored on a best-effort basis.
- Service Level Objective (SLO) target: There is no target for SLO.

## Contact sales

For more information about GitLab Dedicated for Government, [contact sales](https://about.gitlab.com/dedicated/) and talk to an expert.
