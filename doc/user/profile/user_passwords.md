---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User passwords
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

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

{{< history >}}

- Password reset emails sent to any verified email address [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16311) in GitLab 16.1.

{{< /history >}}

You can change your password. GitLab enforces [password requirements](#password-requirements) when you choose your new
password.

### Change a known password

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Password**.
1. In the **Current password** text box, enter your current password.
1. In the **New password** and **Password confirmation** text box, enter your new password.
1. Select **Save password**.

### Change an unknown password

If you do not know your current password, select **Forgot your password?**
from the GitLab sign-in page and complete the form.

If you enter a verified email address for an existing account, GitLab sends a password reset email.
If the provided email address isn't associated with an existing account, no email is sent.

In both situations, you are redirected to the sign-in page and see the following message:

> "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."

{{< alert type="note" >}}

Your account can have more than one verified email address, and any email address
associated with your account can be verified. However, only the primary email address
can be used to sign in once the password is reset.

{{< /alert >}}

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

GitLab Self-Managed instances can configure the following additional password requirements:

- [Password minimum and maximum length limits](../../security/password_length_limits.md).
- [Password complexity requirements](../../administration/settings/sign_up_restrictions.md#password-complexity-requirements).

## Block weak passwords

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23610) in GitLab 15.4 [with a flag](../../administration/feature_flags/_index.md) named `block_weak_passwords`, weak passwords aren't accepted. Disabled by default on GitLab Self-Managed.
- [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/363445) on GitLab.com in GitLab 15.6.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/363445) and enabled on GitLab Self-Managed in GitLab 15.7. Feature flag `block_weak_passwords` removed.

{{< /history >}}

GitLab disallows weak passwords. Your password is considered weak when it:

- Matches one of 4500+ known, breached passwords.
- Contains part of your name, username, or email address.
- Contains a predictable word (for example, `gitlab` or `devops`).

Weak passwords are rejected with the error message: **Password must not contain commonly used combinations of words and letters**.
