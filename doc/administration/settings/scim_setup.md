---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure SCIM for self-managed GitLab instances

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8902) in GitLab 15.8.

You can use the open standard System for Cross-domain Identity Management (SCIM) to automatically:

- Create users.
- Block users.
- Re-add users (reactivate SCIM identity).

The [internal GitLab SCIM API](../../development/internal_api/index.md#instance-scim-api) implements part of [the RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).

If you are a GitLab.com user, see [configuring SCIM for GitLab.com groups](../../user/group/saml_sso/scim_setup.md).

## Configure GitLab

Prerequisites:

- Configure [SAML single sign-on](../../integration/saml.md).

To configure GitLab SCIM:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **SCIM Token** section and select **Generate a SCIM token**.
1. For configuration of your identity provider, save the:
    - Token from the **Your SCIM token** field.
    - URL from the **SCIM API endpoint URL** field.

## Configure an identity provider

You can configure the following as an identity provider:

- [Okta](#configure-okta).

NOTE:
Other identity providers can work with GitLab but they have not been tested and are not supported. You should contact the provider for support. GitLab support can assist by reviewing related log entries.

### Configure Okta

The SAML application created during [single sign-on](index.md) set up for Okta must be set up for SCIM.

Prerequisites:

- You must use the [Okta Lifecycle Management](https://www.okta.com/products/lifecycle-management/) product. This
  product tier is required to use SCIM on Okta.
- [GitLab is configured](#configure-gitlab) for SCIM.
- The SAML application for [Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/) set up as
  described in the [Okta setup notes](../../integration/saml.md#set-up-okta).
- Your Okta SAML setup matches the [configuration steps](index.md), especially the NameID configuration.

To configure Okta for SCIM:

1. Sign in to Okta.
1. In the upper-right corner, select **Admin**. The button is not visible from the **Admin** area.
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

## Remove access

Removing or deactivating a user on the identity provider blocks the user on
the GitLab instance, while the SCIM identity remains linked to the GitLab user.

To update the user SCIM identity, use the
[internal GitLab SCIM API](../../development/internal_api/index.md#update-a-single-scim-provisioned-user-1).

### Reactivate access

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/379149) in GitLab 16.0 [with a flag](../feature_flags.md) named `skip_saml_identity_destroy_during_scim_deprovision`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121226) in GitLab 16.4. Feature flag `skip_saml_identity_destroy_during_scim_deprovision` removed.

After a user is removed or deactivated through SCIM, you can reactivate that user by
adding them to the SCIM identity provider.

After the identity provider performs a sync based on its configured schedule,
the user's SCIM identity is reactivated and their GitLab instance access is restored.

## Troubleshooting

See our [troubleshooting SCIM guide](../../user/group/saml_sso/troubleshooting_scim.md).
