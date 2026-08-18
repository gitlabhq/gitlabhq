---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des groupes de ressources
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [groupes de ressources](../ci/resource_groups/_index.md).

## Lister tous les groupes de ressources {#list-all-resource-groups}

Liste tous les groupes de ressources pour un projet spécifié.

```plaintext
GET /projects/:id/resource_groups
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id`      | entier ou chaîne de caractères     | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths) |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/resource_groups"
```

Exemple de réponse

```json
[
  {
    "id": 3,
    "key": "production",
    "process_mode": "unordered",
    "created_at": "2021-09-01T08:04:59.650Z",
    "updated_at": "2021-09-01T08:04:59.650Z"
  }
]
```

## Récupérer un groupe de ressources {#retrieve-a-resource-group}

Récupère un groupe de ressources spécifié pour un projet.

```plaintext
GET /projects/:id/resource_groups/:key
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id`      | entier ou chaîne de caractères     | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths) |
| `key`     | string  | oui      | La clé encodée dans l'URL du groupe de ressources. Par exemple, utilisez `resource%5Fa` à la place de `resource_a`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

Exemple de réponse

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "unordered",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:04:59.650Z"
}
```

## Récupérer le job actuel d'un groupe de ressources {#retrieve-current-job-for-a-resource-group}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/572135) dans GitLab 18.6.

{{< /history >}}

Récupère le job actuel pour un groupe de ressources spécifié dans un projet.

```plaintext
GET /projects/:id/resource_groups/:key/current_job
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id`      | entier ou chaîne de caractères     | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths) |
| `key`     | string  | oui      | La clé encodée dans l'URL du groupe de ressources. Par exemple, utilisez `resource%5Fa` à la place de `resource_a`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/50/resource_groups/production/current_job"
```

Exemple de réponse

```json
{
  "id": 1154,
  "status": "waiting_for_resource",
  "stage": "deploy",
  "name": "deploy_to_production",
  "ref": "main",
  "tag": false,
  "coverage": null,
  "allow_failure": false,
  "created_at": "2022-09-28T09:57:04.590Z",
  "started_at": null,
  "finished_at": null,
  "duration": null,
  "queued_duration": null,
  "user": {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/2d691a4d0427ca8db6efc3924a6408ba?s=80\u0026d=identicon",
    "web_url": "http://gitlab.example.com/john_smith",
    "created_at": "2022-05-27T19:19:17.526Z",
    "bio": "",
    "location": null,
    "public_email": null,
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null
  },
  "commit": {
    "id": "3177f39064891bbbf5124b27850c339da331f02f",
    "short_id": "3177f390",
    "created_at": "2022-09-27T17:55:31.000+02:00",
    "parent_ids": [
      "18059e45a16eaaeaddf6fc0daf061481549a89df"
    ],
    "title": "List upcoming jobs",
    "message": "List upcoming jobs",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2022-09-27T17:55:31.000+02:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2022-09-27T17:55:31.000+02:00",
    "trailers": {},
    "web_url": "https://gitlab.example.com/test/gitlab/-/commit/3177f39064891bbbf5124b27850c339da331f02f"
  },
  "pipeline": {
    "id": 274,
    "iid": 9,
    "project_id": 50,
    "sha": "3177f39064891bbbf5124b27850c339da331f02f",
    "ref": "main",
    "status": "waiting_for_resource",
    "source": "web",
    "created_at": "2022-09-28T09:57:04.538Z",
    "updated_at": "2022-09-28T09:57:13.537Z",
    "web_url": "https://gitlab.example.com/test/gitlab/-/pipelines/274"
  },
  "web_url": "https://gitlab.example.com/test/gitlab/-/jobs/1154",
  "project": {
    "ci_job_token_scope_enabled": false
  }
}
```

## Lister les prochains jobs pour un groupe de ressources spécifique {#list-upcoming-jobs-for-a-specific-resource-group}

```plaintext
GET /projects/:id/resource_groups/:key/upcoming_jobs
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id`      | entier ou chaîne de caractères     | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths) |
| `key`     | string  | oui      | La clé encodée dans l'URL du groupe de ressources. Par exemple, utilisez `resource%5Fa` à la place de `resource_a`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/50/resource_groups/production/upcoming_jobs"
```

Exemple de réponse

```json
[
  {
    "id": 1154,
    "status": "waiting_for_resource",
    "stage": "deploy",
    "name": "deploy_to_production",
    "ref": "main",
    "tag": false,
    "coverage": null,
    "allow_failure": false,
    "created_at": "2022-09-28T09:57:04.590Z",
    "started_at": null,
    "finished_at": null,
    "duration": null,
    "queued_duration": null,
    "user": {
      "id": 1,
      "username": "john_smith",
      "name": "John Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/2d691a4d0427ca8db6efc3924a6408ba?s=80\u0026d=identicon",
      "web_url": "http://gitlab.example.com/john_smith",
      "created_at": "2022-05-27T19:19:17.526Z",
      "bio": "",
      "location": null,
      "public_email": null,
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": null,
      "job_title": "",
      "pronouns": null,
      "bot": false,
      "work_information": null,
      "followers": 0,
      "following": 0,
      "local_time": null
    },
    "commit": {
      "id": "3177f39064891bbbf5124b27850c339da331f02f",
      "short_id": "3177f390",
      "created_at": "2022-09-27T17:55:31.000+02:00",
      "parent_ids": [
        "18059e45a16eaaeaddf6fc0daf061481549a89df"
      ],
      "title": "List upcoming jobs",
      "message": "List upcoming jobs",
      "author_name": "Example User",
      "author_email": "user@example.com",
      "authored_date": "2022-09-27T17:55:31.000+02:00",
      "committer_name": "Example User",
      "committer_email": "user@example.com",
      "committed_date": "2022-09-27T17:55:31.000+02:00",
      "trailers": {},
      "web_url": "https://gitlab.example.com/test/gitlab/-/commit/3177f39064891bbbf5124b27850c339da331f02f"
    },
    "pipeline": {
      "id": 274,
      "iid": 9,
      "project_id": 50,
      "sha": "3177f39064891bbbf5124b27850c339da331f02f",
      "ref": "main",
      "status": "waiting_for_resource",
      "source": "web",
      "created_at": "2022-09-28T09:57:04.538Z",
      "updated_at": "2022-09-28T09:57:13.537Z",
      "web_url": "https://gitlab.example.com/test/gitlab/-/pipelines/274"
    },
    "web_url": "https://gitlab.example.com/test/gitlab/-/jobs/1154",
    "project": {
      "ci_job_token_scope_enabled": false
    }
  }
]
```

## Mettre à jour un groupe de ressources {#update-a-resource-group}

Met à jour les propriétés d'un groupe de ressources existant.

Renvoie `200` si le groupe de ressources a été mis à jour avec succès. En cas d'erreur, un code de statut `400` est renvoyé.

```plaintext
PUT /projects/:id/resource_groups/:key
```

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `id`           | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths) |
| `key`          | string            | oui      | La clé encodée dans l'URL du groupe de ressources. Par exemple, utilisez `resource%5Fa` à la place de `resource_a`. |
| `process_mode` | string            | non       | Le mode de traitement du groupe de ressources. L'un des suivants : `unordered`, `oldest_first`, `newest_first` ou `newest_ready_first`. Consultez les [modes de traitement](../ci/resource_groups/_index.md#process-modes) pour plus d'informations. |

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "process_mode=oldest_first" \
     --url "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

Exemple de réponse :

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "oldest_first",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:13:38.679Z"
}
```
