---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des jalons de groupe
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [jalons de groupe](../user/project/milestones/_index.md).

Pour les jalons de projet, utilisez l'[API des jalons de projet](milestones.md).

## Lister les jalons de groupe {#list-group-milestones}

Retourne une liste de jalons de groupe.

```plaintext
GET /groups/:id/milestones
GET /groups/:id/milestones?iids[]=42
GET /groups/:id/milestones?iids[]=42&iids[]=43
GET /groups/:id/milestones?state=active
GET /groups/:id/milestones?state=closed
GET /groups/:id/milestones?title=1.0
GET /groups/:id/milestones?search=version
GET /groups/:id/milestones?search_title=17.3+17.4
GET /groups/:id/milestones?search_title=17.3%2017.4
GET /groups/:id/milestones?updated_before=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?updated_after=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?containing_date=2013-10-02T09%3A24%3A18Z
GET /groups/:id/milestones?start_date=2013-10-02T09%3A24%3A18Z&end_date=2013-11-02T09%3A24%3A18Z
```

Paramètres :

| Attribut                   | Type   | Obligatoire | Description |
| ---------                   | ------ | -------- | ----------- |
| `id`                        | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `iids[]`                    | tableau d'entiers | non | Retourne uniquement les jalons ayant le `iid` donné. Ignoré si `include_ancestors` est `true`. |
| `state`                     | string | non | Retourne uniquement les jalons `active` ou `closed`. |
| `title`                     | string | non | Retourne uniquement les jalons ayant le `title` donné (sensible à la casse). |
| `search`                    | string | non | Retourne uniquement les jalons dont le titre ou la description correspond à la chaîne fournie (insensible à la casse). |
| `search_title`              | string | non | Retourne uniquement les jalons dont le titre correspond à la chaîne fournie (insensible à la casse). Plusieurs termes peuvent être fournis, séparés par un espace échappé, soit `+` ou `%20`, et seront combinés avec un ET logique. Exemple : `17.4+17.5` correspondra aux sous-chaînes `17.4` et `17.5` (dans n'importe quel ordre). Introduit dans GitLab 11.8. |
| `include_parent_milestones` | boolean | non | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/433298) dans GitLab 16.7. Utilisez plutôt `include_ancestors`. |
| `include_ancestors`         | boolean | non | Inclut les jalons de tous les groupes parents. |
| `include_descendants`       | boolean | non | Inclut les jalons du groupe et de ses descendants. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/421030) dans GitLab 16.7. |
| `updated_before`            | datetime | non | Retourne uniquement les jalons mis à jour avant la date et l'heure données. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Introduit dans GitLab 15.10. |
| `updated_after`             | datetime | non | Retourne uniquement les jalons mis à jour après la date et l'heure données. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Introduit dans GitLab 15.10. |
| `containing_date`           | datetime | non | Retourne uniquement les jalons où `start_date <= containing_date <= due_date`. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Introduit dans GitLab 13.5. |
| `start_date`                | datetime | non | Retourne uniquement les jalons où `due_date >=` le `start_date` fourni. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Remarque : valide uniquement si `end_date` est également fourni. Introduit dans GitLab 12.8. |
| `end_date`                  | datetime | non | Retourne uniquement les jalons où `start_date <=` le `end_date` fourni. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Remarque : valide uniquement si `start_date` est également fourni. Introduit dans GitLab 12.8. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/milestones"
```

Exemple de réponse :

```json
[
  {
    "id": 12,
    "iid": 3,
    "group_id": 16,
    "title": "10.0",
    "description": "Version",
    "due_date": "2013-11-29",
    "start_date": "2013-11-10",
    "state": "active",
    "updated_at": "2013-10-02T09:24:18Z",
    "created_at": "2013-10-02T09:24:18Z",
    "expired": false,
    "web_url": "https://gitlab.com/groups/gitlab-org/-/milestones/42"
  }
]
```

## Obtenir un seul jalon {#get-single-milestone}

Obtient un seul jalon de groupe.

```plaintext
GET /groups/:id/milestones/:milestone_id
```

Paramètres :

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `milestone_id` | entier | oui | L'identifiant du jalon de groupe |

## Créer un nouveau jalon {#create-new-milestone}

Crée un nouveau jalon de groupe.

```plaintext
POST /groups/:id/milestones
```

Paramètres :

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `title` | string | oui | Le titre d'un jalon |
| `description` | string | non | La description du jalon |
| `due_date` | date | non | La date d'échéance du jalon, au format ISO 8601 (`YYYY-MM-DD`) |
| `start_date` | date | non | La date de début du jalon, au format ISO 8601 (`YYYY-MM-DD`) |

## Modifier le jalon {#edit-milestone}

Met à jour un jalon de groupe existant.

```plaintext
PUT /groups/:id/milestones/:milestone_id
```

Paramètres :

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `milestone_id` | entier | oui | L'identifiant d'un jalon de groupe |
| `title` | string | non | Le titre d'un jalon |
| `description` | string | non | La description d'un jalon |
| `due_date` | date | non | La date d'échéance du jalon, au format ISO 8601 (`YYYY-MM-DD`) |
| `start_date` | date | non | La date de début du jalon, au format ISO 8601 (`YYYY-MM-DD`) |
| `state_event` | string | non | L'événement d'état du jalon _(`close` ou `activate`)_ |

## Supprimer un jalon de groupe {#delete-group-milestone}

Réservé aux utilisateurs disposant du rôle Developer pour le groupe.

```plaintext
DELETE /groups/:id/milestones/:milestone_id
```

Paramètres :

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `milestone_id` | entier | oui | L'identifiant du jalon de groupe |

## Obtenir tous les tickets assignés à un seul jalon {#get-all-issues-assigned-to-a-single-milestone}

Obtient tous les tickets assignés à un seul jalon de groupe.

```plaintext
GET /groups/:id/milestones/:milestone_id/issues
```

Paramètres :

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `milestone_id` | entier | oui | L'identifiant d'un jalon de groupe |

Actuellement, cet endpoint d'API ne retourne pas les tickets des sous-groupes. Si vous souhaitez obtenir tous les tickets des jalons, vous pouvez utiliser l'[API de liste des tickets](issues.md#list-all-issues) et filtrer pour un jalon particulier (par exemple, `GET /issues?milestone=1.0.0&state=opened`).

## Obtenir toutes les merge requests assignées à un seul jalon {#get-all-merge-requests-assigned-to-a-single-milestone}

Obtient toutes les merge requests assignées à un seul jalon de groupe.

```plaintext
GET /groups/:id/milestones/:milestone_id/merge_requests
```

Paramètres :

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `milestone_id` | entier | oui | L'identifiant d'un jalon de groupe |

## Obtenir tous les événements du graphique d'avancement (burndown chart) pour un seul jalon {#get-all-burndown-chart-events-for-a-single-milestone}

{{< details >}}

- Édition :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Obtient tous les événements du graphique d'avancement (burndown chart) pour un seul jalon.

```plaintext
GET /groups/:id/milestones/:milestone_id/burndown_events
```

Paramètres :

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `milestone_id` | entier | oui | L'identifiant d'un jalon de groupe |
