---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des réactions emoji
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/issues/409884) de « award emoji » en « emoji reactions » dans GitLab 16.0.

{{< /history >}}

Utilisez cette API pour gérer les [réactions emoji](../user/emoji_reactions.md).

Les objets GitLab qui acceptent les réactions emoji sont appelés awardables. Vous pouvez réagir avec des emoji sur les ressources suivantes :

- [Epics](../user/group/epics/_index.md) ([API](epics.md)).
- [Issues](../user/project/issues/_index.md) ([API](issues.md)).
- [Merge requests](../user/project/merge_requests/_index.md) ([API](merge_requests.md)).
- [Snippets](../user/snippets.md) ([API](snippets.md)).
- [Commentaires](../user/emoji_reactions.md#emoji-reactions-for-comments) ([API](notes.md)).

## Issues, merge requests et snippets {#issues-merge-requests-and-snippets}

Pour plus d'informations sur l'utilisation de ces endpoints avec les commentaires, voir [Ajouter des réactions aux commentaires](#add-reactions-to-comments).

### Lister toutes les réactions emoji pour une ressource {#list-all-emoji-reactions-for-a-resource}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/335068) dans GitLab 15.1 pour autoriser l'accès non authentifié aux awardables publics.

{{< /history >}}

Liste toutes les réactions emoji pour une issue, un snippet ou une merge request spécifiés. Cet endpoint est accessible sans authentification si l'awardable est accessible publiquement.

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji
GET /projects/:id/snippets/:snippet_id/award_emoji
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | entier        | oui      | ID (`iid` pour les merge requests/issues, `id` pour les snippets) d'un awardable.     |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji"
```

Exemple de réponse :

```json
[
  {
    "id": 4,
    "name": "1234",
    "user": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2016-06-15T10:09:34.206Z",
    "updated_at": "2016-06-15T10:09:34.206Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  },
  {
    "id": 1,
    "name": "microphone",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/user4"
    },
    "created_at": "2016-06-15T10:09:34.177Z",
    "updated_at": "2016-06-15T10:09:34.177Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  }
]
```

### Récupérer une réaction emoji depuis une ressource {#retrieve-an-emoji-reaction-from-a-resource}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/335068) dans GitLab 15.1 pour autoriser l'accès non authentifié aux awardables publics.

{{< /history >}}

Récupère une réaction emoji spécifiée depuis une issue, un snippet ou une merge request. Cet endpoint est accessible sans authentification si l'awardable est accessible publiquement.

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji/:award_id
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
GET /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | entier        | oui      | ID (`iid` pour les merge requests/issues, `id` pour les snippets) d'un awardable.     |
| `award_id`     | entier        | oui      | ID de la réaction emoji.                                                       |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "microphone",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user4"
  },
  "created_at": "2016-06-15T10:09:34.177Z",
  "updated_at": "2016-06-15T10:09:34.177Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### Ajouter une réaction emoji à une ressource {#add-an-emoji-reaction-to-a-resource}

Ajoute une réaction emoji à une issue, un snippet ou une merge request.

```plaintext
POST /projects/:id/issues/:issue_iid/award_emoji
POST /projects/:id/merge_requests/:merge_request_iid/award_emoji
POST /projects/:id/snippets/:snippet_id/award_emoji
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | entier        | oui      | ID (`iid` pour les merge requests/issues, `id` pour les snippets) d'un awardable.     |
| `name`         | string         | oui      | Nom de l'emoji sans deux-points.                                            |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji?name=blowfish"
```

Exemple de réponse :

```json
{
  "id": 344,
  "name": "blowfish",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2016-06-17T17:47:29.266Z",
  "updated_at": "2016-06-17T17:47:29.266Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### Supprimer une réaction emoji d'une ressource {#delete-an-emoji-reaction-from-a-resource}

Supprime une réaction emoji spécifiée d'une issue, d'un snippet ou d'une merge request.

Seul un administrateur ou l'auteur de la réaction peut supprimer une réaction emoji.

```plaintext
DELETE /projects/:id/issues/:issue_iid/award_emoji/:award_id
DELETE /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
DELETE /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`/`merge_request_iid`/`snippet_id` | entier        | oui      | ID (`iid` pour les merge requests/issues, `id` pour les snippets) d'un awardable.     |
| `award_id`     | entier        | oui      | ID d'une réaction emoji.                                                        |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/344"
```

## Ajouter des réactions aux commentaires {#add-reactions-to-comments}

Les commentaires (aussi appelés notes) sont une sous-ressource des issues, des merge requests et des snippets.

> [!note]
> Les exemples ci-dessous décrivent l'utilisation des réactions emoji sur les commentaires d'une issue, mais peuvent être adaptés aux commentaires sur les merge requests et les snippets. Par conséquent, vous devez remplacer `issue_iid` par `merge_request_iid` ou par `snippet_id`.

### Lister toutes les réactions emoji pour un commentaire {#list-all-emoji-reactions-for-a-comment}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/335068) dans GitLab 15.1 pour autoriser l'accès non authentifié aux commentaires publics.

{{< /history >}}

Liste toutes les réactions emoji pour un commentaire spécifié. Cet endpoint est accessible sans authentification si le commentaire est accessible publiquement.

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

Paramètres :

| Attribut   | Type           | Obligatoire | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | entier ou chaîne | oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | entier        | oui      | ID interne d'une issue.                                                     |
| `note_id`   | entier        | oui      | ID d'un commentaire (note).                                                      |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji"
```

Exemple de réponse :

```json
[
  {
    "id": 2,
    "name": "mood_bubble_lightning",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/user4"
    },
    "created_at": "2016-06-15T10:09:34.197Z",
    "updated_at": "2016-06-15T10:09:34.197Z",
    "awardable_id": 1,
    "awardable_type": "Note"
  }
]
```

### Récupérer une réaction emoji depuis un commentaire {#retrieve-an-emoji-reaction-from-a-comment}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/335068) dans GitLab 15.1 pour autoriser l'accès non authentifié aux commentaires publics.

{{< /history >}}

Récupère une réaction emoji depuis un commentaire spécifié. Cet endpoint est accessible sans authentification si le commentaire est accessible publiquement.

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

Paramètres :

| Attribut   | Type           | Obligatoire | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | entier ou chaîne | oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | entier        | oui      | ID interne d'une issue.                                                     |
| `note_id`   | entier        | oui      | ID d'un commentaire (note).                                                      |
| `award_id`  | entier        | oui      | ID de la réaction emoji.                                                       |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji/2"
```

Exemple de réponse :

```json
{
  "id": 2,
  "name": "mood_bubble_lightning",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user4"
  },
  "created_at": "2016-06-15T10:09:34.197Z",
  "updated_at": "2016-06-15T10:09:34.197Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### Ajouter une réaction emoji à un commentaire {#add-an-emoji-reaction-to-a-comment}

Ajoute une réaction emoji à un commentaire spécifié.

```plaintext
POST /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

Paramètres :

| Attribut   | Type           | Obligatoire | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | entier ou chaîne | oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | entier        | oui      | ID interne d'une issue.                                                     |
| `note_id`   | entier        | oui      | ID d'un commentaire (note).                                                      |
| `name`      | string         | oui      | Nom de l'emoji sans deux-points.                                            |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji?name=rocket"
```

Exemple de réponse :

```json
{
  "id": 345,
  "name": "rocket",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2016-06-17T19:59:55.888Z",
  "updated_at": "2016-06-17T19:59:55.888Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### Supprimer une réaction emoji d'un commentaire {#delete-an-emoji-reaction-from-a-comment}

Supprime une réaction emoji d'un commentaire spécifié.

Seul un administrateur ou l'auteur de la réaction peut supprimer une réaction emoji.

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

Paramètres :

| Attribut   | Type           | Obligatoire | Description                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | entier ou chaîne | oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | entier        | oui      | ID interne d'une issue.                                                     |
| `note_id`   | entier        | oui      | ID d'un commentaire (note).                                                      |
| `award_id`  | entier        | oui      | ID d'une réaction emoji.                                                        |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/345"
```
