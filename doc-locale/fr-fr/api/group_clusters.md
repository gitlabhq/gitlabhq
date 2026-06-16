---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des clusters de groupe (basé sur les certificats) (obsolète)
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Cette fonctionnalité a été [dépréciée](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) dans GitLab 14.5.

Comme pour les clusters Kubernetes de [niveau projet](../user/project/clusters/_index.md) et de [niveau instance](../user/instance/clusters/_index.md), les clusters Kubernetes de niveau groupe vous permettent de connecter un cluster Kubernetes à votre groupe, ce qui vous permet d'utiliser le même cluster dans plusieurs projets.

Les utilisateurs doivent disposer du rôle Maintainer ou Owner pour le groupe afin d'utiliser ces endpoints.

## Lister les clusters de groupe {#list-group-clusters}

Liste tous les clusters de groupe pour un groupe spécifié.

```plaintext
GET /groups/:id/clusters
```

Paramètres :

| Attribut | Type           | Obligatoire | Description                                                                   |
| --------- | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters"
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
    "cluster_type":"group_type",
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

## Récupérer un cluster de groupe {#retrieve-a-group-cluster}

Récupère un cluster de groupe spécifié.

```plaintext
GET /groups/:id/clusters/:cluster_id
```

Paramètres :

| Attribut    | Type           | Obligatoire | Description                                                                   |
| ------------ | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `cluster_id` | entier        | oui      | L'ID du cluster                                                         |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters/18"
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
  "cluster_type":"group_type",
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
  "group":
  {
    "id":26,
    "name":"group-with-clusters-api",
    "web_url":"https://gitlab.example.com/group-with-clusters-api"
  }
}
```

## Créer un cluster de groupe {#create-a-group-cluster}

Crée un cluster de groupe pour un groupe spécifié en ajoutant un cluster Kubernetes existant.

```plaintext
POST /groups/:id/clusters/user
```

Paramètres :

| Attribut                                            | Type           | Obligatoire | Description                                                                                         |
| ---------------------------------------------------- | -------------- | -------- | --------------------------------------------------------------------------------------------------- |
| `id`                                                 | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe                       |
| `name`                                               | string         | oui      | Le nom du cluster                                                                             |
| `domain`                                             | string         | non       | Le [domaine de base](../user/group/clusters/_index.md#base-domain) du cluster                       |
| `management_project_id`                              | entier        | non       | L'ID du [projet de gestion](../user/clusters/management_project.md) pour le cluster          |
| `enabled`                                            | boolean        | non       | Détermine si le cluster est actif ou non, par défaut `true`                                            |
| `managed`                                            | boolean        | non       | Détermine si GitLab gère les espaces de nommage et les comptes de service pour ce cluster. Par défaut `true` |
| `platform_kubernetes_attributes[api_url]`            | string         | oui      | L'URL pour accéder à l'API Kubernetes                                                                |
| `platform_kubernetes_attributes[token]`              | string         | oui      | Le jeton pour s'authentifier auprès de Kubernetes                                                        |
| `platform_kubernetes_attributes[ca_cert]`            | string         | non       | Certificat TLS. Requis si l'API utilise un certificat TLS auto-signé.                            |
| `platform_kubernetes_attributes[authorization_type]` | string         | non       | Le type d'autorisation du cluster : `rbac`, `abac` ou `unknown_authorization`. Par défaut `rbac`.      |
| `environment_scope`                                  | string         | non       | L'environnement associé au cluster. Par défaut `*`. Premium et Ultimate uniquement.              |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --header "Content-Type:application/json" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters/user" \
  --data '{
    "name":"cluster-5",
    "platform_kubernetes_attributes":{
      "api_url":"https://35.111.51.20",
      "token":"12345",
      "ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"
    }
  }'
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
  "cluster_type":"group_type",
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
    "authorization_type":"rbac",
    "ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"
  },
  "management_project":null,
  "group":
  {
    "id":26,
    "name":"group-with-clusters-api",
    "web_url":"https://gitlab.example.com/root/group-with-clusters-api"
  }
}
```

## Mettre à jour un cluster de groupe {#update-a-group-cluster}

Met à jour un cluster de groupe spécifié.

```plaintext
PUT /groups/:id/clusters/:cluster_id
```

Paramètres :

| Attribut                                 | Type           | Obligatoire | Description                                                                                |
| ----------------------------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------ |
| `id`                                      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe              |
| `cluster_id`                              | entier        | oui      | L'ID du cluster                                                                      |
| `name`                                    | string         | non       | Le nom du cluster                                                                    |
| `domain`                                  | string         | non       | Le [domaine de base](../user/group/clusters/_index.md#base-domain) du cluster              |
| `management_project_id`                   | entier        | non       | L'ID du [projet de gestion](../user/clusters/management_project.md) pour le cluster |
| `enabled`                                 | boolean        | non       | Détermine si le cluster est actif ou non                                                     |
| `managed`                                 | boolean        | non       | Détermine si GitLab gère les espaces de nommage et les comptes de service pour ce cluster          |
| `platform_kubernetes_attributes[api_url]` | string         | non       | L'URL pour accéder à l'API Kubernetes                                                       |
| `platform_kubernetes_attributes[token]`   | string         | non       | Le jeton pour s'authentifier auprès de Kubernetes                                               |
| `platform_kubernetes_attributes[ca_cert]` | string         | non       | Certificat TLS. Requis si l'API utilise un certificat TLS auto-signé.                   |
| `environment_scope`                       | string         | non       | L'environnement associé au cluster. Premium et Ultimate uniquement.                      |

> [!note]
> `name`, `api_url`, `ca_cert` et `token` ne peuvent être mis à jour que si le cluster a été ajouté via l'option [« Ajouter un cluster Kubernetes existant »](../user/project/clusters/add_existing_cluster.md) ou via l'endpoint [« Créer un cluster de groupe »](#create-a-group-cluster).

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters/24" \
  --data '{
    "name":"new-cluster-name",
    "domain":"new-domain.com",
    "platform_kubernetes_attributes":{
      "api_url":"https://10.10.101.1:6433"
    }
  }'
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
  "cluster_type":"group_type",
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
  "group":
  {
    "id":26,
    "name":"group-with-clusters-api",
    "web_url":"https://gitlab.example.com/group-with-clusters-api"
  }
}
```

## Supprimer un cluster de groupe {#delete-a-group-cluster}

Supprime un cluster de groupe spécifié. Ne supprime pas les ressources existantes dans le cluster Kubernetes connecté.

```plaintext
DELETE /groups/:id/clusters/:cluster_id
```

Paramètres :

| Attribut    | Type           | Obligatoire | Description                                                                   |
| ------------ | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `cluster_id` | entier        | oui      | L'ID du cluster                                                         |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters/23"
```
