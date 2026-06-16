---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'API d'export de liste de dépendances pour générer et télécharger des fichiers d'export des dépendances d'un projet ou d'un groupe."
title: "API d'export de liste de dépendances"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour exporter les [listes de dépendances](../user/application_security/dependency_list/_index.md). Chaque appel à cette API nécessite une authentification.

## Créer un export de liste de dépendances {#create-a-dependency-list-export}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/333463) dans GitLab 16.4 [avec un indicateur](../administration/feature_flags/_index.md) nommé `merge_sbom_api`. Activé par défaut.
- [Disponible généralement](https://gitlab.com/gitlab-org/gitlab/-/issues/425312) dans GitLab 16.7. L'indicateur de fonctionnalité `merge_sbom_api` a été supprimé.

{{< /history >}}

Crée un export JSON CycloneDX pour toutes les dépendances du projet détectées dans un pipeline.

Si un utilisateur authentifié ne dispose pas de la permission [read_dependency](../user/custom_roles/abilities.md#vulnerability-management), cette requête renvoie un code de statut `403 Forbidden`.

Les exports SBOM ne sont accessibles que par l'auteur de l'export.

```plaintext
POST /projects/:id/dependency_list_exports
POST /groups/:id/dependency_list_exports
POST /pipelines/:id/dependency_list_exports
```

| Attribut           | Type              | Obligatoire   | Description                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | integer           | yes        | L'ID du projet, du groupe ou du pipeline auquel l'utilisateur authentifié a accès. |
| `export_type`       | string            | yes        | Format de l'export. Voir [les types d'export](#export-types) pour obtenir la liste des valeurs acceptées. |
| `send_email`        | boolean           | no         | Lorsque défini sur `true`, envoie une notification par e-mail à l'utilisateur qui a demandé l'export lorsque l'export est terminé. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/pipelines/1/dependency_list_exports" \
  --data "export_type=sbom"
```

L'export de liste de dépendances créé est automatiquement supprimé à l'heure spécifiée dans le champ `expires_at`.

Exemple de réponse :

```json
{
  "id": 2,
  "status": "running",
  "has_finished": false,
  "export_type": "sbom",
  "send_email": false,
  "expires_at": "2025-04-06T09:35:38.746Z",
  "self": "http://gitlab.example.com/api/v4/dependency_list_exports/2",
  "download": "http://gitlab.example.com/api/v4/dependency_list_exports/2/download"
}
```

### Types d'export {#export-types}

Les exports peuvent être demandés dans différents formats de fichier. Certains formats ne sont disponibles que pour certains objets.

| Type d'export | Description | Disponible pour |
| ----------- | ----------- | ------------- |
| `dependency_list` | Un objet JSON standard qui liste les dépendances sous forme de paires clé-valeur. | Projets |
| `sbom` | Une nomenclature [CycloneDX](https://cyclonedx.org/) 1.4 | Pipelines |
| `cyclonedx_1_6_json` | Une nomenclature [CycloneDX](https://cyclonedx.org/) 1.6 | Projets |
| `json_array` | Un tableau JSON plat contenant des objets composants. | Groupes |
| `csv` | Un document de valeurs séparées par des virgules (CSV). | Projets, Groupes |

## Récupérer un seul export de liste de dépendances {#retrieve-a-single-dependency-list-export}

Récupère un export de liste de dépendances.

```plaintext
GET /dependency_list_exports/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | L'ID de l'export de liste de dépendances. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/dependency_list_exports/2"
```

Le code de statut est `202 Accepted` lorsque l'export de liste de dépendances est en cours de génération, et `200 OK` lorsqu'il est prêt.

Exemple de réponse :

```json
{
  "id": 4,
  "has_finished": true,
  "self": "http://gitlab.example.com/api/v4/dependency_list_exports/4",
  "download": "http://gitlab.example.com/api/v4/dependency_list_exports/4/download"
}
```

## Télécharger l'export de liste de dépendances {#download-dependency-list-export}

Télécharge un seul export de liste de dépendances.

```plaintext
GET /dependency_list_exports/:id/download
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | L'ID de l'export de liste de dépendances. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/dependency_list_exports/2/download"
```

La réponse est `404 Not Found` si l'export de liste de dépendances n'est pas encore terminé ou n'a pas été trouvé.

Exemple de réponse :

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:aec33827-20ae-40d0-ae83-18ee846364d2",
  "version": 1,
  "metadata": {
    "tools": [
      {
        "vendor": "Gitlab",
        "name": "Gemnasium",
        "version": "2.34.0"
      }
    ],
    "authors": [
      {
        "name": "Gitlab",
        "email": "support@gitlab.com"
      }
    ],
    "properties": [
      {
        "name": "gitlab:dependency_scanning:input_file",
        "value": "package-lock.json"
      }
    ]
  },
  "components": [
    {
      "name": "com.fasterxml.jackson.core/jackson-core",
      "purl": "pkg:maven/com.fasterxml.jackson.core/jackson-core@2.9.2",
      "version": "2.9.2",
      "type": "library",
      "licenses": [
        {
          "license": {
            "id": "MIT",
            "url": "https://spdx.org/licenses/MIT.html"
          }
        },
        {
          "license": {
            "id": "BSD-3-Clause",
            "url": "https://spdx.org/licenses/BSD-3-Clause.html"
          }
        }
      ]
    }
  ]
}

```
