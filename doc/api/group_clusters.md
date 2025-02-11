---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group clusters API (certificate-based) (deprecated)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.

Similarly to [project-level](../user/project/clusters/_index.md) and
[instance-level](../user/instance/clusters/_index.md) Kubernetes clusters,
group-level Kubernetes clusters allow you to connect a Kubernetes cluster to
your group, enabling you to use the same cluster across multiple projects.

Users need at least the Maintainer role for the group to use these endpoints.

## List group clusters

Returns a list of group clusters.

```plaintext
GET /groups/:id/clusters
```

Parameters:

| Attribute | Type           | Required | Description                                                                   |
| --------- | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/groups/26/clusters"
```

Example response:

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

## Get a single group cluster

Gets a single group cluster.

```plaintext
GET /groups/:id/clusters/:cluster_id
```

Parameters:

| Attribute    | Type           | Required | Description                                                                   |
| ------------ | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `cluster_id` | integer        | yes      | The ID of the cluster                                                         |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/groups/26/clusters/18"
```

Example response:

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

## Add existing cluster to group

Adds an existing Kubernetes cluster to the group.

```plaintext
POST /groups/:id/clusters/user
```

Parameters:

| Attribute                                            | Type           | Required | Description                                                                                         |
| ---------------------------------------------------- | -------------- | -------- | --------------------------------------------------------------------------------------------------- |
| `id`                                                 | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                       |
| `name`                                               | string         | yes      | The name of the cluster                                                                             |
| `domain`                                             | string         | no       | The [base domain](../user/group/clusters/_index.md#base-domain) of the cluster                       |
| `management_project_id`                              | integer        | no       | The ID of the [management project](../user/clusters/management_project.md) for the cluster          |
| `enabled`                                            | boolean        | no       | Determines if cluster is active or not, defaults to `true`                                            |
| `managed`                                            | boolean        | no       | Determines if GitLab manages namespaces and service accounts for this cluster. Defaults to `true` |
| `platform_kubernetes_attributes[api_url]`            | string         | yes      | The URL to access the Kubernetes API                                                                |
| `platform_kubernetes_attributes[token]`              | string         | yes      | The token to authenticate against Kubernetes                                                        |
| `platform_kubernetes_attributes[ca_cert]`            | string         | no       | TLS certificate. Required if API is using a self-signed TLS certificate.                            |
| `platform_kubernetes_attributes[authorization_type]` | string         | no       | The cluster authorization type: `rbac`, `abac` or `unknown_authorization`. Defaults to `rbac`.      |
| `environment_scope`                                  | string         | no       | The associated environment to the cluster. Defaults to `*`. Premium and Ultimate only.              |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/groups/26/clusters/user" \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
--request POST --data '{"name":"cluster-5", "platform_kubernetes_attributes":{"api_url":"https://35.111.51.20","token":"12345","ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"}}'
```

Example response:

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

## Edit group cluster

Updates an existing group cluster.

```plaintext
PUT /groups/:id/clusters/:cluster_id
```

Parameters:

| Attribute                                 | Type           | Required | Description                                                                                |
| ----------------------------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------ |
| `id`                                      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)              |
| `cluster_id`                              | integer        | yes      | The ID of the cluster                                                                      |
| `name`                                    | string         | no       | The name of the cluster                                                                    |
| `domain`                                  | string         | no       | The [base domain](../user/group/clusters/_index.md#base-domain) of the cluster              |
| `management_project_id`                   | integer        | no       | The ID of the [management project](../user/clusters/management_project.md) for the cluster |
| `enabled`                                 | boolean        | no       | Determines if cluster is active or not                                                     |
| `managed`                                 | boolean        | no       | Determines if GitLab manages namespaces and service accounts for this cluster          |
| `platform_kubernetes_attributes[api_url]` | string         | no       | The URL to access the Kubernetes API                                                       |
| `platform_kubernetes_attributes[token]`   | string         | no       | The token to authenticate against Kubernetes                                               |
| `platform_kubernetes_attributes[ca_cert]` | string         | no       | TLS certificate. Required if API is using a self-signed TLS certificate.                   |
| `environment_scope`                       | string         | no       | The associated environment to the cluster. Premium and Ultimate only.                      |

NOTE:
`name`, `api_url`, `ca_cert` and `token` can only be updated if the cluster was added
through the ["Add existing Kubernetes cluster"](../user/project/clusters/add_existing_cluster.md) option or
through the ["Add existing cluster to group"](#add-existing-cluster-to-group) endpoint.

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/groups/26/clusters/24" \
-H "Content-Type:application/json" \
--request PUT --data '{"name":"new-cluster-name","domain":"new-domain.com","platform_kubernetes_attributes":{"api_url":"https://10.10.101.1:6433"}}'
```

Example response:

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

## Delete group cluster

Deletes an existing group cluster. Does not remove existing resources within the connected Kubernetes cluster.

```plaintext
DELETE /groups/:id/clusters/:cluster_id
```

Parameters:

| Attribute    | Type           | Required | Description                                                                   |
| ------------ | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `cluster_id` | integer        | yes      | The ID of the cluster                                                         |

Example request:

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/groups/26/clusters/23"
```
