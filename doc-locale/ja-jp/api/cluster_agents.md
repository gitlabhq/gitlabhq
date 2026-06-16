---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: KubernetesエージェントAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- エージェントトークンAPIはGitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)されました。

{{< /history >}}

このAPIを使用して、[Kubernetes向けGitLabエージェント](../user/clusters/agent/_index.md)と対話します。

## すべてのエージェントを一覧表示 {#list-all-agents}

プロジェクトに登録されているすべてのエージェントを一覧表示します。

このエンドポイントを使用するには、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /projects/:id/cluster_agents
```

パラメータは以下のとおりです:

| 属性 | 型              | 必須  | 説明                                                                                                     |
|-----------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい       | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths) |

レスポンス:

応答には、以下のフィールドを持つエージェントのリストが含まれます:

| 属性                            | 型     | 説明                                          |
|--------------------------------------|----------|------------------------------------------------------|
| `id`                                 | 整数  | エージェントのID                                      |
| `name`                               | 文字列   | エージェントの名前                                    |
| `config_project`                     | オブジェクト   | エージェントが属するプロジェクトを表すオブジェクト |
| `config_project.id`                  | 整数  | プロジェクトのID                                    |
| `config_project.description`         | 文字列   | プロジェクトの説明                           |
| `config_project.name`                | 文字列   | プロジェクト名                                  |
| `config_project.name_with_namespace` | 文字列   | プロジェクトのネームスペースを含む完全な名前              |
| `config_project.path`                | 文字列   | プロジェクトへのパス                                  |
| `config_project.path_with_namespace` | 文字列   | プロジェクトへのネームスペースを含む完全なパス              |
| `config_project.created_at`          | 文字列   | プロジェクトが作成されたときのISO8601日時        |
| `created_at`                         | 文字列   | エージェントが作成されたときのISO8601日時          |
| `created_by_user_id`                 | 整数  | エージェントを作成したユーザーのID                 |

リクエスト例: 

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "agent-1",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  },
  {
    "id": 2,
    "name": "agent-2",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  }
]
```

## エージェントを取得する {#retrieve-an-agent}

単一のエージェントの詳細を取得します。

このエンドポイントを使用するには、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /projects/:id/cluster_agents/:agent_id
```

パラメータは以下のとおりです:

| 属性  | 型              | 必須 | 説明                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい      | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `agent_id` | 整数           | はい      | エージェントのID                                                                                                 |

レスポンス:

応答には、以下のフィールドを持つ単一のエージェントが含まれます:

| 属性                            | 型    | 説明                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | 整数 | エージェントのID                                      |
| `name`                               | 文字列  | エージェントの名前                                    |
| `config_project`                     | オブジェクト  | エージェントが属するプロジェクトを表すオブジェクト |
| `config_project.id`                  | 整数 | プロジェクトのID                                    |
| `config_project.description`         | 文字列  | プロジェクトの説明                           |
| `config_project.name`                | 文字列  | プロジェクト名                                  |
| `config_project.name_with_namespace` | 文字列  | プロジェクトのネームスペースを含む完全な名前              |
| `config_project.path`                | 文字列  | プロジェクトへのパス                                  |
| `config_project.path_with_namespace` | 文字列  | プロジェクトへのネームスペースを含む完全なパス              |
| `config_project.created_at`          | 文字列  | プロジェクトが作成されたときのISO8601日時        |
| `created_at`                         | 文字列  | エージェントが作成されたときのISO8601日時          |
| `created_by_user_id`                 | 整数 | エージェントを作成したユーザーのID                 |

リクエスト例: 

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "agent-1",
  "config_project": {
    "id": 20,
    "description": "",
    "name": "test",
    "name_with_namespace": "Administrator / test",
    "path": "test",
    "path_with_namespace": "root/test",
    "created_at": "2022-03-20T20:42:40.221Z"
  },
  "created_at": "2022-04-20T20:42:40.221Z",
  "created_by_user_id": 42
}
```

## エージェントを作成する {#create-an-agent}

プロジェクトの新しいエージェントを作成します。

このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

```plaintext
POST /projects/:id/cluster_agents
```

パラメータは以下のとおりです:

