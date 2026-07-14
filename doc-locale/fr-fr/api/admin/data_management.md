---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de gestion des données
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/537707) dans GitLab 18.3 avec un [indicateur](../../administration/feature_flags/_index.md) nommé `geo_primary_verification_view`. Désactivé par défaut. Cette fonctionnalité est une [expérience](../../policy/development_stages_support.md).
- L'indicateur est activé par défaut dans GitLab 18.8.

{{< /history >}}

Utilisez l'API de gestion des données pour gérer les données d'une instance.

Prérequis :

- Vous devez être un administrateur.

## Récupérer les informations du modèle {#retrieve-model-information}

Récupère des informations sur un modèle de données dans une instance. Cette opération est une [expérience](../../policy/development_stages_support.md) et peut être modifiée ou supprimée sans préavis.

```plaintext
GET /admin/data_management/:model_name
```

Le paramètre `:model_name` doit être l'un des suivants :

- `ci_job_artifacts`
- `ci_pipeline_artifacts`
- `ci_secure_files`
- `container_repositories`
- `dependency_proxy_blobs`
- `dependency_proxy_manifests`
- `design_management_repositories`
- `group_wiki_repositories`
- `lfs_objects`
- `merge_request_diffs`
- `packages_debian_project_component_files`
- `packages_nuget_symbols`
- `packages_package_files`
- `pages_deployments`
- `projects`
- `projects_wiki_repositories`
- `snippet_repositories`
- `supply_chain_attestations`
- `terraform_state_versions`
- `uploads`

Attributs pris en charge :

| Attribut        | Type   | Obligatoire | Description                                                                                                                 |
|------------------|--------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `model_name`     | string | Oui      | Le nom pluralisé du modèle demandé. Doit appartenir à la liste `:model_name` ci-dessus.                                    |
| `checksum_state` | string | Non       | Recherche par statut de somme de contrôle. Valeurs autorisées : pending, started, succeeded, failed, disabled.                                   |
| `identifiers`    | array  | Non       | Filtre les résultats avec un tableau d'identifiants uniques du modèle demandé, qui peuvent être des entiers ou des chaînes encodées en base64. |

