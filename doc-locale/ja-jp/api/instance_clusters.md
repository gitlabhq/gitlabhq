---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: インスタンスクラスターAPI（証明書ベース）（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

> [!warning]
> この機能はGitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

[インスタンスレベルのKubernetesクラスター](../user/instance/clusters/_index.md)を使用すると、KubernetesクラスターをGitLabインスタンスに接続し、そのインスタンス内のすべてのプロジェクトで同じクラスターを使用できます。

ユーザーには、これらのエンドポイントを使用するための管理者アクセスが必要です。

## インスタンスクラスターを一覧表示 {#list-instance-clusters}

すべてのインスタンスクラスターを一覧表示します。

```plaintext
GET /admin/clusters
```

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters"
```

レスポンス例: 

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

## 単一のインスタンスクラスターを取得する {#retrieve-a-single-instance-cluster}

単一のインスタンスクラスターを取得する。

パラメータは以下のとおりです:

| 属性    | 型    | 必須 | 説明           |
| ------------ | ------- | -------- | --------------------- |
| `cluster_id` | 整数 | はい      | クラスターのID |

```plaintext
GET /admin/clusters/:cluster_id
```

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters/9"
```

レスポンス例: 

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

## インスタンスクラスターを作成 {#create-an-instance-cluster}

既存のKubernetesクラスターを追加してインスタンスクラスターを作成します。

```plaintext
POST /admin/clusters/add
```

パラメータは以下のとおりです:

| 属性                                            | 型    | 必須 | 説明                                                                                           |
| ---------------------------------------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------------- |
| `name`                                               | 文字列  | はい      | クラスターの名前                                                                               |
| `domain`                                             | 文字列  | いいえ       | クラスターの[ベースドメイン](../user/project/clusters/gitlab_managed_clusters.md#base-domain)                       |
| `environment_scope`                                  | 文字列  | いいえ       | クラスターに関連付けられた環境。デフォルトは`*`です。                                            |
| `management_project_id`                              | 整数 | いいえ       | クラスターの[管理プロジェクト](../user/clusters/management_project.md)のID            |
| `enabled`                                            | ブール値 | いいえ       | クラスターがアクティブであるかどうかを決定し、`true`にデフォルト設定されます。                                            |
| `managed`                                            | ブール値 | いいえ       | GitLabがこのクラスターのネームスペースとサービスアカウントを管理するかどうかを決定します。デフォルトは`true`です。 |
| `platform_kubernetes_attributes[api_url]`            | 文字列  | はい      | KubernetesAPIにアクセスするためのURL                                                                  |
| `platform_kubernetes_attributes[token]`              | 文字列  | はい      | Kubernetesに対して認証するためのトークン                                                          |
| `platform_kubernetes_attributes[ca_cert]`            | 文字列  | いいえ       | TLS証明書。APIが自己署名TLS証明書を使用している場合は必須です。                              |
| `platform_kubernetes_attributes[namespace]`          | 文字列  | いいえ       | プロジェクトに関連する一意のネームスペース                                                           |
| `platform_kubernetes_attributes[authorization_type]` | 文字列  | いいえ       | クラスターの認可タイプ: `rbac`、`abac`、または`unknown_authorization`。`rbac`がデフォルトです。        |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data '{"name":"cluster-3", "environment_scope":"production", "platform_kubernetes_attributes":{"api_url":"https://example.com", "token":"12345", "ca_cert":"-----BEGIN CERTIFICATE-----qpoeiXXZafCM0ZDJkZjM...-----END CERTIFICATE-----"}}' \
  --url "http://gitlab.example.com/api/v4/admin/clusters/add"
```

レスポンス例: 

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

## インスタンスクラスターを更新 {#update-an-instance-cluster}

既存のインスタンスクラスターを更新します。

```plaintext
PUT /admin/clusters/:cluster_id
```

パラメータは以下のとおりです:

| 属性                                   | 型    | 必須 | 説明                                                                                |
| ------------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------------ |
| `cluster_id`                                | 整数 | はい      | クラスターのID                                                                      |
| `name`                                      | 文字列  | いいえ       | クラスターの名前                                                                    |
| `domain`                                    | 文字列  | いいえ       | クラスターの[ベースドメイン](../user/project/clusters/gitlab_managed_clusters.md#base-domain)            |
| `environment_scope`                         | 文字列  | いいえ       | クラスターに関連付けられた環境                                                  |
| `management_project_id`                     | 整数 | いいえ       | クラスターの[管理プロジェクト](../user/clusters/management_project.md)のID |
| `enabled`                                   | ブール値 | いいえ       | クラスターがアクティブであるかどうかを決定します                                                     |
| `managed`                                   | ブール値 | いいえ       | GitLabがこのクラスターのネームスペースとサービスアカウントを管理するかどうかを決定します          |
| `platform_kubernetes_attributes[api_url]`   | 文字列  | いいえ       | KubernetesAPIにアクセスするためのURL                                                       |
| `platform_kubernetes_attributes[token]`     | 文字列  | いいえ       | Kubernetesに対して認証するためのトークン                                               |
| `platform_kubernetes_attributes[ca_cert]`   | 文字列  | いいえ       | TLS証明書。APIが自己署名TLS証明書を使用している場合は必須です。                   |
| `platform_kubernetes_attributes[namespace]` | 文字列  | いいえ       | プロジェクトに関連する一意のネームスペース                                                |

> [!note]
> `name`、`api_url`、`ca_cert`、および`token`は、クラスターが[既存のKubernetesクラスターを追加](../user/project/clusters/add_existing_cluster.md)オプションまたは[インスタンスクラスターを作成](#create-an-instance-cluster)エンドポイントを介して追加された場合にのみ更新できます。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name":"update-cluster-name", "platform_kubernetes_attributes":{"api_url":"https://new-example.com","token":"new-token"}}' \
  --url "http://gitlab.example.com/api/v4/admin/clusters/9"
```

レスポンス例: 

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

## インスタンスクラスターを削除 {#delete-instance-cluster}

既存のインスタンスクラスターを削除します。接続されているKubernetesクラスター内の既存のリソースは削除しません。

```plaintext
DELETE /admin/clusters/:cluster_id
```

パラメータは以下のとおりです:

| 属性    | 型    | 必須 | 説明           |
| ------------ | ------- | -------- | --------------------- |
| `cluster_id` | 整数 | はい      | クラスターのID |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/clusters/11"
```
