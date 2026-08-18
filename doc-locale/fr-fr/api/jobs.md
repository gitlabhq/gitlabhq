---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "API REST pour récupérer les détails des jobs CI/CD, réessayer et annuler des jobs, exécuter des jobs manuels et accéder aux job logs."
title: API Jobs
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [jobs CI/CD](../ci/jobs/_index.md).

## Lister tous les jobs d'un projet {#list-all-jobs-for-a-project}

Liste tous les jobs d'un projet spécifié.

Par défaut, cette requête renvoie 20 résultats à la fois, car les résultats de l'API [sont paginés](rest/_index.md#pagination)

> [!note]
> Cet endpoint prend en charge la pagination par décalage et la pagination [par jeu de clés](rest/_index.md#keyset-based-pagination), mais la pagination par jeu de clés est fortement recommandée lors de la demande de pages de résultats consécutives.

```plaintext
GET /projects/:id/jobs
```

| Attribut  | Type                           | Obligatoire | Description |
| ---------- | ------------------------------ | -------- | ----------- |
| `id`       | entier ou chaîne                 | Oui      | ID ou [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du projet. |
| `scope`    | chaîne ou tableau de chaînes | Non       | Portée des jobs à afficher. L'une des valeurs ou un tableau de [valeurs de statut de job](#job-status-values). Tous les jobs sont renvoyés si `scope` n'est pas fourni. |
| `order_by` | string                         | Non       | Renvoie les jobs triés par `id`. |
| `sort`     | string                         | Non       | Renvoie les jobs triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs?scope[]=pending&scope[]=running"
```

Exemple de réponse :

```json
[
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:54:27.895Z",
    "erased_at": null,
    "duration": 0.173,
    "queued_duration": 0.010,
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "artifacts": [
      {"file_type": "archive", "size": 1000, "filename": "artifacts.zip", "file_format": "zip"},
      {"file_type": "metadata", "size": 186, "filename": "metadata.gz", "file_format": "gzip"},
      {"file_type": "trace", "size": 1500, "filename": "job.log", "file_format": "raw"},
      {"file_type": "junit", "size": 750, "filename": "junit.xml.gz", "file_format": "gzip"}
    ],
    "artifacts_expire_at": "2016-01-23T17:54:27.895Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "runner": {
      "id": 32,
      "description": "",
      "ip_address": null,
      "active": true,
      "paused": false,
      "is_shared": true,
      "runner_type": "instance_type",
      "name": null,
      "online": false,
      "status": "offline"
    },
    "runner_manager": {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-05-01T10:12:02.507Z",
      "contacted_at": "2024-05-07T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline"
    },
    "stage": "test",
    "status": "failed",
    "failure_reason": "script_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  },
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.727Z",
    "started_at": "2015-12-24T17:54:24.729Z",
    "finished_at": "2015-12-24T17:54:24.921Z",
    "erased_at": null,
    "duration": 0.192,
    "queued_duration": 0.023,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "tag_list": [
      "docker runner", "win10-2004"
    ],
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "artifacts": [],
    "runner": null,
    "runner_manager": null,
    "stage": "test",
    "status": "failed",
    "failure_reason": "stuck_or_timeout_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/6",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  }
]
```

### Valeurs de statut de job {#job-status-values}

Le champ `status` dans les réponses de job et le paramètre `scope` pour filtrer les jobs utilisent les valeurs suivantes :

- `canceled` :  Le job a été annulé manuellement ou interrompu automatiquement.
- `canceling` :  Le job est en cours d'annulation mais `after_script` est en cours d'exécution.
- `created` :  Le job a été créé mais n'a pas encore été traité.
- `failed` :  L'exécution du job a échoué.
- `manual` :  Le job nécessite une action manuelle pour démarrer.
- `pending` :  Le job est dans la file d'attente en attente d'un runner.
- `preparing` :  Le runner prépare l'environnement d'exécution.
- `running` :  Le job s'exécute sur un runner.
- `scheduled` :  Le job a été planifié mais l'exécution n'a pas encore commencé.
- `skipped` :  Le job a été ignoré en raison de conditions ou de dépendances.
- `success` :  Le job s'est terminé avec succès.
- `waiting_for_callback` :  Le job attend un rappel d'un service externe.
- `waiting_for_resource` :  Le job attend que des ressources deviennent disponibles.

## Lister tous les jobs par pipeline {#list-all-jobs-by-pipeline}

Liste tous les jobs d'un pipeline spécifié.

Par défaut, cette requête renvoie 20 résultats à la fois, car les résultats de l'API [sont paginés](rest/_index.md#pagination)

Cet endpoint :

- [Renvoie des données pour tout pipeline](pipelines.md#retrieve-a-single-pipeline) , y compris les [pipelines enfants](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines).
- Ne renvoie pas les jobs relancés dans la réponse par défaut.
- Trie les jobs par ID dans l'ordre décroissant (les plus récents en premier).

```plaintext
GET /projects/:id/pipelines/:pipeline_id/jobs
```

| Attribut         | Type                           | Obligatoire | Description |
| ----------------- | ------------------------------ | -------- | ----------- |
| `id`              | entier ou chaîne                 | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `pipeline_id`     | entier                        | Oui      | ID d'un pipeline. Peut également être obtenu dans les jobs CI à l'aide de la [variable CI prédéfinie](../ci/variables/predefined_variables.md) `CI_PIPELINE_ID`. |
| `include_retried` | boolean                        | Non       | Inclure les jobs relancés dans la réponse. La valeur par défaut est `false`. |
| `scope`           | chaîne **ou** tableau de chaînes | Non       | Portée des jobs à afficher. L'une des valeurs ou un tableau de [valeurs de statut de job](#job-status-values). Tous les jobs sont renvoyés si `scope` n'est pas fourni. |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/6/jobs?scope[]=pending&scope[]=running"
```

