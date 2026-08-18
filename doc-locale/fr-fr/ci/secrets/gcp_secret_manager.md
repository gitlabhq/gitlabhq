---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Apprenez à utiliser les secrets GCP Secret Manager dans les pipelines CI/CD GitLab
title: Utiliser les secrets GCP Secret Manager dans GitLab CI/CD
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/11739) dans GitLab et GitLab Runner 16.8.

{{< /history >}}

Vous pouvez utiliser les secrets stockés dans [Google Cloud (GCP) Secret Manager](https://cloud.google.com/security/products/secret-manager) dans vos pipelines CI/CD GitLab.

Le flux d'utilisation de GitLab avec GCP Secret Manager est le suivant :

1. GitLab émet un jeton d'identification au job CI/CD.
1. Le runner s'authentifie auprès de GCP à l'aide du jeton d'identification.
1. GCP vérifie le jeton d'identification auprès de GitLab.
1. GCP émet un jeton d'accès de courte durée.
1. Le runner accède aux données secrètes à l'aide du jeton d'accès.
1. GCP vérifie les autorisations IAM sur le secret pour le principal du jeton d'accès.
1. GCP renvoie les données secrètes au runner.

Pour utiliser GitLab avec GCP Secret Manager, vous devez :

- Avoir des secrets stockés dans [GCP Secret Manager](https://cloud.google.com/security/products/secret-manager).
- Configurer [GCP Workload Identity Federation](#configure-gcp-iam-workload-identity-federation-wif) pour inclure GitLab en tant que fournisseur d'identité.
- Configurer les autorisations [GCP IAM](#grant-access-to-gcp-iam-principal) pour accorder l'accès à GCP Secret Manager.
- Configurer [GitLab CI/CD avec GCP Secret Manager](#configure-gitlab-cicd-to-use-gcp-secret-manager-secrets).

## Configurer GCP IAM Workload Identity Federation (WIF) {#configure-gcp-iam-workload-identity-federation-wif}

GCP IAM WIF doit être configuré pour reconnaître les jetons d'identification émis par GitLab et leur attribuer un principal approprié. Le principal est utilisé pour autoriser l'accès aux ressources Secret Manager :

1. Dans GCP Console, accédez à **IAM & Admin** > **Workload Identity Federation**.
1. Sélectionnez **CREATE POOL** et créez un nouveau pool d'identités avec un nom unique, par exemple `gitlab-pool`.
1. Sélectionnez **ADD PROVIDER** pour ajouter un nouveau fournisseur OIDC au pool d'identités avec un nom unique, par exemple `gitlab-provider`.
   1. Définissez **Issuer (URL)** sur l'URL GitLab, par exemple `https://gitlab.com`.
   1. Sélectionnez **Default audience**, ou sélectionnez **Allowed audiences** pour une audience personnalisée, utilisée dans `aud` pour le jeton d'identification CI/CD GitLab.
1. Sous **Attribute Mapping**, créez les mappages suivants, où :

   - `attribute.X` est le nom de l'attribut à inclure en tant que revendication dans le jeton Google.
   - `assertion.X` est la valeur à extraire de la [revendication GitLab](../cloud_services/_index.md#id-token-authentication-for-cloud-services).

   | Attribut (sur Google)         | Assertion (depuis GitLab) |
   |-------------------------------|-------------------------|
   | `google.subject`              | `assertion.sub`         |
   | `attribute.gitlab_project_id` | `assertion.project_id`  |

## Accorder l'accès au principal GCP IAM {#grant-access-to-gcp-iam-principal}

Après avoir configuré WIF, vous devez accorder au principal WIF l'accès aux secrets dans Secret Manager.

1. Dans GCP Console, accédez à **Sécurité** > **Secret Manager**.
1. Sélectionnez le nom du secret auquel vous souhaitez accorder l'accès pour afficher les détails du secret.
1. Depuis l'onglet **PERMISSIONS**, sélectionnez **GRANT ACCESS** pour accorder l'accès au jeu de principaux créé via le fournisseur WIF. Le format d'identité externe est :

   ```plaintext
   principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.gitlab_project_id/GITLAB_PROJECT_ID
   ```

   Dans cet exemple :

   - `PROJECT_NUMBER` : Le numéro de projet Google Cloud (et non l'ID) qui se trouve dans le [tableau de bord du projet](https://console.cloud.google.com/home/dashboard).
   - `POOL_ID` : L'ID (et non le nom) du pool d'identités de charge de travail créé dans la première section, par exemple `gitlab-pool`.
   - `GITLAB_PROJECT_ID` : L'ID de projet GitLab disponible sur la [page de présentation du projet](../../user/project/working_with_projects.md#find-the-project-id).

1. Attribuez le rôle **Secret Manager Secret Accessor**.

## Configurer GitLab CI/CD pour utiliser les secrets GCP Secret Manager {#configure-gitlab-cicd-to-use-gcp-secret-manager-secrets}

Vous devez [ajouter ces variables CI/CD](../variables/_index.md#for-a-project) pour fournir des informations sur votre GCP Secret Manager :

- `GCP_PROJECT_NUMBER` : Le [numéro de projet](https://cloud.google.com/resource-manager/docs/creating-managing-projects) GCP.
- `GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID` : L'ID du pool WIF, par exemple `gitlab-pool`.
- `GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID` : L'ID du fournisseur WIF, par exemple `gitlab-provider`.

Vous pouvez ensuite utiliser les secrets stockés dans GCP Secret Manager dans des jobs CI/CD en les définissant avec le mot-clé `gcp_secret_manager` :

```yaml
job_using_gcp_sm:
  id_tokens:
    GCP_ID_TOKEN:
      # `aud` must match the audience defined in the WIF Identity Pool.
      aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID}/providers/${GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID}
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: my-project-secret  # This is the name of the secret defined in GCP Secret Manager
        version: 1               # optional: default to `latest`.
      token: $GCP_ID_TOKEN
```

### Utiliser des secrets d'un projet GCP différent {#use-secrets-from-a-different-gcp-project}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37487) dans GitLab 17.0.

{{< /history >}}

Les noms de secrets dans GCP sont propres à chaque projet. Par défaut, le secret nommé dans `gcp_secret_manager:name` est lu depuis le projet spécifié dans `GCP_PROJECT_NUMBER`.

Pour lire un secret depuis un projet différent de celui contenant le pool WIF, utilisez le nom de secret complet formaté comme suit : `projects/<project-number>/secrets/<secret-name>`.

Par exemple, si `my-project-secret` se trouve dans le projet GCP numéro `123456789`, vous pouvez accéder au secret avec :

```yaml
job_using_gcp_sm:
  # ... as previously configured ...
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: projects/123456789/secrets/my-project-secret  # fully-qualified name of the secret defined in GCP Secret Manager
        version: 1                                          # optional: defaults to `latest`.
      token: $GCP_ID_TOKEN
```

## Dépannage {#troubleshooting}

### Erreur : La taille de l'attribut mappé `google.subject` dépasse la limite de 127 octets {#error-the-size-of-mapped-attribute-googlesubject-exceeds-the-127-bytes-limit}

Les chemins de branche longs peuvent entraîner l'échec d'un job avec cette erreur, car [l'attribut `assertion.sub`](id_token_authentication.md#token-payload) dépasse 127 caractères :

```plaintext
ERROR: Job failed (system failure): resolving secrets: failed to exchange sts token: googleapi: got HTTP response code 400 with body:
{"error":"invalid_request","error_description":"The size of mapped attribute google.subject exceeds the 127 bytes limit.
Either modify your attribute mapping or the incoming assertion to produce a mapped attribute that is less than 127 bytes."}
```

Les chemins de branche longs peuvent être causés par :

- Des sous-groupes profondément imbriqués.
- Des noms de groupe, de dépôt ou de branche trop longs.

Par exemple, pour une branche `gitlab-org/gitlab`, le payload est `project_path:gitlab-org/gitlab:ref_type:branch:ref:{branch_name}`. Pour que la chaîne reste inférieure à 127 caractères, le nom de la branche doit comporter 76 caractères ou moins. Cette limite est imposée par Google Cloud IAM, suivie dans le [ticket Google n° 264362370](https://issuetracker.google.com/issues/264362370?pli=1).

La seule solution à ce problème est d'utiliser des noms plus courts [pour votre branche et votre dépôt](https://github.com/google-github-actions/auth/blob/main/docs/TROUBLESHOOTING.md#subject-exceeds-the-127-byte-limit).

### Message `The secrets provider can not be found. Check your CI/CD variables and try again.` {#the-secrets-provider-can-not-be-found-check-your-cicd-variables-and-try-again-message}

Vous pourriez recevoir cette erreur lorsque vous tentez de démarrer un job configuré pour accéder à GCP Secret Manager :

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

Le job ne peut pas être créé car une ou plusieurs des variables requises ne sont pas définies :

- `GCP_PROJECT_NUMBER`
- `GCP_WORKLOAD_IDENTITY_FEDERATION_POOL_ID`
- `GCP_WORKLOAD_IDENTITY_FEDERATION_PROVIDER_ID`

### Avertissement `WARNING: Not resolved: no resolver that can handle the secret` {#warning-not-resolved-no-resolver-that-can-handle-the-secret-warning}

L'intégration Google Cloud Secret Manager nécessite au minimum GitLab 16.8 et GitLab Runner 16.8. Cet avertissement s'affiche si le job est exécuté par un runner utilisant une version antérieure à 16.8.
