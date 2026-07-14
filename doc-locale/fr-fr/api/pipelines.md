---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "API REST pour créer, gérer et surveiller des pipelines CI/CD."
title: API Pipelines
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [pipelines CI/CD](../ci/pipelines/_index.md).

## Lister les pipelines d'un projet {#list-project-pipelines}

{{< history >}}

- `name` dans la réponse [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) dans GitLab 15.11 [avec un indicateur](../administration/feature_flags/_index.md) nommé `pipeline_name_in_api`. Désactivé par défaut. Désactivé par défaut.
- `name` dans la requête [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) dans la version 15.11 [avec un indicateur](../administration/feature_flags/_index.md) nommé `pipeline_name_search`. Désactivé par défaut. Désactivé par défaut.
- `name` dans la réponse [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/398131) dans GitLab 16.3. L'indicateur de fonctionnalité `pipeline_name_in_api` a été supprimé.
- `name` dans la requête [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/385864) dans GitLab 16.9. L'indicateur de fonctionnalité `pipeline_name_search` a été supprimé.
- Prise en charge du retour des pipelines enfants avec `source` défini sur `parent_pipeline` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/39503) dans GitLab 17.0.

{{< /history >}}

Liste les pipelines dans un projet.

Par défaut, les [pipelines enfants](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines) ne sont pas inclus dans les résultats. Pour retourner les pipelines enfants, définissez `source` sur `parent_pipeline`.

```plaintext
GET /projects/:id/pipelines
```