Exemple de réponse :

```json
[
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.727Z",
    "started_at": "2015-12-24T17:54:24.729Z",
    "finished_at": "2015-12-24T17:54:24.921Z",
    "erased_at": null,
    "duration": 0.192,
    "queued_duration": 0.023,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "artifacts": [],
    "runner": {
      "id": 32,
      "description": "",
      "ip_address": null,
      "active": true,
      "paused": false,
      "is_shared": true,
      "runner_type": "instance_type",
      "name": null,
      "online": false,
      "status": "offline"
    },
    "runner_manager": {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-05-01T10:12:02.507Z",
      "contacted_at": "2024-05-07T06:30:09.355Z",
      "ip_address": "127.0.0.1",
    },
    "stage": "test",
    "status": "failed",
    "failure_reason": "stuck_or_timeout_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/6",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  },
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:54:27.895Z",
    "erased_at": null,
    "duration": 0.173,
    "queued_duration": 0.023,
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "artifacts": [
      {"file_type": "archive", "size": 1000, "filename": "artifacts.zip", "file_format": "zip"},
      {"file_type": "metadata", "size": 186, "filename": "metadata.gz", "file_format": "gzip"},
      {"file_type": "trace", "size": 1500, "filename": "job.log", "file_format": "raw"},
      {"file_type": "junit", "size": 750, "filename": "junit.xml.gz", "file_format": "gzip"}
    ],
    "artifacts_expire_at": "2016-01-23T17:54:27.895Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "runner": null,
    "runner_manager": null,
    "stage": "test",
    "status": "failed",
    "failure_reason": "script_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  }
]
```

## Lister tous les jobs de déclenchement par pipeline {#list-all-trigger-jobs-by-pipeline}

Liste tous les jobs de déclenchement d'un pipeline spécifié.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/bridges
```

| Attribut     | Type                           | Obligatoire | Description |
| ------------- | ------------------------------ | -------- | ----------- |
| `id`          | entier ou chaîne                 | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `pipeline_id` | entier                        | Oui      | ID d'un pipeline. |
| `scope`       | chaîne **ou** tableau de chaînes | Non       | Portée des jobs à afficher. L'une des valeurs ou un tableau de [valeurs de statut de job](#job-status-values). Tous les jobs sont renvoyés si `scope` n'est pas fourni. |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/6/bridges?scope[]=pending&scope[]=running"
```

Exemple de réponse :

