---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Points de terminaison d'API pour la gestion des environnements GitLab, notamment la liste, la création, la mise à jour, l'arrêt et la suppression des environnements."
title: API Environnements
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Paramètre `auto_stop_setting` [ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/428625) dans GitLab 17.8.
- Prise en charge de l'authentification par [jeton de job GitLab CI/CD](../ci/jobs/ci_job_token.md) [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/414549) dans GitLab 16.2.

{{< /history >}}

Utilisez cette API pour interagir avec les [environnements GitLab](../ci/environments/_index.md).

## Lister tous les environnements {#list-all-environments}

Liste tous les environnements d'un projet spécifié.

```plaintext
GET /projects/:id/environments
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le chemin [encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `name`    | string         | non       | Retourne l'environnement portant ce nom. Mutuellement exclusif avec `search`. |
| `search`  | string         | non       | Retourne la liste des environnements correspondant aux critères de recherche. Mutuellement exclusif avec `name`. Doit contenir au moins 3 caractères. |
| `states`  | string         | non       | Liste tous les environnements correspondant à un état spécifique. Valeurs acceptées : `available`, `stopping` ou `stopped`. Si aucune valeur d'état n'est fournie, retourne tous les environnements. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments?name=review%2Ffix-foo"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "review/fix-foo",
    "slug": "review-fix-foo-dfjre3",
    "description": "This is review environment",
    "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
    "state": "available",
    "tier": "development",
    "created_at": "2019-05-25T18:55:13.252Z",
    "updated_at": "2019-05-27T18:55:13.252Z",
    "enable_advanced_logs_querying": false,
    "logs_api_path": "/project/-/logs/k8s.json?environment_name=review%2Ffix-foo",
    "auto_stop_at": "2019-06-03T18:55:13.252Z",
    "kubernetes_namespace": "flux-system",
    "flux_resource_path": "HelmRelease/flux-system",
    "auto_stop_setting": "always"
  }
]
```

## Récupérer un environnement {#retrieve-an-environment}

Récupère un environnement spécifié pour un projet.

```plaintext
GET /projects/:id/environments/:environment_id
```

| Attribut        | Type           | Obligatoire | Description |
|------------------|----------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `environment_id` | entier        | oui      | L'ID de l'environnement. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

Exemple de réponse

```json
{
  "id": 1,
  "name": "review/fix-foo",
  "slug": "review-fix-foo-dfjre3",
  "description": "This is review environment",
  "external_url": "https://review-fix-foo-dfjre3.gitlab.example.com",
  "state": "available",
  "tier": "development",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "enable_advanced_logs_querying": false,
  "logs_api_path": "/project/-/logs/k8s.json?environment_name=review%2Ffix-foo",
  "auto_stop_at": "2019-06-03T18:55:13.252Z",
  "last_deployment": {
    "id": 100,
    "iid": 34,
    "ref": "fdroid",
    "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
    "created_at": "2019-03-25T18:55:13.252Z",
    "status": "success",
    "user": {
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "deployable": {
      "id": 710,
      "status": "success",
      "stage": "deploy",
      "name": "staging",
      "ref": "fdroid",
      "tag": false,
      "coverage": null,
      "created_at": "2019-03-25T18:55:13.215Z",
      "started_at": "2019-03-25T12:54:50.082Z",
      "finished_at": "2019-03-25T18:55:13.216Z",
      "duration": 21623.13423,
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
        "organization": null
      },
      "commit": {
        "id": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "short_id": "416d8ea1",
        "created_at": "2016-01-02T15:39:18.000Z",
        "parent_ids": [
          "e9a4449c95c64358840902508fc827f1a2eab7df"
        ],
        "title": "Removed fabric to fix #40",
        "message": "Removed fabric to fix #40\n",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "authored_date": "2016-01-02T15:39:18.000Z",
        "committer_name": "Administrator",
        "committer_email": "admin@example.com",
        "committed_date": "2016-01-02T15:39:18.000Z"
      },
      "pipeline": {
        "id": 34,
        "sha": "416d8ea11849050d3d1f5104cf8cf51053e790ab",
        "ref": "fdroid",
        "status": "success",
        "web_url": "http://localhost:3000/Commit451/lab-coat/pipelines/34"
      },
      "web_url": "http://localhost:3000/Commit451/lab-coat/-/jobs/710",
      "artifacts": [
        {
          "file_type": "trace",
          "size": 1305,
          "filename": "job.log",
          "file_format": null
        }
      ],
      "runner": null,
      "artifacts_expire_at": null
    }
  },
  "cluster_agent": {
    "id": 1,
    "name": "agent-1",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  },
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## Créer un environnement {#create-an-environment}

Crée un environnement pour un projet spécifié.

```plaintext
POST /projects/:id/environments
```

| Attribut              | Type           | Obligatoire | Description |
|------------------------|----------------|----------|-------------|
| `id`                   | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `name`                 | string         | oui      | Le nom de l'environnement. |
| `description`          | string         | non       | La description de l'environnement. |
| `external_url`         | string         | non       | Lien vers lequel pointer pour cet environnement. |
| `tier`                 | string         | non       | Le niveau du nouvel environnement. Les valeurs autorisées sont `production`, `staging`, `testing`, `development` et `other`. |
| `cluster_agent_id`     | entier        | non       | L'agent de cluster à associer à cet environnement. |
| `kubernetes_namespace` | string         | non       | L'espace de nommage Kubernetes à associer à cet environnement. |
| `flux_resource_path`   | string         | non       | Le chemin de ressource Flux à associer à cet environnement. Il doit s'agir du chemin de ressource complet. Par exemple, `helm.toolkit.fluxcd.io/v2/namespaces/gitlab-agent/helmreleases/gitlab-agent`. |
| `auto_stop_setting`    | string         | non       | Le paramètre d'arrêt automatique de l'environnement. Les valeurs autorisées sont `always` ou `with_action`. |

En cas de succès, retourne `201` ; retourne `400` pour des paramètres incorrects.

```shell
curl --data "name=deploy&external_url=https://deploy.gitlab.example.com" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "description": null,
  "external_url": "https://deploy.gitlab.example.com",
  "state": "available",
  "tier": "production",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## Mettre à jour un environnement existant {#update-an-existing-environment}

