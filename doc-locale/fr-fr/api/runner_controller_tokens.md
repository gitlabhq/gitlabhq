---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des jetons de contrôleur de runner
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated
- Statut :  Expérience

{{< /details >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218229) dans GitLab 18.9 [avec un indicateur](../administration/feature_flags/_index.md) nommé `FF_USE_JOB_ROUTER`. Cette fonctionnalité est une [expérience](../policy/development_stages_support.md) et est soumise au [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
- Le champ `last_used_at` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/591615) dans GitLab 18.10.

{{< /history >}}

L'API des jetons de contrôleur de runner vous permet de gérer les jetons d'authentification pour les contrôleurs de runner. Les contrôleurs de runner utilisent ces jetons pour s'authentifier auprès de l'instance GitLab et gérer les runners. Cette API fournit des points de terminaison pour créer, lister, faire pivoter et révoquer des jetons.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance GitLab.

## Lister tous les jetons de contrôleur de runner {#list-all-runner-controller-tokens}

Liste tous les jetons de contrôleur de runner.

```plaintext
GET /runner_controllers/:id/tokens
```

Paramètres :

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `id`               | entier      | Oui      | L'identifiant du contrôleur de runner. |

Réponse :

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | entier | L'identifiant unique du jeton de contrôleur de runner. |
| `runner_controller_id`  | entier | L'identifiant du contrôleur de runner associé. |
| `description`           | string  | Une description pour le jeton. |
| `last_used_at`          | datetime| La date et l'heure auxquelles le jeton a été utilisé pour la dernière fois. |
| `created_at`            | datetime| La date et l'heure auxquelles le jeton a été créé. |
| `updated_at`            | datetime| La date et l'heure auxquelles le jeton a été mis à jour pour la dernière fois. |

Exemple de requête :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens"
```

Exemple de réponse :

```json
[
    {
        "id": 1,
        "runner_controller_id": 1,
        "description": "Token for runner controller",
        "last_used_at": "2026-01-05T00:00:00Z",
        "created_at": "2026-01-01T00:00:00Z",
        "updated_at": "2026-01-02T00:00:00Z"
    },
    {
        "id": 2,
        "runner_controller_id": 1,
        "description": "Another token for runner controller",
        "last_used_at": "2026-01-05T00:00:00Z",
        "created_at": "2026-01-03T00:00:00Z",
        "updated_at": "2026-01-04T00:00:00Z"
    }
]
```

## Récupérer un jeton de contrôleur de runner unique {#retrieve-a-single-runner-controller-token}

Récupère les détails d'un jeton de contrôleur de runner spécifique par son identifiant.

```plaintext
GET /runner_controllers/:id/tokens/:token_id
```

Paramètres :

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `id`               | entier      | Oui      | L'identifiant du contrôleur de runner. |
| `token_id`         | entier      | Oui      | L'identifiant du jeton de contrôleur de runner. |

Réponse :

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) avec les champs suivants :

| Attribut               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | entier | L'identifiant unique du jeton de contrôleur de runner. |
| `runner_controller_id`  | entier | L'identifiant du contrôleur de runner associé. |
| `description`           | string  | Une description pour le jeton. |
| `last_used_at`          | datetime| La date et l'heure auxquelles le jeton a été utilisé pour la dernière fois. |
| `created_at`            | datetime| La date et l'heure auxquelles le jeton a été créé. |
| `updated_at`            | datetime| La date et l'heure auxquelles le jeton a été mis à jour pour la dernière fois. |

Exemple de requête :

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id"
```

Exemple de réponse :

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "last_used_at": "2026-01-05T00:00:00Z",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-02T00:00:00Z"
}
```

## Créer un jeton de contrôleur de runner {#create-a-runner-controller-token}

Crée un nouveau jeton de contrôleur de runner.

```plaintext
POST /runner_controllers/:id/tokens
```

Paramètres :

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `id`               | entier      | Oui      | L'identifiant du contrôleur de runner. |

Attributs pris en charge :

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `description`      | string       | Oui      | Une description pour le jeton. |

Réponse :

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) avec les attributs suivants :

| Attribut               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | entier | L'identifiant unique du jeton de contrôleur de runner. |
| `runner_controller_id`  | entier | L'identifiant du contrôleur de runner associé. |
| `description`           | string  | Une description pour le jeton. |
| `last_used_at`          | datetime| La date et l'heure auxquelles le jeton a été utilisé pour la dernière fois. |
| `created_at`            | datetime| La date et l'heure auxquelles le jeton a été créé. |
| `updated_at`            | datetime| La date et l'heure auxquelles le jeton a été mis à jour pour la dernière fois. |
| `token`                 | string  | La valeur réelle du jeton utilisée pour l'authentification. |

Exemple de requête :

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --header "Content-Type: application/json" \
    --data '{"description": "Token for runner controller"}' \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens"
```

Exemple de réponse :

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "last_used_at": null,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z",
    "token": "glrct-<token>"
}
```

## Révoquer un jeton de contrôleur de runner {#revoke-a-runner-controller-token}

Révoque un jeton de contrôleur de runner existant.

```plaintext
DELETE /runner_controllers/:id/tokens/:token_id
```

Paramètres :

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `id`               | entier      | Oui      | L'identifiant du contrôleur de runner. |
| `token_id`         | entier      | Oui      | L'identifiant du jeton de contrôleur de runner. |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id"
```

## Faire pivoter un jeton de contrôleur de runner {#rotate-a-runner-controller-token}

Fait pivoter un jeton de contrôleur de runner existant.

```plaintext
POST /runner_controllers/:id/tokens/:token_id/rotate
```

Paramètres :

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `id`               | entier      | Oui      | L'identifiant du contrôleur de runner. |
| `token_id`         | entier      | Oui      | L'identifiant du jeton de contrôleur de runner. |

Réponse :

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) avec les attributs suivants :

| Attribut               | Type    | Description |
|-------------------------|---------|-------------|
| `id`                    | entier | L'identifiant unique du jeton de contrôleur de runner. |
| `runner_controller_id`  | entier | L'identifiant du contrôleur de runner associé. |
| `description`           | string  | Une description pour le jeton. |
| `last_used_at`          | datetime| La date et l'heure auxquelles le jeton a été utilisé pour la dernière fois. |
| `created_at`            | datetime| La date et l'heure auxquelles le jeton a été créé. |
| `updated_at`            | datetime| La date et l'heure auxquelles le jeton a été mis à jour pour la dernière fois. |
| `token`                 | string  | La valeur réelle du jeton utilisée pour l'authentification. |

Exemple de requête :

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/runner_controllers/:id/tokens/:token_id/rotate"
```

Exemple de réponse :

```json
{
    "id": 1,
    "runner_controller_id": 1,
    "description": "Token for runner controller",
    "last_used_at": "2026-01-05T00:00:00Z",
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z",
    "token": "glrct-<token>"
}
```
