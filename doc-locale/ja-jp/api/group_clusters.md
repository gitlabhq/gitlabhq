---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループクラスターAPI（証明書ベース）（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /alert >}}

[プロジェクトレベル](../user/project/clusters/_index.md)および[インスタンスレベル](../user/instance/clusters/_index.md)のKubernetesクラスターと同様に、グループレベルのKubernetesクラスターを使用すると、Kubernetesクラスターをグループに接続して、複数のプロジェクトで同じクラスターを使用できます。

これらのエンドポイントを使用するには、グループのメンテナーロール以上が必要です。

## グループクラスターの一覧表示 {#list-group-clusters}

グループクラスターの一覧を返します。

```plaintext
GET /groups/:id/clusters
```

パラメータは以下のとおりです:

| 属性 | 型           | 必須 | 説明                                                                   |
| --------- | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters"
```

レスポンス例:

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

## 単一グループクラスターの取得 {#get-a-single-group-cluster}

単一グループクラスターを取得します。

```plaintext
GET /groups/:id/clusters/:cluster_id
```

パラメータは以下のとおりです:

| 属性    | 型           | 必須 | 説明                                                                   |
| ------------ | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`         | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `cluster_id` | 整数        | はい      | クラスターの                                                         |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters/18"
```

レスポンス例:

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

## 既存のクラスターをグループに追加 {#add-existing-cluster-to-group}

既存のKubernetesクラスターをグループに追加します。

```plaintext
POST /groups/:id/clusters/user
```

パラメータは以下のとおりです:

| 属性                                            | 型           | 必須 | 説明                                                                                         |
| ---------------------------------------------------- | -------------- | -------- | --------------------------------------------------------------------------------------------------- |
| `id`                                                 | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                       |
| `name`                                               | 文字列         | はい      | クラスターの名前                                                                             |
| `domain`                                             | 文字列         | いいえ       | クラスターの[ベースドメイン](../user/group/clusters/_index.md#base-domain)                       |
| `management_project_id`                              | 整数        | いいえ       | クラスターの[管理プロジェクト](../user/clusters/management_project.md)の          |
| `enabled`                                            | ブール値        | いいえ       | クラスターがアクティブかどうかを決定します。`true`がデフォルトです。                                            |
| `managed`                                            | ブール値        | いいえ       | が、このクラスターのネームスペースとサービスアカウントを管理するかどうかを決定します。デフォルトは`true`です。 |
| `platform_kubernetes_attributes[api_url]`            | 文字列         | はい      | Kubernetes APIにアクセスするためのURL                                                                |
| `platform_kubernetes_attributes[token]`              | 文字列         | はい      | Kubernetesに対して認証するためのトークン                                                        |
| `platform_kubernetes_attributes[ca_cert]`            | 文字列         | いいえ       | TLS証明書。APIが自己署名TLS証明書を使用している場合に必要です。                            |
| `platform_kubernetes_attributes[authorization_type]` | 文字列         | いいえ       | クラスターの認可タイプ: `rbac`、`abac`、または`unknown_authorization`。`rbac`がデフォルトです。      |
| `environment_scope`                                  | 文字列         | いいえ       | クラスターに関連付けられた環境。`*`がデフォルトです。PremiumおよびUltimateのみです。              |

リクエスト例:

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

レスポンス例:

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

## グループクラスターの編集 {#edit-group-cluster}

既存のグループクラスターを更新します。

```plaintext
PUT /groups/:id/clusters/:cluster_id
```

パラメータは以下のとおりです:

| 属性                                 | 型           | 必須 | 説明                                                                                |
| ----------------------------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------ |
| `id`                                      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)              |
| `cluster_id`                              | 整数        | はい      | クラスターの                                                                      |
| `name`                                    | 文字列         | いいえ       | クラスターの名前                                                                    |
| `domain`                                  | 文字列         | いいえ       | クラスターの[ベースドメイン](../user/group/clusters/_index.md#base-domain)              |
| `management_project_id`                   | 整数        | いいえ       | クラスターの[管理プロジェクト](../user/clusters/management_project.md)の |
| `enabled`                                 | ブール値        | いいえ       | クラスターがアクティブかどうかを判断します                                                     |
| `managed`                                 | ブール値        | いいえ       | が、このクラスターのネームスペースとサービスアカウントを管理するかどうかを決定します          |
| `platform_kubernetes_attributes[api_url]` | 文字列         | いいえ       | Kubernetes APIにアクセスするためのURL                                                       |
| `platform_kubernetes_attributes[token]`   | 文字列         | いいえ       | Kubernetesに対して認証するためのトークン                                               |
| `platform_kubernetes_attributes[ca_cert]` | 文字列         | いいえ       | TLS証明書。APIが自己署名TLS証明書を使用している場合に必要です。                   |
| `environment_scope`                       | 文字列         | いいえ       | クラスターに関連付けられた環境。PremiumおよびUltimateのみです。                      |

{{< alert type="note" >}}

`name`、`api_url`、`ca_cert`、および`token`は、[「既存のKubernetesクラスターを追加」](../user/project/clusters/add_existing_cluster.md)オプションまたは[「既存のクラスターをグループに追加」](#add-existing-cluster-to-group)エンドポイントを介してクラスターが追加された場合にのみ更新できます。

{{< /alert >}}

リクエスト例:

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

レスポンス例:

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

## グループクラスターの削除 {#delete-group-cluster}

既存のグループクラスターを削除します。接続されているKubernetesクラスター内の既存のリソースは削除しません。

```plaintext
DELETE /groups/:id/clusters/:cluster_id
```

パラメータは以下のとおりです:

| 属性    | 型           | 必須 | 説明                                                                   |
| ------------ | -------------- | -------- | ----------------------------------------------------------------------------- |
| `id`         | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `cluster_id` | 整数        | はい      | クラスターの                                                         |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/clusters/23"
```
