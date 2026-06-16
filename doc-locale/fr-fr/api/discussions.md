---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Discussions
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [discussions](../user/discussions/_index.md). Cela inclut les [commentaires et fils de discussion](../user/discussions/_index.md), ainsi que les notes système relatives aux modifications d'un objet (par exemple, lorsqu'un jalon change).

Pour gérer les notes de label, utilisez l'[API des événements de label de ressource](resource_label_events.md).

## Comprendre les types de notes dans l'API {#understand-note-types-in-the-api}

Tous les types de discussions ne sont pas également disponibles dans l'API :

- Remarque : Un commentaire laissé à la _racine_ d'une ticket, d'une merge request, d'un commit ou d'un snippet.
- Discussion :  Une collection, souvent appelée _fil de discussion_, de `DiscussionNotes` dans une ticket, une merge request, un commit ou un snippet.
- DiscussionNote :  Un élément individuel dans une discussion sur une ticket, une merge request, un commit ou un snippet. Les éléments de type `DiscussionNote` ne sont pas retournés dans le cadre de l'API Note. Non disponible dans l'[API Events](events.md).

## Pagination des discussions {#discussions-pagination}

Par défaut, les requêtes `GET` retournent 20 résultats à la fois, car les résultats de l'API sont paginés.

En savoir plus sur la [pagination](rest/_index.md#pagination).

## Issues {#issues}

### Lister tous les éléments de discussion d'une issue {#list-all-issue-discussion-items}

Liste tous les éléments de discussion pour une ticket spécifiée dans un projet.

```plaintext
GET /projects/:id/issues/:issue_iid/discussions
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `id`        | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | entier           | Oui      | L'IID d'une ticket. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | string  | L'ID de la discussion. |
| `individual_note`       | boolean | Si `true`, une note individuelle ou une partie d'une discussion. |
| `notes`                 | tableau   | Tableau d'objets note dans la discussion. |
| `notes[].id`            | entier | L'ID de la note. |
| `notes[].type`          | string  | Le type de note (`DiscussionNote` ou `null`). |
| `notes[].body`          | string  | Le contenu de la note. |
| `notes[].author`        | objet  | L'auteur de la note. |
| `notes[].created_at`    | string  | Date de création de la note (format ISO 8601). |
| `notes[].updated_at`    | string  | Date de la dernière mise à jour de la note (format ISO 8601). |
| `notes[].system`        | boolean | Si `true`, une note système. |
| `notes[].noteable_id`   | entier | L'ID de l'objet notable. |
| `notes[].noteable_type` | string  | Le type de l'objet notable. |
| `notes[].project_id`    | entier | L'ID du projet. |
| `notes[].resolvable`    | boolean | Si `true`, la note peut être résolue. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions"
```

Exemple de réponse :

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Issue",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### Récupérer un élément de discussion d'une issue {#retrieve-an-issue-discussion-item}

Récupère un élément de discussion spécifié pour une ticket de projet.

```plaintext
GET /projects/:id/issues/:issue_iid/discussions/:discussion_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | entier            | Oui      | L'ID d'un élément de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`     | entier           | Oui      | L'IID d'une ticket. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'une issue](#list-all-issue-discussion-items).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>"
```

### Créer un fil de discussion pour une issue {#create-an-issue-thread}

Crée un nouveau fil de discussion pour une ticket de projet unique. Similaire à la création d'une note, mais d'autres commentaires (réponses) peuvent y être ajoutés ultérieurement.

```plaintext
POST /projects/:id/issues/:issue_iid/discussions
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `body`       | string            | Oui      | Le contenu du fil de discussion. |
| `id`         | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`  | entier           | Oui      | L'IID d'une ticket. |
| `created_at` | string            | Non       | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'une issue](#list-all-issue-discussion-items).

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions?body=comment"
```

### Ajouter une note à un fil de discussion d'une issue {#add-a-note-to-an-issue-thread}

Ajoute une nouvelle note au fil de discussion. Cela peut également [créer un fil de discussion à partir d'un commentaire unique](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment).

> [!note]
> Il est impossible d'ajouter des notes aux notes système. Toute tentative en ce sens retourne une erreur `400 Bad Request`.

```plaintext
POST /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `body`          | string            | Oui      | Le contenu de la note ou de la réponse. |
| `discussion_id` | entier            | Oui      | L'ID d'un fil de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`     | entier           | Oui      | L'IID d'une ticket. |
| `created_at`    | string            | Non       | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet note créé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes?body=comment"
```

### Mettre à jour une note de fil de discussion d'une issue {#update-an-issue-thread-note}

Met à jour une note de fil de discussion existante d'une ticket.

```plaintext
PUT /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `body`          | string            | Oui      | Le contenu de la note ou de la réponse. |
| `discussion_id` | entier            | Oui      | L'ID d'un fil de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`     | entier           | Oui      | L'IID d'une ticket. |
| `note_id`       | entier           | Oui      | L'ID d'une note de fil de discussion. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et l'objet note mis à jour.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### Supprimer une note de fil de discussion d'une issue {#delete-an-issue-thread-note}

Supprime une note de fil de discussion existante d'une ticket.

```plaintext
DELETE /projects/:id/issues/:issue_iid/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | entier            | Oui      | L'ID d'une discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`     | entier           | Oui      | L'IID d'une ticket. |
| `note_id`       | entier           | Oui      | L'ID d'une note de discussion. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/discussions/<discussion_id>/notes/<note_id>"
```

## Snippets {#snippets}

### Lister tous les éléments de discussion d'un snippet {#list-all-snippet-discussion-items}

Liste tous les éléments de discussion pour un snippet spécifié dans un projet.

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id` | entier           | Oui      | L'ID d'un snippet. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'une issue](#list-all-issue-discussion-items), avec `noteable_type` défini sur `Snippet`.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions"
```

Exemple de réponse :

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Snippet",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### Récupérer un élément de discussion d'un snippet {#retrieve-a-snippet-discussion-item}

Récupère un élément de discussion spécifié pour un snippet de projet.

```plaintext
GET /projects/:id/snippets/:snippet_id/discussions/:discussion_id
```

Attributs pris en charge :

| Attribut       | Type           | Obligatoire | Description |
| --------------- | -------------- | -------- | ----------- |
| `discussion_id` | entier         | Oui      | L'ID d'un élément de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id`    | entier        | Oui      | L'ID d'un snippet. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'un snippet](#list-all-snippet-discussion-items).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>"
```

### Créer un fil de discussion pour un snippet {#create-a-snippet-thread}

Crée un nouveau fil de discussion pour un snippet de projet unique. Similaire à la création d'une note, mais d'autres commentaires (réponses) peuvent y être ajoutés ultérieurement.

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `body`       | string            | Oui      | Le contenu d'une discussion. |
| `id`         | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id` | entier           | Oui      | L'ID d'un snippet. |
| `created_at` | string            | Non       | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet discussion créé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions?body=comment"
```

### Ajouter une note à un fil de discussion d'un snippet {#add-a-note-to-a-snippet-thread}

Ajoute une nouvelle note au fil de discussion.

```plaintext
POST /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `body`          | string            | Oui      | Le contenu de la note ou de la réponse. |
| `discussion_id` | entier            | Oui      | L'ID d'un fil de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `snippet_id`    | entier           | Oui      | L'ID d'un snippet. |
| `created_at`    | string            | Non       | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet note créé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes?body=comment"
```

### Mettre à jour une note de fil de discussion d'un snippet {#update-a-snippet-thread-note}

Met à jour une note de fil de discussion existante d'un snippet.

```plaintext
PUT /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut       | Type           | Obligatoire | Description |
| --------------- | -------------- | -------- | ----------- |
| `body`          | string         | Oui      | Le contenu de la note ou de la réponse. |
| `discussion_id` | entier         | Oui      | L'ID d'un fil de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `note_id`       | entier        | Oui      | L'ID d'une note de fil de discussion. |
| `snippet_id`    | entier        | Oui      | L'ID d'un snippet. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et l'objet note mis à jour.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### Supprimer une note de fil de discussion d'un snippet {#delete-a-snippet-thread-note}

Supprime une note de fil de discussion existante d'un snippet.

```plaintext
DELETE /projects/:id/snippets/:snippet_id/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | entier            | Oui      | L'ID d'une discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `note_id`       | entier           | Oui      | L'ID d'une note de discussion. |
| `snippet_id`    | entier           | Oui      | L'ID d'un snippet. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/snippets/11/discussions/<discussion_id>/notes/<note_id>"
```

## Epics {#epics}

{{< details >}}

- Édition :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> L'API REST des epics a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) dans GitLab 17.0 et sa suppression est prévue dans la v5 de l'API. Ce changement est un changement majeur.
>
> Utilisez plutôt l'API Work Items :
>
> - GitLab 17.4 à 18.0 :  Requis lorsque [le nouveau look pour les epics](../user/group/epics/_index.md#epics-as-work-items) est activé.
> - GitLab 18.1 et versions ultérieures :  Requis pour toutes les installations.
>
> Pour plus d'informations, consultez le [guide de migration de l'API](graphql/epic_work_items_api_migration_guide.md).

### Lister tous les éléments de discussion d'un epic {#list-all-epic-discussion-items}

Liste tous les éléments de discussion pour un seul epic.

```plaintext
GET /groups/:id/epics/:epic_id/discussions
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `epic_id` | entier           | Oui      | L'ID d'un epic. |
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'une issue](#list-all-issue-discussion-items), avec `noteable_type` défini sur `Epic`.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions"
```

Exemple de réponse :

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Epic",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

### Récupérer un élément de discussion d'un epic {#retrieve-an-epic-discussion-item}

Récupère un élément de discussion spécifié pour un epic de groupe.

```plaintext
GET /groups/:id/epics/:epic_id/discussions/:discussion_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | entier            | Oui      | L'ID d'un élément de discussion. |
| `epic_id`       | entier           | Oui      | L'ID d'un epic. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'un epic](#list-all-epic-discussion-items).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>"
```

### Créer un fil de discussion pour un epic {#create-an-epic-thread}

Crée un nouveau fil de discussion pour un seul epic de groupe. Similaire à la création d'une note, mais d'autres commentaires (réponses) peuvent y être ajoutés ultérieurement.

```plaintext
POST /groups/:id/epics/:epic_id/discussions
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `body`       | string            | Oui      | Le contenu du fil de discussion. |
| `epic_id`    | entier           | Oui      | L'ID d'un epic. |
| `id`         | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `created_at` | string            | Non       | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet discussion créé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions?body=comment"
```

### Ajouter une note à un fil de discussion d'un epic {#add-a-note-to-an-epic-thread}

Ajoute une nouvelle note au fil de discussion. Cela peut également [créer un fil de discussion à partir d'un commentaire unique](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment).

```plaintext
POST /groups/:id/epics/:epic_id/discussions/:discussion_id/notes
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `body`          | string            | Oui      | Le contenu de la note ou de la réponse. |
| `discussion_id` | entier            | Oui      | L'ID d'un fil de discussion. |
| `epic_id`       | entier           | Oui      | L'ID d'un epic. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `created_at`    | string            | Non       | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet note créé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes?body=comment"
```

### Mettre à jour une note de fil de discussion d'un epic {#update-an-epic-thread-note}

Met à jour une note de fil de discussion existante d'un epic.

```plaintext
PUT /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `body`          | string            | Oui      | Le contenu d'une note ou d'une réponse. |
| `discussion_id` | entier            | Oui      | L'ID d'un fil de discussion. |
| `epic_id`       | entier           | Oui      | L'ID d'un epic. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `note_id`       | entier           | Oui      | L'ID d'une note de fil de discussion. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et l'objet note mis à jour.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

### Supprimer une note de fil de discussion d'un epic {#delete-an-epic-thread-note}

Supprime une note de fil de discussion existante d'un epic.

```plaintext
DELETE /groups/:id/epics/:epic_id/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `discussion_id` | entier            | Oui      | L'ID d'un fil de discussion. |
| `epic_id`       | entier           | Oui      | L'ID d'un epic. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `note_id`       | entier           | Oui      | L'ID d'une note de fil de discussion. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/discussions/<discussion_id>/notes/<note_id>"
```

## Merge requests {#merge-requests}

### Lister tous les éléments de discussion d'une merge request {#list-all-merge-request-discussion-items}

Liste tous les éléments de discussion pour une merge request spécifiée.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'IID d'une merge request. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | string  | L'ID de la discussion. |
| `individual_note`       | boolean | Si `true`, une note individuelle ou une partie d'une discussion. |
| `notes`                 | tableau   | Tableau d'objets note dans la discussion. |
| `notes[].id`            | entier | L'ID de la note. |
| `notes[].type`          | string  | Le type de note (`DiscussionNote`, `DiffNote` ou `null`). |
| `notes[].body`          | string  | Le contenu de la note. |
| `notes[].author`        | objet  | L'auteur de la note. |
| `notes[].created_at`    | string  | Date de création de la note (format ISO 8601). |
| `notes[].updated_at`    | string  | Date de la dernière mise à jour de la note (format ISO 8601). |
| `notes[].system`        | boolean | Si `true`, une note système. |
| `notes[].noteable_id`   | entier | L'ID de l'objet notable. |
| `notes[].noteable_type` | string  | Le type de l'objet notable. |
| `notes[].project_id`    | entier | L'ID du projet. |
| `notes[].resolved`      | boolean | Si `true`, la note est résolue (merge requests uniquement). |
| `notes[].resolvable`    | boolean | Si `true`, la note peut être résolue. |
| `notes[].resolved_by`   | objet  | L'utilisateur qui a résolu la note. |
| `notes[].resolved_at`   | string  | Date de résolution de la note (format ISO 8601). |
| `notes[].position`      | objet  | Informations de position pour les notes de diff. |
| `notes[].suggestions`   | tableau   | Tableau d'objets de suggestion pour la note. |

Les commentaires de diff contiennent également des informations de position :

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
```

Exemple de réponse :

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null,
        "resolved_at": null
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "resolved": false,
        "resolvable": true,
        "resolved_by": null
      }
    ]
  }
]
```

Les commentaires de diff contiennent également la position :

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": "DiffNote",
        "body": "diff comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "MergeRequest",
        "project_id": 5,
        "noteable_iid": null,
        "commit_id": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
        "position": {
          "base_sha": "b5d6e7b1613fca24d250fa8e5bc7bcc3dd6002ef",
          "start_sha": "7c9c2ead8a320fb7ba0b4e234bd9529a2614e306",
          "head_sha": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
          "old_path": "package.json",
          "new_path": "package.json",
          "position_type": "text",
          "old_line": 27,
          "new_line": 27,
          "line_range": {
            "start": {
              "line_code": "588440f66559714280628a4f9799f0c4eb880a4a_10_10",
              "type": "new",
              "old_line": null,
              "new_line": 10
            },
            "end": {
              "line_code": "588440f66559714280628a4f9799f0c4eb880a4a_11_11",
              "type": "old",
              "old_line": 11,
              "new_line": 11
            }
          }
        },
        "resolved": false,
        "resolvable": true,
        "resolved_by": null,
        "suggestions": [
          {
            "id": 1,
            "from_line": 27,
            "to_line": 27,
            "appliable": true,
            "applied": false,
            "from_content": "x",
            "to_content": "b"
          }
        ]
      }
    ]
  }
]
```

### Récupérer un élément de discussion d'une merge request {#retrieve-a-merge-request-discussion-item}

Récupère un élément de discussion spécifié pour une merge request de projet.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | string            | Oui      | L'ID d'un élément de discussion. |
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'IID d'une merge request. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'une merge request](#list-all-merge-request-discussion-items).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>"
```

