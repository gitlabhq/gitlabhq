---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des contrôleurs de runner
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Statut :  Expérience

{{< /details >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229) dans GitLab 18.9 [avec un indicateur](../administration/feature_flags/_index.md) nommé `FF_USE_JOB_ROUTER`. Cette fonctionnalité est une [expérimentation](../policy/development_stages_support.md) soumise au [Contrat de test GitLab](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
- Le champ `connected` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/591615) dans GitLab 18.10.

{{< /history >}}

L'API des contrôleurs de runner vous permet de gérer les contrôleurs de runner pour le contrôle d'admission des jobs CI/CD. Les contrôleurs de runner se connectent au routeur de jobs et évaluent les jobs en fonction de politiques personnalisées, décidant de les admettre ou de les rejeter. Cette API fournit des points de terminaison pour créer, lire, mettre à jour et supprimer des contrôleurs de runner.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance GitLab.

## Lister tous les contrôleurs de runner {#list-all-runner-controllers}

Liste tous les contrôleurs de runner.

```plaintext
GET /runner_controllers
```

Réponse :

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) avec les attributs de réponse suivants :

| Attribut          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | L'identifiant unique du contrôleur de runner. |
| `description`      | string       | Une description pour le contrôleur de runner. |
| `state`            | string       | L'état du contrôleur de runner. Les valeurs valides sont `disabled` (par défaut), `enabled` ou `dry_run`. |
| `created_at`       | datetime     | La date et l'heure de création du contrôleur de runner. |
| `updated_at`       | datetime     | La date et l'heure de la dernière mise à jour du contrôleur de runner. |

Exemple de requête :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

Exemple de réponse :

```json
[
    {
        "id": 1,
        "description": "Runner controller",
        "state": "enabled",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "description": "Another runner controller",
        "state": "disabled",
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## Récupérer un contrôleur de runner unique {#retrieve-a-single-runner-controller}

Récupère les détails d'un contrôleur de runner spécifique par son ID.

```plaintext
GET /runner_controllers/:id
```

Réponse :

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) avec les attributs de réponse suivants :

| Attribut          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | L'identifiant unique du contrôleur de runner. |
| `description`      | string       | Une description pour le contrôleur de runner. |
| `state`            | string       | L'état du contrôleur de runner. Les valeurs valides sont `disabled` (par défaut), `enabled` ou `dry_run`. |
| `connected`        | boolean      | Indique si le contrôleur de runner est actuellement connecté. Un contrôleur de runner est considéré comme connecté lorsqu'il utilise au moins l'un de ses jetons actifs au cours de la dernière heure. |
| `created_at`       | datetime     | La date et l'heure de création du contrôleur de runner. |
| `updated_at`       | datetime     | La date et l'heure de la dernière mise à jour du contrôleur de runner. |

Exemple de requête :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1"
```

Exemple de réponse :

```json
{
    "id": 1,
    "description": "Runner controller",
    "state": "enabled",
    "connected": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## Enregistrer un contrôleur de runner {#register-a-runner-controller}

Enregistre un nouveau contrôleur de runner.

```plaintext
POST /runner_controllers
```

Attributs pris en charge :

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `description`      | string       | Non       | Une description pour le contrôleur de runner. |
| `state`            | string       | Non       | L'état du contrôleur de runner. Les valeurs valides sont `disabled` (par défaut), `enabled` ou `dry_run`. |

Réponse :

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) avec les attributs de réponse suivants :

| Attribut          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | L'identifiant unique du contrôleur de runner. |
| `description`      | string       | Une description pour le contrôleur de runner. |
| `state`            | string       | L'état du contrôleur de runner. Les valeurs valides sont `disabled` (par défaut), `enabled` ou `dry_run`. |
| `created_at`       | datetime     | La date et l'heure de création du contrôleur de runner. |
| `updated_at`       | datetime     | La date et l'heure de la dernière mise à jour du contrôleur de runner. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "New runner controller", "state": "dry_run"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers"
```

Exemple de réponse :

```json
{
    "id": 3,
    "description": "New runner controller",
    "state": "dry_run",
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-05T00:00:00Z"
}
```

## Mettre à jour un contrôleur de runner {#update-a-runner-controller}

Met à jour les détails d'un contrôleur de runner existant par son ID.

```plaintext
PUT /runner_controllers/:id
```

Attributs pris en charge :

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `description`      | string       | Non       | Une description pour le contrôleur de runner. |
| `state`            | string       | Non       | L'état du contrôleur de runner. Les valeurs valides sont `disabled` (par défaut), `enabled` ou `dry_run`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) avec les attributs de réponse suivants :

| Attribut          | Type         | Description |
|--------------------|--------------|-------------|
| `id`               | integer      | L'identifiant unique du contrôleur de runner. |
| `description`      | string       | Une description pour le contrôleur de runner. |
| `state`            | string       | L'état du contrôleur de runner. Les valeurs valides sont `disabled` (par défaut), `enabled` ou `dry_run`. |
| `created_at`       | datetime     | La date et l'heure de création du contrôleur de runner. |
| `updated_at`       | datetime     | La date et l'heure de la dernière mise à jour du contrôleur de runner. |

Exemple de requête :

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"description": "Updated runner controller", "state": "enabled"}' \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

Exemple de réponse :

```json
{
    "id": 3,
    "description": "Updated runner controller",
    "state": "enabled",
    "created_at": "2026-01-05T00:00:00Z",
    "updated_at": "2026-01-06T00:00:00Z"
}
```

## Supprimer un contrôleur de runner {#delete-a-runner-controller}

