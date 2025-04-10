---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting two-factor authentication
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

## Error: `HTTP Basic: Access denied. If a password was provided for Git authentication ...`

When making a request, you might get an error that states:

```plaintext
HTTP Basic: Access denied. If a password was provided for Git authentication, the password was incorrect or you're required to use a token instead of a password. If a token was provided, it was either incorrect, expired, or improperly scoped.
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

  1. Go to **Settings > System > Date & time**.
  1. Turn on **Set time automatically**. If the setting is already on, turn it off, wait a few seconds, and turn it on again.

{{< /tab >}}

{{< tab title="iOS" >}}

  1. Go to **Settings > General > Date & Time**.
  1. Turn on **Set Automatically**. If the setting is already on, turn it off, wait a few seconds, and turn it on again.

{{< /tab >}}

{{< /tabs >}}

## Error: `Permission denied (publickey)` when generating recovery codes

You might get an error that states `Permission denied (publickey)`.

This issue occurs if you are using a non-default SSH key pair file path and attempt to
[generate recovery codes using SSH](two_factor_authentication_troubleshooting.md#generate-new-recovery-codes-using-ssh).

To resolve this, [configure SSH to point to a different directory](../../ssh.md#configure-ssh-to-point-to-a-different-directory) using `ssh-agent`.

## Recovery options and 2FA reset

If you have enabled 2FA and cannot generate codes, use one of the following methods to access your
account:

### Use a recovery code

When you enabled 2FA, GitLab provided you with a series of recovery codes. You can use these codes to sign in to your account.

To use a recovery code:

1. On the GitLab sign-in page, enter your username or email, and password.
1. When prompted for a two-factor code, enter a recovery code.

After you use a recovery code, you cannot use the same code again.
Your other recovery codes remain valid.

### Generate new recovery codes using SSH

If you added an SSH key to your GitLab account, you can generate a new set of recovery codes with SSH:

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

### Reset 2FA on your account

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

If the previous recovery options do not work, and you still cannot sign in to your account,
you can create a support request to disable 2FA for your account.
After 2FA is disabled, re-enable it as soon as possible to keep your account secure.

This service is only available for accounts with a GitLab.com subscription. For more information, see our
[blog post](https://about.gitlab.com/blog/2020/08/04/gitlab-support-no-longer-processing-mfa-resets-for-free-users/).

To create a support request:

1. Go to [GitLab Support](https://support.gitlab.com).
1. Select **Submit a Ticket**.
1. If possible, sign in to your account.
1. In the issue dropdown list, select **GitLab.com user accounts and login issues**.
1. Complete the fields in the support form.
1. Select **Submit**.

### Reset 2FA for enterprise users

If you are a top-level group Owner on a paid plan, you can disable 2FA for enterprise users.
For more information, see [Disable two-factor-authentication](../../enterprise_user/_index.md#disable-two-factor-authentication).
