---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST de déplacement du stockage des dépôts dans un groupe GitLab."
title: API des déplacements de stockage de dépôts de groupe
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [déplacements de stockage de dépôts de groupe](../administration/operations/moving_repositories.md). Cette API peut vous aider, par exemple, à [migrer vers Gitaly Cluster (Praefect)](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect) ou à migrer un [wiki de groupe](../user/project/wiki/group.md). Cette API ne gère pas les dépôts de projets dans un groupe. Pour planifier des déplacements de projets, utilisez l'[API des déplacements de stockage de dépôts de projet](project_repository_storage_moves.md).

Lorsque GitLab traite un déplacement de stockage de dépôts de groupe, il passe par différents états. Les valeurs de `state` sont :

- `initial` :  L'enregistrement a été créé, mais le job en arrière-plan n'a pas encore été planifié.
- `scheduled` :  Le job en arrière-plan a été planifié.
- `started` :  Les dépôts du groupe sont en cours de copie vers le stockage de destination.
- `replicated` :  Le groupe a été déplacé.
- `failed` :  La copie des dépôts du groupe a échoué, ou les sommes de contrôle ne correspondent pas.
- `finished` :  Le groupe a été déplacé et les dépôts sur le stockage source ont été supprimés.
- `cleanup failed` :  Le groupe a été déplacé, mais les dépôts sur le stockage source n'ont pas pu être supprimés.

Pour garantir l'intégrité des données, GitLab place les groupes dans un état temporaire de lecture seule pendant toute la durée du déplacement. Pendant cette période, les utilisateurs reçoivent ce message s'ils tentent de pousser de nouveaux commits :

```plaintext
The repository is temporarily read-only. Please try again later.
```

Cette API nécessite que vous vous [authentifiiez](rest/authentication.md) en tant qu'administrateur.

Des API sont également disponibles pour déplacer d'autres types de dépôts :

- [API des déplacements de stockage de dépôts de projet](project_repository_storage_moves.md).
- [API des déplacements de stockage de dépôts d'extraits de code](snippet_repository_storage_moves.md).

## Lister tous les déplacements de stockage de dépôts de groupe {#list-all-group-repository-storage-moves}

Liste tous les déplacements de stockage de dépôts de groupe pour une instance.

```plaintext
GET /group_repository_storage_moves
```

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API sont [paginés](rest/_index.md#pagination).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/group_repository_storage_moves"
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
    "group": {
      "id": 283,
      "web_url": "https://gitlab.example.com/groups/testgroup",
      "name": "testgroup"
    }
  }
]
```

## Lister tous les déplacements de stockage de dépôts pour un groupe {#list-all-repository-storage-moves-for-a-group}

Liste tous les déplacements de stockage de dépôts pour un groupe spécifié.

```plaintext
GET /groups/:group_id/repository_storage_moves
```

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API sont [paginés](rest/_index.md#pagination).

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `group_id` | entier | oui | ID du groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
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
    "group": {
      "id": 283,
      "web_url": "https://gitlab.example.com/groups/testgroup",
      "name": "testgroup"
    }
  }
]
```

## Récupérer un déplacement de stockage de dépôts de groupe {#retrieve-a-group-repository-storage-move}

Récupère un déplacement de stockage de dépôts de groupe spécifié.

```plaintext
GET /group_repository_storage_moves/:repository_storage_id
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | entier | oui | ID du déplacement de stockage de dépôts de groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/group_repository_storage_moves/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## Récupérer un déplacement de stockage de dépôts pour un groupe {#retrieve-a-repository-storage-move-for-a-group}

Récupère un déplacement de stockage de dépôts spécifié pour un groupe.

```plaintext
GET /groups/:group_id/repository_storage_moves/:repository_storage_id
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `group_id` | entier | oui | ID du groupe. |
| `repository_storage_id` | entier | oui | ID du déplacement de stockage de dépôts de groupe. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## Créer un déplacement de stockage de dépôts de groupe {#create-a-group-repository-storage-move}

Crée un déplacement de stockage de dépôts de groupe pour un groupe spécifié. Ce point de terminaison :

- Déplace uniquement les dépôts du wiki de groupe.
- Ne déplace pas les dépôts des projets dans un groupe. Pour planifier des déplacements de projets, utilisez l'API [Project repository storage moves](project_repository_storage_moves.md).

```plaintext
POST /groups/:group_id/repository_storage_moves
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `group_id` | entier | oui | ID du groupe. |
| `destination_storage_name` | string | non | Nom du fragment de stockage de destination. Le stockage est sélectionné [en fonction des poids de stockage](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) s'il n'est pas fourni. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"destination_storage_name":"storage2"}' \
     --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## Créer des déplacements de stockage de dépôts de groupe pour un fragment de stockage {#create-group-repository-storage-moves-for-a-storage-shard}

Crée des déplacements de stockage de dépôts pour tous les groupes sur un fragment de stockage spécifié.

```plaintext
POST /group_repository_storage_moves
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | string | oui | Nom du fragment de stockage source. |
| `destination_storage_name` | string | non | Nom du fragment de stockage de destination. Le stockage est sélectionné [en fonction des poids de stockage](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored) s'il n'est pas fourni. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"source_storage_name":"default"}' \
     --url "https://gitlab.example.com/api/v4/group_repository_storage_moves"
```

Exemple de réponse :

```json
{
  "message": "202 Accepted"
}
```

## Sujets connexes {#related-topics}

- [Déplacement des dépôts gérés par GitLab](../administration/operations/moving_repositories.md)
