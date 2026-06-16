---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST pour les vérifications de statut externes dans GitLab."
title: API des vérifications de statut externes
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [vérifications de statut externes](../user/project/merge_requests/status_checks.md).

## Récupérer les services de vérification de statut externe d'un projet {#retrieve-project-external-status-check-services}

Récupère des informations sur les services de vérification de statut externe d'un projet en utilisant le point de terminaison suivant :

```plaintext
GET /projects/:id/external_status_checks
```

**Paramètres** :

| Attribut           | Type    | Obligatoire | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | entier | oui      | ID d'un projet     |

```json
[
  {
    "id": 1,
    "name": "Compliance Tool",
    "project_id": 6,
    "external_url": "https://gitlab.com/example/compliance-tool",
    "hmac": true,
    "protected_branches": [
      {
        "id": 14,
        "project_id": 6,
        "name": "main",
        "created_at": "2020-10-12T14:04:50.787Z",
        "updated_at": "2020-10-12T14:04:50.787Z",
        "code_owner_approval_required": false
      }
    ]
  }
]
```

## Créer un service de vérification de statut externe {#create-external-status-check-service}

Crée un nouveau service de vérification de statut externe pour un projet en utilisant le point de terminaison suivant :

```plaintext
POST /projects/:id/external_status_checks
```

> [!warning]
> Les vérifications de statut externes envoient des informations sur tous les merge requests applicables au service externe défini. Cela inclut les merge requests confidentiels.

| Attribut              | Type             | Obligatoire | Description                                    |
|------------------------|------------------|----------|------------------------------------------------|
| `id`                   | entier          | oui      | ID d'un projet                                |
| `name`                 | string           | oui      | Nom d'affichage du service de vérification de statut externe  |
| `external_url`         | string           | oui      | URL du service de vérification de statut externe           |
| `shared_secret`        | string           | non       | Secret HMAC pour la vérification de statut externe          |
| `protected_branch_ids` | `array<Integer>` | non       | IDs des branches protégées pour limiter la portée de la règle |

## Mettre à jour un service de vérification de statut externe {#update-external-status-check-service}

Met à jour une vérification de statut externe existante pour un projet en utilisant le point de terminaison suivant :

```plaintext
PUT /projects/:id/external_status_checks/:check_id
```

| Attribut              | Type             | Obligatoire | Description                                    |
|------------------------|------------------|----------|------------------------------------------------|
| `id`                   | entier          | oui      | ID d'un projet                                |
| `check_id`             | entier          | oui      | ID d'un service de vérification de statut externe         |
| `name`                 | string           | non       | Nom d'affichage du service de vérification de statut externe  |
| `external_url`         | string           | non       | URL du service de vérification de statut externe           |
| `shared_secret`        | string           | non       | Secret HMAC pour la vérification de statut externe          |
| `protected_branch_ids` | `array<Integer>` | non       | IDs des branches protégées pour limiter la portée de la règle |

## Supprimer un service de vérification de statut externe {#delete-external-status-check-service}

Supprime un service de vérification de statut externe pour un projet en utilisant le point de terminaison suivant :

```plaintext
DELETE /projects/:id/external_status_checks/:check_id
```

| Attribut              | Type           | Obligatoire | Description                            |
|------------------------|----------------|----------|----------------------------------------|
| `check_id`             | entier        | oui      | ID d'un service de vérification de statut externe |
| `id`                   | entier        | oui      | ID d'un projet                        |

## Lister toutes les vérifications de statut pour un merge request {#list-all-status-checks-for-a-merge-request}

Liste les services de vérification de statut externes qui s'appliquent à un seul merge request et leur statut.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/status_checks
```

**Paramètres** :

| Attribut                | Type    | Obligatoire | Description                |
| ------------------------ | ------- | -------- | -------------------------- |
| `id`                     | entier | oui      | ID d'un projet            |
| `merge_request_iid`      | entier | oui      | IID d'un merge request     |

```json
[
    {
        "id": 2,
        "name": "Service 1",
        "external_url": "https://gitlab.com/test-endpoint",
        "status": "passed"
    },
    {
        "id": 1,
        "name": "Service 2",
        "external_url": "https://gitlab.com/test-endpoint-2",
        "status": "pending"
    }
]
```

## Définir le statut d'une vérification de statut externe {#set-status-of-an-external-status-check}

{{< history >}}

- Prise en charge de `failed` et `passed` [activée par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/353836) dans GitLab 15.0
- Prise en charge de `pending` dans GitLab 16.5 [activée par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/413723) dans GitLab 16.5

{{< /history >}}

Définit le statut d'une vérification de statut externe pour un seul merge request, en informant GitLab qu'un merge request a passé une vérification par un service externe. Pour définir le statut d'une vérification externe, le jeton d'accès personnel utilisé doit appartenir à un utilisateur ayant le rôle Developer, Maintainer ou Owner sur le projet cible du merge request.

Exécutez cet appel d'API REST en tant qu'utilisateur disposant des droits pour approuver le merge request lui-même.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_check_responses
```

**Paramètres** :

| Attribut                  | Type    | Obligatoire | Description                                                                                       |
| -------------------------- | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                       | entier | oui      | ID d'un projet                                                                                   |
| `merge_request_iid`        | entier | oui      | IID d'un merge request                                                                            |
| `sha`                      | string  | oui      | SHA au niveau de `HEAD` de la branche source                                                                |
| `external_status_check_id` | entier | oui      | ID d'une vérification de statut externe                                                                    |
| `status`                   | string  | non       | Définir sur `pending` pour marquer la vérification comme en attente, `passed` pour la réussir, ou `failed` pour l'échouer |

> [!note]
> `sha` doit être le SHA au niveau de `HEAD` de la branche source du merge request.

