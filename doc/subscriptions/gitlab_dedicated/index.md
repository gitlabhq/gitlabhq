---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Dedicated

NOTE:
GitLab Dedicated is currently in limited availability. [Contact us](#contact-us) if you are interested.

GitLab Dedicated is a fully isolated, single-tenant SaaS service that is:

- Hosted and managed by GitLab, Inc.
- Deployed in a region of choice on AWS.

GitLab Dedicated enables you to offload the operational overhead of managing the DevOps Platform. It offers a high level of tenant isolation and deployment customization, ideal for enterprises in highly-regulated industries. By deploying your GitLab instance onto separate Cloud Infrastructure from other tenants, GitLab Dedicated helps you better meet your security and compliance requirements.

## Available features

- Authentication: Support for instance-level [SAML OmniAuth](../../integration/saml.md) functionality. GitLab Dedicated acts as the service provider, and you must provide the necessary [configuration](../../integration/saml.md#general-setup) in order for GitLab to communicate with your IdP. This is provided during onboarding. SAML [request signing](../../integration/saml.md#request-signing-optional) is supported.
- Networking:
  - Public connectivity
  - Optional. Private connectivity via [AWS PrivateLink](https://aws.amazon.com/privatelink/).
    You can specify an AWS IAM Principal and preferred Availability Zones during onboarding to enable this functionality.
- Upgrade strategy:
  - Monthly upgrades tracking one release behind the latest (n-1), with the latest security release.
  - Out of band security patches provided for high severity releases.
- Backup strategy: regular backups taken and tested.
- Choice of cloud region: upon onboarding, choose the cloud region where you want to deploy your instance. Some AWS regions have limited features and as a result, we are not able to deploy production instances to those regions. See below for the [full list of regions](#aws-regions-not-supported) not currently supported.
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
