---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des tableaux des tickets de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [tableaux des tickets](../user/project/issue_board.md). Chaque appel à cette API nécessite une authentification.

Si un utilisateur n'est pas membre d'un projet privé, une requête `GET` sur ce projet renvoie un code de statut `404`.

## Lister tous les tableaux des tickets de projet {#list-all-project-issue-boards}

Liste tous les tableaux des tickets dans un projet spécifié.

```plaintext
GET /projects/:id/boards
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards"
```

Exemple de réponse :

```json
[
  {
    "id" : 1,
    "name": "board1",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
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
        "position" : 1,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric": null
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      }
    ]
  }
]
```

Autre exemple de réponse lorsqu'aucun tableau n'a été activé ou n'existe dans le projet :

```json
[]
```

## Récupérer un tableau des tickets {#retrieve-an-issue-board}

Récupère un tableau des tickets spécifié dans un projet.

```plaintext
GET /projects/:id/boards/:board_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `board_id` | integer | oui | L'ID d'un tableau. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1"
```

Exemple de réponse :

```json
  {
    "id": 1,
    "name": "project issue board",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
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
        "position" : 1,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 2,
        "label" : {
          "name" : "Ready",
          "color" : "#FF0000",
          "description" : null
        },
        "position" : 2,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      },
      {
        "id" : 3,
        "label" : {
          "name" : "Production",
          "color" : "#FF5F00",
          "description" : null
        },
        "position" : 3,
        "max_issue_count": 0,
        "max_issue_weight": 0,
        "limit_metric":  null
      }
    ]
  }
```

## Créer un tableau des tickets {#create-an-issue-board}

Crée un tableau des tickets dans un projet spécifié.

```plaintext
POST /projects/:id/boards
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name` | string | oui | Le nom du nouveau tableau. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards" \
  --data "name=newboard"
```

Exemple de réponse :

```json
  {
    "id": 1,
    "name": "newboard",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site"
    },
    "lists" : [],
    "group": null,
    "milestone": null,
    "assignee" : null,
    "labels" : [],
    "weight" : null
  }
```

## Mettre à jour un tableau des tickets {#update-an-issue-board}

Met à jour un tableau des tickets spécifié dans un projet.

```plaintext
PUT /projects/:id/boards/:board_id
```

| Attribut                    | Type           | Obligatoire | Description |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `board_id`                   | integer        | oui      | L'ID d'un tableau. |
| `name`                       | string         | non       | Le nouveau nom du tableau. |
| `hide_backlog_list`          | boolean        | non       | Masquer la liste Ouverte. |
| `hide_closed_list`           | boolean        | non       | Masquer la liste Fermée. |
| `assignee_id`                | integer        | non       | Le cessionnaire auquel le tableau doit être limité en portée. Premium et Ultimate uniquement. |
| `milestone_id`               | integer        | non       | Le jalon auquel le tableau doit être limité en portée. Premium et Ultimate uniquement. |
| `labels`                     | string         | non       | Liste de noms de labels séparés par des virgules à laquelle le tableau doit être limité en portée. Premium et Ultimate uniquement. |
| `weight`                     | integer        | non       | La plage de poids de 0 à 9, à laquelle le tableau doit être limité en portée. Premium et Ultimate uniquement. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1" \
  --data "name=new_name&milestone_id=43&assignee_id=1&labels=Doing&weight=4"
```

Exemple de réponse :

```json
  {
    "id": 1,
    "name": "new_name",
    "hide_backlog_list": false,
    "hide_closed_list": false,
    "project": {
      "id": 5,
      "name": "Diaspora Project Site",
      "name_with_namespace": "Diaspora / Diaspora Project Site",
      "path": "diaspora-project-site",
      "path_with_namespace": "diaspora/diaspora-project-site",
      "created_at": "2018-07-03T05:48:49.982Z",
      "default_branch": null,
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "ssh_url_to_repo": "ssh://user@example.com/diaspora/diaspora-project-site.git",
      "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
      "web_url": "http://example.com/diaspora/diaspora-project-site",
      "readme_url": null,
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "last_activity_at": "2018-07-03T05:48:49.982Z"
    },
    "lists": [],
    "group": null,
    "milestone": {
      "id": 43,
      "iid": 1,
      "project_id": 15,
      "title": "Milestone 1",
      "description": "Milestone 1 desc",
      "state": "active",
      "created_at": "2018-07-03T06:36:42.618Z",
      "updated_at": "2018-07-03T06:36:42.618Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://example.com/root/board1/milestones/1"
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
      "id": 10,
      "name": "Doing",
      "color": "#5CB85C",
      "description": null
    }],
    "weight": 4
  }
```

