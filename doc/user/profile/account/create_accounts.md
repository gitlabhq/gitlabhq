---
type: reference
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Creating users **(FREE SELF)**

You can create users:

- [Manually through the sign-in page](#create-users-on-sign-in-page).
- [Manually in the Admin Area](#create-users-in-admin-area).
- [Manually using the API](../../../api/users.md).
- [Automatically through user authentication integrations](#create-users-through-authentication-integrations).

## Create users on sign-in page

Prerequisites:

- [Sign-up enabled](../../admin_area/settings/sign_up_restrictions.md)

Users can create their own accounts by either:

- Selecting the **Register now** link on the sign-in page.
- Navigating to your GitLab instance's sign-up link. For example: `https://gitlab.example.com/users/sign_up`.

## Create users in Admin Area

Prerequisites:

- You must have administrator access for the instance.

To create a user manually:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users** (`/admin/users`).
1. Select **New user**.
1. Complete the fields.
1. Select **Create user**.

## Create users through authentication integrations

Users are:

- Automatically created upon first sign in with the [LDAP integration](../../../administration/auth/ldap/index.md).
- Created when first signing in using an [OmniAuth provider](../../../integration/omniauth.md) if
  the `allow_single_sign_on` setting is present.
- Created when first signing with [Group SAML](../../group/saml_sso/index.md).
- Automatically created by [SCIM](../../group/saml_sso/scim_setup.md) when the user is created in
  the identity provider.

## Create users through the Rails console

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

To create a user through the Rails console:

1. [Start a Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Run the following commands:

   ```ruby
   u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
   u.skip_confirmation! # Use it only if you wish user to be automatically confirmed. If skipped, user receives confirmation e-mail
   u.save!
   ```
