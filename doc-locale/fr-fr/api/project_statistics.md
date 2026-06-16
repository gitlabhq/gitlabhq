---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de statistiques de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer des statistiques sur un [projet](../user/project/_index.md). Tous les endpoints nécessitent une authentification.

Vous devez disposer d'un accès en lecture au dépôt. Les [jetons d'accès personnels](../user/profile/personal_access_tokens.md) doivent avoir la portée `read_api`. Les [jetons d'accès de groupe](../user/group/settings/group_access_tokens.md) peuvent utiliser le rôle Reporter et la portée `read_api`.

Cette API récupère le nombre de fois où le projet est cloné ou récupéré via la méthode HTTP. Les récupérations SSH ne sont pas incluses.

## Récupérer les statistiques des 30 derniers jours {#retrieve-the-statistics-of-the-last-30-days}

Récupère les statistiques de clonage et de récupération des 30 derniers jours à partir d'un projet spécifié.

```plaintext
GET /projects/:id/statistics
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description                                                                    |
|-----------|-------------------|----------|--------------------------------------------------------------------------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).     |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut              | Type    | Description |
|------------------------|---------|-------------|
| `fetches`              | objet  | Statistiques de récupération pour le projet. |
| `fetches.days`         | tableau   | Tableau des statistiques de récupération quotidiennes. |
| `fetches.days[].count` | entier | Nombre de récupérations pour la date spécifique. |
| `fetches.days[].date`  | string  | Date au format ISO (`YYYY-MM-DD`). |
| `fetches.total`        | entier | Nombre total de récupérations pour les 30 derniers jours. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/statistics"
```

Exemple de réponse :

```json
{
  "fetches": {
    "total": 50,
    "days": [
      {
        "count": 10,
        "date": "2018-01-10"
      },
      {
        "count": 10,
        "date": "2018-01-09"
      },
      {
        "count": 10,
        "date": "2018-01-08"
      },
      {
        "count": 10,
        "date": "2018-01-07"
      },
      {
        "count": 10,
        "date": "2018-01-06"
      }
    ]
  }
}
```
