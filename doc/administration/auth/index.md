---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab authentication and authorization **(FREE SELF)**

GitLab integrates with a number of [OmniAuth providers](../../integration/omniauth.md#supported-providers),
and the following external authentication and authorization providers:

- [LDAP](ldap/index.md): Includes Active Directory, Apple Open Directory, Open LDAP,
  and 389 Server.
  - [Google Secure LDAP](ldap/google_secure_ldap.md)
- [SAML for GitLab.com groups](../../user/group/saml_sso/index.md) **(PREMIUM SAAS)**
- [Smartcard](smartcard.md) **(PREMIUM SELF)**

NOTE:
UltraAuth has removed their software which supports OmniAuth integration. We have therefore removed all references to UltraAuth integration.

## SaaS vs self-managed comparison

The external authentication and authorization providers may support the following capabilities.
For more information, see the links shown on this page for each external provider.

| Capability                                      | SaaS                                    | Self-managed                       |
|-------------------------------------------------|-----------------------------------------|------------------------------------|
| **User Provisioning**                           | SCIM<br>SAML <sup>1</sup> | LDAP <sup>1</sup><br>SAML <sup>1</sup><br>[OmniAuth Providers](../../integration/omniauth.md#supported-providers) <sup>1</sup><br>SCIM  |
| **User Detail Updating** (not group management) | Not Available                           | LDAP Sync                          |
| **Authentication**                              | SAML at top-level group (1 provider)    | LDAP (multiple providers)<br>Generic OAuth 2.0<br>SAML (only 1 permitted per unique provider)<br>Kerberos<br>JWT<br>Smartcard<br>[OmniAuth Providers](../../integration/omniauth.md#supported-providers) (only 1 permitted per unique provider) |
| **Provider-to-GitLab Role Sync**                | SAML Group Sync                         | LDAP Group Sync<br>SAML Group Sync ([GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/285150) and later) |
| **User Removal**                                | SCIM (remove user from top-level group) | LDAP (remove user from groups and block from the instance)<br>SCIM |

1. Using Just-In-Time (JIT) provisioning, user accounts are created when the user first signs in.

## Test OIDC/OAuth in GitLab

See [Test OIDC/OAuth in GitLab](test_oidc_oauth.md) to learn how to test OIDC/OAuth authentication in your GitLab instance using your client application.