| 属性 | 型              | 必須 | 説明                                                                                                     |
|-----------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい      | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`    | 文字列            | はい      | エージェントの名前                                                                                              |

レスポンス:

応答には、以下のフィールドを持つ新しいエージェントが含まれます:

| 属性                            | 型    | 説明                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | 整数 | エージェントのID                                      |
| `name`                               | 文字列  | エージェントの名前                                    |
| `config_project`                     | オブジェクト  | エージェントが属するプロジェクトを表すオブジェクト |
| `config_project.id`                  | 整数 | プロジェクトのID                                    |
| `config_project.description`         | 文字列  | プロジェクトの説明                           |
| `config_project.name`                | 文字列  | プロジェクト名                                  |
| `config_project.name_with_namespace` | 文字列  | プロジェクトのネームスペースを含む完全な名前              |
| `config_project.path`                | 文字列  | プロジェクトへのパス                                  |
| `config_project.path_with_namespace` | 文字列  | プロジェクトへのネームスペースを含む完全なパス              |
| `config_project.created_at`          | 文字列  | プロジェクトが作成されたときのISO8601日時        |
| `created_at`                         | 文字列  | エージェントが作成されたときのISO8601日時          |
| `created_by_user_id`                 | 整数 | エージェントを作成したユーザーのID                 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents" \
  --data '{"name":"some-agent"}'
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "agent-1",
  "config_project": {
    "id": 20,
    "description": "",
    "name": "test",
    "name_with_namespace": "Administrator / test",
    "path": "test",
    "path_with_namespace": "root/test",
    "created_at": "2022-03-20T20:42:40.221Z"
  },
  "created_at": "2022-04-20T20:42:40.221Z",
  "created_by_user_id": 42
}
```

## エージェントを削除する {#delete-an-agent}

既存のエージェント登録を削除します。

このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id
```

パラメータは以下のとおりです:

| 属性  | 型              | 必須 | 説明                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい      | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `agent_id` | 整数           | はい      | エージェントのID                                                                                                 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1"
```

## すべてのエージェントトークンを一覧表示 {#list-all-agent-tokens}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)されました。

{{< /history >}}

エージェントのすべてのアクティブなトークンを一覧表示します。

このエンドポイントを使用するには、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens
```

サポートされている属性は以下のとおりです: 

| 属性  | 型              | 必須  | 説明                                                                                                      |
|------------|-------------------|-----------|------------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい       | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `agent_id` | 整数または文字列 | はい       | エージェントのID。                                                                                                 |

レスポンス:

応答には、以下のフィールドを持つトークンのリストが含まれます:

| 属性            | 型           | 説明                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 整数        | トークンのID。                                                  |
| `name`               | 文字列         | トークンの名前。                                                |
| `description`        | stringまたはnull | トークンの説明。                                         |
| `agent_id`           | 整数        | トークンが属するエージェントのID。                             |
| `status`             | 文字列         | トークンのステータス。有効な値は`active`と`revoked`です。 |
| `created_at`         | 文字列         | トークンが作成されたときのISO8601日時。                      |
| `created_by_user_id` | 文字列         | トークンを作成したユーザーのユーザーID。                        |

リクエスト例: 

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "abcd",
    "description": "Some token",
    "agent_id": 5,
    "status": "active",
    "created_at": "2022-03-25T14:12:11.497Z",
    "created_by_user_id": 1
  },
  {
    "id": 2,
    "name": "foobar",
    "description": null,
    "agent_id": 5,
    "status": "active",
    "created_at": "2022-03-25T14:12:11.497Z",
    "created_by_user_id": 1
  }
]
```

> [!note]
> トークンの`last_used_at`フィールドは、単一のエージェントトークンを取得する場合にのみ返されます。

## エージェントトークンを取得する {#retrieve-an-agent-token}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)されました。

{{< /history >}}

単一のエージェントトークンを取得します。

このエンドポイントを使用するには、デベロッパー、メンテナー、またはオーナーロールが必要です。

エージェントトークンが失効している場合、`404`を返します。

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

サポートされている属性は以下のとおりです: 

| 属性  | 型              | 必須 | 説明                                                                                                       |
|------------|-------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい      | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `agent_id` | 整数           | はい      | エージェントのID。                                                                                                  |
| `token_id` | 整数           | はい      | トークンのID。                                                                                                  |

レスポンス:

応答には、以下のフィールドを持つ単一のトークンが含まれます:

| 属性            | 型           | 説明                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 整数        | トークンのID。                                                  |
| `name`               | 文字列         | トークンの名前。                                                |
| `description`        | stringまたはnull | トークンの説明。                                         |
| `agent_id`           | 整数        | トークンが属するエージェントのID。                             |
| `status`             | 文字列         | トークンのステータス。有効な値は`active`と`revoked`です。 |
| `created_at`         | 文字列         | トークンが作成されたときのISO8601日時。                      |
| `created_by_user_id` | 文字列         | トークンを作成したユーザーのユーザーID。                        |
| `last_used_at`       | stringまたはnull | トークンが最後に使用されたときのISO8601日時。                    |

