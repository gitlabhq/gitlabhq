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

On GitLab Self-Managed and GitLab Dedicated, administrators can configure:

- [Custom password length limits](../../security/password_length_limits.md).
- [Password complexity requirements](../../administration/settings/sign_up_restrictions.md#password-complexity-requirements).

## Choose your password

You can choose a password when you [create a user account](account/create_accounts.md).

If you register your account using an external authentication and
authorization provider, you do not need to choose a password. GitLab
[sets a random, unique, and secure password for you](../../security/passwords_for_integrated_authentication_methods.md).

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

{{< alert type="note" >}}

Your account can have more than one verified email address, and any email address
associated with your account can be verified. However, only the primary email address
can be used to sign in once the password is reset.

{{< /alert >}}
