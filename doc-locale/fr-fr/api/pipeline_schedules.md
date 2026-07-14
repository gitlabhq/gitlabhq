---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des planifications de pipeline
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [planifications de pipeline](../ci/pipelines/schedules.md).

## Répertorier toutes les planifications de pipeline {#list-all-pipeline-schedules}

Répertorie toutes les planifications de pipeline pour un projet.

```plaintext
GET /projects/:id/pipeline_schedules
```

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `scope`   | string            | Non       | Portée des planifications de pipeline, doit être l'une des valeurs suivantes : `active`, `inactive`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules"
```

```json
[
    {
        "id": 13,
        "description": "Test schedule pipeline",
        "ref": "refs/heads/main",
        "cron": "* * * * *",
        "cron_timezone": "Asia/Tokyo",
        "next_run_at": "2017-05-19T13:41:00.000Z",
        "active": true,
        "created_at": "2017-05-19T13:31:08.849Z",
        "updated_at": "2017-05-19T13:40:17.727Z",
        "owner": {
            "name": "Administrator",
            "username": "root",
            "id": 1,
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
            "web_url": "https://gitlab.example.com/root"
        },
        "inputs": [
            {
                "name": "deploy_strategy",
                "value": "blue-green"
            },
            {
                "name": "feature_flags",
                "value": ["flag1", "flag2"]
            }
        ]
    }
]
```

> [!note]
> Le champ `inputs` n'est inclus dans la réponse que pour les utilisateurs disposant des rôles Maintainer ou Owner, ou pour le propriétaire de la planification.

## Récupérer une planification de pipeline {#retrieve-a-pipeline-schedule}

Récupère une planification de pipeline pour un projet.

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "* * * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T13:41:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:40:17.727Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    },
    "variables": [
        {
            "key": "TEST_VARIABLE_1",
            "variable_type": "env_var",
            "value": "TEST_1",
            "raw": false
        }
    ],
    "inputs": [
        {
            "name": "deploy_strategy",
            "value": "blue-green"
        },
        {
            "name": "feature_flags",
            "value": ["flag1", "flag2"]
        }
    ]
}
```

> [!note]
> Les champs `inputs` et `variables` ne sont inclus dans la réponse que pour les utilisateurs disposant des rôles Maintainer ou Owner, ou pour le propriétaire de la planification.

## Répertorier tous les pipelines déclenchés par une planification de pipeline {#list-all-pipelines-triggered-by-a-pipeline-schedule}

Répertorie tous les pipelines déclenchés par une planification de pipeline dans un projet.

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id/pipelines
```

Attributs pris en charge :

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |
| `scope`                | string            | Non       | Portée des pipelines. L'une des valeurs suivantes : `running`, `pending`, `finished`, `branches`, `tags`. |
| `sort`                 | string            | Non       | Trier les pipelines par ordre `asc` ou `desc`. La valeur par défaut est `asc`. |
| `status`               | string            | Non       | Statut des pipelines. L'une des valeurs suivantes : `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual`, `scheduled`. |
| `updated_after`        | datetime          | Non       | Retourne les pipelines mis à jour après la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `updated_before`       | datetime          | Non       | Retourne les pipelines mis à jour avant la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_after`        | datetime          | Non       | Retourne les pipelines créés après la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before`       | datetime          | Non       | Retourne les pipelines créés avant la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/pipelines"
```

Exemple de réponse :

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 29,
    "status": "pending",
    "source": "scheduled",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 29,
    "status": "pending",
    "source": "scheduled",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## Créer une nouvelle planification de pipeline {#create-a-new-pipeline-schedule}

{{< history >}}

- Attribut `inputs` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/525504) dans GitLab 17.11 [avec un flag](../administration/feature_flags/_index.md) nommé `ci_inputs_for_pipelines`. Activé par défaut. Activé par défaut.
- Attribut `inputs` [disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/536548) dans GitLab 18.1. L'indicateur de fonctionnalité `ci_inputs_for_pipelines` a été supprimé.

{{< /history >}}

Crée une nouvelle planification de pipeline pour un projet.

```plaintext
POST /projects/:id/pipeline_schedules
```

| Attribut       | Type              | Obligatoire | Description |
| --------------- | ----------------- | -------- | ----------- |
| `cron`          | string            | Oui      | Planification cron, par exemple : `0 1 * * *`. |
| `description`   | string            | Oui      | Description de la planification de pipeline. |
| `id`            | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `ref`           | string            | Oui      | Nom de la branche ou du tag qui déclenche le pipeline. Accepte les refs courts (`main`) ou les refs complets (`refs/heads/main` ou `refs/tags/main`). Les refs courts sont automatiquement développés en refs complets, sauf si la valeur peut correspondre à une branche ou à un tag. |
| `active`        | boolean           | Non       | Active la planification de pipeline. Si la valeur false est définie, la planification de pipeline est initialement désactivée (par défaut : `true`). |
| `cron_timezone` | string            | Non       | Fuseau horaire pris en charge par `ActiveSupport::TimeZone`, par exemple : `Pacific Time (US & Canada)` (par défaut : `UTC`). |
| `inputs`        | hash              | Non       | Tableau d'[inputs](../ci/inputs/_index.md#for-a-pipeline) à transmettre à la planification de pipeline. Chaque input contient un `name` et une `value`. Les valeurs peuvent être des chaînes, des tableaux, des nombres ou des booléens. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules" \
  --form "description=Build packages" \
  --form "ref=main" \
  --form "cron=0 1 * * 5" \
  --form "cron_timezone=UTC" \
  --form "active=true"