## Supprimer un tableau des tickets {#delete-an-issue-board}

Supprime un tableau des tickets spécifié dans un projet.

```plaintext
DELETE /projects/:id/boards/:board_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `board_id` | integer | oui | L'ID d'un tableau. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1"
```

## Lister toutes les listes d'un tableau des tickets {#list-all-board-lists-in-an-issue-board}

Liste toutes les listes dans un tableau des tickets spécifié. N'inclut pas les listes `open` et `closed`.

```plaintext
GET /projects/:id/boards/:board_id/lists
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `board_id` | integer | oui | L'ID d'un tableau. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists"
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
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  },
  {
    "id" : 2,
    "label" : {
      "name" : "Ready",
      "color" : "#FF0000",
      "description" : null
    },
    "position" : 2,
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  },
  {
    "id" : 3,
    "label" : {
      "name" : "Production",
      "color" : "#FF5F00",
      "description" : null
    },
    "position" : 3,
    "max_issue_count": 0,
    "max_issue_weight": 0,
    "limit_metric":  null
  }
]
```

## Récupérer une liste de tableau {#retrieve-a-board-list}

Récupère une liste spécifiée d'un tableau des tickets.

```plaintext
GET /projects/:id/boards/:board_id/lists/:list_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `board_id` | integer | oui | L'ID d'un tableau. |
| `list_id`| integer | oui | L'ID d'une liste de tableau. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## Créer une liste de tableau {#create-a-board-list}

Crée une nouvelle liste de tableau des tickets.

```plaintext
POST /projects/:id/boards/:board_id/lists
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `board_id` | integer | oui | L'ID d'un tableau. |
| `label_id` | integer | non | L'ID d'un label. |
| `assignee_id` | integer | non | L'ID d'un utilisateur. Premium et Ultimate uniquement. |
| `milestone_id` | integer | non | L'ID d'un jalon. Premium et Ultimate uniquement. |
| `iteration_id` | integer | non | L'ID d'une itération. Premium et Ultimate uniquement. |

> [!note]
> Les arguments label, cessionnaire et jalon sont mutuellement exclusifs, c'est-à-dire qu'un seul d'entre eux est accepté dans une requête. Consultez la [documentation du tableau des tickets](../user/project/issue_board.md) pour plus d'informations concernant la licence requise pour chaque type de liste.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists" \
  --data "label_id=5"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## Mettre à jour une liste de tableau {#update-a-board-list}

Met à jour la position d'une liste spécifiée d'un tableau des tickets.

```plaintext
PUT /projects/:id/boards/:board_id/lists/:list_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `board_id` | integer | oui | L'ID d'un tableau. |
| `list_id` | integer | oui | L'ID d'une liste de tableau. |
| `position` | integer | oui | La position de la liste. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1" \
  --data "position=2"
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
  "max_issue_count": 0,
  "max_issue_weight": 0,
  "limit_metric":  null
}
```

## Supprimer une liste de tableau d'un tableau {#delete-a-board-list-from-a-board}

Supprime une liste spécifiée d'un tableau des tickets.

Prérequis :

- L'une ou l'autre des options :
  - Le rôle Planificateur, Reporter, Responsable sécurité, Developer, Maintainer ou Owner pour le projet.
  - Accès administrateur.

```plaintext
DELETE /projects/:id/boards/:board_id/lists/:list_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `board_id` | integer | oui | L'ID d'un tableau. |
| `list_id` | integer | oui | L'ID d'une liste de tableau. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/boards/1/lists/1"
```
