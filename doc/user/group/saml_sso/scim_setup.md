---
type: howto, reference
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# SCIM provisioning using SAML SSO for GitLab.com groups **(PREMIUM SAAS)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/9388) in GitLab Premium 11.10.

System for Cross-domain Identity Management (SCIM), is an open standard that enables the
automation of user provisioning. When SCIM is provisioned for a GitLab group, membership of
that group is synchronized between GitLab and the identity provider.

The GitLab [SCIM API](../../../api/scim.md) implements part of [the RFC7644 protocol](https://tools.ietf.org/html/rfc7644).

## Features

The following actions are available:

- Create users
- Deactivate users

The following identity providers are supported:

- Azure
- Okta

## Requirements

- [Group Single Sign-On](index.md) must be configured.

## GitLab configuration

Once [Group Single Sign-On](index.md) has been configured, we can:

1. Navigate to the group and click **Administration > SAML SSO**.
1. Click on the **Generate a SCIM token** button.
1. Save the token and URL so they can be used in the next step.

![SCIM token configuration](img/scim_token_v13_3.png)

## Identity Provider configuration

- [Azure](#azure-configuration-steps)
- [Okta](#okta-configuration-steps)

### Azure configuration steps

The SAML application that was created during [Single sign-on](index.md) setup for [Azure](https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/view-applications-portal) now needs to be set up for SCIM.

1. Set up automatic provisioning and administrative credentials by following the
   [Azure's SCIM setup documentation](https://docs.microsoft.com/en-us/azure/active-directory/app-provisioning/use-scim-to-provision-users-and-groups#provisioning-users-and-groups-to-applications-that-support-scim).

During this configuration, note the following:

- The `Tenant URL` and `secret token` are the ones retrieved in the
  [previous step](#gitlab-configuration).
- It is recommended to set a notification email and check the **Send an email notification when a failure occurs** checkbox.
- For mappings, we will only leave `Synchronize Azure Active Directory Users to AppName` enabled.

You can then test the connection by clicking on **Test Connection**. If the connection is successful, be sure to save your configuration before moving on. See below for [troubleshooting](#troubleshooting).

#### Configure attribute mapping

Follow [Azure documentation to configure the attribute mapping](https://docs.microsoft.com/en-us/azure/active-directory/app-provisioning/customize-application-attributes).

The following table below provides an attribute mapping known to work with GitLab. If
your SAML configuration differs from [the recommended SAML settings](index.md#azure-setup-notes),
modify the corresponding `customappsso` settings accordingly. If a mapping is not listed in the
table, use the Azure defaults.

| Azure Active Directory Attribute | `customappsso` Attribute | Matching precedence |
| -------------------------------- | ---------------------- | -------------------- |
| `objectId`                       | `externalId`           | 1 |
| `userPrincipalName`              | `emails[type eq "work"].value` |  |
| `mailNickname`                   | `userName`             |  |

For guidance, you can view [an example configuration in the troubleshooting reference](../../../administration/troubleshooting/group_saml_scim.md#azure-active-directory).

1. Below the mapping list click on **Show advanced options > Edit attribute list for AppName**.
1. Ensure the `id` is the primary and required field, and `externalId` is also required.

   NOTE:
   `username` should neither be primary nor required as we don't support
   that field on GitLab SCIM yet.

1. Save all changes.
1. In the **Provisioning** step, set the `Provisioning Status` to `On`.

   NOTE:
   You can control what is actually synced by selecting the `Scope`. For example,
   `Sync only assigned users and groups` only syncs the users assigned to
   the application (`Users and groups`), otherwise, it syncs the whole Active Directory.

Once enabled, the synchronization details and any errors appears on the
bottom of the **Provisioning** screen, together with a link to the audit events.

WARNING:
Once synchronized, changing the field mapped to `id` and `externalId` may cause a number of errors. These include provisioning errors, duplicate users, and may prevent existing users from accessing the GitLab group.

### Okta configuration steps

Before you start this section, complete the [GitLab configuration](#gitlab-configuration) process.
Make sure that you've also set up a SAML application for [Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/overview/),
as described in the [Okta setup notes](index.md#okta-setup-notes)

Make sure that the Okta setup matches our documentation exactly, especially the NameID
configuration. Otherwise, the Okta SCIM app may not work properly.

1. Sign in to Okta.
1. If you see an **Admin** button in the top right, click the button. This will
   ensure you are in the Admin area.

   NOTE:
   If you're using the Developer Console, click **Developer Console** in the top
   bar and select **Classic UI**. Otherwise, you may not see the buttons described
   in the following steps:

1. In the **Application** tab, click **Add Application**.
1. Search for **GitLab**, find and click on the 'GitLab' application.
1. On the GitLab application overview page, click **Add**.
1. Under **Application Visibility** select both check boxes. Currently the GitLab application does not support SAML authentication so the icon should not be shown to users.
1. Click **Done** to finish adding the application.
1. In the **Provisioning** tab, click **Configure API integration**.
1. Select **Enable API integration**.
    - For **Base URL** enter the URL obtained from the GitLab SCIM configuration page
    - For **API Token** enter the SCIM token obtained from the GitLab SCIM configuration page
1. Click 'Test API Credentials' to verify configuration.
1. Click **Save** to apply the settings.
1. After saving the API integration details, new settings tabs appear on the left. Choose **To App**.
1. Click **Edit**.
1. Check the box to **Enable** for both **Create Users** and **Deactivate Users**.
1. Click **Save**.
1. Assign users in the **Assignments** tab. Assigned users are created and
   managed in your GitLab group.

#### Okta Known Issues

The Okta GitLab application currently only supports SCIM. Continue
using the separate Okta [SAML SSO](index.md) configuration along with the new SCIM
application described above.

### OneLogin

OneLogin provides a "GitLab (SaaS)" app in their catalog, which includes a SCIM integration.
As the app is developed by OneLogin, please reach out to OneLogin if you encounter issues.

## User access and linking setup

During the synchronization process, all of your users get GitLab accounts, welcoming them
to their respective groups, with an invitation email. When implementing SCIM provisioning,
you may want to warn your security-conscious employees about this email.

The following diagram is a general outline on what happens when you add users to your SCIM app:

```mermaid
graph TD
  A[Add User to SCIM app] -->|IdP sends user info to GitLab| B(GitLab: Does the email exists?)
  B -->|No| C[GitLab creates user with SCIM identity]
  B -->|Yes| D[GitLab sends message back 'Email exists']
```

As long as [Group SAML](index.md) has been configured, existing GitLab.com users can link to their accounts in one of the following ways:

- By updating their *primary* email address in their GitLab.com user account to match their identity provider's user profile email address.
- By following these steps:

  1. Sign in to GitLab.com if needed.
  1. Click on the GitLab app in the identity provider's dashboard or visit the **GitLab single sign-on URL**.
  1. Click on the **Authorize** button.

We recommend users do this prior to turning on sync, because while synchronization is active, there may be provisioning errors for existing users.

New users and existing users on subsequent visits can access the group through the identify provider's dashboard or by visiting links directly.

[In GitLab 14.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/325712), GitLab users created with a SCIM identity display with an **Enterprise** badge in the **Members** view.

![Enterprise badge for users created with a SCIM identity](img/member_enterprise_badge_v14_0.png)

For role information, please see the [Group SAML page](index.md#user-access-and-management)

### Blocking access

To rescind access to the group, remove the user from the identity
provider or users list for the specific app.

Upon the next sync, the user is deprovisioned, which means that the user is removed from the group.

NOTE:
Deprovisioning does not delete the user account.

```mermaid
graph TD
  A[Remove User from SCIM app] -->|IdP sends request to GitLab| B(GitLab: Is the user part of the group?)
  B -->|No| C[Nothing to do]
  B -->|Yes| D[GitLab removes user from GitLab group]
```

## Troubleshooting

This section contains possible solutions for problems you might encounter.

### How come I can't add a user after I removed them?

As outlined in the [Blocking access section](#blocking-access), when you remove a user, they are removed from the group. However, their account is not deleted.

When the user is added back to the SCIM app, GitLab cannot create a new user because the user already exists.

Solution: Have a user sign in directly to GitLab, then [manually link](#user-access-and-linking-setup) their account.

### How do I diagnose why a user is unable to sign in

Ensure that the user has been added to the SCIM app.

If you receive "User is not linked to a SAML account", then most likely the user already exists in GitLab. Have the user follow the [User access and linking setup](#user-access-and-linking-setup) instructions.

The **Identity** (`extern_uid`) value stored by GitLab is updated by SCIM whenever `id` or `externalId` changes. Users cannot sign in unless the GitLab Identity (`extern_uid`) value matches the `NameId` sent by SAML.

This value is also used by SCIM to match users on the `id`, and is updated by SCIM whenever the `id` or `externalId` values change.

It is important that this SCIM `id` and SCIM `externalId` are configured to the same value as the SAML `NameId`. SAML responses can be traced using [debugging tools](index.md#saml-debugging-tools), and any errors can be checked against our [SAML troubleshooting docs](index.md#troubleshooting).

### How do I verify user's SAML NameId matches the SCIM externalId

Group owners can see the list of users and the `externalId` stored for each user in the group SAML SSO Settings page.

A possible alternative is to use the [SCIM API](../../../api/scim.md#get-a-list-of-scim-provisioned-users) to manually retrieve the `externalId` we have stored for users, also called the `external_uid` or `NameId`.

To see how the `external_uid` compares to the value returned as the SAML NameId, you can have the user use a [SAML Tracer](index.md#saml-debugging-tools).

### Update or fix mismatched SCIM externalId and SAML NameId

Whether the value was changed or you need to map to a different field, ensure `id`, `externalId`, and `NameId` all map to the same field.

If the GitLab `externalId` doesn't match the SAML NameId, it needs to be updated in order for the user to sign in. Ideally your identity provider is configured to do such an update, but in some cases it may be unable to do so, such as when looking up a user fails due to an ID change.

Be cautious if you revise the fields used by your SCIM identity provider, typically `id` and `externalId`.
We use these IDs to look up users. If the identity provider does not know the current values for these fields,
that provider may create duplicate users.

If the `externalId` for a user is not correct, and also doesn't match the SAML NameID,
you can address the problem in the following ways:

- You can have users unlink and relink themselves, based on the ["SAML authentication failed: User has already been taken"](index.md#message-saml-authentication-failed-user-has-already-been-taken) section.
- You can unlink all users simultaneously, by removing all users from the SAML app while provisioning is turned on.
- It may be possible to use the [SCIM API](../../../api/scim.md#update-a-single-scim-provisioned-user) to manually correct the `externalId` stored for users to match the SAML `NameId`.
  To look up a user, you need to know the desired value that matches the `NameId` as well as the current `externalId`.

It is important not to update these to incorrect values, since this causes users to be unable to sign in. It is also important not to assign a value to the wrong user, as this causes users to get signed into the wrong account.

### I need to change my SCIM app

Individual users can follow the instructions in the ["SAML authentication failed: User has already been taken"](index.md#i-need-to-change-my-saml-app) section.

Alternatively, users can be removed from the SCIM app which de-links all removed users. Sync can then be turned on for the new SCIM app to [link existing users](#user-access-and-linking-setup).

### The SCIM app is throwing `"User has already been taken","status":409` error message

Changing the SAML or SCIM configuration or provider can cause the following problems:

| Problem                                                                      | Solution           |
|------------------------------------------------------------------------------|--------------------|
| SAML and SCIM identity mismatch. | First [verify that the user's SAML NameId matches the SCIM externalId](#how-do-i-verify-users-saml-nameid-matches-the-scim-externalid) and then [update or fix the mismatched SCIM externalId and SAML NameId](#update-or-fix-mismatched-scim-externalid-and-saml-nameid). |
| SCIM identity mismatch between GitLab and the Identify Provider SCIM app. | You can confirm whether you're hitting the error because of your SCIM identity mismatch between your SCIM app and GitLab.com by using [SCIM API](../../../api/scim.md#update-a-single-scim-provisioned-user) which shows up in the `id` key and compares it with the user `externalId` in the SCIM app. You can use the same [SCIM API](../../../api/scim.md#update-a-single-scim-provisioned-user) to update the SCIM `id` for the user on GitLab.com. |

### Azure

#### How do I verify my SCIM configuration is correct?

Review the following:

- Ensure that the SCIM value for `id` matches the SAML value for `NameId`.
- Ensure that the SCIM value for `externalId` matches the SAML value for `NameId`.

Review the following SCIM parameters for sensible values:

- `userName`
- `displayName`
- `emails[type eq "work"].value`

#### Testing Azure connection: invalid credentials

When testing the connection, you may encounter an error: **You appear to have entered invalid credentials. Please confirm you are using the correct information for an administrative account**. If `Tenant URL` and `secret token` are correct, check whether your group path contains characters that may be considered invalid JSON primitives (such as `.`). Removing such characters from the group path typically resolves the error.

#### (Field) can't be blank sync error

When checking the Audit Events for the Provisioning, you can sometimes see the
error `Namespace can't be blank, Name can't be blank, and User can't be blank.`

This is likely caused because not all required fields (such as first name and last name) are present for all users being mapped.

As a workaround, try an alternate mapping:

1. Follow the Azure mapping instructions from above.
1. Delete the `name.formatted` target attribute entry.
1. Change the `displayName` source attribute to have `name.formatted` target attribute.
