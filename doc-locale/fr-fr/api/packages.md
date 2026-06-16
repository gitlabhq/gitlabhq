---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Paquets
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/349418) de la prise en charge de l'authentification par [jeton de job CI/CD GitLab](../ci/jobs/ci_job_token.md) pour l'API au niveau du projet dans GitLab 15.3.

{{< /history >}}

Utilisez cette API pour interagir avec les [GitLab Packages](../administration/packages/_index.md).

## Lister les packages {#list-packages}

{{< history >}}

- `pipelines` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/341950) dans GitLab 16.1.

{{< /history >}}

### Pour un projet {#for-a-project}

Répertorie tous les packages d'un projet spécifié. Tous les types de packages sont inclus dans les résultats. Lorsque l'accès est effectué sans authentification, seuls les packages des projets publics sont renvoyés. Par défaut, les packages avec le statut `default`, `deprecated` et `error` sont renvoyés. Utilisez le paramètre `status` pour afficher d'autres packages.

```plaintext
GET /projects/:id/packages
```

| Attribut             | Type           | Obligatoire | Description |
|:----------------------|:---------------|:---------|:------------|
| `id`                  | entier ou chaîne | oui      | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths). |
| `order_by`            | string         | non       | Le champ à utiliser comme ordre. L'un des suivants : `created_at` (par défaut), `name`, `version` ou `type`. |
| `sort`                | string         | non       | Le sens de l'ordre, soit `asc` (par défaut) pour l'ordre croissant, soit `desc` pour l'ordre décroissant. |
| `package_type`        | string         | non       | Filtrer les packages renvoyés par type. L'un des suivants : `composer`, `conan`, `generic`, `golang`, `helm`, `maven`, `npm`, `nuget`, `pypi` ou `terraform_module`. |
| `package_name`        | string         | non       | Filtrer les packages du projet avec une recherche approximative par nom. |
| `package_version`     | string         | non       | Filtrer les packages du projet par version. Si utilisé en combinaison avec `include_versionless`, aucun package sans version n'est renvoyé. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/349065) dans GitLab 16.6. |
| `include_versionless` | boolean        | non       | Lorsque défini sur true, les packages sans version sont inclus dans la réponse. |
| `status`              | string         | non       | Filtrer les packages renvoyés par statut. L'un des suivants : `default`, `hidden`, `processing`, `error`, `pending_destruction` ou `deprecated`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven",
    "created_at": "2019-11-27T03:37:38.711Z",
    "creator_id": 1,
    "pipeline": {
      "id": 123,
      "status": "pending",
      "ref": "new-pipeline",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "web_url": "https://example.com/foo/bar/pipelines/47",
      "created_at": "2016-08-11T11:28:34.085Z",
      "updated_at": "2016-08-11T11:32:35.169Z",
      "user": {
        "name": "Administrator",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
      }
    },
    "pipelines": [],
    "tags": []
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm",
    "created_at": "2019-11-27T03:37:38.711Z",
    "tags": []
  }
]
```

Par défaut, la requête `GET` renvoie 20 résultats, car l'API est [paginée](rest/_index.md#pagination).

Bien que vous puissiez filtrer les packages par statut, l'utilisation de packages ayant le statut `processing` peut entraîner des données malformées ou des packages corrompus.

### Pour un groupe {#for-a-group}

Prérequis :

- Le rôle Reporter, Responsable sécurité, Developer, Maintainer ou Owner sur au moins un projet dans la hiérarchie du groupe.

Répertorie tous les packages d'un groupe spécifié. Lorsque l'accès est effectué sans authentification, seuls les packages des projets publics sont renvoyés. Par défaut, les packages avec le statut `default`, `deprecated` et `error` sont renvoyés. Utilisez le paramètre `status` pour afficher d'autres packages.

Ce modèle de permissions correspond au champ GraphQL `Group.packages`, de sorte que les endpoints REST et GraphQL renvoient les mêmes packages pour le même appelant.

```plaintext
GET /groups/:id/packages
```

| Attribut             | Type           | Obligatoire | Description |
|:----------------------|:---------------|:---------|:------------|
| `id`                  | entier ou chaîne | oui      | ID ou [chemin encodé par URL](rest/_index.md#namespaced-paths) du groupe. |
| `exclude_subgroups`   | boolean        | non       | Si le paramètre est inclus avec la valeur true, les packages des projets des sous-groupes ne sont pas listés. La valeur par défaut est `false`. |
| `order_by`            | string         | non       | Le champ à utiliser comme ordre. L'un des suivants : `created_at` (par défaut), `name`, `version`, `type` ou `project_path`. |
| `sort`                | string         | non       | Le sens de l'ordre, soit `asc` (par défaut) pour l'ordre croissant, soit `desc` pour l'ordre décroissant. |
| `package_type`        | string         | non       | Filtrer les packages renvoyés par type. L'un des suivants : `composer`, `conan`, `generic`, `golang`, `helm`, `maven`, `npm`, `nuget`, `pypi` ou `terraform_module`. |
| `package_name`        | string         | non       | Filtrer les packages du projet avec une recherche approximative par nom. |
| `package_version`     | string         | non       | Filtrer les packages renvoyés par version. Si utilisé en combinaison avec `include_versionless`, aucun package sans version n'est renvoyé. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/349065) dans GitLab 16.6. |
| `include_versionless` | boolean        | non       | Lorsque défini sur true, les packages sans version sont inclus dans la réponse. |
| `status`              | string         | non       | Filtrer les packages renvoyés par statut. L'un des suivants : `default`, `hidden`, `processing`, `error`, `pending_destruction` ou `deprecated`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/packages?exclude_subgroups=false"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven",
    "_links": {
      "web_path": "/namespace1/project1/-/packages/1",
      "delete_api_path": "/namespace1/project1/-/packages/1"
    },
    "created_at": "2019-11-27T03:37:38.711Z",
    "creator_id": 1,
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm",
    "_links": {
      "web_path": "/namespace1/project1/-/packages/1",
      "delete_api_path": "/namespace1/project1/-/packages/1"
    },
    "created_at": "2019-11-27T03:37:38.711Z",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  }
]
```

