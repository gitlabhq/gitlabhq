---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Single-tenant SaaS solution for government agencies and regulated industries.
title: GitLab Dedicated for Government
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated for Government

{{< /details >}}

GitLab Dedicated for Government is a single-tenant SaaS solution designed for
government agencies and organizations in regulated industries.

It provides the following:

- [FedRAMP Moderate authorized](https://marketplace.fedramp.gov/products/FR2411959145?cache=true) with Authority to Operate (ATO)
- Isolated infrastructure in a dedicated AWS account deployed on [AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html) in the US-West region
- GitLab manages all operations and compliance requirements with government-specialized teams and processes
- Access to complete DevSecOps platform capabilities while maintaining FedRAMP compliance

This offering removes the complexity of compliance infrastructure management so your teams can focus on development.

## Security architecture

Your instance includes the following security controls:

- FedRAMP Moderate compliance with continuous monitoring aligned to federal requirements
- Data sovereignty guaranteed through AWS GovCloud infrastructure in the US-West region
- Isolated infrastructure in a dedicated AWS account separate from all other tenants
- Encryption standards that meet FIPS requirements for data at rest and in transit
- Access controls that follow principle of least privilege with comprehensive audit trails

### Data residency and infrastructure isolation

To meet US data residency requirements, your instance is deployed
on [AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html) in the US-West region.

All customer data, including repositories, databases, artifacts, and backups, remains within the AWS GovCloud boundary.
Your environment includes all infrastructure necessary to host the GitLab application with complete isolation from GitLab.com.

Data is encrypted at rest and in transit using FIPS-compliant encryption standards.

### Access controls

Your environment is protected through multiple layers of security controls:

- Engineers do not have direct access to your tenant environment and operate with the minimum permissions required for their role.
- Infrastructure is monitored 24 hours a day, 7 days a week for security threats and anomalies.
- All access and changes are logged and reviewed by the GitLab Security Incident Response Team.
- Access requests follow formal security policies and approval workflows aligned with government compliance requirements.

## Available features

GitLab Dedicated for Government provides the complete GitLab Ultimate feature set
with the exception of [unavailable features](#unavailable-features).

These features are designed to work within FedRAMP compliance and government security frameworks.

### Availability and scalability

Your instance leverages modified versions of the
[cloud native hybrid reference architectures](../../administration/reference_architectures/_index.md#cloud-native-hybrid)
with high availability enabled.

When [onboarding](../../administration/dedicated/create_instance/_index.md#step-2-create-your-gitlab-dedicated-instance),
GitLab matches you to the closest reference architecture size based on your number of users.

> [!note]
> The published [reference architectures](../../administration/reference_architectures/_index.md) serve as a foundation.
> GitLab Dedicated for Government extends these with additional AWS services for enhanced security and compliance,
> which means costs differ from standard reference architecture estimates.

### Disaster recovery

GitLab backs up all your datastores, including databases and Git repositories.
These backups are tested and stored securely in a separate cloud region by default for added redundancy.

### Authentication and authorization

You can configure single sign-on (SSO) using:

- [SAML](../../administration/dedicated/configure_instance/authentication/saml.md)
- [OpenID Connect (OIDC)](../../administration/dedicated/configure_instance/authentication/openid_connect.md)

Your instance acts as the service provider,
and you provide the necessary configuration for GitLab to communicate with your Identity Provider (IdP).

You can configure multiple identity providers for your instance.

### Email delivery

Email is sent using [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/).
The connection to Amazon SES is encrypted.

To send application email using an SMTP server instead of Amazon SES,
you can [configure your own email service](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service).

### Advanced search

[Advanced search](../../user/search/advanced_search.md) capabilities are included.
You can search across your entire GitLab instance including code, work items, merge requests, and more.

## Unavailable features

To maintain FedRAMP certification and meet government security requirements,
some GitLab features are not available in GitLab Dedicated for Government.

### Authentication, security, and networking

| Feature                              | Alternative |
| ------------------------------------ | ----------- |
| LDAP or Kerberos authentication      | Use SAML or OIDC with your identity provider |
| FortiAuthenticator or FortiToken 2FA | Use identity provider MFA |

### Communication and collaboration

| Feature        | Alternative |
| -------------- | ----------- |
| Reply-by email | Use web interface |
| Service Desk   | Use issue tracking |
| Mattermost     | Use external chat tools |

### Development and AI features

| Feature                                                            | Alternative |
| ------------------------------------------------------------------ | ----------- |
| Some [GitLab Duo AI capabilities](../../user/gitlab_duo/_index.md) | See [supported AI features](../../user/gitlab_duo/_index.md) |
| [Server-side Git hooks](../../administration/server_hooks.md)      | Use [push rules](../../user/project/repository/push_rules.md) or [webhooks](../../user/project/integrations/webhooks.md) |
| Features configured outside of the GitLab user interface           | Contact support |

### Operational features

The following operational features are not available:

- Geo
- Self-serve purchasing and configuration
- Support for deploying to non-AWS cloud providers, such as GCP or Azure
- Pre-production environments

### Feature flags

Feature flags control which features are available in your instance:

- Only features with flags enabled by default are available
- Features with flags disabled by default are not available
- You cannot modify feature flags

## Service operations

GitLab manages all maintenance, monitoring, and support for your instance using government-specific operational processes.
These processes prioritize compliance, security, and stability throughout all maintenance and support activities.

### Maintenance

Your instance receives regular maintenance:

- Monthly upgrades with the latest patch release during your preferred weekly window
- Emergency maintenance for critical security issues

### Releases and versions

Your instance runs one release behind the latest GitLab version.
For example, if the latest version is 16.8, your instance runs 16.7.

This approach provides stability while you receive critical security patches through emergency maintenance.
Features are rolled out after compliance and change review processes.

### Service level agreement

Your instance maintains a service level agreement (SLA) of 99.9% monthly availability.
GitLab uses internal service level objectives (SLOs) to support delivery of this SLA commitment.

The following targets apply:

- Recovery point objective (RPO) target: 4 hours maximum data loss window in a disaster recovery scenario
- Recovery time objective (RTO) target: Service restoration is prioritized by incident severity and impact

GitLab works to restore service as quickly as possible while ensuring data integrity and security.

## Contact sales

Ready to get started? [Contact our sales team](https://about.gitlab.com/sales/dedicated/)
to discuss your requirements and learn how we can support your organization's compliance and security needs.
