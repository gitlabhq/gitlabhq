---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de suivi des erreurs
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec la fonctionnalité de suivi des erreurs pour les projets. Pour plus d'informations, consultez [Suivi des erreurs](../operations/error_tracking.md).

Prérequis :

- Vous devez disposer du rôle Chargé de maintenance ou Propriétaire.

## Récupérer les paramètres de suivi des erreurs {#retrieve-error-tracking-settings}

Récupère les paramètres de suivi des erreurs pour un projet spécifié.

```plaintext
GET /projects/:id/error_tracking/settings
```

| Attribut | Type    | Obligatoire | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | entier | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings"
```

Exemple de réponse :

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## Créer des paramètres de suivi des erreurs {#create-error-tracking-settings}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/393035/) dans GitLab 15.10.

{{< /history >}}

Crée des paramètres de suivi des erreurs pour un projet spécifié.

> [!note]
> Cette API est uniquement disponible lorsqu'elle est utilisée avec le [suivi des erreurs intégré](../operations/integrated_error_tracking.md).

```plaintext
PUT /projects/:id/error_tracking/settings
```

Attributs pris en charge :

| Attribut    | Type    | Obligatoire | Description                                                                                                                                                     |
| ------------ | ------- |----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`         | entier | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                                            |
| `active`     | boolean | oui      | Passez `true` pour activer la configuration des paramètres de suivi des erreurs ou `false` pour la désactiver.                                                                        |
| `integrated` | boolean | oui      | Passez `true` pour activer le backend de suivi des erreurs intégré. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true&integrated=true"
```

Exemple de réponse :

```json
{
  "active": true,
  "project_name": null,
  "sentry_external_url": null,
  "api_url": null,
  "integrated": true
}
```

## Mettre à jour les paramètres du projet de suivi des erreurs {#update-error-tracking-project-settings}

Met à jour les paramètres de suivi des erreurs pour un projet spécifié.

```plaintext
PATCH /projects/:id/error_tracking/settings
```

| Attribut    | Type    | Obligatoire | Description           |
| ------------ | ------- | -------- | --------------------- |
| `id`         | entier | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `active`     | boolean | oui      | Passez `true` pour activer les paramètres de suivi des erreurs déjà configurés ou `false` pour les désactiver. |
| `integrated` | boolean | non       | Passez `true` pour activer le backend de suivi des erreurs intégré. |

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/error_tracking/settings?active=true"
```

Exemple de réponse :

```json
{
  "active": true,
  "project_name": "sample sentry project",
  "sentry_external_url": "https://sentry.io/myawesomeproject/project",
  "api_url": "https://sentry.io/api/0/projects/myawesomeproject/project",
  "integrated": false
}
```

## Répertorier toutes les clés client du projet {#list-all-project-client-keys}

Répertorie toutes les clés client de [suivi des erreurs intégré](../operations/integrated_error_tracking.md) pour un projet spécifié.

```plaintext
GET /projects/:id/error_tracking/client_keys
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "active": true,
    "public_key": "glet_aa77551d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
  },
  {
    "id": 3,
    "active": true,
    "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
    "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
  }
]
```

## Créer une clé client {#create-a-client-key}

Crée une clé client de [suivi des erreurs intégré](../operations/integrated_error_tracking.md) pour un projet spécifié. L'attribut de clé publique est généré automatiquement.

```plaintext
POST /projects/:id/error_tracking/client_keys
```

| Attribut  | Type | Obligatoire | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys"
```

Exemple de réponse :

```json
{
  "id": 3,
  "active": true,
  "public_key": "glet_0ff98b1d849c083f76d0bc545ed053a3",
  "sentry_dsn": "https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5"
}
```

## Supprimer une clé client {#delete-a-client-key}

Supprime une clé client de [suivi des erreurs intégré](../operations/integrated_error_tracking.md) d'un projet spécifié.

```plaintext
DELETE /projects/:id/error_tracking/client_keys/:key_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `key_id`  | entier | oui | L'ID de la clé client. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/error_tracking/client_keys/13"
```
