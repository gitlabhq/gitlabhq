---
stage: SaaS Platforms
group: GitLab Dedicated
description: Available features and benefits.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Dedicated

GitLab Dedicated is a fully isolated, single-tenant SaaS solution that is:

- Hosted and managed by GitLab, Inc.
- Deployed on AWS in a cloud region of your choice. See [available AWS regions](#available-aws-regions).

GitLab Dedicated removes the overhead of platform management to increase your operational efficiency, reduce risk, and enhance the speed and agility of your organization. Each GitLab Dedicated instance is highly available with disaster recovery and deployed into the cloud region of your choice. GitLab teams fully manage the maintenance and operations of each isolated instance, so customers can access our latest product improvements while meeting the most complex compliance standards.

It's the offering of choice for enterprises and organizations in highly regulated industries that have complex regulatory, compliance, and data residency requirements.

## Available features

### Data residency

GitLab Dedicated allows you to select the cloud region where your data will be stored. Upon [onboarding](../../administration/dedicated/create_instance.md#step-2-create-your-gitlab-dedicated-instance), choose the cloud region where you want to deploy your Dedicated instance. Some AWS regions have limited features and as a result, we are not able to deploy production instances to those regions. See below for the [list of available AWS regions](#available-aws-regions).

### Advanced search

GitLab Dedicated uses the [advanced search functionality](../../integration/advanced_search/elasticsearch.md).

### Availability and scalability

GitLab Dedicated leverages modified versions of the GitLab [Cloud Native Hybrid reference architectures](../../administration/reference_architectures/index.md#cloud-native-hybrid) with high availability enabled. When [onboarding](../../administration/dedicated/create_instance.md#step-2-create-your-gitlab-dedicated-instance), GitLab will match you to the closest reference architecture size based on your number of users. Learn about the [current Service Level Objective](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/#current-service-level-objective).

NOTE:
The published [reference architectures](../../administration/reference_architectures/index.md) act as a starting point in defining the cloud resources deployed inside GitLab Dedicated environments, but they are not comprehensive. GitLab Dedicated leverages additional Cloud Provider services beyond what's included in the standard reference architectures for enhanced security and stability of the environment. Therefore, GitLab Dedicated costs differ from standard reference architecture costs.

#### Zero-downtime upgrades

Deployments for GitLab Dedicated follow the process for [zero-downtime upgrades](../../update/zero_downtime.md) to ensure [backward compatibility](../../development/multi_version_compatibility.md) of the application during an upgrade. When no infrastructure changes or maintenance tasks require downtime, using the instance during an upgrade is possible and safe.

During a GitLab version update, static assets may change and are only available in one of the two versions. To mitigate this situation, GitLab Dedicated adopts three techniques:

1. Each static asset has a unique name that changes when its content changes.
1. The browser caches each static asset.
1. Each request from the same browser is routed to the same server temporarily.

These techniques together give a strong assurance about asset availability:

- During an upgrade, a user routed to a server running the new version will receive assets from the same server, completely removing the risk of receiving a broken page.
- If routed to the old version, a regular user will have assets cached in their browser.
- If not cached, they will receive the requested page and assets from the same server.
- If the specific server is upgraded during the requests, they may still be routed to another server running the same version.
- If the new server is running the upgraded version, and the requested asset changed, then the page may show some user interface glitches.

To notice the effect of an upgrade, a new user of the system should connect for the first time during a version upgrade and get routed to an old version of the application immediately before its upgrade. The subsequent asset requests should end up in a server running the new version of GitLab, and the requested assets must have changed during this specific version upgrade. If all of this happens, a page refresh is enough to restore it.

NOTE:
Adopting a caching proxy in the customer network will further reduce this risk.

#### Disaster Recovery

When [onboarding](../../administration/dedicated/create_instance.md#step-2-create-your-gitlab-dedicated-instance) to GitLab Dedicated, you specify a Secondary AWS region in which your data will be stored. This region is used to recover your GitLab Dedicated instance in case of a disaster. Regular backups of all GitLab Dedicated datastores (including Database and Git repositories) are taken and tested regularly and stored in your desired secondary region. GitLab Dedicated also provides the ability to store copies of these backups in a separate cloud region of choice for greater redundancy.

For more information, read about the [recovery plan for GitLab Dedicated](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/#disaster-recovery-plan) as well as RPO and RTO targets. These targets are available only when both the primary and secondary regions are supported by GitLab Dedicated. See below for a [list of available AWS regions](#available-aws-regions) for GitLab Dedicated.

### Security

#### Authentication and authorization

GitLab Dedicated supports instance-level [SAML OmniAuth](../../integration/saml.md) functionality. Your GitLab Dedicated instance acts as the service provider, and you must provide the necessary [configuration](../../integration/saml.md#configure-saml-support-in-gitlab) in order for GitLab to communicate with your IdP. For more information, see how to [configure SAML](../../administration/dedicated/configure_instance.md#saml) for your instance.

- SAML [request signing](../../integration/saml.md#sign-saml-authentication-requests-optional), [group sync](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync), and [SAML groups](../../integration/saml.md#configure-users-based-on-saml-group-membership) are supported.

#### Secure networking

GitLab Dedicated offers public connectivity by default with support for IP allowlists. You can [optionally specify a list of IP addresses](../../administration/dedicated/configure_instance.md#ip-allowlist) that can access your GitLab Dedicated instance. Subsequently, when an IP not on the allowlist tries to access your instance the connection is refused.

Private connectivity using [AWS PrivateLink](https://aws.amazon.com/privatelink/) is also offered as an option. Both [inbound](../../administration/dedicated/configure_instance.md#inbound-private-link) and [outbound](../../administration/dedicated/configure_instance.md#outbound-private-link) PrivateLinks are supported. When connecting to internal resources over an outbound PrivateLink with non public certificates, you can specify a list of certificates that are trusted by GitLab. These certificates can be provided when [updating your instance configuration](../../administration/dedicated/configure_instance.md#custom-certificates).

#### Encryption

Data is encrypted at rest and in transit using the latest encryption standards.

#### Bring your own key encryption

During onboarding, you can specify an AWS KMS encryption key stored in your own AWS account that GitLab uses to encrypt the data for your Dedicated instance. This gives you full control over the data you store in GitLab.

#### SMTP

Email sent from GitLab Dedicated uses [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/). The connection to Amazon SES is encrypted.

If you would rather send application email using an SMTP server instead of Amazon SES, you can [configure your own email service](../../administration/dedicated/configure_instance.md#smtp-email-service).

### Compliance and certifications

GitLab Dedicated is trusted by highly regulated customers in part due to our ability to transparently demonstrate compliance with various regulations, certifications, and compliance frameworks.

You can view compliance and certification details, and download compliance artifacts from the [GitLab Dedicated Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated).

#### Isolation

As a single-tenant SaaS solution, GitLab Dedicated provides infrastructure-level isolation of your GitLab environment. Your environment is placed into a separate AWS account from other tenants. This AWS account contains all of the underlying infrastructure necessary to host the GitLab application and your data stays within the account boundary. You administer the application while GitLab manages the underlying infrastructure. Tenant environments are also completely isolated from GitLab.com.

#### Access controls

GitLab Dedicated adheres to the
[principle of least privilege](https://handbook.gitlab.com/handbook/security/access-management-policy/#principle-of-least-privilege)
to control access to customer tenant environments. Tenant AWS accounts live under
a top-level GitLab Dedicated AWS parent organization. Access to the AWS Organization
is restricted to select GitLab team members. All user accounts within the AWS Organization
follow the overall [GitLab Access Management Policy](https://handbook.gitlab.com/handbook/security/access-management-policy/).
Direct access to customer tenant environments is restricted to a single Hub account.
The GitLab Dedicated Control Plane uses the Hub account to perform automated actions
over tenant accounts when managing environments. Similarly, GitLab Dedicated engineers
do not have direct access to customer tenant environments.
In [break glass](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/blob/main/engineering/breaking_glass.md)
situations, where access to resources in the tenant environment is required to
address a high-severity issue, GitLab engineers must go through the Hub account
to manage those resources. This is done via an approval process, and after permission
is granted, the engineer will assume an IAM role on a temporary basis to access
tenant resources through the Hub account. All actions within the hub account and
tenant account are logged to CloudTrail.

Inside tenant accounts, GitLab leverages Intrusion Detection and Malware Scanning capabilities from AWS GuardDuty. Infrastructure logs are monitored by the GitLab Security Incident Response Team to detect anomalous events.

#### Audit and observability

GitLab Dedicated provides access to [audit and system logs](../../administration/dedicated/configure_instance.md#access-to-application-logs) generated by the application.

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

### Maintenance

GitLab leverages [weekly maintenance windows](../../administration/dedicated/create_instance.md#maintenance-window) to keep your instance up to date, fix security issues, and ensure the overall reliability and performance of your environment.

#### Upgrades

GitLab performs monthly upgrades to your instance with the latest patch release during your preferred [maintenance window](../../administration/dedicated/create_instance.md#maintenance-window) tracking one release behind the latest GitLab release. For example, if the latest version of GitLab available is 16.8, GitLab Dedicated runs on 16.7.

#### Unscheduled maintenance

GitLab may conduct [unscheduled maintenance](../../administration/dedicated/create_instance.md#emergency-maintenance) to address high-severity issues affecting the security, availability, or reliability of your instance.

### Application

GitLab Dedicated comes with the self-managed [Ultimate feature set](https://about.gitlab.com/pricing/feature-comparison/) with the exception of the [unsupported features](#features-that-are-not-available) listed below.

#### GitLab Pages

You can use [GitLab Pages](../../user/project/pages/index.md) on GitLab Dedicated to host your static website. The domain name is `tenant_name.gitlab-dedicated.site`, where `tenant_name` is the same as your instance URL.

NOTE:
Custom domains for GitLab Pages are not supported. For example, if you added a custom domain named `gitlab.my-company.com`, the URL to access the Pages site for your GitLab Dedicated instance would still be `tenant_name.gitlab-dedicated.site`.

You can control access to your Pages website with:

- [GitLab Pages access control](../../user/project/pages/pages_access_control.md).
- [IP allowlists](../../administration/dedicated/configure_instance.md#ip-allowlist). Any existing IP allowlists for your GitLab Dedicated instances are applied.

GitLab Pages for Dedicated:

- Is enabled by default.
- Only works in the primary site if [Geo](../../administration/geo/index.md) is enabled.
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

#### OpenID Connect

You can use [GitLab as an OpenID Connect identity provider](../../integration/openid_connect_provider.md). If you use an IP allowlist to restrict access to your instance, you can [enable OpenID Connect requests](../../administration/dedicated/configure_instance.md#enable-openid-connect-for-your-ip-allowlist) while maintaining your IP restrictions.

#### Migration

To help you migrate your data to GitLab Dedicated, choose from the following options:

1. When migrating from another GitLab instance, you can import groups and projects by either:
   - Using [direct transfer](../../user/group/import/index.md).
   - Using the [direct transfer](../../api/bulk_imports.md) API.
1. When migrating from third-party services, you can use [the GitLab importers](../../user/project/import/index.md#supported-import-sources).
1. You can also engage [Professional Services](../../user/project/import/index.md#migrate-by-engaging-professional-services).

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

## Features that are not available

### GitLab application features

The following GitLab application features are not available:

- LDAP, smart card, or Kerberos authentication
- Multiple login providers
- FortiAuthenticator, or FortiToken 2FA
- Reply-by email
- Service Desk
- Some GitLab Duo AI capabilities
  - View the [list of AI features to see which ones are supported](../../user/ai_features.md).
  - Refer to our [direction page](https://about.gitlab.com/direction/saas-platforms/dedicated/#supporting-ai-features-on-gitlab-dedicated) for more information.
- Features other than [available features](#available-features) that must be configured outside of the GitLab user interface
- Any functionality or feature behind a Feature Flag that is toggled `off` by default.

The following features will not be supported:

- Mattermost
- [Server-side Git hooks](../../administration/server_hooks.md).
  GitLab Dedicated is a SaaS service, and access to the underlying infrastructure is only available to GitLab Inc. team members. Due to the nature of server side configuration, there is a possible security concern of running arbitrary code on Dedicated services, as well as the possible impact that can have on the service SLA. Use the alternative [push rules](../../user/project/repository/push_rules.md) or [webhooks](../../user/project/integrations/webhooks.md) instead.
- Interacting with GitLab [Feature Flags](../../administration/feature_flags.md). [Feature flags support the development and rollout of new or experimental features](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags) on GitLab.com. Features behind feature flags are not considered ready for production use, are experimental and therefore unsafe for GitLab Dedicated. Stability and SLAs may be affected by changing default settings.

### GitLab Dedicated service features

The following operational features are not available:

- Multiple Geo secondaries (Geo replicas) beyond the secondary site included by default
- [Geo proxying](../../administration/geo/secondary_proxy/index.md) and using a unified URL
- Self-serve purchasing and configuration
- Multiple login providers
- Support for deploying to non-AWS cloud providers, such as GCP or Azure
- Observability Dashboard using Switchboard

### Available AWS regions

The following is a list of AWS regions verified for use in GitLab Dedicated. Regions must support io2 volumes and meet other requirements. If there is a region you are interested in that is not on this list, reach out through your account representative or [GitLab Support](https://about.gitlab.com/support/) to inquire about its availability. This list will be updated from time to time as additional regions are verified.

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

## Planned features

For more information about the planned improvements to GitLab Dedicated,
see the [category direction page](https://about.gitlab.com/direction/saas-platforms/dedicated/).

## Interested in GitLab Dedicated?

Learn more about GitLab Dedicated and [talk to an expert](https://about.gitlab.com/dedicated/).
