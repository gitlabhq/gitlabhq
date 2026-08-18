---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des alertes de gestion des alertes
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les images de métriques pour les [alertes](../operations/incident_management/alerts.md).

Des endpoints supplémentaires sont disponibles avec l'[API GraphQL](graphql/reference/_index.md#alertmanagementalert).

## Importer une image de métrique {#upload-metric-image}

Importe une image de métrique pour une alerte spécifiée.

```plaintext
POST /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `alert_iid` | entier        | oui      | L'ID interne de l'alerte d'un projet. |

Exemple de requête :

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --form 'file=@/path/to/file.png' \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images"
```

Exemple de réponse :

```json
{
  "id":17,
  "created_at":"2020-11-12T20:07:58.156Z",
  "filename":"sample_2054",
  "file_path":"/uploads/-/system/alert_metric_image/file/17/sample_2054.png",
  "url":"https://example.com/metric",
  "url_text":"An example metric"
}
```

## Lister toutes les images de métriques {#list-all-metric-images}

Liste toutes les images de métriques pour une alerte spécifiée.

```plaintext
GET /projects/:id/alert_management_alerts/:alert_iid/metric_images
```

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `alert_iid` | entier        | oui      | L'ID interne de l'alerte d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images"
```

Exemple de réponse :

```json
[
  {
    "id":17,
    "created_at":"2020-11-12T20:07:58.156Z",
    "filename":"sample_2054",
    "file_path":"/uploads/-/system/alert_metric_image/file/17/sample_2054.png",
    "url":"https://example.com/metric",
    "url_text":"An example metric"
  },
  {
    "id":18,
    "created_at":"2020-11-12T20:14:26.441Z",
    "filename":"sample_2054",
    "file_path":"/uploads/-/system/alert_metric_image/file/18/sample_2054.png",
    "url":"https://example.com/metric",
    "url_text":"An example metric"
  }
]
```

## Mettre à jour une image de métrique {#update-a-metric-image}

Met à jour une image de métrique spécifiée pour une alerte.

```plaintext
PUT /projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id
```

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `alert_iid` | entier        | oui      | L'ID interne de l'alerte d'un projet. |
| `image_id`  | entier        | oui      | L'ID de l'image. |
| `url`       | string         | non       | L'URL pour afficher plus d'informations sur les métriques. |
| `url_text`  | string         | non       | Une description de l'image ou de l'URL. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request PUT  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images/1"
```

Exemple de réponse :

```json
{
  "id":23,
  "created_at":"2020-11-13T00:06:18.084Z",
  "filename":"file.png",
  "file_path":"/uploads/-/system/alert_metric_image/file/23/file.png",
  "url":"https://example.com/metric",
  "url_text":"An example metric"
}
```

## Supprimer une image de métrique {#delete-a-metric-image}

Supprime une image de métrique spécifiée pour une alerte.

```plaintext
DELETE /projects/:id/alert_management_alerts/:alert_iid/metric_images/:image_id
```

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `alert_iid` | entier        | oui      | L'ID interne de l'alerte d'un projet. |
| `image_id`  | entier        | oui      | L'ID de l'image. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url  "https://gitlab.example.com/api/v4/projects/5/alert_management_alerts/93/metric_images/1"
```

Peut retourner les codes de statut suivants :

- `204 No Content` : si l'image a été supprimée avec succès.
- `422 Unprocessable` : si l'image n'a pas pu être supprimée.
