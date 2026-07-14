---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de clusters de projet (basée sur les certificats) (obsolète)
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Cette fonctionnalité a été [dépréciée](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) dans GitLab 14.5.

Les utilisateurs doivent disposer du rôle Maintainer ou Owner pour utiliser ces points de terminaison.

## Lister tous les clusters dans un projet {#list-all-clusters-in-a-project}

Liste tous les clusters dans un projet spécifié.

```plaintext
GET /projects/:id/clusters
```

Paramètres :

| Attribut | Type    | Obligatoire | Description                                           |
| --------- | ------- | -------- | ----------------------------------------------------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters"
```

Exemple de réponse :

```json
[
  {
    "id":18,
    "name":"cluster-1",
    "domain":"example.com",
    "created_at":"2019-01-02T20:18:12.563Z",
    "managed": true,
    "enabled": true,
    "provider_type":"user",
    "platform_type":"kubernetes",
    "environment_scope":"*",
    "cluster_type":"project_type",
    "user":
    {
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/4249f4df72b..",
      "web_url":"https://gitlab.example.com/root"
    },
    "platform_kubernetes":
    {
      "api_url":"https://104.197.68.152",
      "namespace":"cluster-1-namespace",
      "authorization_type":"rbac",
      "ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"
    },
    "management_project":
    {
      "id":2,
      "description":null,
      "name":"project2",
      "name_with_namespace":"John Doe8 / project2",
      "path":"project2",
      "path_with_namespace":"namespace2/project2",
      "created_at":"2019-10-11T02:55:54.138Z"
    }
  },
  {
    "id":19,
    "name":"cluster-2",
    ...
  }
]
```

## Récupérer un cluster depuis un projet {#retrieve-a-cluster-from-a-project}

Récupère un cluster spécifié dans un projet.

```plaintext
GET /projects/:id/clusters/:cluster_id
```

Paramètres :

| Attribut    | Type    | Obligatoire | Description                                           |
| ------------ | ------- | -------- | ----------------------------------------------------- |
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `cluster_id` | entier | oui      | L'ID du cluster                                 |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters/18"
```

Exemple de réponse :

```json
{
  "id":18,
  "name":"cluster-1",
  "domain":"example.com",
  "created_at":"2019-01-02T20:18:12.563Z",
  "managed": true,
  "enabled": true,
  "provider_type":"user",
  "platform_type":"kubernetes",
  "environment_scope":"*",
  "cluster_type":"project_type",
  "user":
  {
    "id":1,
    "name":"Administrator",
    "username":"root",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/4249f4df72b..",
    "web_url":"https://gitlab.example.com/root"
  },
  "platform_kubernetes":
  {
    "api_url":"https://104.197.68.152",
    "namespace":"cluster-1-namespace",
    "authorization_type":"rbac",
    "ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"
  },
  "management_project":
  {
    "id":2,
    "description":null,
    "name":"project2",
    "name_with_namespace":"John Doe8 / project2",
    "path":"project2",
    "path_with_namespace":"namespace2/project2",
    "created_at":"2019-10-11T02:55:54.138Z"
  },
  "project":
  {
    "id":26,
    "description":"",
    "name":"project-with-clusters-api",
    "name_with_namespace":"Administrator / project-with-clusters-api",
    "path":"project-with-clusters-api",
    "path_with_namespace":"root/project-with-clusters-api",
    "created_at":"2019-01-02T20:13:32.600Z",
    "default_branch":null,
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo":"ssh://gitlab.example.com/root/project-with-clusters-api.git",
    "http_url_to_repo":"https://gitlab.example.com/root/project-with-clusters-api.git",
    "web_url":"https://gitlab.example.com/root/project-with-clusters-api",
    "readme_url":null,
    "avatar_url":null,
    "star_count":0,
    "forks_count":0,
    "last_activity_at":"2019-01-02T20:13:32.600Z",
    "namespace":
    {
      "id":1,
      "name":"root",
      "path":"root",
      "kind":"user",
      "full_path":"root",
      "parent_id":null
    }
  }
}
```

## Ajouter un cluster à un projet {#add-a-cluster-to-a-project}

Ajoute un cluster existant à un projet spécifié.

