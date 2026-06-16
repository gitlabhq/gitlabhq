---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Notes
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les commentaires et les enregistrements système associés au contenu GitLab. Vous pouvez :

- Créez et modifiez des commentaires sur les tickets, les merge requests, les epics, les snippets et les commits.
- Récupérez les [notes générées par le système](../user/project/system_notes.md) concernant les modifications d'objets.
- Triez et paginez les résultats.
- Contrôlez la visibilité avec les indicateurs confidentiels et internes.
- Prévenez les abus grâce à la limitation de débit.

Certaines notes générées par le système sont suivies en tant qu'événements de ressource distincts :

- [Événements de label de ressource](resource_label_events.md)
- [Événements d'état de ressource](resource_state_events.md)
- [Événements de jalon de ressource](resource_milestone_events.md)
- [Événements de poids de ressource](resource_weight_events.md)
- [Événements d'itération de ressource](resource_iteration_events.md)

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API sont paginés. Pour plus d'informations, consultez la [pagination](rest/_index.md#pagination).

## Événements de ressource {#resource-events}

Certaines notes système ne font pas partie de cette API, mais sont enregistrées en tant qu'événements distincts :

- [Événements de label de ressource](resource_label_events.md)
- [Événements d'état de ressource](resource_state_events.md)
- [Événements de jalon de ressource](resource_milestone_events.md)
- [Événements de poids de ressource](resource_weight_events.md)
- [Événements d'itération de ressource](resource_iteration_events.md)

## Pagination des notes {#notes-pagination}

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API sont paginés.

En savoir plus sur la [pagination](rest/_index.md#pagination).

## Limites de débit {#rate-limits}

Pour contribuer à éviter les abus, vous pouvez limiter vos utilisateurs à un nombre spécifique de requêtes `Create` par minute. Pour plus d'informations, consultez les [Limites de débit sur la création de notes](../administration/settings/rate_limit_on_notes_creation.md).

## Issues {#issues}

### Lister toutes les notes d'une issue {#list-all-issue-notes}

Liste toutes les notes d'une issue spécifiée.

```plaintext
GET /projects/:id/issues/:issue_iid/notes
GET /projects/:id/issues/:issue_iid/notes?sort=asc&order_by=updated_at
GET /projects/:id/issues/:issue_iid/notes?activity_filter=only_comments
```

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid` | entier           | oui      | L'IID d'une issue |
| `activity_filter` | string      | non       | Filtrez les notes par type d'activité. Valeurs valides : `all_notes`, `only_comments`, `only_activity`. La valeur par défaut est `all_notes` |
| `sort`      | string            | non       | Renvoie les notes de l'issue triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc` |
| `order_by`  | string            | non       | Renvoie les notes de l'issue ordonnées par les champs `created_at` ou `updated_at`. La valeur par défaut est `created_at` |

```json
[
  {
    "id": 302,
    "body": "closed",
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:22:45Z",
    "updated_at": "2013-10-02T10:22:45Z",
    "system": true,
    "noteable_id": 377,
    "noteable_type": "Issue",
    "project_id": 5,
    "noteable_iid": 377,
    "resolvable": false,
    "confidential": false,
    "internal": false,
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 305,
    "body": "Text of the comment\r\n",
    "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
    },
    "created_at": "2013-10-02T09:56:03Z",
    "updated_at": "2013-10-02T09:56:03Z",
    "system": true,
    "noteable_id": 121,
    "noteable_type": "Issue",
    "project_id": 5,
    "noteable_iid": 121,
    "resolvable": false,
    "confidential": true,
    "internal": true,
    "imported": false,
    "imported_from": "none"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes"
```

### Récupérer une note d'issue {#retrieve-an-issue-note}

Récupère une note spécifiée pour une issue de projet.

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id
```

Paramètres :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid` | entier           | oui      | L'IID d'une issue de projet |
| `note_id`   | entier           | oui      | L'ID d'une note d'issue |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/1"
```

### Créer une note d'issue {#create-an-issue-note}

Crée une note pour une issue de projet spécifiée.

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

Paramètres :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`    | entier           | oui      | L'IID d'une issue. |
| `body`         | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `confidential` | boolean           | non       | **Déprécié** : Prévu pour être supprimé dans GitLab 16.0 et renommé en `internal`. L'indicateur confidentiel d'une note. La valeur par défaut est false. |
| `internal`     | boolean           | non       | L'indicateur interne d'une note. Remplace `confidential` lorsque les deux paramètres sont soumis. La valeur par défaut est false. |
| `created_at`   | string            | non       | Chaîne de date et heure, au format ISO 8601. Elle doit être postérieure au 01-01-1970. Exemple : `2016-03-11T03:45:40Z` (nécessite des droits d'administrateur ou de propriétaire de projet/groupe) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=note"
```

### Mettre à jour une note d'issue {#update-an-issue-note}

Met à jour une note spécifiée d'une issue.

```plaintext
PUT /projects/:id/issues/:issue_iid/notes/:note_id
```

Paramètres :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`    | entier           | oui      | L'IID d'une issue. |
| `note_id`      | entier           | oui      | L'ID d'une note. |
| `body`         | string            | non       | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `confidential` | boolean           | non       | **Déprécié** : Prévu pour être supprimé dans GitLab 16.0. L'indicateur confidentiel d'une note. La valeur par défaut est false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636?body=note"
```

### Supprimer une note d'issue {#delete-an-issue-note}

Supprime une note existante d'une issue.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id
```

Paramètres :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid` | entier           | oui      | L'IID d'une issue |
| `note_id`   | entier           | oui      | L'ID d'une note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes/636"
```

## Snippets {#snippets}

L'API Notes pour les snippets est destinée aux snippets de niveau projet, et non aux snippets personnels.

### Lister toutes les notes de snippet {#list-all-snippet-notes}

Liste toutes les notes d'un snippet spécifié. Les notes de snippet sont des commentaires que les utilisateurs peuvent publier sur un snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/notes
GET /projects/:id/snippets/:snippet_id/notes?sort=asc&order_by=updated_at
```

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `snippet_id` | entier           | oui      | L'ID d'un snippet de projet |
| `sort`       | string            | non       | Renvoie les notes de snippet triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc` |
| `order_by`   | string            | non       | Renvoie les notes de snippet ordonnées par les champs `created_at` ou `updated_at`. La valeur par défaut est `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes"
```

### Récupérer une note de snippet {#retrieve-a-snippet-note}

Récupère une note spécifiée pour un snippet.

```plaintext
GET /projects/:id/snippets/:snippet_id/notes/:note_id
```

Paramètres :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `snippet_id` | entier           | oui      | L'ID d'un snippet de projet |
| `note_id`    | entier           | oui      | L'ID d'une note de snippet |

```json
{
  "id": 302,
  "body": "closed",
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T09:22:45Z",
  "updated_at": "2013-10-02T10:22:45Z",
  "system": true,
  "noteable_id": 377,
  "noteable_type": "Issue",
  "project_id": 5,
  "noteable_iid": 377,
  "resolvable": false,
  "confidential": false,
  "internal": false,
  "imported": false,
  "imported_from": "none"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/11"
```

### Créer une note de snippet {#create-a-snippet-note}

Crée une nouvelle note pour un snippet spécifié. Les notes de snippet sont des commentaires d'utilisateurs sur les snippets. Si vous créez une note dont le corps ne contient qu'une réaction emoji, GitLab renvoie cet objet.

```plaintext
POST /projects/:id/snippets/:snippet_id/notes
```

Paramètres :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `snippet_id` | entier           | oui      | L'ID d'un snippet |
| `body`       | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `created_at` | string            | non       | Chaîne de date et heure, au format ISO 8601. Exemple : `2016-03-11T03:45:40Z` (nécessite des droits d'administrateur ou de propriétaire de projet/groupe) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippet/11/notes?body=note"
```

### Mettre à jour une note de snippet {#update-a-snippet-note}

Met à jour une note spécifiée d'un snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id/notes/:note_id
```

Paramètres :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `snippet_id` | entier           | oui      | L'ID d'un snippet |
| `note_id`    | entier           | oui      | L'ID d'une note de snippet |
| `body`       | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/notes/1659?body=note"
```

### Supprimer une note de snippet {#delete-a-snippet-note}

Supprime une note existante d'un snippet.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/notes/:note_id
```

Paramètres :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `snippet_id` | entier           | oui      | L'ID d'un snippet |
| `note_id`    | entier           | oui      | L'ID d'une note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/52/notes/1659"
```

## Merge requests {#merge-requests}

### Lister toutes les notes de merge request {#list-all-merge-request-notes}

Liste toutes les notes d'une merge request spécifiée.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes
GET /projects/:id/merge_requests/:merge_request_iid/notes?sort=asc&order_by=updated_at
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request de projet |
| `sort`              | string            | non       | Renvoie les notes de merge request triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc` |
| `order_by`          | string            | non       | Renvoie les notes de merge request ordonnées par les champs `created_at` ou `updated_at`. La valeur par défaut est `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes"
```

### Récupérer une note de merge request {#retrieve-a-merge-request-note}

Récupère une note spécifiée pour une merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Paramètres :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request de projet |
| `note_id`           | entier           | oui      | L'ID d'une note de merge request |

```json
{
  "id": 301,
  "body": "Comment for MR",
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T08:57:14Z",
  "updated_at": "2013-10-02T08:57:14Z",
  "system": false,
  "noteable_id": 2,
  "noteable_type": "MergeRequest",
  "project_id": 5,
  "noteable_iid": 2,
  "resolvable": false,
  "confidential": false,
  "internal": false
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1"
```

### Créer une note de merge request {#create-a-merge-request-note}

Crée une note pour une merge request spécifiée. Les notes ne sont pas attachées à des lignes spécifiques dans une merge request. Pour d'autres approches avec un contrôle plus granulaire, consultez [publier un commentaire sur un commit](commits.md#post-comment-to-commit) dans l'API des commits, et [créer un nouveau fil de discussion dans le diff de la merge request](discussions.md#create-a-new-thread-in-the-merge-request-diff) dans l'API des discussions.

Si vous créez une note dont le corps ne contient qu'une réaction emoji, GitLab renvoie cet objet.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/notes
```

Paramètres :

| Attribut                     | Type              | Obligatoire | Description |
|-------------------------------|-------------------|----------|-------------|
| `body`                        | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `id`                          | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | entier           | oui      | L'IID d'une merge request de projet |
| `created_at`                  | string            | non       | Chaîne de date et heure, au format ISO 8601. Exemple : `2016-03-11T03:45:40Z` (nécessite des droits d'administrateur ou de propriétaire de projet/groupe) |
| `internal`                    | boolean           | non       | L'indicateur interne d'une note. La valeur par défaut est false. |
| `merge_request_diff_head_sha` | string            | non       | Requis pour l'action rapide [`/merge`](../user/project/quick_actions.md#merge). Le SHA du commit head, qui garantit que la merge request n'a pas été mise à jour après l'envoi de la requête API. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes?body=note"
```

### Mettre à jour une note de merge request {#update-a-merge-request-note}

Met à jour une note spécifiée d'une merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Paramètres :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request de projet |
| `note_id`           | entier           | non       | L'ID d'une note |
| `body`              | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `confidential`      | boolean           | non       | **Déprécié** : Prévu pour être supprimé dans GitLab 16.0. L'indicateur confidentiel d'une note. La valeur par défaut est false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/notes/1?body=note"
```

### Supprimer une note de merge request {#delete-a-merge-request-note}

Supprime une note existante d'une merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/notes/:note_id
```

Paramètres :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | entier           | oui      | L'IID d'une merge request |
| `note_id`           | entier           | oui      | L'ID d'une note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/7/notes/1602"
```

## Epics {#epics}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> L'API REST Epics a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) dans GitLab 17.0 et sa suppression est prévue dans la v5 de l'API. De GitLab 17.4 à 18.0, si [le nouveau rendu des epics](../user/group/epics/_index.md#epics-as-work-items) est activé, et dans GitLab 18.1 et versions ultérieures, utilisez plutôt l'API Work Items. Pour plus d'informations, consultez [migrer les API d'epic vers les éléments de travail](graphql/epic_work_items_api_migration_guide.md). Ce changement est un changement incompatible.

### Lister toutes les notes d'epic {#list-all-epic-notes}

Liste toutes les notes d'un epic spécifié. Les notes d'epic sont des commentaires que les utilisateurs peuvent publier sur un epic.

> [!note]
> L'API des notes d'epic utilise l'ID de l'epic et non l'IID de l'epic. Si vous utilisez l'IID de l'epic, GitLab renvoie une erreur 404 ou des notes pour le mauvais epic. Elle est différente de l'[API des notes d'issue](#issues) et de l'[API des notes de merge request](#merge-requests).

```plaintext
GET /groups/:id/epics/:epic_id/notes
GET /groups/:id/epics/:epic_id/notes?sort=asc&order_by=updated_at
```

| Attribut  | Type              | Obligatoire | Description |
|------------|-------------------|----------|-------------|
| `id`       | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `epic_id`  | entier           | oui      | L'ID d'un epic de groupe |
| `sort`     | string            | non       | Renvoie les notes d'epic triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc` |
| `order_by` | string            | non       | Renvoie les notes d'epic ordonnées par les champs `created_at` ou `updated_at`. La valeur par défaut est `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes"
```

### Récupérer une note d'epic {#retrieve-an-epic-note}

Récupère une note spécifiée pour un epic.

```plaintext
GET /groups/:id/epics/:epic_id/notes/:note_id
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `epic_id` | entier           | oui      | L'ID d'un epic |
| `note_id` | entier           | oui      | L'ID d'une note |

```json
{
  "id": 302,
  "body": "Epic note",
  "author": {
    "id": 1,
    "username": "pipin",
    "email": "admin@example.com",
    "name": "Pip",
    "state": "active",
    "created_at": "2013-09-30T13:46:01Z"
  },
  "created_at": "2013-10-02T09:22:45Z",
  "updated_at": "2013-10-02T10:22:45Z",
  "system": true,
  "noteable_id": 11,
  "noteable_type": "Epic",
  "project_id": 5,
  "noteable_iid": 11,
  "resolvable": false,
  "confidential": false,
  "internal": false,
  "imported": false,
  "imported_from": "none"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1"
```

### Créer une note d'epic {#create-an-epic-note}

Crée une note pour un epic spécifié. Les notes d'epic sont des commentaires que les utilisateurs peuvent publier sur un epic. Si vous créez une note dont le corps ne contient qu'une réaction emoji, GitLab renvoie cet objet.

```plaintext
POST /groups/:id/epics/:epic_id/notes
```

Paramètres :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `body`         | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `epic_id`      | entier           | oui      | L'ID d'un epic |
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `confidential` | boolean           | non       | **Déprécié** : Prévu pour être supprimé dans GitLab 16.0 et renommé en `internal`. L'indicateur confidentiel d'une note. La valeur par défaut est `false`. |
| `internal`     | boolean           | non       | L'indicateur interne d'une note. Remplace `confidential` lorsque les deux paramètres sont soumis. La valeur par défaut est `false`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes?body=note"
```

### Mettre à jour une note d'epic {#update-an-epic-note}

Met à jour une note spécifiée d'un epic.

```plaintext
PUT /groups/:id/epics/:epic_id/notes/:note_id
```

Paramètres :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `epic_id`      | entier           | oui      | L'ID d'un epic |
| `note_id`      | entier           | oui      | L'ID d'une note |
| `body`         | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `confidential` | boolean           | non       | **Déprécié** : Prévu pour être supprimé dans GitLab 16.0. L'indicateur confidentiel d'une note. La valeur par défaut est false. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/notes/1?body=note"
```

### Supprimer une note d'epic {#delete-an-epic-note}

Supprime une note existante d'un epic.

```plaintext
DELETE /groups/:id/epics/:epic_id/notes/:note_id
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `epic_id` | entier           | oui      | L'ID d'un epic |
| `note_id` | entier           | oui      | L'ID d'une note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/52/notes/1659"
```

## Wikis de projet {#project-wikis}

### Lister toutes les notes du wiki de projet {#list-all-project-wiki-notes}

Liste toutes les notes d'une page de wiki de projet spécifiée. Les notes du wiki de projet sont des commentaires que les utilisateurs peuvent publier sur une page de wiki.

> [!note]
> L'API des notes de page de wiki utilise l'ID meta de la page de wiki au lieu du slug de la page de wiki. Si vous utilisez le slug de la page, GitLab renvoie une erreur 404. Vous pouvez récupérer l'ID meta depuis l'[API des wikis de projet](wikis.md).

```plaintext
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes?sort=asc&order_by=updated_at
```

Paramètres :

| Attribut  | Type              | Obligatoire | Description |
|------------|-------------------|----------|-------------|
| `id`       | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `sort`     | string            | non       | Renvoie les notes de page de wiki triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc` |
| `order_by` | string            | non       | Renvoie les notes de page de wiki ordonnées par les champs `created_at` ou `updated_at`. La valeur par défaut est `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes"
```

### Récupérer une note de page de wiki {#retrieve-a-wiki-page-note}

Récupère une seule note pour une page de wiki spécifiée.

```plaintext
GET /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `note_id` | entier           | oui      | L'ID d'une note |

```json
{
  "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
  },
  "body": "foobar",
  "commands_changes": {},
  "confidential": false,
  "created_at": "2025-03-11T11:36:32.222Z",
  "id": 1218,
  "imported": false,
  "imported_from": "none",
  "internal": false,
  "noteable_id": 35,
  "noteable_iid": null,
  "noteable_type": "WikiPage::Meta",
  "project_id": 5,
  "resolvable": false,
  "system": false,
  "type": null,
  "updated_at": "2025-03-11T11:36:32.222Z"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218"
```

### Créer une note de page de wiki {#create-a-wiki-page-note}

Crée une nouvelle note pour une seule page de wiki. Les notes de page de wiki sont des commentaires que les utilisateurs peuvent publier sur une page de wiki.

```plaintext
POST /projects/:id/wiki_pages/:wiki_page_meta_id/notes
```

Paramètres :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `body`         | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes?body=note"
```

### Mettre à jour une note de page de wiki {#update-a-wiki-page-note}

Met à jour une note existante sur une page de wiki.

```plaintext
PUT /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Paramètres :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `note_id`      | entier           | oui      | L'ID d'une note |
| `body`         | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218?body=note"
```

### Supprimer une note de page de wiki {#delete-a-wiki-page-note}

Supprime une note d'une page de wiki.

```plaintext
DELETE /projects/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL du projet](rest/_index.md#namespaced-paths) |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `note_id` | entier           | oui      | L'ID d'une note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/wiki_pages/35/notes/1218"
```

## Wikis de groupe {#group-wikis}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

### Lister les notes du wiki de groupe {#list-group-wiki-notes}

Liste toutes les notes d'une page de wiki de groupe spécifiée. Les notes du wiki de groupe sont des commentaires que les utilisateurs peuvent publier sur une page de wiki.

> [!note]
> L'API des notes de page de wiki utilise l'ID meta de la page de wiki au lieu du slug de la page de wiki. Si vous utilisez le slug de la page, GitLab renvoie une erreur 404. Vous pouvez récupérer l'ID meta depuis l'[API des wikis de groupe](group_wikis.md).

```plaintext
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes?sort=asc&order_by=updated_at
```

| Attribut  | Type              | Obligatoire | Description |
|------------|-------------------|----------|-------------|
| `id`       | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `sort`     | string            | non       | Renvoie les notes de page de wiki triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc` |
| `order_by` | string            | non       | Renvoie les notes de page de wiki ordonnées par les champs `created_at` ou `updated_at`. La valeur par défaut est `created_at` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes"
```

### Récupérer une note de page de wiki {#retrieve-a-wiki-page-note-1}

Récupère une note spécifiée pour une page de wiki.

```plaintext
GET /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `note_id` | entier           | oui      | L'ID d'une note |

```json
{
  "author": {
      "id": 1,
      "username": "pipin",
      "email": "admin@example.com",
      "name": "Pip",
      "state": "active",
      "created_at": "2013-09-30T13:46:01Z"
  },
  "body": "foobar",
  "commands_changes": {},
  "confidential": false,
  "created_at": "2025-03-11T11:36:32.222Z",
  "id": 1218,
  "imported": false,
  "imported_from": "none",
  "internal": false,
  "noteable_id": 35,
  "noteable_iid": null,
  "noteable_type": "WikiPage::Meta",
  "project_id": null,
  "resolvable": false,
  "system": false,
  "type": null,
  "updated_at": "2025-03-11T11:36:32.222Z"
}
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218"
```

### Créer une note de page de wiki {#create-a-wiki-page-note-1}

Crée une note pour une page de wiki spécifiée. Les notes de page de wiki sont des commentaires que les utilisateurs peuvent publier sur une page de wiki.

```plaintext
POST /groups/:id/wiki_pages/:wiki_page_meta_id/notes
```

Paramètres :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `body`         | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes?body=note"
```

### Mettre à jour une note de page de wiki {#update-a-wiki-page-note-1}

Met à jour une note spécifiée sur une page wiki.

```plaintext
PUT /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Paramètres :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `note_id`      | entier           | oui      | L'ID d'une note |
| `body`         | string            | oui      | Le contenu d'une note. Limité à 1 000 000 de caractères. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218?body=note"
```

### Supprimer une note de page de wiki {#delete-a-wiki-page-note-1}

Supprime une note d'une page de wiki.

```plaintext
DELETE /groups/:id/wiki_pages/:wiki_page_meta_id/notes/:note_id
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `wiki_page_meta_id`  | entier           | oui      | L'ID d'un meta de page de wiki |
| `note_id` | entier           | oui      | L'ID d'une note |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/wiki_pages/35/notes/1218"
```
