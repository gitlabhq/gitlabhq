---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure SAML single sign-on (SSO) authentication for GitLab Dedicated.
title: SAML single sign-on for GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

You can configure SAML single sign-on (SSO) for your GitLab Dedicated instance for up to ten identity providers (IdPs).

The following SAML SSO options are available:

- [Request signing](#request-signing)
- [SAML SSO for groups](#saml-groups)
- [Group sync](#group-sync)

{{< alert type="note" >}}

These instructions apply only to SSO for your GitLab Dedicated instance. For Switchboard, see [configure single sign-on for Switchboard](users_notifications.md#configure-single-sign-on-for-switchboard).

{{< /alert >}}

## Prerequisites

- You must [set up the identity provider](../../../integration/saml.md#set-up-identity-providers) before you can configure SAML for GitLab Dedicated.
- To configure GitLab to sign SAML authentication requests, you must create a private key and public certificate pair for your GitLab Dedicated instance.

## Add a SAML provider with Switchboard

To add a SAML provider for your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **SAML providers**.
1. Select **Add SAML provider**.
1. In the **SAML label** text box, enter a name to identify this provider in Switchboard.
1. Optional. To configure users based on SAML group membership or use group sync, complete these fields:
   - **SAML group attribute**
   - **Admin groups**
   - **Auditor groups**
   - **External groups**
   - **Required groups**
1. In the **IdP cert fingerprint** text box, enter your IdP certificate fingerprint. This value is a SHA1 checksum of your IdP's `X.509` certificate fingerprint.
1. In the **IdP SSO target URL** text box, enter the URL endpoint on your IdP where GitLab Dedicated redirects users to authenticate with this provider.
1. From the **Name identifier format** dropdown list, select the format of the NameID that this provider sends to GitLab.
1. Optional. To configure request signing, complete these fields:
   - **Issuer**
   - **Attribute statements**
   - **Security**
1. To start using this provider, select the **Enable this provider** checkbox.
1. Select **Save**.
1. To add another SAML provider, select **Add SAML provider** again and follow the steps above. You can add up to ten providers.
1. Scroll up to the top of the page. The **Initiated changes** banner explains that your SAML configuration changes are applied during the next maintenance window. To apply the changes immediately, select **Apply changes now**.

After the changes are applied, you can sign in to your GitLab Dedicated instance using this SAML provider. To use group sync, [configure the SAML group links](../../../user/group/saml_sso/group_sync.md#configure-saml-group-links).

## Verify your SAML configuration

To verify that your SAML configuration is successful:

1. Sign out and go to your GitLab Dedicated instance's sign-in page.
1. Check that the SSO button for your SAML provider appears on the sign-in page.
1. Go to the metadata URL of your instance (`https://INSTANCE-URL/users/auth/saml/metadata`).
   The metadata URL shows information that can simplify configuration of your identity provider
   and helps validate your SAML settings.
1. Try signing in through the SAML provider to ensure the authentication flow works correctly.

If troubleshooting information, see [troubleshooting SAML](../../../user/group/saml_sso/troubleshooting.md).

## Add a SAML provider with a Support Request

If you are unable to use Switchboard to add or update SAML for your GitLab Dedicated instance, then you can open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650):

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

{{< alert type="note" >}}

Because SAML request signing requires certificate signing, you must complete these steps to use SAML with this feature enabled.

{{< /alert >}}

To enable SAML request signing:

1. Open a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) and indicate that you want request signing enabled.
1. GitLab will work with you on sending the Certificate Signing Request (CSR) for you to sign. Alternatively, the CSR can be signed with a public CA.
1. After the certificate is signed, you can then use the certificate and its associated private key to complete the `security` section of the [SAML configuration](#add-a-saml-provider-with-switchboard) in Switchboard.

Authentication requests from GitLab to your identity provider can now be signed.

## SAML groups

With SAML groups you can configure GitLab users based on SAML group membership.

To enable SAML groups, add the [required elements](../../../integration/saml.md#configure-users-based-on-saml-group-membership) to your SAML configuration in [Switchboard](#add-a-saml-provider-with-switchboard) or to the SAML block you provide in a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).

## Group sync

With [group sync](../../../user/group/saml_sso/group_sync.md), you can sync users across identity provider groups to mapped groups in GitLab.

To enable group sync:

1. Add the [required elements](../../../user/group/saml_sso/group_sync.md#configure-saml-group-sync) to your SAML configuration in [Switchboard](#add-a-saml-provider-with-switchboard) or to the SAML configuration block you provide in a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Configure the [Group Links](../../../user/group/saml_sso/group_sync.md#configure-saml-group-links).