リクエスト例: 

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/token/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "abcd",
  "description": "Some token",
  "agent_id": 5,
  "status": "active",
  "created_at": "2022-03-25T14:12:11.497Z",
  "created_by_user_id": 1,
  "last_used_at": null
}
```

## エージェントトークンを作成する {#create-an-agent-token}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)されました。
- 2つのトークン制限がGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/361030/)され、`cluster_agents_limit_tokens_created`という名前の[フラグ](../administration/feature_flags/_index.md)が付けられました。
- 2つのトークン制限はGitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/412399)されました。機能フラグ`cluster_agents_limit_tokens_created`は削除されました。

{{< /history >}}

エージェントの新しいトークンを作成します。

このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

1つのエージェントは、同時に2つのアクティブなトークンのみを持つことができます。

```plaintext
POST /projects/:id/cluster_agents/:agent_id/tokens
```

サポートされている属性は以下のとおりです: 

| 属性     | 型              | 必須 | 説明                                                                                                      |
|---------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `agent_id`    | 整数           | はい      | エージェントのID。                                                                                                 |
| `name`        | 文字列            | はい      | トークンの名前。                                                                                              |
| `description` | 文字列            | いいえ       | トークンの説明。                                                                                       |

レスポンス:

応答には、以下のフィールドを持つ新しいトークンが含まれます:

| 属性            | 型           | 説明                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 整数        | トークンのID。                                                  |
| `name`               | 文字列         | トークンの名前。                                                |
| `description`        | stringまたはnull | トークンの説明。                                         |
| `agent_id`           | 整数        | トークンが属するエージェントのID。                             |
| `status`             | 文字列         | トークンのステータス。有効な値は`active`と`revoked`です。 |
| `created_at`         | 文字列         | トークンが作成されたときのISO8601日時。                      |
| `created_by_user_id` | 文字列         | トークンを作成したユーザーのユーザーID。                        |
| `last_used_at`       | stringまたはnull | トークンが最後に使用されたときのISO8601日時。                    |
| `token`              | 文字列         | シークレットトークンの値。                                           |

> [!note]
> `token`は`POST`エンドポイントの応答でのみ返され、後から取得することはできません。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens" \
  --data '{"name":"some-token"}'
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "abcd",
  "description": "Some token",
  "agent_id": 5,
  "status": "active",
  "created_at": "2022-03-25T14:12:11.497Z",
  "created_by_user_id": 1,
  "last_used_at": null,
  "token": "qeY8UVRisx9y3Loxo1scLxFuRxYcgeX3sxsdrpP_fR3Loq4xyg"
}
```

## エージェントトークンを失効する {#revoke-an-agent-token}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)されました。

{{< /history >}}

エージェントトークンを失効します。

このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

サポートされている属性は以下のとおりです: 

サポートされている属性は以下のとおりです:

| 属性       | 型                | 必須 | 説明                                                                                                              |
|------------|-------------------|------|-------------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい  | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `agent_id` | 整数           | はい  | エージェントのID。                                                                                                |
| `token_id` | 整数           | はい  | トークンのID。                                                                                                    |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens/1"
```

## 受信エージェント {#receptive-agents}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12180)されました。

{{< /history >}}

[受容エージェント](../user/clusters/agent/_index.md#receptive-agents)を使用すると、GitLabインスタンスへのネットワーク接続を確立できないがGitLabからは接続できるKubernetesクラスターと、GitLabを統合できます。

### すべてのURL設定を一覧表示 {#list-all-url-configurations}

指定されたエージェントのすべてのURL設定を一覧表示します。

このエンドポイントを使用するには、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /projects/:id/cluster_agents/:agent_id/url_configurations
```

サポートされている属性は以下のとおりです: 

| 属性  | 型              | 必須  | 説明                                                                                                           |
|------------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい       | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `agent_id` | 整数または文字列 | はい       | エージェントのID。                                                                                                      |

レスポンス:

応答には、以下のフィールドを持つURL設定のリストが含まれます:

| 属性            | 型           | 説明                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 整数        | URL設定のID。                                                |
| `agent_id`           | 整数        | URL設定が属するエージェントのID。                           |
| `url`                | 文字列         | このURL設定のURL。                                             |
| `public_key`         | 文字列         | （オプション）JWT認証が使用される場合のBase64エンコードされた公開キー。         |
| `client_cert`        | 文字列         | （オプション）mTLS認証が使用される場合のPEM形式のクライアント証明書。 |
| `ca_cert`            | 文字列         | （オプション）エージェントエンドポイントを検証するためのPEM形式のCA証明書。       |
| `tls_host`           | 文字列         | （オプション）エージェントエンドポイントでサーバー名を検証するためのTLSホスト名。       |

リクエスト例: 

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "agent_id": 5,
    "url": "grpcs://agent.example.com:4242",
    "public_key": "..."
  }
]
```

> [!note]
> `public_key`または`client_cert`のいずれかが設定されますが、両方は設定されません。

### URL設定を取得する {#retrieve-a-url-configuration}

単一のエージェントURL設定を取得します。

このエンドポイントを使用するには、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id
```

