---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'API Epic Issues pour lister, lier et dissocier des tickets avec des epics."
title: API Epic Issues (dépréciée)
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> L'API REST Epics a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) dans GitLab 17.0 et sa suppression est prévue dans la v5 de l'API. De GitLab 17.4 à 18.0, si [le nouveau look pour les epics](../user/group/epics/_index.md#epics-as-work-items) est activé, et dans GitLab 18.1 et versions ultérieures, utilisez plutôt l'API Work Items. Pour plus d'informations, consultez [migrer les API epics vers les éléments de travail](graphql/epic_work_items_api_migration_guide.md). Ce changement est un changement cassant.

Chaque appel d'API vers le point de terminaison de l'API Epic Issues doit être authentifié.

Si un utilisateur n'est pas membre d'un groupe et que le groupe est privé, une requête `GET` sur ce groupe renvoie un code de statut `404`.

Les epics sont disponibles uniquement dans GitLab [Premium et Ultimate](https://about.gitlab.com/pricing/). Si la fonctionnalité Epics n'est pas disponible, un code de statut `403` est renvoyé.

## Lister tous les tickets d'un epic {#list-all-issues-for-an-epic}

Liste tous les tickets assignés à un epic spécifié.

Les réponses sont [paginées](rest/_index.md#pagination) et renvoient 20 résultats par défaut.

```plaintext
GET /groups/:id/epics/:epic_iid/issues
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe                |
| `epic_iid`          | entier ou chaîne   | oui        | L'ID interne de l'epic.  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues"
```

Exemple de réponse :

```json
[
  {
    "id": 76,
    "iid": 6,
    "project_id": 8,
    "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description" : "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2017-11-15T13:39:24.670Z",
    "updated_at": "2018-01-04T10:49:19.506Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 8,
      "title": "v2.0",
      "description": "In tempore culpa inventore quo accusantium.",
      "state": "closed",
      "created_at": "2017-11-15T13:39:13.825Z",
      "updated_at": "2017-11-15T13:39:13.825Z",
      "due_date": null,
      "start_date": null
    },
    "assignees": [{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    }],
    "assignee": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "author": {
      "id": 13,
      "name": "Michell Johns",
      "username": "chris_hahn",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/30e3b2122ccd6b8e45e8e14a3ffb58fc?s=80&d=identicon",
      "web_url": "http://localhost:3001/chris_hahn"
    },
    "user_notes_count": 8,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "_links":{
      "self": "http://localhost:3001/api/v4/projects/8/issues/6",
      "notes": "http://localhost:3001/api/v4/projects/8/issues/6/notes",
      "award_emoji": "http://localhost:3001/api/v4/projects/8/issues/6/award_emoji",
      "project": "http://localhost:3001/api/v4/projects/8"
    },
    "epic_issue_id": 2
  }
]
```

> [!note]
> La colonne `assignee` est dépréciée. Elle est désormais un tableau `assignees` de taille unique.

## Assigner un ticket à un epic {#assign-an-issue-to-an-epic}

Assigne un ticket à un epic spécifié. Si le ticket appartient déjà à un autre epic, il est d'abord désassigné de cet epic.

```plaintext
POST /groups/:id/epics/:epic_iid/issues/:issue_id
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe                |
| `epic_iid`          | entier ou chaîne   | oui        | L'ID interne de l'epic.  |
| `issue_id`          | entier ou chaîne   | oui        | L'ID du ticket.          |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/55"
```

Exemple de réponse :

```json
{
  "id": 11,
  "epic": {
    "id": 30,
    "iid": 5,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null
  },
  "issue": {
    "id": 55,
    "iid": 13,
    "project_id": 8,
    "title": "Beatae laborum voluptatem voluptate eligendi ex accusamus.",
    "description": "Quam veritatis debitis omnis aliquam sit.",
    "state": "opened",
    "created_at": "2017-11-05T13:59:12.782Z",
    "updated_at": "2018-01-05T10:33:03.900Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 48,
      "iid": 6,
      "project_id": 8,
      "title": "Sprint - Sed sed maxime temporibus ipsa ullam qui sit.",
      "description": "Quos veritatis qui expedita sunt deleniti accusamus.",
      "state": "active",
      "created_at": "2017-11-05T13:59:12.445Z",
      "updated_at": "2017-11-05T13:59:12.445Z",
      "due_date": "2017-11-13",
      "start_date": "2017-11-05"
    },
    "assignees": [{
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    }],
    "assignee": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "author": {
      "id": 25,
      "name": "User 3",
      "username": "user3",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "http://localhost:3001/user3"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/13",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
}
```

> [!note]
> La colonne `assignee` est dépréciée. Elle est désormais un tableau `assignees` de taille unique.

## Retirer un ticket d'un epic {#remove-an-issue-from-an-epic}

Retire un ticket d'un epic spécifié.

```plaintext
DELETE /groups/:id/epics/:epic_iid/issues/:epic_issue_id
```

| Attribut           | Type             | Obligatoire   | Description                                                                                          |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe                |
| `epic_iid`          | entier ou chaîne   | oui        | L'ID interne de l'epic.                |
| `epic_issue_id`     | entier ou chaîne   | oui        | L'ID de l'association epic-ticket.     |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/11"
```

Exemple de réponse :

```json
{
  "id": 11,
  "epic": {
    "id": 30,
    "iid": 5,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "start_date": null,
    "end_date": null
  },
  "issue": {
    "id": 223,
    "iid": 13,
    "project_id": 8,
    "title": "Beatae laborum voluptatem voluptate eligendi ex accusamus.",
    "description": "Quam veritatis debitis omnis aliquam sit.",
    "state": "opened",
    "created_at": "2017-11-05T13:59:12.782Z",
    "updated_at": "2018-01-05T10:33:03.900Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 48,
      "iid": 6,
      "project_id": 8,
      "title": "Sprint - Sed sed maxime temporibus ipsa ullam qui sit.",
      "description": "Quos veritatis qui expedita sunt deleniti accusamus.",
      "state": "active",
      "created_at": "2017-11-05T13:59:12.445Z",
      "updated_at": "2017-11-05T13:59:12.445Z",
      "due_date": "2017-11-13",
      "start_date": "2017-11-05"
    },
    "assignees": [{
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    }],
    "assignee": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
    },
    "author": {
      "id": 25,
      "name": "User 3",
      "username": "user3",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "http://localhost:3001/user3"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/13",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
}
```

> [!note]
> La colonne `assignee` est dépréciée. Elle est désormais un tableau `assignees` de taille unique.

## Mettre à jour une association epic-ticket {#update-an-epic-issue-association}

Met à jour une association epic-ticket.

```plaintext
PUT /groups/:id/epics/:epic_iid/issues/:epic_issue_id
```

| Attribut           | Type             | Obligatoire   | Description                                                                                          |
| ------------------- | ---------------- | ---------- | -----------------------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe                |
| `epic_iid`          | entier ou chaîne   | oui        | L'ID interne de l'epic.                |
| `epic_issue_id`     | entier ou chaîne   | oui        | L'ID de l'association epic-ticket.     |
| `move_before_id`    | entier ou chaîne   | non         | L'ID de l'association epic-ticket qui doit être placée avant le lien en question.     |
| `move_after_id`     | entier ou chaîne   | non         | L'ID de l'association epic-ticket qui doit être placée après le lien en question.     |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/issues/11?move_before_id=20"
```

Exemple de réponse :

```json
[
  {
    "id": 30,
    "iid": 6,
    "project_id": 8,
    "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description" : "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2017-11-15T13:39:24.670Z",
    "updated_at": "2018-01-04T10:49:19.506Z",
    "closed_at": null,
    "labels": [],
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 8,
      "title": "v2.0",
      "description": "In tempore culpa inventore quo accusantium.",
      "state": "closed",
      "created_at": "2017-11-15T13:39:13.825Z",
      "updated_at": "2017-11-15T13:39:13.825Z",
      "due_date": null,
      "start_date": null
    },
    "assignees": [{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    }],
    "assignee": {
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://localhost:3001/arnita"
    },
    "author": {
      "id": 13,
      "name": "Michell Johns",
      "username": "chris_hahn",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/30e3b2122ccd6b8e45e8e14a3ffb58fc?s=80&d=identicon",
      "web_url": "http://localhost:3001/chris_hahn"
    },
    "user_notes_count": 8,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "weight": null,
    "discussion_locked": null,
    "web_url": "http://localhost:3001/h5bp/html5-boilerplate/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "_links":{
      "self": "http://localhost:3001/api/v4/projects/8/issues/6",
      "notes": "http://localhost:3001/api/v4/projects/8/issues/6/notes",
      "award_emoji": "http://localhost:3001/api/v4/projects/8/issues/6/award_emoji",
      "project": "http://localhost:3001/api/v4/projects/8"
    },
    "subscribed": true,
    "epic_issue_id": 11,
    "relative_position": 55
  }
]
```
