---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting SCIM **(PREMIUM SAAS)**

This section contains possible solutions for problems you might encounter.

## User cannot be added after they are removed

When you remove a user, they are removed from the group but their account is not deleted
(see [remove access](scim_setup.md#remove-access)).

When the user is added back to the SCIM app, GitLab cannot create a new user because the user already exists.

To solve this problem:

1. Have the user sign in directly to GitLab.
1. [Manually link](scim_setup.md#link-scim-and-saml-identities) their account.

## User cannot sign in

The following are possible solutions for problems where users cannot sign in:

- Ensure that the user was added to the SCIM app.
- If you receive the `User is not linked to a SAML account` error, the user probably already exists in GitLab. Have the
  user follow the [Link SCIM and SAML identities](scim_setup.md#link-scim-and-saml-identities) instructions.
- The **Identity** (`extern_uid`) value stored by GitLab is updated by SCIM whenever `id` or `externalId` changes. Users
  cannot sign in unless the GitLab Identity (`extern_uid`) value matches the `NameId` sent by SAML. This value is also
  used by SCIM to match users on the `id`, and is updated by SCIM whenever the `id` or `externalId` values change.
- The SCIM `id` and SCIM `externalId` must be configured to the same value as the SAML `NameId`. You can trace SAML responses
  using [debugging tools](troubleshooting.md#saml-debugging-tools), and check any errors against the
  [SAML troubleshooting](troubleshooting.md) information.

## Unsure if user's SAML `NameId` matches the SCIM `externalId`

To check if a user's SAML `NameId` matches their SCIM `externalId`:

- Administrators can use the Admin Area to [list SCIM identities for a user](../../admin_area/index.md#user-identities).
- Group owners can see the list of users and the identifier stored for each user in the group SAML SSO Settings page.
- You can use the [SCIM API](../../../api/scim.md) to manually retrieve the `external_uid` GitLab has stored for users and compare the value for each user from the [SAML API](../../../api/saml.md) .
- Have the user use a [SAML Tracer](troubleshooting.md#saml-debugging-tools) and compare the `external_uid` to
  the value returned as the SAML `NameId`.

## Mismatched SCIM `extern_uid` and SAML `NameId`

Whether the value was changed or you need to map to a different field, the following must map to the same field:

- `id`
- `externalId`
- `NameId`

If the GitLab `extern_uid` doesn't match the SAML `NameId`, it must be updated for the user to sign in. Your identity
provider should be configured to do this update. In some cases the identity provider cannot do the update, for example
when a user lookup fails because of an ID change.

Be cautious if you revise the fields used by your SCIM identity provider, typically `id` and `externalId`.
GitLab uses these IDs to look up users. If the identity provider does not know the current values for these fields,
that provider may create duplicate users.

If the `extern_uid` for a user is not correct, and also doesn't match the SAML `NameID`, either:

- Have users unlink and relink themselves, based on the
  [SAML authentication failed: User has already been taken](troubleshooting.md#message-saml-authentication-failed-user-has-already-been-taken)
  section.
- Unlink all users simultaneously by removing all users from the SCIM app while provisioning is turned on.
- Use the [SCIM API](../../../api/scim.md) to manually correct the `extern_uid` stored for users to match the SAML
  `NameId`. To look up a user, you must know the desired value that matches the `NameId` as well as the current
  `extern_uid`.

You must not:

- Update these to incorrect values because this causes users to be unable to sign in.
- Assign a value to the wrong user because this causes users to be signed in to the wrong account.

## Change SCIM app

When the SCIM app changes:

- Users can follow the instructions in the [Change the SAML app](index.md#change-the-identity-provider) section.
- Administrators of the identity provider can:
  1. Remove users from the SCIM app, which unlinks all removed users.
  1. Turn on sync for the new SCIM app to [link existing users](scim_setup.md#link-scim-and-saml-identities).

## SCIM app returns `"User has already been taken","status":409` error

Changing the SAML or SCIM configuration or provider can cause the following problems:

- SAML and SCIM identity mismatch. To solve this problem:
  1. [Verify that the user's SAML `NameId` matches the SCIM `extern_uid`](#unsure-if-users-saml-nameid-matches-the-scim-externalid).
  1. [Update or fix the mismatched SCIM `extern_uid` and SAML `NameId`](#mismatched-scim-extern_uid-and-saml-nameid).
- SCIM identity mismatch between GitLab and the identity provider SCIM app. To solve this problem:
  1. Use the [SCIM API](../../../api/scim.md), which displays the user's `extern_uid` stored in GitLab and compares it with the user `externalId` in
     the SCIM app.
  1. Use the same SCIM API to update the SCIM `extern_uid` for the user on GitLab.com.

## Search Rails logs for SCIM requests

GitLab.com administrators can search for SCIM requests in the `api_json.log` using the `pubsub-rails-inf-gprd-*` index in
[Kibana](https://about.gitlab.com/handbook/support/workflows/kibana.html#using-kibana). Use the following filters based
on the internal [group SCIM API](../../../development/internal_api/index.md#group-scim-api):

- `json.path`: `/scim/v2/groups/<group-path>`
- `json.params.value`: `<externalId>`

In a relevant log entry, the `json.params.value` shows the values of SCIM parameters GitLab receives. Use these values
to verify if SCIM parameters configured in an identity provider's SCIM app are communicated to GitLab as intended.

For example, use these values as a definitive source on why an account was provisioned with a certain set of
details. This information can help where an account was SCIM provisioned with details that do not match
the SCIM app configuration.

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

When checking the Audit Events for the provisioning, you sometimes see a `Namespace can't be blank, Name can't be blank,
and User can't be blank.` error.

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
to [synchronize Azure Active Directory groups to AppName](scim_setup.md#configure-azure-active-directory).

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
- [Self-managed GitLab instances](../../admin_area/settings/scim_setup.md#configure-gitlab).

For self-managed GitLab instances, ensure that GitLab is publicly available so Okta can connect to it. If needed,
you can [allow access to Okta IP addresses](https://help.okta.com/en-us/Content/Topics/Security/ip-address-allow-listing.htm)
on your firewall.
