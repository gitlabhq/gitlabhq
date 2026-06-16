---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des événements de jalon de ressource
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les événements de jalon pour les tickets et les merge requests.

## Tickets {#issues}

### Lister les événements de jalon d'un ticket de projet {#list-project-issue-milestone-events}

Liste tous les événements de jalon pour un seul ticket.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_milestone_events
```

| Attribut   | Type           | Obligatoire | Description                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid` | entier        | oui      | L'IID d'un ticket                                                             |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_milestone_events"
```

Exemple de réponse :

```json
[
  {
    "id": 142,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "add"
  },
  {
    "id": 143,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "remove"
  }
]
```

### Récupérer un seul événement de jalon d'un ticket {#retrieve-a-single-issue-milestone-event}

Récupère un seul événement de jalon pour un ticket de projet spécifique.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_milestone_events/:resource_milestone_event_id
```

Paramètres :

| Attribut                     | Type           | Obligatoire | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du projet |
| `issue_iid`                   | entier        | oui      | L'IID d'un ticket                                                             |
| `resource_milestone_event_id` | entier        | oui      | L'identifiant d'un événement de jalon                                                     |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_milestone_events/1"
```

## Merge requests {#merge-requests}

### Lister les événements de jalon d'une merge request de projet {#list-project-merge-request-milestone-events}

Liste tous les événements de jalon pour une seule merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_milestone_events
```

| Attribut           | Type           | Obligatoire | Description                                                                     |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du projet |
| `merge_request_iid` | entier        | oui      | L'IID d'une merge request                                                      |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_milestone_events"
```

Exemple de réponse :

```json
[
  {
    "id": 142,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "MergeRequest",
    "resource_id": 142,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "add"
  },
  {
    "id": 143,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "MergeRequest",
    "resource_id": 142,
    "milestone":   {
      "id": 61,
      "iid": 9,
      "project_id": 7,
      "title": "v1.2",
      "description": "Ipsum Lorem",
      "state": "active",
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null,
      "web_url": "http://gitlab.example.com:3000/group/project/-/milestones/9"
    },
    "action": "remove"
  }
]
```

### Récupérer un seul événement de jalon d'une merge request {#retrieve-a-single-merge-request-milestone-event}

Récupère un seul événement de jalon pour une merge request de projet spécifique.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_milestone_events/:resource_milestone_event_id
```

Paramètres :

| Attribut                     | Type           | Obligatoire | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | entier        | oui      | L'IID d'une merge request                                                      |
| `resource_milestone_event_id` | entier        | oui      | L'identifiant d'un événement de jalon                                                     |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_milestone_events/120"
```
