---
type: reference, howto
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# SAML SSO for GitLab.com groups **(PREMIUM SAAS)**

> Introduced in GitLab 11.0.

This page describes SAML for groups. For instance-wide SAML on self-managed GitLab instances, see [SAML OmniAuth Provider](../../../integration/saml.md).
[View the differences between SaaS and Self-Managed Authentication and Authorization Options](../../../administration/auth/index.md#saas-vs-self-managed-comparison).

SAML on GitLab.com allows users to sign in through their SAML identity provider. If the user is not already a member, the sign-in process automatically adds the user to the appropriate group.

User synchronization of SAML SSO groups is supported through [SCIM](scim_setup.md). SCIM supports adding and removing users from the GitLab group automatically.
For example, if you remove a user from the SCIM app, SCIM removes that same user from the GitLab group.

SAML SSO is only configurable at the top-level group.

If required, you can find [a glossary of common terms](../../../integration/saml.md#glossary-of-common-terms).

## Configure your identity provider

1. Find the information in GitLab required for configuration:
   1. On the top bar, select **Menu > Groups** and find your group.
   1. On the left sidebar, select **Settings > SAML SSO**.
   1. Note the **Assertion consumer service URL**, **Identifier**, and **GitLab single sign-on URL**.
1. Configure your SAML identity provider app using the noted details.
   Alternatively, GitLab provides a [metadata XML configuration](#metadata-configuration).
   See [specific identity provider documentation](#providers) for more details.
1. Configure the SAML response to include a [NameID](#nameid) that uniquely identifies each user.
1. Configure the required [user attributes](#user-attributes), ensuring you include the user's email address.
1. While the default is enabled for most SAML providers, please ensure the app is set to have service provider
   initiated calls in order to link existing GitLab accounts.
1. Once the identity provider is set up, move on to [configuring GitLab](#configure-gitlab).

![Issuer and callback for configuring SAML identity provider with GitLab.com](img/group_saml_configuration_information.png)

If your account is the only owner in the group after SAML is set up, you can't unlink the account. To [unlink the account](#unlinking-accounts),
set up another user as a group owner.

### NameID

GitLab.com uses the SAML NameID to identify users. The NameID element:

- Is a required field in the SAML response.
- Must be unique to each user.
- Must be a persistent value that never changes, such as a randomly generated unique user ID.
- Is case sensitive. The NameID must match exactly on subsequent login attempts, so should not rely on user input that could change between upper and lower case.
- Should not be an email address or username. We strongly recommend against these as it's hard to
  guarantee it doesn't ever change, for example, when a person's name changes. Email addresses are
  also case-insensitive, which can result in users being unable to sign in.

The relevant field name and recommended value for supported providers are in the [provider specific notes](#providers).
appropriate corresponding field.

WARNING:
Once users have signed into GitLab using the SSO SAML setup, changing the `NameID` breaks the configuration and potentially locks users out of the GitLab group.

#### NameID Format

We recommend setting the NameID format to `Persistent` unless using a field (such as email) that requires a different format.
Most NameID formats can be used, except `Transient` due to the temporary nature of this format.

### User attributes

To create users with the correct information for improved [user access and management](#user-access-and-management),
the user's details must be passed to GitLab as attributes in the SAML assertion. At a minimum, the user's email address
must be specified as an attribute named `email` or `mail`.

You can configure the following attributes with GitLab.com Group SAML:

- `username` or `nickname`. We recommend you configure only one of these.
- The [attributes available](../../../integration/saml.md#assertions) to self-managed GitLab instances.

### Metadata configuration

GitLab provides metadata XML that can be used to configure your identity provider.

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > SAML SSO**.
1. Copy the provided **GitLab metadata URL**.
1. Follow your identity provider's documentation and paste the metadata URL when it's requested.

## Configure GitLab

After you set up your identity provider to work with GitLab, you must configure GitLab to use it for authentication:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > SAML SSO**.
1. Find the SSO URL from your identity provider and enter it the **Identity provider single sign-on URL** field.
1. Find and enter the fingerprint for the SAML token signing certificate in the **Certificate** field.
1. Select the access level to be applied to newly added users in the **Default membership role** field. The default access level is 'Guest'.
1. Select the **Enable SAML authentication for this group** checkbox.
1. Select the **Save changes** button.

![Group SAML Settings for GitLab.com](img/group_saml_settings_v13_12.png)

NOTE:
The certificate [fingerprint algorithm](../../../integration/saml.md#notes-on-configuring-your-identity-provider) must be in SHA1. When configuring the identity provider (such as [Google Workspace](#google-workspace-setup-notes)), use a secure signature algorithm.

### SSO enforcement

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5291) in GitLab 11.8.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/9255) in GitLab 11.11 with ongoing enforcement in the GitLab UI.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/292811) in GitLab 13.8, with an updated timeout experience.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/211962) in GitLab 13.8 with allowing group owners to not go through SSO.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/9152) in GitLab 13.11 with enforcing open SSO session to use Git if this setting is switched on.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/339888) in GitLab 14.7 to not enforce SSO checks for Git activity originating from CI/CD jobs.

With this option enabled, users must access GitLab using your group GitLab single sign-on URL to access group resources.
Users can't be added as new members manually.
Users with the Owner role can use the standard sign in process to make necessary changes to top-level group settings.

SSO enforcement does not affect sign in or access to any resources outside of the group. Users can view which groups and projects they are a member of without SSO sign in.

However, users are not prompted to sign in through SSO on each visit. GitLab checks whether a user
has authenticated through SSO. If it's been more than 1 day since the last sign-in, GitLab
prompts the user to sign in again through SSO.

An [issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/297389) to add a similar SSO requirement for API activity.

SSO has the following effects when enabled:

- For groups, users can't share a project in the group outside the top-level group,
  even if the project is forked.
- For Git activity over SSH and HTTPS, users must have at least one active session signed-in through SSO before they can push to or
  pull from a GitLab repository.
- Git activity originating from CI/CD jobs do not have the SSO check enforced.
- Credentials that are not tied to regular users (for example, project and group access tokens, and deploy keys) do not have the SSO check enforced.
- Users must be signed-in through SSO before they can pull images using the [Dependency Proxy](../../packages/dependency_proxy/index.md).
- When the **Enforce SSO-only authentication for Git and Dependency Proxy activity for this group** option is enabled, any API endpoint that involves Git activity is under SSO
  enforcement. For example, creating or deleting a branch, commit, or tag.

When SSO is enforced, users are not immediately revoked. If the user:

- Is signed out, they cannot access the group after being removed from the identity provider.
- Has an active session, they can continue accessing the group for up to 24 hours until the identity
  provider session times out.

## Providers

The SAML standard means that you can use a wide range of identity providers with GitLab. Your identity provider might have relevant documentation. It can be generic SAML documentation or specifically targeted for GitLab.

When [configuring your identity provider](#configure-your-identity-provider), please consider the notes below for specific providers to help avoid common issues and as a guide for terminology used.

For providers not listed below, you can refer to the [instance SAML notes on configuring an identity provider](../../../integration/saml.md#notes-on-configuring-your-identity-provider)
for additional guidance on information your identity provider may require.

GitLab provides the following information for guidance only.
If you have any questions on configuring the SAML app, please contact your provider's support.

### Azure setup notes

Follow the Azure documentation on [configuring single sign-on to applications](https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/view-applications-portal) with the notes below for consideration.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the Azure SAML setup including SCIM, see [SCIM Provisioning on Azure Using SAML SSO for Groups Demo](https://youtu.be/24-ZxmTeEBU). The video is outdated in regard to
objectID mapping and the [SCIM documentation should be followed](scim_setup.md#azure-configuration-steps).

| GitLab Setting                       | Azure Field                                |
| ------------------------------------ | ------------------------------------------ |
| Identifier                           | Identifier (Entity ID)                     |
| Assertion consumer service URL       | Reply URL (Assertion Consumer Service URL) |
| GitLab single sign-on URL            | Sign on URL                                |
| Identity provider single sign-on URL | Login URL                                  |
| Certificate fingerprint              | Thumbprint                                 |

The recommended attributes and claims settings are:

- **Unique User Identifier (Name identifier)** set to `user.objectID`.
- **nameid-format** set to persistent.
- Additional claims set to [supported attributes](#user-attributes).

If using [Group Sync](#group-sync), customize the name of the group claim to match the required attribute.

See our [example configuration page](example_saml_config.md#azure-active-directory).

### Google Workspace setup notes

Follow the Google Workspace documentation on
[setting up SSO with Google as your identity provider](https://support.google.com/a/answer/6087519?hl=en)
with the notes below for consideration.

| GitLab setting                       | Google Workspace field |
|:-------------------------------------|:-----------------------|
| Identifier                           | Entity ID              |
| Assertion consumer service URL       | ACS URL                |
| GitLab single sign-on URL            | Start URL              |
| Identity provider single sign-on URL | SSO URL                |

NOTE:
Google Workspace displays a SHA256 fingerprint. To retrieve the SHA1 fingerprint required by GitLab for [configuring SAML](#configure-gitlab), download the certificate and calculate
the SHA1 certificate fingerprint using this sample command: `openssl x509 -noout -fingerprint -sha1 -inform pem -in "GoogleIDPCertificate-domain.com.pem"`.

The recommended attributes and claims settings are:

- **Primary email** set to `email`.
- **First name** set to `first_name`.
- **Last name** set to `last_name`.

For NameID, the following settings are recommended:

- **Name ID format** is set to `EMAIL`.
- **NameID** set to `Basic Information > Primary email`.

When selecting **Verify SAML Configuration** on the GitLab SAML SSO page, disregard the warning recommending setting the NameID format to "persistent".

See our [example configuration page](example_saml_config.md#google-workspace).

### Okta setup notes

Please follow the Okta documentation on [setting up a SAML application in Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/) with the notes below for consideration.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the Okta SAML setup including SCIM, see [Demo: Okta Group SAML & SCIM setup](https://youtu.be/0ES9HsZq0AQ).

| GitLab Setting                       | Okta Field                                                 |
| ------------------------------------ | ---------------------------------------------------------- |
| Identifier                           | Audience URI                                               |
| Assertion consumer service URL       | Single sign-on URL                                         |
| GitLab single sign-on URL            | Login page URL (under **Application Login Page** settings) |
| Identity provider single sign-on URL | Identity Provider Single Sign-On URL                       |

Under Okta's **Single sign-on URL** field, check the option **Use this for Recipient URL and Destination URL**.

For NameID, the following settings are recommended; for SCIM, the following settings are required:

- **Application username** (NameID) set to **Custom** `user.getInternalProperty("id")`.
- **Name ID Format** set to **Persistent**.

### OneLogin setup notes

OneLogin supports their own [GitLab (SaaS)](https://onelogin.service-now.com/support?id=kb_article&sys_id=92e4160adbf16cd0ca1c400e0b961923&kb_category=50984e84db738300d5505eea4b961913)
application.

If you decide to use the OneLogin generic [SAML Test Connector (Advanced)](https://onelogin.service-now.com/support?id=kb_article&sys_id=b2c19353dbde7b8024c780c74b9619fb&kb_category=93e869b0db185340d5505eea4b961934),
we recommend the ["Use the OneLogin SAML Test Connector" documentation](https://onelogin.service-now.com/support?id=kb_article&sys_id=93f95543db109700d5505eea4b96198f) with the following settings:

| GitLab Setting                                   | OneLogin Field               |
| ------------------------------------------------ | ---------------------------- |
| Identifier                                       | Audience                     |
| Assertion consumer service URL                   | Recipient                    |
| Assertion consumer service URL                   | ACS (Consumer) URL           |
| Assertion consumer service URL (escaped version) | ACS (Consumer) URL Validator |
| GitLab single sign-on URL                        | Login URL                    |
| Identity provider single sign-on URL             | SAML 2.0 Endpoint            |

Recommended `NameID` value: `OneLogin ID`.

### Change the SAML app

To change the SAML app used for sign in:

- If the NameID is not identical in both the existing and new SAML apps, users must:
  1. [Unlink the current SAML identity](#unlinking-accounts).
  1. [Link their identity](#user-access-and-management) to the new SAML app.
- If the NameID is identical, no change is required.

### Migrate to a different SAML provider

You can migrate to a different SAML provider. During the migration process users will not be able to access any of the SAML groups.
To mitigate this, you can disable [SSO enforcement](#sso-enforcement).

To migrate SAML providers:

1. [Configure](#configure-your-identity-provider) the group with the new identity provider SAML app.
1. Ask users to [unlink their account from the group](#unlinking-accounts).
1. Ask users to [link their account to the new SAML app](#linking-saml-to-your-existing-gitlabcom-account).

### Change email domains

To migrate users to a new email domain, users must:

1. Add their new email as the primary email to their accounts and verify it.
1. [Unlink their account from the group](#unlinking-accounts).
1. [Link their account to the group](#linking-saml-to-your-existing-gitlabcom-account).
1. (Optional) Remove their old email from the account.

## User access and management

> SAML user provisioning [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/268142) in GitLab 13.7.

Once Group SSO is configured and enabled, users can access the GitLab.com group through the identity provider's dashboard. If [SCIM](scim_setup.md) is configured, please see the [user access and linking setup section on the SCIM page](scim_setup.md#user-access-and-linking-setup).

When a user tries to sign in with Group SSO, GitLab attempts to find or create a user based on the following:

- Find an existing user with a matching SAML identity. This would mean the user either had their account created by [SCIM](scim_setup.md) or they have previously signed in with the group's SAML IdP.
- If there is no conflicting user with the same email address, create a new account automatically.
- If there is a conflicting user with the same email address, redirect the user to the sign-in page to:
  - Create a new account with another email address.
  - Sign-in to their existing account to link the SAML identity.

### Linking SAML to your existing GitLab.com account

To link SAML to your existing GitLab.com account:

1. Sign in to your GitLab.com account. [Reset your password](https://gitlab.com/users/password/new) if necessary.
1. Locate and visit the **GitLab single sign-on URL** for the group you're signing in to. A group owner can find this on the group's **Settings > SAML SSO** page. If the sign-in URL is configured, users can connect to the GitLab app from the identity provider.
1. Select **Authorize**.
1. Enter your credentials on the identity provider if prompted.
1. You are then redirected back to GitLab.com and should now have access to the group. In the future, you can use SAML to sign in to GitLab.com.

On subsequent visits, you should be able to go [sign in to GitLab.com with SAML](#signing-in-to-gitlabcom-with-saml) or by visiting links directly. If the **enforce SSO** option is turned on, you are then redirected to sign in through the identity provider.

### Signing in to GitLab.com with SAML

1. Sign in to your identity provider.
1. From the list of apps, select the "GitLab.com" app. (The name is set by the administrator of the identity provider.)
1. You are then signed in to GitLab.com and redirected to the group.

### Configure user settings from SAML response

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/263661) in GitLab 13.7.

GitLab allows setting certain user attributes based on values from the SAML response.
Existing users will have these attributes updated if the user was originally
provisioned by the group. Users are provisioned by the group when the account was
created via [SCIM](scim_setup.md) or by first sign-in with SAML SSO for GitLab.com groups.

#### Supported user attributes

- `can_create_group` - 'true' or 'false' to indicate whether the user can create
  new groups. Default is `true`.
- `projects_limit` - The total number of personal projects a user can create.
  A value of `0` means the user cannot create new projects in their personal
  namespace. Default is `10000`.

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

### Role

Starting from [GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/issues/214523), group owners can set a
"Default membership role" other than Guest. To do so, [configure the SAML SSO for the group](#configure-gitlab).
That role becomes the starting access level of all users added to the group.

Existing members with appropriate privileges can promote or demote users, as needed.

If a user is already a member of the group, linking the SAML identity does not change their role.

Users given a "minimal access" role have [specific restrictions](../../permissions.md#users-with-minimal-access).

### Blocking access

To rescind a user's access to the group when only SAML SSO is configured, either:

- Remove (in order) the user from:
  1. The user data store on the identity provider or the list of users on the specific app.
  1. The GitLab.com group.
- Use Group Sync at the top-level of your group to [automatically remove the user](group_sync.md#automatic-member-removal).

To rescind a user's access to the group when also using SCIM, refer to [Blocking access](scim_setup.md#blocking-access).

### Unlinking accounts

Users can unlink SAML for a group from their profile page. This can be helpful if:

- You no longer want a group to be able to sign you in to GitLab.com.
- Your SAML NameID has changed and so GitLab can no longer find your user.

WARNING:
Unlinking an account removes all roles assigned to that user in the group.
If a user re-links their account, roles need to be reassigned.

Groups require at least one owner. If your account is the only owner in the
group, you are not allowed to unlink the account. In that case, set up another user as a
group owner, and then you can unlink the account.

For example, to unlink the `MyOrg` account:

1. On the top bar, in the top right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Service sign-in** section, select **Disconnect** next to the connected account.

## Group Sync

For information on automatically managing GitLab group membership, see [SAML Group Sync](group_sync.md).

## Passwords for users created via SAML SSO for Groups

The [Generated passwords for users created through integrated authentication](../../../security/passwords_for_integrated_authentication_methods.md) guide provides an overview of how GitLab generates and sets passwords for users created via SAML SSO for Groups.

## Troubleshooting

This section contains possible solutions for problems you might encounter.

### SAML debugging tools

SAML responses are base64 encoded, so we recommend the following browser plugins to decode them on the fly:

- [SAML-tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) for Firefox.
- [SAML Message Decoder](https://chrome.google.com/webstore/detail/saml-message-decoder/mpabchoaimgbdbbjjieoaeiibojelbhm?hl=en) for Chrome.

Specific attention should be paid to:

- The [NameID](#nameid), which we use to identify which user is signing in. If the user has previously signed in, this [must match the value we have stored](#verifying-nameid).
- The presence of a `X509Certificate`, which we require to verify the response signature.
- The `SubjectConfirmation` and `Conditions`, which can cause errors if misconfigured.

#### Generate a SAML Response

SAML Responses can be used to preview the attribute names and values sent in the assertions list while attempting to sign in using an IdP.

To generate a SAML Response:

1. Install either:
   - [SAML Chrome Panel](https://chrome.google.com/webstore/detail/saml-chrome-panel/paijfdbeoenhembfhkhllainmocckace) for Chrome.
   - [SAML-tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) for Firefox.
1. Open a new browser tab.
1. Open the SAML tracer console:
   - Chrome: Right-click on the page, select **Inspect**, then select the **SAML** tab in the opened developer console.
   - Firefox: Select the SAML-tracer icon located on the browser toolbar.
1. Go to the GitLab single sign-on URL for the group in the same browser tab with the SAML tracer open.
1. Select **Authorize** or attempt to log in. A SAML response is displayed in the tracer console that resembles this
   [example SAML response](#example-saml-response).
1. Within the SAML tracer, select the **Export** icon to save the response in JSON format.

### Verifying configuration

For convenience, we've included some [example resources](../../../user/group/saml_sso/example_saml_config.md) used by our Support Team. While they may help you verify the SAML app configuration, they are not guaranteed to reflect the current state of third-party products.

### Verifying NameID

In troubleshooting the Group SAML setup, any authenticated user can use the API to verify the NameID GitLab already has linked to the user by visiting [`https://gitlab.com/api/v4/user`](https://gitlab.com/api/v4/user) and checking the `extern_uid` under identities.

Similarly, group members of a role with the appropriate permissions can make use of the [members API](../../../api/members.md) to view group SAML identity information for members of the group.

This can then be compared to the [NameID](#nameid) being sent by the identity provider by decoding the message with a [SAML debugging tool](#saml-debugging-tools). We require that these match in order to identify users.

### Users receive a 404

Because SAML SSO for groups is a paid feature, your subscription expiring can result in a `404` error when you're signing in using SAML SSO on GitLab.com.
If all users are receiving a `404` when attempting to log in using SAML, confirm
[there is an active subscription](../../../subscriptions/gitlab_com/index.md#view-your-gitlab-saas-subscription) being used in this SAML SSO namespace.

If you receive a `404` during setup when using "verify configuration", make sure you have used the correct
[SHA-1 generated fingerprint](../../../integration/saml.md#notes-on-configuring-your-identity-provider).

If a user is trying to sign in for the first time and the GitLab single sign-on URL has not [been configured](#configure-your-identity-provider), they may see a 404.
As outlined in the [user access section](#linking-saml-to-your-existing-gitlabcom-account), a group Owner needs to provide the URL to users.

### Message: "SAML authentication failed: Extern UID has already been taken"

This error suggests you are signed in as a GitLab user but have already linked your SAML identity to a different GitLab user. Sign out and then try to sign in again using the SSO SAML link, which should log you into GitLab with the linked user account.

If you do not wish to use that GitLab user with the SAML login, you can [unlink the GitLab account from the group's SAML](#unlinking-accounts).

### Message: "SAML authentication failed: User has already been taken"

The user that you're signed in with already has SAML linked to a different identity, or the NameID value has changed.
Here are possible causes and solutions:

| Cause                                                                                          | Solution                                                                                                                                                                   |
| ---------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| You've tried to link multiple SAML identities to the same user, for a given identity provider. | Change the identity that you sign in with. To do so, [unlink the previous SAML identity](#unlinking-accounts) from this GitLab account before attempting to sign in again. |
| The NameID changes every time the user requests SSO identification | Check the NameID is not set with `Transient` format, or the NameID is not changing on subsequent requests.|

### Message: "SAML authentication failed: Email has already been taken"

| Cause                                                                                                                                    | Solution                                                                 |
| ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| When a user account with the email address already exists in GitLab, but the user does not have the SAML identity tied to their account. | The user needs to [link their account](#user-access-and-management). |

User accounts are created in one of the following ways:

- User registration
- Sign in through OAuth
- Sign in through SAML
- SCIM provisioning

### Message: "SAML authentication failed: Extern UID has already been taken, User has already been taken"

Getting both of these errors at the same time suggests the NameID capitalization provided by the identity provider didn't exactly match the previous value for that user.

This can be prevented by configuring the [NameID](#nameid) to return a consistent value. Fixing this for an individual user involves [unlinking SAML in the GitLab account](#unlinking-accounts), although this causes group membership and to-do items to be lost.

### Message: "Request to link SAML account must be authorized"

Ensure that the user who is trying to link their GitLab account has been added as a user within the identity provider's SAML app.

Alternatively, the SAML response may be missing the `InResponseTo` attribute in the
`samlp:Response` tag, which is [expected by the SAML gem](https://github.com/onelogin/ruby-saml/blob/9f710c5028b069bfab4b9e2b66891e0549765af5/lib/onelogin/ruby-saml/response.rb#L307-L316).
The identity provider administrator should ensure that the login is
initiated by the service provider and not the identity provider.

### Message: "Sign in to GitLab to connect your organization's account"

A user can see this message when they are trying to [manually link SAML to their existing GitLab.com account](#linking-saml-to-your-existing-gitlabcom-account).

To resolve this problem, the user should check they are using the correct GitLab password to log in. They first need to
[reset their password](https://gitlab.com/users/password/new) if both:

- The account was provisioned by SCIM.
- This is the first time the user has logged in the username and password.

### Stuck in a login "loop"

Ensure that the **GitLab single sign-on URL** has been configured as "Login URL" (or similarly named field) in the identity provider's SAML app.

Alternatively, when users need to [link SAML to their existing GitLab.com account](#linking-saml-to-your-existing-gitlabcom-account), provide the **GitLab single sign-on URL** and instruct users not to use the SAML app on first sign in.

### The NameID has changed

| Cause                                                                                                                                                                                    | Solution                                                                                                                                                               |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| As mentioned in the [NameID](#nameid) section, if the NameID changes for any user, the user can be locked out. This is a common problem when an email address is used as the identifier. | Follow the steps outlined in the ["SAML authentication failed: User has already been taken"](#message-saml-authentication-failed-user-has-already-been-taken) section. |

### I need additional information to configure my identity provider

Many SAML terms can vary between providers. It is possible that the information you are looking for is listed under another name.

For more information, start with your identity provider's documentation. Look for their options and examples to see how they configure SAML. This can provide hints on what you need to configure GitLab to work with these providers.

It can also help to look at our [more detailed docs for self-managed GitLab](../../../integration/saml.md).
SAML configuration for GitLab.com is mostly the same as for self-managed instances.
However, self-managed GitLab instances use a configuration file that supports more options as described in the external [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml/).
Internally that uses the [`ruby-saml` library](https://github.com/onelogin/ruby-saml), so we sometimes check there to verify low level details of less commonly used options.

It can also help to compare the XML response from your provider with our [example XML used for internal testing](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/spec/fixtures/saml/response.xml).

### Searching Rails log

With access to the rails log or `production_json.log` (available only to GitLab team members for GitLab.com),
you should be able to find the base64 encoded SAML response by searching with the following filters:

- `json.meta.caller_id`: `Groups::OmniauthCallbacksController#group_saml`
- `json.meta.user` or `json.username`: `username`
- `json.method`: `POST`
- `json.path`: `/groups/GROUP-PATH/-/saml/callback`

In a relevant log entry, the `json.params` should provide a valid response with:

- `"key": "SAMLResponse"` and the `"value": (full SAML response)`,
- `"key": "RelayState"` with `"value": "/group-path"`, and
- `"key": "group_id"` with `"value": "group-path"`.

In some cases, if the SAML response is lengthy, you may receive a `"key": "truncated"` with `"value":"..."`.
In these cases, please ask a group owner for a copy of the SAML response from when they select
the "Verify SAML Configuration" button on the group SSO Settings page.

Use a base64 decoder to see a human-readable version of the SAML response.
