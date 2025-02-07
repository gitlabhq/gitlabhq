---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User passwords
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If you use a password to sign in to GitLab, a strong password is very important. A weak or guessable password makes it
easier for unauthorized people to sign in to your account.

Some organizations require you to meet certain requirements when choosing a password.

Improve the security of your account with [two-factor authentication](account/two_factor_authentication.md).

## Choose your password

You can choose a password when you [create a user account](account/create_accounts.md).

If you register your account using an external authentication and
authorization provider, you do not need to choose a password. GitLab
[sets a random, unique, and secure password for you](../../security/passwords_for_integrated_authentication_methods.md).

## Change your password

> - Password reset emails sent to any verified email address [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16311) in GitLab 16.1.

You can change your password. GitLab enforces [password requirements](#password-requirements) when you choose your new
password.

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Password**.
1. In the **Current password** text box, enter your current password.
1. In the **New password** and **Password confirmation** text box, enter your new password.
1. Select **Save password**.

If you do not know your current password, select **I forgot my password**
and complete the form. A password reset email is sent to the email address you
enter into this form, provided that the email address is verified. If you enter an
unverified email address into this form, no email is sent, and you see the following
message:

> "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."

NOTE:
Your account can have more than one verified email address, and any email address
associated with your account can be verified.

## Password requirements

Your passwords must meet a set of requirements when:

- You choose a password during registration.
- You choose a new password using the forgotten password reset flow.
- You change your password proactively.
- You change your password after it expires.
- An administrator creates your account.
- An administrator updates your account.

By default GitLab enforces the following password requirements:

- Minimum and maximum password lengths. For example,
  see [the settings for GitLab.com](../gitlab_com/_index.md#password-requirements).
- Disallowing [weak passwords](#block-weak-passwords).

Self-managed installations can configure the following additional password requirements:

- [Password minimum and maximum length limits](../../security/password_length_limits.md).
- [Password complexity requirements](../../administration/settings/sign_up_restrictions.md#password-complexity-requirements).

## Block weak passwords

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23610) in GitLab 15.4 [with a flag](../../administration/feature_flags.md) named `block_weak_passwords`, weak passwords aren't accepted. Disabled by default on GitLab Self-Managed.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/363445) on GitLab.com in GitLab 15.6.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/363445) and enabled on GitLab Self-Managed in GitLab 15.7. Feature flag `block_weak_passwords` removed.

GitLab disallows weak passwords. Your password is considered weak when it:

- Matches one of 4500+ known, breached passwords.
- Contains part of your name, username, or email address.
- Contains a predictable word (for example, `gitlab` or `devops`).

Weak passwords are rejected with the error message: **Password must not contain commonly used combinations of words and letters**.