## Réessayer une vérification de statut échouée pour un merge request {#retry-failed-status-check-for-a-merge-request}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/383200) dans GitLab 15.7.

{{< /history >}}

Réessaie la vérification de statut externe échouée spécifiée pour un seul merge request. Même si le merge request n'a pas changé, ce point de terminaison renvoie l'état actuel du merge request au service externe défini.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_checks/:external_status_check_id/retry
```

**Paramètres** :

| Attribut                  | Type    | Obligatoire | Description                           |
| -------------------------- | ------- | -------- | ------------------------------------- |
| `id`                       | entier | oui      | ID d'un projet                       |
| `merge_request_iid`        | entier | oui      | IID d'un merge request                |
| `external_status_check_id` | entier | oui      | ID d'une vérification de statut externe échouée |

## Réponse {#response}

En cas de succès, le code de statut est 202.

```json
{
    "message": "202 Accepted"
}
```

Si la vérification de statut est déjà réussie, le code de statut est 422

```json
{
    "message": "External status check must be failed"
}
```

## Exemple de charge utile envoyée au service externe {#example-payload-sent-to-external-service}

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "email": "[REDACTED]"
  },
  "project": {
    "id": 6,
    "name": "Flight",
    "description": "Ipsa minima est consequuntur quisquam.",
    "web_url": "http://example.com/flightjs/Flight",
    "avatar_url": null,
    "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
    "git_http_url": "http://example.com/flightjs/Flight.git",
    "namespace": "Flightjs",
    "visibility_level": 20,
    "path_with_namespace": "flightjs/Flight",
    "default_branch": "main",
    "ci_config_path": null,
    "homepage": "http://example.com/flightjs/Flight",
    "url": "ssh://example.com/flightjs/Flight.git",
    "ssh_url": "ssh://example.com/flightjs/Flight.git",
    "http_url": "http://example.com/flightjs/Flight.git"
  },
  "object_attributes": {
    "assignee_id": null,
    "author_id": 1,
    "created_at": "2022-12-07 07:53:43 UTC",
    "description": "",
    "head_pipeline_id": 558,
    "id": 144,
    "iid": 4,
    "last_edited_at": null,
    "last_edited_by_id": null,
    "merge_commit_sha": null,
    "merge_error": null,
    "merge_params": {
      "force_remove_source_branch": "1"
    },
    "merge_status": "can_be_merged",
    "merge_user_id": null,
    "merge_when_pipeline_succeeds": false,
    "milestone_id": null,
    "source_branch": "root-main-patch-30152",
    "source_project_id": 6,
    "state_id": 1,
    "target_branch": "main",
    "target_project_id": 6,
    "time_estimate": 0,
    "title": "Update README.md",
    "updated_at": "2022-12-07 07:53:43 UTC",
    "updated_by_id": null,
    "url": "http://example.com/flightjs/Flight/-/merge_requests/4",
    "source": {
      "id": 6,
      "name": "Flight",
      "description": "Ipsa minima est consequuntur quisquam.",
      "web_url": "http://example.com/flightjs/Flight",
      "avatar_url": null,
      "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
      "git_http_url": "http://example.com/flightjs/Flight.git",
      "namespace": "Flightjs",
      "visibility_level": 20,
      "path_with_namespace": "flightjs/Flight",
      "default_branch": "main",
      "ci_config_path": null,
      "homepage": "http://example.com/flightjs/Flight",
      "url": "ssh://example.com/flightjs/Flight.git",
      "ssh_url": "ssh://example.com/flightjs/Flight.git",
      "http_url": "http://example.com/flightjs/Flight.git"
    },
    "target": {
      "id": 6,
      "name": "Flight",
      "description": "Ipsa minima est consequuntur quisquam.",
      "web_url": "http://example.com/flightjs/Flight",
      "avatar_url": null,
      "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
      "git_http_url": "http://example.com/flightjs/Flight.git",
      "namespace": "Flightjs",
      "visibility_level": 20,
      "path_with_namespace": "flightjs/Flight",
      "default_branch": "main",
      "ci_config_path": null,
      "homepage": "http://example.com/flightjs/Flight",
      "url": "ssh://example.com/flightjs/Flight.git",
      "ssh_url": "ssh://example.com/flightjs/Flight.git",
      "http_url": "http://example.com/flightjs/Flight.git"
    },
    "last_commit": {
      "id": "141be9714669a4c1ccaa013c6a7f3e462ff2a40f",
      "message": "Update README.md",
      "title": "Update README.md",
      "timestamp": "2022-12-07T07:52:11+00:00",
      "url": "http://example.com/flightjs/Flight/-/commit/141be9714669a4c1ccaa013c6a7f3e462ff2a40f",
      "author": {
        "name": "Administrator",
        "email": "admin@example.com"
      }
    },
    "work_in_progress": false,
    "total_time_spent": 0,
    "time_change": 0,
    "human_total_time_spent": null,
    "human_time_change": null,
    "human_time_estimate": null,
    "assignee_ids": [
    ],
    "reviewer_ids": [
    ],
    "labels": [
    ],
    "state": "opened",
    "blocking_discussions_resolved": true,
    "first_contribution": false,
    "detailed_merge_status": "mergeable"
  },
  "labels": [
  ],
  "changes": {
  },
  "repository": {
    "name": "Flight",
    "url": "ssh://example.com/flightjs/Flight.git",
    "description": "Ipsa minima est consequuntur quisquam.",
    "homepage": "http://example.com/flightjs/Flight"
  },
  "external_approval_rule": {
    "id": 1,
    "name": "QA",
    "external_url": "https://example.com/"
  }
}
```

## Sujets connexes {#related-topics}

- [Vérifications de statut externes](../user/project/merge_requests/status_checks.md)
