---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAML SSO for GitLab.com groups
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

Users can sign in to GitLab through their SAML identity provider.

[SCIM](scim_setup.md) synchronizes users with the group on GitLab.com.

- When you add or remove a user from the SCIM app, SCIM adds or removes the user
  from the GitLab group.
- If the user is not already a group member, the user is added to the group as part of the sign-in process.

You can configure SAML SSO for the top-level group only.

## Set up your identity provider

The SAML standard means that you can use a wide range of identity providers with GitLab. Your identity provider might have relevant documentation. It can be generic SAML documentation or specifically targeted for GitLab.

When setting up your identity provider, use the following provider-specific documentation
to help avoid common issues and as a guide for terminology used.

For identity providers not listed, you can refer to the [instance SAML notes on configuring an identity provider](../../../integration/saml.md#configure-saml-on-your-idp)
for additional guidance on information your provider may require.

GitLab provides the following information for guidance only.
If you have any questions on configuring the SAML app, contact your provider's support.

If you are having issues setting up your identity provider, see the
[troubleshooting documentation](#troubleshooting).

### Azure

To set up SSO with Azure as your identity provider:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > SAML SSO**.
1. Note the information on this page.
1. Go to Azure, [create a non-gallery application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-application-gallery#create-your-own-application), and [configure SSO for an application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso). The following GitLab settings correspond to the Azure fields.

   | GitLab setting                           | Azure field                                    |
   | -----------------------------------------| ---------------------------------------------- |
   | **Identifier**                           | **Identifier (Entity ID)**                     |
   | **Assertion consumer service URL**       | **Reply URL (Assertion Consumer Service URL)** |
   | **GitLab single sign-on URL**            | **Sign on URL**                                |
   | **Identity provider single sign-on URL** | **Login URL**                                  |
   | **Certificate fingerprint**              | **Thumbprint**                                 |

1. You should set the following attributes:
   - **Unique User Identifier (Name ID)** to `user.objectID`.
      - **Name identifier format** to `persistent`. For more information, see how to [manage user SAML identity](#manage-user-saml-identity).
   - **Additional claims** to [supported attributes](#configure-assertions).

1. Make sure the identity provider is set to have provider-initiated calls
   to link existing GitLab accounts.

1. Optional. If you use [Group Sync](group_sync.md), customize the name of the
   group claim to match the required attribute.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
View a demo of [SCIM provisioning on Azure using SAML SSO for groups](https://youtu.be/24-ZxmTeEBU). The `objectID` mapping is outdated in this video. Follow the [SCIM documentation](scim_setup.md#configure-microsoft-entra-id-formerly-azure-active-directory) instead.

For more information, see an [example configuration page](example_saml_config.md#azure-active-directory).

### Google Workspace

To set up Google Workspace as your identity provider:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > SAML SSO**.
1. Note the information on this page.
1. Follow the instructions for [setting up SSO with Google as your identity provider](https://support.google.com/a/answer/6087519?hl=en). The following GitLab settings correspond to the Google Workspace fields.

   | GitLab setting                           | Google Workspace field |
   |:-----------------------------------------|:-----------------------|
   | **Identifier**                           | **Entity ID**          |
   | **Assertion consumer service URL**       | **ACS URL**            |
   | **GitLab single sign-on URL**            | **Start URL**          |
   | **Identity provider single sign-on URL** | **SSO URL**            |

1. Google Workspace displays a SHA256 fingerprint. To retrieve the SHA1 fingerprint
   required by GitLab to [configure SAML](#configure-gitlab):
   1. Download the certificate.
   1. Run this command:

      ```shell
      openssl x509 -noout -fingerprint -sha1 -inform pem -in "GoogleIDPCertificate-domain.com.pem"
      ```

1. Set these values:
   - For **Primary email**: `email`.
   - For **First name**: `first_name`.
   - For **Last name**: `last_name`.
   - For **Name ID format**: `EMAIL`.
   - For **NameID**: `Basic Information > Primary email`.
     For more information, see [supported attributes](#configure-assertions).

1. Make sure the identity provider is set to have provider-initiated calls
   to link existing GitLab accounts.

On the GitLab SAML SSO page, when you select **Verify SAML Configuration**, disregard
the warning that recommends setting the **NameID** format to `persistent`.

For more information, see an [example configuration page](example_saml_config.md#google-workspace).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
View a demo of [how to configure SAML with Google Workspaces and set up Group Sync](https://youtu.be/NKs0FSQVfCY).

### Okta

To set up SSO with Okta as your identity provider:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > SAML SSO**.
1. Note the information on this page.
1. Follow the instructions for [setting up a SAML application in Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/).

   The following GitLab settings correspond to the Okta fields.

   | GitLab setting                           | Okta field                                                     |
   | ---------------------------------------- | -------------------------------------------------------------- |
   | **Identifier**                           | **Audience URI**                                               |
   | **Assertion consumer service URL**       | **Single sign-on URL**                                         |
   | **GitLab single sign-on URL**            | **Login page URL** (under **Application Login Page** settings) |
   | **Identity provider single sign-on URL** | **Identity Provider Single Sign-On URL**                       |

1. Under the Okta **Single sign-on URL** field, select the **Use this for Recipient URL and Destination URL** checkbox.

1. Set these values:
   - For **Application username (NameID)**: **Custom** `user.getInternalProperty("id")`.
   - For **Name ID Format**: `Persistent`. For more information, see [manage user SAML identity](#manage-user-saml-identity).
   - For **email**: `user.email` or similar.
   - For additional **Attribute Statements**, see [supported attributes](#configure-assertions).

1. Make sure the identity provider is set to have provider-initiated calls
   to link existing GitLab accounts.

The Okta GitLab application available in the App Catalog only supports [SCIM](scim_setup.md). Support
for SAML is proposed in [issue 216173](https://gitlab.com/gitlab-org/gitlab/-/issues/216173).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the Okta SAML setup including SCIM, see [Demo: Okta Group SAML & SCIM setup](https://youtu.be/0ES9HsZq0AQ).

For more information, see an [example configuration page](example_saml_config.md#okta)

### OneLogin

OneLogin supports its own [GitLab (SaaS) application](https://onelogin.service-now.com/support?id=kb_article&sys_id=08e6b9d9879a6990c44486e5cebb3556&kb_category=50984e84db738300d5505eea4b961913).

To set up OneLogin as your identity provider:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > SAML SSO**.
1. Note the information on this page.
1. If you use the OneLogin generic
   [SAML Test Connector (Advanced)](https://onelogin.service-now.com/support?id=kb_article&sys_id=b2c19353dbde7b8024c780c74b9619fb&kb_category=93e869b0db185340d5505eea4b961934),
   you should [use the OneLogin SAML Test Connector](https://onelogin.service-now.com/support?id=kb_article&sys_id=93f95543db109700d5505eea4b96198f). The following GitLab settings correspond
   to the OneLogin fields:

   | GitLab setting                                       | OneLogin field                   |
   | ---------------------------------------------------- | -------------------------------- |
   | **Identifier**                                       | **Audience**                     |
   | **Assertion consumer service URL**                   | **Recipient**                    |
   | **Assertion consumer service URL**                   | **ACS (Consumer) URL**           |
   | **Assertion consumer service URL (escaped version)** | **ACS (Consumer) URL Validator** |
   | **GitLab single sign-on URL**                        | **Login URL**                    |
   | **Identity provider single sign-on URL**             | **SAML 2.0 Endpoint**            |

1. For **NameID**, use `OneLogin ID`. For more information, see [manage user SAML identity](#manage-user-saml-identity).
1. Configure [required and supported attributes](#configure-assertions).
1. Make sure the identity provider is set to have provider-initiated calls
   to link existing GitLab accounts.

### Configure assertions

NOTE:
These attributes are case-insensitive.

At minimum, you must configure the following assertions:

1. [NameID](#manage-user-saml-identity).
1. Email.

Optionally, you can pass user information to GitLab as attributes in the SAML assertion.

- The user's email address can be an **email** or **mail** attribute.
- The username can be either a **username** or **nickname** attribute. You should specify only
  one of these.

For more information on available attributes, see [SAML SSO for GitLab Self-Managed](../../../integration/saml.md#configure-assertions).

### Use metadata

To configure some identity providers, you need a GitLab metadata URL.
To find this URL:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > SAML SSO**.
1. Copy the provided **GitLab metadata URL**.
1. Follow your identity provider's documentation and paste the metadata URL when it's requested.

Check your identity provider's documentation to see if it supports the GitLab metadata URL.

### Manage the identity provider

After you have set up your identity provider, you can:

- Change the identity provider.
- Change email domains.

#### Change the identity provider

You can change to a different identity provider. During the change process,
users cannot access any of the SAML groups. To mitigate this, you can disable
[SSO enforcement](#sso-enforcement).

To change identity providers:

1. [Configure](#set-up-your-identity-provider) the group with the new identity provider.
1. Optional. If the **NameID** is not identical, [change the **NameID** for users](#manage-user-saml-identity).

#### Change email domains

To migrate users to a new email domain, tell users to:

1. [Add their new email](../../profile/_index.md#change-your-primary-email) as the primary email to their accounts and verify it.
1. Optional. Remove their old email from the account.

If the **NameID** is configured with the email address, [change the **NameID** for users](#manage-user-saml-identity).

## Configure GitLab

> - Ability to set a custom role as the default membership role [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/417285) in GitLab 16.7.

After you set up your identity provider to work with GitLab, you must configure GitLab to use it for authentication:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > SAML SSO**.
1. Complete the fields:
   - In the **Identity provider single sign-on URL** field, enter the SSO URL from your identity provider.
   - In the **Certificate fingerprint** field, enter the fingerprint for the SAML token signing certificate.
1. For groups on GitLab.com: in the **Default membership role** field, select:
   1. The role to assign to new users.
   1. The role to assign to
      [users who are not members of a mapped SAML group](group_sync.md#automatic-member-removal)
      when SAML Group Links is configured for the group.
1. For groups on self-managed instances: in the **Default membership role** field,
   select the role to assign to new users.
   The default role is **Guest**. That role becomes the starting role of all users
   added to the group:
   - In GitLab 16.7 and later, group Owners can set a [custom role](../../custom_roles.md)
   - In GitLab 16.6 and earlier, group Owners can set a default membership role other than **Guest**.
     as the default membership role.
1. Select the **Enable SAML authentication for this group** checkbox.
1. Optional. Select:
   - In GitLab 17.4 and later, **Disable password authentication for enterprise users**.
     For more information, see the [Disable password authentication for enterprise users documentation](#disable-password-authentication-for-enterprise-users).
   - **Enforce SSO-only authentication for web activity for this group**.
   - **Enforce SSO-only authentication for Git and Dependency Proxy activity for this group**.
     For more information, see the [SSO enforcement documentation](#sso-enforcement).
1. Select **Save changes**.

NOTE:
The certificate [fingerprint algorithm](../../../integration/saml.md#configure-saml-on-your-idp) must be in SHA1. When configuring the identity provider (such as [Google Workspace](#google-workspace)), use a secure signature algorithm.

If you are having issues configuring GitLab, see the [troubleshooting documentation](#troubleshooting).

## User access and management

After group SSO is configured and enabled, users can access the GitLab.com group through the identity provider's dashboard.
If [SCIM](scim_setup.md) is configured, see [user access](scim_setup.md#user-access) on the SCIM page.

When a user tries to sign in with Group SSO, GitLab attempts to find or create a user based on the following:

- Find an existing user with a matching SAML identity. This would mean the user either had their account created by [SCIM](scim_setup.md) or they have previously signed in with the group's SAML IdP.
- If an account does not already exist with the same email address, create a new account automatically. GitLab tries to match both the primary and secondary email addresses.
- If an account already exists with the same email address, redirect the user to the sign-in page to:
  - Create a new account with another email address.
  - Sign-in to their existing account to link the SAML identity.

### Link SAML to your existing GitLab.com account

> - **Remember me** checkbox [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/121569) in GitLab 15.7.

NOTE:
If the user is an [enterprise user](../../enterprise_user/_index.md) of that group, the following steps do not apply. The enterprise user must instead [sign in with a SAML account that has the same email as the GitLab account](#returning-users-automatic-identity-relinking). This allows GitLab to link the SAML account to the existing account.

To link SAML to your existing GitLab.com account:

1. Sign in to your GitLab.com account. [Reset your password](https://gitlab.com/users/password/new)
   if necessary.
1. Locate and visit the **GitLab single sign-on URL** for the group you're signing
   in to. A group owner can find this on the group's **Settings > SAML SSO** page.
   If the sign-in URL is configured, users can connect to the GitLab app from the identity provider.
1. Optional. Select the **Remember me** checkbox to stay signed in to GitLab for 2 weeks.
   You may still be asked to re-authenticate with your SAML provider more frequently.
1. Select **Authorize**.
1. Enter your credentials on the identity provider if prompted.
1. You are then redirected back to GitLab.com and should now have access to the group.
   In the future, you can use SAML to sign in to GitLab.com.

If a user is already a member of the group, linking the SAML identity does not
change their role.

On subsequent visits, you should be able to [sign in to GitLab.com with SAML](#sign-in-to-gitlabcom-with-saml)
or by visiting links directly. If the **enforce SSO** option is turned on, you
are then redirected to sign in through the identity provider.

### Sign in to GitLab.com with SAML

1. Sign in to your identity provider.
1. From the list of apps, select the "GitLab.com" app. (The name is set by the administrator of the identity provider.)
1. You are then signed in to GitLab.com and redirected to the group.

### Manage user SAML identity

> - Update of SAML identities using the SAML API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

GitLab.com uses the SAML **NameID** to identify users. The **NameID** is:

- A required field in the SAML response.
- Case sensitive.

The **NameID** must:

- Be unique to each user.
- Be a persistent value that never changes, such as a randomly generated unique user ID.
- Match exactly on subsequent sign-in attempts, so it should not rely on user input
  that could change between upper and lower case.

The **NameID** should not be an email address or username because:

- Email addresses and usernames are more likely to change over time. For example,
  when a person's name changes.
- Email addresses are case-insensitive, which can result in users being unable to
  sign in.

The **NameID** format must be `Persistent`, unless you are using a field, like email, that
requires a different format. You can use any format except `Transient`.

#### Change user **NameID**

Group owners can use the [SAML API](../../../api/saml.md#update-extern_uid-field-for-a-saml-identity) to change their group members' **NameID** and update their SAML identities.

If [SCIM](scim_setup.md) is configured, group owners can update the SCIM identities using the [SCIM API](../../../api/scim.md#update-extern_uid-field-for-a-scim-identity).

Alternatively, ask the users to reconnect their SAML account.

1. Ask relevant users to [unlink their account from the group](#unlink-accounts).
1. Ask relevant users to [link their account to the new SAML app](#link-saml-to-your-existing-gitlabcom-account).

WARNING:
After users have signed into GitLab using SSO SAML, changing the **NameID** value
breaks the configuration and could lock users out of the GitLab group.

For more information on the recommended value and format for specific identity
providers, see [set up your identity provider](#set-up-your-identity-provider).

### Configure enterprise user settings from SAML response

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/412898) to configure only enterprise user settings in GitLab 16.7.

GitLab allows setting certain user attributes based on values from the SAML response.
An existing user's attributes are updated from the SAML response values if that
user is an [enterprise user](../../enterprise_user/_index.md) of the group.

#### Supported user attributes

- **can_create_group** - `true` or `false` to indicate whether an enterprise user can create
  new top-level groups. Default is `true`.
- **projects_limit** - The total number of personal projects an enterprise user can create.
  A value of `0` means the user cannot create new projects in their personal
  namespace. Default is `100000`.

#### Example SAML response

You can find SAML responses in the developer tools or console of your browser,
in base64-encoded format. Use the base64 decoding tool of your choice to
convert the information to XML. An example SAML response is shown here.

```xml
   <saml2:AttributeStatement>
      <saml2:Attribute Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.email</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="username" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
        <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.nickName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="first_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.firstName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="last_name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">user.lastName</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="can_create_group" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">true</saml2:AttributeValue>
      </saml2:Attribute>
      <saml2:Attribute Name="projects_limit" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified">
         <saml2:AttributeValue xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">10</saml2:AttributeValue>
      </saml2:Attribute>
   </saml2:AttributeStatement>
```

### Bypass user email confirmation with verified domains

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238461) in GitLab 15.4.

By default, users provisioned with SAML or SCIM are sent a verification email to verify their identity. Instead, you can
[configure GitLab with a custom domain](../../enterprise_user/_index.md#set-up-a-verified-domain) and GitLab
automatically confirms user accounts. Users still receive an
[enterprise user](../../enterprise_user/_index.md) welcome email. Confirmation is bypassed if both of the following are true:

- The user is provisioned with SAML or SCIM.
- The user has an email address that belongs to the verified domain.

### Disable password authentication for enterprise users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/373718) in GitLab 17.4.

Prerequisites:

- You must have the Owner role for the group that the enterprise user belongs to.
- Group SSO must be enabled.

You can disable password authentication for all [enterprise users](../../enterprise_user/_index.md) in a group. This also applies to enterprise users who are administrators of the group. Configuring this setting stops enterprise users from changing, resetting, or authenticating with their password. Instead, these users can authenticate with:

- The group SAML IdP for the GitLab web UI.
- A personal access token for the GitLab API and Git with HTTP Basic Authentication unless the group has [disabled personal access tokens for enterprise users](../../profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users).

To disable password authentication for enterprise users:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > SAML SSO**.
1. Under **Configuration**, select **Disable password authentication for enterprise users**.
1. Select **Save changes**.

#### Returning users (Automatic Identity Relinking)

If an enterprise user is removed from the group and then returns, they can sign in with their enterprise SSO account.
As long as the user's email address in the identity provider remains the same as the email address on the existing GitLab account, the SSO identity is automatically linked to the account and the user can sign in without any issues.

### Block user access

To rescind a user's access to the group when only SAML SSO is configured, either:

- Remove (in order) the user from:
  1. The user data store on the identity provider or the list of users on the specific app.
  1. The GitLab.com group.
- Use [Group Sync](group_sync.md#automatic-member-removal) at the top-level of
  your group with the default role set to [minimal access](../../permissions.md#users-with-minimal-access)
  to automatically block access to all resources in the group.

To rescind a user's access to the group when also using SCIM, refer to [Remove access](scim_setup.md#remove-access).

### Unlink accounts

Users can unlink SAML for a group from their profile page. This can be helpful if:

- You no longer want a group to be able to sign you in to GitLab.com.
- Your SAML **NameID** has changed and so GitLab can no longer find your user.

WARNING:
Unlinking an account removes all roles assigned to that user in the group.
If a user re-links their account, roles need to be reassigned.

Groups require at least one owner. If your account is the only owner in the
group, you are not allowed to unlink the account. In that case, set up another user as a
group owner, and then you can unlink the account.

For example, to unlink the `MyOrg` account:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Service sign-in** section, select **Disconnect** next to the connected account.

## SSO enforcement

> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/215155) in GitLab 15.5 [with a flag](../../../administration/feature_flags.md) named `transparent_sso_enforcement` to include transparent enforcement even when SSO enforcement is not enabled. Disabled on GitLab.com.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/375788) in GitLab 15.8 by enabling transparent SSO by default on GitLab.com.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/389562) in GitLab 15.10. Feature flag `transparent_sso_enforcement` removed.

On GitLab.com, SSO is enforced:

- When SAML SSO is enabled.
- For users with an existing SAML identity when accessing groups and projects in the organization's
  group hierarchy. By using their GitLab.com credentials, users can view other groups and projects outside their organization, as well as their user settings, without signing in through SAML SSO.

A user has a SAML identity if one or both of the following are true:

- They have signed in to GitLab by using their GitLab group's single sign-on URL.
- They were provisioned by SCIM.

Users are not prompted to sign in through SSO on each visit. GitLab checks
whether a user has authenticated through SSO. If the user last signed in more
than 24 hours ago, GitLab prompts the user to sign in again through SSO.

SSO is enforced as follows:

| Project/Group visibility | Enforce SSO setting | Member with identity | Member without identity | Non-member or not signed in |
|--------------------------|---------------------|----------------------|-------------------------|-----------------------------|
| Private                  | Off                 | Enforced             | Not enforced            | Not enforced                |
| Private                  | On                  | Enforced             | Enforced                | Enforced                    |
| Public                   | Off                 | Enforced             | Not enforced            | Not enforced                |
| Public                   | On                  | Enforced             | Enforced                | Not enforced                |

An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/297389) to add a similar SSO requirement for API activity. Until this requirement is added, you can use features that rely on APIs without an active SSO session.

### SSO-only for web activity enforcement

When the **Enforce SSO-only authentication for web activity for this group** option is enabled:

- All members must access GitLab by using their GitLab group's single sign-on URL
  to access group resources, regardless of whether they have an existing SAML
  identity.
- SSO is enforced when users access groups and projects in the organization's
  group hierarchy. Users can view other groups and projects outside their organization without signing in through SAML SSO.
- Users cannot be added as new members manually.
- Users with the Owner role can use the standard sign in process to make
  necessary changes to top-level group settings.
- For non-members or users who are not signed in:
  - SSO is not enforced when they access public group resources.
  - SSO is enforced when they access private group resources.
- For items in the organization's group hierarchy, dashboard visibility is as
  follows:
  - SSO is enforced when viewing your [To-Do List](../../todos.md). Your
    to-do items are hidden if your SSO session has expired, and an
    [alert is shown](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115254).
  - SSO is enforced when viewing your list of assigned issues. Your issues are
    hidden if your SSO session has expired.
    [Issue 414475](https://gitlab.com/gitlab-org/gitlab/-/issues/414475) proposes to change this
    behavior so that issues are visible.
  - SSO is not enforced when viewing lists of merge requests where you are the
    assignee or your review is requested. You can see merge requests even if
    your SSO session has expired.

SSO enforcement for web activity has the following effects when enabled:

- For groups, users cannot share a project in the group outside the top-level
  group, even if the project is forked.
- Git activity originating from CI/CD jobs do not have the SSO check enforced.
- Credentials that are not tied to regular users (for example, project and group
  access tokens, and deploy keys) do not have the SSO check enforced.
- Users must be signed-in through SSO before they can pull images using the
  [Dependency Proxy](../../packages/dependency_proxy/_index.md).
- When the **Enforce SSO-only authentication for Git and Dependency Proxy
  activity for this group** option is enabled, any API endpoint that involves
  Git activity is under SSO enforcement. For example, creating or deleting a
  branch, commit, or tag. For Git activity over SSH and HTTPS, users must
  have at least one active session signed-in through SSO before they can push to or
  pull from a GitLab repository. The active session can be on a different device.

When SSO for web activity is enforced, non-SSO group members do not lose access
immediately. If the user:

- Has an active session, they can continue accessing the group for up to 24
  hours until the identity provider session times out.
- Is signed out, they cannot access the group after being removed from the
  identity provider.

## Migrate to a new identity provider

To migrate to a new identity provider, use the [SAML API](../../../api/saml.md) to update all of your group member's identities.

For example:

1. Set a maintenance window to ensure that no users are active at that time.
1. Use the SAML API [to update each user's identity](../../../api/saml.md#update-extern_uid-field-for-a-saml-identity).
1. Configure the new identity provider.
1. Test that sign in works.

## Related topics

- [SAML SSO for GitLab Self-Managed](../../../integration/saml.md)
- [Glossary](../../../integration/saml.md#glossary)
- [Blog post: The ultimate guide to enabling SAML and SSO on GitLab.com](https://about.gitlab.com/blog/2023/09/14/the-ultimate-guide-to-enabling-saml/)
- [Authentication comparison between SaaS and self-managed](../../../administration/auth/_index.md#gitlabcom-compared-to-gitlab-self-managed)
- [Passwords for users created through integrated authentication](../../../security/passwords_for_integrated_authentication_methods.md)
- [SAML Group Sync](group_sync.md)

## Troubleshooting

If you find it difficult to match the different SAML terms between GitLab and the
identity provider:

1. Check your identity provider's documentation. Look at their example SAML
   configurations for information on the terms they use.
1. Check the [SAML SSO for GitLab Self-Managed documentation](../../../integration/saml.md).
   The GitLab Self-Managed SAML configuration file supports more options
   than the GitLab.com file. You can find information on the self-managed instance
   file in the:
   - External [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml/).
   - [`ruby-saml` library](https://github.com/onelogin/ruby-saml).
1. Compare the XML response from your provider with our
   [example XML used for internal testing](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/fixtures/saml/response.xml).

For other troubleshooting information, see the [troubleshooting SAML guide](troubleshooting.md).