```

Exemple de réponse :

```json
{
    "id": 14,
    "description": "Build packages",
    "ref": "refs/heads/main",
    "cron": "0 1 * * 5",
    "cron_timezone": "UTC",
    "next_run_at": "2017-05-26T01:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:43:08.169Z",
    "updated_at": "2017-05-19T13:43:08.169Z",
    "last_pipeline": null,
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    }
}
```

Exemple de requête avec `inputs` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules" \
  --form "description=Build packages" \
  --form "ref=main" \
  --form "cron=0 1 * * 5" \
  --form "cron_timezone=UTC" \
  --form "active=true" \
  --form "inputs[][name]=deploy_strategy" \
  --form "inputs[][value]=blue-green"
```

## Mettre à jour une planification de pipeline {#update-a-pipeline-schedule}

Met à jour une planification de pipeline pour un projet. Une fois la mise à jour effectuée, la planification est automatiquement reprogrammée.

```plaintext
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |
| `active`               | boolean           | Non       | Active la planification de pipeline. Si la valeur false est définie, la planification de pipeline est initialement désactivée. |
| `cron_timezone`        | string            | Non       | Fuseau horaire pris en charge par `ActiveSupport::TimeZone` (par exemple `Pacific Time (US & Canada)`), ou `TZInfo::Timezone` (par exemple `America/Los_Angeles`). |
| `cron`                 | string            | Non       | Planification cron, par exemple : `0 1 * * *`. |
| `description`          | string            | Non       | Description de la planification de pipeline. |
| `ref`                  | string            | Non       | Nom de la branche ou du tag qui déclenche le pipeline. Accepte les refs courts (`main`) ou les refs complets (`refs/heads/main` ou `refs/tags/main`). Les refs courts sont automatiquement développés en refs complets, sauf si la valeur peut correspondre à une branche ou à un tag. |
| `inputs`               | hash              | Non       | Tableau d'[inputs](../ci/inputs/_index.md) à transmettre à la planification de pipeline. Chaque input contient un `name` et une `value`. Pour supprimer un input existant, incluez le champ `name` et définissez `destroy` sur `true`. Les valeurs peuvent être des chaînes, des tableaux, des nombres ou des booléens. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13" \
  --form "cron=0 2 * * *"
```

Exemple de réponse :

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:44:16.135Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    }
}
```

Exemple de requête avec `inputs` :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13" \
  --form "cron=0 2 * * *" \
  --form "inputs[][name]=deploy_strategy" \
  --form "inputs[][value]=rolling" \
  --form "inputs[][name]=existing_input" \
  --form "inputs[][destroy]=true"
```

## Mettre à jour la propriété d'une planification de pipeline {#update-ownership-of-a-pipeline-schedule}

Met à jour le propriétaire d'une planification de pipeline pour un projet.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/take_ownership"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/maeda"
    }
}
```

## Supprimer une planification de pipeline {#delete-a-pipeline-schedule}

Supprime une planification de pipeline pour un projet.

```plaintext
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/maeda"
    }
}
```

## Exécuter une planification de pipeline immédiatement {#run-a-pipeline-schedule-immediately}

Exécute une planification de pipeline immédiatement. La prochaine exécution planifiée de ce pipeline n'est pas affectée.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/play
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/pipeline_schedules/1/play"
```

Exemple de réponse :

```json
{
  "message": "201 Created"
}
```

## Créer une variable pour une planification de pipeline {#create-a-variable-for-a-pipeline-schedule}

Crée une nouvelle variable pour une planification de pipeline.

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `key`                  | string            | Oui      | Clé d'une variable ; ne doit pas dépasser 255 caractères ; seuls `A-Z`, `a-z`, `0-9` et `_` sont autorisés. |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |
| `value`                | string            | Oui      | Valeur d'une variable. |
| `variable_type`        | string            | Non       | Type d'une variable. Les types disponibles sont : `env_var` (par défaut) et `file`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "variable_type": "env_var",
    "value": "new value"
}
```

## Récupérer une variable pour une planification de pipeline {#retrieve-a-variable-for-a-pipeline-schedule}

{{< history >}}

- [Introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/386005) dans GitLab 18.7.

{{< /history >}}

Récupère une variable pour une planification de pipeline.

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `key`                  | string            | Oui      | Clé d'une variable. |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut       | Type   | Description |
| --------------- | ------ | ----------- |
| `key`           | string | Clé de la variable. |
| `value`         | string | Valeur de la variable. |
| `variable_type` | string | Type de la variable. Soit `env_var` soit `file`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

Exemple de réponse :

```json
{
    "key": "NEW_VARIABLE",
    "variable_type": "env_var",
    "value": "new value"
}
```

## Mettre à jour une variable pour une planification de pipeline {#update-a-variable-for-a-pipeline-schedule}

Met à jour une variable pour une planification de pipeline.

```plaintext
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `key`                  | string            | Oui      | Clé d'une variable. |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |
| `value`                | string            | Oui      | Valeur d'une variable. |
| `variable_type`        | string            | Non       | Type d'une variable. Les types disponibles sont : `env_var` (par défaut) et `file`. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var"
}
```

## Supprimer une variable pour une planification de pipeline {#delete-a-variable-for-a-pipeline-schedule}

Supprime une variable pour une planification de pipeline.

```plaintext
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| Attribut              | Type              | Obligatoire | Description |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `key`                  | string            | Oui      | Clé d'une variable. |
| `pipeline_schedule_id` | entier           | Oui      | ID de la planification de pipeline. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value"
}
```

### Refs ambigus {#ambiguous-refs}

L'API ne peut pas développer automatiquement un `ref` court en un `ref` complet dans les cas suivants :

- Une branche et un tag existent tous deux avec le même nom que votre `ref` court.
- Aucune branche ni aucun tag n'existe avec ce nom.

Pour résoudre ce problème, fournissez le `ref` complet afin de vous assurer que la ressource correcte est identifiée.
