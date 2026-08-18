---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Apprenez à utiliser les secrets Azure Key Vault dans les pipelines CI/CD GitLab
title: Utiliser les secrets Azure Key Vault dans GitLab CI/CD
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/271271) dans GitLab et GitLab Runner 16.3. En raison du [ticket 424746](https://gitlab.com/gitlab-org/gitlab/-/issues/424746), cette fonctionnalité ne fonctionnait pas comme prévu.
- [Le ticket 424746](https://gitlab.com/gitlab-org/gitlab/-/issues/424746) a été résolu et cette fonctionnalité est désormais disponible de manière générale dans GitLab Runner 16.6.

{{< /history >}}

Vous pouvez utiliser des secrets stockés dans [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/) dans vos pipelines CI/CD GitLab.

Prérequis :

- Disposer d'un [Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) sur Azure.
  - Votre utilisateur IAM doit se voir [attribuer le rôle **Key Vault Administrator**](https://learn.microsoft.com/en-us/azure/role-based-access-control/quickstart-assign-role-user-portal#grant-access) pour le **resource group** assigné au Key Vault. Dans le cas contraire, vous ne pourrez pas créer de secrets dans le Key Vault.
- [Configurez OpenID Connect dans Azure pour récupérer des identifiants temporaires](../cloud_services/azure/_index.md). Ces étapes comprennent des instructions sur la création d'une application Azure AD pour l'accès au Key Vault.
- Ajoutez des [variables CI/CD à votre projet](../variables/_index.md#for-a-project) pour fournir des informations sur votre serveur Vault :
  - `AZURE_KEY_VAULT_SERVER_URL` : L'URL de votre serveur Azure Key Vault, par exemple `https://vault.example.com`.
  - `AZURE_CLIENT_ID` : L'ID client de l'application Azure.
  - `AZURE_TENANT_ID` : L'ID de tenant de l'application Azure.

## Utiliser les secrets Azure Key Vault dans un job CI/CD {#use-azure-key-vault-secrets-in-a-cicd-job}

Vous pouvez utiliser un secret stocké dans votre Azure Key Vault dans un job en le définissant avec le mot-clé [`azure_key_vault`](../yaml/_index.md#secretsazure_key_vault) :

```yaml
job:
  id_tokens:
    AZURE_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'DATABASE-PASSWORD'
        version: '00000000000000000000000000000000'
```

Pour utiliser plusieurs secrets d'Azure Key Vault dans le même job, définissez chaque secret sous le mot-clé `secrets` :

```yaml
job:
  id_tokens:
    AZURE_JWT:
      aud: 'https://gitlab.com'
  secrets:
    REDIS_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'REDIS-PASSWORD'
        version: '00000000000000000000000000000000'
    DATABASE_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'DATABASE-PASSWORD'
        version: '00000000000000000000000000000000'
```

Dans ces exemples :

- `aud` est l'audience, qui doit correspondre à l'audience utilisée lors de la [création des identifiants d'identité fédérée](../cloud_services/azure/_index.md#create-entra-id-federated-identity-credentials)
- `name` est le nom du secret dans Azure Key Vault.
- `version` est la version du secret dans Azure Key Vault. La version est un GUID généré sans tirets, que vous pouvez trouver sur la page des secrets Azure Key Vault.
- GitLab récupère le secret depuis Azure Key Vault et stocke la valeur dans un fichier temporaire. Le chemin vers ce fichier est stocké dans une variable CI/CD portant le nom que vous avez défini sous secrets (par exemple `DATABASE_PASSWORD` ou `REDIS_PASSWORD`), de manière similaire aux [variables CI/CD de type fichier](../variables/_index.md#use-file-type-cicd-variables).

## Dépannage {#troubleshooting}

Consultez la page [Dépannage OIDC pour Azure](../cloud_services/azure/_index.md#troubleshooting) pour les problèmes généraux liés à la configuration d'OIDC avec Azure.

### Message `JWT token is invalid or malformed` {#jwt-token-is-invalid-or-malformed-message}

Vous pouvez recevoir cette erreur lors de la récupération de secrets depuis Azure Key Vault :

```plaintext
RESPONSE 400 Bad Request
AADSTS50027: JWT token is invalid or malformed.
```

Cela se produit en raison d'un [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/424746) dans GitLab Runner où le jeton JWT n'est pas analysé correctement. Pour résoudre ce problème, mettez à niveau vers GitLab Runner 16.6 ou une version ultérieure.

### Message `Caller is not authorized to perform action on resource` {#caller-is-not-authorized-to-perform-action-on-resource-message}

Vous pouvez recevoir cette erreur lors de la récupération de secrets depuis Azure Key Vault :

```plaintext
RESPONSE 403: 403 Forbidden
ERROR CODE: Forbidden
Caller is not authorized to perform action on resource.\r\nIf role assignments, deny assignments or role definitions were changed recently, please observe propagation time.
ForbiddenByRbac
```

Si votre Azure Key Vault utilise RBAC, vous devez ajouter l'attribution de rôle **Key Vault Secrets User** à votre application Azure AD.

Par exemple :

```shell
appId=$(az ad app list --display-name gitlab-oidc --query '[0].appId' -otsv)
az role assignment create --assignee $appId --role "Key Vault Secrets User" --scope /subscriptions/<subscription-id>
```

Vous pouvez trouver votre ID d'abonnement dans :

- Le [portail Azure](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription).
- L'[interface CLI Azure](https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#get-the-active-subscription).

### Message `The secrets provider can not be found. Check your CI/CD variables and try again.` {#the-secrets-provider-can-not-be-found-check-your-cicd-variables-and-try-again-message}

Vous pouvez recevoir cette erreur lorsque vous tentez de démarrer un job configuré pour accéder à Azure Key Vault :

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

Le job ne peut pas être créé car une ou plusieurs des variables requises ne sont pas définies :

- `AZURE_KEY_VAULT_SERVER_URL`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
