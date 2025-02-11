---
stage: GitLab Dedicated
group: Switchboard
description: Available features and benefits.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Dedicated
---

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

You can configure [SAML single sign-on (SSO)](../../integration/saml.md) using any number of SAML providers for authentication. Your instance acts as the service provider, and you provide the necessary configuration for GitLab to communicate with your Identity Providers (IdPs). SAML request signing, group sync, and SAML groups are supported.

For more information, see how to configure [SAML](../../administration/dedicated/configure_instance/saml.md) for your instance.

#### Secure networking

Two connectivity options are available:

- Public connectivity with IP allowlists: By default, your instance is publicly accessible. You can [configure an IP allowlist](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist) to restrict access to specified IP addresses.
- Private connectivity with AWS PrivateLink: You can configure [AWS PrivateLink](https://aws.amazon.com/privatelink/) for [inbound](../../administration/dedicated/configure_instance/network_security.md#inbound-private-link) and [outbound](../../administration/dedicated/configure_instance/network_security.md#outbound-private-link) connections.

For private connections to internal resources using non-public certificates, you can also [specify trusted certificates](../../administration/dedicated/configure_instance/network_security.md#custom-certificates).

#### Data encryption

Data is encrypted at rest and in transit using the latest encryption standards.

Optionally, you can use your own AWS Key Management Service (KMS) encryption key for data at rest. This option gives you full control over the data you store in GitLab.

For more information, see [Encrypted data at rest (BYOK)](../../administration/dedicated/create_instance.md#encrypted-data-at-rest-byok).

#### Email service

By default, [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/) is used to send emails securely. As an alternative, you can [configure your own email service](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service) using SMTP.

### Compliance

GitLab Dedicated adheres to various regulations, certifications, and compliance frameworks to ensure the security, and reliability of your data.

#### View compliance and certification details

You can view compliance and certification details, and download compliance artifacts from the [GitLab Dedicated Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated).

#### Access controls

GitLab Dedicated implements strict access controls to protect your environment:

- Follows the [principle of least privilege](https://handbook.gitlab.com/handbook/security/access-management-policy/#principle-of-least-privilege).
- Restricts access to the AWS organization to select GitLab team members.
- User accounts follow the [Access Management Policy](https://handbook.gitlab.com/handbook/security/access-management-policy/).
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
- Avoid having to migrate away from an existing domain already configured for a self-managed instance

When you add a custom hostname:

- The hostname is included in the external URL used to access your instance.
- Any connections to your instance using the previous domain names are no longer available.

To add a custom hostname after your instance is created, submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

NOTE:
Custom hostnames for GitLab Pages are not supported. If you use GitLab Pages, the URL to access the Pages site for your GitLab Dedicated instance would be `tenant_name.gitlab-dedicated.site`.

### Application

GitLab Dedicated comes with the self-managed [Ultimate feature set](https://about.gitlab.com/pricing/feature-comparison/) with a small number of exceptions. For more information, see [Unavailable features](#unavailable-features).

#### Advanced search

GitLab Dedicated uses the [advanced search functionality](../../integration/advanced_search/elasticsearch.md).

#### GitLab Pages

You can use [GitLab Pages](../../user/project/pages/_index.md) on GitLab Dedicated to host your static website. The domain name is `tenant_name.gitlab-dedicated.site`, where `tenant_name` is the same as your instance URL.

NOTE:
Custom domains for GitLab Pages are not supported. For example, if you added a custom domain named `gitlab.my-company.com`, the URL to access the Pages site for your GitLab Dedicated instance would still be `tenant_name.gitlab-dedicated.site`.

You can control access to your Pages website with:

- [GitLab Pages access control](../../user/project/pages/pages_access_control.md).
- [IP allowlists](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist). Any existing IP allowlists for your GitLab Dedicated instances are applied.

GitLab Pages for Dedicated:

- Is enabled by default.
- Only works in the primary site if [Geo](../../administration/geo/_index.md) is enabled.
- Is not included as part of instance migrations to GitLab Dedicated.

The following GitLab Pages features are not available for GitLab Dedicated:

- Custom domains
- PrivateLink access
- Namespaces in URL path
- Let's Encrypt integration
- Reduced authentication scope
- Running Pages behind a proxy

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

### Application features

The following GitLab application features are not available:

- LDAP, smart card, or Kerberos authentication
- Multiple login providers
- FortiAuthenticator or FortiToken 2FA
- Reply by email
- Service Desk
- Some GitLab Duo AI capabilities
  - View the [list of supported AI features](../../user/ai_features.md)
  - For more information, see the [Supporting AI Features on GitLab Dedicated](https://about.gitlab.com/direction/saas-platforms/dedicated/#supporting-ai-features-on-gitlab-dedicated)
- Features other than [available features](#available-features) that must be configured outside of the GitLab user interface
- Any functionality or feature behind a feature flag that is turned `off` by default
- [Sigstore for keyless signing and verification](../../ci/yaml/signing_examples.md)

The following features are not supported:

- [Mattermost](../../integration/mattermost/_index.md)
- [Server-side Git hooks](../../administration/server_hooks.md)

NOTE:
Access to the underlying infrastructure is only available to GitLab team members. Due to the server-side configuration, there is a security concern with running arbitrary code on services, and the possible impact on the service SLA. As an alternative, use [push rules](../../user/project/repository/push_rules.md) or [webhooks](../../user/project/integrations/webhooks.md) instead.

### Operational features

The following operational features are not available:

- Multiple Geo secondaries (Geo replicas) beyond the secondary site included by default
- [Geo proxying](../../administration/geo/secondary_proxy/_index.md) and using a unified URL
- Self-serve purchasing and configuration
- Support for deploying to non-AWS cloud providers, such as GCP or Azure
- Observability dashboard in Switchboard

### Feature flags

[Feature flags](../../administration/feature_flags.md) are not available for GitLab Dedicated.

Feature flags support the development and rollout of new or experimental features on GitLab.com. Features behind feature flags are not considered ready for production use, are experimental and therefore unsafe for GitLab Dedicated. Stability and SLAs may be affected by changing default settings.

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

For more information on setting up your GitLab Dedicated instance, see [Create your GitLab Dedicated instance](../../administration/dedicated/create_instance.md).
