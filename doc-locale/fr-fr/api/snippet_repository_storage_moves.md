---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des déplacements de stockage de dépôt de snippets
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [déplacements de stockage de dépôt de snippets](../administration/operations/moving_repositories.md). Cette API peut vous aider, par exemple, à [migrer vers le cluster Gitaly (Praefect)](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect).

Au fur et à mesure que les déplacements de stockage de dépôt de snippets sont traités, ils transitent par différents états. Les valeurs de `state` sont :

- `initial` : L'enregistrement a été créé, mais le job en arrière-plan n'a pas encore été planifié.
- `scheduled` : Le job en arrière-plan a été planifié.
- `started` : Le dépôt de snippet est en cours de copie vers le stockage de destination.
- `replicated` : Le snippet a été déplacé.
- `failed` : La copie du dépôt de snippet a échoué ou la somme de contrôle ne correspondait pas.
- `finished` : Le snippet a été déplacé et le dépôt sur le stockage source a été supprimé.
- `cleanup failed` : Le snippet a été déplacé, mais le dépôt sur le stockage source n'a pas pu être supprimé.

Pour garantir l'intégrité des données, les snippets sont placés dans un état temporaire en lecture seule pendant la durée du déplacement. Pendant ce temps, les utilisateurs reçoivent un message `The repository is temporarily read-only. Please try again later.` s'ils tentent de pousser de nouveaux commits.

Cette API vous demande de [vous authentifier](rest/authentication.md) en tant qu'administrateur.

Pour les autres types de dépôts, consultez :

- [API des déplacements de stockage de dépôt de projet](project_repository_storage_moves.md).
- [API des déplacements de stockage de dépôt de groupe](group_repository_storage_moves.md).

## Lister tous les déplacements de stockage de dépôt de snippets {#list-all-snippet-repository-storage-moves}

Liste tous les déplacements de stockage de dépôt de snippets.

```plaintext
GET /snippet_repository_storage_moves
```

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API sont [paginés](rest/_index.md#pagination).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
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
    "snippet": {
      "id": 65,
      "title": "Test Snippet",
      "description": null,
      "visibility": "internal",
      "updated_at": "2020-12-01T11:15:50.385Z",
      "created_at": "2020-12-01T11:15:50.385Z",
      "project_id": null,
      "web_url": "https://gitlab.example.com/-/snippets/65",
      "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
      "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
      "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
    }
  }
]
```

## Lister tous les déplacements de stockage de dépôt pour un snippet {#list-all-repository-storage-moves-for-a-snippet}

Liste tous les déplacements de stockage de dépôt pour un snippet spécifié.

```plaintext
GET /snippets/:snippet_id/repository_storage_moves
```

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API sont [paginés](rest/_index.md#pagination).

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | entier | oui | ID du snippet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
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
    "snippet": {
      "id": 65,
      "title": "Test Snippet",
      "description": null,
      "visibility": "internal",
      "updated_at": "2020-12-01T11:15:50.385Z",
      "created_at": "2020-12-01T11:15:50.385Z",
      "project_id": null,
      "web_url": "https://gitlab.example.com/-/snippets/65",
      "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
      "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
      "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
    }
  }
]
```

## Récupérer un déplacement de stockage de dépôt de snippet {#retrieve-a-snippet-repository-storage-move}

Récupère un déplacement de stockage de dépôt de snippet spécifié.

```plaintext
GET /snippet_repository_storage_moves/:repository_storage_id
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | entier | oui | ID du déplacement de stockage de dépôt de snippet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## Récupérer un déplacement de stockage de dépôt pour un snippet {#retrieve-a-repository-storage-move-for-a-snippet}

Récupère un déplacement de stockage de dépôt pour un snippet spécifié.

```plaintext
GET /snippets/:snippet_id/repository_storage_moves/:repository_storage_id
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | entier | oui | ID du snippet. |
| `repository_storage_id` | entier | oui | ID du déplacement de stockage de dépôt de snippet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## Planifier un déplacement de stockage de dépôt pour un snippet {#schedule-a-repository-storage-move-for-a-snippet}

Planifie un déplacement de stockage de dépôt pour un snippet spécifié.

```plaintext
POST /snippets/:snippet_id/repository_storage_moves
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | entier | oui | ID du snippet. |
| `destination_storage_name` | string | non | Nom de la partition de stockage de destination. Le stockage est sélectionné [automatiquement en fonction des poids de stockage](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) s'il n'est pas fourni. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"destination_storage_name":"storage2"}' \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## Planifier des déplacements de stockage de dépôt pour tous les snippets sur une partition de stockage {#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard}

Planifie des déplacements de stockage de dépôt pour chaque dépôt de snippet stocké sur la partition de stockage source. Ce point de terminaison migre tous les snippets en une seule fois.

```plaintext
POST /snippet_repository_storage_moves
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | string | oui | Nom de la partition de stockage source. |
| `destination_storage_name` | string | non | Nom de la partition de stockage de destination. Le stockage est sélectionné [automatiquement en fonction des poids de stockage](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) s'il n'est pas fourni. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"source_storage_name":"default"}' \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
```

Exemple de réponse :

```json
{
  "message": "202 Accepted"
}
```

## Sujets connexes {#related-topics}

- [Déplacement des dépôts gérés par GitLab](../administration/operations/moving_repositories.md)
