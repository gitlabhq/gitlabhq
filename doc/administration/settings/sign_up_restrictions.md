---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Sign-up restrictions

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

You can enforce the following restrictions on sign ups:

- Disable new sign ups.
- Require administrator approval for new sign ups.
- Require user email confirmation.
- Allow or deny sign ups using specific email domains.

## Disable new sign ups

By default, any user visiting your GitLab domain can sign up for an account. For customers running
public-facing GitLab instances, we **highly** recommend that you consider disabling new sign ups if
you do not expect public users to sign up for an account.

To disable sign ups:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Clear the **Sign-up enabled** checkbox, then select **Save changes**.

You can also disable new sign ups with the [Rails console](../operations/rails_console.md) by running the following command:

```ruby
::Gitlab::CurrentSettings.update!(signup_enabled: false)
```

## Require administrator approval for new sign ups

This setting is enabled by default for new GitLab instances.
When this setting is enabled, any user visiting your GitLab domain and signing up for a new account using the registration form
must be explicitly [approved](../../administration/moderate_users.md#approve-or-reject-a-user-sign-up) by an
administrator before they can start using their account. It is only applicable if sign ups are enabled.

To require administrator approval for new sign ups:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Select the **Require admin approval for new sign-ups** checkbox, then select **Save changes**.

If an administrator disables this setting, the users in pending approval state are
automatically approved in a background job.

NOTE:
This setting doesn't apply to LDAP or OmniAuth users. To enforce approvals for new users
signing up using OmniAuth or LDAP, set `block_auto_created_users` to `true` in the
[OmniAuth configuration](../../integration/omniauth.md#configure-common-settings) or
[LDAP configuration](../auth/ldap/index.md#basic-configuration-settings).
A [user cap](#user-cap) can also be used to enforce approvals for new users.

## Confirm user email

> - Soft email confirmation [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107302/diffs) from a feature flag to an application setting in GitLab 15.9.

You can send confirmation emails during sign up and require that users confirm
their email address before they are allowed to sign in.

To enforce confirmation of the email address used for new sign ups:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Under **Email confirmation settings**, select **Hard**.

The following settings are available:

- **Hard** - Send a confirmation email during sign up. New users must confirm their email address before they can sign in.
- **Soft** - Send a confirmation email during sign up. New users can sign in immediately, but must confirm their email in three days. After three days, the user is not able to sign in until they confirm their email.
- **Off** - New users can sign up without confirming their email address.

## User cap

The user cap is the maximum number of billable users who can sign up or be added to a subscription
without administrator approval. After the user cap is reached, users who sign up or are
added must be [approved](../../administration/moderate_users.md#approve-or-reject-a-user-sign-up)
by an administrator. Users can use their account only after they have been approved by an administrator.

If an administrator increases or removes the user cap, users pending approval are automatically approved.

[View how to set up a user cap for groups](../../user/group/manage.md#user-cap-for-groups).

NOTE:
For instances that use LDAP or OmniAuth, when [administrator approval for new sign-ups](#require-administrator-approval-for-new-sign-ups)
is enabled or disabled, downtime might occur due to changes in the Rails configuration.
You can set a user cap to enforce approvals for new users. To ensure the user cap applies immediately, set the cap to a value below the current number of billable users (for example, `1`).

### Set a user cap

Set a user cap to restrict the number of users who can sign up without administrator approval.

The number of [billable users](../../subscriptions/self_managed/index.md#billable-users) is updated once a day.
The user cap might apply only retrospectively after the cap has already been exceeded.
To ensure the cap is enabled immediately, set the cap to a value below the current number of
billable users (for example, `1`).

Prerequisites:

- You must be an administrator.

To set a user cap:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Enter a number in **User cap**.
1. Select **Save changes**.

### Remove the user cap

Remove the user cap so that the number of new users who can sign up without
administrator approval is not restricted.

After you remove the user cap, users pending approval are automatically approved.

Prerequisites:

- You must be an administrator.

To remove the user cap:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Remove the number from **User cap**.
1. Select **Save changes**.

## Turn on restricted access

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com
**Status:** Beta

> -Introduced in GitLab 17.5.

This feature is in [beta](../../policy/experiment-beta-support.md).

Use restricted access to prevent overage fees. Overage fees occur when you exceed the number of seats
in your subscription, and must be paid at the next [quarterly reconciliation](../../subscriptions/quarterly_reconciliation.md).

When you turn on restricted access, groups cannot add new billable users when there are no seats
left in the subscription.

Prerequisites:

- You must have the Owner role for the group.
- The group or one of its subgroups or projects must not be shared externally.

To turn on restricted access:

1. On the left sidebar, select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Seat controls**, select **Restricted access**.

### Known issues

When you turn on restricted access, the following known issues might occur and result in overages:

- The number of seats can still be exceeded if:
  - You promote a user that is a member of the root group and has the Minimal Access role to a higher role.
  - For Ultimate, you promote a user with the Guest role to a higher role.
  - You use SAML or SCIM to add new members, and have exceeded the number of seats in the subscription.
  - Multiple users with the Owner role add members simultaneously.
  - New billable members delay accepting an invitation.
  - You change from using the user cap to restricted access, and have members pending approval
    from before you changed to restricted access. In this case, those members remain in a pending state. If
    pending members are approved while using restricted access, you might exceed the number of seats in your subscription.
- If you renew your subscription through the GitLab Sales Team for less users than your current
subscription, you will incur an overage fee. To avoid this fee, remove additional users before your
renewal starts. For example:
  - You have 20 users.
  - You renew your subscription for 15 users.
  - You will be charged overages for the five additional users.

## Minimum password length limit

You can [change](../../security/password_length_limits.md#modify-minimum-password-length)
the minimum number of characters a user must have in their password using the GitLab UI.

### Password complexity requirements

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354965) in GitLab 15.2.

By default, the only requirement for user passwords is [minimum password length](#minimum-password-length-limit).
You can add additional complexity requirements. Changes to password complexity requirements apply to new passwords:

- For new users that sign up.
- For existing users that reset their password.

Existing passwords are unaffected. To change password complexity requirements:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Under **Minimum password length (number of characters)**, select additional password complexity requirements. You can require numbers, uppercase letters, lowercase letters,
   and symbols.
1. Select **Save changes**.

## Allow or deny sign ups using specific email domains

You can specify an inclusive or exclusive list of email domains which can be used for user sign up.

These restrictions are only applied during sign up from an external user. An administrator can add a
user through the administrator panel with a disallowed domain. The users can also change their
email addresses to disallowed domains after sign up.

### Allowlist email domains

You can restrict users only to sign up using email addresses matching the given
domains list.

### Denylist email domains

You can block users from signing up when using an email addresses of specific domains. This can
reduce the risk of malicious users creating spam accounts with disposable email addresses.

### Create email domain allowlist or denylist

To create an email domain allowlist or denylist:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. For the allowlist, you must enter the list manually. For the denylist, you can enter the list
   manually or upload a `.txt` file that contains list entries.

   Both the allowlist and denylist accept wildcards. For example, you can use
`*.company.com` to accept every `company.com` subdomain, or `*.io` to block all
domains ending in `.io`. Domains must be separated by a whitespace,
semicolon, comma, or a new line.

   ![Domain Denylist](img/domain_denylist_v14_1.png)

## Set up LDAP user filter

You can limit GitLab access to a subset of the LDAP users on your LDAP server.

See the [documentation on setting up an LDAP user filter](../auth/ldap/index.md#set-up-ldap-user-filter) for more information.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
