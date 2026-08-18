---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'export des relations de projet"
description: "Exportez les relations de projet avec l'API REST."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Cette API est utilisée par l'instance de destination lors de la [migration de groupe par transfert direct](../user/group/import/_index.md) pour migrer une structure de projet. Vous n'avez généralement pas besoin d'utiliser cette API vous-même.

Dans ce contexte, une {{< glossary-tooltip text="relation" >}} est un élément exportable tel qu'une merge request. Lors de l'export, la relation inclut tous les éléments liés à la relation, tels qu'un label.

Si vous souhaitez utiliser cette API, votre instance GitLab doit remplir certains [prérequis](../user/group/import/direct_transfer_migrations.md#prerequisites).

> [!note]
> Cette API ne peut pas être utilisée avec l'[API d'import et d'export de groupe](group_import_export.md), qui est destinée à la migration basée sur des fichiers.

## Planifier un nouvel export pour un projet {#schedule-a-new-export-for-a-project}

Planifie un export des relations pour un projet spécifié.

```plaintext
POST /projects/:id/export_relations
```

| Attribut | Type              | Obligatoire | Description                                        |
|-----------|-------------------|----------|----------------------------------------------------|
| `id`      | entier ou chaîne de caractères | Oui      | ID du projet.                                 |
| `batched` | boolean           | Non       | Indique si l'export doit être effectué par lots.                      |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations"
```

```json
{
  "message": "202 Accepted"
}
```

## Récupérer le statut d'un export {#retrieve-the-status-of-an-export}

Récupère le statut d'un export de relations.

```plaintext
GET /projects/:id/export_relations/status
```

| Attribut  | Type              | Obligatoire | Description                                        |
|------------|-------------------|----------|----------------------------------------------------|
| `id`       | entier ou chaîne de caractères | Oui      | ID du projet.                                 |
| `relation` | string            | Non       | Nom de la relation de premier niveau du projet à afficher.    |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/status"
```

Le statut peut être l'un des suivants :

- `0` : `started`
- `1` : `finished`
- `-1` : `failed`

```json
[
  {
    "relation": "project_badges",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.423Z",
    "batched": true,
    "batches_count": 1,
    "batches": [
      {
        "status": 1,
        "batch_number": 1,
        "objects_count": 1,
        "error": null,
        "updated_at": "2021-05-04T11:25:20.423Z"
      }
    ]
  },
  {
    "relation": "boards",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.085Z",
    "batched": false,
    "batches_count": 0
  }
]
```

## Télécharger un export {#download-an-export}

Télécharge l'export de relations terminé.

```plaintext
GET /projects/:id/export_relations/download
```

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `id`           | entier ou chaîne de caractères | Oui      | ID du projet. |
| `relation`     | string            | Oui      | Nom de la relation de premier niveau du projet à télécharger. |
| `batched`      | boolean           | Non       | Indique si l'export est effectué par lots. |
| `batch_number` | integer           | Non       | Numéro du lot d'export à télécharger. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```

## Sujets connexes {#related-topics}

- [API d'export des relations de groupe](group_relations_export.md)
