---
type: reference, howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# SAML SSO for GitLab.com groups **(PREMIUM)**

> Introduced in GitLab 11.0.

This page describes SAML for Groups. For instance-wide SAML on self-managed GitLab instances, see [SAML OmniAuth Provider](../../../integration/saml.md).

SAML on GitLab.com allows users to sign in through their SAML identity provider. If the user is not already a member, the sign-in process automatically adds the user to the appropriate group.

If you follow our guidance to automate user provisioning using [SCIM](scim_setup.md) or [group-managed accounts](group_managed_accounts.md), you do not need to create such accounts manually.

User synchronization of SAML SSO groups is supported through [SCIM](scim_setup.md). SCIM supports adding and removing users from the GitLab group.
For example, if you remove a user from the SCIM app, SCIM removes that same user from the GitLab group.

## Configuring your Identity Provider

1. Navigate to the group and click **Settings > SAML SSO**.
1. Configure your SAML server using the **Assertion consumer service URL**, **Identifier**, and **GitLab single sign-on URL**. Alternatively GitLab provides [metadata XML configuration](#metadata-configuration). See [specific identity provider documentation](#providers) for more details.
1. Configure the SAML response to include a NameID that uniquely identifies each user.
1. Configure [required assertions](group_managed_accounts.md#assertions) if using [Group Managed Accounts](group_managed_accounts.md).
1. Once the identity provider is set up, move on to [configuring GitLab](#configuring-gitlab).

![Issuer and callback for configuring SAML identity provider with GitLab.com](img/group_saml_configuration_information.png)

### NameID

GitLab.com uses the SAML NameID to identify users. The NameID element:

- Is a required field in the SAML response.
- Must be unique to each user.
- Must be a persistent value that will never change, such as a randomly generated unique user ID.
- Is case sensitive. The NameID must match exactly on subsequent login attempts, so should not rely on user input that could change between upper and lower case.
- Should not be an email address or username. We strongly recommend against these as it is hard to guarantee they will never change, for example when a person's name changes. Email addresses are also case-insensitive, which can result in users being unable to sign in.

The relevant field name and recommended value for supported providers are in the [provider specific notes](#providers).
appropriate corresponding field.

CAUTION: **Warning:**
Once users have signed into GitLab using the SSO SAML setup, changing the `NameID` will break the configuration and potentially lock users out of the GitLab group.

#### NameID Format

We recommend setting the NameID format to `Persistent` unless using a field (such as email) that requires a different format.

### Metadata configuration

GitLab provides metadata XML that can be used to configure your Identity Provider.

1. Navigate to the group and click **Settings > SAML SSO**.
1. Copy the provided **GitLab metadata URL**.
1. Follow your Identity Provider's documentation and paste the metadata URL when it is requested.

## Configuring GitLab

Once you've set up your identity provider to work with GitLab, you'll need to configure GitLab to use it for authentication:

1. Navigate to the group's **Settings > SAML SSO**.
1. Find the SSO URL from your Identity Provider and enter it the **Identity provider single sign-on URL** field.
1. Find and enter the fingerprint for the SAML token signing certificate in the **Certificate** field.
1. Click the **Enable SAML authentication for this group** toggle switch.
1. Click the **Save changes** button.

![Group SAML Settings for GitLab.com](img/group_saml_settings.png)

NOTE: **Note:**
Please note that the certificate [fingerprint algorithm](#additional-providers-and-setup-options) must be in SHA1. When configuring the identity provider, use a secure signature algorithm.

### SSO enforcement

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5291) in GitLab 11.8.
- [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/9255) in GitLab 11.11 with ongoing enforcement in the GitLab UI.

With this option enabled, users must go through your group's GitLab single sign-on URL. They may also be added via SCIM, if configured. Users cannot be added manually, and may only access project/group resources via the UI by signing in through the SSO URL.

However, users will not be prompted to sign in through SSO on each visit. GitLab will check whether a user has authenticated through SSO, and will only prompt the user to sign in via SSO if the session has expired.

We intend to add a similar SSO requirement for [Git and API activity](https://gitlab.com/gitlab-org/gitlab/-/issues/9152).

When SSO enforcement is enabled for a group, users cannot share a project in the group outside the top-level group, even if the project is forked.

To disallow users to contribute outside of the top-level group, please see [Group Managed Accounts](group_managed_accounts.md).

## Providers

NOTE: **Note:**
GitLab is unable to provide support for IdPs that are not listed here.

| Provider | Documentation |
|----------|---------------|
| ADFS (Active Directory Federation Services) | [Create a Relying Party Trust](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/create-a-relying-party-trust) |
| Azure | [Configuring single sign-on to applications](https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/configure-single-sign-on-non-gallery-applications) |
| Okta | [Setting up a SAML application in Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/overview/) |
| OneLogin | [Use the OneLogin SAML Test Connector](https://onelogin.service-now.com/support?id=kb_article&sys_id=93f95543db109700d5505eea4b96198f) |

When [configuring your identify provider](#configuring-your-identity-provider), please consider the notes below for specific providers to help avoid common issues and as a guide for terminology used.

### Azure setup notes

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the Azure SAML setup including SCIM, see [SCIM Provisioning on Azure Using SAML SSO for Groups Demo](https://youtu.be/24-ZxmTeEBU).

| GitLab Setting | Azure Field |
|--------------|----------------|
| Identifier   | Identifier (Entity ID) |
| Assertion consumer service URL | Reply URL (Assertion Consumer Service URL) |
| GitLab single sign-on URL | Sign on URL |
| Identity provider single sign-on URL | Login URL |
| Certificate fingerprint | Thumbprint |

We recommend:

- **Unique User Identifier (Name identifier)** set to `user.objectID`.
- **nameid-format** set to persistent.

### Okta setup notes

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of the Okta SAML setup including SCIM, see [Demo: Okta Group SAML & SCIM setup](https://youtu.be/0ES9HsZq0AQ).

| GitLab Setting | Okta Field |
|--------------|----------------|
| Identifier | Audience URI |
| Assertion consumer service URL | Single sign-on URL |
| GitLab single sign-on URL | Login page URL (under **Application Login Page** settings) |
| Identity provider single sign-on URL | Identity Provider Single Sign-On URL |

Under Okta's **Single sign-on URL** field, check the option **Use this for Recipient URL and Destination URL**.

We recommend:

- **Application username** (NameID) set to **Custom** `user.getInternalProperty("id")`.
- **Name ID Format** set to **Persistent**.

### OneLogin setup notes

The GitLab app listed in the OneLogin app catalog is for self-managed GitLab instances.
For GitLab.com, use a generic SAML Test Connector such as the SAML Test Connector (Advanced).

| GitLab Setting | OneLogin Field |
|--------------|----------------|
| Identifier | Audience |
| Assertion consumer service URL | Recipient |
| Assertion consumer service URL | ACS (Consumer) URL |
| Assertion consumer service URL (escaped version) | ACS (Consumer) URL Validator |
| GitLab single sign-on URL | Login URL |
| Identity provider single sign-on URL | SAML 2.0 Endpoint |

Recommended `NameID` value: `OneLogin ID`.

### Additional providers and setup options

The SAML standard means that a wide range of identity providers will work with GitLab. Unfortunately we have not verified connections with all SAML providers.
For more information, see our [discussion on providers](#providers).

Your identity provider may have relevant documentation. It may be generic SAML documentation, or specifically targeted for GitLab. Examples:

- [Auth0](https://auth0.com/docs/protocols/saml/saml-idp-generic)
- [G Suite](https://support.google.com/a/answer/6087519?hl=en)
- [JumpCloud](https://support.jumpcloud.com/support/s/article/single-sign-on-sso-with-gitlab-2019-08-21-10-36-47)
- [PingOne by Ping Identity](https://docs.pingidentity.com/bundle/pingone/page/xsh1564020480660-1.html)

Your Identity Provider may require additional configuration, such as the following:

| Field | Value | Notes |
|-------|-------|-------|
| SAML Profile | Web browser SSO profile | GitLab uses SAML to sign users in via their browser. We don't make requests direct to the Identity Provider. |
| SAML Request Binding | HTTP Redirect | GitLab (the service provider) redirects users to your Identity Provider with a base64 encoded `SAMLRequest` HTTP parameter. |
| SAML Response Binding | HTTP POST | Your Identity Provider responds to users with an HTTP form including the `SAMLResponse`, which a user's browser submits back to GitLab. |
| Sign SAML Response | Yes | We require this to prevent tampering. |
| X.509 Certificate in response | Yes | This is used to sign the response and checked against the provided fingerprint. |
| Fingerprint Algorithm | SHA-1  | We need a SHA-1 hash of the certificate used to sign the SAML Response. |
| Signature Algorithm | SHA-1/SHA-256/SHA-384/SHA-512 | Also known as the Digest Method, this can be specified in the SAML response. It determines how a response is signed. |
| Encrypt SAML Assertion | No | TLS is used between your Identity Provider, the user's browser, and GitLab. |
| Sign SAML Assertion | Optional | We don't require Assertions to be signed. We validate their integrity by requiring the whole response to be signed. |
| Check SAML Request Signature | No | GitLab does not sign SAML requests, but does check the signature on the SAML response. |
| Default RelayState | Optional | The URL users should end up on after signing in via a button on your Identity Provider. |
| NameID Format | `Persistent` | See [details above](#nameid-format). |
| Additional URLs | | You may need to use the `Identifier` or `Assertion consumer service URL` in other fields on some providers. |
| Single Sign Out URL | | Not supported |

If the information you need isn't listed above you may wish to check our [troubleshooting docs below](#i-need-additional-information-to-configure-my-identity-provider).

## User access and management

Once Group SSO is configured and enabled, users can access the GitLab.com group through the identity provider's dashboard. If [SCIM](scim_setup.md) is configured, please see the [user access and linking setup section on the SCIM page](scim_setup.md#user-access-and-linking-setup).

When a user tries to sign in with Group SSO, they will need an account that's configured with one of the following:

- [SCIM](scim_setup.md).
- [Group-managed accounts](group_managed_accounts.md).
- A GitLab.com account.

### Linking SAML to your existing GitLab.com account

To link SAML to your existing GitLab.com account:

1. Sign in to your GitLab.com account.
1. Locate and visit the **GitLab single sign-on URL** for the group you are signing in to. A group Admin can find this on the group's **Settings > SAML SSO** page. If the sign-in URL is configured, users can connect to the GitLab app from the Identity Provider.
1. Click **Authorize**.
1. Enter your credentials on the Identity Provider if prompted.
1. You will be redirected back to GitLab.com and should now have access to the group. In the future, you can use SAML to sign in to GitLab.com.

On subsequent visits, you should be able to go [sign in to GitLab.com with SAML](#signing-in-to-gitlabcom-with-saml) or by visiting links directly. If the **enforce SSO** option is turned on, you will be redirected to sign in through the identity provider.

### Signing in to GitLab.com with SAML

1. Sign in to your identity provider.
1. From the list of apps, click on the "GitLab.com" app (The name is set by the administrator of the identity provider).
1. You will be signed in to GitLab.com and redirected to the group.

### Role

The first time you sign in, GitLab adds you to the top-level parent group with the Guest role. Existing members with appropriate privileges can promote that new user.

If a user is already a member of the group, linking the SAML identity does not change their role.

### Blocking access

To rescind access to the group, perform the following steps, in order:

1. Remove the user from the user datastore on the identity provider or the list of users on the specific app.
1. Remove the user from the GitLab.com group.

### Unlinking accounts

Users can unlink SAML for a group from their profile page. This can be helpful if:

- You no longer want a group to be able to sign you in to GitLab.com.
- Your SAML NameID has changed and so GitLab can no longer find your user.

For example, to unlink the `MyOrg` account, the following **Disconnect** button will be available under **Profile > Accounts**:

![Unlink Group SAML](img/unlink_group_saml.png)

## Glossary

| Term | Description |
|------|-------------|
| Identity Provider | The service which manages your user identities such as ADFS, Okta, Onelogin, or Ping Identity. |
| Service Provider | SAML considers GitLab to be a service provider. |
| Assertion | A piece of information about a user's identity, such as their name or role. Also know as claims or attributes. |
| SSO | Single Sign On. |
| Assertion consumer service URL | The callback on GitLab where users will be redirected after successfully authenticating with the identity provider. |
| Issuer | How GitLab identifies itself to the identity provider. Also known as a "Relying party trust identifier". |
| Certificate fingerprint | Used to confirm that communications over SAML are secure by checking that the server is signing communications with the correct certificate. Also known as a certificate thumbprint. |

## Configuring on a self-managed GitLab instance **(PREMIUM ONLY)**

For self-managed GitLab instances we strongly recommend using the
[instance-wide SAML OmniAuth Provider](../../../integration/saml.md) instead.

Group SAML SSO helps if you need to allow access via multiple SAML identity providers, but as a multi-tenant solution is less suited to cases where you administer your own GitLab instance.

To proceed with configuring Group SAML SSO instead, you'll need to enable the `group_saml` OmniAuth provider. This can be done from:

- `gitlab.rb` for GitLab [Omnibus installations](#omnibus-installations).
- `gitlab/config/gitlab.yml` for [source installations](#source-installations).

### Limitations

Group SAML on a self-managed instance is limited when compared to the recommended
[instance-wide SAML](../../../integration/saml.md). The recommended solution allows you to take advantage of:

- [LDAP compatibility](../../../administration/auth/ldap/index.md).
- [LDAP Group Sync](../index.md#manage-group-memberships-via-ldap).
- [Required groups](../../../integration/saml.md#required-groups-starter-only).
- [Admin groups](../../../integration/saml.md#admin-groups-starter-only).
- [Auditor groups](../../../integration/saml.md#auditor-groups-starter-only).

### Omnibus installations

1. Make sure GitLab is
   [configured with HTTPS](../../../install/installation.md#using-https).
1. Enable OmniAuth and the `group_saml` provider in `gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_enabled'] = true
   gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

### Source installations

1. Make sure GitLab is
   [configured with HTTPS](../../../install/installation.md#using-https).
1. Enable OmniAuth and the `group_saml` provider in `gitlab/config/gitlab.yml`:

    ```yaml
    omniauth:
        enabled: true
        providers:
          - { name: 'group_saml' }
    ```

## Troubleshooting

This section contains possible solutions for problems you might encounter.

### SAML debugging tools

SAML responses are base64 encoded, so we recommend the following browser plugins to decode them on the fly:

- [SAML tracer for Firefox](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/)
- [Chrome SAML Panel](https://chrome.google.com/webstore/detail/saml-chrome-panel/paijfdbeoenhembfhkhllainmocckace?hl=en)

Specific attention should be paid to:

- The [NameID](#nameid), which we use to identify which user is signing in. If the user has previously signed in, this [must match the value we have stored](#verifying-nameid).
- The presence of a `X509Certificate`, which we require to verify the response signature.
- The `SubjectConfirmation` and `Conditions`, which can cause errors if misconfigured.

### Verifying configuration

For convenience, we've included some [example resources](../../../administration/troubleshooting/group_saml_scim.md) used by our Support Team. While they may help you verify the SAML app configuration, they are not guaranteed to reflect the current state of third-party products.

### Verifying NameID

In troubleshooting the Group SAML setup, any authenticated user can use the API to verify the NameID GitLab already has linked to the user by visiting [https://gitlab.com/api/v4/user](https://gitlab.com/api/v4/user) and checking the `extern_uid` under identities.

Similarly, group members of a role with the appropriate permissions can make use of the [members API](../../../api/members.md) to view group SAML identity information for members of the group.

This can then be compared to the [NameID](#nameid) being sent by the Identity Provider by decoding the message with a [SAML debugging tool](#saml-debugging-tools). We require that these match in order to identify users.

### Message: "SAML authentication failed: Extern uid has already been taken"

This error suggests you are signed in as a GitLab user but have already linked your SAML identity to a different GitLab user. Sign out and then try to sign in again using the SSO SAML link, which should log you into GitLab with the linked user account.

If you do not wish to use that GitLab user with the SAML login, you can [unlink the GitLab account from the group's SAML](#unlinking-accounts).

### Message: "SAML authentication failed: User has already been taken"

The user that you're signed in with already has SAML linked to a different identity.
Here are possible causes and solutions:

| Cause                                                                                          | Solution                                                                                                                                                                    |
|------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| You've tried to link multiple SAML identities to the same user, for a given Identity Provider. | Change the identity that you sign in with. To do so, [unlink the previous SAML identity](#unlinking-accounts) from this GitLab account before attempting to sign in again. |

### Message: "SAML authentication failed: Email has already been taken"

| Cause                                                                                                                                    | Solution                                                                 |
|------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| When a user account with the email address already exists in GitLab, but the user does not have the SAML identity tied to their account. | The user will need to [link their account](#user-access-and-management). |

### Message: "SAML authentication failed: Extern uid has already been taken, User has already been taken"

Getting both of these errors at the same time suggests the NameID capitalization provided by the Identity Provider didn't exactly match the previous value for that user.

This can be prevented by configuring the [NameID](#nameid) to return a consistent value. Fixing this for an individual user involves [unlinking SAML in the GitLab account](#unlinking-accounts), although this will cause group membership and Todos to be lost.

### Message: "Request to link SAML account must be authorized"

Ensure that the user who is trying to link their GitLab account has been added as a user within the identity provider's SAML app.

### Stuck in a login "loop"

Ensure that the **GitLab single sign-on URL** has been configured as "Login URL" (or similarly named field) in the identity provider's SAML app.

Alternatively, when users need to [link SAML to their existing GitLab.com account](#linking-saml-to-your-existing-gitlabcom-account), provide the **GitLab single sign-on URL** and instruct users not to use the SAML app on first sign in.

### The NameID has changed

| Cause                                                                                                                                                                                     | Solution                                                                                                                                                                                                                                           |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| As mentioned in the [NameID](#nameid) section, if the NameID changes for any user, the user can be locked out. This is a common problem when an email address is used as the identifier. | Follow the steps outlined in the ["SAML authentication failed: User has already been taken"](#message-saml-authentication-failed-user-has-already-been-taken) section. If many users are affected, we recommend that you use the appropriate API. |

### I need to change my SAML app

Users will need to [unlink the current SAML identity](#unlinking-accounts) and [link their identity](#user-access-and-management) to the new SAML app.

### I need additional information to configure my identity provider

Many SAML terms can vary between providers. It is possible that the information you are looking for is listed under another name.

For more information, start with your Identity Provider's documentation. Look for their options and examples to see how they configure SAML. This can provide hints on what you'll need to configure GitLab to work with these providers.

It can also help to look at our [more detailed docs for self-managed GitLab](../../../integration/saml.md).
SAML configuration for GitLab.com is mostly the same as for self-managed instances.
However, self-managed GitLab instances use a configuration file that supports more options as described in the external [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml/).
Internally that uses the [`ruby-saml` library](https://github.com/onelogin/ruby-saml), so we sometimes check there to verify low level details of less commonly used options.

It can also help to compare the XML response from your provider with our [example XML used for internal testing](https://gitlab.com/gitlab-org/gitlab/blob/master/ee/spec/fixtures/saml/response.xml).
