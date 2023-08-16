---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: concepts, howto
---

# Use Azure Key Vault secrets in GitLab CI/CD **(PREMIUM ALL)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/271271) in GitLab and GitLab Runner 16.3.

You can use secrets stored in the [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)
in your GitLab CI/CD pipelines.

Prerequisites:

- Have a key vault on Azure.
- Have an application with key vault permissions.
- [Configure OpenID Connect in Azure to retrieve temporary credentials](../../ci/cloud_services/azure/index.md).
- Add [CI/CD variables to your project](../variables/index.md#for-a-project) to provide details about your Vault server:
  - `AZURE_KEY_VAULT_SERVER_URL`: The URL of your Azure Key Vault server, such as `https://vault.example.com`.
  - `AZURE_CLIENT_ID`: The client ID of the Azure application.
  - `AZURE_TENANT_ID`: The tenant ID of the Azure application.

## Use Azure Key Vault secrets in a CI/CD job

You can use a secret stored in your Azure Key Vault in a job by defining it with the
[`azure_key_vault`](../yaml/index.md#secretsazure_key_vault) keyword:

```yaml
job:
  id_tokens:
    AZURE_JWT:
      aud: 'azure'
  secrets:
    DATABASE_PASSWORD:
      token: AZURE_JWT
      azure_key_vault:
        name: 'test'
        version: 'test'
```

In this example:

- `name` is the name of the secret.
- `version` is the version of the secret.
- GitLab fetches the secret from Azure Key Vault and stores the value in a temporary file.
  The path to this file is stored in a `DATABASE_PASSWORD` CI/CD variable, similar to
  [file type CI/CD variables](../variables/index.md#use-file-type-cicd-variables).
