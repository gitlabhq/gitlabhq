---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# GitLab integrations **(FREE)**

GitLab can be integrated with external services for enhanced functionality.

## Issue trackers

You can use an [external issue tracker](external-issue-tracker.md) at the same time as the GitLab
issue tracker, or use only the external issue tracker.

## Authentication sources

GitLab can be configured to authenticate access requests with the following authentication sources:

- Enable the [Auth0 OmniAuth](auth0.md) provider.
- Enable sign in with [Bitbucket](bitbucket.md) accounts.
- Configure GitLab to sign in using [CAS](cas.md).
- Integrate with [Kerberos](kerberos.md).
- Enable sign in via [LDAP](../administration/auth/ldap/index.md).
- Enable [OAuth2 provider](oauth_provider.md) application creation.
- Use [OmniAuth](omniauth.md) to enable sign in via Twitter, GitHub, GitLab.com, Google,
  Bitbucket, Facebook, Shibboleth, SAML, Crowd, Azure, or Authentiq ID.
- Use GitLab as an [OpenID Connect](openid_connect_provider.md) identity provider.
- Authenticate to [Vault](vault.md) through GitLab OpenID Connect.
- Configure GitLab as a [SAML](saml.md) 2.0 Service Provider.

## Security enhancements

GitLab can be integrated with the following external services to enhance security:

- [Akismet](akismet.md) helps reduce spam.
- Google [reCAPTCHA](recaptcha.md) helps verify new users.

GitLab also provides features to improve the security of your own application. For more details see [GitLab Secure](../user/application_security/index.md).

## Security partners

GitLab has integrated with several security partners. For more information, see
[Security partners integration](security_partners/index.md).

## Continuous integration

GitLab can be integrated with the following external service for continuous integration:

- [Jenkins](jenkins.md) CI.

## Feature enhancements

GitLab can be integrated with the following enhancements:

- Add GitLab actions to [Gmail actions buttons](gmail_action_buttons_for_gitlab.md).
- Configure [PlantUML](../administration/integration/plantuml.md)
or [Kroki](../administration/integration/kroki.md) to use diagrams in AsciiDoc and Markdown documents.
- Attach merge requests to [Trello](trello_power_up.md) cards.
- Enable integrated code intelligence powered by [Sourcegraph](sourcegraph.md).
- Add [Elasticsearch](elasticsearch.md) for [Advanced Search](../user/search/advanced_search.md).

## Integrations

Integration with services such as Campfire, Flowdock, Jira, Pivotal Tracker, and Slack are available as [Integrations](../user/project/integrations/overview.md).

## Troubleshooting

### SSL certificate errors

When trying to integrate GitLab with services using self-signed certificates,
SSL certificate errors can occur in different parts of the application. Sidekiq
is a common culprit.

There are two approaches you can take to solve this:

1. Add the root certificate to the trusted chain of the OS.
1. If using Omnibus, you can add the certificate to the GitLab trusted certificates.

**OS main trusted chain**

This [resource](https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html)
has all the information you need to add a certificate to the main trusted chain.

This [answer](https://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu)
at Super User also has relevant information.

**Omnibus Trusted Chain**

[Install the self signed certificate or custom certificate authorities](https://docs.gitlab.com/omnibus/common_installation_problems/README.html#using-self-signed-certificate-or-custom-certificate-authorities)
in to Omnibus GitLab.

It is enough to concatenate the certificate to the main trusted certificate
however it may be overwritten during upgrades:

```shell
cat jira.pem >> /opt/gitlab/embedded/ssl/certs/cacert.pem
```

After that restart GitLab with:

```shell
sudo gitlab-ctl restart
```
