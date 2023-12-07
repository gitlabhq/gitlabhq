---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Pipeline security

## Secrets Management

Secrets management is the systems that developers use to securely store sensitive data
in a secure environment with strict access controls. A **secret** is a sensitive credential
that should be kept confidential, and includes:

- Passwords.
- SSH keys.
- Access tokens.
- Any other types of credentials where exposure would be harmful to an organization.

## Secrets storage

### Secrets management providers

Secrets that are the most sensitive and under the strictest policies should be stored
in a secrets management. [Vault](https://www.vaultproject.io) is one provider in this space.
When using Vault, secrets are stored outside of the GitLab instance.

You can use the GitLab [Vault integration](../secrets/index.md#use-vault-secrets-in-a-ci-job)
to retrieve those secrets in CI/CD pipelines when they are needed.

### CI/CD variables

[CI/CD Variables](../variables/index.md) are a convenient way to store and use data
in a CI/CD pipeline, but variables are less secure than secrets management providers.
Variable values:

- Are stored in the GitLab project, group, or instance settings. Users with access
  to the settings have access to the variables.
- Can be [overridden](../variables/index.md#override-a-defined-cicd-variable),
  making it hard to determine which value was used.
- Can be exposed by accidental pipeline misconfiguration.

Sensitive data should be stored in a secrets management solution. If there is low
sensitivity data that you want to store in a CI/CD variable, be sure to always:

- [Mask the variables](../variables/index.md#mask-a-cicd-variable).
- [Protect the variables](../variables/index.md#protect-a-cicd-variable) when possible.
