---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des clusters d'instance (basée sur les certificats) (obsolète)"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

> [!warning]
> Cette fonctionnalité a été [dépréciée](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) dans GitLab 14.5.

Avec les [clusters Kubernetes au niveau de l'instance](../user/instance/clusters/_index.md), vous pouvez connecter un cluster Kubernetes à l'instance GitLab et utiliser le même cluster pour tous les projets de votre instance.

Les utilisateurs doivent disposer d'un accès administrateur pour utiliser ces endpoints.

## Lister les clusters d'instance {#list-instance-clusters}

Liste tous les clusters d'instance.

```plaintext
GET /admin/clusters
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters"
```

Exemple de réponse :

```json
[
  {
    "id": 9,
    "name": "cluster-1",
    "created_at": "2020-07-14T18:36:10.440Z",
    "managed": true,
    "enabled": true,
    "domain": null,
    "provider_type": "user",
    "platform_type": "kubernetes",
    "environment_scope": "*",
    "cluster_type": "instance_type",
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "platform_kubernetes": {
      "api_url": "https://example.com",
      "namespace": null,
      "authorization_type": "rbac",
      "ca_cert":"-----BEGIN CERTIFICATE-----IxMDM1MV0ZDJkZjM...-----END CERTIFICATE-----"
    },
    "provider_gcp": null,
    "management_project": null
  },
  {
    "id": 10,
    "name": "cluster-2",
    "created_at": "2020-07-14T18:39:05.383Z",
    "domain": null,
    "provider_type": "user",
    "platform_type": "kubernetes",
    "environment_scope": "staging",
    "cluster_type": "instance_type",
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "platform_kubernetes": {
      "api_url": "https://example.com",
      "namespace": null,
      "authorization_type": "rbac",
      "ca_cert":"-----BEGIN CERTIFICATE-----LzEtMCadtaLGxcsGAZjM...-----END CERTIFICATE-----"
    },
    "provider_gcp": null,
    "management_project": null
  },
  {
    "id": 11,
    "name": "cluster-3",
    ...
  }
]
```

## Récupérer un seul cluster d'instance {#retrieve-a-single-instance-cluster}

Récupère un seul cluster d'instance.

Paramètres :

| Attribut    | Type    | Obligatoire | Description           |
| ------------ | ------- | -------- | --------------------- |
| `cluster_id` | integer | oui      | L'ID du cluster |

```plaintext
GET /admin/clusters/:cluster_id
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters/9"
```

Exemple de réponse :

```json
{
  "id": 9,
  "name": "cluster-1",
  "created_at": "2020-07-14T18:36:10.440Z",
  "managed": true,
  "enabled": true,
  "domain": null,
  "provider_type": "user",
  "platform_type": "kubernetes",
  "environment_scope": "*",
  "cluster_type": "instance_type",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "platform_kubernetes": {
    "api_url": "https://example.com",
    "namespace": null,
    "authorization_type": "rbac",
    "ca_cert":"-----BEGIN CERTIFICATE-----IxMDM1MV0ZDJkZjM...-----END CERTIFICATE-----"
  },
  "provider_gcp": null,
  "management_project": null
}
```

## Créer un cluster d'instance {#create-an-instance-cluster}

Crée un cluster d'instance en ajoutant un cluster Kubernetes existant.

```plaintext
POST /admin/clusters/add
```

Paramètres :

| Attribut                                            | Type    | Obligatoire | Description                                                                                           |
| ---------------------------------------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------------- |
| `name`                                               | string  | oui      | Le nom du cluster                                                                               |
| `domain`                                             | string  | non       | Le [domaine de base](../user/project/clusters/gitlab_managed_clusters.md#base-domain) du cluster                       |
| `environment_scope`                                  | string  | non       | L'environnement associé au cluster. Par défaut : `*`                                            |
| `management_project_id`                              | integer | non       | L'ID du [projet de gestion](../user/clusters/management_project.md) du cluster            |
| `enabled`                                            | boolean | non       | Détermine si le cluster est actif ou non, par défaut `true`                                            |
| `managed`                                            | boolean | non       | Détermine si GitLab gère les espaces de nommage et les comptes de service pour ce cluster. Par défaut : `true` |
| `platform_kubernetes_attributes[api_url]`            | string  | oui      | L'URL d'accès à l'API Kubernetes                                                                  |
| `platform_kubernetes_attributes[token]`              | string  | oui      | Le token pour s'authentifier auprès de Kubernetes                                                          |
| `platform_kubernetes_attributes[ca_cert]`            | string  | non       | Certificat TLS. Requis si l'API utilise un certificat TLS auto-signé.                              |
| `platform_kubernetes_attributes[namespace]`          | string  | non       | L'espace de nommage unique lié au projet                                                           |
| `platform_kubernetes_attributes[authorization_type]` | string  | non       | Le type d'autorisation du cluster : `rbac`, `abac` ou `unknown_authorization`. Par défaut : `rbac`.        |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data '{"name":"cluster-3", "environment_scope":"production", "platform_kubernetes_attributes":{"api_url":"https://example.com", "token":"12345", "ca_cert":"-----BEGIN CERTIFICATE-----qpoeiXXZafCM0ZDJkZjM...-----END CERTIFICATE-----"}}' \
  --url "http://gitlab.example.com/api/v4/admin/clusters/add"
```

Exemple de réponse :

```json
{
  "id": 11,
  "name": "cluster-3",
  "created_at": "2020-07-14T18:42:50.805Z",
  "managed": true,
  "enabled": true,
  "domain": null,
  "provider_type": "user",
  "platform_type": "kubernetes",
  "environment_scope": "production",
  "cluster_type": "instance_type",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com:3000/root"
  },
  "platform_kubernetes": {
    "api_url": "https://example.com",
    "namespace": null,
    "authorization_type": "rbac",
    "ca_cert":"-----BEGIN CERTIFICATE-----qpoeiXXZafCM0ZDJkZjM...-----END CERTIFICATE-----"
  },
  "provider_gcp": null,
  "management_project": null
}
```

## Mettre à jour un cluster d'instance {#update-an-instance-cluster}

Met à jour un cluster d'instance existant.

```plaintext
PUT /admin/clusters/:cluster_id
```

Paramètres :

| Attribut                                   | Type    | Obligatoire | Description                                                                                |
| ------------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------------ |
| `cluster_id`                                | integer | oui      | L'ID du cluster                                                                      |
| `name`                                      | string  | non       | Le nom du cluster                                                                    |
| `domain`                                    | string  | non       | Le [domaine de base](../user/project/clusters/gitlab_managed_clusters.md#base-domain) du cluster            |
| `environment_scope`                         | string  | non       | L'environnement associé au cluster                                                  |
| `management_project_id`                     | integer | non       | L'ID du [projet de gestion](../user/clusters/management_project.md) du cluster |
| `enabled`                                   | boolean | non       | Détermine si le cluster est actif ou non                                                     |
| `managed`                                   | boolean | non       | Détermine si GitLab gère les espaces de nommage et les comptes de service pour ce cluster          |
| `platform_kubernetes_attributes[api_url]`   | string  | non       | L'URL d'accès à l'API Kubernetes                                                       |
| `platform_kubernetes_attributes[token]`     | string  | non       | Le token pour s'authentifier auprès de Kubernetes                                               |
| `platform_kubernetes_attributes[ca_cert]`   | string  | non       | Certificat TLS. Requis si l'API utilise un certificat TLS auto-signé.                   |
| `platform_kubernetes_attributes[namespace]` | string  | non       | L'espace de nommage unique lié au projet                                                |

> [!note]
> `name`, `api_url`, `ca_cert` et `token` ne peuvent être mis à jour que si le cluster a été ajouté via l'option [Add existing Kubernetes cluster](../user/project/clusters/add_existing_cluster.md) ou via l'endpoint [Créer un cluster d'instance](#create-an-instance-cluster).

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name":"update-cluster-name", "platform_kubernetes_attributes":{"api_url":"https://new-example.com","token":"new-token"}}' \
  --url "http://gitlab.example.com/api/v4/admin/clusters/9"
```

Exemple de réponse :

```json
{
  "id": 9,
  "name": "update-cluster-name",
  "created_at": "2020-07-14T18:36:10.440Z",
  "managed": true,
  "enabled": true,
  "domain": null,
  "provider_type": "user",
  "platform_type": "kubernetes",
  "environment_scope": "*",
  "cluster_type": "instance_type",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "platform_kubernetes": {
    "api_url": "https://new-example.com",
    "namespace": null,
    "authorization_type": "rbac",
    "ca_cert":"-----BEGIN CERTIFICATE-----IxMDM1MV0ZDJkZjM...-----END CERTIFICATE-----"
  },
  "provider_gcp": null,
  "management_project": null,
  "project": null
}
```

## Supprimer un cluster d'instance {#delete-instance-cluster}

Supprime un cluster d'instance existant. Ne supprime pas les ressources existantes dans le cluster Kubernetes connecté.

```plaintext
DELETE /admin/clusters/:cluster_id
```

Paramètres :

| Attribut    | Type    | Obligatoire | Description           |
| ------------ | ------- | -------- | --------------------- |
| `cluster_id` | integer | oui      | L'ID du cluster |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters/11"
```
