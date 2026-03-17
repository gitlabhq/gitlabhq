---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトクラスターAPI（証明書ベース）（非推奨）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]この機能はGitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

これらのエンドポイントを使用するには、ユーザーにはメンテナーまたはオーナーロールが必要です。

## プロジェクトクラスターのリスト {#list-project-clusters}

プロジェクトクラスターのリストを返します。

```plaintext
GET /projects/:id/clusters
```

パラメータは以下のとおりです:

| 属性 | 型    | 必須 | 説明                                           |
| --------- | ------- | -------- | ----------------------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters"
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

## 単一のプロジェクトクラスターを取得 {#get-a-single-project-cluster}

単一のプロジェクトクラスターを取得します。

```plaintext
GET /projects/:id/clusters/:cluster_id
```

パラメータは以下のとおりです:

| 属性    | 型    | 必須 | 説明                                           |
| ------------ | ------- | -------- | ----------------------------------------------------- |
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `cluster_id` | 整数 | はい      | クラスターのID                                 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters/18"
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

## 既存のクラスターをプロジェクトに追加 {#add-existing-cluster-to-project}

既存のKubernetesクラスターをプロジェクトに追加します。

```plaintext
POST /projects/:id/clusters/user
```

パラメータは以下のとおりです:

| 属性                                            | 型    | 必須 | 説明                                                                                           |
| ---------------------------------------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------------- |
| `id`                                                 | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                                                 |
| `name`                                               | 文字列  | はい      | クラスターの名前                                                                               |
| `domain`                                             | 文字列  | いいえ       | クラスターの[ベースドメイン](../user/project/clusters/gitlab_managed_clusters.md#base-domain)                       |
| `management_project_id`                              | 整数 | いいえ       | クラスターの[管理プロジェクト](../user/clusters/management_project.md)のID            |
| `enabled`                                            | ブール値 | いいえ       | クラスターがアクティブであるかどうかを決定し、`true`にデフォルト設定されます。                                            |
| `managed`                                            | ブール値 | いいえ       | GitLabがこのクラスターのネームスペースとサービスアカウントを管理するかどうかを決定します。デフォルトは`true`です。 |
| `platform_kubernetes_attributes[api_url]`            | 文字列  | はい      | KubernetesAPIにアクセスするためのURL                                                                  |
| `platform_kubernetes_attributes[token]`              | 文字列  | はい      | Kubernetesに対して認証するためのトークン                                                          |
| `platform_kubernetes_attributes[ca_cert]`            | 文字列  | いいえ       | TLS証明書。APIが自己署名TLS証明書を使用している場合は必須です。                              |
| `platform_kubernetes_attributes[namespace]`          | 文字列  | いいえ       | プロジェクトに関連する一意のネームスペース                                                           |
| `platform_kubernetes_attributes[authorization_type]` | 文字列  | いいえ       | クラスターの認可タイプ: `rbac`、`abac`、または`unknown_authorization`。`rbac`がデフォルトです。        |
| `environment_scope`                                  | 文字列  | いいえ       | クラスターに関連付けられた環境。`*`がデフォルトです。PremiumおよびUltimateのみです。                         |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --header "Content-Type:application/json" \
  --data '{"name":"cluster-5", "platform_kubernetes_attributes":{"api_url":"https://35.111.51.20","token":"12345","namespace":"cluster-5-namespace","ca_cert":"-----BEGIN CERTIFICATE-----\r\nhFiK1L61owwDQYJKoZIhvcNAQELBQAw\r\nLzEtMCsGA1UEAxMkZDA1YzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM4ZDBj\r\nMB4XDTE4MTIyNzIwMDM1MVoXDTIzMTIyNjIxMDM1MVowLzEtMCsGA1UEAxMkZDA1\r\nYzQ1YjctNzdiMS00NDY0LThjNmEtMTQ0ZDJkZjM.......-----END CERTIFICATE-----"}}' \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters/user"
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

## プロジェクトクラスターを編集 {#edit-project-cluster}

既存のプロジェクトクラスターを更新します。

```plaintext
PUT /projects/:id/clusters/:cluster_id
```

パラメータは以下のとおりです:

| 属性                                   | 型    | 必須 | 説明                                                                                |
| ------------------------------------------- | ------- | -------- | ------------------------------------------------------------------------------------------ |
| `id`                                        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                                      |
| `cluster_id`                                | 整数 | はい      | クラスターのID                                                                      |
| `name`                                      | 文字列  | いいえ       | クラスターの名前                                                                    |
| `domain`                                    | 文字列  | いいえ       | クラスターの[ベースドメイン](../user/project/clusters/gitlab_managed_clusters.md#base-domain)            |
| `management_project_id`                     | 整数 | いいえ       | クラスターの[管理プロジェクト](../user/clusters/management_project.md)のID |
| `enabled`                                   | ブール値 | いいえ       | クラスターがアクティブであるかどうかを決定します                                                     |
| `managed`                                   | ブール値 | いいえ       | GitLabがこのクラスターのネームスペースとサービスアカウントを管理するかどうかを決定します          |
| `platform_kubernetes_attributes[api_url]`   | 文字列  | いいえ       | KubernetesAPIにアクセスするためのURL                                                       |
| `platform_kubernetes_attributes[token]`     | 文字列  | いいえ       | Kubernetesに対して認証するためのトークン                                               |
| `platform_kubernetes_attributes[ca_cert]`   | 文字列  | いいえ       | TLS証明書。APIが自己署名TLS証明書を使用している場合は必須です。                   |
| `platform_kubernetes_attributes[namespace]` | 文字列  | いいえ       | プロジェクトに関連する一意のネームスペース                                                |
| `environment_scope`                         | 文字列  | いいえ       | クラスターに関連付けられた環境                                                  |

> [!note] `name`、`api_url`、`ca_cert`、および`token`は、[「Add existing Kubernetes cluster」](../user/project/clusters/add_existing_cluster.md)オプションまたは[「Add existing cluster to project」](#add-existing-cluster-to-project)エンドポイントを使用してクラスターが追加された場合にのみ更新できます。

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --data '{"name":"new-cluster-name","domain":"new-domain.com","api_url":"https://new-api-url.com"}' \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters/24"
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

## プロジェクトクラスターを削除 {#delete-project-cluster}

既存のプロジェクトクラスターを削除します。接続されているKubernetesクラスター内の既存のリソースは削除しません。

```plaintext
DELETE /projects/:id/clusters/:cluster_id
```

パラメータは以下のとおりです:

| 属性    | 型    | 必須 | 説明                                           |
| ------------ | ------- | -------- | ----------------------------------------------------- |
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `cluster_id` | 整数 | はい      | クラスターのID                                 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/26/clusters/23"
```
