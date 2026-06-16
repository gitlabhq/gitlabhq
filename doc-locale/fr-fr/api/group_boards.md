---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des tableaux des tickets de groupe
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [tableaux des tickets de groupe](../user/project/issue_board.md#group-issue-boards). Chaque appel à cette API nécessite une authentification.

Si un utilisateur n'est pas membre d'un groupe et que le groupe est privé, une requête `GET` renvoie le code de statut `404`.

## Lister tous les tableaux des tickets de groupe dans un groupe {#list-all-group-issue-boards-in-a-group}

Liste tous les tableaux des tickets de groupe pour un groupe spécifié.

```plaintext
GET /groups/:id/boards
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
]
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient des paramètres différents, en raison de la possibilité d'avoir plusieurs tableaux de groupe.

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
]
```

## Récupérer un tableau des tickets de groupe {#retrieve-a-group-issue-board}

Récupère un tableau des tickets de groupe spécifié.

```plaintext
GET /groups/:id/boards/:board_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `board_id` | entier | oui | L'ID d'un tableau. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

Exemple de réponse :

```json
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient des paramètres différents, en raison de la possibilité d'avoir plusieurs tableaux des tickets de groupe.

Exemple de réponse :

```json
  {
    "id": 1,
    "name": "group issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone":   {
      "id": 12,
      "title": "10.0"
    },
    "lists" : [
      {
        "id" : 1,
        "label" : {
          "name" : "Testing",
          "color" : "#F0AD4E",
          "description" : null
        },
        "position" : 1
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3
      }
    ]
  }
```

## Créer un tableau des tickets de groupe {#create-a-group-issue-board}

{{< details >}}

- Édition :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Crée un tableau des tickets de groupe pour un groupe spécifié.

```plaintext
POST /groups/:id/boards
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `name` | string | oui | Le nom du nouveau tableau. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards?name=newboard"
```

Exemple de réponse :

```json
  {
    "id": 1,
    "name": "newboard",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": null,
    "lists" : [],
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone": null,
    "assignee" : null,
    "labels" : [],
    "weight" : null
  }
```

## Mettre à jour un tableau des tickets de groupe {#update-a-group-issue-board}

Met à jour un tableau des tickets de groupe spécifié.

```plaintext
PUT /groups/:id/boards/:board_id
```

| Attribut                    | Type           | Obligatoire | Description |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `board_id`                   | entier        | oui      | L'ID d'un tableau. |
| `name`                       | string         | non       | Le nouveau nom du tableau. |
| `hide_backlog_list`          | boolean        | non       | Masquer la liste Ouvert. |
| `hide_closed_list`           | boolean        | non       | Masquer la liste Fermé. |
| `assignee_id`                | entier        | non       | Le cessionnaire auquel le tableau doit être limité dans sa portée. Premium et Ultimate uniquement. |
| `milestone_id`               | entier        | non       | Le jalon auquel le tableau doit être limité dans sa portée. Premium et Ultimate uniquement. |
| `labels`                     | string         | non       | Liste des noms de labels séparés par des virgules, à laquelle le tableau doit être limité dans sa portée. Premium et Ultimate uniquement. |
| `weight`                     | entier        | non       | La plage de poids de 0 à 9, à laquelle le tableau doit être limité dans sa portée. Premium et Ultimate uniquement. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1?name=new_name&milestone_id=44&assignee_id=1&labels=GroupLabel&weight=4"
```

Exemple de réponse :

```json
  {
    "id": 1,
    "name": "new_name",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": null,
    "lists": [],
    "group": {
      "id": 5,
      "name": "Documentcloud",
      "web_url": "http://example.com/groups/documentcloud"
    },
    "milestone": {
      "id": 44,
      "iid": 1,
      "group_id": 5,
      "title": "Group Milestone",
      "description": "Group Milestone Desc",
      "state": "active",
      "created_at": "2018-07-03T07:15:19.271Z",
      "updated_at": "2018-07-03T07:15:19.271Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://example.com/groups/documentcloud/-/milestones/1"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://example.com/root"
    },
    "labels": [{
      "id": 11,
      "name": "GroupLabel",
      "color": "#428BCA",
      "description": ""
    }],
    "weight": 4
  }
```

## Supprimer un tableau des tickets de groupe {#delete-a-group-issue-board}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Supprime un tableau des tickets de groupe spécifié.

```plaintext
DELETE /groups/:id/boards/:board_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `board_id` | entier | oui | L'ID d'un tableau. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1"
```

## Lister les listes du tableau des tickets de groupe {#list-group-issue-board-lists}

Liste toutes les listes du tableau des tickets de groupe pour un tableau spécifié. N'inclut pas les listes `open` et `closed`.

```plaintext
GET /groups/:id/boards/:board_id/lists
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `board_id` | entier | oui | L'ID d'un tableau. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists"
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
    "position" : 1
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3
  }
]
```

## Récupérer une liste du tableau des tickets de groupe {#retrieve-a-group-issue-board-list}

Récupère une liste du tableau des tickets de groupe spécifiée.

```plaintext
GET /groups/:id/boards/:board_id/lists/:list_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `board_id` | entier | oui | L'ID d'un tableau. |
| `list_id` | entier | oui | L'ID d'une liste du tableau. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
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
  "position" : 1
}
```

## Créer une liste du tableau des tickets de groupe {#create-a-group-issue-board-list}

Crée une liste du tableau des tickets de groupe pour un tableau spécifié.

```plaintext
POST /groups/:id/boards/:board_id/lists
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `board_id` | entier | oui | L'ID d'un tableau. |
| `label_id` | entier | non | L'ID d'un label. |
| `assignee_id` | entier | non | L'ID d'un utilisateur. Premium et Ultimate uniquement. |
| `milestone_id` | entier | non | L'ID d'un jalon. Premium et Ultimate uniquement. |
| `iteration_id` | entier | non | L'ID d'une itération. Premium et Ultimate uniquement. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/12/lists?milestone_id=7"
```

Exemple de réponse :

```json
{
  "id": 9,
  "label": null,
  "position": 0,
  "milestone": {
    "id": 7,
    "iid": 3,
    "group_id": 12,
    "title": "Milestone with due date",
    "description": "",
    "state": "active",
    "created_at": "2017-09-03T07:16:28.596Z",
    "updated_at": "2017-09-03T07:16:49.521Z",
    "due_date": null,
    "start_date": null,
    "web_url": "https://gitlab.example.com/groups/issue-reproduce/-/milestones/3"
  }
}
```

## Mettre à jour une liste du tableau des tickets de groupe {#update-a-group-issue-board-list}

Met à jour une liste du tableau des tickets de groupe spécifiée. Cet appel est utilisé pour modifier la position de la liste.

```plaintext
PUT /groups/:id/boards/:board_id/lists/:list_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`            | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `board_id` | entier | oui | L'ID d'un tableau. |
| `list_id` | entier | oui | L'ID d'une liste du tableau. |
| `position` | entier | oui | La position de la liste. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1?position=2"
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
  "position" : 1
}
```

## Supprimer une liste du tableau des tickets de groupe {#delete-a-group-issue-board-list}

Supprime une liste du tableau des tickets de groupe spécifiée. Réservé aux administrateurs et aux propriétaires de groupe.

```plaintext
DELETE /groups/:id/boards/:board_id/lists/:list_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `board_id` | entier | oui | L'ID d'un tableau. |
| `list_id` | entier | oui | L'ID d'une liste du tableau. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/boards/1/lists/1"
```
