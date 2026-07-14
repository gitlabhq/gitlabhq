---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Unlock accounts that are locked after failed authentication attempts.
title: Locked user accounts
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Configurable locked user policy [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27048) in GitLab 16.5.

{{< /history >}}

GitLab locks a user account after several failed authentication attempts. To unlock an account, wait for the end of
the automatic unlock period or [reset your password](https://gitlab.com/users/password/new).

The following situations can cause a failed authentication attempt:

- Incorrect password during sign-in.
- Incorrect passkey during sign-in.
- Incorrect one-time password (OTP) or passkey code during a two-factor authentication (2FA) challenge.
- Incorrect password when updating profile settings.
- Incorrect current password when changing a password.
- Incorrect 2FA code when enabling admin mode.

Lock and unlock behavior depends on the offering and the user's 2FA status:

- On GitLab.com or GitLab instances that use [account email verification](email_verification.md):
  - Accounts with 2FA or external identities (SAML, OAuth) lock after 10 or more failed attempts. These
    accounts unlock automatically after 10 minutes.
  - Accounts without 2FA or external identities lock after three or more failed attempts in 24 hours. These
    accounts unlock automatically after 24 hours or by confirming identity with email verification.
- On GitLab instances without account email verification:
  - All accounts lock after 10 or more failed attempts. These accounts unlock automatically after
    10 minutes.

On GitLab Self-Managed and GitLab Dedicated, use the [application settings API](../api/settings.md#update-application-settings)
to configure the `max_login_attempts` and `failed_login_attempts_unlock_period_in_minutes` lockout limits.

## Manually unlock user accounts

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites

- Administrator access on the instance.

On GitLab Self-Managed and GitLab Dedicated instances, administrators can manually unlock an account before the
end of the unlock period.

{{< tabs >}}

{{< tab title="Admin area" >}}

To unlock an account from the Admin area:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Overview** > **Users**.
1. Use the search bar to find the locked user.
1. From the **User administration** dropdown list, select **Unlock**.

The user can now sign in.

{{< /tab >}}

{{< tab title="Rails console" >}}

To unlock a user account from a Rails console:

1. Start a [Rails console session](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Find the user to unlock:

   - By username:

     ```ruby
     user = User.find_by_username('exampleuser')
     ```

   - By user ID:

     ```ruby
     user = User.find(123)
     ```

   - By email address:

     ```ruby
     user = User.find_by(email: 'user@example.com')
     ```

1. Unlock the user:

   ```ruby
   user.unlock_access!
   ```

1. Exit the console:

   ```ruby
   exit
   ```

The user can now sign in.

{{< /tab >}}

{{< /tabs >}}
