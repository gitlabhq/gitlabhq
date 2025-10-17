---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Passkeys
description: Passwordless authentication and 2FA using passkeys
ignore_in_report: true
noindex: true
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206407) in GitLab 18.6
  [with a flag](../administration/feature_flags/_index.md) named `passkeys`.
  Disabled by default on GitLab Self-Managed.

{{< /history >}}

Passkeys provide a secure and convenient way to sign in to your GitLab account without using
passwords. Passkeys offer phishing-resistant sign-in while protecting users from weak password
vulnerabilities and credential breaches.

## How passkeys work

Passkeys use public-key cryptography to authenticate you securely to GitLab. When you create a passkey:

- Your device generates a unique cryptographic key pair.
- The private key stays securely on your device and is never shared.
- GitLab stores only the public key, which cannot be used to impersonate you.
- When you sign in, your device uses biometric authentication or a PIN to unlock the private key and prove your identity.

This approach ensures that if GitLab servers are compromised, attackers cannot use your passkey to access your account.

### Security considerations

- Keep backup authentication methods: Always maintain alternative ways to access your account,
  such as recovery codes or other 2FA methods.
- Maintain device security: Ensure your device is protected with a strong PIN, password,
  or biometric lock.
- Review regularly: Periodically review your registered passkeys and remove any for devices
  you no longer use.
- Do not use shared devices: Do not set up passkeys on shared or public devices.

## View your passkeys

To view information about your registered passkeys, including the passkey name, device type,
and usage details:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. Select **Manage authentication**.
1. In the **Passkey sign-in** section, view your passkeys.

## Add a passkey

Prerequisites:

- You must have a device that supports the WebAuthn standard.
  - Desktop browsers: Chrome, Firefox, Safari, and Edge.
  - Mobile devices: iOS 16 and later, and Android 9 and later, with biometric authentication
    or device PINs turned on.
  - Security keys: Hardware security keys that support FIDO2 or WebAuthn.

To add a passkey:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. Select **Manage authentication**.
1. In the **Passkey sign-in** section, select **Add passkey**.
1. Follow the prompts on your device or browser.
1. Enter your current password to confirm your identity.
1. Enter a name for your passkey.
1. Select **Add passkey**.

## Sign in with a passkey

To sign in to GitLab with a passkey, instead of a password:

1. Go to the GitLab sign-in page.

   - On GitLab.com, go to `https://gitlab.com/users/sign_in`.
   - On GitLab Self-Managed, use your instance domain. For example, `https://gitlab.example.com/users/sign_in`.

1. Under the additional sign-in options, select **Passkey**.
1. Follow the prompts on your device to authenticate using your fingerprint, face recognition, or device PIN.

## Use a passkey for two-factor authentication

If you have enabled [two-factor authentication](../user/profile/account/two_factor_authentication.md)
(2FA) for your account, passkeys become available as an additional and default 2FA option.

To use a passkey as a 2FA method:

1. Go to the GitLab sign-in page.

   - On GitLab.com, go to `https://gitlab.com/users/sign_in`.
   - On GitLab Self-Managed, use your instance domain. For example, `https://gitlab.example.com/users/sign_in`.

1. Enter your username and password.
1. When prompted, authenticate with your passkey.
1. Follow the prompts on your device to authenticate using your fingerprint, face recognition, or device PIN.

{{< alert type="note" >}}

If your passkey is unavailable on the current device, use your backup 2FA method instead.

{{< /alert >}}

## Delete a passkey

Delete a passkey if you no longer use the device, or if you want to replace it with a new passkey.
If you delete your only passkey, GitLab will also disable passkey sign-in for your account.

To delete a passkey:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. Select **Manage authentication**.
1. In the **Passkey sign-in** section, find the passkey you want to delete.
1. Next to the passkey, select **Delete** ({{< icon name="remove" >}}).
1. On the confirmation dialog, confirm the deletion.

   - If you have multiple passkeys, select **Delete passkey**.
   - If you have a single passkey, select **Disable passkey sign-in**.

{{< alert type="warning" >}}

Deleted passkeys cannot be recovered. You must add a new passkey if you want to authenticate with the device again.

{{< /alert >}}

## Troubleshooting

### Problems adding a passkey

If you cannot add a passkey:

- Verify that your device and browser support WebAuthn and biometric authentication.
- Ensure your browser is up to date.
- Check that you have set up a device PIN, fingerprint, or face recognition on your device.
- Try using a different browser or device.
- Check if the device is already registered as a WebAuthn two-factor authentication method.
  - If the device is already registered as a WebAuthn two-factor authentication method:

    1. Delete the WebAuthn device from your 2FA methods.
    1. Register it as a passkey.
    1. If you want to enable 2FA again, configure a backup 2FA method (such as an authenticator app).
       GitLab automatically adds your passkey as your default two-factor authentication.

### Cannot sign in with passkey

If you cannot sign in using your passkey:

- Make sure you use the same device used to create the passkey.
- Verify that your biometric authentication or device PIN works.
- Try clearing your browser cache and cookies.
- Use your backup 2FA method or password to sign in, then check your passkey settings.

### Lost or replaced device

If you lose your device or get a new one, sign in with your password and set up a new passkey.

To set up a passkey on your new device:

1. Sign in to GitLab using your password.
1. If you use passkeys as a 2FA method, sign in with your backup method.
1. Remove the old passkey from your account settings.
1. Set up a new passkey on your new device.

## Related topics

- [Two-factor authentication](../user/profile/account/two_factor_authentication.md)
- [User passwords](../user/profile/user_passwords.md)
