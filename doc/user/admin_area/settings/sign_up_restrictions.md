---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Sign-up restrictions **(FREE SELF)**

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

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**, and expand **Sign-up restrictions**.
1. Clear the **Sign-up enabled** checkbox, then select **Save changes**.

## Require administrator approval for new sign ups

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4491) in GitLab 13.5.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/267568) in GitLab 13.6.

When this setting is enabled, any user visiting your GitLab domain and signing up for a new account
must be explicitly [approved](../moderate_users.md#approve-or-reject-a-user-sign-up) by an
administrator before they can start using their account. In GitLab 13.6 and later, this setting is
enabled by default for new GitLab instances. It is only applicable if sign ups are enabled.

To require administrator approval for new sign ups:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**, and expand **Sign-up restrictions**.
1. Select the **Require admin approval for new sign-ups** checkbox, then select **Save changes**.

In [GitLab 13.7 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/273258), if an administrator disables this setting, the users in pending approval state are
automatically approved in a background job.

## Require email confirmation

You can send confirmation emails during sign up and require that users confirm
their email address before they are allowed to sign in.

To enforce confirmation of the email address used for new sign ups:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**, and expand **Sign-up restrictions**.
1. Select the **Enable email restrictions for sign ups** checkbox, then select **Save changes**.

## User cap **(FREE SELF)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4315) in GitLab 13.7.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/292600) in GitLab 13.9.

When the number of billable users reaches the user cap, any user who is added or requests access must be
[approved](../moderate_users.md#approve-or-reject-a-user-sign-up) by an administrator before they can start using
their account.

If an administrator [increases](#set-the-user-cap-number) or [removes](#remove-the-user-cap) the
user cap, the users in pending approval state are automatically approved in a background job.

### Set the user cap number

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Enter a number in **User cap**.
1. Select **Save changes**.

New user sign ups are subject to the user cap restriction.

## Remove the user cap

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Remove the number from **User cap**.
1. Select **Save changes**.

New users sign ups are not subject to the user cap restriction. Users in pending approval state are
automatically approved in a background job.

## Soft email confirmation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/47003) in GitLab 12.2.
> - It's [deployed behind a feature flag](../../../user/feature_flags.md), disabled by default.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-soft-email-confirmation).

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

The soft email confirmation improves the sign-up experience for new users by allowing
them to sign in without an immediate confirmation when an email confirmation is required.
GitLab shows the user a reminder to confirm their email address, and the user can't
create or update pipelines until their email address is confirmed.

## Minimum password length limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20661) in GitLab 12.6

You can [change](../../../security/password_length_limits.md#modify-minimum-password-length-using-gitlab-ui)
the minimum number of characters a user must have in their password using the GitLab UI.

## Allow or deny sign ups using specific email domains

You can specify an inclusive or exclusive list of email domains which can be used for user sign up.

These restrictions are only applied during sign up from an external user. An administrator can add a
user through the admin panel with a disallowed domain. Also, note that the users can change their
email addresses to disallowed domains after sign up.

### Allowlist email domains

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/598) in GitLab 7.11.0

You can restrict users only to sign up using email addresses matching the given
domains list.

### Denylist email domains

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5259) in GitLab 8.10.

You can block users from signing up when using an email addresses of specific domains. This can
reduce the risk of malicious users creating spam accounts with disposable email addresses.

### Create email domain allowlist or denylist

To create an email domain allowlist or denylist:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**, and expand **Sign-up restrictions**.
1. For the allowlist, you must enter the list manually. For the denylist, you can enter the list
   manually or upload a `.txt` file that contains list entries.

   Both the allowlist and denylist accept wildcards. For example, you can use
`*.company.com` to accept every `company.com` subdomain, or `*.io` to block all
domains ending in `.io`. Domains must be separated by a whitespace,
semicolon, comma, or a new line.

   ![Domain Denylist](img/domain_denylist.png)

### Enable or disable soft email confirmation

Soft email confirmation is under development but ready for production use.
It is deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:soft_email_confirmation)
```

To disable it:

```ruby
Feature.disable(:soft_email_confirmation)
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
