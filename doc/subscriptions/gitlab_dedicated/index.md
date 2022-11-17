---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Dedicated

NOTE:
GitLab Dedicated is currently in limited availability. [Contact us](#contact-us) if you are interested.

GitLab Dedicated is a fully isolated, single-tenant SaaS service that is:

- Hosted and managed by GitLab, Inc.
- Deployed in a region of choice on AWS.

GitLab Dedicated enables you to offload the operational overhead of managing the DevOps Platform. It offers a high level of tenant isolation and deployment customization, ideal for enterprises in highly-regulated industries. By deploying your GitLab instance onto separate Cloud Infrastructure from other tenants, GitLab Dedicated helps you better meet your security and compliance requirements.

## Available features

- Authentication: Support for instance-level [SAML OmniAuth](../../integration/saml.md) functionality. GitLab Dedicated acts as the service provider, and you must provide the necessary [configuration](../../integration/saml.md#general-setup) in order for GitLab to communicate with your IdP. This is provided during onboarding.
  - SAML [request signing](../../integration/saml.md#request-signing-optional), [group sync](../../user/group/saml_sso/group_sync.md#configure-saml-group-sync), and [SAML groups](../../integration/saml.md#saml-groups) are supported.
- Networking:
  - Public connectivity with support for IP Allowlists. During onboarding, you can optionally specify a list of IP addresses that can access your Dedicated instance. Subsequently, when an IP not on the allowlist tries to access your instance the connection will be refused.
  - Optional. Private connectivity via [AWS PrivateLink](https://aws.amazon.com/privatelink/).
    You can specify an AWS IAM Principal and preferred Availability Zones during onboarding to enable this functionality. Both Ingress and Egress Private Links are supported. When connecting to an internal service running in your VPC over https via PrivateLink, Dedicated supports the ability to use a private SSL certificate, which can be provided during onboarding.
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

### Dedicated service features

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
- GovCloud

## Planned features

Learn more about the planned improvements to Dedicated on the public [direction page](https://about.gitlab.com/direction/saas-platforms/dedicated/).

## Contact us

Fill in the following form to contact us and learn more about this offering.

<!-- markdownlint-disable -->

<!-- NOTE: The following form only shows when the site is served under HTTPS,
     so it will not appear when developing locally or in a review app.
     See https://gitlab.com/gitlab-com/marketing/marketing-operations/-/issues/6238#note_923358643
-->

<script src="https://page.gitlab.com/js/forms2/js/forms2.min.js"></script>
<form id="mktoForm_3226"></form>
<script>MktoForms2.loadForm("https://page.gitlab.com", "194-VVC-221", 3226);</script>
<style>
  #mktoForm_3226 {
    font-size: .875rem !important;
  }
  .mktoLabel {
    margin-top: 1rem !important;
    padding-bottom: .5rem !important;
    font-weight: 600;
  }
  .mktoHtmlText,
  #LblPhone,
  .mktoTextField,
  #commentCapture,
  .mktoField,
  .mktoButtonRow button {
    width: 20rem !important;
  }
  .mktoHtmlText {
    font-size: .875rem;
  }
  .mktoButtonRow {
    margin: 1em 0;
  }
  .mktoButtonRow span {
    margin-left: 0 !important;
  }
  .mktoButtonRow button {
    margin: 1em 0 1.5em !important;
  }
</style>

<!-- markdownlint-enable -->
