---
type: reference
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Creating users **(FREE SELF)**

You can create users:

- Manually through the sign in page or Admin Area.
- Automatically through user authentication integrations.

## Create users on sign in page

If you have [sign-up enabled](../../admin_area/settings/sign_up_restrictions.md), users can create their own accounts by selecting "Register now" on the sign-in page, or navigate to `https://gitlab.example.com/users/sign_up`.

![Register Tab](img/register_v13_6.png)

## Create users in Admin Area

As an admin user, you can manually create users by:

1. Navigating to **Admin Area > Overview > Users** (`/admin/users` page).
1. Selecting the **New User** button.

You can also [create users through the API](../../../api/users.md) as an admin.

![Admin User Button](img/admin_user_button.png)

![Admin User Form](img/admin_user_form.png)

## Create users through authentication integrations

Users will be:

- Automatically created upon first sign in with the [LDAP integration](../../../administration/auth/ldap/index.md).
- Created when first signing in via an [OmniAuth provider](../../../integration/omniauth.md) if the `allow_single_sign_on` setting is present.
- Created when first signing with [Group SAML](../../group/saml_sso/index.md)
- Automatically created by [SCIM](../../group/saml_sso/scim_setup.md) when the user is created in the identity provider.
