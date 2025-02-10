---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting SCIM
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This section contains possible solutions for problems you might encounter.

## User cannot be added after they are removed

When you remove a user, they are removed from the group but their account is not deleted
(see [remove access](scim_setup.md#remove-access)).

When the user is added back to the SCIM app, GitLab does not create a new user because the user already exists.

From August 11, 2023, the `skip_saml_identity_destroy_during_scim_deprovision` feature flag is enabled.

For a user de-provisioned by SCIM from that date, their SAML identity is not removed.
When that user is added back to the SCIM app:

- Their SCIM identity `active` attribute is set to `true`.
- They can sign in using SSO.

For users de-provisioned by SCIM before that date, their SAML identity is destroyed.
To solve this problem, the user must [link SAML to their existing GitLab.com account](_index.md#link-saml-to-your-existing-gitlabcom-account).

### GitLab Self-Managed

For GitLab Self-Managed, administrators of that instance can instead [add the user identity themselves](../../../administration/admin_area.md#user-identities). This might save time if administrators need to re-add multiple identities.

## User cannot sign in

The following are possible solutions for problems where users cannot sign in:

- Ensure that the user was added to the SCIM app.
- If you receive the `User is not linked to a SAML account` error, the user probably already exists in GitLab. Have the
  user follow the [Link SCIM and SAML identities](scim_setup.md#link-scim-and-saml-identities) instructions.
  Alternatively, self-managed administrators can [add a user identity](../../../administration/admin_area.md#user-identities).
- The **Identity** (`extern_uid`) value stored by GitLab is updated by SCIM whenever `id` or `externalId` changes. Users
  cannot sign in unless the GitLab identifier (`extern_uid`) of the sign-in method matches the ID sent by the provider, such as
  the `NameId` sent by SAML. This value is also used by SCIM to match users on the `id`, and is updated by SCIM whenever the `id` or `externalId` values change.
- On GitLab.com, the SCIM `id` and SCIM `externalId` must be configured to the same value as the SAML `NameId`. You can trace SAML responses
  using [debugging tools](troubleshooting.md#saml-debugging-tools), and check any errors against the
  [SAML troubleshooting](troubleshooting.md) information.

## Unsure if user's SAML `NameId` matches the SCIM `externalId`

To check if a user's SAML `NameId` matches their SCIM `externalId`:

- Administrators can use the **Admin** area to [list SCIM identities for a user](../../../administration/admin_area.md#user-identities).
- Group owners can see the list of users and the identifier stored for each user in the group SAML SSO Settings page.
- You can use the [SCIM API](../../../api/scim.md) to manually retrieve the `extern_uid` GitLab has stored for users and compare the value for each user from the [SAML API](../../../api/saml.md) .
- Have the user use a [SAML Tracer](troubleshooting.md#saml-debugging-tools) and compare the `extern_uid` to
  the value returned as the SAML `NameId`.

## Mismatched SCIM `extern_uid` and SAML `NameId`

Whether the value was changed or you need to map to a different field, the following must map to the same field:

- `extern_Id`
- `NameId`

If the SCIM `extern_uid` does not match the SAML `NameId`, you must update the SCIM `extern_uid` to enable the user to sign in.

Be cautious if you revise the fields used by your SCIM identity provider, typically `extern_Id`.
Your identity provider should be configured to do this update.
In some cases the identity provider cannot do the update, for example when a user lookup fails.

GitLab uses these IDs to look up users.
If the identity provider does not know the current values for these fields,
that provider may create duplicate users, or fail to complete expected actions.

To change the identifier values to match, you can do one of the following:

- Have users unlink and relink themselves, based on the
  [SAML authentication failed: User has already been taken](troubleshooting.md#message-saml-authentication-failed-user-has-already-been-taken)
  section.
- Unlink all users simultaneously by removing all users from the SCIM app while provisioning is turned on.

  WARNING:
  This resets all users' roles in the top-level group and subgroups to the [configured default membership role](_index.md#configure-gitlab).
- Use the [SAML API](../../../api/saml.md) or [SCIM API](../../../api/scim.md) to manually correct the `extern_uid` stored for users to match the SAML
  `NameId` or SCIM `externalId`.

You must not:

- Update these to incorrect values because this causes users to be unable to sign in.
- Assign a value to the wrong user because this causes users to be signed in to the wrong account.

Additionally, the user's primary email must match the email in your SCIM identity provider.

## Change SCIM app

When the SCIM app changes:

- Users can follow the instructions in the [Change the SAML app](_index.md#change-the-identity-provider) section.
- Administrators of the identity provider can:
  1. Remove users from the SCIM app, which:
     - In GitLab.com, removes all removed users from the group.
     - In GitLab Self-Managed, blocks users.
  1. Turn on sync for the new SCIM app to [link existing users](scim_setup.md#link-scim-and-saml-identities).

## SCIM app returns `"User has already been taken","status":409` error

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

Changing the SAML or SCIM configuration or provider can cause the following problems:

- SAML and SCIM identity mismatch. To solve this problem:
  1. [Verify that the user's SAML `NameId` matches the SCIM `extern_uid`](#unsure-if-users-saml-nameid-matches-the-scim-externalid).
  1. [Update or fix the mismatched SCIM `extern_uid` and SAML `NameId`](#mismatched-scim-extern_uid-and-saml-nameid).
- SCIM identity mismatch between GitLab and the identity provider SCIM app. To solve this problem:
  1. Use the [SCIM API](../../../api/scim.md), which displays the user's `extern_uid` stored in GitLab and compares it with the user `externalId` in
     the SCIM app.
  1. Use the same SCIM API to update the SCIM `extern_uid` for the user on GitLab.com.

## The member's email address is not allowed for this group

SCIM provisioning may fail with HTTP status `412` and the following error message:

```plaintext
The member's email address is not allowed for this group. Check with your administrator.
```

This error occurs when both of the following are true:

- [Restrict group access by domain](../access_and_permissions.md) is configured
  for the group.
- The user account being provisioned has an email domain that is not allowed.

To resolve this issue, you can do either of the following:

- Add the user account's email domain to the list of allowed domains.
- Disable the [Restrict group access by domain](../access_and_permissions.md)
  feature by removing all domains.

## Search Rails logs for SCIM requests

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

GitLab.com administrators can search for SCIM requests in the `api_json.log` using the `pubsub-rails-inf-gprd-*` index in
[Kibana](https://handbook.gitlab.com/handbook/support/workflows/kibana/#using-kibana). Use the following filters based
on the internal [group SCIM API](../../../development/internal_api/_index.md#group-scim-api):

- `json.path`: `/scim/v2/groups/<group-path>`
- `json.params.value`: `<externalId>`

In a relevant log entry, the `json.params.value` shows the values of SCIM parameters GitLab receives. Use these values
to verify if SCIM parameters configured in an identity provider's SCIM app are communicated to GitLab as intended.

For example, use these values as a definitive source on why an account was provisioned with a certain set of
details. This information can help where an account was SCIM provisioned with details that do not match
the SCIM app configuration.

## Member's email address is not linked error in SCIM log

When you attempt to provision a SCIM user on GitLab.com, GitLab checks to see if
a user with that email address already exists. You might see the following error
when the:

- User exists, but does not have a SAML identity linked.
- User exists, has a SAML identity, **and** has a SCIM identity that is set to `active: false`.

```plaintext
The member's email address is not linked to a SAML account or has an inactive
SCIM identity.
```

This error message is returned with the status `412`.

This might prevent the affected end user from accessing their account correctly.

The first workaround is:

1. Have the end user [link SAML to their existing GitLab.com account](_index.md#link-saml-to-your-existing-gitlabcom-account).
1. After the user has done this, initiate a SCIM sync from your identity provider.
   If the SCIM sync completes without the same error, GitLab has
   successfully linked the SCIM identity to the existing user account, and the user
   should now be able to sign in using SAML SSO.

If the error persists, the user most likely already exists, has both a SAML and
SCIM identity, and a SCIM identity that is set to `active: false`. To resolve
this:

1. Optional. If you did not save your SCIM token when you first configured SCIM, [generate a new token](scim_setup.md#configure-gitlab). If you generate a new SCIM token, you **must** update the token in your identity provider's SCIM configuration, or SCIM will stop working.
1. Locate your SCIM token.
1. Use the API to [get a single SCIM provisioned user](../../../development/internal_api/_index.md#get-a-single-scim-provisioned-user).
1. Check the returned information to make sure that:

   - The user's identifier (`id`) and email match what your identity provider is sending.
   - `active` is set to `false`.

   If any of this information does not match, [contact GitLab Support](https://support.gitlab.com/).
1. Use the API to [update the SCIM provisioned user's `active` value to `true`](../../../development/internal_api/_index.md#update-a-single-scim-provisioned-user).
1. If the update returns a status code `204`, have the user attempt to sign in
   using SAML SSO.

## Azure Active Directory

The following troubleshooting information is specifically for SCIM provisioned through Azure Active Directory.

### Verify my SCIM configuration is correct

Ensure that:

- The matching precedence for `externalId` is 1.
- The SCIM value for `externalId` matches the SAML value for `NameId`.

Review the following SCIM parameters for sensible values:

- `userName`
- `displayName`
- `emails[type eq "work"].value`

### `invalid credentials` error when testing connection

When testing the connection, you may encounter an error:

```plaintext
You appear to have entered invalid credentials. Please confirm
you are using the correct information for an administrative account
```

If `Tenant URL` and `secret token` are correct, check whether your group path contains characters that may be considered
invalid JSON primitives (such as `.`). Removing or URL encoding these characters in the group path typically resolves the error.

### `(Field) can't be blank` sync error

When checking the audit events for the provisioning, you sometimes see a
`Namespace can't be blank, Name can't be blank, and User can't be blank.` error.

This error can occur because not all required fields (such as first name and last name) are present for all users
being mapped.

As a workaround, try an alternate mapping:

1. Follow the [Azure mapping instructions](scim_setup.md#configure-attribute-mappings).
1. Delete the `name.formatted` target attribute entry.
1. Change the `displayName` source attribute to have `name.formatted` target attribute.

### `Failed to match an entry in the source and target systems Group 'Group-Name'` error

Group provisioning in Azure can fail with the `Failed to match an entry in the source and target systems Group 'Group-Name'`
error. The error response can include a HTML result of the GitLab URL `https://gitlab.com/users/sign_in`.

This error is harmless and occurs because group provisioning was turned on but GitLab SCIM integration does not support
it nor require it. To remove the error, follow the instructions in the Azure configuration guide to disable the option
to [synchronize Azure Active Directory groups to AppName](scim_setup.md#configure-microsoft-entra-id-formerly-azure-active-directory).

## Okta

The following troubleshooting information is specifically for SCIM provisioned through Okta.

### `Error authenticating: null` message when testing API SCIM credentials

When testing the API credentials in your Okta SCIM application, you may encounter an error:

```plaintext
Error authenticating: null
```

Okta needs to be able to connect to your GitLab instance to provision or deprovision users.

In your Okta SCIM application, check that the SCIM **Base URL** is correct and pointing to a valid GitLab
SCIM API endpoint URL. Check the following documentation to find information on this URL for:

- [GitLab.com groups](scim_setup.md#configure-gitlab).
- [GitLab Self-Managed](../../../administration/settings/scim_setup.md#configure-gitlab).

For GitLab Self-Managed, ensure your instance is publicly available so Okta can connect to it. If needed,
you can [allow access to Okta IP addresses](https://help.okta.com/en-us/Content/Topics/Security/ip-address-allow-listing.htm)
on your firewall.
