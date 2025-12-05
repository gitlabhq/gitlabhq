---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Troubleshooting two-factor authentication
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Error: `HTTP Basic: Access denied. If a password was provided for Git authentication ...`

When making a request, you might get an error that states:

```plaintext
HTTP Basic: Access denied. If a password was provided for Git authentication,
the password was incorrect or you're required to use a token instead of a password.
If a token was provided, it was either incorrect, expired, or improperly scoped.
```

This error occurs when:

- You have enabled 2FA and attempted to authenticate with a username and password.
- You have not enabled 2FA and attempted to authenticate with an incorrect username or password.
- You have not enabled 2FA and the [enforce 2FA for all users](../../../security/two_factor_authentication.md#enforce-2fa-for-all-users) setting is active.
- You have not enabled 2FA and the [password authentication enabled for Git over HTTP(S)](../../../administration/settings/sign_in_restrictions.md#password-authentication-enabled)
  setting is not active.

To resolve this error:

- Use a [personal access token](../personal_access_tokens.md) with the correct scopes:
  - For Git requests over HTTP(S): `read_repository` or `write_repository`
  - For [GitLab container registry](../../packages/container_registry/authenticate_with_container_registry.md)
  requests: `read_registry` or `write_registry`
  - For [dependency proxy](../../packages/dependency_proxy/_index.md#authenticate-with-the-dependency-proxy-for-container-images)
  requests: `read_registry` and `write_registry`
- If you configured LDAP, use an [LDAP password](../../../administration/auth/ldap/_index.md).
- Use an [OAuth credential helper](two_factor_authentication.md#oauth-credential-helpers).

## Error: `invalid pin code`

An `invalid pin code` error can indicate that there is a time sync issue between the authentication
application and the GitLab instance itself.

To resolve this issue, turn on time synchronization for the device that generates your 2FA codes.

{{< tabs >}}

{{< tab title="Android" >}}

  1. Go to **Settings** > **System** > **Date & time**.
  1. Turn on **Set time automatically**. If the setting is already on, turn it off, wait a few seconds, and turn it on again.

{{< /tab >}}

{{< tab title="iOS" >}}

  1. Go to **Settings** > **General** > **Date & Time**.
  1. Turn on **Set Automatically**. If the setting is already on, turn it off, wait a few seconds, and turn it on again.

{{< /tab >}}

{{< /tabs >}}

## Error: `Permission denied (publickey)` when generating recovery codes

You might get an error that states `Permission denied (publickey)`.

This issue occurs if you are using a non-default SSH key pair file path and attempt to
[generate recovery codes using SSH](two_factor_authentication_troubleshooting.md#regenerate-recovery-codes-with-ssh).

To resolve this, [configure SSH to point to a different directory](../../ssh.md#configure-ssh-to-point-to-a-different-directory) using `ssh-agent`.

## Recovery options and 2FA reset

### Use a recovery code

When you enabled a one-time password (OTP) authenticator, GitLab provided you with a series of
[recovery codes](two_factor_authentication.md#recovery-codes).
You can use these codes to sign in to your account.

To use a recovery code:

1. On the GitLab sign-in page, enter your username or email, and password.
1. When prompted for a two-factor code, enter a recovery code.

After you use a recovery code, you cannot use the same code again.
Your other recovery codes remain valid.

### Regenerate recovery codes with the UI

If you can still access your account, you can regenerate your recovery codes through your user settings.

To regenerate recovery codes with the UI:

1. Access your [**User settings**](../_index.md#access-your-user-settings).
1. Select **Account** > **Two-Factor Authentication (2FA)**.
1. Select **Manage two-factor authentication**.
1. In the **Disable two-factor authentication** section, select **Regenerate recovery codes**.
1. In the dialog, enter your current password and select **Regenerate recovery codes**.

{{< alert type="note" >}}

Every time you regenerate 2FA recovery codes, save them. You can't use any previously created 2FA codes.

{{< /alert >}}

### Regenerate recovery codes with SSH

If you added an SSH key to your GitLab account, you can regenerate your recovery codes with SSH:

{{< alert type="note" >}}

- You cannot use `gitlab-sshd` to regenerate recovery codes.

{{< /alert >}}

To regenerate recovery codes with SSH:

1. In a terminal, run:

   ```shell
   ssh git@gitlab.com 2fa_recovery_codes
   ```

   On GitLab Self-Managed instances, replace `gitlab.com` with the GitLab server hostname (`gitlab.example.com`).

1. On the confirmation message, enter `yes`.
1. Save the recovery codes that GitLab generates. Your previous recovery codes are no longer valid.
1. On the sign-in page, enter your username or email, and password.
1. When prompted for a two-factor code, enter one of your new recovery codes.

After signing in, immediately set up 2FA with a new device.

### Restore 2FA codes from authenticator backup

In addition to the GitLab recovery codes, many authenticator apps offer their own backup and
recovery methods. If you lose your device, you may be able to restore your 2FA codes by
logging into your authenticator app on a new device, provided you enabled backup features
beforehand.

{{< alert type="note" >}}

- You must enable your authenticator backup features before you lose access to your device.
- GitLab Support cannot assist with recovery issues related to third-party authenticator apps.
- GitLab recommends using recovery codes as your primary recovery method. Make sure you save
  your recovery codes when you enable 2FA.

{{< /alert >}}

For more information, see the documentation for your specific authenticator app.
Documentation for common authenticators is available through the following locations:

- [Microsoft Authenticator](https://support.microsoft.com/en-us/account-billing/restore-account-credentials-from-microsoft-authenticator-ce53096e-1e1c-4840-9e32-1618bc33cd43)
- [Google Authenticator](https://support.google.com/accounts/answer/1066447)
- [Authy](https://www.twilio.com/en-us/blog/how-the-authy-two-factor-backups-work)
- [1Password](https://support.1password.com/recovery-codes/?mac#recover-your-account)

### Reset 2FA on your account

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

If the previous recovery options do not work, you can create a support request to disable 2FA for
your account. This service is only available for accounts with a GitLab.com subscription.

GitLab Support cannot reset 2FA for Free accounts. If you cannot recover your 2FA method, you will
be permanently locked out of your account and must create a new one. For more information, see the
[blog announcement](https://about.gitlab.com/blog/2020/08/04/gitlab-support-no-longer-processing-mfa-resets-for-free-users/).

To create a support request:

1. Go to [GitLab Support](https://support.gitlab.com).
1. Select **Submit a Ticket**.
1. Sign in with your GitLab Support account.
   Your support account is different from your GitLab account and is not impacted by your 2FA issue.
1. In the issue dropdown list, select **GitLab.com user accounts and login issues**.
1. Complete the fields in the support form.
1. Select **Submit**.

After you regain access to your account, re-enable 2FA as soon as possible to keep your account secure.

### Reset 2FA for enterprise users

If you are a top-level group Owner on a paid plan, you can disable 2FA for enterprise users.
For more information, see [disable 2FA for enterprise users](../../../security/two_factor_authentication.md#enterprise-users).
