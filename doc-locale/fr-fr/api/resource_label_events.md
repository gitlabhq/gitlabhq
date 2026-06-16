---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des événements de label de ressource
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer les événements de label de ressource qui suivent qui, quand, et quel [label](../user/project/labels.md) a été ajouté à (ou supprimé d') un ticket, une merge request ou un epic.

## Tickets {#issues}

### Répertorier les événements de label de ticket d'un projet {#list-project-issue-label-events}

Répertorie tous les événements de label pour un seul ticket.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_label_events
```

| Attribut           | Type             | Obligatoire   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid`         | entier          | oui        | L'IID d'un ticket |

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
    "label": {
      "id": 73,
      "name": "a1",
      "color": "#34495E",
      "description": ""
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
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "label": {
      "id": 74,
      "name": "p1",
      "color": "#0033CC",
      "description": ""
    },
    "action": "remove"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_label_events"
```

### Récupérer un seul événement de label de ticket {#retrieve-a-single-issue-label-event}

Récupère un seul événement de label pour un ticket de projet spécifique.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_label_events/:resource_label_event_id
```

Paramètres :

| Attribut       | Type           | Obligatoire | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid`     | entier        | oui      | L'IID d'un ticket |
| `resource_label_event_id` | entier        | oui      | L'ID d'un événement de label |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_label_events/1"
```

## Epics {#epics}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> L'API REST Epics a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) dans GitLab 17.0 et sa suppression est prévue dans la v5 de l'API. De GitLab 17.4 à 18.0, si [le nouveau look des epics](../user/group/epics/_index.md#epics-as-work-items) est activé, et dans GitLab 18.1 et versions ultérieures, utilisez plutôt l'API Work Items. Pour plus d'informations, voir [migrer les API epics vers les work items](graphql/epic_work_items_api_migration_guide.md). Ce changement est un changement radical.

### Répertorier les événements de label d'epic d'un groupe {#list-group-epic-label-events}

Répertorie tous les événements de label pour un seul epic.

```plaintext
GET /groups/:id/epics/:epic_id/resource_label_events
```

| Attribut           | Type             | Obligatoire   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `epic_id`           | entier          | oui        | L'ID d'un epic |

```json
[
  {
    "id": 106,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-19T11:43:01.746Z",
    "resource_type": "Epic",
    "resource_id": 33,
    "label": {
      "id": 73,
      "name": "a1",
      "color": "#34495E",
      "description": ""
    },
    "action": "add"
  },
  {
    "id": 107,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-19T11:43:01.746Z",
    "resource_type": "Epic",
    "resource_id": 33,
    "label": {
      "id": 37,
      "name": "glabel2",
      "color": "#A8D695",
      "description": ""
    },
    "action": "add"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/11/resource_label_events"
```

### Récupérer un seul événement de label d'epic {#retrieve-a-single-epic-label-event}

Récupère un seul événement de label pour un epic de groupe spécifique.

```plaintext
GET /groups/:id/epics/:epic_id/resource_label_events/:resource_label_event_id
```

Paramètres :

| Attribut       | Type           | Obligatoire | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `epic_id`       | entier        | oui      | L'ID d'un epic |
| `resource_label_event_id` | entier        | oui      | L'ID d'un événement de label |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/11/resource_label_events/107"
```

## Merge requests {#merge-requests}

### Répertorier les événements de label de merge request d'un projet {#list-project-merge-request-label-events}

Répertorie tous les événements de label pour une seule merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_label_events
```

| Attribut           | Type             | Obligatoire   | Description  |
| ------------------- | ---------------- | ---------- | ------------ |
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | entier          | oui        | L'IID d'une merge request |

```json
[
  {
    "id": 119,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T06:17:28.394Z",
    "resource_type": "MergeRequest",
    "resource_id": 28,
    "label": {
      "id": 74,
      "name": "p1",
      "color": "#0033CC",
      "description": ""
    },
    "action": "add"
  },
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
    "created_at": "2018-08-20T06:17:28.394Z",
    "resource_type": "MergeRequest",
    "resource_id": 28,
    "label": {
      "id": 41,
      "name": "project",
      "color": "#D1D100",
      "description": ""
    },
    "action": "add"
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_label_events"
```

### Récupérer un seul événement de label de merge request {#retrieve-a-single-merge-request-label-event}

Récupère un seul événement de label pour une merge request de projet spécifique.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/resource_label_events/:resource_label_event_id
```

Paramètres :

| Attribut           | Type           | Obligatoire | Description |
| ------------------- | -------------- | -------- | ----------- |
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | entier        | oui      | L'IID d'une merge request |
| `resource_label_event_id`     | entier        | oui      | L'ID d'un événement de label |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/resource_label_events/120"
```
