---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User passwords
description: Secure user passwords through requirements enforcement and password reset procedures.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

If you use a password to sign in to GitLab, a strong password is very important. A weak or guessable password makes it
easier for unauthorized people to sign in to your account.

Some organizations require you to meet certain requirements when choosing a password.

Improve the security of your account with [two-factor authentication](account/two_factor_authentication.md).

## Password requirements

Password requirements apply when you:

- Choose a password during registration.
- Reset your password.
- Change your password.
- Have an administrator create or update your account.

By default, GitLab enforces the following requirements:

- Minimum password length: 8 characters.
- Maximum password length: 128 characters.
- Must not match a list of 4,500+ known, breached passwords.
- Must not contain part of your name, username, or email address.
- Must not contain a predictable word (for example, `gitlab` or `devops`).

On GitLab Self-Managed and GitLab Dedicated, administrators can
[modify password complexity requirements](../../administration/settings/sign_up_restrictions.md#modify-password-complexity-requirements).

## Compromised password detection

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188723) in GitLab 18.0 [with a flag](../../administration/feature_flags/_index.md) named `notify_compromised_passwords`. Disabled by default.
- Enabled on GitLab.com in GitLab 18.1. Feature flag `notify_compromised_passwords` removed.

{{< /history >}}

GitLab can notify you if your GitLab.com credentials are compromised as part of a data breach on another service or platform. GitLab credentials are encrypted and GitLab itself does not have direct access to them.

When a compromised credential is detected, GitLab displays a security banner and sends an email alert that includes instructions on how to change your password and strengthen your account security.

Compromised password detection is unavailable when authenticating [with an external provider](../../administration/auth/_index.md), or if your account is already [locked](../../security/unlock_user.md).

## Choose your password

You can choose a password when you [create a user account](account/create_accounts.md).

### Passwords for externally authenticated accounts

If your account was created with an external [authentication and authorization provider](../../administration/auth/_index.md),
GitLab automatically generates a random password to maintain data consistency.

This password has the following properties:

- 128 characters in length
- Generated using the Devise gem's
  [`friendly_token` method](https://github.com/heartcombo/devise/blob/f26e05c20079c9acded3c0ee16da0df435a28997/lib/devise.rb#L492)
- Unique and secure

You don't need to know or use this password.

## Change your password

You can change your password. The new password must meet the password requirements.

To change your password:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Password**.
1. In the **Current password** text box, enter your current password.
1. In the **New password** and **Password confirmation** text box, enter your new password.
1. Select **Save password**.

## Reset your password

{{< history >}}

- Password reset emails sent to any verified email address [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16311) in GitLab 16.1.

{{< /history >}}

If you forget your password, you can submit a request to reset your password.

To reset your password:

1. Go to the GitLab sign-in page.
   - On GitLab.com, this is available at [https://gitlab.com/users/sign_in](https://gitlab.com/users/sign_in/).
   - On GitLab Self-Managed and GitLab Dedicated, use your domain. For example, `gitlab.example.com/users/sign_in`.
1. Select **Forgot your password?**.
1. Enter your email.
1. Select **Reset password**.

You are redirected to the sign-in page. If the provided email is verified and associated with an
existing account, GitLab sends a password reset email.

> [!note]
> Your account can have more than one verified email address, and any email address
> associated with your account can be verified. However, only the primary email address
> can be used to sign in once the password is reset.

## Credential storage

GitLab stores user passwords in a hashed format, not as plain text. To hash passwords, GitLab uses
the [Devise](https://github.com/heartcombo/devise) authentication library.

Password hashes use these security measures:

- Hashing algorithm:
  - Bcrypt: Used by default.
  - PBKDF2+SHA512: Used when FIPS mode is enabled.
- Stretching: Passwords are [stretched](https://en.wikipedia.org/wiki/Key_stretching) to protect against
  brute-force attacks. The stretching factor depends on the hashing algorithm:
  - Bcrypt: 10
  - PBKDF2+SHA512: 20,000
- Salting: A random [cryptographic salt](https://en.wikipedia.org/wiki/Salt_(cryptography))
  is generated for each password to protect against pre-computed hash and
  dictionary attacks. Each password has a unique salt.

OAuth access tokens are also stored in the database in PBKDF2+SHA512 format and
stretched 20,000 times.
