---
comments: false
type: index
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab authentication and authorization **(FREE SELF)**

GitLab integrates with the following external authentication and authorization
providers:

- [Atlassian](atlassian.md)
- [Auth0](../../integration/auth0.md)
- [Authentiq](authentiq.md)
- [AWS Cognito](cognito.md)
- [Azure](../../integration/azure.md)
- [Bitbucket Cloud](../../integration/bitbucket.md)
- [CAS](../../integration/cas.md)
- [Crowd](crowd.md)
- [Facebook](../../integration/facebook.md)
- [GitHub](../../integration/github.md)
- [GitLab.com](../../integration/gitlab.md)
- [Google OAuth](../../integration/google.md)
- [JWT](jwt.md)
- [Kerberos](../../integration/kerberos.md)
- [LDAP](ldap/index.md): Includes Active Directory, Apple Open Directory, Open LDAP,
  and 389 Server.
  - [Google Secure LDAP](ldap/google_secure_ldap.md)
- [Salesforce](../../integration/salesforce.md)
- [SAML](../../integration/saml.md)
- [SAML for GitLab.com groups](../../user/group/saml_sso/index.md) **(PREMIUM SAAS)**
- [Shibboleth](../../integration/saml.md)
- [Smartcard](smartcard.md) **(PREMIUM SELF)**
- [Twitter](../../integration/twitter.md)

NOTE:
UltraAuth has removed their software which supports OmniAuth integration. We have therefore removed all references to UltraAuth integration.

## SaaS vs Self-Managed Comparison

The external authentication and authorization providers may support the following capabilities.
For more information, see the links shown on this page for each external provider.

| Capability                                      | SaaS                                    | Self-Managed                       |
|-------------------------------------------------|-----------------------------------------|------------------------------------|
| **User Provisioning**                           | SCIM<br>Just-In-Time (JIT) Provisioning | LDAP Sync                          |
| **User Detail Updating** (not group management) | Not Available                           | LDAP Sync                          |
| **Authentication**                              | SAML at top-level group (1 provider)    | LDAP (multiple providers)<br>Generic OAuth2<br>SAML (only 1 permitted per unique provider)<br>Kerberos<br>JWT<br>Smartcard<br>OmniAuth Providers (only 1 permitted per unique provider) |
| **Provider-to-GitLab Role Sync**                | SAML Group Sync                         | LDAP Group Sync                    |
| **User Removal**                                | SCIM (remove user from top-level group) | LDAP (Blocking User from Instance) |

## Change apps or configuration

When GitLab doesn't support having multiple providers (such as OAuth), GitLab configuration and user identification must be
updated at the same time if the provider or app is changed.

These instructions apply to all methods of authentication where GitLab stores an `extern_uid` and it is the only data used
for user authentication.

When changing apps within a provider, if the user `extern_uid` does not change, only the GitLab configuration must be
updated.

To swap configurations:

1. Change provider configuration in your `gitlab.rb` file.
1. Update `extern_uid` for all users that have an identity in GitLab for the previous provider.

To find the `extern_uid`, look at an existing user's current `extern_uid` for an ID that matches the appropriate field in
your current provider for the same user.

There are two methods to update the `extern_uid`:

- Using the [Users API](../../api/users.md#user-modification). Pass the provider name and the new `extern_uid`.
- Using the [Rails console](../operations/rails_console.md):

  ```ruby
  Identity.where(extern_uid: 'old-id').update!(extern_uid: 'new-id')`
  ```
