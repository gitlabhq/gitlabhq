---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: New user account restrictions
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can enforce the following restrictions on new user accounts:

- Prevent account creation.
- Require administrator approval for new accounts.
- Require user email confirmation.
- Allow or deny new accounts that use specific email domains.

## Prerequisites

You must have administrator access.

## Disable new user account creation

By default, any user visiting your GitLab domain can create an account. For customers running
public-facing GitLab instances, we highly recommend that you consider disabling new accounts if
you do not expect public users to create accounts. For GitLab Dedicated, new account creation is
prevented by default when your instance is provisioned.

To prevent new account creation:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. Clear the **Allow new user accounts** checkbox, then select **Save changes**.

You can also prevent new user accounts with the [Rails console](../operations/rails_console.md) by running the following command:

```ruby
::Gitlab::CurrentSettings.update!(signup_enabled: false)
```

## Require administrator approval for new user accounts

This setting is enabled by default for new GitLab instances.
When this setting is enabled, any user visiting your GitLab domain and signing up for a new account using the registration form
must be explicitly approved by an
administrator before they can start using their account. It is only applicable if user accounts are allowed.

To require administrator approval for new user accounts:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. Select the **Require admin approval for new user accounts** checkbox, then select **Save changes**.

If an administrator disables this setting, the users in pending approval state are
automatically approved in a background job.

> [!note]
> This setting doesn't apply to LDAP or OmniAuth users. To enforce approvals for new users
> signing up using OmniAuth or LDAP, set `block_auto_created_users` to `true` in the
> [OmniAuth configuration](../../integration/omniauth.md#configure-common-settings) or
> [LDAP configuration](../auth/ldap/_index.md#basic-configuration-settings).
> A [user cap](../../subscriptions/manage_seats.md#user-cap) can also be used to enforce approvals for new users.

## Confirm user email

You can send confirmation emails upon account creation and require that users confirm
their email address before they are allowed to sign in.

To enforce confirmation of the email address used for new accounts:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. Under **Email confirmation settings**, select **Hard**.

The following settings are available:

- **Hard** - Send a confirmation email during account creation. New users must confirm their email address before they can sign in.
- **Soft** - Send a confirmation email during account creation. New users can sign in immediately, but must confirm their email in three days. After three days, the user is not able to sign in until they confirm their email.
- **Off** - New users can sign in without confirming their email address.

## Turn on restricted access

Prerequisites:

- You must be an administrator.
- The group or one of its subgroups or projects must not be shared externally.

To turn on restricted access:

1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. Under **Seat control**, select **Restricted access**.

## Set a user cap

Prerequisites:

- You must be an administrator.

To set a user cap:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. In the **User cap** field, enter a number or leave blank for unlimited.
1. Select **Save changes**.

## Remove the user cap

Remove the user cap so that the number of new users who can create accounts without
administrator approval is not restricted.

After you remove the user cap, users pending approval are automatically approved.

Prerequisites:

- You must be an administrator.

To remove the user cap:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. Remove the number from **User cap**.
1. Select **Save changes**.

## Modify password complexity requirements

By default, user passwords have a limited number of [requirements](../../user/profile/user_passwords.md#password-requirements).
You can modify the requirements to increase the minimum length or require specific character types.

Changing the password requirements does not affect existing user passwords.
Modified complexity requirements are enforced only in these situations:

- When a new user creates an account.
- When an existing user resets their password.

To modify password complexity requirements:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. Modify the complexity requirements:

   | Setting | Description |
   |---------|-------------|
   | **Minimum password length** | Sets the minimum number of characters required. Cannot be less than 8 characters or more than 128 characters. |
   | **Require numbers** | Requires passwords to contain at least one number (0-9). Premium and Ultimate only. |
   | **Require uppercase letters** | Requires passwords to contain at least one uppercase letter (A-Z). Premium and Ultimate only. |
   | **Require lowercase letters** | Requires passwords to contain at least one lowercase letter (a-z). Premium and Ultimate only. |
   | **Require symbols** | Requires passwords to contain at least one symbol. Premium and Ultimate only. |

1. Select **Save changes**.

## Allow or deny account creation by using specific email domains

You can specify an inclusive or exclusive list of email domains that can be used for new user accounts.

These restrictions are only applied during new account creation by an external user. An administrator can add a
user through the administrator panel with a disallowed domain. The users can also change their
email addresses to disallowed domains after they create an account.

### Allowlist email domains

You can restrict users to creating user accounts with email addresses that match the given
domains list.

### Denylist email domains

You can block users from signing up when using an email addresses of specific domains. This can
reduce the risk of malicious users creating spam accounts with disposable email addresses.

### Create email domain allowlist or denylist

To create an email domain allowlist or denylist:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. For the allowlist, you must enter the list manually. For the denylist, you can enter the list
   manually or upload a `.txt` file that contains list entries.

   Both the allowlist and denylist accept wildcards. For example, you can use
   `*.company.com` to accept every `company.com` subdomain, or `*.io` to block all
   domains ending in `.io`. Domains must be separated by a whitespace,
   semicolon, comma, or a new line.

   ![The domain denylist settings with the options to upload a file or enter the denylist manually.](img/domain_denylist_v14_1.png)

## Set up LDAP user filter

You can limit GitLab access to a subset of the LDAP users on your LDAP server.

See the [documentation on setting up an LDAP user filter](../auth/ldap/_index.md#set-up-ldap-user-filter) for more information.

## Turn on administrator approval for role promotions

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/433166) in GitLab 16.9 [with a feature flag](../feature_flags/_index.md) named `member_promotion_management`.
- Feature flag `member_promotion_management` [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167757/) from `wip` to `beta` and enabled by default in GitLab 17.5.
- Feature flag `member_promotion_management` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187888) in GitLab 18.0.

{{< /history >}}

To prevent existing users from being promoted into a billable role in a project or group,
turn on administrator approval for role promotions. You can then approve or reject promotion requests
that are [pending administrator approval](../moderate_users.md#view-users-pending-role-promotion).

- If an administrator adds a user to a group or project:
  - If the new user role is [billable](../../subscriptions/manage_seats.md#billable-users),
    all other membership requests for that user are automatically approved.
  - If the new user role is not billable, other requests for that user remain pending until administrator approval.
- If a user who isn't an administrator adds a user to a group or project:
  - If the user does not have any billable role in any group or project, and is added or promoted to a billable role,
    their request remains [pending until administrator approval](../moderate_users.md#view-users-pending-role-promotion).
  - If the user already has a billable role, administrator approval is not required.

Prerequisites:

- You must be an administrator.

To turn on approvals for role promotions:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **New user account restrictions**.
1. In the **Seat control** section, select **Approve role promotions**.

> [!note]
> This approval requirement does not apply to memberships granted by
> [LDAP synchronization](../auth/ldap/ldap_synchronization.md)
> or [SAML group links](../../user/group/saml_sso/group_sync.md). Users who receive a role promotion
> through LDAP or SAML do not require administrator approval, regardless of whether they previously
> had a billable role.
