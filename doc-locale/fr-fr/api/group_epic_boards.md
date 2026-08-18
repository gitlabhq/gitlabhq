---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des tableaux d'epics de groupe"
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/385903) dans GitLab 15.9.

{{< /history >}}

Utilisez cette API pour gérer les [tableaux d'epics de groupe](../user/group/epics/epic_boards.md). Chaque requête adressée à cette API doit être authentifiée.

Si un utilisateur n'est pas membre d'un groupe et que le groupe est privé, une requête `GET` renvoie le code de statut `404`.

## Répertorier tous les tableaux d'epics dans un groupe {#list-all-epic-boards-in-a-group}

Répertorie tous les tableaux d'epics pour un groupe spécifié.

```plaintext
GET /groups/:id/epic_boards
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe accessible par l'utilisateur authentifié |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epic_boards"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "group epic board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "labels": [
      {
        "id": 1,
        "title": "Board Label",
        "color": "#c21e56",
        "description": "label applied to the epic board",
        "group_id": 5,
        "project_id": null,
        "template": false,
        "text_color": "#FFFFFF",
        "created_at": "2023-01-27T10:40:59.738Z",
        "updated_at": "2023-01-27T10:40:59.738Z"
      }
    ],
    "lists": [
      {
        "id": 1,
        "label": {
          "id": 69,
          "name": "Testing",
          "color": "#F0AD4E",
          "description": null
        },
        "position": 1,
        "list_type": "label"
      },
      {
        "id": 2,
        "label": {
          "id": 70,
          "name": "Ready",
          "color": "#FF0000",
          "description": null
        },
        "position": 2,
        "list_type": "label"
      },
      {
        "id": 3,
        "label": {
          "id": 71,
          "name": "Production",
          "color": "#FF5F00",
          "description": null
        },
        "position": 3,
        "list_type": "label"
      }
    ]
  }
]
```

## Récupérer un tableau d'epics de groupe {#retrieve-a-group-epic-board}

Récupère un tableau d'epics de groupe spécifié.

```plaintext
GET /groups/:id/epic_boards/:board_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe accessible par l'utilisateur authentifié |
| `board_id` | entier | oui | L'ID d'un tableau d'epics |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epic_boards/1"
```

Exemple de réponse :

```json
  {
    "id": 1,
    "name": "group epic board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "labels": [
      {
        "id": 1,
        "title": "Board Label",
        "color": "#c21e56",
        "description": "label applied to the epic board",
        "group_id": 5,
        "project_id": null,
        "template": false,
        "text_color": "#FFFFFF",
        "created_at": "2023-01-27T10:40:59.738Z",
        "updated_at": "2023-01-27T10:40:59.738Z"
      }
    ],
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "id": 69,
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1,
        "list_type": "label"
      },
      {
        "id" : 2,
        "label" : {
          "id": 70,
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "list_type": "label"
      },
      {
        "id" : 3,
        "label" : {
          "id": 71,
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "list_type": "label"
      }
    ]
  }
```

## Répertorier les listes du tableau d'epics de groupe {#list-group-epic-board-lists}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/385904) dans GitLab 15.9.

{{< /history >}}

Répertorie toutes les listes du tableau d'epics de groupe pour un tableau spécifié. N'inclut pas les listes `open` et `closed`.

```plaintext
GET /groups/:id/epic_boards/:board_id/lists
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe accessible par l'utilisateur authentifié |
| `board_id` | entier | oui | L'ID d'un tableau d'epics |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epic_boards/1/lists"
```

Exemple de réponse :

```json
[
  {
    "id" : 1,
    "label" : {
      "name" : "Testing",
      "color" : "#F0AD4E",
      "description" : null
    },
    "position" : 1,
    "list_type" : "label",
    "collapsed" : false
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2,
    "list_type" : "label",
    "collapsed" : false
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3,
    "list_type" : "label",
    "collapsed" : false
  }
]
```

## Récupérer une liste du tableau d'epics de groupe {#retrieve-a-group-epic-board-list}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/385904) dans GitLab 15.9.

{{< /history >}}

Récupère une liste du tableau d'epics de groupe spécifiée.

```plaintext
GET /groups/:id/epic_boards/:board_id/lists/:list_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe accessible par l'utilisateur authentifié |
| `board_id` | entier | oui | L'ID d'un tableau d'epics |
| `list_id` | entier | oui | L'ID de la liste d'un tableau d'epics |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epic_boards/1/lists/1"
```

Exemple de réponse :

```json
{
  "id" : 1,
  "label" : {
    "name" : "Testing",
    "color" : "#F0AD4E",
    "description" : null
  },
  "position" : 1,
  "list_type" : "label",
  "collapsed" : false
}
```
