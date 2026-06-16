---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API d'administration de recherche"
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120751) dans GitLab 16.1

{{< /history >}}

Utilisez cette API pour récupérer des informations sur les [migrations de recherche avancée](../integration/advanced_search/elasticsearch.md#advanced-search-migrations).

Prérequis :

- Vous devez être un administrateur.

## Lister toutes les migrations de recherche avancée {#list-all-advanced-search-migrations}

Liste toutes les migrations de recherche avancée pour l'instance GitLab.

```plaintext
GET /admin/search/migrations
```

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations"
```

Exemple de réponse :

```json
[
  {
    "version": 20230427555555,
    "name": "BackfillHiddenOnMergeRequests",
    "started_at": "2023-05-12T01:35:05.469+00:00",
    "completed_at": "2023-05-12T01:36:06.432+00:00",
    "completed": true,
    "obsolete": false,
    "migration_state": {}
  },
  {
    "version": 20230428500000,
    "name": "AddSuffixProjectInWikiRid",
    "started_at": "2023-05-04T18:59:43.542+00:00",
    "completed_at": "2023-05-04T18:59:43.542+00:00",
    "completed": false,
    "obsolete": false,
    "migration_state": {
      "pause_indexing": true,
      "slice": 1,
      "task_id": null,
      "max_slices": 5,
      "retry_attempt": 0
    }
  },
  {
    "version": 20230503064300,
    "name": "BackfillProjectPermissionsInBlobsUsingPermutations",
    "started_at": "2023-05-03T16:04:44.074+00:00",
    "completed_at": "2023-05-03T16:04:44.074+00:00",
    "completed": true,
    "obsolete": false,
    "migration_state": {
      "permutation_idx": 8,
      "documents_remaining": 5,
      "task_id": "I2_LXc-xQlOeu-KmjYpM8g:172820",
      "documents_remaining_for_permutation": 0
    }
  }
]
```

## Récupérer une migration de recherche avancée {#retrieve-an-advanced-search-migration}

Récupère une migration de recherche avancée spécifiée par version ou nom de migration.

```plaintext
GET /admin/search/migrations/:version_or_name
```

Paramètres :

| Attribut         | Type           | Obligatoire | Description                          |
|-------------------|----------------|----------|--------------------------------------|
| `version_or_name` | entier ou chaîne | Oui      | La version ou le nom de la migration. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations/20230503064300"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations/BackfillProjectPermissionsInBlobsUsingPermutations"
```

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut         | Type     | Description                                           |
|:------------------|:---------|:------------------------------------------------------|
| `version`         | entier  | Version de la migration.                             |
| `name`            | string   | Nom de la migration.                                |
| `started_at`      | datetime | Date de début de la migration.                         |
| `completed_at`    | datetime | Date de fin de la migration.                    |
| `completed`       | boolean  | Si `true`, la migration est terminée.                |
| `obsolete`        | boolean  | Si `true`, la migration a été marquée comme obsolète. |
| `migration_state` | objet   | État de migration stocké.                               |

Exemple de réponse :

```json
{
  "version": 20230503064300,
  "name": "BackfillProjectPermissionsInBlobsUsingPermutations",
  "started_at": "2023-05-03T16:04:44.074+00:00",
  "completed_at": "2023-05-03T16:04:44.074+00:00",
  "completed": true,
  "obsolete": false,
  "migration_state": {
    "permutation_idx": 8,
    "documents_remaining": 5,
    "task_id": "I2_LXc-xQlOeu-KmjYpM8g:172820",
    "documents_remaining_for_permutation": 0
  }
}
```
