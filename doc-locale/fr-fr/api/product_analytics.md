---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez Cube pour interroger l'API Product Analytics de GitLab. Envoyez des requêtes, générez des jetons d'accès et récupérez des métadonnées d'analyse."
title: API Product Analytics
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : Bêta

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 15.4 [avec un indicateur](../administration/feature_flags/_index.md) nommé `cube_api_proxy`. Désactivé par défaut.
- `cube_api_proxy` supprimé et remplacé par `product_analytics_internal_preview` dans GitLab 15.10.
- `product_analytics_internal_preview` remplacé par `product_analytics_dashboards` dans GitLab 15.11.
- `product_analytics_dashboards` [activé](https://gitlab.com/gitlab-org/gitlab/-/issues/398653) par défaut dans GitLab 16.11.
- Le feature flag `product_analytics_dashboards` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/454059) dans GitLab 17.1.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167296) en bêta dans GitLab 17.5 [avec un indicateur](../administration/feature_flags/_index.md) nommé `product_analytics_features`.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité n'est pas prête pour une utilisation en production.

Utilisez cette API pour suivre le comportement des utilisateurs et l'utilisation des applications.

> [!note]
> Assurez-vous de définir d'abord les paramètres d'application `cube_api_base_url` et `cube_api_key` en utilisant [l'API](settings.md).

## Créer une requête Cube {#create-a-cube-query-request}

Crée une requête vers l'API Cube et génère un jeton d'accès.

```plaintext
POST /projects/:id/product_analytics/request/load
POST /projects/:id/product_analytics/request/dry-run
```

| Attribut       | Type             | Obligatoire | Description                                                                                 |
|-----------------|------------------| -------- |---------------------------------------------------------------------------------------------|
| `id`            | entier          | oui      | L'identifiant d'un projet auquel l'utilisateur actuel a un accès en lecture.                               |
| `include_token` | boolean          | non       | Indique si le jeton d'accès doit être inclus dans la réponse. (Requis uniquement pour la génération d'entonnoir.) |

### Corps de la requête {#request-body}

Le corps de la requête de chargement doit être une requête Cube valide.

> [!note]
> Lors de la mesure de `TrackedEvents`, vous devez utiliser `TrackedEvents.*` pour `dimensions` et `timeDimensions`. La même règle s'applique lors de la mesure de `Sessions`.

#### Exemple d'événements suivis {#tracked-events-example}

```json
{
  "query": {
    "measures": [
      "TrackedEvents.count"
    ],
    "timeDimensions": [
      {
        "dimension": "TrackedEvents.utcTime",
        "dateRange": "This week"
      }
    ],
    "order": [
      [
        "TrackedEvents.count",
        "desc"
      ],
      [
        "TrackedEvents.docPath",
        "desc"
      ],
      [
        "TrackedEvents.utcTime",
        "asc"
      ]
    ],
    "dimensions": [
      "TrackedEvents.docPath"
    ],
    "limit": 23
  },
  "queryType": "multi"
}
```

#### Exemple de sessions {#sessions-example}

```json
{
  "query": {
    "measures": [
      "Sessions.count"
    ],
    "timeDimensions": [
      {
        "dimension": "Sessions.startAt",
        "granularity": "day"
      }
    ],
    "order": {
      "Sessions.startAt": "asc"
    },
    "limit": 100
  },
  "queryType": "multi"
}
```

## Récupérer les métadonnées Cube {#retrieve-cube-metadata}

Récupère les métadonnées Cube pour les données d'analyse.

```plaintext
GET /projects/:id/product_analytics/request/meta
```

| Attribut | Type             | Obligatoire | Description                                                   |
| --------- |------------------| -------- |---------------------------------------------------------------|
| `id`      | entier          | oui      | L'identifiant d'un projet auquel l'utilisateur actuel a un accès en lecture. |
