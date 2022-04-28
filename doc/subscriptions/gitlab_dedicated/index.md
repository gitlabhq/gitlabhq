---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Dedicated

NOTE:
GitLab Dedicated is currently in limited availability. Please [contact us](#contact-us) if you are interested.

GitLab Dedicated is a fully isolated, single-tenant GitLab instance that is:

- Hosted and managed by GitLab, Inc.
- Deployed in a region of choice in AWS.

GitLab Dedicated enables you to offload the operational overhead of managing the DevOps Platform. It offers a high level of tenant isolation and deployment customization, ideal for enterprises in highly-regulated industries. By deploying your GitLab instance onto a separate Cloud Infrastructure from other tenants, GitLab Dedicated helps you better meet your security and compliance requirements.

## Available features

- Authentication: Support for instance-level [SAML OmniAuth](../../integration/saml.md) functionality. GitLab Dedicated acts as the service provider, and you will need to provide the necessary [configuration](../../integration/saml.md#general-setup) in order for GitLab to communicate with your IdP. This will be provided during onboarding. SAML [request signing](../../integration/saml.md#request-signing-optional) is supported.
- Networking:
  - Public connectivity
  - Optional. Private connectivity via [AWS PrivateLink](https://aws.amazon.com/privatelink/).
    You can specify an AWS IAM Principal and preferred Availability Zones during onboarding to enable this functionality.
- Upgrade strategy:
  - Monthly upgrades tracking one release behind the latest (n-1), with the latest security release.
  - Out of band security patches provided for high severity items.
- Backup strategy: regular backups taken and tested.
- Choice of Cloud Region: upon onboarding, choose the cloud region where you want to deploy your instance. Some AWS regions have limited features and as a result, we are not able to deploy production instances to those regions. See below for the [full list of regions](#aws-regions-not-supported) not currently supported.
- Security: Data encrypted at rest and in transit using latest encryption standards.
- Application: Self-managed [Ultimate feature set](https://about.gitlab.com/pricing/self-managed/feature-comparison/) with the exception of the unsupported features [listed below](#features-not-available-at-launch).

## Features not available at launch

Features that are not available but we plan to support in the future:

- LDAP, Smartcard, Kerberos authentication
- Custom domain
- Advanced Search
- Pages
- GitLab-managed runners
- FortiAuthenticator/FortiToken 2FA
- Reply-by email
- Service desk

Features that we do not plan to offer at all:

- Mattermost
- Server-side Git Hooks

### AWS regions not supported

The following AWS regions are not available at launch:

- Jakarta (ap-southeast-3)
- Bahrain (me-south-1)
- Hong Kong (ap-east-1)
- Cape Town (af-south-1)
- Milan (eu-south-1)
- Paris (eu-west-3)
- GovCloud

## Contact us

Fill in the following form to contact us and learn more about this offering.

<!-- markdownlint-disable -->

<script src="//page.gitlab.com/js/forms2/js/forms2.min.js"></script>
<form id="mktoForm_3226"></form>
<script>MktoForms2.loadForm("//page.gitlab.com", "194-VVC-221", 3226);</script>

<!-- markdownlint-enable -->
