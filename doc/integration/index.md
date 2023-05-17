---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Integrate with GitLab **(FREE)**

You can integrate GitLab with external services for enhanced functionality.

## Services

Services such as Campfire, Jira, Pivotal Tracker, and Slack
are available as [integrations](../user/project/integrations/index.md).

## Issue trackers

You can use an [external issue tracker](external-issue-tracker.md) with the GitLab
issue tracker or use an external issue tracker only.

## Authentication sources

You can integrate GitLab with the following authentication sources:

- Enable the [Auth0 OmniAuth](auth0.md) provider.
- Enable sign-in with [Bitbucket](bitbucket.md) accounts.
- Authenticate with [Kerberos](kerberos.md).
- Enable sign-in with [LDAP](../administration/auth/ldap/index.md).
- Enable creating [OAuth 2.0](oauth_provider.md) applications.
- Use [OmniAuth](omniauth.md) to enable sign-in through:
  - Azure
  - Bitbucket
  - Crowd
  - Facebook
  - GitHub
  - GitLab.com
  - Google
  - SAML
  - Twitter
- Use GitLab as an [OpenID Connect](openid_connect_provider.md) identity provider.
- Authenticate with [Vault](vault.md) through GitLab OpenID Connect.
- Configure GitLab as a [SAML 2.0](saml.md) Service Provider.

## Security enhancements

You can integrate GitLab with the following security enhancements:

- [Akismet](akismet.md) to reduce spam.
- Google [reCAPTCHA](recaptcha.md) to verify new users.

GitLab also provides features to improve the security of your own application.
For more details, see [Secure your application](../user/application_security/index.md).

## Security partners

You can integrate GitLab with several security partners. For more information, see
[Security partner integrations](security_partners/index.md).

## Continuous integration

You can integrate GitLab with the following external services for continuous integration:

- [Jenkins](jenkins.md) CI.
- [Datadog](datadog.md) to monitor for CI/CD job failures and performance issues.

## Feature enhancements

You can integrate GitLab with the following feature enhancements:

- Add GitLab actions to [Gmail actions buttons](gmail_action_buttons_for_gitlab.md).
- Configure [PlantUML](../administration/integration/plantuml.md)
or [Kroki](../administration/integration/kroki.md) to use diagrams in AsciiDoc and Markdown documents.
- Attach merge requests to [Trello](trello_power_up.md) cards.
- Enable integrated code intelligence powered by [Sourcegraph](sourcegraph.md).
- Add [Elasticsearch](advanced_search/elasticsearch.md) for [advanced search](../user/search/advanced_search.md).

## Troubleshooting

### SSL certificate errors

When integrating GitLab with services using a self-signed certificate, you might
encounter SSL certificate errors in different parts of the application.

As a workaround, you can do one of the following:

- Add the certificate to the OS trusted chain. See:
  - [Adding trusted root certificates to the server](https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html)
  - [How do you add a certificate authority (CA) to Ubuntu?](https://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu)
- In Omnibus GitLab, add the certificate to the Omnibus trusted chain:
  1. [Install the self-signed certificate](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates).
  1. Concatenate the self-signed certificate with the GitLab trusted certificate.
     The self-signed certificate might be overwritten during upgrades.

     ```shell
     cat jira.pem >> /opt/gitlab/embedded/ssl/certs/cacert.pem
     ```

  1. Restart GitLab.

     ```shell
     sudo gitlab-ctl restart
     ```

### Search Sidekiq logs in Kibana

To locate a specific integration in Kibana, use the following KQL search string:

```plaintext
`json.integration_class.keyword : "Integrations::Jira" and json.project_path : "path/to/project"`
```

You can find information in:

- `json.exception.backtrace`
- `json.exception.class`
- `json.exception.message`
- `json.message`
