---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Récupérez les métriques DORA de projet et de groupe avec l'API REST."
title: API des métriques DevOps Research and Assessment (DORA)
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer les détails des [métriques DORA](../../user/analytics/dora_metrics.md) pour vos groupes et projets.

Des endpoints supplémentaires sont disponibles avec l'[API GraphQL](../graphql/reference/_index.md).

Prérequis :

- Vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner.

## Récupérer les métriques DORA au niveau projet {#retrieve-project-level-dora-metrics}

Récupère les métriques DORA pour un projet spécifié.

```plaintext
GET /projects/:id/dora/metrics
```

| Attribut            | Type             | Obligatoire | Description |
|:---------------------|:-----------------|:---------|:------------|
| `id`                 | entier ou chaîne de caractères   | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths) accessible par l'utilisateur authentifié. |
| `metric`             | string           | oui      | L'une des valeurs suivantes : `deployment_frequency`, `lead_time_for_changes`, `time_to_restore_service` ou `change_failure_rate`. |
| `end_date`           | string           | non       | Plage de dates de fin. Format de date ISO 8601, par exemple `2021-03-01`. Par défaut, il s'agit de la date actuelle. |
| `environment_tiers`  | tableau de chaînes de caractères | non       | Les [niveaux des environnements](../../ci/environments/_index.md#deployment-tier-of-environments). La valeur par défaut est `production`. |
| `interval`           | string           | non       | L'intervalle de regroupement. L'une des valeurs suivantes : `all`, `monthly` ou `daily`. La valeur par défaut est `daily`. |
| `start_date`         | string           | non       | Plage de dates de début. Format de date ISO 8601, par exemple `2021-03-01`. Par défaut, il y a 3 mois. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/dora/metrics?metric=deployment_frequency"
```

Exemple de réponse :

```json
[
  { "date": "2021-03-01", "value": 3 },
  { "date": "2021-03-02", "value": 6 },
  { "date": "2021-03-03", "value": 0 },
  { "date": "2021-03-04", "value": 0 },
  { "date": "2021-03-05", "value": 0 },
  { "date": "2021-03-06", "value": 0 },
  { "date": "2021-03-07", "value": 0 },
  { "date": "2021-03-08", "value": 4 }
]
```

## Récupérer les métriques DORA au niveau groupe {#retrieve-group-level-dora-metrics}

Récupère les métriques DORA pour un groupe spécifié.

```plaintext
GET /groups/:id/dora/metrics
```

| Attribut           | Type             | Obligatoire | Description |
|:--------------------|:-----------------|:---------|:------------|
| `id`                | entier ou chaîne de caractères   | oui      | L'ID ou le [chemin encodé en URL du projet](../rest/_index.md#namespaced-paths) accessible par l'utilisateur authentifié. |
| `metric`            | string           | oui      | L'une des valeurs suivantes : `deployment_frequency`, `lead_time_for_changes`, `time_to_restore_service` ou `change_failure_rate`. |
| `end_date`          | string           | non       | Plage de dates de fin. Format de date ISO 8601, par exemple `2021-03-01`. Par défaut, il s'agit de la date actuelle. |
| `environment_tiers` | tableau de chaînes de caractères | non       | Les [niveaux des environnements](../../ci/environments/_index.md#deployment-tier-of-environments). La valeur par défaut est `production`. |
| `interval`          | string           | non       | L'intervalle de regroupement. L'une des valeurs suivantes : `all`, `monthly` ou `daily`. La valeur par défaut est `daily`. |
| `start_date`        | string           | non       | Plage de dates de début. Format de date ISO 8601, par exemple `2021-03-01`. Par défaut, il y a 3 mois. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/dora/metrics?metric=deployment_frequency"
```

Exemple de réponse :

```json
[
  { "date": "2021-03-01", "value": 3 },
  { "date": "2021-03-02", "value": 6 },
  { "date": "2021-03-03", "value": 0 },
  { "date": "2021-03-04", "value": 0 },
  { "date": "2021-03-05", "value": 0 },
  { "date": "2021-03-06", "value": 0 },
  { "date": "2021-03-07", "value": 0 },
  { "date": "2021-03-08", "value": 4 }
]
```

## Le champ `value` {#the-value-field}

Pour les endpoints au niveau projet et au niveau groupe décrits précédemment, le champ `value` dans la réponse de l'API REST a une signification différente selon le paramètre de requête `metric` fourni :

| Paramètre de requête `metric`   | Description de `value` dans la réponse |
|:---------------------------|:-----------------------------------|
| `deployment_frequency`     | L'API REST renvoie le nombre total de déploiements réussis au cours de la période. [Ticket 371271](https://gitlab.com/gitlab-org/gitlab/-/issues/371271) propose de mettre à jour l'API REST pour renvoyer la moyenne quotidienne au lieu du nombre total. |
| `change_failure_rate`      | Le nombre d'incidents divisé par le nombre de déploiements au cours de la période. Disponible uniquement pour l'environnement de production. |
| `lead_time_for_changes`    | Le nombre médian de secondes entre la fusion du merge request (MR) et le déploiement des commits du MR pour tous les MRs déployés au cours de la période. |
| `time_to_restore_service`  | Le nombre médian de secondes pendant lesquelles un incident était ouvert au cours de la période. Disponible uniquement pour l'environnement de production. |

> [!note]
> L'API REST renvoie les intervalles `monthly` et `all` en calculant la médiane des valeurs médianes quotidiennes. Cela peut introduire une légère imprécision dans les données renvoyées.
