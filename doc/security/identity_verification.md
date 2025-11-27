---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Identity verification
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95722) in GitLab 15.4 [with a flag](../administration/feature_flags/_index.md) named `identity_verification`. Disabled by default.
- Enabled on GitLab.com in GitLab 16.0.
- Generally available in GitLab 16.11. Feature flag `identity_verification` removed.

{{< /history >}}

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

In addition to email verification, you might also be asked to provide a valid phone number and
verify a one-time password (OTP) code.

{{< alert type="note" >}}

You cannot verify an account with a phone number associated with a banned user.

{{< /alert >}}

### Country support

Some countries have limited or no support for phone number verification:

- Unsupported: Phone verification is not available.
- Partial support: Phone verification might not work due to local regulations or
  enforcement policies.

If phone verification is unavailable in your country, try [credit card verification](#credit-card-verification)
or create a [support ticket](https://about.gitlab.com/support/).

| Country | Support level |
|---------|---------------|
| Armenia | Partial support |
| Bangladesh | Unsupported |
| Belarus | Partial support |
| Cambodia | Partial support |
| China | Unsupported |
| Cuba | Unsupported |
| Eswatini | Partial support |
| Haiti | Partial support |
| Hong Kong | Unsupported |
| Indonesia | Unsupported |
| Iran | Unsupported |
| Kazakhstan | Partial support |
| Kenya | Partial support |
| Kuwait | Partial support |
| Macau | Unsupported |
| Malaysia | Unsupported |
| Mexico | Partial support |
| Myanmar | Partial support |
| Nigeria | Partial support |
| North Korea | Unsupported |
| Oman | Partial support |
| Pakistan | Unsupported |
| Philippines | Partial support |
| Qatar | Partial support |
| Russia | Unsupported |
| Saudi Arabia | Unsupported |
| South Africa | Partial support |
| Syria | Unsupported |
| Tanzania | Partial support |
| Thailand | Partial support |
| Turkey | Partial support |
| Uganda | Partial support |
| Ukraine | Partial support |
| United Arab Emirates | Unsupported |
| Uzbekistan | Partial support |
| Vietnam | Unsupported |

## Credit card verification

In addition to email and phone number verification, you might have to provide a valid credit card number.

To verify your account, you might need to provide a valid credit card number in addition to your
email address and phone number. GitLab does not store your card details directly or make any charges.

You cannot verify an account with a credit card number associated with a banned user.
