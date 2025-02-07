---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Azure Key Vault secrets in GitLab CI/CD
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/271271) in GitLab and GitLab Runner 16.3. Due to [issue 424746](https://gitlab.com/gitlab-org/gitlab/-/issues/424746) this feature did not work as expected.
> - [Issue 424746](https://gitlab.com/gitlab-org/gitlab/-/issues/424746) resolved and this feature made generally available in GitLab Runner 16.6.

You can use secrets stored in the [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)
in your GitLab CI/CD pipelines.

Prerequisites:

- Have a [Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) on Azure.
  - Your IAM user must be [granted the **Key Vault Administrator** role assignment](https://learn.microsoft.com/en-us/azure/role-based-access-control/quickstart-assign-role-user-portal#grant-access)
    for the **resource group** assigned to the Key Vault. Otherwise, you can't create secrets inside the Key Vault.
- [Configure OpenID Connect in Azure to retrieve temporary credentials](../cloud_services/azure/_index.md). These
  steps include instructions on how to create an Azure AD application for Key Vault access.
- Add [CI/CD variables to your project](../variables/_index.md#for-a-project) to provide details about your Vault server:
  - `AZURE_KEY_VAULT_SERVER_URL`: The URL of your Azure Key Vault server, such as `https://vault.example.com`.
  - `AZURE_CLIENT_ID`: The client ID of the Azure application.
  - `AZURE_TENANT_ID`: The tenant ID of the Azure application.

## Use Azure Key Vault secrets in a CI/CD job

You can use a secret stored in your Azure Key Vault in a job by defining it with the
[`azure_key_vault`](../yaml/_index.md#secretsazure_key_vault) keyword:

```yaml
job:
  id_tokens:
    AZURE_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'test'
        version: '00000000000000000000000000000000'
```

In this example:

- `aud` is the audience, which must match the audience used when [creating the federated identity credentials](../cloud_services/azure/_index.md#create-azure-ad-federated-identity-credentials)
- `name` is the name of the secret in Azure Key Vault.
- `version` is the version of the secret in Azure Key Vault. The version is a generated
  GUID without dashes, which can be found on the Azure Key Vault secrets page.
- GitLab fetches the secret from Azure Key Vault and stores the value in a temporary file.
  The path to this file is stored in a `DATABASE_PASSWORD` CI/CD variable, similar to
  [file type CI/CD variables](../variables/_index.md#use-file-type-cicd-variables).

## Troubleshooting

Refer to [OIDC for Azure troubleshooting](../cloud_services/azure/_index.md#troubleshooting) for general
problems when setting up OIDC with Azure.

### `JWT token is invalid or malformed` message

You might receive this error when fetching secrets from Azure Key Vault:

```plaintext
RESPONSE 400 Bad Request
AADSTS50027: JWT token is invalid or malformed.
```

This occurs due to a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424746) in GitLab Runner where the JWT token isn't parsed correctly.
To resolve this, upgrade to GitLab Runner 16.6 or later.

### `Caller is not authorized to perform action on resource` message

You might receive this error when fetching secrets from Azure Key Vault:

```plaintext
RESPONSE 403: 403 Forbidden
ERROR CODE: Forbidden
Caller is not authorized to perform action on resource.\r\nIf role assignments, deny assignments or role definitions were changed recently, please observe propagation time.
ForbiddenByRbac
```

If your Azure Key Vault is using RBAC, you must add the **Key Vault Secrets User** role assignment to your Azure AD
application.

For example:

```shell
appId=$(az ad app list --display-name gitlab-oidc --query '[0].appId' -otsv)
az role assignment create --assignee $appId --role "Key Vault Secrets User" --scope /subscriptions/<subscription-id>
```

You can find your subscription ID in:

- The [Azure Portal](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription).
- The [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#get-the-active-subscription).

### `The secrets provider can not be found. Check your CI/CD variables and try again.` message

You might receive this error when attempting to start a job configured to access Azure Key Vault:

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

The job can't be created because one or more of the required variables are not defined:

- `AZURE_KEY_VAULT_SERVER_URL`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
