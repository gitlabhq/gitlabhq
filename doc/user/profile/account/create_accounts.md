---
stage: Govern
group: Authentication
description: Passwords, user moderation, broadcast messages.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Creating users

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

You can create users:

- [Manually through the sign-in page](#create-users-on-sign-in-page).
- [Manually in the Admin area](#create-users-in-admin-area).
- [Manually using the API](../../../api/users.md).
- [Automatically through user authentication integrations](#create-users-through-authentication-integrations).

## Create users on sign-in page

Prerequisites:

- [Sign-up must be enabled](../../../administration/settings/sign_up_restrictions.md).

Users can create their own accounts by either:

- Selecting the **Register now** link on the sign-in page.
- Navigating to your GitLab instance's sign-up link. For example: `https://gitlab.example.com/users/sign_up`.

## Create users in Admin area

Prerequisites:

- You must have administrator access to the instance.

To create a user manually:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Overview > Users**.
1. Select **New user**.
1. Complete the required fields, such as name, username, and email.
1. Select **Create user**.

A reset link is sent to the user's email and they are forced to set their
password on first sign in.

To set a user's password without relying on the email confirmation, after you
create a user following the previous steps:

1. Select the user.
1. Select **Edit**.
1. Complete the password and password confirmation fields.
1. Select **Save changes**.

The user can now sign in with the new username and password, and they are asked
to change the password you set up for them.

NOTE:
If you wanted to create a test user, you could follow the previous steps
by providing a fake email and using the same password in the final confirmation.

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
   u.assign_personal_namespace(Organizations::Organization.default_organization)
   u.skip_confirmation! # Use it only if you wish user to be automatically confirmed. If skipped, user receives confirmation e-mail
   u.save!
   ```
