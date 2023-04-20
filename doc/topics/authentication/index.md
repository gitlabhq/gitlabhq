---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Authentication **(FREE)**

This page gathers all the resources for the topic **Authentication** in GitLab.

## GitLab users

- [SSH](../../user/ssh.md)
- [Two-factor authentication](../../user/profile/account/two_factor_authentication.md)
- [Stay signed in indefinitely](../../user/profile/index.md#stay-signed-in-indefinitely)
- **Articles:**
  - [Support for Universal 2nd Factor Authentication - YubiKeys](https://about.gitlab.com/blog/2016/06/22/gitlab-adds-support-for-u2f/)
  - [Security Webcast with Yubico](https://about.gitlab.com/blog/2016/08/31/gitlab-and-yubico-security-webcast/)
- **Integrations:**
  - [GitLab as OAuth 2.0 authentication service provider](../../integration/oauth_provider.md)
  - [GitLab as OpenID Connect identity provider](../../integration/openid_connect_provider.md)

## GitLab administrators

- [LDAP](../../administration/auth/ldap/index.md)
- [Enforce two-factor authentication (2FA)](../../security/two_factor_authentication.md)
- **Articles:**
  - [Feature Highlight: LDAP Integration](https://about.gitlab.com/blog/2014/07/10/feature-highlight-ldap-sync/)
  - [Debugging LDAP](https://about.gitlab.com/handbook/support/workflows/debugging_ldap.html)
- **Integrations:**
  - [OmniAuth](../../integration/omniauth.md)
  - [Atlassian Crowd OmniAuth Provider](../../administration/auth/crowd.md)
  - [CAS OmniAuth Provider](../../integration/cas.md)
  - [SAML OmniAuth Provider](../../integration/saml.md)
  - [SAML for GitLab.com Groups](../../user/group/saml_sso/index.md)
  - [SCIM user provisioning for GitLab.com Groups](../../user/group/saml_sso/scim_setup.md)
  - [Kerberos integration (GitLab EE)](../../integration/kerberos.md)

## API

- [OAuth 2.0 tokens](../../api/rest/index.md#oauth-20-tokens)
- [Personal access tokens](../../api/rest/index.md#personalprojectgroup-access-tokens)
- [Project access tokens](../../api/rest/index.md#personalprojectgroup-access-tokens)
- [Group access tokens](../../api/rest/index.md#personalprojectgroup-access-tokens)
- [Impersonation tokens](../../api/rest/index.md#impersonation-tokens)
- [OAuth 2.0 identity provider API](../../api/oauth2.md)

## Third-party resources

<!-- vale gitlab.Spelling = NO -->

- [Kanboard Plugin GitLab Authentication](https://github.com/kanboard/plugin-gitlab-auth)
- [Jenkins GitLab OAuth Plugin](https://wiki.jenkins.io/display/JENKINS/GitLab+OAuth+Plugin)
- [OKD - Configuring Authentication and User Agent](https://docs.okd.io/3.11/install_config/configuring_authentication.html#GitLab)

<!-- vale gitlab.Spelling = YES -->