{{< history >}}

- Paramètre `name` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/338897) dans GitLab 16.0.

{{< /history >}}

Met à jour un environnement existant pour un projet.

```plaintext
PUT /projects/:id/environments/:environments_id
```

| Attribut              | Type            | Obligatoire | Description |
|------------------------|-----------------|----------|-------------|
| `id`                   | entier ou chaîne  | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `environment_id`       | entier         | oui      | L'ID de l'environnement. |
| `description`          | string          | non       | La description de l'environnement. |
| `external_url`         | string          | non       | Le nouveau `external_url`. |
| `tier`                 | string          | non       | Le niveau du nouvel environnement. Les valeurs autorisées sont `production`, `staging`, `testing`, `development` et `other`. |
| `cluster_agent_id`     | entier ou null | non       | L'agent de cluster à associer à cet environnement ou `null` pour le supprimer. |
| `kubernetes_namespace` | chaîne ou null  | non       | L'espace de nommage Kubernetes à associer à cet environnement ou `null` pour le supprimer. |
| `flux_resource_path`   | chaîne ou null  | non       | Le chemin de ressource Flux à associer à cet environnement ou `null` pour le supprimer. |
| `auto_stop_setting`    | chaîne ou null  | non       | Le paramètre d'arrêt automatique de l'environnement. Les valeurs autorisées sont `always` ou `with_action`. |

En cas de succès, retourne `200`. En cas d'erreur, retourne `400`.

```shell
curl --request PUT \
  --data "external_url=https://staging.gitlab.example.com" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "staging",
  "slug": "staging",
  "description": null,
  "external_url": "https://staging.gitlab.example.com",
  "state": "available",
  "tier": "staging",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## Supprimer un environnement {#delete-an-environment}

Supprime un environnement d'un projet. L'environnement doit d'abord être arrêté.

```plaintext
DELETE /projects/:id/environments/:environment_id
```

| Attribut        | Type           | Obligatoire | Description |
|------------------|----------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `environment_id` | entier        | oui      | L'ID de l'environnement. |

En cas de succès, retourne `204`. Retourne `404` si l'environnement n'existe pas. Retourne `403` si l'environnement n'est pas arrêté.

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1"
```

## Supprimer plusieurs environnements éphémères arrêtés {#delete-multiple-stopped-review-apps}

Planifie la suppression de plusieurs environnements qui ont déjà été [arrêtés](../ci/environments/_index.md#stopping-an-environment) et qui se trouvent [dans le dossier des environnements éphémères](../ci/review_apps/_index.md). La suppression effective est effectuée 1 semaine après l'heure d'exécution. Par défaut, seuls les environnements âgés de 30 jours ou plus sont supprimés.

```plaintext
DELETE /projects/:id/environments/review_apps
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `before`  | datetime       | non       | La date avant laquelle les environnements peuvent être supprimés. Par défaut, il y a 30 jours. Attendu au format ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `limit`   | entier        | non       | Nombre maximum d'environnements à supprimer. Par défaut : 100. |
| `dry_run` | boolean        | non       | Par défaut `true` pour des raisons de sécurité. Effectue une simulation où aucune suppression réelle n'est réalisée. Définissez la valeur sur `false` pour supprimer réellement l'environnement. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/review_apps"
```

Exemple de réponse :

```json
{
  "scheduled_entries": [
    {
      "id": 387,
      "name": "review/023f1bce01229c686a73",
      "slug": "review-023f1bce01-3uxznk",
      "external_url": null
    },
    {
      "id": 388,
      "name": "review/85d4c26a388348d3c4c0",
      "slug": "review-85d4c26a38-5giw1c",
      "external_url": null
    }
  ],
  "unprocessable_entries": []
}
```

## Arrêter un environnement {#stop-an-environment}

Arrête un environnement en cours d'exécution.

```plaintext
POST /projects/:id/environments/:environment_id/stop
```

| Attribut        | Type           | Obligatoire | Description |
|------------------|----------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `environment_id` | entier        | oui      | L'ID de l'environnement. |
| `force`          | boolean        | non       | Force l'arrêt de l'environnement sans exécuter les actions `on_stop`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/1/stop"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "deploy",
  "slug": "deploy",
  "external_url": "https://deploy.gitlab.example.com",
  "state": "stopped",
  "created_at": "2019-05-25T18:55:13.252Z",
  "updated_at": "2019-05-27T18:55:13.252Z",
  "kubernetes_namespace": "flux-system",
  "flux_resource_path": "HelmRelease/flux-system",
  "auto_stop_setting": "always"
}
```

## Arrêter les environnements obsolètes {#stop-stale-environments}

Arrête tous les environnements qui ont été modifiés ou déployés pour la dernière fois avant une date spécifiée. Exclut les environnements protégés.

```plaintext
POST /projects/:id/environments/stop_stale
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `before`  | date           | oui      | Arrête les environnements qui ont été modifiés ou déployés avant la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). Les valeurs valides sont comprises entre il y a 10 ans et il y a 1 semaine |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/environments/stop_stale?before=10%2F10%2F2021"
```

Exemple de réponse :

```json
{
  "message": "Successfully requested stop for all stale environments"
}
```
