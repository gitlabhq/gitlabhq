---
type: reference, howto
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure SCIM for self-managed GitLab instances **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8902) in GitLab 15.8.

You can use the open standard System for Cross-domain Identity Management (SCIM) to automatically:

- Create users.
- Remove users (deactivate SCIM identity).

The [internal GitLab SCIM API](../../../development/internal_api/index.md#instance-scim-api) implements part of [the RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).

If you are a GitLab.com user, see [configuring SCIM for GitLab.com groups](../../../user/group/saml_sso/scim_setup.md).

## Configure GitLab

Prerequisites:

- Configure [SAML single sign-on](../../../integration/saml.md).

To configure GitLab SCIM:

1. On the top bar, select **Main menu > Admin area**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **SCIM Token** section and select **Generate a SCIM token**.
1. For configuration of your identity provider, save the:
    - Token from the **Your SCIM token** field.
    - URL from the **SCIM API endpoint URL** field.
