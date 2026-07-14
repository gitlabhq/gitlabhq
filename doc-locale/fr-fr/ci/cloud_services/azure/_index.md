---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer OpenID Connect dans Azure pour récupérer des identifiants temporaires
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> `CI_JOB_JWT_V2` a été [déprécié dans GitLab 15.9](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) et sa suppression est prévue dans GitLab 17.0. Utilisez plutôt les [jetons d'ID](../../secrets/id_token_authentication.md).

Ce tutoriel explique comment utiliser un JSON web token (JWT) dans un job GitLab CI/CD pour récupérer des identifiants temporaires depuis Azure sans avoir à stocker de secrets.

Pour commencer, configurez OpenID Connect (OIDC) pour la fédération d'identité entre GitLab et Azure. Pour plus d'informations sur l'utilisation d'OIDC avec GitLab, consultez [Se connecter aux services cloud](../_index.md).

Prérequis :

- Accès à un abonnement Azure existant avec le niveau d'accès `Owner`.
- Accès au tenant Microsoft Entra ID correspondant avec au moins le niveau d'accès `Application Developer`.
- Une installation locale de l'[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli). Vous pouvez également effectuer toutes les étapes suivantes avec [Azure Cloud Shell](https://portal.azure.com/#cloudshell/).
- Votre instance GitLab doit être accessible publiquement sur Internet, car Azure doit se connecter au point de terminaison OIDC de GitLab.
- Un projet GitLab.

Pour suivre ce tutoriel :

1. [Créer une application Entra ID et un principal de service](#create-an-entra-id-application-and-service-principal).
1. [Créer des identifiants d'identité fédérée Entra ID](#create-entra-id-federated-identity-credentials).
1. [Accorder des autorisations au principal de service](#grant-permissions-for-the-service-principal).
1. [Récupérer un identifiant temporaire](#retrieve-a-temporary-credential).

Pour plus d'informations sur la fédération d'identité Azure, consultez [la fédération d'identité de charge de travail](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation).

## Créer une application Entra ID et un principal de service {#create-an-entra-id-application-and-service-principal}

Pour créer une [application Entra ID](https://learn.microsoft.com/en-us/cli/azure/ad/app?view=azure-cli-latest#az-ad-app-create) et un principal de service pour GitLab :

1. Dans l'Azure CLI, créez l'application pour GitLab :

   ```shell
   appId=$(az ad app create --display-name gitlab-oidc --query appId -otsv)
   ```

   Enregistrez la sortie `appId` (ID client de l'application), car vous en aurez besoin ultérieurement pour configurer votre pipeline CI/CD GitLab.

1. Créez un [principal de service](https://learn.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create) correspondant :

   ```shell
   az ad sp create --id $appId --query appId -otsv
   ```

Au lieu de l'Azure CLI, vous pouvez [utiliser le portail Azure pour créer ces ressources](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal).

## Créer des identifiants d'identité fédérée Entra ID {#create-entra-id-federated-identity-credentials}

Pour créer les identifiants d'identité fédérée pour l'application Entra ID précédente pour une branche spécifique dans `<mygroup>/<myproject>` :

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

Pour les problèmes liés aux valeurs de `issuer`, `subject` ou `audiences`, consultez les détails de [dépannage](#troubleshooting).

Vous pouvez également vérifier l'application Entra ID et les identifiants d'identité fédérée Entra ID depuis le portail Azure :

1. Ouvrez la vue [Microsoft Entra ID App Registration](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps) et sélectionnez l'inscription d'application appropriée en recherchant le nom d'affichage `gitlab-oidc`.
1. Sur la page de présentation, vous pouvez vérifier des détails tels que `Application (client) ID`, `Object ID` et `Tenant ID`.
1. Sous `Certificates & secrets`, accédez à `Federated credentials` pour consulter vos identifiants d'identité fédérée Entra ID.

### Créer des identifiants pour n'importe quelle branche ou n'importe quel tag {#create-credentials-for-any-branch-or-any-tag}

Pour créer des identifiants pour n'importe quelle branche ou tag (correspondance générique), vous pouvez utiliser les [identifiants d'identité fédérée flexibles](https://learn.microsoft.com/entra/workload-id/workload-identities-flexible-federated-identity-credentials).

Pour toutes les branches dans `<mygroup>/<myproject>` :

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

Pour tous les tags dans `<mygroup>/<myproject>` :

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

## Accorder des autorisations au principal de service {#grant-permissions-for-the-service-principal}

Après avoir créé les identifiants, utilisez [`role assignment`](https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create) pour accorder des autorisations au principal de service précédent afin qu'il puisse accéder aux ressources Azure :

```shell
az role assignment create --assignee $appId --role Reader --scope /subscriptions/<subscription-id>
```

Vous pouvez trouver votre ID d'abonnement dans :

- Le [portail Azure](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription).
- L'[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#get-the-active-subscription).

La commande précédente accorde des autorisations en lecture seule à l'ensemble de l'abonnement. Pour plus d'informations sur l'application du principe du moindre privilège dans le contexte de votre organisation, consultez [Meilleures pratiques pour les rôles Entra ID](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices).

## Récupérer un identifiant temporaire {#retrieve-a-temporary-credential}

Après avoir configuré l'application Entra ID et les identifiants d'identité fédérée, le job CI/CD peut récupérer un identifiant temporaire en utilisant l'[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login) :

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

Les variables CI/CD sont :

- `AZURE_CLIENT_ID` : L'[ID client de l'application que vous avez enregistré précédemment](#create-an-entra-id-application-and-service-principal).
- `AZURE_TENANT_ID` : L'ID de votre tenant Microsoft Entra ID. Vous pouvez [le trouver en utilisant l'Azure CLI ou le portail Azure](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant).
- `GITLAB_OIDC_TOKEN` : Un [jeton d'ID](../../secrets/id_token_authentication.md) OIDC.

## Dépannage {#troubleshooting}

### Erreur : `No matching federated identity record found` {#error-no-matching-federated-identity-record-found}

Si vous recevez l'erreur `ERROR: AADSTS70021: No matching federated identity record found for presented assertion.`, vérifiez les éléments suivants :

- L'`Issuer` défini dans les identifiants d'identité fédérée Entra ID, par exemple `https://gitlab.com` ou l'URL de votre propre instance GitLab.
- Le `Subject identifier` défini dans les identifiants d'identité fédérée Entra ID, par exemple `project_path:<mygroup>/<myproject>:ref_type:branch:ref:<branch>`.
  - Pour le projet `gitlab-group/gitlab-project` et la branche `main`, la valeur serait : `project_path:gitlab-group/gitlab-project:ref_type:branch:ref:main`.
  - Les valeurs correctes de `mygroup` et `myproject` peuvent être récupérées en vérifiant l'URL lors de l'accès à votre projet GitLab ou, dans le coin supérieur droit de la page de présentation du projet, en sélectionnant **Code**.
- L'`Audience` défini dans les identifiants d'identité fédérée Entra ID, par exemple `https://gitlab.com` ou l'URL de votre propre instance GitLab.

Vous pouvez consulter ces paramètres, ainsi que vos variables CI/CD `AZURE_CLIENT_ID` et `AZURE_TENANT_ID`, depuis le portail Azure :

1. Ouvrez la vue [Microsoft Entra ID App Registration](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps) et sélectionnez l'inscription d'application appropriée en recherchant le nom d'affichage `gitlab-oidc`.
1. Sur la page de présentation, vous pouvez vérifier des détails tels que `Application (client) ID`, `Object ID` et `Tenant ID`.
1. Sous `Certificates & secrets`, accédez à `Federated credentials` pour consulter vos identifiants d'identité fédérée Entra ID.

Consultez [Se connecter aux services cloud](../_index.md) pour plus de détails.

### Message `Request to External OIDC endpoint failed` {#request-to-external-oidc-endpoint-failed-message}

Si vous recevez l'erreur `ERROR: AADSTS501661: Request to External OIDC endpoint failed.`, vérifiez que votre instance GitLab est accessible publiquement depuis Internet.

Azure doit pouvoir accéder aux points de terminaison GitLab suivants pour s'authentifier avec OIDC :

- `GET /.well-known/openid-configuration`
- `GET /oauth/discovery/keys`

Si vous mettez à jour votre pare-feu et que vous recevez toujours cette erreur, [videz le cache Redis](../../../administration/raketasks/maintenance.md#clear-redis-cache) et réessayez.

### Message `No matching federated identity record found for presented assertion audience` {#no-matching-federated-identity-record-found-for-presented-assertion-audience-message}

Si vous recevez l'erreur `ERROR: AADSTS700212: No matching federated identity record found for presented assertion audience 'https://gitlab.com'`, vérifiez que votre job CI/CD utilise la valeur `aud` correcte.

La valeur `aud` doit correspondre à l'audience utilisée pour [créer les identifiants d'identité fédérée](#create-entra-id-federated-identity-credentials).
