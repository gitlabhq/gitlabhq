---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Available features and benefits.
title: GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated is a single-tenant SaaS solution that is:

- Fully isolated.
- Deployed in your preferred AWS cloud region.
- Hosted and maintained by GitLab.

Each instance provides:

- [High availability](data_residency_and_high_availability.md) with disaster recovery.
- [Regular updates](maintenance.md) with the latest features.
- Enterprise-grade security measures.

With GitLab Dedicated, you can:

- Increase operational efficiency.
- Reduce infrastructure management overhead.
- Improve organizational agility.
- Meet strict compliance requirements.

## Available features

This section lists the key features that are available for GitLab Dedicated.

### Security

GitLab Dedicated provides the following security features to protect your data and control access to your instance.

#### Authentication and authorization

GitLab Dedicated supports [SAML](../../administration/dedicated/configure_instance/saml.md) and [OpenID Connect (OIDC)](../../administration/dedicated/configure_instance/openid_connect.md) providers for single sign-on (SSO).

You can configure single sign-on (SSO) using the supported providers for authentication. Your instance acts as the service provider, and you provide the necessary configuration for GitLab to communicate with your Identity Providers (IdPs).

#### Secure networking

Two connectivity options are available:

- Public connectivity with IP allowlists: By default, your instance is publicly accessible. You can [configure an IP allowlist](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist) to restrict access to specified IP addresses.
- Private connectivity with AWS PrivateLink: You can configure [AWS PrivateLink](https://aws.amazon.com/privatelink/) for [inbound](../../administration/dedicated/configure_instance/network_security.md#inbound-private-link) and [outbound](../../administration/dedicated/configure_instance/network_security.md#outbound-private-link) connections.

For private connections to internal resources using non-public certificates, you can also [specify trusted certificates](../../administration/dedicated/configure_instance/network_security.md#custom-certificates).

#### Data encryption

Data is encrypted at rest and in transit using the latest encryption standards.

Optionally, you can use your own AWS Key Management Service (KMS) encryption key for data at rest. This option gives you full control over the data you store in GitLab.

For more information, see [encrypted data at rest (BYOK)](../../administration/dedicated/encryption.md#encrypted-data-at-rest).

#### Email service

By default, [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/) is used to send emails securely. As an alternative, you can [configure your own email service](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service) using SMTP.

### Compliance

GitLab Dedicated adheres to various regulations, certifications, and compliance frameworks to ensure the security, and reliability of your data.

#### View compliance and certification details

You can view compliance and certification details, and download compliance artifacts from the [GitLab Dedicated Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated).

#### Access controls

GitLab Dedicated implements strict access controls to protect your environment:

- Follows the principle of least privilege, which grants only the minimum permissions necessary.
- Restricts access to the AWS organization to select GitLab team members.
- Implements comprehensive security policies and access requests for user accounts.
- Uses a single Hub account for automated actions and emergency access.
- GitLab Dedicated engineers do not have direct access to customer environments.

In [emergency situations](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/incident-management/-/blob/main/procedures/break-glass.md#break-glass-procedure), GitLab engineers must:

1. Use the Hub account to access customer resources.
1. Request access through an approval process.
1. Assume a temporary IAM role through the Hub account.

All actions in the Hub and tenant accounts are logged to CloudTrail.

#### Monitoring

In tenant accounts, GitLab Dedicated uses:

- AWS GuardDuty for intrusion detection and malware scanning.
- Infrastructure log monitoring by the GitLab Security Incident Response Team to detect anomalous events.

#### Audit and observability

You can access [application logs](../../administration/dedicated/monitor.md) for auditing and observability purposes. These logs provide insights into system activities and user actions, helping you monitor your instance and maintain compliance requirements.

### Bring your own domain

You can use your own hostname to access your GitLab Dedicated instance. Instead of `tenant_name.gitlab-dedicated.com`, you can use a hostname for a domain that you own, like `gitlab.my-company.com`. Optionally, you can also provide a custom hostname for the bundled container registry and KAS services for your GitLab Dedicated instance. For example, `gitlab-registry.my-company.com` and `gitlab-kas.my-company.com`.

Add a custom hostname to:

- Increase control over branding
- Avoid having to migrate away from an existing domain already configured for a GitLab Self-Managed instance

When you add a custom hostname:

- The hostname is included in the external URL used to access your instance.
- Any connections to your instance using the previous domain names are no longer available.

For more information about using a custom hostname for your GitLab Dedicated instance, see [bring your own domain (BYOD)](../../administration/dedicated/configure_instance/network_security.md#bring-your-own-domain-byod).

{{< alert type="note" >}}

Custom hostnames for GitLab Pages are not supported. If you use GitLab Pages, the URL to access the Pages site for your GitLab Dedicated instance would be `tenant_name.gitlab-dedicated.site`.

{{< /alert >}}

### Application

GitLab Dedicated comes with the self-managed [Ultimate feature set](https://about.gitlab.com/pricing/feature-comparison/) with a small number of exceptions. For more information, see [Unavailable features](#unavailable-features).

#### Advanced search

GitLab Dedicated uses the [advanced search functionality](../../integration/advanced_search/elasticsearch.md).

#### GitLab Pages

You can use [GitLab Pages](../../user/project/pages/_index.md) on GitLab Dedicated to host your static website. The domain name is `tenant_name.gitlab-dedicated.site`, where `tenant_name` is the same as your instance URL.

{{< alert type="note" >}}

Custom domains for GitLab Pages are not supported. For example, if you added a custom domain named `gitlab.my-company.com`, the URL to access the Pages site for your GitLab Dedicated instance would still be `tenant_name.gitlab-dedicated.site`.

{{< /alert >}}

You can control access to your Pages website with:

- [GitLab Pages access control](../../user/project/pages/pages_access_control.md).
- [IP allowlists](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist). Any existing IP allowlists for your GitLab Dedicated instances are applied.

GitLab Pages for Dedicated:

- Is enabled by default.
- Only works in the primary site if [Geo](../../administration/geo/_index.md) is enabled.
- Is not included as part of instance migrations to GitLab Dedicated.

#### Hosted runners

[Hosted runners for GitLab Dedicated](../../administration/dedicated/hosted_runners.md) allow you to scale CI/CD workloads with no maintenance overhead.

#### Self-managed runners

As an alternative to using hosted runners, you can use your own runners for your GitLab Dedicated instance.

To use self-managed runners, install [GitLab Runner](https://docs.gitlab.com/runner/install/) on infrastructure that you own or manage.

#### OpenID Connect and SCIM

You can use [SCIM for user management](../../api/scim.md) or [GitLab as an OpenID Connect identity provider](../../integration/openid_connect_provider.md) while maintaining IP restrictions to your instance.

To use these features with IP allowlists:

- [Enable SCIM provisioning for your IP allowlist](../../administration/dedicated/configure_instance/network_security.md#enable-scim-provisioning-for-your-ip-allowlist)
- [Enable OpenID Connect for your IP allowlist](../../administration/dedicated/configure_instance/network_security.md#enable-openid-connect-for-your-ip-allowlist)

### Pre-production environments

GitLab Dedicated supports pre-production environments that match the configuration of production environments. You can use pre-production environments to:

- Test new features before implementing them in production.
- Test configuration changes before applying them in production.

Pre-production environments must be purchased as an add-on to your GitLab Dedicated subscription, with no additional licenses required.

The following capabilities are available:

- Flexible sizing: Match the size of your production environment or use a smaller reference architecture.
- Version consistency: Runs the same GitLab version as your production environment.

Limitations:

- Single-region deployment only.
- No SLA commitment.
- Cannot run newer versions than production.

## Unavailable features

This section lists the features that are not available for GitLab Dedicated.

### Authentication and security

| Feature                                       | Description                                                           | Impact                                                       |
| --------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| LDAP authentication                           | Authentication using corporate LDAP/Active Directory credentials.     | Must use GitLab-specific passwords or access tokens instead. |
| Smart card authentication                     | Authentication using smart cards for enhanced security.               | Cannot use existing smart card infrastructure.               |
| Kerberos authentication                       | Single sign-on authentication using Kerberos protocol.                | Must authenticate separately to GitLab.                      |
| Multiple login providers                      | Configuration of multiple OAuth/SAML providers (Google, GitHub).      | Limited to a single identity provider.                       |
| FortiAuthenticator/FortiToken 2FA             | Two-factor authentication using Fortinet security solutions.          | Cannot integrate existing Fortinet 2FA infrastructure.       |
| Git clone using HTTPS with username/password  | Git operations using username and password authentication over HTTPS. | Must use access tokens for Git operations.                   |
| [Sigstore](../../ci/yaml/signing_examples.md) | Keyless signing and verification for software supply chain security.  | Must use traditional code signing methods.                   |

### Communication and collaboration

| Feature        | Description                                                         | Impact                                                     |
| -------------- | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| Reply by email | Respond to GitLab notifications and discussions through email.      | Must use GitLab web interface to respond.                  |
| Service Desk   | Ticketing system for external users to create issues through email. | External users must have GitLab accounts to create issues. |

### Development and AI features

| Feature                                | Description                                                                          | Impact                                       |
| -------------------------------------- | ------------------------------------------------------------------------------------ | -------------------------------------------- |
| Some GitLab Duo AI capabilities        | AI-powered features for code suggestions, vulnerability detection, and productivity. | Limited AI assistance for development tasks. |
| Features behind disabled feature flags | Experimental or unreleased features disabled by default.                             | Cannot access features in development.       |

For more information about AI features, see [GitLab Duo](../../user/gitlab_duo/_index.md).

#### Feature flags

GitLab uses [feature flags](../../administration/feature_flags/_index.md) to support the
development and rollout of new or experimental features. In GitLab Dedicated:

- Features behind feature flags that are enabled by default are available.
- Features behind feature flags that are disabled by default are not available and
  cannot be enabled by administrators.

Features behind flags that are disabled by default are not ready for production use and
therefore unsafe for GitLab Dedicated.

When a feature becomes generally available and the flag is enabled or removed, the feature
becomes available in GitLab Dedicated in the same GitLab version. GitLab Dedicated follows
its own [release schedule](maintenance.md) for version deployments.

### GitLab Pages

| Feature                      | Description                                                     | Impact                                                                 |
| ---------------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Custom domains               | Host GitLab Pages sites on custom domain names.                 | Pages sites accessible only using `tenant_name.gitlab-dedicated.site`. |
| PrivateLink access           | Private network access to GitLab Pages through AWS PrivateLink. | Pages sites must be accessed over public internet.                     |
| Namespaces in URL path       | Organize Pages sites with namespace-based URL structure.        | Limited URL organization options.                                      |
| Let's Encrypt integration    | Automatic SSL certificate provisioning for Pages sites.         | Must manage SSL certificates manually.                                 |
| Reduced authentication scope | Fine-grained access controls for Pages sites.                   | Less flexible authentication options.                                  |
| Running Pages behind a proxy | Deploy Pages sites behind reverse proxy configurations.         | Limited deployment architecture options.                               |

### Operational features

The following operational features are not available:

- Multiple Geo secondaries (Geo replicas) beyond the secondary site included by default
- [Geo proxying](../../administration/geo/secondary_proxy/_index.md) and using a unified URL
- Self-serve purchasing and configuration
- Support for deploying to non-AWS cloud providers, such as GCP or Azure
- Observability dashboard in Switchboard

### Features that require server access

The following features require direct server access and cannot be configured:

| Feature                                                       | Description                                                        | Impact                                                                                                                    |
| ------------------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| [Mattermost](../../integration/mattermost/_index.md)          | Integrated team chat and collaboration platform.                   | Use external chat solutions.                                                                                              |
| [Server-side Git hooks](../../administration/server_hooks.md) | Custom scripts that run on Git events (pre-receive, post-receive). | Use [push rules](../../user/project/repository/push_rules.md) or [webhooks](../../user/project/integrations/webhooks.md). |

{{< alert type="note" >}}

Access to the underlying infrastructure is only available to GitLab team members.
Due to the server-side configuration, there is a security concern with running arbitrary code on services,
and the possible impact on the service SLA. As an alternative, use [push rules](../../user/project/repository/push_rules.md)
or [webhooks](../../user/project/integrations/webhooks.md) instead.

{{< /alert >}}

## Service level availability

GitLab Dedicated maintains a monthly service level objective of 99.5% availability.

Service level availability measures the percentage of time that GitLab Dedicated is available for use during a calendar month. GitLab calculates availability based on the following core services:

| Service area       | Included features                                                                 |
| ------------------ | --------------------------------------------------------------------------------- |
| Web interface      | GitLab issues, merge requests, CI job logs, GitLab API, Git operations over HTTPS |
| Container Registry | Registry HTTPS requests                                                           |
| Git operations     | Git push, pull, and clone operations over SSH                                     |

### Service level exclusions

The following are not included in service level availability calculations:

- Service interruptions caused by customer misconfigurations
- Issues with customer or cloud provider infrastructure outside of GitLab control
- Scheduled maintenance windows
- Emergency maintenance for critical security or data issues
- Service disruptions caused by natural disasters, widespread internet outages, datacenter failures, or other events outside of GitLab control.

## Migrate to GitLab Dedicated

To migrate your data to GitLab Dedicated:

- From another GitLab instance:
  - Use [direct transfer](../../user/group/import/_index.md).
  - Use the [direct transfer API](../../api/bulk_imports.md).
- From third-party services:
  - Use [the import sources](../../user/project/import/_index.md#supported-import-sources).
- For complex migrations:
  - Engage [Professional Services](../../user/project/import/_index.md#migrate-by-engaging-professional-services).

## Get started

For more information about GitLab Dedicated or to request a demo, see [GitLab Dedicated](https://about.gitlab.com/dedicated/).

For more information on setting up your GitLab Dedicated instance, see [Create your GitLab Dedicated instance](../../administration/dedicated/create_instance/_index.md).
