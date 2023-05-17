---
stage: Anti-Abuse
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Account email verification **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86352) in GitLab 15.2 [with a flag](../administration/feature_flags.md) named `require_email_verification`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `require_email_verification`. On GitLab.com, this feature is not available.

Account email verification provides an additional layer of GitLab account security.
When certain conditions are met, an account is locked. If your account is locked,
you must verify your identity or reset your password to sign in to GitLab.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo, see [Require email verification - demo](https://www.youtube.com/watch?v=wU6BVEGB3Y0).

## Accounts without two-factor authentication (2FA)

An account is locked when either:

- There are three or more failed sign-in attempts in 24 hours.
- A user attempts to sign in from a new IP address and the
  `check_ip_address_for_email_verification` feature flag is enabled.

A locked account without 2FA is not unlocked automatically.

After a successful sign in, an email with a six-digit verification code is sent.
The verification code expires after 60 minutes.

To unlock your account, sign in and enter the verification code. You can also
[reset your password](https://gitlab.com/users/password/new).

## Accounts with 2FA or OAuth

An account is locked when there are five or more failed sign-in attempts in 10 minutes.

Accounts with 2FA or OAuth are automatically unlocked after 10 minutes. To unlock an account manually,
reset your password.

## Related topics

- [Locked and blocked account support](https://about.gitlab.com/handbook/support/workflows/reinstating-blocked-accounts.html)
