---
stage: GitLab Dedicated
group: Switchboard
description: Configure SAML single sign-on (SSO) authentication for GitLab Dedicated.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAML single sign-on for GitLab Dedicated
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

You can [configure SAML single sign-on (SSO)](../../../integration/saml.md#configure-saml-support-in-gitlab) for your GitLab Dedicated instance. Optionally, you can configure more than one SAML identity provider (IdP).

The following SAML SSO options are available:

- [Request signing](../../../integration/saml.md#sign-saml-authentication-requests-optional)
- [SAML SSO for groups](../../../integration/saml.md#configure-users-based-on-saml-group-membership)
- [Group sync](../../../user/group/saml_sso/group_sync.md#configure-saml-group-sync)

Prerequisites:

- You must [set up the identity provider](../../../integration/saml.md#set-up-identity-providers) before you can configure SAML for GitLab Dedicated.
- To configure GitLab to sign SAML authentication requests, you must create a private key and public certificate pair for your GitLab Dedicated instance.

NOTE:
You can only configure one SAML IdP with Switchboard. If you configured a SAML IdP on your GitLab Dedicated instance before the introduction of support for multiple IdPs, you can manage that provider through Switchboard. To configure additional SAML IdPs, [submit a support request](#activate-saml-with-a-support-request).

## Activate SAML with Switchboard

To activate SAML for your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **SAML Config**.
1. Turn on the **Enable** toggle.
1. Complete the required fields:
   - SAML label
   - IdP cert fingerprint
   - IdP SSO target URL
   - Name identifier format
1. To configure users based on [SAML group membership](#saml-groups) or use [group sync](#group-sync), complete the following fields:
   - SAML group attribute
   - Admin groups
   - Auditor groups
   - External groups
   - Required groups
1. To configure [SAML request signing](#request-signing), complete the following fields:
   - Issuer
   - Attribute statements
   - Security
1. Select **Save**.
1. Scroll up to the top of the page and select whether to apply the changes immediately or during the next maintenance window.
1. To use group sync, [configure the SAML group links](../../../user/group/saml_sso/group_sync.md#configure-saml-group-links).
1. To verify the SAML configuration is successful:
   - Check that the SSO button description is displayed on your instance's sign-in page.
   - Go to the metadata URL of your instance (`https://INSTANCE-URL/users/auth/saml/metadata`). This page can be used to simplify much of the configuration of the identity provider, and manually validate the settings.

## Activate SAML with a Support Request

If you are unable to use Switchboard to activate or update SAML for your GitLab Dedicated instance, or if you need to configure more than one SAML IdP, then you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650):

1. To make the necessary changes, include the desired [SAML configuration block](../../../integration/saml.md#configure-saml-support-in-gitlab) for your GitLab application in your support ticket. At a minimum, GitLab needs the following information to enable SAML for your instance:
   - IDP SSO Target URL
   - Certificate fingerprint or certificate
   - NameID format
   - SSO login button description

   ```json
   "saml": {
     "attribute_statements": {
         //optional
     },
     "enabled": true,
     "groups_attribute": "",
     "admin_groups": [
       // optional
     ],
     "idp_cert_fingerprint": "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
     "idp_sso_target_url": "https://login.example.com/idp",
     "label": "IDP Name",
     "name_identifier_format": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
     "security": {
       // optional
     },
     "auditor_groups": [
       // optional
     ],
     "external_groups": [
       // optional
     ],
     "required_groups": [
       // optional
     ],
   }
   ```

1. After GitLab deploys the SAML configuration to your instance, you are notified on your support ticket.
1. To verify the SAML configuration is successful:
   - Check that the SSO login button description is displayed on your instance's login page.
   - Go to the metadata URL of your instance, which is provided by GitLab in the support ticket. This page can be used to simplify much of the configuration of the identity provider, as well as manually validate the settings.

## Request signing

If [SAML request signing](../../../integration/saml.md#sign-saml-authentication-requests-optional) is desired, a certificate must be obtained. This certificate can be self-signed which has the advantage of not having to prove ownership of an arbitrary Common Name (CN) to a public Certificate Authority (CA).

NOTE:
Because SAML request signing requires certificate signing, you must complete these steps to use SAML with this feature enabled.

To enable SAML request signing:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and indicate that you want request signing enabled.
1. GitLab will work with you on sending the Certificate Signing Request (CSR) for you to sign. Alternatively, the CSR can be signed with a public CA.
1. After the certificate is signed, you can then use the certificate and its associated private key to complete the `security` section of the [SAML configuration](#activate-saml-with-switchboard) in Switchboard.

Authentication requests from GitLab to your identity provider can now be signed.

## SAML groups

With SAML groups you can configure GitLab users based on SAML group membership.

To enable SAML groups, add the [required elements](../../../integration/saml.md#configure-users-based-on-saml-group-membership) to your SAML configuration in [Switchboard](#activate-saml-with-switchboard) or to the SAML block you provide in a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

## Group sync

With [group sync](../../../user/group/saml_sso/group_sync.md), you can sync users across identity provider groups to mapped groups in GitLab.

To enable group sync:

1. Add the [required elements](../../../user/group/saml_sso/group_sync.md#configure-saml-group-sync) to your SAML configuration in [Switchboard](#activate-saml-with-switchboard) or to the SAML configuration block you provide in a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Configure the [Group Links](../../../user/group/saml_sso/group_sync.md#configure-saml-group-links).
