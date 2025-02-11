---
stage: Foundations
group: Import and Integrate
description: Projects, issues, authentication, security providers.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Integrate with GitLab
---

You can integrate GitLab with external applications for enhanced functionality.

## Project integrations

Applications like Jenkins, Jira, and Slack are available as [project integrations](../user/project/integrations/_index.md).

## Issue trackers

You can configure an [external issue tracker](external-issue-tracker.md) and use:

- The external issue tracker with the GitLab issue tracker
- The external issue tracker only

## Authentication providers

You can integrate GitLab with authentication providers like LDAP and SAML.

For more information, see [GitLab authentication and authorization](../administration/auth/_index.md).

## Security improvements

Solutions like Akismet and reCAPTCHA are available for spam protection.

You can also integrate GitLab with the following security partners:

<!-- vale gitlab_base.Spelling = NO -->

- [Anchore](https://docs.anchore.com/current/docs/integration/ci_cd/gitlab/)
- [Prisma Cloud](https://docs.prismacloud.io/en/enterprise-edition/content-collections/application-security/get-started/connect-code-and-build-providers/code-repositories/add-gitlab)
- [Checkmarx](https://checkmarx.atlassian.net/wiki/spaces/SD/pages/1929937052/GitLab+Integration)
- [CodeSecure](https://codesecure.com/our-integrations/codesonar-sast-gitlab-ci-pipeline/)
- [Deepfactor](https://www.deepfactor.io/docs/integrate-deepfactor-scanner-in-your-ci-cd-pipelines/#gitlab)
- [Fortify](https://www.microfocus.com/en-us/fortify-integrations/gitlab)
- [Indeni](https://docs.cloudrail.app/#/integrations/gitlab)
- [Jscrambler](https://docs.jscrambler.com/code-integrity/documentation/gitlab-ci-integration)
- [Mend](https://www.mend.io/gitlab/)
- [Semgrep](https://semgrep.dev/for/gitlab/)
- [StackHawk](https://docs.stackhawk.com/continuous-integration/gitlab/)
- [Tenable](https://docs.tenable.com/vulnerability-management/Content/vulnerability-management/VulnerabilityManagementOverview.htm)
- [Venafi](https://marketplace.venafi.com/xchange/620d2d6ed419fb06a5c5bd36/solution/6292c2ef7550f2ee553cf223)
- [Veracode](https://docs.veracode.com/r/c_integration_buildservs#gitlab)

<!-- vale gitlab_base.Spelling = YES -->

GitLab can check your application for security vulnerabilities.
For more information, see [Secure your application](../user/application_security/secure_your_application.md).

## Troubleshooting

When working with integrations, you might encounter the following issues.

### SSL certificate errors

When you use a self-signed certificate to integrate GitLab with external applications, you might
encounter SSL certificate errors in different parts of GitLab.

As a workaround, do one of the following:

- Add the certificate to the OS trusted chain. For more information, see:
  - [Adding trusted root certificates to the server](https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html)
  - [How do you add a certificate authority (CA) to Ubuntu?](https://superuser.com/questions/437330/how-do-you-add-a-certificate-authority-ca-to-ubuntu)
- For installations that use the Linux package, add the certificate to the GitLab trusted chain:
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

### Error: `Test Failed. Save Anyway`

When you configure an integration on an uninitialized repository, the integration might fail with
a `Test Failed. Save Anyway` error. This error occurs because the integration uses push data
to build the test payload when the project does not have push events.

To resolve this issue, initialize the repository by pushing a test file to the project
and configure the integration again.
