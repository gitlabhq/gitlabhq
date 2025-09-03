---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Account email verification
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86352) in GitLab 15.2 [with a flag](../administration/feature_flags/_index.md) named `require_email_verification`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/519123) in GitLab 18.1 Feature flag `require_email_verification` removed.

{{< /history >}}

Account email verification provides an additional layer of GitLab account security. When certain
conditions are met, an account is locked. If your account is locked, you must verify your email
or reset your password to sign in to GitLab.

{{< alert type="note" >}}

On GitLab Self-Managed, this feature is disabled by default. Use the [Application settings API](../api/settings.md)
to enable the `require_email_verification_on_account_locked` attribute.

{{< /alert >}}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo, see [Require email verification - demo](https://www.youtube.com/watch?v=wU6BVEGB3Y0).

On GitLab.com, if you don't receive a verification email, select **Resend Code** before you contact the support team.

## Accounts without two-factor authentication (2FA)

An account is locked when either:

- There are three or more failed sign-in attempts in 24 hours.
- A user attempts to sign in from a new IP address.

A locked account without 2FA is not unlocked automatically.

After a successful sign in, an email with a six-digit verification code is sent to your account's
primary email address. If you cannot access your primary email address, you can instead send the
verification code to any of your secondary email addresses.

The verification code expires after 60 minutes.

To unlock your account, sign in and enter the verification code. You can also
[reset your password](https://gitlab.com/users/password/new).

## Accounts with 2FA or OAuth

An account is locked when there are ten or more failed sign-in attempts, or more than the
amount defined in the [configurable locked user policy](unlock_user.md#gitlab-self-managed-and-gitlab-dedicated-users).

Accounts with 2FA or OAuth are automatically unlocked after ten minutes, or more than the
amount defined in the [configurable locked user policy](unlock_user.md#gitlab-self-managed-and-gitlab-dedicated-users).
To unlock an account manually, reset your password.
