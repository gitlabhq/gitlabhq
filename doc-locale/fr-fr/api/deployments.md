---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Déploiements
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Prise en charge de l'authentification par [jeton de job GitLab CI/CD](../ci/jobs/ci_job_token.md) [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/414549) dans GitLab 16.2.

{{< /history >}}

Utilisez cette API pour interagir avec les [déploiements de code](../ci/environments/deployments.md) vers les environnements GitLab.

## Lister tous les déploiements d'un projet {#list-all-project-deployments}

Liste tous les déploiements d'un projet.

```plaintext
GET /projects/:id/deployments
```

| Attribut         | Type           | Obligatoire | Description                                                                                                     |
|-------------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`              | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `order_by`        | string         | non       | Retourne les déploiements triés par l'un des champs `id`, `iid`, `created_at`, `updated_at`, `finished_at` ou `ref`. La valeur par défaut est `id`.    |
| `sort`            | string         | non       | Retourne les déploiements triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `asc`.                                            |
| `updated_after`   | datetime       | non       | Retourne les déploiements mis à jour après la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `updated_before`  | datetime       | non       | Retourne les déploiements mis à jour avant la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `finished_after`  | datetime       | non       | Retourne les déploiements terminés après la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `finished_before` | datetime       | non       | Retourne les déploiements terminés avant la date spécifiée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `environment`     | string         | non       | Le [nom de l'environnement](../ci/environments/_index.md) par lequel filtrer les déploiements.       |
| `status`          | string         | non       | Le statut par lequel filtrer les déploiements. L'un des suivants : `created`, `running`, `success`, `failed`, `canceled` ou `blocked`. |

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments"
```

> [!note]
> Lorsque vous utilisez `finished_before` ou `finished_after`, vous devez définir `order_by` sur `finished_at` et `status` doit être `success`.

Exemple de réponse :

```json
[
  {
    "created_at": "2016-08-11T07:36:40.222Z",
    "updated_at": "2016-08-11T07:38:12.414Z",
    "status": "created",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T09:36:01.000+02:00",
        "id": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "message": "Merge branch 'new-title' into 'main'\r\n\r\nUpdate README\r\n\r\n\r\n\r\nSee merge request !1",
        "short_id": "99d03678",
        "title": "Merge branch 'new-title' into 'main'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T07:36:27.357Z",
      "finished_at": "2016-08-11T07:36:39.851Z",
      "id": 657,
      "name": "deploy",
      "ref": "main",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
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
      "pipeline": {
        "created_at": "2016-08-11T02:12:10.222Z",
        "id": 36,
        "ref": "main",
        "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "status": "success",
        "updated_at": "2016-08-11T02:12:10.222Z",
        "web_url": "http://gitlab.dev/root/project/pipelines/12"
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 41,
    "iid": 1,
    "ref": "main",
    "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/root"
    }
  },
  {
    "created_at": "2016-08-11T11:32:35.444Z",
    "updated_at": "2016-08-11T11:34:01.123Z",
    "status": "created",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T13:28:26.000+02:00",
        "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "message": "Merge branch 'rename-readme' into 'main'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2",
        "short_id": "a91957a8",
        "title": "Merge branch 'rename-readme' into 'main'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T11:32:24.456Z",
      "finished_at": "2016-08-11T11:32:35.145Z",
      "id": 664,
      "name": "deploy",
      "ref": "main",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
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
      "pipeline": {
        "created_at": "2016-08-11T07:43:52.143Z",
        "id": 37,
        "ref": "main",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "status": "success",
        "updated_at": "2016-08-11T07:43:52.143Z",
        "web_url": "http://gitlab.dev/root/project/pipelines/13"
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 42,
    "iid": 2,
    "ref": "main",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/root"
    }
  }
]
```

## Récupérer un déploiement {#retrieve-a-deployment}

Récupère un seul déploiement.

