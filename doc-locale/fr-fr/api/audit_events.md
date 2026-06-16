---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "API REST pour récupérer les événements d'audit GitLab pour les instances, les groupes et les projets."
title: "API des événements d'audit"
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Author Email ajouté au corps de la réponse](https://gitlab.com/gitlab-org/gitlab/-/issues/386322) dans GitLab 15.9.

{{< /history >}}

## Événements d'audit d'instance {#instance-audit-events}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API REST pour récupérer les [événements d'audit d'instance](../administration/compliance/audit_event_reports.md).

Pour récupérer les événements d'audit via l'API REST, vous devez [vous authentifier](rest/authentication.md) en tant qu'administrateur.

### Lister tous les événements d'audit d'instance {#list-all-instance-audit-events}

{{< history >}}

- Prise en charge de la pagination par jeu de clés [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/367528) dans GitLab 15.11.
- Le type d'entité `Gitlab::Audit::InstanceScope` pour les événements d'audit d'instance a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418185) dans GitLab 16.2.

{{< /history >}}

Répertorie tous les événements d'audit d'instance disponibles, limités à un maximum de 30 jours par requête.

```plaintext
GET /audit_events
```

| Attribut | Type | Obligatoire | Description                                                                                                     |
| --------- | ---- | -------- |-----------------------------------------------------------------------------------------------------------------|
| `created_after` | string | non | Renvoie les événements d'audit créés à partir de l'heure donnée ou après celle-ci. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)               |
| `created_before` | string | non | Renvoie les événements d'audit créés avant l'heure donnée ou à cette heure-là. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)              |
| `entity_type` | string | non | Renvoie les événements d'audit pour le type d'entité donné. Les valeurs valides sont : `User`, `Group`, `Project` ou `Gitlab::Audit::InstanceScope`. |
| `entity_id` | entier | non | Renvoie les événements d'audit pour l'ID d'entité donné. Nécessite la présence de l'attribut `entity_type`.                    |

> [!warning]
> La pagination par décalage a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194) dans GitLab 17.8 et sa suppression est prévue dans la version 19.0. Utilisez plutôt la pagination [par jeu de clés](rest/_index.md#keyset-based-pagination). Ce changement est un changement cassant.

Ce point de terminaison prend en charge la pagination par décalage et la pagination [par jeu de clés](rest/_index.md#keyset-based-pagination). Vous devez utiliser la pagination par jeu de clés lorsque vous demandez des pages de résultats consécutives.

En savoir plus sur la [pagination](rest/_index.md#pagination).

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/audit_events"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "author_id": 1,
    "entity_id": 6,
    "entity_type": "Project",
    "details": {
      "custom_message": "Project archived",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs/flight",
      "target_type": "Project",
      "target_details": "flightjs/flight",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs/flight"
    },
    "created_at": "2019-08-30T07:00:41.885Z"
  },
  {
    "id": 2,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "add": "group",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-27T18:36:44.162Z"
  },
  {
    "id": 3,
    "author_id": 51,
    "entity_id": 51,
    "entity_type": "User",
    "details": {
      "change": "email address",
      "from": "hello@flightjs.com",
      "to": "maintainer@flightjs.com",
      "author_name": "Andreas",
      "author_email": "admin@example.com",
      "target_id": 51,
      "target_type": "User",
      "target_details": "Andreas",
      "ip_address": null,
      "entity_path": "Andreas"
    },
    "created_at": "2019-08-22T16:34:25.639Z"
  },
  {
    "id": 4,
    "author_id": 43,
    "entity_id": 1,
    "entity_type": "Gitlab::Audit::InstanceScope",
    "details": {
      "author_name": "Administrator",
      "author_class": "User",
      "target_id": 32,
      "target_type": "AuditEvents::Streaming::InstanceHeader",
      "target_details": "unknown",
      "custom_message": "Created custom HTTP header with key X-arg.",
      "ip_address": "127.0.0.1",
      "entity_path": "gitlab_instance"
    },
    "ip_address": "127.0.0.1",
    "author_name": "Administrator",
    "entity_path": "gitlab_instance",
    "target_details": "unknown",
    "created_at": "2023-08-01T11:29:44.764Z",
    "target_type": "AuditEvents::Streaming::InstanceHeader",
    "target_id": 32,
    "event_type": "audit_events_streaming_instance_headers_create"
  }
]
```

### Récupérer un événement d'audit d'instance {#retrieve-an-instance-audit-event}

Récupère un événement d'audit d'instance spécifié.

```plaintext
GET /audit_events/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | oui | L'ID de l'événement d'audit |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/audit_events/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 6,
  "entity_type": "Project",
  "details": {
    "custom_message": "Project archived",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "target_id": "flightjs/flight",
    "target_type": "Project",
    "target_details": "flightjs/flight",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs/flight"
  },
  "created_at": "2019-08-30T07:00:41.885Z"
}
```

## Événements d'audit de groupe {#group-audit-events}

{{< history >}}

- Prise en charge de la pagination par jeu de clés [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/333968) dans GitLab 15.2.

{{< /history >}}

Utilisez cette API REST pour récupérer les [événements d'audit de groupe](../user/compliance/audit_events.md#group-audit-events).

Un utilisateur avec :

- Le rôle Owner peut récupérer les événements d'audit de groupe de tous les utilisateurs.
- Le rôle Developer ou Maintainer est limité aux événements d'audit de groupe basés sur ses propres actions.

> [!warning]
> La pagination par décalage a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194) dans GitLab 17.8 et sa suppression est prévue dans la version 19.0. Utilisez plutôt la pagination [par jeu de clés](rest/_index.md#keyset-based-pagination). Ce changement est un changement cassant.

Ce point de terminaison prend en charge la pagination par décalage et la pagination [par jeu de clés](rest/_index.md#keyset-based-pagination). La pagination par jeu de clés est recommandée lors de la demande de pages de résultats consécutives.

### Lister tous les événements d'audit de groupe {#list-all-group-audit-events}

{{< history >}}

- Prise en charge de la pagination par jeu de clés [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/333968) dans GitLab 15.2.

{{< /history >}}

Répertorie tous les événements d'audit pour un groupe spécifié.

```plaintext
GET /groups/:id/audit_events
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `created_after` | string | non | Renvoie les événements d'audit de groupe créés à partir de l'heure donnée ou après celle-ci. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ)`  |
| `created_before` | string | non | Renvoie les événements d'audit de groupe créés avant l'heure donnée ou à cette heure-là. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API REST sont paginés.

En savoir plus sur la [pagination](rest/_index.md#pagination).

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/60/audit_events"
```

