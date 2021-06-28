---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Authentication **(FREE)**

This page gathers all the resources for the topic **Authentication** within GitLab.

## GitLab users

- [SSH](../../ssh/index.md)
- [Two-Factor Authentication (2FA)](../../user/profile/account/two_factor_authentication.md#two-factor-authentication)
- [Why do I keep getting signed out?](../../user/profile/index.md#why-do-i-keep-getting-signed-out)
- **Articles:**
  - [Support for Universal 2nd Factor Authentication - YubiKeys](https://about.gitlab.com/blog/2016/06/22/gitlab-adds-support-for-u2f/)
  - [Security Webcast with Yubico](https://about.gitlab.com/blog/2016/08/31/gitlab-and-yubico-security-webcast/)
- **Integrations:**
  - [GitLab as OAuth2 authentication service provider](../../integration/oauth_provider.md#introduction-to-oauth)
  - [GitLab as OpenID Connect identity provider](../../integration/openid_connect_provider.md)

## GitLab administrators

- [LDAP](../../administration/auth/ldap/index.md)
- [Enforce Two-factor Authentication (2FA)](../../security/two_factor_authentication.md#enforce-two-factor-authentication-2fa)
- **Articles:**
  - [Feature Highlight: LDAP Integration](https://about.gitlab.com/blog/2014/07/10/feature-highlight-ldap-sync/)
  - [Debugging LDAP](https://about.gitlab.com/handbook/support/workflows/debugging_ldap.html)
- **Integrations:**
  - [OmniAuth](../../integration/omniauth.md)
  - [Authentiq OmniAuth Provider](../../administration/auth/authentiq.md#authentiq-omniauth-provider)
  - [Atlassian Crowd OmniAuth Provider](../../administration/auth/crowd.md)
  - [CAS OmniAuth Provider](../../integration/cas.md)
  - [SAML OmniAuth Provider](../../integration/saml.md)
  - [SAML for GitLab.com Groups](../../user/group/saml_sso/index.md)
  - [SCIM user provisioning for GitLab.com Groups](../../user/group/saml_sso/scim_setup.md)
  - [Kerberos integration (GitLab EE)](../../integration/kerberos.md)

## API

- [OAuth 2 Tokens](../../api/index.md#oauth2-tokens)
- [Personal access tokens](../../api/index.md#personalproject-access-tokens)
- [Project access tokens](../../api/index.md#personalproject-access-tokens)
- [Impersonation tokens](../../api/index.md#impersonation-tokens)
- [GitLab as an OAuth2 provider](../../api/oauth2.md#gitlab-as-an-oauth2-provider)

## Third-party resources

<!-- vale gitlab.Spelling = NO -->

- [Kanboard Plugin GitLab Authentication](https://github.com/kanboard/plugin-gitlab-auth)
- [Jenkins GitLab OAuth Plugin](https://wiki.jenkins.io/display/JENKINS/GitLab+OAuth+Plugin)
- [OKD - Configuring Authentication and User Agent](https://docs.okd.io/3.11/install_config/configuring_authentication.html#GitLab)

<!-- vale gitlab.Spelling = YES -->