Supprime un contrôleur de runner spécifique par son ID.

```plaintext
DELETE /runner_controllers/:id
```

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/3"
```

## Portées des contrôleurs de runner {#runner-controller-scopes}

Les portées des contrôleurs de runner définissent les jobs qu'un contrôleur de runner évalue pour le contrôle d'admission. Un contrôleur de runner doit avoir au moins une portée pour recevoir des demandes d'admission. Sans portée, le contrôleur reste inactif même lorsque son état est `enabled` ou `dry_run`.

Les portées des contrôleurs de runner prennent en charge deux types de portée mutuellement exclusifs :

- **Instance scope** : Le contrôleur de runner évalue les jobs pour tous les runners de l'instance GitLab.
- **Runner scope** : Le contrôleur de runner évalue les jobs uniquement pour des runners d'instance spécifiques.

Un contrôleur de runner peut avoir soit une portée d'instance, soit une ou plusieurs portées de runner, mais pas les deux.

> [!note]
> Seules les portées d'instance et de runner sont disponibles. Des types de portée supplémentaires (groupe, projet) sont proposés dans [le ticket 586419](https://gitlab.com/gitlab-org/gitlab/-/issues/586419).

### Lister toutes les portées d'un contrôleur de runner {#list-all-scopes-for-a-runner-controller}

Liste toutes les portées configurées pour un contrôleur de runner spécifique :

```plaintext
GET /runner_controllers/:id/scopes
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description                              |
|-----------|---------|----------|------------------------------------------|
| `id`      | integer | Oui      | L'ID du contrôleur de runner.         |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                              | Type         | Description                                               |
|----------------------------------------|--------------|-----------------------------------------------------------|
| `instance_level_scopings`              | object array | Liste des portées d'instance pour le contrôleur de runner. |
| `instance_level_scopings[].created_at` | datetime     | La date et l'heure de création de la portée.           |
| `instance_level_scopings[].updated_at` | datetime     | La date et l'heure de la dernière mise à jour de la portée.      |
| `runner_level_scopings`                | object array | Liste des portées de runner pour le contrôleur de runner.  |
| `runner_level_scopings[].runner_id`    | integer      | L'ID du runner.                                     |
| `runner_level_scopings[].created_at`   | datetime     | La date et l'heure de création de la portée.           |
| `runner_level_scopings[].updated_at`   | datetime     | La date et l'heure de la dernière mise à jour de la portée.      |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes"
```

Exemple de réponse :

```json
{
    "instance_level_scopings": [
        {
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z"
        }
    ],
    "runner_level_scopings": []
}
```

### Ajouter une portée d'instance {#add-instance-scope}

Ajoute une portée d'instance à un contrôleur de runner. Une fois ajoutée, le contrôleur de runner évalue les jobs pour tous les runners de l'instance GitLab.

Un contrôleur de runner ne peut avoir qu'une seule portée d'instance. Si une portée d'instance existe déjà, ce point de terminaison renvoie une erreur.

```plaintext
POST /runner_controllers/:id/scopes/instance
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description                              |
|-----------|---------|----------|------------------------------------------|
| `id`      | integer | Oui      | L'ID du contrôleur de runner.         |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut               | Type     | Description                                          |
|-------------------------|----------|------------------------------------------------------|
| `created_at`            | datetime | La date et l'heure de création de la portée.      |
| `updated_at`            | datetime | La date et l'heure de la dernière mise à jour de la portée. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/instance"
```

Exemple de réponse :

```json
{
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
}
```

### Supprimer une portée d'instance {#remove-instance-scope}

Supprime une portée d'instance d'un contrôleur de runner.

```plaintext
DELETE /runner_controllers/:id/scopes/instance
```

Attributs pris en charge :

| Attribut     | Type    | Obligatoire | Description                                          |
|---------------|---------|----------|------------------------------------------------------|
| `id`          | integer | Oui      | L'ID du contrôleur de runner.                     |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/instance"
```

### Ajouter une portée de runner {#add-runner-scope}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/586417) dans GitLab 18.10.

{{< /history >}}

Ajoute une portée de runner à un contrôleur de runner. Une fois ajoutée, le contrôleur de runner évalue les jobs uniquement pour le runner spécifié.

Un contrôleur de runner avec une portée d'instance ne peut pas avoir de portées de runner. Supprimez la portée d'instance avant d'ajouter des portées de runner.

```plaintext
POST /runner_controllers/:id/scopes/runners/:runner_id
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                      |
|-------------|---------|----------|----------------------------------|
| `id`        | integer | Oui      | L'ID du contrôleur de runner. |
| `runner_id` | integer | Oui      | L'ID du runner. Doit être un runner d'instance. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type     | Description                                          |
|--------------|----------|------------------------------------------------------|
| `runner_id`  | integer  | L'ID du runner.                                |
| `created_at` | datetime | La date et l'heure de création de la portée.      |
| `updated_at` | datetime | La date et l'heure de la dernière mise à jour de la portée. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/runners/5"
```

Exemple de réponse :

```json
{
    "runner_id": 5,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
}
```

### Supprimer une portée de runner {#remove-runner-scope}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/586417) dans GitLab 18.10.

{{< /history >}}

Supprime une portée de runner d'un contrôleur de runner.

```plaintext
DELETE /runner_controllers/:id/scopes/runners/:runner_id
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                      |
|-------------|---------|----------|----------------------------------|
| `id`        | integer | Oui      | L'ID du contrôleur de runner. |
| `runner_id` | integer | Oui      | L'ID du runner.            |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/1/scopes/runners/5"
```
