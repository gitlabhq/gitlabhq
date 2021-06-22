---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Instance clusters API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36001) in GitLab 13.2.

Instance-level Kubernetes clusters allow you to connect a Kubernetes cluster to the GitLab instance, which enables you to use the same cluster across multiple projects. [More information](../user/instance/clusters/index.md)

NOTE:
Users need administrator access to use these endpoints.

## List instance clusters

Returns a list of instance clusters.

```plaintext
GET /admin/clusters
```

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/admin/clusters"
```

Example response:

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

## Get a single instance cluster

Returns a single instance cluster.

Parameters:

| Attribute    | Type    | Required | Description           |
| ------------ | ------- | -------- | --------------------- |
| `cluster_id` | integer | yes      | The ID of the cluster |

```plaintext
GET /admin/clusters/:cluster_id
```

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/admin/clusters/9"
```

Example response:

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

## Add existing instance cluster

Adds an existing Kubernetes instance cluster.

```plaintext
POST /admin/clusters/add
```

Parameters:

| Attribute                                            | Type    | Required | Description                                                                                           |
| ---------------------------------------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------------- |
| `name`                                               | string  | yes      | The name of the cluster                                                                               |
| `domain`                                             | string  | no       | The [base domain](../user/project/clusters/gitlab_managed_clusters.md#base-domain) of the cluster                       |
| `environment_scope`                                  | string  | no       | The associated environment to the cluster. Defaults to `*`                                            |
| `management_project_id`                              | integer | no       | The ID of the [management project](../user/clusters/management_project.md) for the cluster            |
| `enabled`                                            | boolean | no       | Determines if cluster is active or not, defaults to `true`                                            |
| `managed`                                            | boolean | no       | Determines if GitLab manages namespaces and service accounts for this cluster. Defaults to `true` |
| `platform_kubernetes_attributes[api_url]`            | string  | yes      | The URL to access the Kubernetes API                                                                  |
| `platform_kubernetes_attributes[token]`              | string  | yes      | The token to authenticate against Kubernetes                                                          |
| `platform_kubernetes_attributes[ca_cert]`            | string  | no       | TLS certificate. Required if API is using a self-signed TLS certificate.                              |
| `platform_kubernetes_attributes[namespace]`          | string  | no       | The unique namespace related to the project                                                           |
| `platform_kubernetes_attributes[authorization_type]` | string  | no       | The cluster authorization type: `rbac`, `abac` or `unknown_authorization`. Defaults to `rbac`.        |

Example request:

```shell
curl --header "Private-Token:<your_access_token>" "http://gitlab.example.com/api/v4/admin/clusters/add" \
-H "Accept:application/json" \
-H "Content-Type:application/json" \
-X POST --data '{"name":"cluster-3", "environment_scope":"production", "platform_kubernetes_attributes":{"api_url":"https://example.com", "token":"12345",  "ca_cert":"-----BEGIN CERTIFICATE-----qpoeiXXZafCM0ZDJkZjM...-----END CERTIFICATE-----"}}'

```

Example response:

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

## Edit instance cluster

Updates an existing instance cluster.

```shell
PUT /admin/clusters/:cluster_id
```

Parameters:

| Attribute                                   | Type    | Required | Description                                                                                |
| ------------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------------ |
| `cluster_id`                                | integer | yes      | The ID of the cluster                                                                      |
| `name`                                      | string  | no       | The name of the cluster                                                                    |
| `domain`                                    | string  | no       | The [base domain](../user/project/clusters/gitlab_managed_clusters.md#base-domain) of the cluster            |
| `environment_scope`                         | string  | no       | The associated environment to the cluster                                                  |
| `management_project_id`                     | integer | no       | The ID of the [management project](../user/clusters/management_project.md) for the cluster |
| `enabled`                                   | boolean | no       | Determines if cluster is active or not                                                     |
| `managed`                                   | boolean | no       | Determines if GitLab manages namespaces and service accounts for this cluster          |
| `platform_kubernetes_attributes[api_url]`   | string  | no       | The URL to access the Kubernetes API                                                       |
| `platform_kubernetes_attributes[token]`     | string  | no       | The token to authenticate against Kubernetes                                               |
| `platform_kubernetes_attributes[ca_cert]`   | string  | no       | TLS certificate. Required if API is using a self-signed TLS certificate.                   |
| `platform_kubernetes_attributes[namespace]` | string  | no       | The unique namespace related to the project                                                |

NOTE:
`name`, `api_url`, `ca_cert` and `token` can only be updated if the cluster was added
through the [Add existing Kubernetes cluster](../user/project/clusters/add_remove_clusters.md#add-existing-cluster) option or
through the [Add existing instance cluster](#add-existing-instance-cluster) endpoint.

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "http://gitlab.example.com/api/v4/admin/clusters/9" \
-H "Content-Type:application/json" \
-X PUT --data '{"name":"update-cluster-name", "platform_kubernetes_attributes":{"api_url":"https://new-example.com","token":"new-token"}}'

```

Example response:

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

## Delete instance cluster

Deletes an existing instance cluster.

```plaintext
DELETE /admin/clusters/:cluster_id
```

Parameters:

| Attribute    | Type    | Required | Description           |
| ------------ | ------- | -------- | --------------------- |
| `cluster_id` | integer | yes      | The ID of the cluster |

Example request:

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/admin/clusters/11"
```