Par défaut, la requête `GET` renvoie 20 résultats, car l'API est [paginée](rest/_index.md#pagination).

Le champ `creator_id` contient l'ID de l'utilisateur qui a créé le package. Ce champ est `null` lorsque le package a été créé par un jeton de déploiement ou un jeton de job.

L'objet `_links` contient les propriétés suivantes :

- `web_path` : Le chemin que vous pouvez consulter dans GitLab pour voir les détails du package.
- `delete_api_path` : Le chemin d'API pour supprimer le package. Disponible uniquement si l'utilisateur qui effectue la demande dispose de la permission nécessaire.

Bien que vous puissiez filtrer les packages par statut, l'utilisation de packages ayant le statut `processing` peut entraîner des données malformées ou des packages corrompus.

## Récupérer un package de projet {#retrieve-a-project-package}

{{< history >}}

- `pipelines` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/341950) dans GitLab 16.1.

{{< /history >}}

Récupère un package de projet spécifié. Seuls les packages avec le statut `default` ou `deprecated` sont renvoyés.

```plaintext
GET /projects/:id/packages/:package_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths). |
| `package_id`      | entier | oui | ID d'un package. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "com/mycompany/my-app",
  "version": "1.0-SNAPSHOT",
  "package_type": "maven",
  "_links": {
    "web_path": "/namespace1/project1/-/packages/1",
    "delete_api_path": "/namespace1/project1/-/packages/1"
  },
  "created_at": "2019-11-27T03:37:38.711Z",
  "last_downloaded_at": "2022-09-07T07:51:50.504Z",
  "creator_id": 1,
  "pipelines": [
    {
      "id": 123,
      "status": "pending",
      "ref": "new-pipeline",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "web_url": "https://example.com/foo/bar/pipelines/47",
      "created_at": "2016-08-11T11:28:34.085Z",
      "updated_at": "2016-08-11T11:32:35.169Z",
      "user": {
        "name": "Administrator",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
      }
    }
  ],
  "versions": [
    {
      "id":2,
      "version":"2.0-SNAPSHOT",
      "created_at":"2020-04-28T04:42:11.573Z",
      "pipelines": [
        {
          "id": 234,
          "status": "pending",
          "ref": "new-pipeline",
          "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
          "web_url": "https://example.com/foo/bar/pipelines/58",
          "created_at": "2016-08-11T11:28:34.085Z",
          "updated_at": "2016-08-11T11:32:35.169Z",
          "user": {
            "name": "Administrator",
            "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
          }
        }
      ]
    }
  ]
}
```

Le champ `creator_id` contient l'ID de l'utilisateur qui a créé le package. Ce champ est `null` lorsque le package a été créé par un jeton de déploiement ou un jeton de job.

L'objet `_links` contient les propriétés suivantes :

- `web_path` : Le chemin que vous pouvez consulter dans GitLab pour voir les détails du package. Disponible uniquement si le package a le statut `default` ou `deprecated`.
- `delete_api_path` : Le chemin d'API pour supprimer le package. Disponible uniquement si l'utilisateur qui effectue la demande dispose de la permission nécessaire.

## Lister les fichiers de package {#list-package-files}

Répertorie tous les fichiers de package pour un package spécifié.

```plaintext
GET /projects/:id/packages/:package_id/package_files
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths) |
| `package_id`      | entier | oui | ID d'un package. |
| `order_by`            | string         | non       | Le champ à utiliser comme ordre. L'un des suivants : `id` (par défaut), `file_name`, `created_at`. |
| `sort`                | string         | non       | Le sens de l'ordre, soit `asc` (par défaut) pour l'ordre croissant, soit `desc` pour l'ordre décroissant. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files"
```

Exemple de réponse :

