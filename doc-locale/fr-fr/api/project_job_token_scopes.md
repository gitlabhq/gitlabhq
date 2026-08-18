---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de portée du jeton de job CI/CD
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les portées du [jeton de job CI/CD](../ci/jobs/ci_job_token.md).

> [!note]
> Toutes les requêtes vers le point de terminaison de l'API de portée du jeton de job CI/CD doivent être [authentifiées](rest/authentication.md). L'utilisateur authentifié doit avoir le rôle Maintainer ou Owner pour le projet.

## Récupérer les paramètres d'accès au jeton de job CI/CD pour un projet {#retrieve-the-cicd-job-token-access-settings-for-a-project}

Récupère les [paramètres d'accès au jeton de job CI/CD](../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project) (portée du jeton de job) d'un projet spécifié.

```plaintext
GET /projects/:id/job_token_scope
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut          | Type    | Description |
|--------------------|---------|-------------|
| `inbound_enabled`  | boolean | Indique si le paramètre [**Groupes et projets autorisés**](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) est activé pour la liste d'autorisation. Si désactivé, alors [tous les projets ont accès](../ci/jobs/ci_job_token.md#allow-any-project-to-access-your-project). Cette valeur indique si la liste d'autorisation est actuellement active, ce qui peut être `true` en raison du paramètre d'instance [**Enforce job token allowlist**](../administration/settings/continuous_integration.md#enforce-job-token-allowlist). |
| `outbound_enabled` | boolean | Indique si le jeton de job CI/CD généré dans ce projet a accès à d'autres projets. [Déprécié et dont la suppression est prévue dans GitLab 18.0](../update/deprecations.md#cicd-job-token---limit-access-from-your-project-setting-removal). |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope"
```

Exemple de réponse :

```json
{
  "inbound_enabled": true,
  "outbound_enabled": false
}
```

## Mettre à jour les paramètres d'accès au jeton de job CI/CD pour un projet {#update-the-cicd-job-token-access-settings-for-a-project}

{{< history >}}

- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/issues/411406) de **Allow access to this project with a CI_JOB_TOKEN** en **Limit access to this project** dans GitLab 16.3.
- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/issues/415519) de **Limit access to this project** en **Groupes et projets autorisés** dans GitLab 17.2.

{{< /history >}}

Met à jour le [paramètre **Groupes et projets autorisés**](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) (portée du jeton de job) d'un projet spécifié.