```plaintext
POST /projects/:id/clusters/user
```

Paramètres :

| Attribut                                            | Type    | Obligatoire | Description                                                                                           |
| ---------------------------------------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------------- |
| `id`                                                 | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)                                                 |
| `name`                                               | string  | oui      | Le nom du cluster                                                                               |
| `domain`                                             | string  | non       | Le [domaine de base](../user/project/clusters/gitlab_managed_clusters.md#base-domain) du cluster                       |
| `management_project_id`                              | entier | non       | L'ID du [projet de gestion](../user/clusters/management_project.md) pour le cluster            |
| `enabled`                                            | boolean | non       | Détermine si le cluster est actif ou non, par défaut `true`                                            |
| `managed`                                            | boolean | non       | Détermine si GitLab gère les espaces de nommage et les comptes de service pour ce cluster. Par défaut `true` |
| `platform_kubernetes_attributes[api_url]`            | string  | oui      | L'URL pour accéder à l'API Kubernetes                                                                  |
| `platform_kubernetes_attributes[token]`              | string  | oui      | Le jeton d'accès personnel pour s'authentifier auprès de Kubernetes                                                          |
| `platform_kubernetes_attributes[ca_cert]`            | string  | non       | Certificat TLS. Requis si l'API utilise un certificat TLS auto-signé.                              |
| `platform_kubernetes_attributes[namespace]`          | string  | non       | L'espace de nommage unique associé au projet                                                           |
| `platform_kubernetes_attributes[authorization_type]` | string  | non       | Le type d'autorisation du cluster : `rbac`, `abac` ou `unknown_authorization`. Par défaut `rbac`.        |
| `environment_scope`                                  | string  | non       | L'environnement associé au cluster. Par défaut `*`. GitLab Premium et GitLab Ultimate uniquement.                         |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --header "Content-Type:application/json" \
  --data '{"name":"cluster-5", "platform_kubernetes_attributes":{"api_url":"https://35.111.51.20","token":"12345","namespace":"cluster-5-namespace","ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"}}' \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters/user"
```

Exemple de réponse :

```json
{
  "id":24,
  "name":"cluster-5",
  "created_at":"2019-01-03T21:53:40.610Z",
  "managed": true,
  "enabled": true,
  "provider_type":"user",
  "platform_type":"kubernetes",
  "environment_scope":"*",
  "cluster_type":"project_type",
  "user":
  {
    "id":1,
    "name":"Administrator",
    "username":"root",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/4249f4df72b..",
    "web_url":"https://gitlab.example.com/root"
  },
  "platform_kubernetes":
  {
    "api_url":"https://35.111.51.20",
    "namespace":"cluster-5-namespace",
    "authorization_type":"rbac",
    "ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"
  },
  "management_project":null,
  "project":
  {
    "id":26,
    "description":"",
    "name":"project-with-clusters-api",
    "name_with_namespace":"Administrator / project-with-clusters-api",
    "path":"project-with-clusters-api",
    "path_with_namespace":"root/project-with-clusters-api",
    "created_at":"2019-01-02T20:13:32.600Z",
    "default_branch":null,
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo":"ssh://gitlab.example.com/root/project-with-clusters-api.git",
    "http_url_to_repo":"https://gitlab.example.com/root/project-with-clusters-api.git",
    "web_url":"https://gitlab.example.com/root/project-with-clusters-api",
    "readme_url":null,
    "avatar_url":null,
    "star_count":0,
    "forks_count":0,
    "last_activity_at":"2019-01-02T20:13:32.600Z",
    "namespace":
    {
      "id":1,
      "name":"root",
      "path":"root",
      "kind":"user",
      "full_path":"root",
      "parent_id":null
    }
  }
}
```

## Mettre à jour un cluster dans un projet {#update-a-cluster-in-a-project}

Met à jour un cluster dans un projet spécifié.

```plaintext
PUT /projects/:id/clusters/:cluster_id
```

Paramètres :

| Attribut                                   | Type    | Obligatoire | Description                                                                                |
| ------------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------------ |
| `id`                                        | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)                                      |
| `cluster_id`                                | entier | oui      | L'ID du cluster                                                                      |
| `name`                                      | string  | non       | Le nom du cluster                                                                    |
| `domain`                                    | string  | non       | Le [domaine de base](../user/project/clusters/gitlab_managed_clusters.md#base-domain) du cluster            |
| `management_project_id`                     | entier | non       | L'ID du [projet de gestion](../user/clusters/management_project.md) pour le cluster |
| `enabled`                                   | boolean | non       | Détermine si le cluster est actif ou non                                                     |
| `managed`                                   | boolean | non       | Détermine si GitLab gère les espaces de nommage et les comptes de service pour ce cluster          |
| `platform_kubernetes_attributes[api_url]`   | string  | non       | L'URL pour accéder à l'API Kubernetes                                                       |
| `platform_kubernetes_attributes[token]`     | string  | non       | Le jeton d'accès personnel pour s'authentifier auprès de Kubernetes                                               |
| `platform_kubernetes_attributes[ca_cert]`   | string  | non       | Certificat TLS. Requis si l'API utilise un certificat TLS auto-signé.                   |
| `platform_kubernetes_attributes[namespace]` | string  | non       | L'espace de nommage unique associé au projet                                                |
| `environment_scope`                         | string  | non       | L'environnement associé au cluster                                                  |

> [!note]
> `name`, `api_url`, `ca_cert` et `token` ne peuvent être mis à jour que si le cluster a été ajouté via l'option ["Add existing Kubernetes cluster"](../user/project/clusters/add_existing_cluster.md) ou via le point de terminaison ["Add existing cluster to project"](#add-a-cluster-to-a-project).

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --data '{"name":"new-cluster-name","domain":"new-domain.com","api_url":"https://new-api-url.com"}' \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters/24"
```

Exemple de réponse :

```json
{
  "id":24,
  "name":"new-cluster-name",
  "domain":"new-domain.com",
  "created_at":"2019-01-03T21:53:40.610Z",
  "managed": true,
  "enabled": true,
  "provider_type":"user",
  "platform_type":"kubernetes",
  "environment_scope":"*",
  "cluster_type":"project_type",
  "user":
  {
    "id":1,
    "name":"Administrator",
    "username":"root",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/4249f4df72b..",
    "web_url":"https://gitlab.example.com/root"
  },
  "platform_kubernetes":
  {
    "api_url":"https://new-api-url.com",
    "namespace":"cluster-5-namespace",
    "authorization_type":"rbac",
    "ca_cert":null
  },
  "management_project":
  {
    "id":2,
    "description":null,
    "name":"project2",
    "name_with_namespace":"John Doe8 / project2",
    "path":"project2",
    "path_with_namespace":"namespace2/project2",
    "created_at":"2019-10-11T02:55:54.138Z"
  },
  "project":
  {
    "id":26,
    "description":"",
    "name":"project-with-clusters-api",
    "name_with_namespace":"Administrator / project-with-clusters-api",
    "path":"project-with-clusters-api",
    "path_with_namespace":"root/project-with-clusters-api",
    "created_at":"2019-01-02T20:13:32.600Z",
    "default_branch":null,
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo":"ssh://gitlab.example.com/root/project-with-clusters-api.git",
    "http_url_to_repo":"https://gitlab.example.com/root/project-with-clusters-api.git",
    "web_url":"https://gitlab.example.com/root/project-with-clusters-api",
    "readme_url":null,
    "avatar_url":null,
    "star_count":0,
    "forks_count":0,
    "last_activity_at":"2019-01-02T20:13:32.600Z",
    "namespace":
    {
      "id":1,
      "name":"root",
      "path":"root",
      "kind":"user",
      "full_path":"root",
      "parent_id":null
    }
  }
}
```

## Supprimer un cluster d'un projet {#delete-cluster-from-a-project}

Supprime un cluster spécifié d'un projet. Ne supprime pas les ressources existantes dans le cluster Kubernetes connecté.

```plaintext
DELETE /projects/:id/clusters/:cluster_id
```

Paramètres :

| Attribut    | Type    | Obligatoire | Description                                           |
| ------------ | ------- | -------- | ----------------------------------------------------- |
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `cluster_id` | entier | oui      | L'ID du cluster                                 |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters/23"
```
