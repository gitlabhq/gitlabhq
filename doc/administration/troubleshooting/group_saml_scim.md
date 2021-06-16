---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Troubleshooting Group SAML and SCIM **(PREMIUM SAAS)**

These are notes and screenshots regarding Group SAML and SCIM that the GitLab Support Team sometimes uses while troubleshooting, but which do not fit into the official documentation. GitLab is making this public, so that anyone can make use of the Support team's collected knowledge.

Please refer to the GitLab [Group SAML](../../user/group/saml_sso/index.md) docs for information on the feature and how to set it up.

When troubleshooting a SAML configuration, GitLab team members will frequently start with the [SAML troubleshooting section](../../user/group/saml_sso/index.md#troubleshooting).

They may then set up a test configuration of the desired identity provider. We include example screenshots in this section.

## SAML and SCIM screenshots

This section includes relevant screenshots of the following example configurations of [Group SAML](../../user/group/saml_sso/index.md) and [Group SCIM](../../user/group/saml_sso/scim_setup.md):

- [Azure Active Directory](#azure-active-directory)
- [Okta](#okta)
- [OneLogin](#onelogin)

WARNING:
These screenshots are updated only as needed by GitLab Support. They are **not** official documentation.

If you are currently having an issue with GitLab, you may want to check your [support options](https://about.gitlab.com/support/).

## Azure Active Directory

Basic SAML app configuration:

![Azure AD basic SAML](img/AzureAD-basic_SAML.png)

User claims and attributes:

![Azure AD user claims](img/AzureAD-claims.png)

SCIM mapping:

![Azure AD SCIM](img/AzureAD-scim_attribute_mapping.png)

Group Sync:

![Azure Group Claims](img/azure_configure_group_claim.png)

## Okta

Basic SAML app configuration:

![Okta basic SAML](img/Okta-SAMLsetup.png)

User claims and attributes:

![Okta Attributes](img/Okta-attributes.png)

Advanced SAML app settings (defaults):

![Okta Advanced Settings](img/Okta-advancedsettings.png)

IdP Links and Certificate:

![Okta Links and Certificate](img/Okta-linkscert.png)

Sign on settings:

![Okta SAML settings](img/okta_saml_settings.png)

Self-managed instance example:

![Okta admin panel view](img/okta_admin_panel_v13_9.png)

## OneLogin

Application details:

![OneLogin application details](img/OneLogin-app_details.png)

Parameters:

![OneLogin application details](img/OneLogin-parameters.png)

Adding a user:

![OneLogin user add](img/OneLogin-userAdd.png)

SSO settings:

![OneLogin SSO settings](img/OneLogin-SSOsettings.png)
