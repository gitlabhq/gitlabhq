---
comments: false
---

# GitLab Integration

GitLab integrates with multiple third-party services to allow external issue
trackers and external authentication.

See the documentation below for details on how to configure these services.

- [Akismet](akismet.md) Configure Akismet to stop spam
- [Auth0 OmniAuth](auth0.md) Enable the Auth0 OmniAuth provider
- [Bitbucket](bitbucket.md) Import projects from Bitbucket.org and login to your GitLab instance with your
Bitbucket.org account
- [CAS](cas.md) Configure GitLab to sign in using CAS
- [External issue tracker](external-issue-tracker.md) Redmine, JIRA, etc.
- [Gmail actions buttons](gmail_action_buttons_for_gitlab.md) Adds GitLab actions to messages
- [JIRA](../user/project/integrations/jira.md) Integrate with the JIRA issue tracker
- [LDAP](ldap.md) Set up sign in via LDAP
- [OAuth2 provider](oauth_provider.md) OAuth2 application creation
- [OmniAuth](omniauth.md) Sign in via Twitter, GitHub, GitLab.com, Google, Bitbucket, Facebook, Shibboleth, SAML, Crowd, Azure and Authentiq ID
- [OpenID Connect](openid_connect_provider.md) Use GitLab as an identity provider
- [PlantUML](../administration/integration/plantuml.md) Configure PlantUML to use diagrams in AsciiDoc documents.
- [reCAPTCHA](recaptcha.md) Configure GitLab to use Google reCAPTCHA for new users
- [SAML](saml.md) Configure GitLab as a SAML 2.0 Service Provider
- [Trello](trello_power_up.md) Integrate Trello with GitLab

> GitLab Enterprise Edition contains [advanced Jenkins support][jenkins].

## Project services

Integration with services such as Campfire, Flowdock, Gemnasium, HipChat,
Pivotal Tracker, and Slack are available in the form of a [Project Service][].

[Project Service]: ../user/project/integrations/project_services.md

## SSL certificate errors

When trying to integrate GitLab with services that are using self-signed certificates,
it is very likely that SSL certificate errors will occur on different parts of the
application, most likely Sidekiq. There are 2 approaches you can take to solve this:

1. Add the root certificate to the trusted chain of the OS.
1. If using Omnibus, you can add the certificate to GitLab's trusted certificates.

**OS main trusted chain**

This [resource](http://kb.kerio.com/product/kerio-connect/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html)
has all the information you need to add a certificate to the main trusted chain.

This [answer](http://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu)
at Super User also has relevant information.

**Omnibus Trusted Chain**

[Install the self signed certificate or custom certificate authorities](http://docs.gitlab.com/omnibus/common_installation_problems/README.html#using-self-signed-certificate-or-custom-certificate-authorities)
in to GitLab Omnibus.

It is enough to concatenate the certificate to the main trusted certificate
however it may be overwritten during upgrades:

```bash
cat jira.pem >> /opt/gitlab/embedded/ssl/certs/cacert.pem
```

After that restart GitLab with:

```bash
sudo gitlab-ctl restart
```

[jenkins]: http://docs.gitlab.com/ee/integration/jenkins.html