```json
[
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:58:27.895Z",
    "erased_at": null,
    "duration": 240,
    "queued_duration": 0.123,
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending",
      "created_at": "2015-12-24T15:50:16.123Z",
      "updated_at": "2015-12-24T18:00:44.432Z",
      "web_url": "https://example.com/foo/bar/pipelines/6"
    },
    "ref": "main",
    "stage": "test",
    "status": "pending",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    },
    "downstream_pipeline": {
      "id": 5,
      "sha": "f62a4b2fb89754372a346f24659212eb8da13601",
      "ref": "main",
      "status": "pending",
      "created_at": "2015-12-24T17:54:27.722Z",
      "updated_at": "2015-12-24T17:58:27.896Z",
      "web_url": "https://example.com/diaspora/diaspora-client/pipelines/5"
    }
  }
]
```

## Récupérer un job par jeton de job {#retrieve-a-job-by-job-token}

Récupère un job généré par un jeton de job spécifié.

```plaintext
GET /job
```

Exemples (doit être exécuté dans la section [`script`](../ci/yaml/_index.md#script) d'un [job CI/CD](../ci/jobs/_index.md)) :

```shell
# Option 1
curl --header "Authorization: Bearer $CI_JOB_TOKEN" \
  --url "${CI_API_V4_URL}/job"

# Option 2
curl --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --url "${CI_API_V4_URL}/job"

# Option 3
curl --url "${CI_API_V4_URL}/job?job_token=$CI_JOB_TOKEN"
```

Exemple de réponse :

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2015-12-24T15:51:21.880Z",
  "started_at": "2015-12-24T17:54:30.733Z",
  "finished_at": "2015-12-24T17:54:31.198Z",
  "erased_at": null,
  "duration": 0.465,
  "queued_duration": 0.123,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "project_id": 1,
    "ref": "main",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "failed",
  "failure_reason": "script_failure",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/8",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.dev/root",
    "created_at": "2015-12-21T13:14:24.077Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": ""
  }
}
```

## Récupérer l'agent GitLab pour Kubernetes par `CI_JOB_TOKEN` {#retrieve-gitlab-agent-for-kubernetes-by-ci_job_token}

Récupère le job qui a généré le `CI_JOB_TOKEN`, ainsi qu'une liste des [agents](../user/clusters/agent/_index.md) autorisés.

```plaintext
GET /job/allowed_agents
```

Attributs pris en charge :

| Attribut      | Type   | Obligatoire | Description |
|----------------|--------|----------|-------------|
| `CI_JOB_TOKEN` | string | Oui      | Valeur du jeton associée à la variable `CI_JOB_TOKEN` fournie par GitLab. |

Exemple de requête :

```shell
# Option 1
curl --header "JOB-TOKEN: <CI_JOB_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/job/allowed_agents"

# Option 2
curl --url "https://gitlab.example.com/api/v4/job/allowed_agents?job_token=<CI_JOB_TOKEN>"
```

Exemple de réponse :

```json
{
  "allowed_agents": [
    {
      "id": 1,
      "config_project": {
        "id": 1,
        "description": null,
        "name": "project1",
        "name_with_namespace": "John Doe2 / project1",
        "path": "project1",
        "path_with_namespace": "namespace1/project1",
        "created_at": "2022-11-16T14:51:50.579Z"
      }
    }
  ],
  "job": {
    "id": 1
  },
  "pipeline": {
    "id": 2
  },
  "project": {
    "id": 1,
    "groups": [
      {
        "id": 1
      },
      {
        "id": 2
      },
      {
        "id": 3
      }
    ]
  },
  "user": {
    "id": 2,
    "name": "John Doe3",
    "username": "user2",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/10fc7f102b",
    "web_url": "http://localhost/user2"
  }
}
```

## Récupérer un job par ID de job {#retrieve-a-job-by-job-id}

Récupère un job avec un ID de job spécifié.

```plaintext
GET /projects/:id/jobs/:job_id
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`  | entier        | Oui      | ID d'un job. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/8"
```

