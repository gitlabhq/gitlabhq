---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure SCIM for GitLab Self-Managed or GitLab Dedicated
description: Manage the user lifecycle with automated account provisioning.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8902) in GitLab 15.8.

{{< /history >}}

You can use the open standard System for Cross-domain Identity Management (SCIM) to automatically:

- Create users.
- Block users.
- Re-add users (reactivate SCIM identity).

The [internal GitLab SCIM API](../../development/internal_api/_index.md#instance-scim-api) implements part of [the RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).

If you are a GitLab.com user, see [configuring SCIM for GitLab.com groups](../../user/group/saml_sso/scim_setup.md).

## Configure GitLab

Prerequisites:

- Configure [SAML single sign-on](../../integration/saml.md).

To configure GitLab SCIM:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand the **SCIM Token** section and select **Generate a SCIM token**.
1. For configuration of your identity provider, save the:
   - Token from the **Your SCIM token** field.
   - URL from the **SCIM API endpoint URL** field.

## Configure an identity provider

You can configure the following as an identity provider:

- [Okta](#configure-okta).
- [Microsoft Entra ID (formerly Azure Active Directory)](#configure-microsoft-entra-id-formerly-azure-active-directory)

{{< alert type="note" >}}

Other identity providers can work with GitLab but they have not been tested and are not supported. You should contact the provider for support. GitLab support can assist by reviewing related log entries.

{{< /alert >}}

### Configure Okta

The SAML application created during [single sign-on](../../integration/saml.md) set up for Okta must be set up for SCIM.

Prerequisites:

- You must use the [Okta Lifecycle Management](https://www.okta.com/products/lifecycle-management/) product. This
  product tier is required to use SCIM on Okta.
- [GitLab is configured](#configure-gitlab) for SCIM.
- The SAML application for [Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/) set up as
  described in the [Okta setup notes](../../integration/saml.md#set-up-okta).
- Your Okta SAML setup matches the [configuration steps](_index.md), especially the NameID configuration.

To configure Okta for SCIM:

1. Sign in to Okta.
1. In the upper-right corner, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**. The button is not visible from the **Admin** area.
1. In the **Application** tab, select **Browse App Catalog**.
1. Find and select the **GitLab** application.
1. On the GitLab application overview page, select **Add Integration**.
1. Under **Application Visibility**, select both checkboxes. The GitLab application does not support SAML
   authentication so the icon should not be shown to users.
1. Select **Done** to finish adding the application.
1. In the **Provisioning** tab, select **Configure API integration**.
1. Select **Enable API integration**.
   - For **Base URL**, paste the URL you copied from **SCIM API endpoint URL** on the GitLab SCIM configuration page.
   - For **API Token**, paste the SCIM token you copied from **Your SCIM token** on the GitLab SCIM
     configuration page.
1. To verify the configuration, select **Test API Credentials**.
1. Select **Save**.
1. After saving the API integration details, new settings tabs appear on the left. Select **To App**.
1. Select **Edit**.
1. Select the **Enable** checkbox for both **Create Users** and **Deactivate Users**.
1. Select **Save**.
1. Assign users in the **Assignments** tab. Assigned users are created and managed in your GitLab group.

### Configure Microsoft Entra ID (formerly Azure Active Directory)

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143146) to Microsoft Entra ID terminology in GitLab 16.10.

{{< /history >}}

Prerequisites:

- [GitLab is configured](#configure-gitlab) for SCIM.
- The [SAML application for Microsoft Entra ID is set up](../../integration/saml.md#set-up-microsoft-entra-id).

The SAML application created during [single sign-on](../../integration/saml.md) set up for
[Azure Active Directory](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/view-applications-portal)
must be set up for SCIM. For an example, see [example configuration](../../user/group/saml_sso/example_saml_config.md#scim-mapping).

{{< alert type="note" >}}

You must configure SCIM provisioning exactly as detailed in the following instructions. If misconfigured, you will encounter issues with user provisioning
and sign in, which require a lot of effort to resolve. If you have any trouble or questions with any step, contact GitLab support.

{{< /alert >}}

To configure Microsoft Entra ID, you configure:

- Microsoft Entra ID for SCIM.
- Settings.
- Mappings, including attribute mappings.

#### Configure Microsoft Entra ID for SCIM

1. In your app, go to the **Provisioning** tab and select **Get started**.
1. Set the **Provisioning Mode** to **Automatic**.
1. Complete the **Admin Credentials** using the value of:
   - **SCIM API endpoint URL** in GitLab for the **Tenant URL** field.
   - **Your SCIM token** in GitLab for the **Secret Token** field.
1. Select **Test Connection**.

   If the test is successful, save your configuration.

   If the test is unsuccessful, see
   [troubleshooting](../../user/group/saml_sso/troubleshooting.md) to try to resolve this.
1. Select **Save**.

After saving, the **Mappings** and **Settings** sections appear.

#### Configure mappings

Under the **Mappings** section, first provision the groups:

1. Select **Provision Microsoft Entra ID Groups**.
1. On the Attribute Mapping page, turn off the **Enabled** toggle.

   SCIM group provisioning is not supported in GitLab. Leaving group provisioning enabled does not break the SCIM user provisioning, but it causes errors in the
   Entra ID SCIM provisioning log that might be confusing and misleading.

   {{< alert type="note" >}}

   Even when **Provision Microsoft Entra ID Groups** is disabled, the mappings section might display **Enabled: Yes**. This behavior is a display bug that you can safely ignore.

   {{< /alert >}}

1. Select **Save**.

Next, provision the users:

1. Select **Provision Microsoft Entra ID Users**.
1. Ensure that the **Enabled** toggle is set to **Yes**.
1. Ensure that all **Target Object Actions** are enabled.
1. Under **Attribute Mappings**, configure mappings to match
   the [configured attribute mappings](#configure-attribute-mappings):
   1. Optional. In the **customappsso Attribute** column, find `externalId` and delete it.
   1. Edit the first attribute to have a:
      - **source attribute** of `objectId`.
      - **target attribute** of `externalId`.
      - **matching precedence** of `1`.
   1. Update the existing **customappsso** attributes to match the
      [configured attribute mappings](#configure-attribute-mappings).
   1. Delete any additional attributes that are not present in the [attribute mappings table](#configure-attribute-mappings). They do not cause problems if they are
      not deleted, but GitLab does not consume the attributes.
1. Under the mapping list, select the **Show advanced options** checkbox.
1. Select the **Edit attribute list for customappsso** link.
1. Ensure the `id` is the primary and required field, and `externalId` is also required.
1. Select **Save**, which returns you to the Attribute Mapping configuration page.
1. To close the **Attribute Mapping** configuration page, select `X` in the upper-right corner.

##### Configure attribute mappings

{{< alert type="note" >}}

While Microsoft transitions from Azure Active Directory to Entra ID naming schemes, you might notice inconsistencies in
your user interface. If you're having trouble, you can view an older version of this document or contact GitLab Support.

{{< /alert >}}

While [configuring Entra ID for SCIM](#configure-microsoft-entra-id-formerly-azure-active-directory), you configure
attribute mappings. For an example, see [example configuration](../../user/group/saml_sso/example_saml_config.md#scim-mapping).

The following table provides attribute mappings that are required for GitLab.

| Source attribute                                                           | Target attribute               | Matching precedence |
|:---------------------------------------------------------------------------|:-------------------------------|:--------------------|
| `objectId`                                                                 | `externalId`                   | 1                   |
| `userPrincipalName` OR `mail` <sup>1</sup>                                 | `emails[type eq "work"].value` |                     |
| `mailNickname`                                                    | `userName`                     |                     |
| `displayName` OR `Join(" ", [givenName], [surname])` <sup>2</sup>          | `name.formatted`               |                     |
| `Switch([IsSoftDeleted], , "False", "True", "True", "False")` <sup>3</sup> | `active`                       |                     |

**Footnotes**:

1. Use `mail` as a source attribute when the `userPrincipalName` is not an email address or is not deliverable.
1. Use the `Join` expression if your `displayName` does not match the format of `Firstname Lastname`.
1. This is an expression mapping type, not a direct mapping. Select **Expression** in the **Mapping type** dropdown list.

Each attribute mapping has:

- A **customappsso Attribute**, which corresponds to **target attribute**.
- A **Microsoft Entra ID Attribute**, which corresponds to **source attribute**.
- A matching precedence.

For each attribute:

1. Edit the existing attribute or add a new attribute.
1. Select the required source and target attribute mappings from the dropdown lists.
1. Select **Ok**.
1. Select **Save**.

If your SAML configuration differs from [the recommended SAML settings](../../integration/saml.md), select the mapping
attributes and modify them accordingly. The source attribute that you map to the `externalId`
target attribute must match the attribute used for the SAML `NameID`.

If a mapping is not listed in the table, use the Microsoft Entra ID defaults. For a list of required attributes,
refer to the [internal instance SCIM API](../../development/internal_api/_index.md#instance-scim-api) documentation.

#### Configure settings

Under the **Settings** section:

1. Optional. If desired, select the **Send an email notification when a failure occurs** checkbox.
1. Optional. If desired, select the **Prevent accidental deletion** checkbox.
1. If necessary, select **Save** to ensure all changes have been saved.

After you have configured the mappings and the settings, return to the app overview page and select **Start provisioning** to start automatic SCIM provisioning of users in GitLab.

{{< alert type="warning" >}}

Once synchronized, changing the field mapped to `id` and `externalId` might cause errors. These include
provisioning errors, duplicate users, and might prevent existing users from accessing the GitLab group.

{{< /alert >}}

## Remove access

Removing or deactivating a user on the identity provider blocks the user on
the GitLab instance, while the SCIM identity remains linked to the GitLab user.

To update the user SCIM identity, use the
[internal GitLab SCIM API](../../development/internal_api/_index.md#update-a-single-scim-provisioned-user-1).

### Reactivate access

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/379149) in GitLab 16.0 [with a flag](../feature_flags/_index.md) named `skip_saml_identity_destroy_during_scim_deprovision`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121226) in GitLab 16.4. Feature flag `skip_saml_identity_destroy_during_scim_deprovision` removed.

{{< /history >}}

After a user is removed or deactivated through SCIM, you can reactivate that user by
adding them to the SCIM identity provider.

After the identity provider performs a sync based on its configured schedule,
the user's SCIM identity is reactivated and their GitLab instance access is restored.

## Group synchronization with SCIM

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15990) in GitLab 18.0 [with a flag](../../administration/feature_flags/_index.md) named `self_managed_scim_group_sync`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/553662) by default in GitLab 18.2.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/554271) in GitLab 18.6. Feature flag `self_managed_scim_group_sync` removed.

{{< /history >}}

In addition to user provisioning, you can use SCIM to synchronize group memberships between your identity provider and GitLab.
With this method you can automatically add and remove users from GitLab groups based on their group memberships in your identity provider.

Prerequisites:

- [SAML group links](../../user/group/saml_sso/group_sync.md#configure-saml-group-links) must be configured first.
- The SAML group names in your identity provider must match the SAML group names configured in GitLab.

### Configure group synchronization in your identity provider

For detailed instructions on configuring group synchronization in your identity provider, refer to the provider's documentation. Examples below:

- [Okta Groups API](https://developer.okta.com/docs/reference/api/groups/)
- [Microsoft Entra ID (Azure AD) SCIM Groups](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/use-scim-to-provision-users-and-groups)

{{< alert type="warning" >}}

When multiple SAML group links map to the same GitLab group, users are assigned the highest role across all mapping group links. Users removed from an IdP group stay in a GitLab group if they belong to another SAML group linked to it.

{{< /alert >}}

## Troubleshooting

See our [troubleshooting SCIM guide](../../user/group/saml_sso/troubleshooting_scim.md).
