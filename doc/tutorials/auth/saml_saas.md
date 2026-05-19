---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutorial: Set up SAML SSO for GitLab.com groups'
---

This tutorial walks you through setting up SAML single sign-on (SSO) for a GitLab.com group using
an Identity Provider (IdP) such as Okta or Microsoft Entra ID. When you finish, members of your group
can sign in to GitLab through the IdP.

In this tutorial, you:

1. Configure SAML through an IdP application.
1. Configure SAML SSO in your GitLab group.
1. Test the SAML connection.
1. Link a user account to verify the setup.

## Before you begin

Prerequisites:

- You must have the Owner role for a GitLab Premium or Ultimate group on GitLab.com.
- You must have administrator access to your IdP.
- You must have at least one test user account in your IdP.
- You should be familiar with single sign-on concepts.

Time to complete: 20-30 minutes

## Step 1: Gather GitLab information

Before you can set up anything in your IdP, you must get some connection details from GitLab
that tell your IdP how to communicate with your GitLab group.

To gather the GitLab information:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **SAML SSO**.
1. Note these values:
   - **Identifier**
   - **Assertion consumer service URL**
   - **GitLab single sign-on URL**

## Step 2: Create an IdP application

Now that you have your GitLab details ready, create an application in your IdP.
This application maps the GitLab information to the IdP and configures how user
information flows between the two systems.

To create an IdP application:

{{< tabs >}}

{{< tab title="Okta" >}}

1. Sign in to Okta as an administrator.
1. In the Admin Console, select **Applications** > **Applications**.
1. Select **Create App Integration**.
1. In the **Sign-in method** section, select **SAML 2.0**.
1. Select **Next**.
1. On the **General Settings** tab, enter a name for your application. For example, `GitLab SAML`.
1. Select **Next**.
1. On the **Configure SAML** tab, complete the fields with the values from Step 1:
   - **Single sign-on URL**: Enter the **Assertion consumer service URL**.
   - Select the **Use this for Recipient URL and Destination URL** checkbox.
   - **Audience URI (SP Entity ID)**: Enter the **Identifier**.
1. Configure the name identifier:
   - **Application username (NameID)**: Select **Custom** and enter `user.getInternalProperty("id")`.
   - **Name ID Format**: Select **Persistent**.
1. In the **Attribute Statements (optional)** section, add this attribute:
   - **Name**: `email`
   - **Value**: `user.email`
1. Scroll down to **Application Login Page** settings:
   - **Login page URL**: Enter the **GitLab single sign-on URL**.
1. Select **Next**.
1. On the **Feedback** tab, select the appropriate options for your use case.
1. Select **Finish**.

The SAML application is created in Okta.

> [!note]
> For more information about SAML attributes and advanced configuration options,
> see the [SAML SSO documentation](../../user/group/saml_sso/_index.md#okta).

{{< /tab >}}

{{< tab title="Entra ID" >}}

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com/).
1. Select **Identity** > **Applications** > **Enterprise applications**.
1. Select **New application**.
1. Select **Create your own application**.
1. In the dialog, complete the fields:
   - **Name**: Enter a name for your application. For this tutorial, use `GitLab SAML`.
   - Select **Integrate any other application you don't find in the gallery (Non-gallery)**.
1. Select **Create**.

The enterprise application is created in Microsoft Entra ID.

1. In your enterprise application, select **Single sign-on** from the left sidebar.
1. Select **SAML** as the single sign-on method.
1. In the **Basic SAML Configuration** section, select **Edit**.
1. Complete the fields with the values from Step 1:
   - **Identifier (Entity ID)**: Enter the **Identifier**.
   - **Reply URL (Assertion Consumer Service URL)**: Enter the **Assertion consumer service URL**.
   - **Sign on URL**: Enter the **GitLab single sign-on URL**.
1. Select **Save**.
1. In the **User Attributes & Claims** section, select **Edit**.
1. Select **Add new claim** and complete the fields:
   - **Name**: Enter `email`.
   - **Source attribute**: Select `user.mail`.
1. Select **Save**.
1. Edit the **Unique User Identifier (Name ID)** claim:
   - Select the existing **Unique User Identifier** claim.
   - **Source attribute**: Select `user.objectid`.
   - **Name identifier format**: Select **Persistent**.
1. Select **Save**.