### Créer un fil de discussion pour une merge request {#create-a-merge-request-thread}

Crée un nouveau fil de discussion pour une seule merge request de projet. Similaire à la création d'une note, mais d'autres commentaires (réponses) peuvent y être ajoutés ultérieurement. Pour d'autres approches, consultez [Publier un commentaire sur un commit](commits.md#post-comment-to-commit) dans l'API Commits, et [Créer une note de merge request](notes.md#create-a-merge-request-note) dans l'API Notes.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions
```

Attributs pris en charge pour tous les commentaires :

| Attribut                 | Type              | Obligatoire                             | Description |
|---------------------------|-------------------|--------------------------------------|-------------|
| `body`                    | string            | Oui                                  | Le contenu du fil de discussion. |
| `id`                      | entier ou chaîne | Oui                                  | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid`       | entier           | Oui                                  | L'IID d'une merge request. |
| `commit_id`               | string            | Non                                   | SHA référençant le commit sur lequel démarrer cette discussion. |
| `created_at`              | string            | Non                                   | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |
| `position`                | hash              | Non                                   | Position lors de la création d'une note de diff. |
| `position[base_sha]`      | string            | Oui (si `position*` est fourni)     | SHA du commit de base dans la branche source. |
| `position[head_sha]`      | string            | Oui (si `position*` est fourni)     | SHA référençant le HEAD de cette merge request. |
| `position[start_sha]`     | string            | Oui (si `position*` est fourni)     | SHA référençant le commit dans la branche cible. |
| `position[position_type]` | string            | Oui (si position* est fourni)       | Type de la référence de position. Valeurs autorisées : `text`, `image` ou `file`. `file` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423046) dans GitLab 16.4. |
| `position[new_path]`      | string            | Oui (si le type de position est `text`) | Chemin du fichier après la modification. |
| `position[old_path]`      | string            | Oui (si le type de position est `text`) | Chemin du fichier avant la modification. |
| `position[new_line]`      | entier           | Non                                   | Pour les notes de diff `text`, le numéro de ligne après la modification. |
| `position[old_line]`      | entier           | Non                                   | Pour les notes de diff `text`, le numéro de ligne avant la modification. |
| `position[line_range]`    | hash              | Non                                   | Plage de lignes pour une note de diff multiligne. |
| `position[width]`         | entier           | Non                                   | Pour les notes de diff `image`, la largeur de l'image. |
| `position[height]`        | entier           | Non                                   | Pour les notes de diff `image`, la hauteur de l'image. |
| `position[x]`             | float             | Non                                   | Pour les notes de diff `image`, la coordonnée X. |
| `position[y]`             | float             | Non                                   | Pour les notes de diff `image`, la coordonnée Y. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet discussion créé.

