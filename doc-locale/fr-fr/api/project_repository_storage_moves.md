---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de déplacement du stockage des dépôts de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les dépôts de projet, y compris les dépôts wiki et de conception, peuvent être déplacés entre les stockages. Cette API peut vous aider lors de la [migration vers Gitaly Cluster (Praefect)](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect), par exemple.

Au fur et à mesure que les déplacements de stockage des dépôts de projet sont traités, ils passent par différents états. Les valeurs de `state` sont :

- `initial` : L'enregistrement a été créé mais le job en arrière-plan n'a pas encore été planifié.
- `scheduled` : Le job en arrière-plan a été planifié.
- `started` : Les dépôts du projet sont en cours de copie vers le stockage de destination.
- `replicated` : Le projet a été déplacé.
- `failed` : La copie des dépôts du projet a échoué ou les sommes de contrôle ne correspondaient pas.
- `finished` : Le projet a été déplacé et les dépôts sur le stockage source ont été supprimés.
- `cleanup failed` : Le projet a été déplacé mais les dépôts sur le stockage source n'ont pas pu être supprimés.

Pour garantir l'intégrité des données, les projets sont placés dans un état temporaire de lecture seule pendant la durée du déplacement. Pendant ce temps, les utilisateurs reçoivent un message `The repository is temporarily read-only. Please try again later.` s'ils essaient de pousser de nouveaux commits.

Cette API vous demande de [vous authentifier](rest/authentication.md) en tant qu'administrateur.

Pour les autres types de dépôts, voir :

- [API de déplacement du stockage des dépôts d'extraits de code](snippet_repository_storage_moves.md).
- [API de déplacement du stockage des dépôts de groupe](group_repository_storage_moves.md).

## Lister tous les déplacements de stockage des dépôts de projet {#list-all-project-repository-storage-moves}

```plaintext
GET /project_repository_storage_moves
```

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois car les résultats de l'API sont [paginés](rest/_index.md#pagination).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "project": {
      "id": 1,
      "description": null,
      "name": "project1",
      "name_with_namespace": "John Doe2 / project1",
      "path": "project1",
      "path_with_namespace": "namespace1/project1",
      "created_at": "2020-05-07T04:27:17.016Z"
    }
  }
]
```

## Lister tous les déplacements de stockage des dépôts pour un projet {#list-all-repository-storage-moves-for-a-project}

```plaintext
GET /projects/:project_id/repository_storage_moves
```

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois car les résultats de l'API sont [paginés](rest/_index.md#pagination).

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `project_id` | entier | oui | ID du projet |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "project": {
      "id": 1,
      "description": null,
      "name": "project1",
      "name_with_namespace": "John Doe2 / project1",
      "path": "project1",
      "path_with_namespace": "namespace1/project1",
      "created_at": "2020-05-07T04:27:17.016Z"
    }
  }
]
```

## Récupérer un déplacement de stockage de dépôt de projet {#retrieve-a-project-repository-storage-move}

```plaintext
GET /project_repository_storage_moves/:repository_storage_id
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | entier | oui | ID du déplacement de stockage du dépôt de projet |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## Récupérer un déplacement de stockage de dépôt pour un projet {#retrieve-a-repository-storage-move-for-a-project}

```plaintext
GET /projects/:project_id/repository_storage_moves/:repository_storage_id
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `project_id` | entier | oui | ID du projet |
| `repository_storage_id` | entier | oui | ID du déplacement de stockage du dépôt de projet |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## Créer un déplacement de stockage de dépôt pour un projet {#create-a-repository-storage-move-for-a-project}

```plaintext
POST /projects/:project_id/repository_storage_moves
```

Paramètres :

| Attribut | Type | Obligatoire | Description                                                                                                                                                                                                        |
| --------- | ---- | -------- |--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `project_id` | entier | oui | ID du projet                                                                                                                                                                                                  |
| `destination_storage_name` | string | non | Nom du fragment de stockage de destination. Le stockage est sélectionné [automatiquement en fonction des poids de stockage](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) si non fourni |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"destination_storage_name":"storage2"}' \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## Créer des déplacements de stockage de dépôts pour tous les projets sur un fragment de stockage {#create-repository-storage-moves-for-all-projects-on-a-storage-shard}

Crée des déplacements de stockage de dépôts pour chaque dépôt de projet stocké sur le fragment de stockage source. Ce point de terminaison migre tous les projets en une seule fois.

```plaintext
POST /project_repository_storage_moves
```

Paramètres :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | string | oui | Nom du fragment de stockage source. |
| `destination_storage_name` | string | non | Nom du fragment de stockage de destination. Le stockage est sélectionné [automatiquement en fonction des poids de stockage](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) si non fourni. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"source_storage_name":"default"}' \
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves"
```

Exemple de réponse :

```json
{
  "message": "202 Accepted"
}
```

## Sujets connexes {#related-topics}

- [Déplacement des dépôts gérés par GitLab](../administration/operations/moving_repositories.md)
