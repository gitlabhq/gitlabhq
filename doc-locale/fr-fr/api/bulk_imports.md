---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Migration de groupes et de projets par transfert direct via l'API"
description: "Démarrez et visualisez les migrations de groupes et de projets avec l'API REST."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour migrer des groupes et des projets en utilisant le [transfert direct](../user/group/import/direct_transfer_migrations.md).

Prérequis :

- Consultez les [prérequis pour la migration de groupes par transfert direct](../user/group/import/direct_transfer_migrations.md#prerequisites).

## Démarrer une migration de groupe ou de projet {#start-a-group-or-project-migration}

Démarre une nouvelle migration de groupe ou de projet. Pour migrer un projet, spécifiez `entities[project_entity]`.

```plaintext
POST /bulk_imports
```

| Attribut                         | Type    | Obligatoire | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `configuration`                   | Hash    | Oui      | La configuration de l'instance GitLab source. |
| `configuration[url]`              | Chaîne  | Oui      | URL de l'instance GitLab source. |
| `configuration[access_token]`     | Chaîne  | Oui      | Jeton d'accès à l'instance GitLab source. |
| `entities`                        | Array   | Oui      | Liste des entités à importer. |
| `entities[source_type]`           | Chaîne  | Oui      | Type d'entité source. Les valeurs valides sont `group_entity` et `project_entity`. |
| `entities[source_full_path]`      | Chaîne  | Oui      | Chemin complet source de l'entité à importer. Par exemple, `gitlab-org/gitlab`. |
| `entities[destination_slug]`      | Chaîne  | Oui      | Slug de destination pour l'entité. GitLab utilise le slug comme chemin URL vers l'entité. Le nom de l'entité importée est copié depuis le nom de l'entité source et non depuis le slug. |
| `entities[destination_namespace]` | Chaîne  | Oui      | Chemin complet de l'[espace de nommage](../user/namespace/_index.md) du groupe de destination pour l'entité. Pour `project_entity`, cette valeur doit être un groupe existant sur l'instance de destination. Pour `group_entity`, cette valeur peut être un groupe existant sur l'instance de destination ou une chaîne vide `""` pour créer un groupe principal sur l'instance de destination (sur GitLab Self-Managed et GitLab Dedicated). Les espaces de nommage personnels ne sont pas pris en charge. |
| `entities[destination_name]`      | Chaîne  | Non       | Déprécié : Utilisez plutôt `destination_slug`. Slug de destination pour l'entité. |
| `entities[migrate_memberships]`   | Boolean | Non       | Importer les appartenances des utilisateurs. La valeur par défaut est `true`. |
| `entities[migrate_projects]`      | Boolean | Non       | Importer également tous les projets imbriqués du groupe (si `source_type` est `group_entity`). La valeur par défaut est `true`. |

```shell
curl --request POST \
  --url "https://destination-gitlab-instance.example.com/api/v4/bulk_imports" \
  --header "PRIVATE-TOKEN: <your_access_token_for_destination_gitlab_instance>" \
  --header "Content-Type: application/json" \
  --data '{
    "configuration": {
      "url": "https://source-gitlab-instance.example.com",
      "access_token": "<your_access_token_for_source_gitlab_instance>"
    },
    "entities": [
      {
        "source_full_path": "source/full/path",
        "source_type": "group_entity",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination/namespace/path"
      }
    ]
  }'
```

```json
{
  "id": 1,
  "status": "created",
  "source_type": "gitlab",
  "source_url": "https://gitlab.example.com",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z",
  "has_failures": false
}
```

## Lister toutes les migrations de groupes ou de projets {#list-all-group-or-project-migrations}

Liste toutes les migrations de groupes ou de projets.

```plaintext
GET /bulk_imports
```

| Attribut  | Type    | Obligatoire | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | non       | Nombre d'enregistrements à retourner par page.                                              |
| `page`     | integer | non       | Page à récupérer.                                                                  |
| `sort`     | string  | non       | Retourner les enregistrements triés dans l'ordre `asc` ou `desc` par date de création. La valeur par défaut est `desc` |
| `status`   | string  | non       | Statut d'importation.                                                                     |

Le statut peut être l'un des suivants :

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports?per_page=2&page=1"
```

```json
[
    {
        "id": 1,
        "status": "finished",
        "source_type": "gitlab",
        "source_url": "https://gitlab.example.com",
        "created_at": "2021-06-18T09:45:55.358Z",
        "updated_at": "2021-06-18T09:46:27.003Z",
        "has_failures": false
    },
    {
        "id": 2,
        "status": "started",
        "source_type": "gitlab",
        "source_url": "https://gitlab.example.com",
        "created_at": "2021-06-18T09:47:36.581Z",
        "updated_at": "2021-06-18T09:47:58.286Z",
        "has_failures": false
    }
]
```

## Lister toutes les entités de migration de groupes ou de projets {#list-all-group-or-project-migration-entities}

Liste toutes les entités de migration de groupes ou de projets.

```plaintext
GET /bulk_imports/entities
```

| Attribut  | Type    | Obligatoire | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | non       | Nombre d'enregistrements à retourner par page.                                              |
| `page`     | integer | non       | Page à récupérer.                                                                  |
| `sort`     | string  | non       | Retourner les enregistrements triés dans l'ordre `asc` ou `desc` par date de création. La valeur par défaut est `desc` |
| `status`   | string  | non       | Statut d'importation.                                                                     |

Le statut peut être l'un des suivants :

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/entities?per_page=2&page=1&status=started"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "entity_type": "group",
        "source_full_path": "source_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": [],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": false,
        "stats": {
            "labels": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            },
            "milestones": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            }
        }
    },
    {
        "id": 2,
        "bulk_import_id": 2,
        "status": "failed",
        "entity_type": "group",
        "source_full_path": "another_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "another_slug",
        "destination_namespace": "another_namespace",
        "parent_id": null,
        "namespace_id": null,
        "project_id": null,
        "created_at": "2021-06-24T10:40:20.110Z",
        "updated_at": "2021-06-24T10:40:46.590Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": false,
        "stats": { }
    }
]
```

## Récupérer une migration de groupe ou de projet {#retrieve-a-group-or-project-migration}

Récupère les détails d'une migration de groupe ou de projet.

```plaintext
GET /bulk_imports/:id
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1"
```

```json
{
  "id": 1,
  "status": "finished",
  "source_type": "gitlab",
  "source_url": "https://gitlab.example.com",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z"
}
```

## Lister les entités de migration de groupes ou de projets {#list-group-or-project-migration-entities}

Liste les entités de migration de groupes ou de projets pour une migration spécifique.

```plaintext
GET /bulk_imports/:id/entities
```

| Attribut  | Type    | Obligatoire | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | non       | Nombre d'enregistrements à retourner par page.                                              |
| `page`     | integer | non       | Page à récupérer.                                                                  |
| `sort`     | string  | non       | Retourner les enregistrements triés dans l'ordre `asc` ou `desc` par date de création. La valeur par défaut est `desc` |
| `status`   | string  | non       | Statut d'importation.                                                                     |

Le statut peut être l'un des suivants :

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities?per_page=2&page=1&status=finished"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "entity_type": "group",
        "source_full_path": "source_group",
        "destination_full_path": "destination/full_path",
        "destination_name": "destination_slug",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ],
        "migrate_projects": true,
        "migrate_memberships": true,
        "has_failures": true,
        "stats": {
            "labels": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            },
            "milestones": {
                "source": 10,
                "fetched": 10,
                "imported": 10
            }
        }
    }
]
```

## Récupérer une entité de migration de groupe ou de projet {#retrieve-a-group-or-project-migration-entity}

Récupère les détails d'une entité de migration de groupe ou de projet.

```plaintext
GET /bulk_imports/:id/entities/:entity_id
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2"
```

```json
{
    "id": 1,
    "bulk_import_id": 1,
    "status": "finished",
    "entity_type": "group",
    "source_full_path": "source_group",
    "destination_full_path": "destination/full_path",
    "destination_name": "destination_slug",
    "destination_slug": "destination_slug",
    "destination_namespace": "destination_path",
    "parent_id": null,
    "namespace_id": 1,
    "project_id": null,
    "created_at": "2021-06-18T09:47:37.390Z",
    "updated_at": "2021-06-18T09:47:51.867Z",
    "failures": [
        {
            "relation": "group",
            "step": "extractor",
            "exception_message": "Error!",
            "exception_class": "Exception",
            "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
            "created_at": "2021-06-24T10:40:46.495Z",
            "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
            "pipeline_step": "extractor"
        }
    ],
    "migrate_projects": true,
    "migrate_memberships": true,
    "has_failures": true,
    "stats": {
        "labels": {
            "source": 10,
            "fetched": 10,
            "imported": 10
        },
        "milestones": {
            "source": 10,
            "fetched": 10,
            "imported": 10
        }
    }
}
```

## Lister les enregistrements d'importation échoués pour une entité de migration {#list-failed-import-records-for-a-migration-entity}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/428016) dans GitLab 16.6.

{{< /history >}}

Liste les enregistrements d'importation échoués pour une entité de migration de groupe ou de projet.

```plaintext
GET /bulk_imports/:id/entities/:entity_id/failures
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2/failures"
```

```json
{
  "relation": "issues",
  "exception_message": "Error!",
  "exception_class": "StandardError",
  "correlation_id_value": "06289e4b064329a69de7bb2d7a1b5a97",
  "source_url": "https://gitlab.example/project/full/path/-/issues/1",
  "source_title": "Issue title"
}
```

## Annuler une migration {#cancel-a-migration}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438281) dans GitLab 17.1.

{{< /history >}}

Annule une migration par transfert direct.

```plaintext
POST /bulk_imports/:id/cancel
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/bulk_imports/1/cancel"
```

```json
{
  "id": 1,
  "status": "canceled",
  "source_type": "gitlab",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z",
  "has_failures": false
}
```

Codes de statut de réponse possibles :

| Statut | Description                     |
|--------|---------------------------------|
| 200    | Migration annulée avec succès |
| 401    | Non autorisé                    |
| 403    | Interdit                       |
| 404    | Migration introuvable             |
| 503    | Service indisponible             |
