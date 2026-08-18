---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer OpenID Connect avec GCP Workload Identity Federation
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> `CI_JOB_JWT_V2` a été [dépréciée dans GitLab 15.9](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) et est prévue pour suppression dans GitLab 17.0. Utilisez plutôt les [jetons d'ID](../../secrets/id_token_authentication.md).

Ce tutoriel montre comment s'authentifier auprès de Google Cloud depuis un job GitLab CI/CD en utilisant un jeton JSON Web Token (JWT) et Workload Identity Federation. Cette configuration génère des identifiants temporaires à la demande sans avoir besoin de stocker des secrets.

Pour commencer, configurez OpenID Connect (OIDC) pour la fédération d'identité entre GitLab et Google Cloud. Pour plus d'informations sur l'utilisation d'OIDC avec GitLab, lisez [Se connecter aux services cloud](../_index.md).

Ce tutoriel suppose que vous disposez d'un compte Google Cloud et d'un projet Google Cloud. Votre compte doit disposer au minimum de la permission **workload identity pool Admin** sur le projet Google Cloud.

> [!note]
> Si vous préférez utiliser un module Terraform et un modèle CI/CD plutôt que ce tutoriel, consultez [How OIDC can simplify authentication of GitLab CI/CD pipelines with Google Cloud](https://about.gitlab.com/blog/introduction-of-oidc-modules-for-integration-between-google-cloud-and-gitlab-ci/).

Pour suivre ce tutoriel :

1. [Créer le pool d'identités de charge de travail Google Cloud](#create-the-google-cloud-workload-identity-pool).
1. [Créer un fournisseur d'identités de charge de travail](#create-a-workload-identity-provider).
1. [Accorder des autorisations pour l'emprunt d'identité du compte de service](#grant-permissions-for-service-account-impersonation).
1. [Récupérer un identifiant temporaire](#retrieve-a-temporary-credential).

## Créer le pool d'identités de charge de travail Google Cloud {#create-the-google-cloud-workload-identity-pool}

[Créer un nouveau pool d'identités de charge de travail Google Cloud](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_the_workload_identity_pool_and_provider) avec les options suivantes :

- **Nom** : Nom convivial pour le pool d'identités de charge de travail, par exemple `GitLab`.
- **ID du pool** : ID unique dans le projet Google Cloud pour le pool d'identités de charge de travail, par exemple `gitlab`. Cette valeur est utilisée pour faire référence au pool et apparaît dans les URL.
- **Description** : facultatif. Une description du pool.
- **Enabled Pool** : Assurez-vous que cette option est définie sur `true`.

Nous recommandons de créer un seul pool par installation GitLab et par projet Google Cloud. Si vous disposez de plusieurs dépôts GitLab et jobs CI/CD sur la même instance GitLab, ils peuvent s'authentifier à l'aide de différents fournisseurs auprès du même pool.

## Créer un fournisseur d'identités de charge de travail {#create-a-workload-identity-provider}

[Créer un nouveau fournisseur d'identités de charge de travail Google Cloud](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_the_workload_identity_pool_and_provider) au sein du pool d'identités de charge de travail créé à l'étape précédente, en utilisant les options suivantes :

- **Type de fournisseur** : OpenID Connect (OIDC).
- **Provider name** : Nom convivial pour le fournisseur d'identités de charge de travail, par exemple `gitlab/gitlab`.
- **ID du fournisseur** : ID unique dans le pool pour le fournisseur d'identités de charge de travail, par exemple `gitlab-gitlab`. Cette valeur est utilisée pour faire référence au fournisseur et apparaît dans les URL.
- **Issuer (URL)** : L'adresse de votre instance GitLab, par exemple `https://gitlab.com/` ou `https://gitlab.example.com/`.
  - L'adresse doit utiliser le protocole `https://`.
  - L'adresse doit se terminer par une barre oblique finale.
- **Audiences** : Définissez manuellement la liste des audiences autorisées sur l'adresse de votre instance GitLab, par exemple `https://gitlab.com` ou `https://gitlab.example.com`.
  - L'adresse doit utiliser le protocole `https://`.
  - L'adresse ne doit pas se terminer par une barre oblique finale.
- **Provider attributes mapping** : Créez les mappages suivants, où `attribute.X` est le nom de l'attribut à inclure comme revendication dans le jeton Google, et `assertion.X` est la valeur à extraire de la [revendication GitLab](../_index.md#id-token-authentication-for-cloud-services) :

  | Attribut (sur Google) | Assertion (depuis GitLab) |
  | --- | --- |
  | `google.subject` | `assertion.sub` |
  | `attribute.X` | `assertion.X` |

  Vous pouvez également [créer des attributs complexes](https://cloud.google.com/iam/docs/workload-identity-federation#mapping) à l'aide du langage Common Expression Language (CEL).

  Vous devez mapper chaque attribut que vous souhaitez utiliser pour l'attribution des autorisations. Par exemple, si vous souhaitez mapper des autorisations à l'étape suivante en fonction de l'adresse e-mail de l'utilisateur, vous devez mapper `attribute.user_email` sur `assertion.user_email`.

> [!warning]
> Pour les projets hébergés sur GitLab.com, GCP exige que vous [limitiez l'accès aux seuls jetons émis par votre groupe GitLab](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#gitlab-saas_2).

## Accorder des autorisations pour l'emprunt d'identité du compte de service {#grant-permissions-for-service-account-impersonation}

La création du pool d'identités de charge de travail et du fournisseur d'identités de charge de travail définit l'authentification dans Google Cloud. À ce stade, vous pouvez vous authentifier depuis un job GitLab CI/CD vers Google Cloud. Cependant, vous ne disposez d'aucune autorisation sur Google Cloud (autorisation).

Pour accorder à votre job GitLab CI/CD des autorisations sur Google Cloud, vous devez :

1. [Créer un compte de service Google Cloud](https://cloud.google.com/iam/docs/service-accounts-create). Vous pouvez utiliser le nom et l'ID de votre choix.
1. [Accorder des autorisations IAM](https://cloud.google.com/iam/docs/granting-changing-revoking-access) à votre compte de service sur les ressources Google Cloud. Ces autorisations varient considérablement selon votre cas d'utilisation. En général, accordez à ce compte de service les autorisations sur votre projet Google Cloud et les ressources que vous souhaitez que votre job GitLab CI/CD puisse utiliser. Par exemple, si vous deviez téléverser un fichier dans un bucket Google Cloud Storage dans votre job GitLab CI/CD, vous accorderiez à ce compte de service le rôle `roles/storage.objectCreator` sur votre bucket Cloud Storage.
1. [Accorder les autorisations à l'identité externe](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#impersonate) pour emprunter l'identité de ce compte de service. Cette étape permet à un job GitLab CI/CD de s'autoriser auprès de Google Cloud via l'emprunt d'identité du compte de service. Cette étape accorde une autorisation IAM sur le compte de service lui-même, donnant à l'identité externe les autorisations nécessaires pour agir en tant que ce compte de service. Les identités externes sont exprimées à l'aide du protocole `principalSet://`.

Tout comme l'étape précédente, cette étape dépend fortement de la configuration souhaitée. Par exemple, pour permettre à un job GitLab CI/CD d'emprunter l'identité d'un compte de service nommé `my-service-account` si le job GitLab CI/CD a été initié par un utilisateur GitLab avec le nom d'utilisateur `chris`, vous accorderiez le rôle IAM `roles/iam.workloadIdentityUser` à l'identité externe sur `my-service-account`. L'identité externe prend le format suivant :

```plaintext
principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.user_login/chris
```

où `PROJECT_NUMBER` est le numéro de votre projet Google Cloud, et `POOL_ID` est l'ID (pas le nom) du pool d'identités de charge de travail créé dans la première section.

Cette configuration suppose également que vous avez ajouté `user_login` comme attribut mappé à partir de l'assertion dans la section précédente.

## Récupérer un identifiant temporaire {#retrieve-a-temporary-credential}

Après avoir configuré l'OIDC et le rôle, le job GitLab CI/CD peut récupérer un identifiant temporaire depuis le [Google Cloud Security Token Service (STS)](https://cloud.google.com/iam/docs/reference/sts/rest).

Ajoutez `id_tokens` à votre job CI/CD :

```yaml
job:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.example.com
```

Obtenez des identifiants temporaires à l'aide du jeton d'ID :

```shell
PAYLOAD="$(cat <<EOF
{
  "audience": "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
  "grantType": "urn:ietf:params:oauth:grant-type:token-exchange",
  "requestedTokenType": "urn:ietf:params:oauth:token-type:access_token",
  "scope": "https://www.googleapis.com/auth/cloud-platform",
  "subjectTokenType": "urn:ietf:params:oauth:token-type:jwt",
  "subjectToken": "${GITLAB_OIDC_TOKEN}"
}
EOF
)"
```

```shell
FEDERATED_TOKEN="$(curl --fail "https://sts.googleapis.com/v1/token" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data "${PAYLOAD}" \
  | jq -r '.access_token'
)"
```

Où :

- `PROJECT_NUMBER` est le numéro de votre projet Google Cloud (pas son nom).
- `POOL_ID` est l'ID du pool d'identités de charge de travail créé dans la première section.
- `PROVIDER_ID` est l'ID du fournisseur d'identités de charge de travail créé dans la deuxième section.
- `GITLAB_OIDC_TOKEN` est un [jeton d'ID](../../secrets/id_token_authentication.md) OIDC.

Vous pouvez ensuite utiliser le jeton fédéré résultant pour emprunter l'identité du compte de service créé dans la section précédente :

```shell
ACCESS_TOKEN="$(curl --fail "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/SERVICE_ACCOUNT_EMAIL:generateAccessToken" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer FEDERATED_TOKEN" \
  --data '{"scope": ["https://www.googleapis.com/auth/cloud-platform"]}' \
  | jq -r '.accessToken'
)"
```

Où :

- `SERVICE_ACCOUNT_EMAIL` est l'adresse e-mail complète du compte de service dont l'identité est à emprunter, créé dans la section précédente.
- `FEDERATED_TOKEN` est le jeton fédéré récupéré à l'étape précédente.

Le résultat est un jeton d'accès Google Cloud OAuth 2.0, que vous pouvez utiliser pour vous authentifier auprès de la plupart des API et services Google Cloud lorsqu'il est utilisé comme jeton Bearer. Vous pouvez également transmettre cette valeur à l'interface de ligne de commande `gcloud` en définissant la variable d'environnement `CLOUDSDK_AUTH_ACCESS_TOKEN`.

## Exemple fonctionnel {#working-example}

Consultez ce [projet de référence](https://gitlab.com/guided-explorations/gcp/configure-openid-connect-in-gcp) pour le provisionnement d'OIDC dans GCP à l'aide de Terraform et d'un exemple de script pour récupérer des identifiants temporaires.

## Dépannage {#troubleshooting}

- Lors du débogage des réponses `curl`, installez la dernière version de curl. Utilisez `--fail-with-body` à la place de `-f`. Cette commande affiche l'intégralité du corps, qui peut contenir des messages d'erreur utiles.

- Pour plus d'informations, consultez [Troubleshoot Workload Identity Federation](https://cloud.google.com/iam/docs/troubleshooting-workload-identity-federation).
