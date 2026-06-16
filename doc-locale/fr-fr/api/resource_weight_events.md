---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des événements de poids de ressources
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour accéder aux événements de modification de poids pour les tickets.

## Issues {#issues}

### Lister tous les événements de poids d'un ticket de projet {#list-all-project-issue-weight-events}

Liste tous les événements de poids pour un seul ticket.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_weight_events
```

| Attribut   | Type           | Obligatoire | Description                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `issue_iid` | entier        | oui      | L'IID d'un ticket                                                             |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_weight_events"
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
    "issue_id": 253,
    "weight": 3
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
    "issue_id": 253,
    "weight": 2
  }
]
```

### Récupérer un événement de poids unique d'un ticket {#retrieve-single-issue-weight-event}

Récupère un événement de poids unique pour un ticket de projet spécifique.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_weight_events/:resource_weight_event_id
```

Paramètres :

| Attribut                     | Type           | Obligatoire | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet |
| `issue_iid`                   | entier        | oui      | L'IID d'un ticket                                                             |
| `resource_weight_event_id`    | entier        | oui      | L'ID d'un événement de poids                                                     |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_weight_events/143"
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
"issue_id": 253,
"weight": 2
}
```
