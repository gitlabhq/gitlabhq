---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des liens de tickets dans GitLab."
title: API REST des liens de tickets
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La relation simple « se rapporte à » a été [déplacée](https://gitlab.com/gitlab-org/gitlab/-/issues/212329) vers GitLab Free dans la version 13.4.

{{< /history >}}

Utilisez cette API REST pour gérer les [tickets liés](../user/project/issues/related_issues.md).

## Répertorier tous les liens de tickets {#list-all-issue-links}

Répertorie tous les [tickets liés](../user/project/issues/related_issues.md) pour un ticket spécifié, triés par date et heure de création de la relation (ordre croissant). Les tickets sont filtrés en fonction des autorisations de l'utilisateur.

```plaintext
GET /projects/:id/issues/:issue_iid/links
```

Paramètres :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)  |
| `issue_iid` | integer | oui      | L'ID interne du ticket d'un projet |

```json
[
  {
    "id" : 84,
    "iid" : 14,
    "issue_link_id": 1,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null,
    "link_type": "relates_to",
    "link_created_at": "2016-01-07T12:44:33.959Z",
    "link_updated_at": "2016-01-07T12:44:33.959Z"
  }
]
```

## Récupérer un lien de ticket {#retrieve-an-issue-link}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88228) dans GitLab 15.1.
- L'attribut de réponse `id` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/585093) dans GitLab 18.9.

{{< /history >}}

Récupère les détails d'un lien de ticket spécifié.

```plaintext
GET /projects/:id/issues/:issue_iid/links/:issue_link_id
```

Attributs pris en charge :

| Attribut       | Type           | Obligatoire               | Description                                                                 |
|-----------------|----------------|------------------------|-----------------------------------------------------------------------------|
| `id`            | entier ou chaîne de caractères | Oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | Oui | ID interne du ticket d'un projet.                                           |
| `issue_link_id` | entier ou chaîne de caractères | Oui | ID d'une relation entre tickets.                                                |

Attributs du corps de la réponse :

| Attribut      | Type   | Description                                                                               |
|:---------------|:-------|:------------------------------------------------------------------------------------------|
| `id`           | integer | ID du lien de ticket.                                                                     |
| `source_issue` | objet | Détails du ticket source de la relation.                                          |
| `target_issue` | objet | Détails du ticket cible de la relation.                                          |
| `link_type`    | string | Type de la relation. Les valeurs possibles sont `relates_to`, `blocks` et `is_blocked_by`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/84/issues/14/links/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```

## Créer un lien de ticket {#create-an-issue-link}

{{< history >}}

- L'attribut de réponse `id` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/585093) dans GitLab 18.9.

{{< /history >}}

Crée une relation bidirectionnelle entre deux tickets. L'utilisateur doit être autorisé à mettre à jour les deux tickets pour que l'opération réussisse.

```plaintext
POST /projects/:id/issues/:issue_iid/links
```

| Attribut           | Type           | Obligatoire | Description                          |
|---------------------|----------------|----------|--------------------------------------|
| `id`                | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid`         | integer        | oui      | L'ID interne du ticket d'un projet |
| `target_project_id` | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) d'un projet cible  |
| `target_issue_iid`  | entier ou chaîne de caractères | oui      | L'ID interne du ticket d'un projet cible |
| `link_type`         | string         | non       | Le type de la relation (`relates_to`, `blocks`, `is_blocked_by`), par défaut `relates_to`). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/1/links?target_project_id=5&target_issue_iid=1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```

## Supprimer un lien de ticket {#delete-an-issue-link}

{{< history >}}

- L'attribut de réponse `id` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/585093) dans GitLab 18.9.

{{< /history >}}

Supprime un lien de ticket spécifié, en retirant la relation bidirectionnelle.

```plaintext
DELETE /projects/:id/issues/:issue_iid/links/:issue_link_id
```

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)  |
| `issue_iid` | integer | oui      | L'ID interne du ticket d'un projet |
| `issue_link_id` | entier ou chaîne de caractères | oui      | L'ID d'une relation entre tickets |
| `link_type` | string  | non | Le type de la relation (`relates_to`, `blocks`, `is_blocked_by`), par défaut `relates_to` |

```json
{
  "id": 1,
  "source_issue" : {
    "id" : 83,
    "iid" : 11,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/11",
    "confidential": false,
    "weight": null
  },
  "target_issue" : {
    "id" : 84,
    "iid" : 14,
    "project_id" : 4,
    "created_at" : "2016-01-07T12:44:33.959Z",
    "title" : "Issues with auth",
    "state" : "opened",
    "assignees" : [],
    "assignee" : null,
    "labels" : [
      "bug"
    ],
    "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
    },
    "description" : null,
    "updated_at" : "2016-01-07T12:44:33.959Z",
    "milestone" : null,
    "subscribed" : true,
    "user_notes_count": 0,
    "due_date": null,
    "web_url": "http://example.com/example/example/issues/14",
    "confidential": false,
    "weight": null
  },
  "link_type": "relates_to"
}
```
