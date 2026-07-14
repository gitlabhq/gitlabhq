---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Jetons de déclenchement de pipeline
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour [déclencher des pipelines](../ci/triggers/_index.md).

## Lister les jetons de déclenchement de projet {#list-project-trigger-tokens}

Liste les jetons de déclenchement de pipeline d'un projet.

```plaintext
GET /projects/:id/triggers
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
[
    {
        "id": 10,
        "description": "my trigger",
        "created_at": "2016-01-07T09:53:58.235Z",
        "last_used": null,
        "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
        "updated_at": "2016-01-07T09:53:58.235Z",
        "owner": null
    }
]
```

Le jeton de déclenchement est affiché en entier s'il a été créé par l'utilisateur authentifié. Les jetons de déclenchement créés par d'autres utilisateurs sont raccourcis à quatre caractères.

## Récupérer les détails d'un jeton de déclenchement {#retrieve-trigger-token-details}

Récupère les détails du jeton de déclenchement de pipeline d'un projet.

```plaintext
GET /projects/:id/triggers/:trigger_id
```

| Attribut    | Type           | Obligatoire | Description |
|--------------|----------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `trigger_id` | entier        | Oui      | L'ID du déclencheur |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Créer un jeton de déclenchement {#create-a-trigger-token}

Crée un jeton de déclenchement de pipeline pour un projet.

```plaintext
POST /projects/:id/triggers
```

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `description` | string         | Oui      | Le nom du déclencheur |
| `id`          | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form description="my description" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Mettre à jour un jeton de déclenchement de pipeline {#update-a-pipeline-trigger-token}

Met à jour le jeton de déclenchement de pipeline d'un projet.

```plaintext
PUT /projects/:id/triggers/:trigger_id
```

| Attribut     | Type           | Obligatoire | Description |
|---------------|----------------|----------|-------------|
| `id`          | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `trigger_id`  | entier        | Oui      | L'ID du déclencheur |
| `description` | string         | Non       | Le nom du déclencheur |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form description="my description" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/10"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Supprimer un jeton de déclenchement de pipeline {#delete-a-pipeline-trigger-token}

Supprime le jeton de déclenchement de pipeline d'un projet.

```plaintext
DELETE /projects/:id/triggers/:trigger_id
```

| Attribut    | Type           | Obligatoire | Description |
|--------------|----------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `trigger_id` | entier        | Oui      | L'ID du déclencheur |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

## Déclencher un pipeline avec un jeton {#trigger-a-pipeline-with-a-token}

{{< history >}}

- L'attribut `inputs` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/519958) dans GitLab 17.10 [avec un indicateur](../administration/feature_flags/_index.md) nommé `ci_inputs_for_pipelines`. Désactivé par défaut.
- L'attribut `inputs` [activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/525504) dans GitLab 17.11.
- L'attribut `inputs` [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/536548) dans GitLab 18.1. L'indicateur de fonctionnalité `ci_inputs_for_pipelines` a été supprimé.

{{< /history >}}

Déclenche un pipeline en utilisant un [jeton de déclenchement de pipeline](../ci/triggers/_index.md#create-a-pipeline-trigger-token) ou un [jeton de job CI/CD](../ci/jobs/ci_job_token.md) pour l'authentification.

Avec un jeton de job CI/CD, le [pipeline déclenché est un pipeline multi-projets](../ci/pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api). Le job qui authentifie la requête devient associé au pipeline upstream, qui est visible sur le graphe de pipeline.

Si vous utilisez un jeton de déclenchement dans un job, le job n'est pas associé au pipeline upstream.

```plaintext
POST /projects/:id/trigger/pipeline
```

Attributs pris en charge :

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `ref`       | string         | Oui      | La branche ou le tag sur lequel exécuter le pipeline. |
| `token`     | string         | Oui      | Le jeton de déclenchement ou le jeton de job CI/CD. |
| `variables` | hash           | Non       | Une correspondance de chaînes clé-valeur contenant les variables du pipeline. Par exemple : `{ VAR1: "value1", VAR2: "value2" }`. |
| `inputs`    | hash           | Non       | Une correspondance d'entrées, sous forme de paires clé-valeur, à utiliser lors de la création du pipeline. |

Exemple de requête avec des [variables](../ci/variables/_index.md) :

```shell
curl --request POST \
  --form "variables[VAR1]=value1" \
  --form "variables[VAR2]=value2" \
  --url "https://gitlab.example.com/api/v4/projects/123/trigger/pipeline?token=2cb1840fb9dfc9fb0b7b1609cd29cb&ref=main"
```

Exemple de requête avec des [entrées](../ci/inputs/_index.md) :

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --data '{"inputs": {"environment": "environment", "scan_security": false, "level": 3}}' \
  --url "https://gitlab.example.com/api/v4/projects/123/trigger/pipeline?token=2cb1840fb9dfc9fb0b7b1609cd29cb&ref=main"
```

Exemple de réponse :

```json
{
  "id": 257,
  "iid": 118,
  "project_id": 123,
  "sha": "91e2711a93e5d9e8dddfeb6d003b636b25bf6fc9",
  "ref": "main",
  "status": "created",
  "source": "trigger",
  "created_at": "2022-03-31T01:12:49.068Z",
  "updated_at": "2022-03-31T01:12:49.068Z",
  "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/257",
  "before_sha": "0000000000000000000000000000000000000000",
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
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": null,
  "coverage": null,
  "detailed_status": {
    "icon": "status_created",
    "text": "created",
    "label": "created",
    "group": "created",
    "tooltip": "created",
    "has_details": true,
    "details_path": "/test-group/test-project/-/pipelines/257",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_created-4b975aa976d24e5a3ea7cd9a5713e6ce2cd9afd08b910415e96675de35f64955.png"
  },
  "archived": false
}
```
