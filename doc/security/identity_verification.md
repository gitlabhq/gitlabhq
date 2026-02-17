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

By default, users provisioned with SAML or SCIM must complete email verification. You
can [bypass email verification](../user/group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains)
by adding a custom domain. GitLab automatically confirms user accounts when their email
domain matches.

If you encounter identity verification errors when running CI/CD pipelines,
see [debugging pipeline errors](../ci/debugging.md#error-identity-verification-is-required-in-order-to-run-ci-jobs).

## Email verification

To register an account, you must provide a valid email address.
See [Make new users confirm email](user_email_confirmation.md).

## Phone number verification

In addition to email verification, you might also be asked to provide a valid phone number and
verify a one-time password (OTP) code.

> [!note]
> You cannot verify an account with a phone number associated with a banned user.

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

In addition to an email address and phone number, you might also need to provide a valid credit card number to verify your account.

GitLab does not store your card details directly or make any charges. This process is not connected to any billing information for your groups.

You cannot verify an account with a credit card number associated with a banned user.