```plaintext
GET /projects/:id/deployments/:deployment_id
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `deployment_id` | entier | oui      | L'ID du déploiement |

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1"
```

Exemple de réponse :

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "updated_at": "2016-08-11T11:34:01.123Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": {
    "id": 664,
    "status": "success",
    "stage": "deploy",
    "name": "deploy",
    "ref": "main",
    "tag": false,
    "coverage": null,
    "created_at": "2016-08-11T11:32:24.456Z",
    "started_at": null,
    "finished_at": "2016-08-11T11:32:35.145Z",
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
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    },
    "commit": {
      "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "short_id": "a91957a8",
      "title": "Merge branch 'rename-readme' into 'main'\r",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "created_at": "2016-08-11T13:28:26.000+02:00",
      "message": "Merge branch 'rename-readme' into 'main'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2"
    },
    "pipeline": {
      "created_at": "2016-08-11T07:43:52.143Z",
      "id": 42,
      "ref": "main",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "status": "success",
      "updated_at": "2016-08-11T07:43:52.143Z",
      "web_url": "http://gitlab.dev/root/project/pipelines/5"
    },
    "runner": null
  }
}
```

Lorsque des [règles d'approbation multiples](../ci/environments/deployment_approvals.md#add-multiple-approval-rules) sont configurées, les déploiements créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `approval_summary` :

```json
{
  "approval_summary": {
    "rules": [
      {
        "user_id": null,
        "group_id": 134,
        "access_level": null,
        "access_level_description": "qa-group",
        "required_approvals": 1,
        "deployment_approvals": []
      },
      {
        "user_id": null,
        "group_id": 135,
        "access_level": null,
        "access_level_description": "security-group",
        "required_approvals": 2,
        "deployment_approvals": [
          {
            "user": {
              "id": 100,
              "username": "security-user-1",
              "name": "security user-1",
              "state": "active",
              "avatar_url": "https://www.gravatar.com/avatar/e130fcd3a1681f41a3de69d10841afa9?s=80&d=identicon",
              "web_url": "http://localhost:3000/security-user-1"
            },
            "status": "approved",
            "created_at": "2022-04-11T03:37:03.058Z",
            "comment": null
          }
        ]
      }
    ]
  }
  ...
}
```

## Créer un déploiement {#create-a-deployment}

Crée un déploiement.

```plaintext
POST /projects/:id/deployments
```

| Attribut     | Type           | Obligatoire | Description                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).|
| `environment` | string         | oui      | Le [nom de l'environnement](../ci/environments/_index.md) pour lequel créer le déploiement.                        |
| `sha`         | string         | oui      | Le SHA du commit déployé.                                                                         |
| `ref`         | string         | oui      | Le nom de la branche ou du tag déployé.                                                                 |
| `tag`         | boolean        | oui      | Un booléen qui indique si la référence déployée est un tag (`true`) ou non (`false`).                                |
| `status`      | string         | oui      | Le statut du déploiement créé. L'un des suivants : `running`, `success`, `failed` ou `canceled`        |

```shell
curl --request "POST" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "environment=production&sha=a91957a858320c0e17f3a0eca7cfacbff50ea29a&ref=main&tag=false&status=success" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments"
```

Exemple de réponse :

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": null
}
```

Les déploiements créés par des utilisateurs sur GitLab Premium ou Ultimate incluent les propriétés `approvals` et `pending_approval_count` :

```json
{
  "status": "created",
  "pending_approval_count": 0,
  "approvals": [],
  ...
}
```

## Mettre à jour un déploiement {#update-a-deployment}

Met à jour un déploiement.

```plaintext
PUT /projects/:id/deployments/:deployment_id
```

| Attribut        | Type           | Obligatoire | Description         |
|------------------|----------------|----------|---------------------|
| `id`             | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `deployment_id`  | entier        | oui      | L'ID du déploiement à mettre à jour. |
| `status`         | string         | oui      | Le nouveau statut du déploiement. L'un des suivants : `running`, `success`, `failed` ou `canceled`.                         |

