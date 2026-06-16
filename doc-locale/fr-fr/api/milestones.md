---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des jalons de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [jalons de projet](../user/project/milestones/_index.md).

Pour les jalons de groupe, utilisez l'[API des jalons de groupe](group_milestones.md).

## Lister tous les jalons de projet {#list-all-project-milestones}

Liste tous les jalons d'un projet.

```plaintext
GET /projects/:id/milestones
GET /projects/:id/milestones?iids[]=42
GET /projects/:id/milestones?iids[]=42&iids[]=43
GET /projects/:id/milestones?state=active
GET /projects/:id/milestones?state=closed
GET /projects/:id/milestones?title=1.0
GET /projects/:id/milestones?search=version
GET /projects/:id/milestones?updated_before=2013-10-02T09%3A24%3A18Z
GET /projects/:id/milestones?updated_after=2013-10-02T09%3A24%3A18Z
```

Paramètres :

| Attribut                         | Type   | Obligatoire | Description |
| ----------------------------      | ------ | -------- | ----------- |
| `id`                              | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `iids[]`                          | tableau d'entiers | non | Retourner uniquement les jalons ayant le `iid` donné. Ignoré si `include_ancestors` est `true`.  |
| `state`                           | string | non | Retourner uniquement les jalons `active` ou `closed` |
| `title`                           | string | non | Retourner uniquement les jalons ayant le `title` donné |
| `search`                          | string | non | Retourner uniquement les jalons dont le titre ou la description correspond à la chaîne fournie |
| `include_parent_milestones`       | boolean | non | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/433298) dans GitLab 16.7. Utilisez `include_ancestors` à la place. |
| `include_ancestors`               | boolean | non | Inclure les jalons de tous les groupes parents. |
| `updated_before`                  | datetime | non | Retourner uniquement les jalons mis à jour avant le datetime donné. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Introduit dans GitLab 15.10 |
| `updated_after`                   | datetime | non | Retourner uniquement les jalons mis à jour après le datetime donné. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Introduit dans GitLab 15.10 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/milestones"
```

Exemple de réponse :

```json
[
  {
    "id": 12,
    "iid": 3,
    "project_id": 16,
    "title": "10.0",
    "description": "Version",
    "due_date": "2013-11-29",
    "start_date": "2013-11-10",
    "state": "active",
    "updated_at": "2013-10-02T09:24:18Z",
    "created_at": "2013-10-02T09:24:18Z",
    "expired": false
  }
]
```

## Récupérer un jalon {#retrieve-a-milestone}

Récupère un jalon de projet spécifié.

```plaintext
GET /projects/:id/milestones/:milestone_id
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `milestone_id` | entier        | oui      | L'ID du jalon du projet                                                                               |

## Créer un jalon {#create-a-milestone}

Crée un jalon de projet.

```plaintext
POST /projects/:id/milestones
```

Paramètres :

| Attribut     | Type           | Obligatoire | Description                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `title`       | string         | oui      | Le titre du jalon                                                                                        |
| `description` | string         | non       | La description du jalon                                                                                |
| `due_date`    | string         | non       | La date d'échéance du jalon (`YYYY-MM-DD`)                                                                    |
| `start_date`  | string         | non       | La date de début du jalon (`YYYY-MM-DD`)                                                                  |

## Mettre à jour un jalon {#update-a-milestone}

Met à jour un jalon de projet spécifié.

```plaintext
PUT /projects/:id/milestones/:milestone_id
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `milestone_id` | entier        | oui      | L'ID du jalon du projet                                                                               |
| `title`        | string         | non       | Le titre du jalon                                                                                        |
| `description`  | string         | non       | La description du jalon                                                                                |
| `due_date`     | string         | non       | La date d'échéance du jalon (`YYYY-MM-DD`)                                                                    |
| `start_date`   | string         | non       | La date de début du jalon (`YYYY-MM-DD`)                                                                  |
| `state_event`  | string         | non       | L'événement d'état du jalon (close ou activate)                                                            |

## Supprimer un jalon {#delete-a-milestone}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) du rôle utilisateur minimum de Developer à Reporter dans GitLab 15.0.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Supprime un jalon de projet spécifié.

Uniquement pour les utilisateurs ayant le rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

```plaintext
DELETE /projects/:id/milestones/:milestone_id
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `milestone_id` | entier        | oui      | L'ID du jalon du projet                                                                               |

## Lister tous les tickets pour un jalon {#list-all-issues-for-a-milestone}

Liste tous les tickets assignés à un jalon de projet spécifié.

```plaintext
GET /projects/:id/milestones/:milestone_id/issues
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `milestone_id` | entier        | oui      | L'ID du jalon du projet                                                                               |

## Lister toutes les merge requests pour un jalon {#list-all-merge-requests-for-a-milestone}

Liste toutes les merge requests assignées à un jalon de projet spécifié.

```plaintext
GET /projects/:id/milestones/:milestone_id/merge_requests
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `milestone_id` | entier        | oui      | L'ID du jalon du projet                                                                               |

## Promouvoir un jalon en jalon de groupe {#promote-a-milestone-to-group-milestone}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/343889) du rôle utilisateur minimum de Developer à Reporter dans GitLab 15.0.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Promeut un jalon de projet en jalon de groupe.

Uniquement pour les utilisateurs ayant le rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le groupe.

```plaintext
POST /projects/:id/milestones/:milestone_id/promote
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `milestone_id` | entier        | oui      | L'ID du jalon du projet                                                                               |

## Lister tous les événements du graphique d'avancement (burndown chart) pour un jalon {#list-all-burndown-chart-events-for-a-milestone}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Liste tous les événements du graphique d'avancement (burndown chart) pour un jalon spécifié.

```plaintext
GET /projects/:id/milestones/:milestone_id/burndown_events
```

Paramètres :

| Attribut      | Type           | Obligatoire | Description                                                                                                     |
|----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`           | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `milestone_id` | entier        | oui      | L'ID du jalon du projet                                                                               |
