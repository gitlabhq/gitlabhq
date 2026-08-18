---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
title: API Événements
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/13056) le type de cible `epics` dans GitLab 17.3.

{{< /history >}}

Utilisez cette API pour consulter l'activité des événements. Les événements peuvent inclure un large éventail d'actions, notamment rejoindre des projets, commenter des tickets, envoyer des modifications vers des merge requests, ou fermer des epics.

Pour des informations sur les limites de rétention des activités, consultez :

- [Limite de la période d'activité des utilisateurs](../user/profile/contributions_calendar.md#event-time-period-limit)
- [Limite de la période d'activité des projets](../user/project/working_with_projects.md#view-project-activity)

Cette API présente des limitations liées aux epics, aux merge requests et aux événements de push en masse :

- Certaines fonctionnalités des epics, comme les éléments enfants, les éléments liés, les dates de début, les dates d'échéance et les statuts de santé, ne sont pas renvoyées par l'API.
- Certaines notes de merge request peuvent utiliser à la place le type `DiscussionNote`. Ce type de cible [n'est pas pris en charge par l'API](discussions.md#understand-note-types-in-the-api).
- Les événements de push en masse créés lorsqu'un push dépasse la [limite d'activités d'événements de push](../administration/settings/push_event_activities_limit.md) sont renvoyés avec des détails limités : `commit_count: 0`, `ref_count` indiquant le nombre de refs envoyées, et des valeurs `null` pour les attributs de commit individuels (`commit_from`, `commit_to`, `ref`, `commit_title`).

## Lister tous les événements {#list-all-events}

Liste tous les événements pour l'utilisateur authentifié. Ne renvoie pas les événements associés aux epics ou aux merge requests. Renvoie les événements de push en masse avec des détails de commit limités.

Prérequis :

- Votre jeton d'accès doit avoir soit la portée `read_user`, soit la portée `api`.

```plaintext
GET /events
```

Paramètres :

| Paramètre     | Type            | Obligatoire | Description |
| ------------- | --------------- | -------- | ----------- |
| `action`      | string          | non       | Si défini, renvoie les événements avec le [type d'action](../user/profile/contributions_calendar.md#user-contribution-events) spécifié. |
| `target_type` | string          | non       | Si défini, renvoie les événements spécifiés. Valeurs possibles : `epic`, `issue`, `merge_request`, `milestone`, `note`, `project`, `snippet` et `user`. |
| `before`      | date (ISO 8601) | non       | Si défini, renvoie les événements créés avant la date spécifiée. |
| `after`       | date (ISO 8601) | non       | Si défini, renvoie les événements créés après la date spécifiée. |
| `scope`       | string          | non       | Inclut tous les événements dans les projets d'un utilisateur. |
| `sort`        | string          | non       | Direction du tri des résultats par date de création. Valeurs possibles : `asc`, `desc`. Par défaut : `desc`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01&scope=all"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 160,
    "target_iid": 53,
    "target_type": "Issue",
    "author_id": 25,
    "target_title": "Qui natus eos odio tempore et quaerat consequuntur ducimus cupiditate quis.",
    "created_at": "2017-02-09T10:43:19.667Z",
    "author": {
      "name": "User 3",
      "username": "user3",
      "id": 25,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/user3"
    },
    "author_username": "user3",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 2,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 159,
    "target_iid": 14,
    "target_type": "Issue",
    "author_id": 21,
    "target_title": "Nostrum enim non et sed optio illo deleniti non.",
    "created_at": "2017-02-09T10:43:19.426Z",
    "author": {
      "name": "Test User",
      "username": "ted",
      "id": 21,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/80fb888c9a48b9a3f87477214acaa63f?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/ted"
    },
    "author_username": "ted",
    "imported": false,
    "imported_from": "none"
  }
]
```

## Récupérer les événements de contribution pour un utilisateur {#retrieve-contribution-events-for-a-user}

Récupère les événements de contribution pour un utilisateur spécifié. Ne renvoie pas les événements associés aux epics ou aux merge requests. Renvoie les événements de push en masse avec des détails de commit limités.

Prérequis :

- Votre jeton d'accès doit avoir soit la portée `read_user`, soit la portée `api`.

```plaintext
GET /users/:id/events
```

Paramètres :

| Paramètre     | Type            | Obligatoire | Description |
| ------------- | --------------- | -------- | ----------- |
| `id`          | integer         | oui      | ID ou nom d'utilisateur d'un utilisateur. |
| `action`      | string          | non       | Si défini, renvoie les événements avec le [type d'action](../user/profile/contributions_calendar.md#user-contribution-events) spécifié. |
| `target_type` | string          | non       | Si défini, renvoie les événements spécifiés. Valeurs possibles : `epic`, `issue`, `merge_request`, `milestone`, `note`, `project`, `snippet` et `user`. |
| `before`      | date (ISO 8601) | non       | Si défini, renvoie les événements créés avant la date spécifiée. |
| `after`       | date (ISO 8601) | non       | Si défini, renvoie les événements créés après la date spécifiée. |
| `sort`        | string          | non       | Direction du tri des résultats par date de création. Valeurs possibles : `asc`, `desc`. Par défaut : `desc`. |
| `page`        | integer         | non       | Renvoie la page de résultats spécifiée. Par défaut : `1`. |
| `per_page`    | integer         | non       | Nombre de résultats par page. Par défaut : `20`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/:id/events"
```

Exemple de réponse :

```json
[
  {
    "id": 3,
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 830,
    "target_iid": 82,
    "target_type": "Issue",
    "author_id": 1,
    "target_title": "Public project search field",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 4,
    "title": null,
    "project_id": 15,
    "action_name": "pushed",
    "target_id": null,
    "target_iid": null,
    "target_type": null,
    "author_id": 1,
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "john",
    "imported": false,
    "imported_from": "none",
    "push_data": {
      "commit_count": 1,
      "action": "pushed",
      "ref_type": "branch",
      "commit_from": "50d4420237a9de7be1304607147aec22e4a14af7",
      "commit_to": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "ref": "main",
      "commit_title": "Add simple search to projects in public area"
    },
    "target_title": null
  },
  {
    "id": 5,
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 840,
    "target_iid": 11,
    "target_type": "Issue",
    "author_id": 1,
    "target_title": "Finish & merge Code search PR",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 7,
    "title": null,
    "project_id": 15,
    "action_name": "commented on",
    "target_id": 1312,
    "target_iid": 61,
    "target_type": "Note",
    "author_id": 1,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "http://localhost:3000/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "noteable_id": 377,
      "noteable_type": "Issue"
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  }
]
```

## Lister tous les événements visibles pour un projet {#list-all-visible-events-for-a-project}

Liste tous les événements visibles pour un projet spécifié. Renvoie les événements de push en masse créés lorsqu'un push dépasse la [limite d'activités d'événements de push](../administration/settings/push_event_activities_limit.md) avec des détails de commit limités : `commit_count: 0`, `ref_count` indiquant le nombre de refs envoyées, et des valeurs `null` pour les attributs de commit individuels.

```plaintext
GET /projects/:project_id/events
```

Paramètres :

| Paramètre     | Type            | Obligatoire | Description |
| ------------- | --------------- | -------- | ----------- |
| `project_id`  | entier ou chaîne de caractères  | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un projet. |
| `action`      | string          | non       | Si défini, renvoie les événements avec le [type d'action](../user/profile/contributions_calendar.md#user-contribution-events) spécifié. |
| `target_type` | string          | non       | Si défini, renvoie les événements spécifiés. Valeurs possibles : `epic`, `issue`, `merge_request`, `milestone`, `note`, `project`, `snippet` et `user`. |
| `before`      | date (ISO 8601) | non       | Si défini, renvoie les événements créés avant la date spécifiée. |
| `after`       | date (ISO 8601) | non       | Si défini, renvoie les événements créés après la date spécifiée. |
| `sort`        | string          | non       | Direction du tri des résultats par date de création. Valeurs possibles : `asc`, `desc`. Par défaut : `desc`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:project_id/events?target_type=issue&action=created&after=2017-01-31&before=2017-03-01"
```

Exemple de réponse :

```json
[
  {
    "id": 8,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 160,
    "target_iid": 160,
    "target_type": "Issue",
    "author_id": 25,
    "target_title": "Qui natus eos odio tempore et quaerat consequuntur ducimus cupiditate quis.",
    "created_at": "2017-02-09T10:43:19.667Z",
    "author": {
      "name": "User 3",
      "username": "user3",
      "id": 25,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97d6d9441ff85fdc730e02a6068d267b?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/user3"
    },
    "author_username": "user3",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 9,
    "title": null,
    "project_id": 1,
    "action_name": "opened",
    "target_id": 159,
    "target_iid": 159,
    "target_type": "Issue",
    "author_id": 21,
    "target_title": "Nostrum enim non et sed optio illo deleniti non.",
    "created_at": "2017-02-09T10:43:19.426Z",
    "author": {
      "name": "Test User",
      "username": "ted",
      "id": 21,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/80fb888c9a48b9a3f87477214acaa63f?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/ted"
    },
    "author_username": "ted",
    "imported": false,
    "imported_from": "none"
  },
  {
    "id": 10,
    "title": null,
    "project_id": 1,
    "action_name": "commented on",
    "target_id": 1312,
    "target_iid": 1312,
    "target_type": "Note",
    "author_id": 1,
    "data": null,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "https://gitlab.example.com/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "https://gitlab.example.com/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "noteable_id": 377,
      "noteable_type": "Issue",
      "noteable_iid": 377
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "https://gitlab.example.com/root"
    },
    "author_username": "root",
    "imported": false,
    "imported_from": "none"
  }
]
```