Utilisez les paramètres `page` et `per_page` de [pagination](rest/_index.md#offset-based-pagination) pour contrôler la pagination des résultats.

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `id`             | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name`           | string            | Non       | Retourne les pipelines portant le nom spécifié. |
| `order_by`       | string            | Non       | Le champ selon lequel trier les pipelines : `id`, `status`, `ref`, `updated_at` ou `user_id` (par défaut : `id`). |
| `ref`            | string            | Non       | Retourne les pipelines pour la branche ou le tag spécifié. |
| `scope`          | string            | Non       | Retourne les pipelines dans la portée spécifiée : `running`, `pending`, `finished`, `branches` ou `tags`. |
| `sha`            | string            | Non       | Retourne les pipelines pour le SHA de commit spécifié. |
| `sort`           | string            | Non       | L'ordre de tri : `asc` ou `desc` (par défaut : `desc`). |
| `source`         | string            | Non       | Retourne les pipelines avec la [source](../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable) spécifiée. |
| `status`         | string            | Non       | Retourne les pipelines avec le statut spécifié : `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual` ou `scheduled`. |
| `updated_after`  | datetime          | Non       | Retourne les pipelines mis à jour après la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `updated_before` | datetime          | Non       | Retourne les pipelines mis à jour avant la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_after`  | datetime          | Non       | Retourne les pipelines créés après la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before` | datetime          | Non       | Retourne les pipelines créés avant la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `username`       | string            | Non       | Retourne les pipelines déclenchés par le nom d'utilisateur spécifié. |
| `yaml_errors`    | boolean           | Non       | Retourne les pipelines avec des configurations invalides. |

Lorsque `scope` est défini sur `branches` ou `tags`, l'API retourne uniquement le dernier pipeline pour chaque référence de branche ou de tag.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines"
```

Exemple de réponse

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 1,
    "status": "pending",
    "source": "push",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 1,
    "status": "pending",
    "source": "web",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## Récupérer un pipeline unique {#retrieve-a-single-pipeline}

{{< history >}}

- `name` dans la réponse [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) dans GitLab 15.11 [avec un indicateur](../administration/feature_flags/_index.md) nommé `pipeline_name_in_api`. Désactivé par défaut. Désactivé par défaut.
- `name` dans la réponse [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/398131) dans GitLab 16.3. L'indicateur de fonctionnalité `pipeline_name_in_api` a été supprimé.

{{< /history >}}

Récupère un pipeline unique à partir d'un projet.

Vous pouvez également obtenir un [pipeline enfant](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines) unique.

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

Utilisez les paramètres `page` et `per_page` de [pagination](rest/_index.md#offset-based-pagination) pour contrôler la pagination des résultats.

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `pipeline_id` | entier        | Oui      | L'ID d'un pipeline |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

Exemple de réponse

```json
{
  "id": 287,
  "iid": 144,
  "project_id": 21,
  "name": "Build pipeline",
  "sha": "50f0acb76a40e34a4ff304f7347dcc6587da8a14",
  "ref": "main",
  "status": "success",
  "source": "push",
  "created_at": "2022-09-21T01:05:07.200Z",
  "updated_at": "2022-09-21T01:05:50.185Z",
  "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/287",
  "before_sha": "8a24fb3c5877a6d0b611ca41fc86edc174593e2b",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "username": "root",
    "name": "Administrator",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/root"
  },
  "started_at": "2022-09-21T01:05:14.197Z",
  "finished_at": "2022-09-21T01:05:50.175Z",
  "committed_at": null,
  "duration": 34,
  "queued_duration": 6,
  "coverage": null,
  "detailed_status": {
    "icon": "status_success",
    "text": "passed",
    "label": "passed",
    "group": "success",
    "tooltip": "passed",
    "has_details": false,
    "details_path": "/test-group/test-project/-/pipelines/287",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
  },
  "archived": false
}
```

## Récupérer le dernier pipeline {#retrieve-the-latest-pipeline}

{{< history >}}

- `name` dans la réponse [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310) dans GitLab 15.11 [avec un indicateur](../administration/feature_flags/_index.md) nommé `pipeline_name_in_api`. Désactivé par défaut. Désactivé par défaut.
- `name` dans la réponse [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/398131) dans GitLab 16.3. L'indicateur de fonctionnalité `pipeline_name_in_api` a été supprimé.

{{< /history >}}

Récupère le dernier pipeline pour le commit le plus récent sur une référence spécifique dans un projet. Si aucun pipeline n'existe pour le commit, un code de statut `403` est retourné.

```plaintext
GET /projects/:id/pipelines/latest
```

Utilisez les paramètres `page` et `per_page` de [pagination](rest/_index.md#offset-based-pagination) pour contrôler la pagination des résultats.

| Attribut | Type   | Obligatoire | Description |
|-----------|--------|----------|-------------|
| `ref`     | string | Non       | La branche ou le tag pour lequel vérifier le dernier pipeline. Par défaut, correspond à la branche par défaut si non spécifié. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/latest"
```

Exemple de réponse

```json
{
    "id": 287,
    "iid": 144,
    "project_id": 21,
    "name": "Build pipeline",
    "sha": "50f0acb76a40e34a4ff304f7347dcc6587da8a14",
    "ref": "main",
    "status": "success",
    "source": "push",
    "created_at": "2022-09-21T01:05:07.200Z",
    "updated_at": "2022-09-21T01:05:50.185Z",
    "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/287",
    "before_sha": "8a24fb3c5877a6d0b611ca41fc86edc174593e2b",
    "tag": false,
    "yaml_errors": null,
    "user": {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/root"
    },
    "started_at": "2022-09-21T01:05:14.197Z",
    "finished_at": "2022-09-21T01:05:50.175Z",
    "committed_at": null,
    "duration": 34,
    "queued_duration": 6,
    "coverage": null,
    "detailed_status": {
        "icon": "status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "tooltip": "passed",
        "has_details": false,
        "details_path": "/test-group/test-project/-/pipelines/287",
        "illustration": null,
        "favicon": "/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
    },
    "archived": false
}
```

## Récupérer les variables d'un pipeline {#retrieve-pipeline-variables}

Récupère les [variables du pipeline](../ci/variables/_index.md#use-pipeline-variables) d'un pipeline.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/variables
```

Utilisez les paramètres `page` et `per_page` de [pagination](rest/_index.md#offset-based-pagination) pour contrôler la pagination des résultats.

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `pipeline_id` | entier        | Oui      | L'ID d'un pipeline |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/variables"
```

Exemple de réponse

```json
[
  {
    "key": "RUN_NIGHTLY_BUILD",
    "variable_type": "env_var",
    "value": "true"
  },
  {
    "key": "foo",
    "value": "bar"
  }
]
```

## Récupérer un rapport de test pour un pipeline {#retrieve-a-test-report-for-a-pipeline}

> [!note]
> Cette route d'API fait partie de la fonctionnalité [Rapport de test unitaire](../ci/testing/unit_test_reports.md).

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

Utilisez les paramètres `page` et `per_page` de [pagination](rest/_index.md#offset-based-pagination) pour contrôler la pagination des résultats.

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `pipeline_id` | entier        | Oui      | L'ID d'un pipeline |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report"
```

Exemple de réponse :

```json
{
  "total_time": 5,
  "total_count": 1,
  "success_count": 1,
  "failed_count": 0,
  "skipped_count": 0,
  "error_count": 0,
  "test_suites": [
    {
      "name": "Secure",
      "total_time": 5,
      "total_count": 1,
      "success_count": 1,
      "failed_count": 0,
      "skipped_count": 0,
      "error_count": 0,
      "test_cases": [
        {
          "status": "success",
          "name": "Security Reports can create an auto-remediation MR",
          "classname": "vulnerability_management_spec",
          "execution_time": 5,
          "system_output": null,
          "stack_trace": null
        }
      ]
    }
  ]
}
```

## Récupérer un résumé de rapport de test pour un pipeline {#retrieve-a-test-report-summary-for-a-pipeline}

> [!note]
> Cette route d'API fait partie de la fonctionnalité [Rapport de test unitaire](../ci/testing/unit_test_reports.md).

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report_summary
```

Utilisez les paramètres `page` et `per_page` de [pagination](rest/_index.md#offset-based-pagination) pour contrôler la pagination des résultats.

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `pipeline_id` | entier        | Oui      | L'ID d'un pipeline |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report_summary"
```

Exemple de réponse :

```json
{
    "total": {
        "time": 1904,
        "count": 3363,
        "success": 3351,
        "failed": 0,
        "skipped": 12,
        "error": 0,
        "suite_error": null
    },
    "test_suites": [
        {
            "name": "test",
            "total_time": 1904,
            "total_count": 3363,
            "success_count": 3351,
            "failed_count": 0,
            "skipped_count": 12,
            "error_count": 0,
            "build_ids": [
                66004
            ],
            "suite_error": null
        }
    ]
}
```

## Créer un nouveau pipeline {#create-a-new-pipeline}

{{< history >}}

- `iid` dans la réponse [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) dans GitLab 14.6.
- L'attribut `inputs` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/519958) dans GitLab 17.10 [avec un indicateur](../administration/feature_flags/_index.md) nommé `ci_inputs_for_pipelines`. Activé par défaut. Activé par défaut.
- L'attribut `inputs` [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/536548) dans GitLab 18.1. L'indicateur de fonctionnalité `ci_inputs_for_pipelines` a été supprimé.

{{< /history >}}

```plaintext
POST /projects/:id/pipeline
```

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `ref`       | string         | Oui      | La branche ou le tag sur lequel exécuter le pipeline. Pour les pipelines de merge request, utilisez le [point de terminaison des merge requests](merge_requests.md#create-merge-request-pipeline). |
| `variables` | tableau          | Non       | Un [tableau de hachages](rest/_index.md#array-of-hashes) contenant les variables disponibles dans le pipeline, correspondant à la structure `[{ 'key': 'UPLOAD_TO_S3', 'variable_type': 'file', 'value': 'true' }, {'key': 'TEST', 'value': 'test variable'}]`. Si `variable_type` est exclu, la valeur par défaut est `env_var`. |
| `inputs`    | hachage           | Non       | Un [hachage](rest/_index.md#hash) contenant les entrées, sous forme de paires clé-valeur, à utiliser lors de la création du pipeline. |

Exemple de base :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

Exemple de requête avec des [entrées](../ci/inputs/_index.md) :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main" \
  --data '{"inputs": {"environment": "environment", "scan_security": false, "level": 3}}'
```

Exemple de réponse

```json
{
  "id": 61,
  "iid": 21,
  "project_id": 1,
  "sha": "384c444e840a515b23f21915ee5766b87068a70d",
  "ref": "main",
  "status": "pending",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-11-04T09:36:13.747Z",
  "updated_at": "2016-11-04T09:36:13.977Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/61",
  "archived": false
}
```

## Relancer les jobs d'un pipeline {#retry-jobs-in-a-pipeline}

{{< history >}}

- `iid` dans la réponse [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/342223) dans GitLab 14.6.

{{< /history >}}

Relance les jobs échoués ou annulés dans un pipeline. S'il n'y a aucun job échoué ou annulé dans le pipeline, l'appel à ce point de terminaison n'a aucun effet.

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `pipeline_id` | entier        | Oui      | L'ID d'un pipeline |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/retry"
```

Réponse :

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "pending",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "archived": false
}
```

## Annuler tous les jobs d'un pipeline {#cancel-all-jobs-for-a-pipeline}

```plaintext
POST /projects/:id/pipelines/:pipeline_id/cancel
```

> [!note]
> Ce point de terminaison retourne une réponse de succès `200` quel que soit l'état du pipeline. Pour plus d'informations, consultez le [ticket 414963](https://gitlab.com/gitlab-org/gitlab/-/issues/414963).

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `pipeline_id` | entier        | Oui      | L'ID d'un pipeline |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/cancel"
```

Réponse :

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "canceled",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "archived": false
}
```

## Supprimer un pipeline {#delete-a-pipeline}

La suppression d'un pipeline fait expirer tous les caches du pipeline et supprime tous les objets directement associés, tels que les builds, les journaux, les artefacts et les déclencheurs. **This action cannot be undone**.

La suppression d'un pipeline ne supprime pas automatiquement ses [pipelines enfants](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines). Consultez le [ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/39503) pour plus de détails.

```plaintext
DELETE /projects/:id/pipelines/:pipeline_id
```

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `pipeline_id` | entier        | Oui      | L'ID d'un pipeline |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

## Mettre à jour les métadonnées du pipeline {#update-pipeline-metadata}

Met à jour les métadonnées du pipeline. Les métadonnées contiennent le nom du pipeline.

```plaintext
PUT /projects/:id/pipelines/:pipeline_id/metadata
```

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `name`        | string         | Oui      | Le nouveau nom du pipeline |
| `pipeline_id` | entier        | Oui      | L'ID d'un pipeline |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/46/metadata" \
  --data '{"name": "Some new pipeline name"}'
```

Exemple de réponse :

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "running",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "name": "Some new pipeline name",
  "archived": false
}
```