#### Créer un nouveau fil de discussion sur la page d'aperçu {#create-a-new-thread-on-the-overview-page}

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions?body=comment"
```

#### Créer un nouveau fil de discussion dans le diff de la merge request {#create-a-new-thread-in-the-merge-request-diff}

- `position[old_path]` et `position[new_path]` sont obligatoires et doivent faire référence au chemin du fichier avant et après la modification.
- Pour créer un fil de discussion sur une ligne ajoutée (surlignée en vert dans le diff de la merge request), utilisez `position[new_line]` et n'incluez pas `position[old_line]`.
- Pour créer un fil de discussion sur une ligne supprimée (surlignée en rouge dans le diff de la merge request), utilisez `position[old_line]` et n'incluez pas `position[new_line]`.
- Pour créer un fil de discussion sur une ligne inchangée, incluez à la fois `position[new_line]` et `position[old_line]` pour la ligne. Ces positions peuvent ne pas être identiques si des modifications antérieures dans le fichier ont changé le numéro de ligne. Pour la discussion concernant un correctif, voir [issue 32516](https://gitlab.com/gitlab-org/gitlab/-/issues/325161).
- Si vous spécifiez des paramètres `base`, `head`, `start` ou `SHA` incorrects, vous pourriez rencontrer le bug décrit dans [l'issue #296829](https://gitlab.com/gitlab-org/gitlab/-/issues/296829).

Pour créer un nouveau fil de discussion :

1. [Obtenir la dernière version du diff de la merge request](merge_requests.md#retrieve-merge-request-diff-versions) :

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/versions"
   ```

