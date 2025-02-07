---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure OpenID Connect in Azure to retrieve temporary credentials
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
`CI_JOB_JWT_V2` was [deprecated in GitLab 15.9](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)
and is scheduled to be removed in GitLab 17.0. Use [ID tokens](../../yaml/_index.md#id_tokens) instead.

This tutorial demonstrates how to use a JSON web token (JWT) in a GitLab CI/CD job
to retrieve temporary credentials from Azure without needing to store secrets.

To get started, configure OpenID Connect (OIDC) for identity federation between GitLab and Azure.
For more information on using OIDC with GitLab, read [Connect to cloud services](../_index.md).

Prerequisites:

- Access to an existing Azure Subscription with `Owner` access level.
- Access to the corresponding Azure Active Directory Tenant with at least the `Application Developer` access level.
- A local installation of the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).
  Alternatively, you can follow all the steps below with the [Azure Cloud Shell](https://portal.azure.com/#cloudshell/).
- Your GitLab instance must be publicly accessible over the internet as Azure must to connect to the GitLab OIDC endpoint.
- A GitLab project.

To complete this tutorial:

1. [Create Azure AD application and service principal](#create-azure-ad-application-and-service-principal).
1. [Create Azure AD federated identity credentials](#create-azure-ad-federated-identity-credentials).
1. [Grant permissions for the service principal](#grant-permissions-for-the-service-principal).
1. [Retrieve a temporary credential](#retrieve-a-temporary-credential).

For more information about Azure identity federation, see [workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation).

## Create Azure AD application and service principal

To create an [Azure AD application](https://learn.microsoft.com/en-us/cli/azure/ad/app?view=azure-cli-latest#az-ad-app-create)
and service principal:

1. In the Azure CLI, create the AD application:

   ```shell
   appId=$(az ad app create --display-name gitlab-oidc --query appId -otsv)
   ```

   Save the `appId` (Application client ID) output, as you need it later
   to configure your GitLab CI/CD pipeline.

1. Create a corresponding [Service Principal](https://learn.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create):

   ```shell
   az ad sp create --id $appId --query appId -otsv
   ```

Instead of the Azure CLI, you can [use the Azure Portal to create these resources](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal).

## Create Azure AD federated identity credentials

To create the federated identity credentials for the above Azure AD application
for a specific branch in `<mygroup>/<myproject>`:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": "project_path:<mygroup>/<myproject>:ref_type:branch:ref:<branch>",
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

For issues related to the values of `issuer`, `subject` or `audiences`, see the
[troubleshooting](#troubleshooting) details.

Optionally, you can now verify the Azure AD application and the Azure AD federated
identity credentials from the Azure Portal:

1. Open the [Azure Active Directory App Registration](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
   view and select the appropriate app registration by searching for the display name `gitlab-oidc`.
1. On the overview page you can verify details like the `Application (client) ID`,
   `Object ID`, and `Tenant ID`.
1. Under `Certificates & secrets`, go to `Federated credentials` to review your
   Azure AD federated identity credentials.

### Create credentials for any branch or any tag

To create credentials for any branch or tag (wildcard matching), you can use
[flexible federated identity credentials](https://learn.microsoft.com/entra/workload-id/workload-identities-flexible-federated-identity-credentials).

For all branches in `<mygroup>/<myproject>`:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": null,
  "claimsMatchingExpression": {
    "value": "claims['sub'] matches 'project_path:<mygroup>/<myproject>:ref_type:branch:ref:*'",
    "languageVersion": 1
  },
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

For all tags in `<mygroup>/<myproject>`:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": null,
  "claimsMatchingExpression": {
    "value": "claims['sub'] matches 'project_path:<mygroup>/<myproject>:ref_type:tag:ref:*'",
    "languageVersion": 1
  },
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

## Grant permissions for the service principal

After you create the credentials, use [`role assignment`](https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create)
to grant permissions to the above service principal to access to Azure resources:

```shell
az role assignment create --assignee $appId --role Reader --scope /subscriptions/<subscription-id>
```

You can find your subscription ID in:

- The [Azure Portal](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription).
- The [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#get-the-active-subscription).

The command above grants read-only permissions to the entire subscription. For more information on applying the principle of least privilege in the context of your organization, read [Best practices for Azure AD roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices).

## Retrieve a temporary credential

After you configure the Azure AD application and federated identity credentials,
the CI/CD job can retrieve a temporary credential by using the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login):

```yaml
default:
  image: mcr.microsoft.com/azure-cli:latest

variables:
  AZURE_CLIENT_ID: "<client-id>"
  AZURE_TENANT_ID: "<tenant-id>"

auth:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.com
  script:
    - az login --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID --federated-token $GITLAB_OIDC_TOKEN
    - az account show
```

The CI/CD variables are:

- `AZURE_CLIENT_ID`: The [application client ID you saved earlier](#create-azure-ad-application-and-service-principal).
- `AZURE_TENANT_ID`: Your Azure Active Directory. You can
  [find it by using the Azure CLI or Azure Portal](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant).
- `GITLAB_OIDC_TOKEN`: An OIDC [ID token](../../yaml/_index.md#id_tokens).

## Troubleshooting

### "No matching federated identity record found"

If you receive the error `ERROR: AADSTS70021: No matching federated identity record found for presented assertion.`
you should verify:

- The `Issuer` defined in the Azure AD federated identity credentials, for example
  `https://gitlab.com` or your own GitLab URL.
- The `Subject identifier` defined in the Azure AD federated identity credentials,
  for example `project_path:<mygroup>/<myproject>:ref_type:branch:ref:<branch>`.
  - For the `gitlab-group/gitlab-project` project and `main` branch it would be:
    `project_path:gitlab-group/gitlab-project:ref_type:branch:ref:main`.
  - The correct values of `mygroup` and `myproject` can be retrieved by checking the URL
    when accessing your GitLab project or, in the upper-right corner of the project's overview page, selecting **Code**.
- The `Audience` defined in the Azure AD federated identity credentials, for example `https://gitlab.com`
  or your own GitLab URL.

You can review these settings, as well as your `AZURE_CLIENT_ID` and `AZURE_TENANT_ID`
CI/CD variables, from the Azure Portal:

1. Open the [Azure Active Directory App Registration](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
   view and select the appropriate app registration by searching for the display name `gitlab-oidc`.
1. On the overview page you can verify details like the `Application (client) ID`,
   `Object ID`, and `Tenant ID`.
1. Under `Certificates & secrets`, go to `Federated credentials` to review your
   Azure AD federated identity credentials.

Review [Connect to cloud services](../_index.md) for further details.

### `Request to External OIDC endpoint failed` message

If you receive the error `ERROR: AADSTS501661: Request to External OIDC endpoint failed.`
you should verify that your GitLab instance is publicly accessible from the internet.

Azure must be able to access the following GitLab endpoints to authenticate with OIDC:

- `GET /.well-known/openid-configuration`
- `GET /oauth/discovery/keys`

If you update your firewall and still receive this error, [clear the Redis cache](../../../administration/raketasks/maintenance.md#clear-redis-cache)
and try again.

### `No matching federated identity record found for presented assertion audience` message

If you receive the error `ERROR: AADSTS700212: No matching federated identity record found for presented assertion audience 'https://gitlab.com'`
you should verify that your CI/CD job uses the correct `aud` value.

The `aud` value should match the audience used to [create the federated identity credentials](#create-azure-ad-federated-identity-credentials).
