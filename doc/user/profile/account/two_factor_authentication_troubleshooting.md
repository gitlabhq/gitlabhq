---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting two-factor authentication
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

## Error: `HTTP Basic: Access denied. If a password was provided for Git authentication ...`

When making a request, you can receive the following error:

```plaintext
HTTP Basic: Access denied. If a password was provided for Git authentication, the password was incorrect or you're required to use a token instead of a password. If a token was provided, it was either incorrect, expired, or improperly scoped.
```

This error occurs in the following scenarios:

- You have 2FA enabled and have attempted to authenticate with a username and
  password.
- You do not have 2FA enabled and have sent an incorrect username or password
  with your request.
- You do not have 2FA enabled but an administrator has enabled the
  [enforce 2FA for all users](../../../security/two_factor_authentication.md#enforce-2fa-for-all-users) setting.
- You do not have 2FA enabled, but an administrator has disabled the
  [password authentication enabled for Git over HTTP(S)](../../../administration/settings/sign_in_restrictions.md#password-authentication-enabled)
  setting.

Instead you can authenticate:

- Using a [personal access token](../personal_access_tokens.md) (PAT):
  - For Git requests over HTTP(S), a PAT with `read_repository` or `write_repository` scope is required.
  - For [GitLab container registry](../../packages/container_registry/authenticate_with_container_registry.md) requests, a PAT
    with `read_registry` or `write_registry` scope is required.
  - For [dependency proxy](../../packages/dependency_proxy/_index.md#authenticate-with-the-dependency-proxy-for-container-images) requests, a PAT with
    `read_registry` and `write_registry` scopes is required.
- If you have configured LDAP, using an [LDAP password](../../../administration/auth/ldap/_index.md)
- Using an [OAuth credential helper](../../profile/account/two_factor_authentication.md#oauth-credential-helpers).

## Error: "invalid pin code"

If you receive an `invalid pin code` error, this can indicate that there is a time sync issue
between the authentication application and the GitLab instance itself.
To avoid the time sync issue, enable time synchronization in the device that
generates the codes. For example:

- For Android (Google Authenticator):
  1. Go to the Main Menu in Google Authenticator.
  1. Select Settings.
  1. Select the Time correction for the codes.
  1. Select Sync now.
- For iOS:
  1. Go to Settings.
  1. Select General.
  1. Select Date & Time.
  1. Enable Set Automatically. If it's already enabled, disable it, wait a few seconds, and re-enable.

## Error: "Permission denied (publickey)" when regenerating recovery codes

If you receive a `Permission denied (publickey)` error when attempting to
[generate new recovery codes using an SSH key](#generate-new-recovery-codes-using-ssh)
and you are using a non-default SSH key pair file path, you might need to
[manually register your private SSH key](../../ssh.md#configure-ssh-to-point-to-a-different-directory) using `ssh-agent`.

## Recovery options and 2FA reset

If you don't have access to your code generation device and are unable to sign into your account, the following recovery options are available:

- If you saved your recovery codes when you enabled 2FA, [use a saved recovery code](#use-a-saved-recovery-code).
- If you don't have your recovery codes but have an SSH key, [generate new recovery codes using SSH](#generate-new-recovery-codes-using-ssh).
- If you don't have your recovery codes or an SSH key, [disable and reset 2FA on your account](#disable-and-reset-2fa-on-your-account)

### Use a saved recovery code

To use a recovery code:

1. Enter your username or email, and password, on the GitLab sign-in page.
1. When prompted for a two-factor code, enter the recovery code.

After you use a recovery code, you cannot re-use it. You can still use the other recovery codes you saved.

### Generate new recovery codes using SSH

If you forget to save your recovery codes when enabling 2FA, and you added an SSH key to your GitLab account, you can generate a new set of recovery codes with SSH:

1. In a terminal, run:

   ```shell
   ssh git@gitlab.com 2fa_recovery_codes
   ```

   On self-managed instances, replace **`gitlab.com`** in the command above with the GitLab server hostname (`gitlab.example.com`).

1. You are prompted to confirm that you want to generate new codes. This process invalidates previously-saved codes. For
   example:

   ```shell
   Are you sure you want to generate new two-factor recovery codes?
   Any existing recovery codes you saved will be invalidated. (yes/no)

   yes

   Your two-factor authentication recovery codes are:

   119135e5a3ebce8e
   11f6v2a498810dcd
   3924c7ab2089c902
   e79a3398bfe4f224
   34bd7b74adbc8861
   f061691d5107df1a
   169bf32a18e63e7f
   b510e7422e81c947
   20dbed24c5e74663
   df9d3b9403b9c9f0

   During sign in, use one of the codes above when prompted for your
   two-factor code. Then, visit your Profile Settings and add a new device
   so you do not lose access to your account again.
   ```

1. Go to the GitLab sign-in page and enter your username or email, and password. When prompted for a
   two-factor code, enter one of the recovery codes obtained from the command-line output.

After signing in, immediately set up 2FA with a new device.

### Disable and reset 2FA on your account

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

If other methods are unavailable, create a support ticket to request
a GitLab global administrator to disable 2FA for your account.

This service is only available for accounts that have a GitLab.com subscription. For more information, see our
[blog post](https://about.gitlab.com/blog/2020/08/04/gitlab-support-no-longer-processing-mfa-resets-for-free-users/).

1. Go to [GitLab Support](https://support.gitlab.com).
1. Select **Submit a Ticket**.
1. If possible, sign into your account.
1. In the issue dropdown list, select **GitLab.com user accounts and login issues**.
1. Complete the fields in the support form.
1. Select **Submit**.

Disabling this setting temporarily leaves your account in a less secure state.
You should sign in and re-enable 2FA as soon as possible.

If you are a top-level Owner of a namespace on a paid plan, you can disable 2FA for enterprise users.
For more information, see
[Disable two-factor-authentication](../../enterprise_user/_index.md#disable-two-factor-authentication).
