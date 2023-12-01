---
type: reference, howto
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure SCIM for self-managed GitLab instances **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8902) in GitLab 15.8.

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

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand the **SCIM Token** section and select **Generate a SCIM token**.
1. For configuration of your identity provider, save the:
    - Token from the **Your SCIM token** field.
    - URL from the **SCIM API endpoint URL** field.

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