```shell
curl --request "PUT" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "status=success" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/42"
```

Exemple de réponse :

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": null
}
```

Les déploiements créés par des utilisateurs sur GitLab Premium ou Ultimate incluent les propriétés `approvals` et `pending_approval_count` :

```json
{
  "status": "created",
  "pending_approval_count": 0,
  "approvals": [
    {
      "user": {
        "id": 49,
        "username": "project_6_bot",
        "name": "****",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/e83ac685f68ea07553ad3054c738c709?s=80&d=identicon",
        "web_url": "http://localhost:3000/project_6_bot"
      },
      "status": "approved",
      "created_at": "2022-02-24T20:22:30.097Z",
      "comment": "Looks good to me"
    }
  ],
  ...
}
```

## Supprimer un déploiement {#delete-a-deployment}

Supprime un déploiement spécifié qui n'est pas actuellement le dernier déploiement pour un environnement ou qui se trouve dans un état `running`.

```plaintext
DELETE /projects/:id/deployments/:deployment_id
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `deployment_id` | entier | oui      | L'ID du déploiement |

```shell
curl --request "DELETE" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1"
```

Exemples de réponses :

```json
{ "message": "204 Deployment destroyed" }
```

```json
{ "message": "403 Forbidden" }
```

```json
{ "message": "400 Cannot destroy running deployment" }
```

```json
{ "message": "400 Deployment currently deployed to environment" }
```

## Lister toutes les merge requests associées à un déploiement {#list-all-merge-requests-associated-with-a-deployment}

> [!note]
> Tous les déploiements ne peuvent pas être associés à des merge requests. Consultez [Suivre les merge requests déployées dans un environnement](../ci/environments/deployments.md#track-newly-included-merge-requests-per-deployment) pour plus d'informations.

Liste toutes les merge requests livrées avec un déploiement donné.

```plaintext
GET /projects/:id/deployments/:deployment_id/merge_requests
```

Elle prend en charge les mêmes paramètres que l'[API des merge requests](merge_requests.md#list-merge-requests) et retourne une réponse au même format :

```shell
curl --request "GET" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/42/merge_requests"
```

## Approuver ou rejeter un déploiement {#approve-or-reject-a-deployment}

Approuve ou rejette un déploiement.

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/343864) dans GitLab 14.7 [avec un flag](../administration/feature_flags/_index.md) nommé `deployment_approvals`. Désactivé par défaut.
- [Flag de fonctionnalité supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/347342) dans GitLab 14.8.

{{< /history >}}

Consultez [Approbations de déploiement](../ci/environments/deployment_approvals.md) pour plus d'informations sur cette fonctionnalité.

```plaintext
POST /projects/:id/deployments/:deployment_id/approval
```

| Attribut       | Type           | Obligatoire | Description                                                                                                     |
|-----------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `deployment_id` | entier        | oui      | L'ID du déploiement.                                                                                       |
| `status`        | string         | oui      | Le statut de l'approbation (soit `approved` soit `rejected`).                                                   |
| `comment`       | string         | non       | Un commentaire accompagnant l'approbation                                                                               |
| `represented_as`| string         | non       | Le nom de l'utilisateur/groupe/rôle à utiliser pour l'approbation, lorsque l'utilisateur appartient à des [règles d'approbation multiples](../ci/environments/deployment_approvals.md#add-multiple-approval-rules). |

```shell
curl --request "POST" \
  --data "status=approved&comment=Looks good to me&represented_as=security" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deployments/1/approval"
```

Exemple de réponse :

```json
{
  "user": {
    "id": 100,
    "username": "security-user-1",
    "name": "security user-1",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e130fcd3a1681f41a3de69d10841afa9?s=80&d=identicon",
    "web_url": "http://localhost:3000/security-user-1"
  },
  "status": "approved",
  "created_at": "2022-02-24T20:22:30.097Z",
  "comment":"Looks good to me"
}
```
