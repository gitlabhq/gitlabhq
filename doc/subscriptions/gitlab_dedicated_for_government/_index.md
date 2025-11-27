---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Single-tenant SaaS solution for government agencies.
title: GitLab Dedicated for Government
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated for Government

{{< /details >}}

GitLab Dedicated for Government is a single-tenant SaaS solution designed for
government agencies and organizations with government compliance requirements.

Key features include:

- [FedRAMP Moderate Authority to Operate (ATO)](https://marketplace.fedramp.gov/products/FR2411959145?cache=true)
- AWS GovCloud deployment
- High availability and disaster recovery
- Enhanced security architecture

GitLab Dedicated for Government removes platform management overhead so your teams can focus on mission delivery.
GitLab teams manage all maintenance and operations of each isolated instance.
You access the latest product improvements while meeting compliance standards.

## Government-specific capabilities

GitLab Dedicated for Government includes government-specific enhancements:

Security and compliance:

- Compliance monitoring aligned with FedRAMP requirements
- Data sovereignty on AWS GovCloud infrastructure
- Advanced access controls and audit capabilities

Authentication:

- Integration with government identity providers
- Multi-factor authentication through your identity provider

Managed operations:

- GitLab handles all infrastructure management
- Compliance-focused maintenance and upgrade processes

## Available features

### Data residency

To meet US data residency requirements, GitLab Dedicated for Government is deployed
on [AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html) in the US-West region.

All customer data, including repositories, databases, artifacts, and backups, remains within the AWS GovCloud boundary.

### Advanced search

{{< alert type="note" >}}

This feature is currently available for use in production environments as a preview and continues to be enhanced.

{{< /alert >}}

GitLab Dedicated for Government includes [advanced search](../../user/search/advanced_search.md) capabilities.
You can search across your entire GitLab instance including code, issues, merge requests, and more.

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

GitLab Dedicated supports [SAML](../../administration/dedicated/configure_instance/authentication/saml.md) and [OpenID Connect (OIDC)](../../administration/dedicated/configure_instance/authentication/openid_connect.md) providers for single sign-on (SSO).

You can configure single sign-on (SSO) using the supported providers for authentication. Your instance acts as the service provider, and you provide the necessary configuration for GitLab to communicate with your Identity Providers (IdPs).

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

Inside tenant accounts, GitLab leverages Intrusion Detection and Malware Scanning capabilities from AWS GuardDuty.
Infrastructure logs are monitored by the GitLab Security Incident Response Team to detect anomalous events.

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
  - View the [list of AI features to see which ones are supported](../../user/gitlab_duo/_index.md).
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

GitLab uses [feature flags](../../administration/feature_flags/_index.md) to support the development and rollout of new or experimental features.
In GitLab Dedicated for Government:

- Features behind feature flags that are **enabled by default** are available.
- Features behind feature flags that are **disabled by default** are not available and cannot be enabled by administrators.

Features behind flags that are disabled by default are not ready for production use and therefore unsafe for GitLab Dedicated for Government.

When a feature becomes generally available and the flag is enabled or removed, the feature becomes available in GitLab Dedicated for Government in the same GitLab version.

## Service level agreement

The following service level agreement (SLA) targets are defined for GitLab Dedicated for Government:

- Recovery point objective (RPO) target: 4 hours maximum data loss window in a disaster recovery scenario.
- Recovery time objective (RTO) target: Service restoration is prioritized by incident severity and impact.
  GitLab works to restore service as quickly as possible while ensuring data integrity and security.
- Service level objective (SLO) target: Specific availability targets are determined based on FedRAMP requirements and operational best practices.

## Contact sales

For more information about GitLab Dedicated for Government, [contact sales](https://about.gitlab.com/dedicated/) and talk to an expert.
