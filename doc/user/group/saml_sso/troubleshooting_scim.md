---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting SCIM **(PREMIUM SAAS)**

This section contains possible solutions for problems you might encounter.

## How come I can't add a user after I removed them?

As outlined in the [Blocking access section](scim_setup.md#blocking-access), when you remove a user, they are removed from the group. However, their account is not deleted.

When the user is added back to the SCIM app, GitLab cannot create a new user because the user already exists.

Solution: Have a user sign in directly to GitLab, then [manually link](scim_setup.md#user-access-and-linking-setup) their account.

## How do I diagnose why a user is unable to sign in

Ensure that the user has been added to the SCIM app.

If you receive "User is not linked to a SAML account", then most likely the user already exists in GitLab. Have the user follow the [User access and linking setup](scim_setup.md#user-access-and-linking-setup) instructions.

The **Identity** (`extern_uid`) value stored by GitLab is updated by SCIM whenever `id` or `externalId` changes. Users cannot sign in unless the GitLab Identity (`extern_uid`) value matches the `NameId` sent by SAML.

This value is also used by SCIM to match users on the `id`, and is updated by SCIM whenever the `id` or `externalId` values change.

It is important that this SCIM `id` and SCIM `externalId` are configured to the same value as the SAML `NameId`. SAML responses can be traced using [debugging tools](troubleshooting.md#saml-debugging-tools), and any errors can be checked against our [SAML troubleshooting docs](troubleshooting.md).

## How do I verify user's SAML NameId matches the SCIM externalId

Admins can use the Admin Area to [list SCIM identities for a user](../../admin_area/index.md#user-identities).

Group owners can see the list of users and the `externalId` stored for each user in the group SAML SSO Settings page.

A possible alternative is to use the [SCIM API](../../../api/scim.md#get-a-list-of-scim-provisioned-users) to manually retrieve the `externalId` we have stored for users, also called the `external_uid` or `NameId`.

To see how the `external_uid` compares to the value returned as the SAML NameId, you can have the user use a [SAML Tracer](troubleshooting.md#saml-debugging-tools).

## Update or fix mismatched SCIM externalId and SAML NameId

Whether the value was changed or you need to map to a different field, ensure `id`, `externalId`, and `NameId` all map to the same field.

If the GitLab `externalId` doesn't match the SAML NameId, it needs to be updated in order for the user to sign in. Ideally your identity provider is configured to do such an update, but in some cases it may be unable to do so, such as when looking up a user fails due to an ID change.

Be cautious if you revise the fields used by your SCIM identity provider, typically `id` and `externalId`.
We use these IDs to look up users. If the identity provider does not know the current values for these fields,
that provider may create duplicate users.

If the `externalId` for a user is not correct, and also doesn't match the SAML NameID,
you can address the problem in the following ways:

- You can have users unlink and relink themselves, based on the ["SAML authentication failed: User has already been taken"](troubleshooting.md#message-saml-authentication-failed-user-has-already-been-taken) section.
- You can unlink all users simultaneously, by removing all users from the SAML app while provisioning is turned on.
- It may be possible to use the [SCIM API](../../../api/scim.md#update-a-single-scim-provisioned-user) to manually correct the `externalId` stored for users to match the SAML `NameId`.
  To look up a user, you need to know the desired value that matches the `NameId` as well as the current `externalId`.

It is important not to update these to incorrect values, since this causes users to be unable to sign in. It is also important not to assign a value to the wrong user, as this causes users to get signed into the wrong account.

## I need to change my SCIM app

Individual users can follow the instructions in the ["SAML authentication failed: User has already been taken"](index.md#change-the-saml-app) section.

Alternatively, users can be removed from the SCIM app which de-links all removed users. Sync can then be turned on for the new SCIM app to [link existing users](scim_setup.md#user-access-and-linking-setup).

## The SCIM app is throwing `"User has already been taken","status":409` error message

Changing the SAML or SCIM configuration or provider can cause the following problems:

| Problem                                                                   | Solution                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SAML and SCIM identity mismatch.                                          | First [verify that the user's SAML NameId matches the SCIM externalId](#how-do-i-verify-users-saml-nameid-matches-the-scim-externalid) and then [update or fix the mismatched SCIM externalId and SAML NameId](#update-or-fix-mismatched-scim-externalid-and-saml-nameid).                                                                                                                                                                              |
| SCIM identity mismatch between GitLab and the identity provider SCIM app. | You can confirm whether you're hitting the error because of your SCIM identity mismatch between your SCIM app and GitLab.com by using [SCIM API](../../../api/scim.md#update-a-single-scim-provisioned-user) which shows up in the `id` key and compares it with the user `externalId` in the SCIM app. You can use the same [SCIM API](../../../api/scim.md#update-a-single-scim-provisioned-user) to update the SCIM `id` for the user on GitLab.com. |

## Search Rails logs for SCIM requests

GitLab.com administrators can search for SCIM requests in the `api_json.log` using the `pubsub-rails-inf-gprd-*` index in [Kibana](https://about.gitlab.com/handbook/support/workflows/kibana.html#using-kibana). Use the following filters based on the [SCIM API](../../../api/scim.md):

- `json.path`: `/scim/v2/groups/<group-path>`
- `json.params.value`: `<externalId>`

In a relevant log entry, the `json.params.value` shows the values of SCIM parameters GitLab receives. These values can be used to verify if SCIM parameters configured in an
identity provider's SCIM app are communicated to GitLab as intended. For example, we can use these values as a definitive source on why an account was provisioned with a certain
set of details. This information can help where an account was SCIM provisioned with details that appear to be incongruent with what might have been configured within an identity
provider's SCIM app.

## Azure

### How do I verify my SCIM configuration is correct?

Review the following:

- Ensure that the SCIM value for `id` matches the SAML value for `NameId`.
- Ensure that the SCIM value for `externalId` matches the SAML value for `NameId`.

Review the following SCIM parameters for sensible values:

- `userName`
- `displayName`
- `emails[type eq "work"].value`

### Testing Azure connection: invalid credentials

When testing the connection, you may encounter an error: **You appear to have entered invalid credentials. Please confirm you are using the correct information for an administrative account**. If `Tenant URL` and `secret token` are correct, check whether your group path contains characters that may be considered invalid JSON primitives (such as `.`). Removing such characters from the group path typically resolves the error.

### (Field) can't be blank sync error

When checking the Audit Events for the Provisioning, you can sometimes see the
error `Namespace can't be blank, Name can't be blank, and User can't be blank.`

This is likely caused because not all required fields (such as first name and last name) are present for all users being mapped.

As a workaround, try an alternate mapping:

1. Follow the Azure mapping instructions from above.
1. Delete the `name.formatted` target attribute entry.
1. Change the `displayName` source attribute to have `name.formatted` target attribute.

### Failed to match an entry in the source and target systems Group 'Group-Name'

Group provisioning in Azure can fail with the `Failed to match an entry in the source and target systems Group 'Group-Name'` error message,
and the error response can include a HTML result of the GitLab URL `https://gitlab.com/users/sign_in`.

This error is harmless and occurs because Group provisioning was turned on but GitLab SCIM integration does not support it nor require it. To
remove the error, follow the instructions in the Azure configuration guide to disable the option
[`Synchronize Azure Active Directory Groups to AppName`](scim_setup.md#configure-azure-active-directory).
