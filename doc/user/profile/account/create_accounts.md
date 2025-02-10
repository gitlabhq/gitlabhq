---
stage: Fulfillment
group: Provision
description: Create user accounts in GitLab.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Create users
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

You can create user accounts in GitLab in different ways:

- Direct users to create their own account.
- Create accounts for other users manually.
- Configure authentication integrations.
- Create users through the Rails console.

If you want to automate user creation, you should use the [users API endpoint](../../../api/users.md#create-a-user).

## Create users on sign-in page

By default, any user visiting your GitLab instance can register for an account.
If you have previously [disabled this setting](../../../administration/settings/sign_up_restrictions.md#disable-new-sign-ups), you must turn it back on.

Users can create their own accounts by either:

- Selecting the **Register now** link on the sign-in page.
- Navigating to your GitLab instance's sign-up link (for example: `https://gitlab.example.com/users/sign_up`).

## Create users in Admin area

Prerequisites:

- You must have administrator access to the instance.

To create a user manually:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Select **New user**.
1. Complete the required fields, such as name, username, and email.
1. Select **Create user**.

A reset link is sent to the user's email, and they are required to set their password when they first sign in.

### Set user password

To set a user's password without relying on the email confirmation, after you create a user:

1. Select the user.
1. Select **Edit**.
1. Complete the password and password confirmation fields.
1. Select **Save changes**.

The user can now sign in with the new username and password,
and they are required to change the password you set up for them.

## Create users through authentication integrations

GitLab can automatically create user accounts through authentication integrations.
Users are created when they:

- Sign in for the first time with:
  - [LDAP](../../../administration/auth/ldap/_index.md)
  - [Group SAML](../../group/saml_sso/_index.md)
  - An [OmniAuth provider](../../../integration/omniauth.md) that has the setting `allow_single_sign_on` turned on
- Are provisioned through [SCIM](../../group/saml_sso/scim_setup.md) in the identity provider.

## Create users through the Rails console

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions.
Always run commands in a test environment first and have a backup instance ready to restore.

To create a user through the Rails console:

1. [Start a Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Run the command according to your GitLab version:

  ::Tabs

  :::TabTitle 16.10 and earlier

  ```ruby
  u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
  # u.assign_personal_namespace
  u.skip_confirmation! # Use only if you want the user to be automatically confirmed. If you do not use this, the user receives a confirmation email.
  u.save!
  ```

  :::TabTitle 16.11 through 17.6

  ```ruby
  u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
  u.assign_personal_namespace(Organizations::Organization.default_organization)
  u.skip_confirmation! # Use only if you want the user to be automatically confirmed. If you do not use this, the user receives a confirmation email.
  u.save!
  ```

  :::TabTitle 17.7 and later

  ```ruby
  u = Users::CreateService.new(nil,
    username: 'test_user',
    email: 'test@example.com',
    name: 'Test User',
    password: '123password',
    password_confirmation: '123password',
    organization_id: Organizations::Organization.first.id,
    skip_confirmation: true
  ).execute
  ```

  ::EndTabs