Exemple de réponse :

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2015-12-24T15:51:21.880Z",
  "started_at": "2015-12-24T17:54:30.733Z",
  "finished_at": "2015-12-24T17:54:31.198Z",
  "erased_at": null,
  "duration": 0.465,
  "queued_duration": 0.010,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "tag_list": [
      "docker runner", "macos-10.15"
    ],
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "project_id": 1,
    "ref": "main",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/8",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.dev/root",
    "created_at": "2015-12-21T13:14:24.077Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": ""
  }
}
```

## Récupérer un fichier journal pour un job {#retrieve-a-log-file-for-a-job}

Récupère un job log (trace) pour un ID de job spécifié.

```plaintext
GET /projects/:id/jobs/:job_id/trace
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`  | entier        | Oui      | ID d'un job. |

```shell
curl --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/8/trace"
```

Codes de statut de réponse possibles :

| Statut | Description |
|--------|-------------|
| 200    | Fournit le fichier journal |
| 404    | Job introuvable ou aucun fichier journal |

## Annuler un job {#cancel-a-job}

Annule un seul job d'un projet.

```plaintext
POST /projects/:id/jobs/:job_id/cancel
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`  | entier        | Oui      | ID d'un job. |
| `force`   | boolean        | Non       | [Force l'annulation](../ci/jobs/_index.md#force-cancel-a-job) d'un job à l'état `canceling` lorsque défini sur `true`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/cancel"
```

Exemple de réponse :

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:14:09.526Z",
  "finished_at": null,
  "erased_at": null,
  "duration": 8,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "canceled",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

## Relancer un job {#retry-a-job}

{{< history >}}

- L'attribut `job_inputs` a été [introduit](https://gitlab.com/groups/gitlab-org/-/work_items/17833) dans GitLab 18.10.

{{< /history >}}

Relance un seul job d'un projet

```plaintext
POST /projects/:id/jobs/:job_id/retry
```

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`     | entier           | Oui      | ID d'un job. |
| `job_inputs` | hachage              | Non       | Un hachage de valeurs d'[entrée de job](../ci/jobs/job_inputs.md) à utiliser lors de la relance du job. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/retry"
```

Exemple de réponse :

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": null,
  "finished_at": null,
  "erased_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "pending",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

> [!note]
> Avant GitLab 17.0, cet endpoint ne prend pas en charge les jobs de déclenchement.

## Effacer un job {#erase-a-job}

Efface un seul job d'un projet (supprime les artefacts de job et un job log)

```plaintext
POST /projects/:id/jobs/:job_id/erase
```

Paramètres

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`  | entier        | Oui      | ID d'un job. |

Exemple de requête

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/erase"
```

Exemple de réponse :

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "download_url": null,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "erased_at": "2016-01-11T11:30:19.914Z",
  "duration": 97.0,
  "queued_duration": 0.010,
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

> [!note]
> Vous ne pouvez pas supprimer les jobs archivés avec l'API, mais vous pouvez [supprimer les artefacts de job et les journaux des jobs terminés avant une date spécifique](../administration/cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts)

## Exécuter un job {#run-a-job}

{{< history >}}

- L'attribut `job_inputs` a été [introduit](https://gitlab.com/groups/gitlab-org/-/work_items/17833) dans GitLab 18.10.

{{< /history >}}

Pour un job en statut manuel, déclenche une action pour démarrer le job.

```plaintext
POST /projects/:id/jobs/:job_id/play
```

| Attribut                  | Type              | Obligatoire | Description |
|----------------------------|-------------------|----------|-------------|
| `id`                       | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `job_id`                   | entier           | Oui      | ID d'un job. |
| `job_inputs`               | hachage              | Non       | Un hachage de valeurs d'[entrée de job](../ci/jobs/job_inputs.md) à utiliser lors de l'exécution du job. |
| `job_variables_attributes` | tableau de hachages   | Non       | Un tableau contenant les variables personnalisées disponibles pour le job. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data @variables.json \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/play"
```

`@variables.json` est structuré comme suit :

```json
{
  "job_variables_attributes": [
    {
      "key": "TEST_VAR_1",
      "value": "test1"
    },
    {
      "key": "TEST_VAR_2",
      "value": "test2"
    }
  ]
}
```

Exemple de réponse :

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": null,
  "finished_at": null,
  "erased_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "pending",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```
