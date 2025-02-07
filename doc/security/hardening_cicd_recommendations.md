---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hardening - CI/CD Recommendations
---

General hardening guidelines and philosophies are outlined in the [main hardening documentation](hardening.md).

The hardening recommendations and concepts for CI/CD are listed below.

## Basic Recommendations

How you configure the different CI/CD settings depends on your use of CI/CD. For example if you are using it to build
packages, you often need real-time access to external resources such as Docker
images or external code repositories. If you are using it for Infrastructure
as Code (IaC), you often need to store credentials for external systems to
automate deployment. For these and many other scenarios, you need to store
potentially sensitive information to be used during CI/CD operations. As the
individual scenarios themselves are numerous, we have summarized some basic
information to help harden the CI/CD process.

- **Secrets Management**. Passwords, tokens, keys, and other secrets that require any
  level of protection should never be stored in plaintext. Some type of encrypted
  container technology should be used, such as GCP Secret Manager, AWS KMS, or
  HashiCorp Vault. For self-managed and standalone instances, HashiCorp Vault is
  recommended, and many GitLab features can take advantage of Vault and are well
  documented in the main [Documentation](../index.md). For detailed CI/CD examples, see [using external secrets in CI](../ci/secrets/_index.md).
- **External Communications**. If your CI/CD process requires connectivity to other
  hosts, ensure that these communication channels are encrypted. You should use TLS 1.2 or 1.3, and where possible implement mutual TLS.
- **Logging**. Logging can be very important for auditing and troubleshooting, so it
  is important that you enable any logging features to ensure you are getting
  the information in logs you need. Make sure through periodic testing that
  plaintext secrets or other sensitive information is not inadvertently added to log
  files.

## Specific Recommendations

### Pipelines

Pipelines are a part of jobs that execute steps in stages to automate tasks on behalf
of the users of a project. They are a core component of CD/CD.

By default, only the default branch gets a protected pipeline. An owner of a project
can ensure that other branches are protected by
[configuring a protected branch](../user/project/repository/branches/protected.md).
This allows for more restricted security on pipelines. For more information, see
[pipeline security on a protected branch](../ci/pipelines/_index.md#pipeline-security-on-protected-branches).

Deployment is the part of the CI/CD that deploys the results of the pipeline in
relationship to a given environment. Default settings do not impose many
restrictions, and as different users with different roles and responsibilities can
trigger pipelines that can interact with those environments, you should
restrict these environments. For more information, see
[protected environments](../ci/environments/protected_environments.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