1. Notez les détails de la dernière version, qui est répertoriée en premier dans le tableau de réponse.

   ```json
   [
     {
       "id": 164560414,
       "head_commit_sha": "f9ce7e16e56c162edbc9e480108041cf6b0291fe",
       "base_commit_sha": "5e6dffa282c5129aa67cd227a0429be21bfdaf80",
       "start_commit_sha": "5e6dffa282c5129aa67cd227a0429be21bfdaf80",
       "created_at": "2021-03-30T09:18:27.351Z",
       "merge_request_id": 93958054,
       "state": "collected",
       "real_size": "2"
     },
     "previous versions are here"
   ]
   ```

1. Créez un nouveau fil de discussion de diff. Cet exemple crée un fil de discussion sur une ligne ajoutée :

   ```shell
   curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --form 'position[position_type]=text' \
     --form 'position[base_sha]=<use base_commit_sha from the versions response>' \
     --form 'position[head_sha]=<use head_commit_sha from the versions response>' \
     --form 'position[start_sha]=<use start_commit_sha from the versions response>' \
     --form 'position[new_path]=file.js' \
     --form 'position[old_path]=file.js' \
     --form 'position[new_line]=18' \
     --form 'body=test comment body' \
     --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions"
   ```

#### Paramètres pour les commentaires multilignes {#parameters-for-multiline-comments}

