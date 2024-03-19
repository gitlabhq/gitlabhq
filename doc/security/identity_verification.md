---
stage: Govern
group: Anti-Abuse
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Identity verification

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95722) in GitLab 15.4 [with a flag](../administration/feature_flags.md) named `identity_verification`. Disabled by default.

FLAG:
This feature is not ready for production use.

Identity verification provides multiple layers of GitLab account security.
Depending on your [risk score](../integration/arkose.md), you might be required to perform up to
three stages of verification to register an account:

- **All users** - Email verification.
- **Medium-risk users** - Phone number verification.
- **High-risk users** - Credit card verification.

Users created after signing in with [SAML SSO for GitLab.com groups](../user/group/saml_sso/index.md) are exempt from identity verification.

## Email verification

To register an account, you must provide a valid email address.
See [Account email verification](email_verification.md).

## Phone number verification

In addition to email verification, you might have to provide a valid phone number and verify a one-time code.

You cannot verify an account with a phone number associated with a banned user.

## Credit card verification

In addition to email and phone number verification, you might have to provide a valid credit card number.

You cannot verify an account with a credit card number associated with a banned user.

## Related topics

- [Identity verification development documentation](../development/identity_verification.md)
- [Changing risk assessment support](https://handbook.gitlab.com/handbook/support/workflows/reinstating-blocked-accounts/#change-risk-assessment-credit-card-verification)