Exemple de réponse :

```json
[
  {
    "id": 2,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "custom_message": "Group marked for deletion",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-28T19:36:44.162Z"
  },
  {
    "id": 1,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "add": "group",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-27T18:36:44.162Z"
  }
]
```

### Récupérer un événement d'audit de groupe {#retrieve-a-group-audit-event}

Récupère un événement d'audit pour un groupe spécifié. Disponible uniquement pour les propriétaires de groupe et les administrateurs.

```plaintext
GET /groups/:id/audit_events/:audit_event_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe |
| `audit_event_id` | entier | oui | L'ID de l'événement d'audit |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/60/audit_events/2"
```

Exemple de réponse :

```json
{
  "id": 2,
  "author_id": 1,
  "entity_id": 60,
  "entity_type": "Group",
  "details": {
    "custom_message": "Group marked for deletion",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "target_id": "flightjs",
    "target_type": "Group",
    "target_details": "flightjs",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs"
  },
  "created_at": "2019-08-28T19:36:44.162Z"
}
```

## Événements d'audit de projet {#project-audit-events}

Utilisez cette API REST pour récupérer les [événements d'audit de projet](../user/compliance/audit_events.md#project-audit-events).

Un utilisateur avec un rôle Maintainer (ou supérieur) peut récupérer les événements d'audit de projet de tous les utilisateurs. Un utilisateur avec un rôle Developer est limité aux événements d'audit de projet basés sur ses propres actions.

### Lister tous les événements d'audit de projet {#list-all-project-audit-events}

{{< history >}}

- Prise en charge de la pagination par jeu de clés [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/367528) dans GitLab 15.10.

{{< /history >}}

Répertorie tous les événements d'audit pour un projet spécifié.

```plaintext
GET /projects/:id/audit_events
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `created_after` | string | non | Renvoie les événements d'audit de projet créés à partir de l'heure donnée ou après celle-ci. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)  |
| `created_before` | string | non | Renvoie les événements d'audit de projet créés avant l'heure donnée ou à cette heure-là. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |

> [!warning]
> La pagination par décalage a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194) dans GitLab 17.8 et sa suppression est prévue dans la version 19.0. Utilisez plutôt la pagination [par jeu de clés](rest/_index.md#keyset-based-pagination). Ce changement est un changement cassant.

Par défaut, les requêtes `GET` renvoient 20 résultats à la fois, car les résultats de l'API REST sont paginés. Lors de la demande de pages de résultats consécutives, vous devez utiliser la [pagination par jeu de clés](rest/_index.md#keyset-based-pagination).

En savoir plus sur la [pagination](rest/_index.md#pagination).

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/projects/7/audit_events"
```

Exemple de réponse :

```json
[
  {
    "id": 5,
    "author_id": 1,
    "entity_id": 7,
    "entity_type": "Project",
    "details": {
        "change": "prevent merge request approval from committers",
        "from": "",
        "to": "true",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "target_id": 7,
        "target_type": "Project",
        "target_details": "twitter/typeahead-js",
        "ip_address": "127.0.0.1",
        "entity_path": "twitter/typeahead-js"
    },
    "created_at": "2020-05-26T22:55:04.230Z"
  },
  {
      "id": 4,
      "author_id": 1,
      "entity_id": 7,
      "entity_type": "Project",
      "details": {
          "change": "prevent merge request approval from authors",
          "from": "false",
          "to": "true",
          "author_name": "Administrator",
          "author_email": "admin@example.com",
          "target_id": 7,
          "target_type": "Project",
          "target_details": "twitter/typeahead-js",
          "ip_address": "127.0.0.1",
          "entity_path": "twitter/typeahead-js"
      },
      "created_at": "2020-05-26T22:55:04.218Z"
  }
]
```

### Récupérer un événement d'audit de projet {#retrieve-a-project-audit-event}

Récupère un événement d'audit pour un projet spécifié. Disponible uniquement pour les utilisateurs ayant le rôle Maintainer ou Owner pour le projet.

```plaintext
GET /projects/:id/audit_events/:audit_event_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `audit_event_id` | entier | oui | L'ID de l'événement d'audit |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/projects/7/audit_events/5"
```

Exemple de réponse :

```json
{
  "id": 5,
  "author_id": 1,
  "entity_id": 7,
  "entity_type": "Project",
  "details": {
      "change": "prevent merge request approval from committers",
      "from": "",
      "to": "true",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": 7,
      "target_type": "Project",
      "target_details": "twitter/typeahead-js",
      "ip_address": "127.0.0.1",
      "entity_path": "twitter/typeahead-js"
  },
  "created_at": "2020-05-26T22:55:04.230Z"
}
```
