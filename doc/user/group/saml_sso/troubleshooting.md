---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting SAML
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This page contains possible solutions for problems you might encounter when using:

- [SAML SSO for GitLab.com groups](_index.md).
- The self-managed instance-level [SAML OmniAuth Provider](../../../integration/saml.md).
- [Switchboard](../../../administration/dedicated/configure_instance/saml.md#activate-saml-with-switchboard) to configure SAML for GitLab Dedicated instances.

## SAML debugging tools

SAML responses are base64 encoded, so we recommend the following browser plugins to decode them on the fly:

- [SAML-tracer](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/) for Firefox.
- [SAML Message Decoder](https://chromewebstore.google.com/detail/mpabchoaimgbdbbjjieoaeiibojelbhm?hl=en) for Chrome.

If you cannot install a browser plugin, you can [manually generate and capture a SAML response](#manually-generate-a-saml-response) instead.

Pay specific attention to:

- The `NameID`, which we use to identify which user is signing in. If the user has previously signed in, this
  [must match the value we have stored](#verify-nameid).
- The presence of a `X509Certificate`, which we require to verify the response signature.
- The `SubjectConfirmation` and `Conditions`, which can cause errors if misconfigured.

### Generate a SAML response

Use SAML responses to preview the attribute names and values sent in the assertions list while attempting to sign in
using an identity provider.

To generate a SAML Response:

1. Install one of the [browser debugging tools](#saml-debugging-tools).
1. Open a new browser tab.
1. Open the SAML tracer console:
   - Chrome: On a context menu on the page, select **Inspect**, then select the **SAML** tab in the developer console.
   - Firefox: Select the SAML-tracer icon located on the browser toolbar.
1. For GitLab.com Groups:
   - Go to the GitLab single sign-on URL for the group.
   - Select **Authorize** or attempt to sign
1. For Self Managed Instance:
   - Go to the instance home page
   - Click on the `SAML Login` button to sign in
1. A SAML response is displayed in the tracer console that resembles this
   [example SAML response](_index.md#example-saml-response).
1. Within the SAML tracer, select the **Export** icon to save the response in JSON format.

#### Manually generate a SAML response

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see this [video on manually generating a SAML response without using a browser plugin (using Google Chrome)](https://youtu.be/umMPj6ohF_I), uploaded by GitLab Support.
<!-- Video published on 2024-09-09 -->

Regardless of what browser you use, the process is similar to the following:

1. Right-click on a new browser and click on **Inspect** to open the **DevTools** window.
1. Select the **Network** tab. Make sure that **Preserve log** is selected.
1. Switch to the browser page and sign in to GitLab using SAML SSO.
1. Switch back to the **DevTools** window and filter for the `callback` event.
1. Select the **Payload** tab for the callback event and right-click to copy the value.
1. Paste this value into the following command: `echo "<value>" | base64 --decode > saml_response.xml`.
1. Open `saml_response.xml` in a code editor.

   If you have an XML "prettifier" installed in your code editor, you should be able to automatically
   format the response to be easier to read.

## Search Rails logs for a SAML sign-in

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can find detailed information about a SAML sign-in in the [`audit_json.log` file](../../../administration/logs/_index.md#audit_jsonlog).

For example, by searching for `system_access`, you can find entries that show when a user signed into GitLab using SAML:

```json
{
  "severity": "INFO",
  "time": "2024-08-13T06:05:35.721Z",
  "correlation_id": "01J555EZK136DQ8S7P32G9GEND",
  "meta.caller_id": "OmniauthCallbacksController#saml",
  "meta.remote_ip": "45.87.213.198",
  "meta.feature_category": "system_access",
  "meta.user": "bbtest",
  "meta.user_id": 16,
  "meta.client_id": "user/16",
  "author_id": 16,
  "author_name": "bbtest@agounder.onmicrosoft.com",
  "entity_id": 16,
  "entity_type": "User",
  "created_at": "2024-08-13T06:05:35.708+00:00",
  "ip_address": "45.87.213.198",
  "with": "saml",
  "target_id": 16,
  "target_type": "User",
  "target_details": "bbtest@agounder.onmicrosoft.com",
  "entity_path": "bbtest"
}
```

If you have configured SAML Group Links, the log also shows entries detailing membership being removed:

```json
{
  "severity": "INFO",
  "time": "2024-08-13T05:24:07.769Z",
  "correlation_id": "01J55330SRTKTD5CHMS96DNZEN",
  "meta.caller_id": "Auth::SamlGroupSyncWorker",
  "meta.remote_ip": "45.87.213.206",
  "meta.feature_category": "system_access",
  "meta.client_id": "ip/45.87.213.206",
  "meta.root_caller_id": "OmniauthCallbacksController#saml",
  "id": 179,
  "author_id": 6,
  "entity_id": 2,
  "entity_type": "Group",
  "details": {
    "remove": "user_access",
    "member_id": 7,
    "author_name": "BB Test",
    "author_class": "User",
    "target_id": 6,
    "target_type": "User",
    "target_details": "BB Test",
    "custom_message": "Membership destroyed",
    "ip_address": "45.87.213.198",
    "entity_path": "group1"
  },
```

You can also see details of the user that GitLab received from the SAML provider in `auth_json.log`, for example:

```json
{
  "severity": "INFO",
  "time": "2024-08-20T07:01:20.979Z",
  "correlation_id": "01J5Q9E59X4P40ZT3MCE35C2A9",
  "meta.caller_id": "OmniauthCallbacksController#saml",
  "meta.remote_ip": "xxx.xxx.xxx.xxx",
  "meta.feature_category": "system_access",
  "meta.client_id": "ip/xxx.xxx.xxx.xxx",
  "payload_type": "saml_response",
  "saml_response": {
    "issuer": [
      "https://sts.windows.net/03b8c6c5-104b-43e2-aed3-abb07df387cc/"
    ],
    "name_id": "ab260d59-0317-47f5-9afb-885c7a1257ab",
    "name_id_format": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
    "name_id_spnamequalifier": null,
    "name_id_namequalifier": null,
    "destination": "https://dh-gitlab.agounder.com/users/auth/saml/callback",
    "audiences": [
      "https://dh-gitlab.agounder.com/16.11.6"
    ],
    "attributes": {
      "http://schemas.microsoft.com/identity/claims/tenantid": [
        "03b8c6c5-104b-43e2-aed3-abb07df387cc"
      ],
      "http://schemas.microsoft.com/identity/claims/objectidentifier": [
        "ab260d59-0317-47f5-9afb-885c7a1257ab"
      ],
      "http://schemas.microsoft.com/identity/claims/identityprovider": [
        "https://sts.windows.net/03b8c6c5-104b-43e2-aed3-abb07df387cc/"
      ],
      "http://schemas.microsoft.com/claims/authnmethodsreferences": [
        "http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/password"
      ],
      "email": [
        "bbtest@agounder.com"
      ],
      "firstname": [
        "BB"
      ],
      "name": [
        "bbtest@agounder.onmicrosoft.com"
      ],
      "lastname": [
        "Test"
      ]
    },
    "in_response_to": "_f8863f68-b5f1-43f0-9534-e73933e6ed39",
    "allowed_clock_drift": 2.220446049250313e-16,
    "success": true,
    "status_code": "urn:oasis:names:tc:SAML:2.0:status:Success",
    "status_message": null,
    "session_index": "_b4f253e2-aa61-46a4-902b-43592fe30800",
    "assertion_encrypted": false,
    "response_id": "_392cc747-7c8b-41de-8be0-23f5590d5ded",
    "assertion_id": "_b4f253e2-aa61-46a4-902b-43592fe30800"
  }
}
```

## Testing GitLab SAML

You can use one of the following to troubleshoot SAML:

- A [complete GitLab with SAML testing environment using Docker compose](https://gitlab.com/gitlab-com/support/toolbox/replication/tree/master/compose_files).
- A [quick start guide to start a Docker container](../../../administration/troubleshooting/test_environments.md#saml)
  with a plug and play SAML 2.0 identity provider if you only require a SAML provider.
- A local environment by
  [enabling SAML for groups on a GitLab Self-Managed instance](../../../integration/saml.md#configure-group-saml-sso-on-gitlab-self-managed).

## Verify configuration

For convenience, we've included some [example resources](example_saml_config.md) used by our Support Team. While they may help you verify the SAML app configuration, they are not guaranteed to reflect the current state of third-party products.

### Calculate the fingerprint

If you use a `idp_cert_fingerprint`, it must be a SHA1 fingerprint. To calculate a SHA1 fingerprint, download the certificate file and run:

```shell
openssl x509 -in <filename.crt> -noout -fingerprint -sha1
```

Replace `filename.crt` with the name of the certificate file.

## SSO Certificate updates

When the certificate used for your identity provider changes (for example when updating or renewing the certificate), you must update the certificate fingerprint as well. You can find the certificate fingerprint in your identity provider's UI. If you cannot get the certificate in the identity provider UI, follow the steps in the [calculate the fingerprint](#calculate-the-fingerprint) documentation.

## Configuration errors

### Invalid audience

This error means that the identity provider doesn't recognize GitLab as a valid sender and
receiver of SAML requests. Make sure to:

- Add the GitLab callback URL to the approved audiences of the identity provider server.
- Avoid trailing whitespace in the `issuer` string.

### Key validation error, Digest mismatch or Fingerprint mismatch

These errors all come from a similar place, the SAML certificate. SAML requests
must be validated using either a fingerprint, a certificate, or a validator.

For this requirement, be sure to take the following into account:

- If you use a fingerprint, it must be the correct SHA1 fingerprint. To confirm that you are using
  the correct SHA1 fingerprint:
  1. Re-download the certificate file.
  1. [Calculate the fingerprint](#calculate-the-fingerprint).
  1. Compare the fingerprint to the value provided in `idp_cert_fingerprint`. The values should be the same.
- If no certificate is provided in the settings, a fingerprint or fingerprint
  validator needs to be provided and the response from the server must contain
  a certificate (`<ds:KeyInfo><ds:X509Data><ds:X509Certificate>`).
- If a certificate is provided in the settings, it is no longer necessary for
  the request to contain one. In this case the fingerprint or fingerprint
  validators are optional.

If none of the above described scenarios is valid, the request
fails with one of the mentioned errors.

### Missing claims, or `Email can't be blank` errors

The identity provider server needs to pass certain information in order for GitLab to either
create an account, or match the login information to an existing account. `email`
is the minimum amount of information that needs to be passed. If the identity provider server
is not providing this information, all SAML requests fail.

Make sure this information is provided.

Another issue that can result in this error is when the correct information is being sent by
the identity provider, but the attributes don't match the names in the OmniAuth `info` hash. In this case,
you must set `attribute_statements` in the SAML configuration to
[map the attribute names in your SAML Response to the corresponding OmniAuth `info` hash names](../../../integration/saml.md#map-saml-response-attribute-names).

## User sign in banner error messages

### Message: "SAML authentication failed: SAML NameID is missing from your SAML response."

You might get an error that states `SAML authentication failed: SAML NameID is missing from your SAML response. Please contact your administrator.`

This issue occurs when you try sign into GitLab using Group SSO, but your SAML response did not include a `NameID`.

To resolve this issue:

- Contact your administrator to ensure your IdP account has an assigned `NameID`.
- Use a [SAML debugging tool](#saml-debugging-tools) to verify that your SAML response has a valid `NameID`.

### Message: "SAML authentication failed: Extern uid has already been taken."

You might get an error that states `SAML authentication failed: Extern uid has already been taken. Please contact your administrator to generate a unique external_uid (NameID).`

This issue occurs when you try to link your existing GitLab account to a SAML identity using Group SSO, but there is an existing GitLab account with your current `NameID`.

To resolve this issue, tell your administrator to re-generate a unique `Extern UID` (`NameID`) for your IdP account. Make sure this new `Extern UID` adheres to the [GitLab `NameID` constraints](_index.md#manage-user-saml-identity).

If you do not wish to use that GitLab user with the SAML login, you can [unlink the GitLab account from the SAML app](_index.md#unlink-accounts).

### Message: "SAML authentication failed: User has already been taken"

The user that you're signed in with already has SAML linked to a different identity, or the `NameID` value has changed.
Here are possible causes and solutions:

| Cause                                                                                          | Solution                                                                                                                                                                   |
| ---------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| You've tried to link multiple SAML identities to the same user, for a given identity provider. | Change the identity that you sign in with. To do so, [unlink the previous SAML identity](_index.md#unlink-accounts) from this GitLab account before attempting to sign in again. |
| The `NameID` changes every time the user requests SSO identification | [Check the `NameID`](#verify-nameid) is not set with `Transient` format, or the `NameID` is not changing on subsequent requests.|

### Message: "SAML authentication failed: Email has already been taken"

| Cause                                                                                                                                    | Solution                                                                 |
| ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| When a user account with the email address already exists in GitLab, but the user does not have the SAML identity tied to their account. | The user needs to [link their account](_index.md#user-access-and-management). |

User accounts are created in one of the following ways:

- User registration
- Sign in through OAuth
- Sign in through SAML
- SCIM provisioning

### Error: user has already been taken

Getting both of these errors at the same time suggests the `NameID` capitalization provided by the identity provider didn't exactly match the previous value for that user:

- `SAML authentication failed: Extern UID has already been taken`
- `User has already been taken`

This can be prevented by configuring the `NameID` to return a consistent value. Fixing this for an individual user involves changing the identifier for the user. For GitLab.com, the user needs to [unlink their SAML from the GitLab account](_index.md#unlink-accounts).

### Message: "Request to link SAML account must be authorized"

Ensure that the user who is trying to link their GitLab account has been added as a user within the identity provider's SAML app.

Alternatively, the SAML response may be missing the `InResponseTo` attribute in the
`samlp:Response` tag, which is [expected by the SAML gem](https://github.com/onelogin/ruby-saml/blob/9f710c5028b069bfab4b9e2b66891e0549765af5/lib/onelogin/ruby-saml/response.rb#L307-L316).
The identity provider administrator should ensure that the login is
initiated by the service provider and not only the identity provider.

### Message: `There is already a GitLab account associated with this email address.`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

A user can see this message when they are trying to [manually link SAML to their existing GitLab.com account](_index.md#link-saml-to-your-existing-gitlabcom-account):

```plaintext
There is already a GitLab account associated with this email address.
Sign in with your existing credentials to connect your organization's account
```

To resolve this problem, the user should check they are using the correct GitLab password to sign in. The user first needs
to [reset their password](https://gitlab.com/users/password/new) if both:

- The account was provisioned by SCIM.
- They are signing in with username and password for the first time.

### Message: "SAML Name ID and email address do not match your user account"

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

Users might get an error that states "SAML Name ID and email address do not match your user account. Contact an administrator."
This means:

- The NameID value sent by SAML does not match the existing SAML identity `extern_uid` value. Both the NameID and the `extern_uid` are case sensitive. For more information, see  [manage user SAML identity](_index.md#manage-user-saml-identity).
- Either the SAML response did not include an email address or the email address did not match the user's GitLab email address.

The workaround is that a GitLab group Owner uses the [SAML API](../../../api/saml.md) to update the user's SAML `extern_uid`.
The `extern_uid` value must match the Name ID value sent by the SAML identity provider (IdP). Depending on the IdP configuration
this may be a generated unique ID, an email address, or other value.

### Error: Certificate element missing in response (`ds:x509certificate`)

This error suggests that the IdP is not configured to include the X.509 certificate in the SAML response:

```plaintext
Certificate element missing in response (ds:x509certificate) and not cert provided at settings
```

The X.509 certificate must be included in the response.
To resolve this problem, configure your IdP to include the X.509 certificate in the SAML response.

For more information, see the documentation on [additional configuration for SAML apps on your IdP](../../../integration/saml.md#additional-configuration-for-saml-apps-on-your-idp).

## Other user sign in issues

### Verify `NameID`

In troubleshooting, any authenticated user can use the API to verify the `NameID` GitLab already has linked to their user by visiting [`https://gitlab.com/api/v4/user`](https://gitlab.com/api/v4/user) and checking the `extern_uid` under identities.

For self-managed, administrators can use the [users API](../../../api/users.md) to see the same information.

When using SAML for groups, group members of a role with the appropriate permissions can make use of the [members API](../../../api/members.md) to view group SAML identity information for members of the group.

This can then be compared to the `NameID` being sent by the identity provider by decoding the message with a [SAML debugging tool](#saml-debugging-tools). We require that these match to identify users.

### Stuck in a login "loop"

Ensure that the **GitLab single sign-on URL** (for GitLab.com) or the instance URL (for self-managed) has been configured as "Login URL" (or similarly named field) in the identity provider's SAML app.

For GitLab.com, alternatively, when users need to [link SAML to their existing GitLab.com account](_index.md#link-saml-to-your-existing-gitlabcom-account), provide the **GitLab single sign-on URL** and instruct users not to use the SAML app on first sign in.

### Users receive a 404

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

If the user receives a `404` after signing in successfully, check if you have IP restrictions configured. IP restriction settings are configured:

- On GitLab.com, [at the group level](../access_and_permissions.md#restrict-group-access-by-ip-address).
- For GitLab Self-Managed, [at the instance level](../../../administration/reporting/ip_addr_restrictions.md).

Because SAML SSO for groups is a paid feature, your subscription expiring can result in a `404` error when you're signing in using SAML SSO on GitLab.com.
If all users are receiving a `404` when attempting to sign in using SAML, confirm
[there is an active subscription](../../../subscriptions/gitlab_com/_index.md#view-gitlabcom-subscription) being used in this SAML SSO namespace.

If you receive a `404` during setup when using "verify configuration", make sure you have used the correct
[SHA-1 generated fingerprint](../../../integration/saml.md#configure-saml-on-your-idp).

If a user is trying to sign in for the first time and the GitLab single sign-on URL has not [been configured](_index.md#set-up-your-identity-provider), they may see a 404.
As outlined in the [user access section](_index.md#link-saml-to-your-existing-gitlabcom-account), a group Owner needs to provide the URL to users.

If the top-level group has [restricted membership by email domain](../access_and_permissions.md#restrict-group-access-by-domain), and a user with an email domain that is not allowed tries to sign in with SSO, that user might receive a 404. Users might have multiple accounts, and their SAML identity might be linked to their personal account which has an email address that is different than the company domain. To check this, verify the following:

- That the top-level group has restricted membership by email domain.
- That, in [audit events](../../../administration/audit_event_reports.md) for the top-level group:
  - You can see **Signed in with GROUP_SAML authentication** action for that user.
  - That the user's username is the same as the username you configured for SAML SSO, by selecting the **Author** name.
    - If the username is different to the username you configured for SAML SSO, ask the user to [unlink the SAML identity](_index.md#unlink-accounts) from their personal account.

If all users are receiving a `404` after signing in to the identity provider (IdP):

- Verify the `assertion_consumer_service_url`:

  - In the GitLab configuration by [matching it to the HTTPS endpoint of GitLab](../../../integration/saml.md#configure-saml-support-in-gitlab).
  - As the `Assertion Consumer Service URL` or equivalent when setting up the SAML app on your IdP.

- Verify if the `404` is related to [the user having too many groups assigned to them in their Azure IdP](group_sync.md#user-that-belongs-to-many-saml-groups-automatically-removed-from-gitlab-group).

If a subset of users are receiving a `404` after signing in to the IdP, first verify audit events if the user gets added to the group and then immediately removed. Alternatively, if the user can successfully sign in, but they do not show as [a member of the top-level group](../_index.md#search-a-group):

- Ensure the user has been [added to the SAML identity provider](_index.md#user-access-and-management), and [SCIM](scim_setup.md) if configured.
- Ensure the user's SCIM identity's `active` attribute is `true` using the [SCIM API](../../../api/scim.md).
  If the `active` attribute is `false`, you can do one of the following to possibly resolve the issue:

  - Trigger a sync for the user in the SCIM identity provider. For example, Azure has a "Provision on demand" option.
  - Remove and re-add the user in the SCIM identity provider.
  - Have the user [unlink their account](_index.md#unlink-accounts) if possible, then [link their account](_index.md#link-saml-to-your-existing-gitlabcom-account).
  - Use the [internal SCIM API](../../../development/internal_api/_index.md#update-a-single-scim-provisioned-user) to update the user's SCIM identity using your group's SCIM token.
    If you do not know your group's SCIM token, reset the token and update the SCIM identity provider app with the new token.
    Example request:

    ```plaintext
    curl --request PATCH "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" --header "Authorization: Bearer <SCIM_TOKEN>" --header "Content-Type: application/scim+json" --data '{ "Operations": [{"op":"Replace","path":"active","value":"true"}] }'
    ```

### 500 error after login

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

If you see a "500 error" in GitLab when you are redirected back from the SAML
sign-in page, this could indicate that:

- GitLab couldn't get the email address for the SAML user. Ensure the identity provider provides a claim containing the user's
  email address using the claim name `email` or `mail`.
- The certificate set your `gitlab.rb` file for `identity provider_cert_fingerprint` or `identity provider_cert` file is incorrect.
- Your `gitlab.rb` file is set to enable `identity provider_cert_fingerprint`, and `identity provider_cert` is being provided, or the reverse.

### 422 error after login

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

If you see a "422 error" in GitLab when you are redirected from the SAML
sign-in page, you might have an incorrectly configured Assertion Consumer
Service (ACS) URL on the identity provider.

Make sure the ACS URL points to `https://gitlab.example.com/users/auth/saml/callback`, where
`gitlab.example.com` is the URL of your GitLab instance.

If the ACS URL is correct, and you still have errors, review the other
Troubleshooting sections.

#### 422 error with non-allowed email

You might get an 422 error that states "Email is not allowed for sign-up. Please use your regular email address."

This message might indicate that you must add or remove a domain from your domain allowlist or denylist settings.

To implement this workaround:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Sign-up restrictions**.
1. Add or remove a domain as appropriate to **Allowed domains for sign-ups** and **Denied domains for sign-ups**.
1. Select **Save changes**.

### User is blocked when signing in through SAML

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

The following are the most likely reasons that a user is blocked when signing in through SAML:

- In the configuration, `gitlab_rails['omniauth_block_auto_created_users'] = true` is set and this is the user's first time signing in.
- [`required_groups`](../../../integration/saml.md#required-groups) are configured but the user is not a member of one.

## Google workspace troubleshooting tips

The Google Workspace documentation on [SAML app error messages](https://support.google.com/a/answer/6301076?hl=en) is helpful for debugging if you are seeing an error from Google while signing in.
Pay particular attention to the following 403 errors:

- `app_not_configured`
- `app_not_configured_for_user`

## Message: "The member's email address is not linked to a SAML account"

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

This error appears when you try to invite a user to a GitLab.com group (or subgroup or project within a group) that has [SAML SSO enforcement](_index.md#sso-enforcement) enabled.

If you see this message after trying to invite a user to a group:

1. Ensure the user has been [added to the SAML identity provider](_index.md#user-access-and-management).
1. Ask the user to [link SAML to their existing GitLab.com account](_index.md#link-saml-to-your-existing-gitlabcom-account), if they have one. Otherwise, ask the user to create a GitLab.com account by [accessing GitLab.com through the identity provider's dashboard](_index.md#user-access-and-management), or by [signing up manually](https://gitlab.com/users/sign_up) and linking SAML to their new account.
1. Ensure the user is a [member of the top-level group](../_index.md#search-a-group).

Additionally, see [troubleshooting users receiving a 404 after sign in](#users-receive-a-404).

## Message: `The SAML response did not contain an email address.`

If you see this error:

```plaintext
The SAML response did not contain an email address.
Either the SAML identity provider is not configured to send the attribute, or the
identity provider directory does not have an email address value for your user
```

This error appears when:

- the SAML response does not contain the user's email address in an **email** or **mail** attribute.
- a user attempts to [link SAML](_index.md#user-access-and-management) to their account but has not yet completed the [identity verification process](../../../security/identity_verification.md).

Ensure the SAML identity provider is configured to send a [supported mail attribute](../../../integration/saml.md):

```xml
<Attribute Name="email">
  <AttributeValue>user@example.com‹/AttributeValue>
</Attribute>
```

Attribute names starting with phrases such as `http://schemas.xmlsoap.org/ws/2005/05/identity/claims` and `http://schemas.microsoft.com/ws/2008/06/identity/claims/` are supported by default beginning in GitLab 16.7.

```xml
<Attribute Name="http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress">
  <AttributeValue>user@example.com‹/AttributeValue>
</Attribute>
```
