---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 클러스터 API(인증서 기반)(더 이상 사용되지 않음)
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> 이 기능은 GitLab 14.5에서 [더 이상 사용되지 않습니다](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

[프로젝트 수준](../user/project/clusters/_index.md) 의 Kubernetes 클러스터 및 [인스턴스 수준](../user/instance/clusters/_index.md)의 Kubernetes 클러스터와 유사하게 그룹 수준의 Kubernetes 클러스터를 사용하면 Kubernetes 클러스터를 그룹에 연결하여 여러 프로젝트에서 동일한 클러스터를 사용할 수 있습니다.

사용자는 이러한 엔드포인트를 사용하려면 그룹에 대한 유지보수자 또는 소유자 역할이 필요합니다.

## 그룹 클러스터 나열 {#list-group-clusters}

지정된 그룹에 대한 모든 그룹 클러스터를 나열합니다.

```plaintext
GET /groups/:id/clusters
```

매개변수:

| 속성 | 유형           | 필수 | 설명                                                                   |
| --------- | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters"
```

예시 응답:

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

## 그룹 클러스터 검색 {#retrieve-a-group-cluster}

지정된 그룹 클러스터를 검색합니다.

```plaintext
GET /groups/:id/clusters/:cluster_id
```

매개변수:

| 속성    | 유형           | 필수 | 설명                                                                   |
| ------------ | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`         | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `cluster_id` | 정수        | 예      | 클러스터의 ID                                                         |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters/18"
```

예시 응답:

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

## 그룹 클러스터 생성 {#create-a-group-cluster}

기존 Kubernetes 클러스터를 추가하여 지정된 그룹에 대한 그룹 클러스터를 생성합니다.

```plaintext
POST /groups/:id/clusters/user
```

매개변수:

| 속성                                            | 유형           | 필수 | 설명                                                                                         |
| ---------------------------------------------------- | -------------- | -------- | --------------------------------------------------------------------------------------------------- |
| `id`                                                 | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)                       |
| `name`                                               | 문자열         | 예      | 클러스터의 이름                                                                             |
| `domain`                                             | 문자열         | 아니요       | 클러스터의 [기본 도메인](../user/group/clusters/_index.md#base-domain)                       |
| `management_project_id`                              | 정수        | 아니요       | 클러스터의 [관리 프로젝트](../user/clusters/management_project.md)의 ID          |
| `enabled`                                            | 부울        | 아니요       | 클러스터이 활성 상태인지 여부를 결정하고 기본값은 `true`                                            |
| `managed`                                            | 부울        | 아니요       | GitLab이 이 클러스터에 대한 네임스페이스 및 서비스 계정을 관리하는지 여부를 결정합니다. 기본값은 `true` |
| `platform_kubernetes_attributes[api_url]`            | 문자열         | 예      | Kubernetes API에 액세스할 URL                                                                |
| `platform_kubernetes_attributes[token]`              | 문자열         | 예      | Kubernetes에 대해 인증할 토큰                                                        |
| `platform_kubernetes_attributes[ca_cert]`            | 문자열         | 아니요       | TLS 인증서. API가 자체 서명된 TLS 인증서를 사용하는 경우 필수입니다.                            |
| `platform_kubernetes_attributes[authorization_type]` | 문자열         | 아니요       | 클러스터 권한 부여 유형: `rbac`, `abac` 또는 `unknown_authorization`. 기본값은 `rbac`.      |
| `environment_scope`                                  | 문자열         | 아니요       | 클러스터와 연결된 환경. 기본값은 `*`. 프리미엄 및 얼티밋만 해당.              |

요청 예시:

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

예시 응답:

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

## 그룹 클러스터 업데이트 {#update-a-group-cluster}

지정된 그룹 클러스터를 업데이트합니다.

```plaintext
PUT /groups/:id/clusters/:cluster_id
```

매개변수:

| 속성                                 | 유형           | 필수 | 설명                                                                                |
| ----------------------------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------ |
| `id`                                      | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths)              |
| `cluster_id`                              | 정수        | 예      | 클러스터의 ID                                                                      |
| `name`                                    | 문자열         | 아니요       | 클러스터의 이름                                                                    |
| `domain`                                  | 문자열         | 아니요       | 클러스터의 [기본 도메인](../user/group/clusters/_index.md#base-domain)              |
| `management_project_id`                   | 정수        | 아니요       | 클러스터의 [관리 프로젝트](../user/clusters/management_project.md)의 ID |
| `enabled`                                 | 부울        | 아니요       | 클러스터가 활성 상태인지 여부를 결정합니다                                                     |
| `managed`                                 | 부울        | 아니요       | GitLab이 이 클러스터에 대한 네임스페이스 및 서비스 계정을 관리하는지 여부를 결정합니다          |
| `platform_kubernetes_attributes[api_url]` | 문자열         | 아니요       | Kubernetes API에 액세스할 URL                                                       |
| `platform_kubernetes_attributes[token]`   | 문자열         | 아니요       | Kubernetes에 대해 인증할 토큰                                               |
| `platform_kubernetes_attributes[ca_cert]` | 문자열         | 아니요       | TLS 인증서. API가 자체 서명된 TLS 인증서를 사용하는 경우 필수입니다.                   |
| `environment_scope`                       | 문자열         | 아니요       | 클러스터와 연결된 환경. 프리미엄 및 얼티밋만 해당.                      |

> [!note]
> `name`, `api_url`, `ca_cert` 및 `token`은 ["기존 Kubernetes 클러스터 추가"](../user/project/clusters/add_existing_cluster.md) 옵션 또는 ["그룹 클러스터 생성"](#create-a-group-cluster) 엔드포인트를 통해 클러스터가 추가된 경우에만 업데이트할 수 있습니다.

요청 예시:

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

예시 응답:

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

## 그룹 클러스터 삭제 {#delete-a-group-cluster}

지정된 그룹 클러스터를 삭제합니다. 연결된 Kubernetes 클러스터 내의 기존 리소스를 제거하지 않습니다.

```plaintext
DELETE /groups/:id/clusters/:cluster_id
```

매개변수:

| 속성    | 유형           | 필수 | 설명                                                                   |
| ------------ | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`         | 정수 또는 문자열 | 예      | 그룹의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `cluster_id` | 정수        | 예      | 클러스터의 ID                                                         |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters/23"
```