Attributs pris en charge pour les commentaires multilignes uniquement :

| Attribut                                | Type    | Obligatoire | Description |
|------------------------------------------|---------|----------|-------------|
| `position[line_range][end][line_code]`   | string  | Oui      | [Code de ligne](#line-code) pour la ligne de fin. |
| `position[line_range][end][type]`        | string  | Oui      | Utilisez `new` pour les lignes ajoutées par ce commit, sinon `old`. |
| `position[line_range][end][old_line]`    | entier | Non       | Ancien numéro de ligne de la ligne de fin. |
| `position[line_range][end][new_line]`    | entier | Non       | Nouveau numéro de ligne de la ligne de fin. |
| `position[line_range][start][line_code]` | string  | Oui      | [Code de ligne](#line-code) pour la ligne de début. |
| `position[line_range][start][type]`      | string  | Oui      | Utilisez `new` pour les lignes ajoutées par ce commit, sinon `old`. |
| `position[line_range][start][old_line]`  | entier | Non       | Ancien numéro de ligne de la ligne de début. |
| `position[line_range][start][new_line]`  | entier | Non       | Nouveau numéro de ligne de la ligne de début. |
| `position[line_range][end]`              | hash    | Non       | Ligne de fin de la note multiligne. |
| `position[line_range][start]`            | hash    | Non       | Ligne de début de la note multiligne. |

Les paramètres `old_line` et `new_line` dans l'attribut `line_range` affichent la plage pour les commentaires multilignes. Par exemple, « Commentaire sur les lignes +296 à +297 ».

#### Code de ligne {#line-code}

Un code de ligne a la forme `<SHA>_<old>_<new>`, par exemple : `adc83b19e793491b1c6ea0fd8b46cd9f32e292fc_5_5`

- `<SHA>` est le hachage SHA1 du nom de fichier.
- `<old>` est le numéro de ligne avant la modification.
- `<new>` est le numéro de ligne après la modification.

Par exemple, si un commit (`<COMMIT_ID>`) supprime la ligne 463 dans le README, vous pouvez commenter la suppression en référençant la ligne 463 dans l'ancien fichier :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Very clever to remove this unnecessary line!" \
  --form "path=README" \
  --form "line=463" \
  --form "line_type=old" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

Si un commit (`<COMMIT_ID>`) ajoute la ligne 157 à `hello.rb`, vous pouvez commenter l'ajout en référençant la ligne 157 dans le nouveau fichier :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=This is brilliant!" \
  --form "path=hello.rb" \
  --form "line=157" \
  --form "line_type=new" \
  --url "https://gitlab.com/api/v4/projects/47/repository/commits/<COMMIT_ID>/comments"
```

### Résoudre un fil de discussion d'une merge request {#resolve-a-merge-request-thread}

Résoudre ou rouvrir un fil de discussion dans une merge request.

Prérequis :

- Vous devez disposer du rôle Développeur, Mainteneur ou Propriétaire, ou être l'auteur de la modification en cours de révision.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | string            | Oui      | L'ID d'un fil de discussion. |
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'IID d'une merge request. |
| `resolved`          | boolean           | Oui      | Si `true`, résoudre ou rouvrir la discussion. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et l'objet discussion mis à jour.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>?resolved=true"
```

### Ajouter une note à un fil de discussion d'une merge request {#add-note-to-a-merge-request-thread}

Ajoute une nouvelle note au fil de discussion. Cela peut également [créer un fil de discussion à partir d'un commentaire unique](../user/discussions/_index.md#create-a-thread-by-replying-to-a-standard-comment).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `body`              | string            | Oui      | Le contenu de la note ou de la réponse. |
| `discussion_id`     | string            | Oui      | L'ID d'un fil de discussion. |
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'IID d'une merge request. |
| `created_at`        | string            | Non       | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet note créé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes?body=comment"
```

### Mettre à jour une note de fil de discussion d'une merge request {#update-a-merge-request-thread-note}

Met à jour ou résout une note de fil de discussion spécifiée pour une merge request.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | string            | Oui      | L'ID d'un fil de discussion. |
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'IID d'une merge request. |
| `note_id`           | entier           | Oui      | L'ID d'une note de fil de discussion. |
| `body`              | string            | Non       | Le contenu de la note ou de la réponse. Exactement l'un des paramètres `body` ou `resolved` doit être défini. |
| `resolved`          | boolean           | Non       | Résoudre ou rouvrir la note. Exactement l'un des paramètres `body` ou `resolved` doit être défini. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et l'objet note mis à jour.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

Résolution d'une note :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>?resolved=true"
```

### Supprimer une note de fil de discussion d'une merge request {#delete-a-merge-request-thread-note}

Supprime une note de fil de discussion existante d'une merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `discussion_id`     | string            | Oui      | L'ID d'un fil de discussion. |
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'IID d'une merge request. |
| `note_id`           | entier           | Oui      | L'ID d'une note de fil de discussion. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/discussions/<discussion_id>/notes/<note_id>"
```

## Commits {#commits}

### Lister tous les éléments de discussion d'un commit {#list-all-commit-discussion-items}

Liste tous les éléments de discussion pour un commit spécifié.

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `commit_id` | string            | Oui      | Le SHA d'un commit. |
| `id`        | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'une issue](#list-all-issue-discussion-items), avec `noteable_type` défini sur `Commit`.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions"
```

Exemple de réponse :

```json
[
  {
    "id": "6a9c1750b37d513a43987b574953fceb50b03ce7",
    "individual_note": false,
    "notes": [
      {
        "id": 1126,
        "type": "DiscussionNote",
        "body": "discussion text",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-03T21:54:39.668Z",
        "updated_at": "2018-03-03T21:54:39.668Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      },
      {
        "id": 1129,
        "type": "DiscussionNote",
        "body": "reply to the discussion",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T13:38:02.127Z",
        "updated_at": "2018-03-04T13:38:02.127Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  },
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": true,
    "notes": [
      {
        "id": 1128,
        "type": null,
        "body": "a single comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "resolvable": false
      }
    ]
  }
]
```

Les commentaires de diff contiennent aussi la position :

```json
[
  {
    "id": "87805b7c09016a7058e91bdbe7b29d1f284a39e6",
    "individual_note": false,
    "notes": [
      {
        "id": 1128,
        "type": "DiffNote",
        "body": "diff comment",
        "attachment": null,
        "author": {
          "id": 1,
          "name": "root",
          "username": "root",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/00afb8fb6ab07c3ee3e9c1f38777e2f4?s=80&d=identicon",
          "web_url": "http://localhost:3000/root"
        },
        "created_at": "2018-03-04T09:17:22.520Z",
        "updated_at": "2018-03-04T09:17:22.520Z",
        "system": false,
        "noteable_id": 3,
        "noteable_type": "Commit",
        "project_id": 5,
        "noteable_iid": null,
        "position": {
          "base_sha": "b5d6e7b1613fca24d250fa8e5bc7bcc3dd6002ef",
          "start_sha": "7c9c2ead8a320fb7ba0b4e234bd9529a2614e306",
          "head_sha": "4803c71e6b1833ca72b8b26ef2ecd5adc8a38031",
          "old_path": "package.json",
          "new_path": "package.json",
          "position_type": "text",
          "old_line": 27,
          "new_line": 27
        },
        "resolvable": false
      }
    ]
  }
]
```

### Récupérer un élément de discussion d'un commit {#retrieve-a-commit-discussion-item}

Récupère un élément de discussion spécifié pour un commit de projet.

```plaintext
GET /projects/:id/repository/commits/:commit_id/discussions/:discussion_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `commit_id`     | string            | Oui      | Le SHA d'un commit. |
| `discussion_id` | string            | Oui      | L'ID d'un élément de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les mêmes attributs de réponse que [Lister les éléments de discussion d'un commit](#list-all-commit-discussion-items).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>"
```

### Créer un fil de discussion de commit {#create-a-commit-thread}

Crée un nouveau fil de discussion pour un commit de projet unique. Similaire à la création d'une note, mais d'autres commentaires (réponses) peuvent y être ajoutés ultérieurement.

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions
```

Attributs pris en charge :

| Attribut                 | Type              | Obligatoire                         | Description |
|---------------------------|-------------------|----------------------------------|-------------|
| `body`                    | string            | Oui                              | Le contenu du fil de discussion. |
| `commit_id`               | string            | Oui                              | Le SHA d'un commit. |
| `id`                      | entier ou chaîne | Oui                              | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `created_at`              | string            | Non                               | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |
| `position`                | hash              | Non                               | Position lors de la création d'une note de diff. |
| `position[base_sha]`      | string            | Oui (si `position*` est fourni) | SHA du commit parent. |
| `position[head_sha]`      | string            | Oui (si `position*` est fourni) | Le SHA de ce commit. Identique à `commit_id`. |
| `position[start_sha]`     | string            | Oui (si `position*` est fourni) | SHA du commit parent. |
| `position[position_type]` | string            | Oui (si `position*` est fourni) | Type de la référence de position. Valeurs autorisées : `text`, `image` ou `file`. `file` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423046) dans GitLab 16.4. |
| `position[new_path]`      | string            | Non                               | Chemin du fichier après la modification. |
| `position[new_line]`      | entier           | Non                               | Numéro de ligne après la modification. |
| `position[old_path]`      | string            | Non                               | Chemin du fichier avant la modification. |
| `position[old_line]`      | entier           | Non                               | Numéro de ligne avant la modification. |
| `position[height]`        | entier           | Non                               | Pour les notes de diff `image`, hauteur de l'image. |
| `position[width]`         | entier           | Non                               | Pour les notes de diff `image`, largeur de l'image. |
| `position[x]`             | entier           | Non                               | Pour les notes de diff `image`, la coordonnée X. |
| `position[y]`             | entier           | Non                               | Pour les notes de diff `image`, la coordonnée Y. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet discussion créé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions?body=comment"
```

Les règles de création de la requête API sont les mêmes que lors de la [création d'un nouveau fil de discussion dans le diff de la merge request](#create-a-new-thread-in-the-merge-request-diff). Les exceptions :

- `base_sha`
- `head_sha`
- `start_sha`

### Ajouter une note à un fil de discussion de commit {#add-note-to-a-commit-thread}

Ajoute une nouvelle note au fil de discussion.

```plaintext
POST /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `body`          | string            | Oui      | Le contenu de la note ou de la réponse. |
| `commit_id`     | string            | Oui      | Le SHA d'un commit. |
| `discussion_id` | string            | Oui      | L'ID d'un fil de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `created_at`    | string            | Non       | Chaîne de date et heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire de projet/groupe. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et l'objet note créé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes?body=comment"
```

### Mettre à jour une note de fil de discussion de commit {#update-a-commit-thread-note}

Met à jour ou résout une note de fil de discussion spécifiée pour un commit.

```plaintext
PUT /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `body`          | string            | Non       | Le contenu d'une note. |
| `commit_id`     | string            | Oui      | Le SHA d'un commit. |
| `discussion_id` | string            | Oui      | L'ID d'un fil de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `note_id`       | entier           | Oui      | L'ID d'une note de fil de discussion. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et l'objet note mis à jour.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>?body=comment"
```

Résolution d'une note :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>?resolved=true"
```

### Supprimer une note de discussion d'un commit {#delete-a-commit-discussion-note}

Supprime une note de discussion existante d'un commit.

```plaintext
DELETE /projects/:id/repository/commits/:commit_id/discussions/:discussion_id/notes/:note_id
```

Attributs pris en charge :

| Attribut       | Type              | Obligatoire | Description |
|-----------------|-------------------|----------|-------------|
| `commit_id`     | string            | Oui      | Le SHA d'un commit. |
| `discussion_id` | string            | Oui      | L'ID d'un fil de discussion. |
| `id`            | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `note_id`       | entier           | Oui      | L'ID d'une note de fil de discussion. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/<commit_id>/discussions/<discussion_id>/notes/<note_id>"
```