> [!note]
> For more information about SAML attributes and advanced configuration options,
> see the [SAML SSO documentation](../../user/group/saml_sso/_index.md#azure).

{{< /tab >}}

{{< tab title="Google Workspace" >}}

1. Sign in to the [Google Admin console](https://admin.google.com/).
1. Select **Apps** > **Web and mobile apps**.
1. Select **Add App** > **Add custom SAML app**.
1. In the **App Details** page, enter a name for your application. For example, `GitLab SAML`.
1. Select **Continue**.
1. On the **Google Identity Provider details** page, leave this page open. You need these values in Step 3.
1. Select **Continue**.
1. On the **Service provider details** page, complete the fields with the values from Step 1:
   - **ACS URL**: Enter the **Assertion consumer service URL**.
   - **Entity ID**: Enter the **Identifier**.
   - **Start URL**: Enter the **GitLab single sign-on URL**.
   - **Name ID format**: Select **EMAIL**.
   - **Name ID**: Select **Basic Information** > **Primary email**.
1. Select **Continue**.
1. On the **Attribute mapping** page, add these attributes:
   - **Google Directory attribute**: `Primary email`, **App attribute**: `email`
   - **Google Directory attribute**: `First name`, **App attribute**: `first_name`
   - **Google Directory attribute**: `Last name`, **App attribute**: `last_name`
1. Select **Finish**.
   The SAML application is created in Google Workspace.
1. Turn on the application for your users:
   - On the **User access** section, select **ON for everyone**.
   - Select **Save**.

For more information about SAML attributes and advanced configuration options,
see the [SAML SSO documentation](../../user/group/saml_sso/_index.md#google-workspace).

{{< /tab >}}

{{< tab title="OneLogin" >}}

1. Sign in to OneLogin as an administrator.
1. Select **Administration** > **Applications**.
1. Select **Add App**.
1. Search for **SAML Test Connector (Advanced)** and select it.
1. In the **Display Name** field, enter a name for your application. For example, `GitLab SAML`.
1. Select **Save**.
1. Select the **Configuration** tab.
1. Complete the fields with the values from Step 1:
   - **Audience (EntityID)**: Enter the **Identifier**.
   - **Recipient**: Enter the **Assertion consumer service URL**.
   - **ACS (Consumer) URL Validator**: Enter the **Assertion consumer service URL** as a regex.
     For example, `https://gitlab\.com/groups/your-group/-/saml/callback`.
   - **ACS (Consumer) URL**: Enter the **Assertion consumer service URL**.
   - **Login URL**: Enter the **GitLab single sign-on URL**.
1. Select **Save**.
1. Select the **Parameters** tab.
1. Add the required attribute by selecting **Add parameter**:
   - **Field name**: `email`, **Value**: Email
1. For **NameID**, select **OneLogin ID** in the value field.
1. Select **Save**.
1. Select the **Access** tab to assign users or roles to the application.

The SAML application is created in OneLogin.

For more information about SAML attributes and advanced configuration options,
see the [SAML SSO documentation](../../user/group/saml_sso/_index.md#onelogin).

{{< /tab >}}

{{< tab title="Keycloak" >}}

1. Sign in to Keycloak as an administrator.
1. Go to **Clients** and select **Create client**.
1. In the **General Settings** page, select **SAML** as the **Client type**.
1. Complete the fields with the values from Step 1:
   - **Client ID**: Enter the **Identifier**.
   - **Valid redirect URIs**: Enter the **Assertion consumer service URL**.
   - **Assertion Consumer Service POST Binding URL**: Enter the **Assertion consumer service URL**.
   - **Home URL**: Enter the **GitLab single sign-on URL**.
1. Select **Save**.
1. On the **Settings** tab, in the **SAML capabilities** section:
   - **Name ID format**: Select `persistent`.
   - Turn on the **Force name ID format** toggle.
   - Turn on the **Force POST binding** toggle.
   - Turn on the **Include AuthnStatement** toggle.
1. In the **Signature and Encryption** section, turn on the **Sign documents** toggle.
1. On the **Keys** tab, make sure all sections are disabled.
1. On the **Client scopes** tab:
   - Select the client scope for GitLab.
   - Select **Configure a new mapper**, and select **User Attribute** in the window that opens.
   - On the **Add mapper** page, set the **Name**, **User Attribute**, and **SAML Attribute Name** fields to `email`.
   - Select **Save**.

The SAML client is created in Keycloak.

> [!note]
> For more information about SAML attributes and advanced configuration options,
> see the [SAML SSO documentation](../../user/group/saml_sso/_index.md#keycloak).

{{< /tab >}}

{{< tab title="AWS IAM Identity Center" >}}

1. Sign in to the AWS IAM Identity Center console.
1. Select **Applications**, then select **Add application**.
1. Select **I have an application I want to set up**.
1. Select **SAML 2.0** as the application type.
1. Select **Next**.
1. On the **Configure application** page, enter a display name for your application. For example, `GitLab SAML`.
1. Complete the fields with the values from Step 1:
   - **Application ACS URL**: Enter the **Assertion consumer service URL**.
   - **Application SAML audience**: Enter the **Identifier**.
   - **Application start URL**: Enter the **GitLab single sign-on URL**.
1. Under **Attribute mappings**, configure these attributes:
   - **Subject**: `${user:email}`, **Format**: `unspecified`
   - **email**: `${user:email}`, **Format**: `unspecified`
   - **first_name**: `${user:givenName}`, **Format**: `unspecified`
   - **last_name**: `${user:familyName}`, **Format**: `unspecified`

   > [!warning]
   > To avoid authentication errors for existing GitLab users, do not set the format to
   > `persistent` or `transient`.

1. Select **Submit**.
   The SAML application is created in AWS IAM Identity Center.
1. Assign users to the GitLab application.

For more information about SAML attributes and advanced configuration options,
see the [SAML SSO documentation](../../user/group/saml_sso/_index.md#aws-iam-identity-center).

> [!note]
> AWS IAM Identity Center defaults to IdP-initiated login. To link existing GitLab accounts,
> users must sign in from the **GitLab single sign-on URL** or the **Application start URL**.

{{< /tab >}}

{{< /tabs >}}

## Step 3: Gather the connection details

Now retrieve the information that GitLab needs to send authentication requests to the IdP.

To gather the connection details:

{{< tabs >}}

{{< tab title="Okta" >}}

1. In your Okta SAML app, select the **Sign On** tab.
1. On the right side, select **View SAML setup instructions**.
1. Note the **Identity Provider Single Sign-On URL**.
1. Generate a certificate fingerprint:
   1. In the **X.509 Certificate** field, copy the text and save it locally.
   1. Open a terminal and go to the directory where you saved the certificate file.
   1. Run this command to generate the certificate fingerprint:

   ```shell
      # Replace `<certificate_filename>` with the actual filename of your downloaded certificate.
      # You might need to install OpenSSL or use an alternative method to generate the fingerprint.
       openssl x509 -noout -fingerprint -sha256 -in <certificate_filename>.crt
   ```

1. Copy the fingerprint value after `SHA256 Fingerprint=`.
   The fingerprint looks like `A1:B2:C3:D4:E5:F6:...`.

{{< /tab >}}

{{< tab title="Entra ID" >}}

1. In your Entra ID enterprise application, select **Single sign-on**.
1. In the **Set up GitLab SAML** section, note the **Login URL**.
   The name of this section is based on the name of your enterprise application.
1. In the **SAML Signing Certificate** section, note the **Thumbprint** value.
   The thumbprint looks like `A1B2C3D4E5F6...`.

{{< /tab >}}

{{< tab title="Google Workspace" >}}

1. In your Google Workspace SAML app, go to the app details page.
1. Note the **SSO URL** value.
1. Note the **SHA-256 fingerprint** value displayed for the certificate.
   The fingerprint looks like `A1:B2:C3:D4:E5:F6:...`.

{{< /tab >}}

{{< tab title="OneLogin" >}}

1. In your OneLogin SAML app, select the **SSO** tab.
1. Note the **SAML 2.0 Endpoint (HTTP)** URL.
1. In the **X.509 Certificate** section, select **View Details**.
1. Note the **SHA-256 Fingerprint** value.
   The fingerprint looks like `A1:B2:C3:D4:E5:F6:...`.

{{< /tab >}}

{{< tab title="Keycloak" >}}

1. In your Keycloak SAML client, in the **Action** dropdown list, select **Download adapter config**.
1. In the **Download adapter config** dialog, select **mod-auth-mellon** from the dropdown list.
1. Select **Download**.
1. Extract the downloaded archive and open `idp-metadata.xml`.
1. Locate the `<md:SingleSignOnService>` tag and note the value of the `Location` attribute.
1. Generate a certificate fingerprint:
   1. Locate the `<ds:X509Certificate>` tag and copy the value to a separate file.
   1. Convert the value to PEM format. Add `-----BEGIN CERTIFICATE-----` at the beginning of the file and `-----END CERTIFICATE-----` at the end of the file as new lines.

{{< /tab >}}

{{< tab title="AWS IAM Identity Center" >}}

1. In your AWS IAM Identity Center SAML app, select the application you created.
1. In the **IAM Identity Center SAML metadata** section, note the **IAM Identity Center sign-in URL**.
1. Download the certificate.
1. Generate a certificate fingerprint:
   1. Open a terminal and go to the directory where you saved the certificate file.
   1. Run this command to generate the certificate fingerprint:

   ```shell
   # Replace `<certificate_filename>` with the actual filename of your downloaded certificate.
   # You might need to install OpenSSL or use an alternative method to generate the fingerprint.
   openssl x509 -noout -fingerprint -sha256 -in <certificate_filename>.pem
   ```

1. Copy the fingerprint value after `SHA1 Fingerprint=`.
   The fingerprint looks like `A1:B2:C3:D4:E5:F6:...`.

> [!note]
> AWS IAM Identity Center requires a SHA1 fingerprint. For more information, see
> the [SAML SSO documentation](../../user/group/saml_sso/_index.md#aws-iam-identity-center).

{{< /tab >}}

{{< /tabs >}}

## Step 4: Configure SAML SSO in GitLab

You have everything you need to complete the connection. Return to GitLab and enter
the connection details to turn on SAML authentication for your group.

To configure SAML:

1. Return to your GitLab group.
1. Select **Settings** > **SAML SSO**.
1. In the **Configuration** section, complete the fields:
   - **Identity provider single sign-on URL**: Enter the URL from Step 3.
   - **Certificate fingerprint**: Enter the fingerprint from Step 3.
1. Select the **Enable SAML authentication for this group** checkbox.
1. From the **Default membership role** dropdown list, select **Minimal Access**.
1. Select **Save changes**.

The basic SAML connection is now configured.

> [!note]
> You can set the default membership role to any role. All new users are assigned this role when
> they first sign in through SAML. Setting the default to [**Minimal Access**](../../user/permissions.md#users-with-minimal-access)
> and promoting users later reduces the risk of users having too much access.

## Step 5: Test the SAML configuration

Before you invite your team, verify that the connection works correctly.

To test the SAML configuration:

1. On the **Settings** > **SAML SSO** page, select **Verify SAML Configuration**.
   GitLab redirects you to the IdP.
1. Sign in with your IdP credentials.
1. Confirm that the IdP redirects you back to GitLab.

If you see errors, see the [troubleshooting guide](../../user/group/saml_sso/troubleshooting.md).

## Step 6: Link a user account to test the full flow

The configuration looks good. Now test the experience from a user's perspective
by linking a test account like your team members do when they first connect
to GitLab through the IdP.

To test user account linking:

1. Sign out of GitLab.
1. In a different browser or incognito window, sign in to your test GitLab account.
1. Go to the GitLab single sign-on URL you noted in Step 1.
1. Select **Authorize**.
1. When prompted, sign in with your IdP credentials.
1. Verify you are redirected to the GitLab group.

Congratulations! You have successfully linked a SAML identity to a GitLab account.

## Step 7: Optional: Turn on SSO enforcement

You have a working SAML setup. As an optional final step, you can turn on
SSO enforcement. SSO enforcement requires all group members to authenticate through the IdP,
which strengthens security. However, it prevents access through other authentication methods.

To turn on SSO enforcement:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **SAML SSO**.
1. Select **Enforce SSO-only authentication for web activity for this group**.
1. Select **Save changes**.

After you enable enforcement, all group members must sign in through the IdP before they can access group resources.

## Next steps

You've successfully set up SAML SSO for your GitLab group! Here are some things you might want to do next:

- [Set up SCIM provisioning](../../user/group/saml_sso/scim_setup.md) to automatically sync users.
- [Configure Group Sync](../../user/group/saml_sso/group_sync.md) to manage GitLab group membership based on your IdP groups.
- Verify a domain to [bypass user email confirmation](../../user/group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains) for new users.
- Review the [SSO enforcement documentation](../../user/group/saml_sso/_index.md#sso-enforcement) for advanced security options.

## Troubleshooting

If you encounter issues during this tutorial, see the following resources:

- [Common SAML errors and solutions](../../user/group/saml_sso/troubleshooting.md)
- [How to unlink and relink accounts](../../user/group/saml_sso/_index.md#unlink-accounts)
- [Support resources](https://about.gitlab.com/support/)