Ce point de terminaison prend en charge la [pagination par jeu de clés](../rest/_index.md#keyset-based-pagination) sur la clé primaire du modèle, avec un tri par ordre croissant ou décroissant. Pour utiliser la pagination par jeu de clés, ajoutez le paramètre `pagination=keyset` à la requête. Par défaut, la pagination par jeu de clés charge 20 enregistrements par page, triés par ordre croissant. Vous pouvez modifier l'ordre de tri avec le paramètre de requête `sort`, et les valeurs `asc` ou `desc`. Pour sélectionner un nombre d'enregistrements par page, utilisez le paramètre `per_page`.

En cas de succès, renvoie [`200`](../rest/troubleshooting.md#status-codes) et des informations sur le modèle. Il inclut les attributs de réponse suivants :

| Attribut              | Type              | Description                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | Informations de somme de contrôle spécifiques à Geo, si disponibles.                               |
| `created_at`           | timestamp         | Horodatage de création, si disponible.                                              |
| `file_size`            | integer           | Taille de l'objet, si disponible.                                              |
| `model_class`          | string            | Nom de classe du modèle.                                                       |
| `record_identifier`    | string ou integer | Identifiant unique de l'enregistrement. Peut être un entier ou une chaîne encodée en base64. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects?pagination=keyset"
```

Exemple de réponse :

```json
[
  {
    "record_identifier": 1,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:10.173Z",
    "file_size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.643Z",
      "checksum_state": "succeeded",
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  },
  {
    "record_identifier": 2,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:14.402Z",
    "file_size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.214Z",
      "checksum_state": "succeeded",
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  }
]
```

## Recalculer les sommes de contrôle pour les enregistrements du modèle {#recalculate-checksums-for-model-records}

Recalcule les sommes de contrôle pour les enregistrements sélectionnés d'un modèle spécifié, filtrés par les paramètres `checksum_state` et `identifiers` si fournis. La requête place un job en arrière-plan dans la file d'attente pour effectuer le recalcul.

```plaintext
PUT /admin/data_management/:model_name/checksum
```

| Attribut          | Type    | Obligatoire | Description                                                                                                                 |
|--------------------|---------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `model_name`       | string  | Oui      | Le nom pluralisé du modèle demandé. Doit appartenir à la liste `:model_name` ci-dessus.                                    |
| `checksum_state`   | string  | Non       | Filtre par statut de somme de contrôle. Valeurs autorisées : pending, started, succeeded, failed, disabled.                                   |
| `identifiers`      | array   | Non       | Filtre les enregistrements avec un tableau d'identifiants uniques du modèle demandé, qui peuvent être des entiers ou des chaînes encodées en base64. |

En cas de succès, renvoie [`200`](../rest/troubleshooting.md#status-codes) et une réponse JSON contenant les informations suivantes :

| Attribut | Type   | Description                                       |
|-----------|--------|---------------------------------------------------|
| `message` | string | Un message d'information sur le succès ou l'erreur. |
| `status`  | string | Peut être « success » ou « error ».                      |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/checksum"
```

Exemple de réponse :

```json
{
  "status": "success",
  "message": "Batch update job has been successfully enqueued."
}
```

## Récupérer des informations sur un enregistrement de modèle {#retrieve-information-about-a-model-record}

Récupère des informations sur un enregistrement de modèle spécifié.

```plaintext
GET /admin/data_management/:model_name/:id
```

| Attribut           | Type              | Obligatoire | Description                                                                                 |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------|
| `model_name`        | string            | Oui      | Le nom pluralisé du modèle demandé. Doit appartenir à la liste `:model_name` ci-dessus.    |
| `record_identifier` | string ou integer | Oui      | L'identifiant unique du modèle demandé. Peut être un entier ou une chaîne encodée en base64. |

En cas de succès, renvoie [`200`](../rest/troubleshooting.md#status-codes) et des informations sur l'enregistrement de modèle spécifique. Il inclut les attributs de réponse suivants :

| Attribut              | Type              | Description                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | Informations de somme de contrôle spécifiques à Geo, si disponibles.                               |
| `created_at`           | timestamp         | Horodatage de création, si disponible.                                              |
| `file_size`            | integer           | Taille de l'objet, si disponible.                                              |
| `model_class`          | string            | Nom de classe du modèle.                                                       |
| `record_identifier`    | string ou integer | Identifiant unique de l'enregistrement. Peut être un entier ou une chaîne encodée en base64. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/1"
```

Exemple de réponse :

```json
{
  "record_identifier": 1,
  "model_class": "Project",
  "created_at": "2025-02-05T11:27:10.173Z",
  "file_size": null,
  "checksum_information": {
    "checksum": "<object checksum>",
    "last_checksum": "2025-07-24T14:22:18.643Z",
    "checksum_state": "succeeded",
    "checksum_retry_count": 0,
    "checksum_retry_at": null,
    "checksum_failure": null
  }
}
```

## Recalculer la somme de contrôle d'un enregistrement de modèle {#recalculate-the-checksum-of-a-model-record}

Recalcule la somme de contrôle d'un enregistrement de modèle spécifié. La valeur de la somme de contrôle est une représentation du modèle interrogé hachée avec l'algorithme md5 ou sha256.

```plaintext
PUT /admin/data_management/:model_name/:record_identifier/checksum
```

| Attribut           | Type              | Obligatoire | Description                                                                                                               |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `model_name`        | string            | Oui      | Le nom pluralisé du modèle demandé. Doit appartenir à la liste `:model_name` ci-dessus.                                  |
| `record_identifier` | string ou integer | Oui      | Identifiant unique de l'enregistrement. Peut être un entier ou une chaîne encodée en base64 (extrait de la réponse de la requête GET). |

En cas de succès, renvoie [`200`](../rest/troubleshooting.md#status-codes) et des informations sur l'enregistrement de modèle spécifique.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/1/checksum"
```

Exemple de réponse :

```json
{
  "record_identifier": 1,
  "model_class": "Project",
  "created_at": "2025-02-05T11:27:10.173Z",
  "file_size": null,
  "checksum_information": {
    "checksum": "<sha256 or md5 string>",
    "last_checksum": "2025-07-24T14:22:18.643Z",
    "checksum_state": "succeeded",
    "checksum_retry_count": 0,
    "checksum_retry_at": null,
    "checksum_failure": null
  }
}
```
