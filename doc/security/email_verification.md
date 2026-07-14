---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Account email verification
description: Confirm user identity with email verification.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/519123) in GitLab 18.1. Feature flag `require_email_verification` removed.

{{< /history >}}

Account email verification provides an additional layer of GitLab account security.
Email verification is required in the following situations:

- Your account is [locked](unlock_user.md) due to multiple failed sign-in attempts.
- Email-based one-time password (OTP) is [enabled](../user/profile/account/two_factor_authentication.md#enable-email-otp)
  for your account.
- You sign in from a new or untrusted IP address.

> [!note]
> On GitLab Self-Managed and GitLab Dedicated, this feature is disabled by default. Use the [application settings API](../api/settings.md)
> to enable the `require_email_verification_on_account_locked` attribute.

<i class="fa-youtube-play" aria-hidden="true"></i>
For a demo, see [Require email verification - demo](https://www.youtube.com/watch?v=wU6BVEGB3Y0).

To complete email verification, sign in to your account and enter the six-digit verification code sent to your
primary email address. If you cannot access your primary email address, you can instead send the verification code
to any of your secondary email addresses.

Verification codes expire after 60 minutes.

On GitLab.com, if you don't receive a verification email, select **Resend Code** before you contact the support team.