サポートされている属性は以下のとおりです: 

| 属性              | 型              | 必須 | 説明                                                                                                            |
|------------------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------------|
| `id`                   | 整数または文字列 | はい      | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths)。  |
| `agent_id`             | 整数           | はい      | エージェントのID。                                                                                                       |
| `url_configuration_id` | 整数           | はい      | URL設定のID。                                                                                           |

レスポンス:

応答には、以下のフィールドを持つ単一のURL設定が含まれます:

| 属性            | 型           | 説明                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 整数        | URL設定のID。                                                |
| `agent_id`           | 整数        | URL設定が属するエージェントのID。                           |
| `url`                | 文字列         | このURL設定のエージェントURL。                                             |
| `public_key`         | 文字列         | （オプション）JWT認証が使用される場合のBase64エンコードされた公開キー。         |
| `client_cert`        | 文字列         | （オプション）mTLS認証が使用される場合のPEM形式のクライアント証明書。 |
| `ca_cert`            | 文字列         | （オプション）エージェントエンドポイントを検証するためのPEM形式のCA証明書。       |
| `tls_host`           | 文字列         | （オプション）エージェントエンドポイントでサーバー名を検証するためのTLSホスト名。       |

リクエスト例: 

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "public_key": "..."
}
```

> [!note]
> `public_key`または`client_cert`のいずれかが設定されますが、両方は設定されません。

### URL設定を作成する {#create-a-url-configuration}

エージェントの新しいURL設定を作成します。

このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

1つのエージェントは、同時に1つのURL設定のみを持つことができます。

```plaintext
POST /projects/:id/cluster_agents/:agent_id/url_configurations
```

サポートされている属性は以下のとおりです: 

| 属性     | 型              | 必須 | 説明                                                                                                           |
|---------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `agent_id`    | 整数           | はい      | エージェントのID。                                                                                                      |
| `url`         | 文字列            | はい      | このURL設定のエージェントURL。                                                                                 |
| `client_cert` | 文字列            | いいえ       | mTLS認証を使用する場合のPEM形式のクライアント証明書。`client_key`と共に指定する必要があります。           |
| `client_key`  | 文字列            | いいえ       | mTLS認証を使用する場合のPEM形式のクライアントキー。`client_cert`と共に指定する必要があります。                  |
| `ca_cert`     | 文字列            | いいえ       | エージェントエンドポイントを検証するためのPEM形式のCA証明書。                                                            |
| `tls_host`    | 文字列            | いいえ       | エージェントエンドポイントでサーバー名を検証するためのTLSホスト名。                                                            |

レスポンス:

応答には、以下のフィールドを持つ新しいURL設定が含まれます:

| 属性            | 型           | 説明                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 整数        | URL設定のID。                                                |
| `agent_id`           | 整数        | URL設定が属するエージェントのID。                           |
| `url`                | 文字列         | このURL設定のエージェントURL。                                             |
| `public_key`         | 文字列         | （オプション）JWT認証が使用される場合のBase64エンコードされた公開キー。         |
| `client_cert`        | 文字列         | （オプション）mTLS認証が使用される場合のPEM形式のクライアント証明書。 |
| `ca_cert`            | 文字列         | （オプション）エージェントエンドポイントを検証するためのPEM形式のCA証明書。       |
| `tls_host`           | 文字列         | （オプション）エージェントエンドポイントでサーバー名を検証するためのTLSホスト名。       |

JWTトークンでURL設定を作成する例のリクエスト:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations" \
  --data '{"url":"grpcs://agent.example.com:4242"}'
```

JWT認証の応答例:

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "public_key": "..."
}
```

mTLSを使用して、`client.pem`および`client-key.pem`ファイルからのクライアント証明書とキーでURL設定を作成する例のリクエスト:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations" \
  --data '{"url":"grpcs://agent.example.com:4242", \
           "client_cert":"'"$(awk -v ORS='\\n' '1' client.pem)"'", \
           "client_key":"'"$(awk -v ORS='\\n' '1' client-key.pem)"'"}'
```

mTLSの応答例:

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "client_cert": "..."
}
```

> [!note]
> `client_cert`と`client_key`が提供されない場合、秘密鍵と公開鍵のキーペアが生成され、mTLSの代わりにJWT認証が使用されます。

### URL設定を削除する {#delete-a-url-configuration}

エージェントのURL設定を削除します。

このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id
```

サポートされている属性は以下のとおりです: 

| 属性              | 型              | 必須 | 説明                                                                                                           |
|------------------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`                   | 整数または文字列 | はい      | 認証済みユーザーによって維持されるIDまたは[プロジェクトのURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `agent_id`             | 整数           | はい      | エージェントのID。                                                                                                      |
| `url_configuration_id` | 整数           | はい      | URL設定のID。                                                                                          |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations/1
```
