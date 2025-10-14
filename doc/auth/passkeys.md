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

You can use passkeys:

- For passwordless sign-in: Use the **Sign in with Passkey** option on the GitLab sign-in page.
- As an additional two-factor authentication method: After you enable any
[two-factor authentication](../user/profile/account/two_factor_authentication.md) (2FA) method,
passkeys become available as an additional and default 2FA option.

## How passkeys work

1. When you sign in, your device uses your PIN or biometric authentication (like fingerprints or face
   recognition) to unlock the private key and prove your identity.
