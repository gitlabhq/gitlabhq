---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Create user accounts in GitLab.
title: Create users
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

User accounts form the foundation of GitLab collaboration. Every person who needs access to your GitLab
projects requires an account. User accounts control access permissions, track contributions, and maintain
security across your instance.

You can create user accounts in GitLab in different ways:

- Self-registration for teams who value autonomy
- Admin-driven creation for controlled onboarding
- Authentication integration for enterprise environments
- Console access for automation and bulk operations

You can also use the [users API endpoint](../../../api/users.md#create-a-user) to automatically create users.

Choose the right method based on your organization's size, security requirements, and workflows.

## Create a user on the sign-in page

By default, any user visiting your GitLab instance can register for an account.
If you have previously [disabled this setting](../../../administration/settings/sign_up_restrictions.md#disable-new-sign-ups), you must turn it back on.

Users can create their own accounts by either:

- Selecting the **Register now** link on the sign-in page.
- Navigating to your GitLab instance's sign-up link (for example: `https://gitlab.example.com/users/sign_up`).

## Create a user in the Admin area

Prerequisites:

- You must be an administrator for the instance.

To create a user:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Overview** > **Users**.
1. Select **New user**.
1. In the **Account** section, enter the required account information.
1. Optional. In the **Access** section, configure any project limits or user type settings.
1. Select **Create user**.

GitLab sends an email to the user with a sign-in link, and the user must create a password when
they first sign in. You can also directly [set a password](../../../security/reset_user_password.md#use-the-ui)
for the user.

## Create a user with an authentication integration

GitLab can automatically create user accounts through authentication integrations.
Users are created when they:

- Are provisioned through [SCIM](../../group/saml_sso/scim_setup.md) in the identity provider.
- Sign in for the first time with:
  - [LDAP](../../../administration/auth/ldap/_index.md)
  - [Group SAML](../../group/saml_sso/_index.md)
  - An [OmniAuth provider](../../../integration/omniauth.md) that has the setting `allow_single_sign_on` turned on

## Create a user through the Rails console

{{< alert type="warning" >}}

Commands that change data can cause damage if not run correctly or under the right conditions.
Always run commands in a test environment first and have a backup instance ready to restore.

{{< /alert >}}

To create a user through the Rails console:

1. Start a [Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Run the command according to your GitLab version:

  {{< tabs >}}

  {{< tab title="16.10 and earlier" >}}

  ```ruby
  u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
  # u.assign_personal_namespace
  u.skip_confirmation! # Use only if you want the user to be automatically confirmed. If you do not use this, the user receives a confirmation email.
  u.save!
  ```

  {{< /tab >}}

  {{< tab title="16.11 through 17.6" >}}

  ```ruby
  u = User.new(username: 'test_user', email: 'test@example.com', name: 'Test User', password: 'password', password_confirmation: 'password')
  u.assign_personal_namespace(Organizations::Organization.default_organization)
  u.skip_confirmation! # Use only if you want the user to be automatically confirmed. If you do not use this, the user receives a confirmation email.
  u.save!
  ```

  {{< /tab >}}

  {{< tab title="17.7 and later" >}}

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

  {{< /tab >}}

  {{< /tabs >}}