```json
[
  {
    "id": 25,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:52.199Z",
    "file_name": "my-app-1.5-20181107.152550-1.jar",
    "size": 2421,
    "file_md5": "58e6a45a629910c6ff99145a688971ac",
    "file_sha1": "ebd193463d3915d7e22219f52740056dfd26cbfe",
    "file_sha256": "a903393463d3915d7e22219f52740056dfd26cbfeff321b",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  },
  {
    "id": 26,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:56.776Z",
    "file_name": "my-app-1.5-20181107.152550-1.pom",
    "size": 1122,
    "file_md5": "d90f11d851e17c5513586b4a7e98f1b2",
    "file_sha1": "9608d068fe88aff85781811a42f32d97feb440b5",
    "file_sha256": "2987d068fe88aff85781811a42f32d97feb4f092a399"
  },
  {
    "id": 27,
    "package_id": 4,
    "created_at": "2018-11-07T15:26:00.556Z",
    "file_name": "maven-metadata.xml",
    "size": 767,
    "file_md5": "6dfd0cce1203145a927fef5e3a1c650c",
    "file_sha1": "d25932de56052d320a8ac156f745ece73f6a8cd2",
    "file_sha256": "ac849d002e56052d320a8ac156f745ece73f6a8cd2f3e82"
  }
]
```

Par défaut, la requête `GET` renvoie 20 résultats, car l'API est [paginée](rest/_index.md#pagination).

## Lister les pipelines de package {#list-package-pipelines}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/341950) dans GitLab 16.1.

{{< /history >}}

Répertorie tous les pipelines d'un package spécifié. Les résultats sont triés par `id` dans l'ordre décroissant.

Les résultats sont [paginés](rest/_index.md#keyset-based-pagination) et renvoient jusqu'à 20 enregistrements par page.

```plaintext
GET /projects/:id/packages/:package_id/pipelines
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths) |
| `package_id`      | entier | oui | ID d'un package. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/pipelines"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 9,
    "sha": "2b6127f6bb6f475c4e81afcc2251e3f941e554f9",
    "ref": "mytag",
    "status": "failed",
    "source": "push",
    "created_at": "2023-02-01T12:19:21.895Z",
    "updated_at": "2023-02-01T14:00:05.922Z",
    "web_url": "http://gdk.test:3001/feature-testing/composer-repository/-/pipelines/1",
    "user": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url": "http://gdk.test:3001/root"
    }
  },
  {
    "id": 2,
    "iid": 2,
    "project_id": 9,
    "sha": "e564015ac6cb3d8617647802c875b27d392f72a6",
    "ref": "main",
    "status": "canceled",
    "source": "push",
    "created_at": "2023-02-01T12:23:23.694Z",
    "updated_at": "2023-02-01T12:26:28.635Z",
    "web_url": "http://gdk.test:3001/feature-testing/composer-repository/-/pipelines/2",
    "user": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url": "http://gdk.test:3001/root"
    }
  }
]
```

## Supprimer un package de projet {#delete-a-project-package}

Supprime un package de projet spécifié.

```plaintext
DELETE /projects/:id/packages/:package_id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths) |
| `package_id`      | entier | oui | ID d'un package. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

Peut renvoyer les codes de statut suivants :

- `204 No Content` : Le package a été supprimé avec succès.
- `403 Forbidden` : Le package est protégé contre la suppression.
- `404 Not Found` : Le package est introuvable.

Si le [transfert de requêtes](../user/packages/package_registry/supported_functionality.md#forwarding-requests) est activé, la suppression d'un package peut introduire un [risque de confusion des dépendances](../user/packages/package_registry/supported_functionality.md#deleting-packages).

Si un package est protégé par une [règle de protection](../user/packages/package_registry/package_protection_rules.md#protect-a-package), la suppression du package est interdite.

## Supprimer un fichier de package {#delete-a-package-file}

> [!warning]
> La suppression d'un fichier de package peut corrompre votre package, le rendant inutilisable ou impossible à extraire depuis votre client gestionnaire de packages. Lors de la suppression d'un fichier de package, assurez-vous de bien comprendre ce que vous faites.

Supprime un fichier de package spécifié.

```plaintext
DELETE /projects/:id/packages/:package_id/package_files/:package_file_id
```

| Attribut         | Type           | Obligatoire | Description |
| ----------------- | -------------- | -------- | ----------- |
| `id`              | entier ou chaîne | oui | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths). |
| `package_id`      | entier        | oui | ID d'un package. |
| `package_file_id` | entier        | oui | ID d'un fichier de package. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files/:package_file_id"
```

Peut renvoyer les codes de statut suivants :

- `204 No Content` : Le package a été supprimé avec succès.
- `403 Forbidden` : L'utilisateur n'est pas autorisé à supprimer le fichier ou le package est protégé contre la suppression.
- `404 Not Found` : Le package ou le fichier de package est introuvable.

Si un package auquel appartient un fichier de package est protégé par une [règle de protection](../user/packages/package_registry/package_protection_rules.md#protect-a-package), la suppression du fichier de package est interdite.
