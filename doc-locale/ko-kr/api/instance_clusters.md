---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 인스턴스 클러스터 API(인증서 기반) (사용 중단됨)
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!warning]
> 이 기능은 GitLab 14.5에서 [사용 중단되었습니다](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

[인스턴스 수준 Kubernetes 클러스터](../user/instance/clusters/_index.md)를 사용하면 Kubernetes 클러스터를 GitLab 인스턴스에 연결하고 인스턴스 내의 모든 프로젝트에서 동일한 클러스터를 사용할 수 있습니다.

사용자는 이 엔드포인트를 사용하려면 관리자 액세스 권한이 필요합니다.

## 인스턴스 클러스터 나열 {#list-instance-clusters}

모든 인스턴스 클러스터를 나열합니다.

```plaintext
GET /admin/clusters
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters"
```

응답 예시:

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

## 단일 인스턴스 클러스터 검색 {#retrieve-a-single-instance-cluster}

단일 인스턴스 클러스터를 검색합니다.

매개 변수:

| 특성    | 유형    | 필수 | 설명           |
| ------------ | ------- | -------- | --------------------- |
| `cluster_id` | 정수 | 예      | 클러스터의 ID |

```plaintext
GET /admin/clusters/:cluster_id
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters/9"
```

응답 예시:

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

## 인스턴스 클러스터 생성 {#create-an-instance-cluster}

기존 Kubernetes 클러스터를 추가하여 인스턴스 클러스터를 생성합니다.

```plaintext
POST /admin/clusters/add
```

매개 변수:

| 특성                                            | 유형    | 필수 | 설명                                                                                           |
| ---------------------------------------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------------- |
| `name`                                               | 문자열  | 예      | 클러스터의 이름                                                                               |
| `domain`                                             | 문자열  | 아니오       | 클러스터의 [기본 도메인](../user/project/clusters/gitlab_managed_clusters.md#base-domain)                       |
| `environment_scope`                                  | 문자열  | 아니오       | 클러스터와 관련된 환경. `*`로 기본 설정됩니다                                            |
| `management_project_id`                              | 정수 | 아니오       | 클러스터의 [관리 프로젝트](../user/clusters/management_project.md)의 ID            |
| `enabled`                                            | 부울 | 아니오       | 클러스터가 활성 상태인지 확인하며, 기본값은 `true`                                            |
| `managed`                                            | 부울 | 아니오       | GitLab이 이 클러스터의 네임스페이스 및 서비스 계정을 관리하는지 확인합니다. `true`로 기본 설정됩니다 |
| `platform_kubernetes_attributes[api_url]`            | 문자열  | 예      | Kubernetes API에 액세스할 URL                                                                  |
| `platform_kubernetes_attributes[token]`              | 문자열  | 예      | Kubernetes에 대해 인증할 토큰                                                          |
| `platform_kubernetes_attributes[ca_cert]`            | 문자열  | 아니오       | TLS 인증서. API가 자체 서명된 TLS 인증서를 사용하는 경우 필수입니다.                              |
| `platform_kubernetes_attributes[namespace]`          | 문자열  | 아니오       | 프로젝트와 관련된 고유한 네임스페이스                                                           |
| `platform_kubernetes_attributes[authorization_type]` | 문자열  | 아니오       | 클러스터 권한 부여 유형: `rbac`, `abac` 또는 `unknown_authorization`. `rbac`로 기본 설정됩니다.        |

요청 예시:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data '{"name":"cluster-3", "environment_scope":"production", "platform_kubernetes_attributes":{"api_url":"https://example.com", "token":"12345", "ca_cert":"-----BEGIN CERTIFICATE-----qpoeiXXZafCM0ZDJkZjM...-----END CERTIFICATE-----"}}' \
  --url "http://gitlab.example.com/api/v4/admin/clusters/add"
```

응답 예시:

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

## 인스턴스 클러스터 업데이트 {#update-an-instance-cluster}

기존 인스턴스 클러스터를 업데이트합니다.

```plaintext
PUT /admin/clusters/:cluster_id
```

매개 변수:

| 특성                                   | 유형    | 필수 | 설명                                                                                |
| ------------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------------ |
| `cluster_id`                                | 정수 | 예      | 클러스터의 ID                                                                      |
| `name`                                      | 문자열  | 아니오       | 클러스터의 이름                                                                    |
| `domain`                                    | 문자열  | 아니오       | 클러스터의 [기본 도메인](../user/project/clusters/gitlab_managed_clusters.md#base-domain)            |
| `environment_scope`                         | 문자열  | 아니오       | 클러스터와 관련된 환경                                                  |
| `management_project_id`                     | 정수 | 아니오       | 클러스터의 [관리 프로젝트](../user/clusters/management_project.md)의 ID |
| `enabled`                                   | 부울 | 아니오       | 클러스터가 활성 상태인지 확인합니다                                                     |
| `managed`                                   | 부울 | 아니오       | GitLab이 이 클러스터의 네임스페이스 및 서비스 계정을 관리하는지 확인합니다          |
| `platform_kubernetes_attributes[api_url]`   | 문자열  | 아니오       | Kubernetes API에 액세스할 URL                                                       |
| `platform_kubernetes_attributes[token]`     | 문자열  | 아니오       | Kubernetes에 대해 인증할 토큰                                               |
| `platform_kubernetes_attributes[ca_cert]`   | 문자열  | 아니오       | TLS 인증서. API가 자체 서명된 TLS 인증서를 사용하는 경우 필수입니다.                   |
| `platform_kubernetes_attributes[namespace]` | 문자열  | 아니오       | 프로젝트와 관련된 고유한 네임스페이스                                                |

> [!note]
> `name`, `api_url`, `ca_cert` 및 `token`는 [기존 Kubernetes 클러스터 추가](../user/project/clusters/add_existing_cluster.md) 옵션을 통해 또는 [인스턴스 클러스터 생성](#create-an-instance-cluster) 엔드포인트를 통해 클러스터를 추가한 경우에만 업데이트할 수 있습니다.

요청 예시:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name":"update-cluster-name", "platform_kubernetes_attributes":{"api_url":"https://new-example.com","token":"new-token"}}' \
  --url "http://gitlab.example.com/api/v4/admin/clusters/9"
```

응답 예시:

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

## 인스턴스 클러스터 삭제 {#delete-instance-cluster}

기존 인스턴스 클러스터를 삭제합니다. 연결된 Kubernetes 클러스터 내의 기존 리소스는 제거하지 않습니다.

```plaintext
DELETE /admin/clusters/:cluster_id
```

매개 변수:

| 특성    | 유형    | 필수 | 설명           |
| ------------ | ------- | -------- | --------------------- |
| `cluster_id` | 정수 | 예      | 클러스터의 ID |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters/11"
```
