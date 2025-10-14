---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use external secrets in CI/CD
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD jobs might need sensitive information, called secrets, to complete work.
This sensitive information could be items like API tokens, database credentials, or private keys.
Secrets are sourced from a secrets provider.

Unlike CI/CD variables which are always available in jobs, secrets must be explicitly
requested by a job.

GitLab supports several secret management providers, including:

1. [HashiCorp Vault](hashicorp_vault.md)
1. [Google Cloud Secret Manager](gcp_secret_manager.md)
1. [Azure Key Vault](azure_key_vault.md)
1. [AWS Secrets Manager](aws_secrets_manager.md)

These integrations use [ID tokens](id_token_authentication.md) for authentication.
You can also use ID tokens to manually authenticate with any secrets provider that supports
OIDC authentication with JSON web tokens (JWT).
