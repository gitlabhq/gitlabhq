---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des événements d'état des ressources"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les événements de changement d'état des tickets, des merge requests et des epics.

Cette API ne suit pas l'état initial (`created` ou `opened`) des ressources. Pour une ressource qui n'a pas été fermée ou rouverte, une liste vide est retournée.

## Issues {#issues}

### Répertorier les événements d'état d'un ticket de projet {#list-project-issue-state-events}

Répertorie tous les événements d'état d'un seul ticket.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events
```

| Attribut   | Type           | Obligatoire | Description                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid` | entier        | oui      | L'IID d'un ticket                                                             |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_state_events"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### Récupérer un seul événement d'état de ticket {#retrieve-a-single-issue-state-event}

Récupère un seul événement d'état pour un ticket de projet spécifique.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_state_events/:resource_state_event_id
```

Paramètres :

| Attribut                     | Type           | Obligatoire | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet |
| `issue_iid`                   | entier        | oui      | L'IID d'un ticket                                                             |
| `resource_state_event_id`     | entier        | oui      | L'ID d'un événement d'état                                                     |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_state_events/143"
```

Exemple de réponse :

```json
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
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```

## Merge requests {#merge-requests}

### Répertorier les événements d'état de merge request d'un projet {#list-project-merge-request-state-events}

Répertorie tous les événements d'état d'une seule merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_state_events
```

| Attribut           | Type           | Obligatoire | Description                                                                     |
| ------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet |
| `merge_request_iid` | entier        | oui      | L'IID d'une merge request                                                      |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_state_events"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### Récupérer un seul événement d'état de merge request {#retrieve-a-single-merge-request-state-event}

Récupère un seul événement d'état pour une merge request de projet spécifique.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_state_events/:resource_state_event_id
```

Paramètres :

| Attribut                     | Type           | Obligatoire | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid`           | entier        | oui      | L'IID d'une merge request                                                      |
| `resource_state_event_id`     | entier        | oui      | L'ID d'un événement d'état                                                     |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_state_events/120"
```

Exemple de réponse :

```json
{
  "id": 120,
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
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```

## Epics {#epics}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97554) dans GitLab 15.4.

{{< /history >}}

> [!warning]
> L'API REST Epics a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) dans GitLab 17.0 et sa suppression est prévue dans la v5 de l'API. De GitLab 17.4 à 18.0, si [le nouveau look pour les epics](../user/group/epics/_index.md#epics-as-work-items) est activé, et dans GitLab 18.1 et versions ultérieures, utilisez plutôt l'API Work Items. Pour plus d'informations, consultez [migrer les APIs d'epic vers les éléments de travail](graphql/epic_work_items_api_migration_guide.md). Ce changement est un changement de rupture.

### Répertorier les événements d'état d'epic de groupe {#list-group-epic-state-events}

Répertorie tous les événements d'état d'un seul epic.

```plaintext
GET /groups/:id/epics/:epic_id/resource_state_events
```

| Attribut   | Type           | Obligatoire | Description                                                                    |
|-------------| -------------- | -------- |--------------------------------------------------------------------------------|
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.   |
| `epic_id`   | entier        | oui      | L'ID d'un epic.                                                              |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/resource_state_events"
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
    "resource_type": "Epic",
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "opened"
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
    "resource_type": "Epic",
    "resource_id": 11,
    "source_commit": null,
    "source_merge_request_id": null,
    "state": "closed"
  }
]
```

### Récupérer un seul événement d'état d'epic {#retrieve-a-single-epic-state-event}

Récupère un seul événement d'état d'epic.

```plaintext
GET /groups/:id/epics/:epic_id/resource_state_events/:resource_state_event_id
```

Paramètres :

| Attribut                 | Type           | Obligatoire | Description                                                                   |
|---------------------------| -------------- | -------- |-------------------------------------------------------------------------------|
| `id`                      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.  |
| `epic_id`                 | entier        | oui      | L'ID d'un epic.                                                           |
| `resource_state_event_id` | entier        | oui      | L'ID d'un événement d'état.                                                       |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/epics/11/resource_state_events/143"
```

Exemple de réponse :

```json
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
  "resource_type": "Epic",
  "resource_id": 11,
  "source_commit": null,
  "source_merge_request_id": null,
  "state": "closed"
}
```
