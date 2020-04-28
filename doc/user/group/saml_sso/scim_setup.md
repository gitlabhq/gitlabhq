---
type: howto, reference
---

# SCIM provisioning using SAML SSO for GitLab.com groups **(SILVER ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/9388) in [GitLab.com Silver](https://about.gitlab.com/pricing/) 11.10.

System for Cross-domain Identity Management (SCIM), is an open standard that enables the
automation of user provisioning. When SCIM is provisioned for a GitLab group, membership of
that group is synchronized between GitLab and the identity provider.

GitLab's [SCIM API](../../../api/scim.md) implements part of [the RFC7644 protocol](https://tools.ietf.org/html/rfc7644).

## Features

Currently, the following actions are available:

- Create users
- Update users (Azure only)
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

![SCIM token configuration](img/scim_token.png)

## Identity Provider configuration

- [Azure](#azure-configuration-steps)
- [Okta](#okta-configuration-steps)

### Azure configuration steps

The SAML application that was created during [Single sign-on](index.md) setup for [Azure](https://docs.microsoft.com/en-us/azure/active-directory/manage-apps/configure-single-sign-on-non-gallery-applications) now needs to be set up for SCIM.

1. Check the configuration for your GitLab SAML app and ensure that **Name identifier value** (NameID) points to `user.objectid` or another unique identifier. This will match the `extern_uid` used on GitLab.

   ![Name identifier value mapping](img/scim_name_identifier_mapping.png)

1. Set up automatic provisioning and administrative credentials by following the
   [Provisioning users and groups to applications that support SCIM](https://docs.microsoft.com/en-us/azure/active-directory/app-provisioning/use-scim-to-provision-users-and-groups#provisioning-users-and-groups-to-applications-that-support-scim) section in Azure's SCIM setup documentation.

During this configuration, note the following:

- The `Tenant URL` and `secret token` are the ones retrieved in the
  [previous step](#gitlab-configuration).
- Should there be any problems with the availability of GitLab or similar
  errors, the notification email set will get those.
- It is recommended to set a notification email and check the **Send an email notification when a failure occurs** checkbox.
- For mappings, we will only leave `Synchronize Azure Active Directory Users to AppName` enabled.

You can then test the connection by clicking on **Test Connection**. If the connection is successful, be sure to save your configuration before moving on. See below for [troubleshooting](#troubleshooting).

#### Configure attribute mapping

1. Click on `Synchronize Azure Active Directory Users to AppName` to configure the attribute mapping.
1. Click **Delete** next to the `mail` mapping.
1. Map `userPrincipalName` to `emails[type eq "work"].value` and change its **Matching precedence** to `2`.
1. Map `mailNickname` to `userName`.
1. Determine how GitLab will uniquely identify users.

    - Use `objectId` unless users already have SAML linked for your group.
    - If you already have users with SAML linked then use the `Name ID` value from the [SAML configuration](#azure). Using a different value will likely cause duplicate users and prevent users from accessing the GitLab group.

1. Create a new mapping:
   1. Click **Add New Mapping**.
   1. Set:
      - **Source attribute** to the unique identifier determined above, typically `objectId`.
      - **Target attribute** to `externalId`.
      - **Match objects using this attribute** to `Yes`.
      - **Matching precedence** to `1`.

1. Click the `userPrincipalName` mapping and change **Match objects using this attribute** to `No`.

1. Save your changes. For reference, you can view [an example configuration in the troubleshooting reference](../../../administration/troubleshooting/group_saml_scim.md#azure-active-directory).

   NOTE: **Note:** If you used a unique identifier **other than** `objectId`, be sure to map it to `externalId`.

1. Below the mapping list click on **Show advanced options > Edit attribute list for AppName**.

1. Ensure the `id` is the primary and required field, and `externalId` is also required.

   NOTE: **Note:**
   `username` should neither be primary nor required as we don't support
   that field on GitLab SCIM yet.

1. Save all the screens and, in the **Provisioning** step, set
   the `Provisioning Status` to `On`.

   ![Provisioning status toggle switch](img/scim_provisioning_status.png)

   NOTE: **Note:**
   You can control what is actually synced by selecting the `Scope`. For example,
   `Sync only assigned users and groups` will only sync the users assigned to
   the application (`Users and groups`), otherwise, it will sync the whole Active Directory.

Once enabled, the synchronization details and any errors will appear on the
bottom of the **Provisioning** screen, together with a link to the audit logs.

CAUTION: **Warning:**
Once synchronized, changing the field mapped to `id` and `externalId` will likely cause provisioning errors, duplicate users, and prevent existing users from accessing the GitLab group.

### Okta configuration steps

The SAML application that was created during [Single sign-on](index.md#okta-setup-notes) setup for [Okta](https://developer.okta.com/docs/guides/saml-application-setup/overview/) now needs to be set up for SCIM.

1. Sign in to Okta.
1. If you see an **Admin** button in the top right, click the button. This will
   ensure you are in the Admin area.

   TIP: **Tip:** If you're using the Developer Console, click **Developer Console** in the top
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
1. After saving the API integration details, new settings tabs will appear on the left. Choose **To App**.
1. Click **Edit**.
1. Check the box to **Enable** for both **Create Users** and **Deactivate Users**.
1. Click **Save**.
1. Assign users in the **Assignments** tab. Assigned users will be created and
   managed in your GitLab group.

#### Okta Known Issues

The Okta GitLab application currently only supports SCIM. Continue
using the separate Okta [SAML SSO](index.md) configuration along with the new SCIM
application described above.

## User access and linking setup

As long as [Group SAML](index.md) has been configured, prior to turning on sync, existing GitLab.com users can link to their accounts in one of the following ways, before synchronization is active:

- By updating their *primary* email address in their GitLab.com user account to match their identity provider's user profile email address.
- By following these steps:

  1. Sign in to GitLab.com if needed.
  1. Click on the GitLab app in the identity provider's dashboard or visit the **GitLab single sign on URL**.
  1. Click on the **Authorize** button.

New users and existing users on subsequent visits can access the group through the identify provider's dashboard or by visiting links directly.

For role information, please see the [Group SAML page](index.md#user-access-and-management)

### Blocking access

To rescind access to the group, we recommend removing the user from the identity
provider or users list for the specific app.

Upon the next sync, the user will be deprovisioned, which means that the user will be removed from the group. The user account will not be deleted unless using [group managed accounts](index.md#group-managed-accounts).

## Troubleshooting

This section contains possible solutions for problems you might encounter.

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

#### Azure: (Field) can't be blank sync error

When checking the Audit Logs for the Provisioning, you can sometimes see the
error `Namespace can't be blank, Name can't be blank, and User can't be blank.`

This is likely caused because not all required fields (such as first name and last name) are present for all users being mapped.

As a workaround, try an alternate mapping:

1. Follow the Azure mapping instructions from above.
1. Delete the `name.formatted` target attribute entry.
1. Change the `displayName` source attribute to have `name.formatted` target attribute.

#### How do I diagnose why a user is unable to sign in

The **Identity** (`extern_uid`) value stored by GitLab is updated by SCIM whenever `id` or `externalId` changes. Users won't be able to sign in unless the GitLab Identity (`extern_uid`) value matches the `NameId` sent by SAML.

This value is also used by SCIM to match users on the `id`, and is updated by SCIM whenever the `id` or `externalId` values change.

It is important that this SCIM `id` and SCIM `externalId` are configured to the same value as the SAML `NameId`. SAML responses can be traced using [debugging tools](./index.md#saml-debugging-tools), and any errors can be checked against our [SAML troubleshooting docs](./index.md#troubleshooting).

#### How do I verify user's SAML NameId matches the SCIM externalId

Group owners can see the list of users and the `externalId` stored for each user in the group SAML SSO Settings page.

Alternatively, the [SCIM API](../../../api/scim.md#get-a-list-of-saml-users) can be used to manually retrieve the `externalId` we have stored for users, also called the `external_uid` or `NameId`.

For example:

```shell
curl 'https://example.gitlab.com/api/scim/v2/groups/GROUP_NAME/Users?startIndex=1"' --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

To see how this compares to the value returned as the SAML NameId, you can have the user use a [SAML Tracer](index.md#saml-debugging-tools).

#### Update or fix mismatched SCIM externalId and SAML NameId

Whether the value was changed or you need to map to a different field, ensure `id`, `externalId`, and `NameId` all map to the same field.

If GitLab's `externalId` doesn't match the SAML NameId, it will need to be updated in order for the user to log in. Ideally your identity provider will be configured to do such an update, but in some cases it may be unable to do so, such as when looking up a user fails due to an ID change.

Be cautious if you revise the fields used by your SCIM identity provider, typically `id` and `externalId`.
We use these IDs to look up users. If the identity provider does not know the current values for these fields,
that provider may create duplicate users.

If the `externalId` for a user is not correct, and also doesn't match the SAML NameID,
you can address the problem in the following ways:

- You can have users unlink and relink themselves, based on the ["SAML authentication failed: User has already been taken"](./index.md#message-saml-authentication-failed-user-has-already-been-taken) section.
- You can unlink all users simultaneously, by removing all users from the SAML app while provisioning is turned on.
- You can use the [SCIM API](../../../api/scim.md#update-a-single-saml-user) to manually correct the `externalId` stored for users to match the SAML `NameId`.
  To look up a user, you'll need to know the desired value that matches the `NameId` as well as the current `externalId`.

It is then possible to issue a manual SCIM#update request, for example:

```shell
curl --verbose --request PATCH 'https://gitlab.com/api/scim/v2/groups/YOUR_GROUP/Users/OLD_EXTERNAL_UID' --data '{ "Operations": [{"op":"Replace","path":"externalId","value":"NEW_EXTERNAL_UID"}] }' --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

It is important not to update these to incorrect values, since this will cause users to be unable to sign in. It is also important not to assign a value to the wrong user, as this would cause users to get signed into the wrong account.

#### I need to change my SCIM app

Individual users can follow the instructions in the ["SAML authentication failed: User has already been taken"](./index.md#i-need-to-change-my-saml-app) section.

Alternatively, users can be removed from the SCIM app which will delink all removed users. Sync can then be turned on for the new SCIM app to [link existing users](#user-access-and-linking-setup).
