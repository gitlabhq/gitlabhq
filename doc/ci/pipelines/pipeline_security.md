---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pipeline security
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Secrets Management

Secrets management is the systems that developers use to securely store sensitive data
in a secure environment with strict access controls. A **secret** is a sensitive credential
that should be kept confidential. Examples of a secret include:

- Passwords
- SSH keys
- Access tokens
- Any other types of credentials where exposure would be harmful to an organization

## Secrets storage

### Secrets management providers

Secrets that are the most sensitive and under the strictest policies should be stored
in a secrets manager. When using a secrets manager solution, secrets are stored outside
of the GitLab instance. There are a number of providers in this space, including
[HashiCorp's Vault](https://www.vaultproject.io), [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault),
and [Google Cloud Secret Manager](https://cloud.google.com/security/products/secret-manager).

You can use the GitLab native integrations for certain [external secret management providers](../secrets/_index.md) to retrieve those secrets in CI/CD pipelines when they are needed.

### CI/CD variables

[CI/CD Variables](../variables/_index.md) are a convenient way to store and reuse data
in a CI/CD pipeline, but variables are less secure than secrets management providers.
Variable values:

- Are stored in the GitLab project, group, or instance settings. Users with access
  to the settings have access to variables values that are not [hidden](../variables/_index.md#hide-a-cicd-variable).
- Can be [overridden](../variables/_index.md#use-pipeline-variables),
  making it hard to determine which value was used.
- Can be exposed by accidental pipeline misconfiguration.

Information suitable for storage in a variable should be data that can be exposed without risk of exploitation (non-sensitive).

Sensitive data should be stored in a secrets management solution. If there is low
sensitivity data that you want to store in a CI/CD variable, be sure to always:

- [Mask the variables](../variables/_index.md#mask-a-cicd-variable)
  or [Mask and hide the variable](../variables/_index.md#hide-a-cicd-variable).
- [Protect the variables](../variables/_index.md#protect-a-cicd-variable) when possible.
- [Hide the variables](../variables/_index.md#hide-a-cicd-variable) when possible.
