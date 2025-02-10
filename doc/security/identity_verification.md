---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Identity verification
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95722) in GitLab 15.4 [with a flag](../administration/feature_flags.md) named `identity_verification`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/371389) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/371389) in GitLab 16.11. Feature flag `identity_verification` removed.

Identity verification provides multiple layers of GitLab account security.
Depending on your [risk score](../integration/arkose.md), you might be required to perform up to
three stages of verification to register an account:

- **All users** - Email verification.
- **Medium-risk users** - Phone number verification.
- **High-risk users** - Credit card verification.

Users created after signing in with [SAML SSO for GitLab.com groups](../user/group/saml_sso/_index.md) are exempt from identity verification.

## Email verification

To register an account, you must provide a valid email address.
See [Make new users confirm email](user_email_confirmation.md).

## Phone number verification

In addition to email verification, you might have to provide a valid phone number and verify a one-time code.

You cannot verify an account with a phone number associated with a banned user.

### Unsupported countries

Phone number verification is not supported for numbers from the following countries:

- Bangladesh
- China
- Cuba
- Hong Kong
- Indonesia
- Iran
- Macau
- Malaysia
- North Korea
- Pakistan
- Russia
- Saudi Arabia
- Syria
- United Arab Emirates
- Vietnam

Users with phone numbers from unsupported countries can try [credit card verification](#credit-card-verification), or create a [support ticket](https://about.gitlab.com/support/).

### Partially supported countries

A user might not receive a one-time password (OTP) if their phone number is from an partially supported country. Whether a message is delivered depends on country enforcement and regulation.

The following countries are partially supported:

<!-- vale gitlab_base.Spelling = NO -->

- Armenia
- Belarus
- Cambodia
- Eswatini
- Haiti
- Kazakhstan
- Kenya
- Kuwait
- Mexico
- Myanmar
- Nigeria
- Oman
- Philippines
- Qatar
- South Africa
- Tanzania
- Thailand
- Turkey
- Uganda
- Ukraine
- Uzbekistan

<!-- vale gitlab_base.Spelling = YES -->

Users with phone numbers from partially supported countries can try [credit card verification](#credit-card-verification), or create a [support ticket](https://about.gitlab.com/support/).

## Credit card verification

In addition to email and phone number verification, you might have to provide a valid credit card number.

You cannot verify an account with a credit card number associated with a banned user.

## Related topics

- [Identity verification development documentation](../development/identity_verification.md)
- [Changing risk assessment support](https://handbook.gitlab.com/handbook/support/workflows/reinstating-blocked-accounts/#change-risk-assessment-credit-card-verification)
