---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project clusters API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/23922) in GitLab 11.7.

Users need at least the [Maintainer](../user/permissions.md) role to use these endpoints.

## List project clusters

Returns a list of project clusters.

```plaintext
GET /projects/:id/clusters
```

Parameters:

| Attribute | Type    | Required | Description                                           |
| --------- | ------- | -------- | ----------------------------------------------------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/26/clusters"
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

## Get a single project cluster

Gets a single project cluster.

```shell
GET /projects/:id/clusters/:cluster_id
```

Parameters:

| Attribute    | Type    | Required | Description                                           |
| ------------ | ------- | -------- | ----------------------------------------------------- |
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `cluster_id` | integer | yes      | The ID of the cluster                                 |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/26/clusters/18"
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

## Add existing cluster to project

Adds an existing Kubernetes cluster to the project.

```shell
POST /projects/:id/clusters/user
```

Parameters:

| Attribute                                            | Type    | Required | Description                                                                                           |
| ---------------------------------------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------------- |
| `id`                                                 | integer or string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user                                                 |
| `name`                                               | string  | yes      | The name of the cluster                                                                               |
| `domain`                                             | string  | no       | The [base domain](../user/project/clusters/gitlab_managed_clusters.md#base-domain) of the cluster                       |
| `management_project_id`                              | integer | no       | The ID of the [management project](../user/clusters/management_project.md) for the cluster            |
| `enabled`                                            | boolean | no       | Determines if cluster is active or not, defaults to `true`                                            |
| `managed`                                            | boolean | no       | Determines if GitLab manages namespaces and service accounts for this cluster. Defaults to `true` |
| `platform_kubernetes_attributes[api_url]`            | string  | yes      | The URL to access the Kubernetes API                                                                  |
| `platform_kubernetes_attributes[token]`              | string  | yes      | The token to authenticate against Kubernetes                                                          |
| `platform_kubernetes_attributes[ca_cert]`            | string  | no       | TLS certificate. Required if API is using a self-signed TLS certificate.                              |
| `platform_kubernetes_attributes[namespace]`          | string  | no       | The unique namespace related to the project                                                           |
| `platform_kubernetes_attributes[authorization_type]` | string  | no       | The cluster authorization type: `rbac`, `abac` or `unknown_authorization`. Defaults to `rbac`.        |
| `environment_scope`                                  | string  | no       | The associated environment to the cluster. Defaults to `*` **(PREMIUM)**                              |

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/26/clusters/user" \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST --data '{"name":"cluster-5", "platform_kubernetes_attributes":{"api_url":"https://35.111.51.20","token":"12345","namespace":"cluster-5-namespace","ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"}}'
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
    "ssh_url_to_repo":"ssh:://gitlab.example.com/root/project-with-clusters-api.git",
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

## Edit project cluster

Updates an existing project cluster.

```shell
PUT /projects/:id/clusters/:cluster_id
```

Parameters:

| Attribute                                   | Type    | Required | Description                                                                                |
| ------------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------------ |
| `id`                                        | integer or string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user                                      |
| `cluster_id`                                | integer | yes      | The ID of the cluster                                                                      |
| `name`                                      | string  | no       | The name of the cluster                                                                    |
| `domain`                                    | string  | no       | The [base domain](../user/project/clusters/gitlab_managed_clusters.md#base-domain) of the cluster            |
| `management_project_id`                     | integer | no       | The ID of the [management project](../user/clusters/management_project.md) for the cluster |
| `enabled`                                   | boolean | no       | Determines if cluster is active or not                                                     |
| `managed`                                   | boolean | no       | Determines if GitLab manages namespaces and service accounts for this cluster          |
| `platform_kubernetes_attributes[api_url]`   | string  | no       | The URL to access the Kubernetes API                                                       |
| `platform_kubernetes_attributes[token]`     | string  | no       | The token to authenticate against Kubernetes                                               |
| `platform_kubernetes_attributes[ca_cert]`   | string  | no       | TLS certificate. Required if API is using a self-signed TLS certificate.                   |
| `platform_kubernetes_attributes[namespace]` | string  | no       | The unique namespace related to the project                                                |
| `environment_scope`                         | string  | no       | The associated environment to the cluster **(PREMIUM)**                                    |

NOTE:
`name`, `api_url`, `ca_cert` and `token` can only be updated if the cluster was added
through the ["Add existing Kubernetes cluster"](../user/project/clusters/add_remove_clusters.md#add-existing-cluster) option or
through the ["Add existing cluster to project"](#add-existing-cluster-to-project) endpoint.

Example request:

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/26/clusters/24" \
-H "Content-Type:application/json" \
-X PUT --data '{"name":"new-cluster-name","domain":"new-domain.com","api_url":"https://new-api-url.com"}'
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
    "ssh_url_to_repo":"ssh:://gitlab.example.com/root/project-with-clusters-api.git",
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

## Delete project cluster

Deletes an existing project cluster.

```plaintext
DELETE /projects/:id/clusters/:cluster_id
```

Parameters:

| Attribute    | Type    | Required | Description                                           |
| ------------ | ------- | -------- | ----------------------------------------------------- |
| `id`         | integer or string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `cluster_id` | integer | yes      | The ID of the cluster                                 |

Example request:

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/26/clusters/23"
```
