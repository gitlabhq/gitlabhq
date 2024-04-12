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

#### Disaster Recovery

When [onboarding](../../administration/dedicated/create_instance.md#step-2-create-your-gitlab-dedicated-instance) to GitLab Dedicated, you can provide a Secondary AWS region in which your data is stored. This region is used to recover your GitLab Dedicated instance in case of a disaster. Regular backups of all GitLab Dedicated datastores (including Database and Git repositories) are taken and tested regularly and stored in your desired secondary region. GitLab Dedicated also provides the ability to store copies of these backups in a separate cloud region of choice for greater redundancy.

For more information, read about the [recovery plan for GitLab Dedicated](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/#disaster-recovery-plan) as well as RPO and RTO targets. These targets are available only when both the primary and secondary regions are supported by GitLab Dedicated. See below for a [list of available AWS regions](#available-aws-regions) for GitLab Dedicated.

### Security

#### Authentication and authorization

GitLab Dedicated supports instance-level [SAML OmniAuth](../../integration/saml.md) functionality. Your GitLab Dedicated instance acts as the service provider, and you must provide the necessary [configuration](../../integration/saml.md#configure-saml-support-in-gitlab) in order for GitLab to communicate with your IdP. For more information, see how to [configure SAML](../../administration/dedicated/configure_instance.md#saml) for your instance.

- SAML [request signing](../../integration/saml.md#sign-saml-authentication-requests-optional), [group sync](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync), and [SAML groups](../../integration/saml.md#configure-users-based-on-saml-group-membership) are supported.

#### Secure networking

GitLab Dedicated offers public connectivity by default with support for IP allowlists. You can [optionally specify a list of IP addresses](../../administration/dedicated/configure_instance.md#ip-allowlist) that can access your GitLab Dedicated instance. Subsequently, when an IP not on the allowlist tries to access your instance the connection is refused.

Private connectivity via [AWS PrivateLink](https://aws.amazon.com/privatelink/) is also offered as an option. Both [inbound](../../administration/dedicated/configure_instance.md#inbound-private-link) and [outbound](../../administration/dedicated/configure_instance.md#outbound-private-link) PrivateLinks are supported. When connecting to internal resources over an outbound PrivateLink with non public certificates, you can specify a list of certificates that are trusted by GitLab. These certificates can be provided when [updating your instance configuration](../../administration/dedicated/configure_instance.md#custom-certificates).

#### Encryption

Data is encrypted at rest and in transit using the latest encryption standards.

#### Bring your own key encryption

During onboarding, you can specify an AWS KMS encryption key stored in your own AWS account that GitLab uses to encrypt the data for your Dedicated instance. This gives you full control over the data you store in GitLab.

#### SMTP

Email sent from GitLab Dedicated uses [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/). The connection to Amazon SES is encrypted.

### Compliance

#### Certifications

GitLab Dedicated offers the following [compliance certifications](https://about.gitlab.com/security/):

- SOC 2 Type 2 Report (Security, Confidentiality, and Availability criteria)
- ISO/IEC 27001:2013
- ISO/IEC 27017:2015
- ISO/IEC 27018:2019
- TISAX (Assessment Level: 2; Objective: Info high)

#### Isolation

As a single-tenant SaaS solution, GitLab Dedicated provides infrastructure-level isolation of your GitLab environment. Your environment is placed into a separate AWS account from other tenants. This AWS account contains all of the underlying infrastructure necessary to host the GitLab application and your data stays within the account boundary. You administer the application while GitLab manages the underlying infrastructure. Tenant environments are also completely isolated from GitLab.com.

#### Access controls

GitLab Dedicated adheres to the [principle of least privilege](https://handbook.gitlab.com/handbook/security/access-management-policy/#principle-of-least-privilege) to control access to customer tenant environments. Tenant AWS accounts live under a top-level GitLab Dedicated AWS parent organization. Access to the AWS Organization is restricted to select GitLab team members. All user accounts within the AWS Organization follow the overall [GitLab Access Management Policy](https://handbook.gitlab.com/handbook/security/access-management-policy/). Direct access to customer tenant environments is restricted to a single Hub account. The GitLab Dedicated Control Plane uses the Hub account to perform automated actions over tenant accounts when managing environments. Similarly, GitLab Dedicated engineers do not have direct access to customer tenant environments. In [break glass](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/blob/main/engineering/breaking_glass.md) situations, where access to resources in the tenant environment is required to address a high-severity issue, GitLab engineers must go through the Hub account to manage those resources. This is done via an approval process, and after permission is granted, the engineer will assume an IAM role on a temporary basis to access tenant resources through the Hub account. All actions within the hub account and tenant account are logged to CloudTrail.

Inside tenant accounts, GitLab leverages Intrusion Detection and Malware Scanning capabilities from AWS GuardDuty. Infrastructure logs are monitored by the GitLab Security Incident Response Team to detect anomalous events.

#### Audit and observability

GitLab Dedicated provides access to [audit and system logs](../../administration/dedicated/configure_instance.md#access-to-application-logs) generated by the application.

### Bring your own domain

You can configure a custom domain name for your GitLab Dedicated instance. So instead of `customer_name.gitlab-dedicated.com` you can use any domain name that you own, like `gitlab.my-company.com`. You can leverage this feature to:

- Increase control over branding
- Avoid having to migrate away from an existing domain already configured for a self-managed instance

Optionally, you can also provide custom domain names for the bundled container registry and KAS services, like `gitlab-registry.my-company.com` and `gitlab-kas.my-company.com`.

### Maintenance

GitLab leverages [weekly maintenance windows](../../administration/dedicated/create_instance.md#maintenance-window) to keep your instance up to date, fix security issues, and ensure the overall reliability and performance of your environment.

#### Upgrades

GitLab performs monthly upgrades to your instance with the latest security release during your preferred [maintenance window](../../administration/dedicated/create_instance.md#maintenance-window) tracking one release behind the latest GitLab release. For example, if the latest version of GitLab available is 16.8, GitLab Dedicated runs on 16.7.

#### Unscheduled maintenance

GitLab may conduct unscheduled maintenance to address high-severity issues affecting the security, availability, or reliability of your instance.

### Application

GitLab Dedicated comes with the self-managed [Ultimate feature set](https://about.gitlab.com/pricing/feature-comparison/) with the exception of the [unsupported features](#features-that-are-not-available) listed below.

#### GitLab Pages

You can use GitLab Pages on GitLab Dedicated to host your static website. The domain name is `tenant_name.gitlab-dedicated.site`, where `tenant_name` is the same as your instance URL.

You can control access to your Pages website with [GitLab Pages access control](../../user/project/pages/pages_access_control.md).

In addition, you can limit access to your Pages website by using an [IP allowlist](../../administration/dedicated/configure_instance.md#ip-allowlist). Any existing IP allowlists for your GitLab Dedicated instances are applied.

The following GitLab Pages features are not available:

- Custom domains
- PrivateLink access
- Change of authentication scope

In addition, GitLab Pages:

- Only works in the primary site if [Geo](../../administration/geo/index.md) is enabled.
- Is not included as part of instance migrations to GitLab Dedicated.

GitLab Pages for GitLab Dedicated is enabled by default for all customers.

#### GitLab Runners

##### Hosted by GitLab

DETAILS:
**Status:** Beta

On 2024-01-31, GitLab released Hosted runners in closed [Beta](../../policy/experiment-beta-support.md#beta).

Hosted runners for GitLab Dedicated allow you to scale CI/CD workloads with no maintenance overhead.

The beta release of Hosted Runners provides the following features:

1. Linux-based runners at the instance level
1. Complete isolation from other tenants, following the same principles as GitLab Dedicated
1. Auto-scaling
1. Fully managed by GitLab

Additional features will be included based on customer demand leading up to limited and general availability.

Hosted Runners for Dedicated are available upon invitation for existing GitLab Dedicated customers. To participate in the closed Beta of Hosted Runners for Dedicated, please reach out to your Customer Success Manager or Account representative.

##### Request runner IP ranges

IP ranges for runners hosted by GitLab are available upon request. IP ranges are maintained on a best-effort basis and may change at any time during the Beta due to changes in the infrastructure.
Please reach out to your Customer Success Manager or Account representative.

##### Machine types available for Linux (x86-64)

Instance runners available during the Beta are using EC2 `M7i` general-purpose machines.

##### Bring Your Own

With GitLab Dedicated, you must [install the GitLab Runner application](https://docs.gitlab.com/runner/install/index.html) on infrastructure that you own or manage. If hosting GitLab Runners on AWS, you can avoid having requests from the Runner fleet route through the public internet by setting up a secure connection from the Runner VPC to the GitLab Dedicated endpoint via AWS Private Link. Learn more about [networking options](#secure-networking).

#### Migration

To help you migrate your data to GitLab Dedicated, you can choose from the following options:

1. When migrating from another GitLab instance, you can import groups and projects by either:
    - Using [direct transfer](../../user/group/import/index.md).
    - Using the [direct transfer](../../api/bulk_imports.md) API.
1. When migrating from third-party services, you can use [the GitLab importers](../../user/project/import/index.md#supported-import-sources).
1. You can also engage [Professional Services](../../user/project/import/index.md#migrate-by-engaging-professional-services).

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
- Interacting with GitLab [Feature Flags](../../administration/feature_flags.md)
- Any functionality or feature behind a Feature Flag that is toggled `off` by default

The following features will not be supported:

- Mattermost
- [Server-side Git hooks](../../administration/server_hooks.md).
  GitLab Dedicated is a SaaS service, and access to the underlying infrastructure is only available to GitLab Inc. team members. Due to the nature of server side configuration, there is a possible security concern of running arbitrary code on Dedicated services, as well as the possible impact that can have on the service SLA. Use the alternative [push rules](../../user/project/repository/push_rules.md) or [webhooks](../../user/project/integrations/webhooks.md) instead.

### GitLab Dedicated service features

The following operational features are not available:

- Multiple Geo secondaries (Geo replicas) beyond the secondary site included by default
- Self-serve purchasing and configuration
- Multiple login providers
- Support for deploying to non-AWS cloud providers, such as GCP or Azure
- Observability Dashboard using Switchboard
- Pre-Production Instance

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
