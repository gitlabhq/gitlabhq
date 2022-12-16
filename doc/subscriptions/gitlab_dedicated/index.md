---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Dedicated

NOTE:
GitLab Dedicated is currently in limited availability. You can learn more and join the waitlist [on our website](https://about.gitlab.com/single-tenant-saas).

GitLab Dedicated is a fully isolated, single-tenant SaaS service that is:

- Hosted and managed by GitLab, Inc.
- Deployed on AWS in a cloud region of your choice (see the [regions that are not supported](#aws-regions-not-supported)).

GitLab Dedicated removes the overhead of platform management to increase your operational efficiency, reduce risk, and enhance the speed and agility of your organization. Each GitLab Dedicated instance is highly available with disaster recovery and deployed into the cloud region of your choice. GitLab teams fully manage the maintenance and operations of each isolated instance, so customers can access our latest product improvements while meeting the most complex compliance standards.

It's the offering of choice for enterprises and organizations in highly regulated industries that have complex regulatory, compliance, and data residency requirements.

## Available features

- Authentication: Support for instance-level [SAML OmniAuth](../../integration/saml.md) functionality. GitLab Dedicated acts as the service provider, and you must provide the necessary [configuration](../../integration/saml.md#configure-saml-support-in-gitlab) in order for GitLab to communicate with your IdP. This is provided during onboarding.
  - SAML [request signing](../../integration/saml.md#sign-saml-authentication-requests-optional), [group sync](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync), and [SAML groups](../../integration/saml.md#configure-users-based-on-saml-group-membership) are supported.
- Networking:
  - Public connectivity with support for IP Allowlists. During onboarding, you can optionally specify a list of IP addresses that can access your GitLab Dedicated instance. Subsequently, when an IP not on the allowlist tries to access your instance the connection is refused.
  - Optional. Private connectivity via [AWS PrivateLink](https://aws.amazon.com/privatelink/).
    You can specify an AWS IAM Principal and preferred Availability Zones during onboarding to enable this functionality. Both Ingress and Egress PrivateLinks are supported. When connecting to an internal service running in your VPC over HTTPS via PrivateLink, GitLab Dedicated supports the ability to use a private SSL certificate, which can be provided during onboarding.
- Upgrades:
  - Monthly upgrades tracking one release behind the latest (n-1), with the latest security release.
  - Out of band security patches provided for high severity releases.
- Backups: Regular backups taken and tested.
- Choice of cloud region: Upon onboarding, choose the cloud region where you want to deploy your instance. Some AWS regions have limited features and as a result, we are not able to deploy production instances to those regions. See below for the [full list of regions](#aws-regions-not-supported) not currently supported.
- Security: Data encrypted at rest and in transit using latest encryption standards.
- Application: Self-managed [Ultimate feature set](https://about.gitlab.com/pricing/feature-comparison/) with the exception of the unsupported features [listed below](#features-that-are-not-available).

## Features that are not available

### GitLab application features

The following GitLab application features are not available:

- LDAP, Smartcard, or Kerberos authentication
- Multiple login providers
- Advanced Search
- GitLab Pages
- FortiAuthenticator, or FortiToken 2FA
- Reply-by email
- Service Desk
- GitLab-managed runners
- Any feature [not listed above](#available-features) which must be configured outside of the GitLab user interface.

The following features will not be supported:

- Mattermost
- Server-side Git hooks

### GitLab Dedicated service features

The following operational features are not available:

- Custom domains
- Bring Your Own Key (BYOK) encryption
- Multiple Geo secondaries (Geo replicas) beyond the secondary site included by default
- Self-serve purchasing and configuration
- Multiple login providers
- Non-AWS cloud providers, such as GCP or Azure

### AWS regions not supported

The following AWS regions are not available:

- Jakarta (`ap-southeast-3`)
- Bahrain (`me-south-1`)
- Hong Kong (`ap-east-1`)
- Cape Town (`af-south-1`)
- Milan (`eu-south-1`)
- Paris (`eu-west-3`)
- Zurich (`eu-central-2`)
- GovCloud (US-East) (`us-gov-east-1`)
- GovCloud (US-West) (`us-gov-west-1`)

## Planned features

Learn more about the planned improvements to GitLab Dedicated on the public [direction page](https://about.gitlab.com/direction/saas-platforms/dedicated/).

## Learn more about GitLab Dedicated and join our waitlist

As we scale this new offering, we are making GitLab Dedicated available by inviting customers to learn more and join our waitlist [on our website](https://about.gitlab.com/single-tenant-saas).