```plaintext
PATCH /projects/:id/job_token_scope
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `enabled` | boolean           | Oui      | Restreint l'accès au jeton de job aux seuls projets figurant dans la liste d'autorisation. Définissez sur `false` pour autoriser l'accès depuis tous les projets. Ce paramètre peut être remplacé par le paramètre d'instance [**Enforce job token allowlist**](../administration/settings/continuous_integration.md#enforce-job-token-allowlist). |

En cas de succès, renvoie [`204`](rest/troubleshooting.md#status-codes) et aucun corps de réponse.

Si le paramètre d'instance **Enforce job token allowlist** est activé et que vous tentez de définir `enabled` sur `false`, renvoie [`400`](rest/troubleshooting.md#status-codes) avec un message d'erreur.

Exemple de requête :

```shell
curl --request PATCH \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "enabled": false }'
```

## Répertorier tous les projets dans une liste d'autorisation de jeton de job CI/CD {#list-all-projects-in-a-cicd-job-token-allowlist}

Répertorie tous les projets dans la [liste d'autorisation de jeton de job CI/CD](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) d'un projet spécifié.

```plaintext
GET /projects/:id/job_token_scope/allowlist
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Ce point de terminaison prend en charge la [pagination basée sur les décalages](rest/_index.md#offset-based-pagination).

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et une liste de projets avec des champs limités pour chaque projet.

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist"
```

Exemple de réponse :

```json
[
  {
    "id": 4,
    "description": null,
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "star_count": 0,
    "last_activity_at": "2013-09-30T13:46:02Z",
    "namespace": {
      "id": 2,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/diaspora"
    }
  },
  {
    ...
  }
```

## Ajouter un projet à une liste d'autorisation de jeton de job CI/CD {#add-a-project-to-a-cicd-job-token-allowlist}

Ajoute un projet à la [liste d'autorisation de jeton de job CI/CD](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) d'un projet spécifié.

```plaintext
POST /projects/:id/job_token_scope/allowlist
```

Attributs pris en charge :

| Attribut           | Type           | Obligatoire | Description |
|---------------------|----------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `target_project_id` | entier        | Oui      | L'ID du projet ajouté à la liste d'autorisation entrante de jeton de job CI/CD. |

En cas de succès, renvoie [`201`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `source_project_id` | entier | ID du projet contenant la liste d'autorisation entrante de jeton de job CI/CD à mettre à jour. |
| `target_project_id` | entier | ID du projet ajouté à la liste d'autorisation entrante du projet source. |

Exemple de requête :

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "target_project_id": 2 }'
```

Exemple de réponse :

```json
{
  "source_project_id": 1,
  "target_project_id": 2
}
```

## Supprimer un projet d'une liste d'autorisation de jeton de job CI/CD {#delete-a-project-from-a-cicd-job-token-allowlist}

Supprime un projet de la [liste d'autorisation de jeton de job CI/CD](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) d'un projet spécifié.

```plaintext
DELETE /projects/:id/job_token_scope/allowlist/:target_project_id
```

Attributs pris en charge :

| Attribut           | Type           | Obligatoire | Description |
|---------------------|----------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `target_project_id` | entier        | Oui      | L'ID du projet supprimé de la liste d'autorisation entrante de jeton de job CI/CD. |

En cas de succès, renvoie [`204`](rest/troubleshooting.md#status-codes) et aucun corps de réponse.

Exemple de requête :

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```

## Répertorier tous les groupes dans une liste d'autorisation de jeton de job CI/CD {#list-all-groups-in-a-cicd-job-token-allowlist}

Répertorie tous les groupes dans la [liste d'autorisation de jeton de job CI/CD](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) d'un projet spécifié.

```plaintext
GET /projects/:id/job_token_scope/groups_allowlist
```

Attributs pris en charge :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Ce point de terminaison prend en charge la [pagination basée sur les décalages](rest/_index.md#offset-based-pagination).

En cas de succès, renvoie [`200`](rest/troubleshooting.md#status-codes) et une liste de groupes avec des champs limités pour chaque projet.

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist"
```

Exemple de réponse :

```json
[
  {
    "id": 4,
    "web_url": "https://gitlab.example.com/groups/diaspora/diaspora-group",
    "name": "namegroup"
  },
  {
    ...
  }
]
```

## Ajouter un groupe à une liste d'autorisation de jeton de job CI/CD {#add-a-group-to-a-cicd-job-token-allowlist}

Ajoute un groupe à la [liste d'autorisation de jeton de job CI/CD](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) d'un projet spécifié.

```plaintext
POST /projects/:id/job_token_scope/groups_allowlist
```

Attributs pris en charge :

| Attribut         | Type           | Obligatoire | Description |
|-------------------|----------------|----------|-------------|
| `id`              | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `target_group_id` | entier        | Oui      | L'ID du groupe ajouté à la liste d'autorisation des groupes de jeton de job CI/CD. |

En cas de succès, renvoie [`201`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type    | Description |
|---------------------|---------|-------------|
| `source_project_id` | entier | ID du projet contenant la liste d'autorisation entrante de jeton de job CI/CD à mettre à jour. |
| `target_group_id`   | entier | ID du groupe ajouté à la liste d'autorisation des groupes du projet source. |

Exemple de requête :

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "target_group_id": 2 }'
```

Exemple de réponse :

```json
{
  "source_project_id": 1,
  "target_group_id": 2
}
```

## Supprimer un groupe d'une liste d'autorisation de jeton de job CI/CD {#delete-a-group-from-a-cicd-job-token-allowlist}

Supprime un groupe de la [liste d'autorisation de jeton de job CI/CD](../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) d'un projet spécifié.

```plaintext
DELETE /projects/:id/job_token_scope/groups_allowlist/:target_group_id
```

Attributs pris en charge :

| Attribut         | Type           | Obligatoire | Description |
|-------------------|----------------|----------|-------------|
| `id`              | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `target_group_id` | entier        | Oui      | L'ID du groupe supprimé de la liste d'autorisation des groupes de jeton de job CI/CD. |

En cas de succès, renvoie [`204`](rest/troubleshooting.md#status-codes) et aucun corps de réponse.

Exemple de requête :

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/1/job_token_scope/groups_allowlist/2" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json'
```
