---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: KubernetesエージェントAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- エージェントトークンAPIは、GitLab 15.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)。

{{< /history >}}

このAPIを使用して、[Kubernetes向けGitLabエージェント](../user/clusters/agent/_index.md)を操作します。

## プロジェクトのエージェントをリスト表示します {#list-the-agents-for-a-project}

プロジェクトに登録されているエージェントのリストを返します。

このエンドポイントを使用するには、デベロッパーロール以上が必要です。

```plaintext
GET /projects/:id/cluster_agents
```

パラメータは以下のとおりです:

| 属性 | 型              | 必須  | 説明                                                                                                     |
|-----------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい       | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |

応答:

レスポンスは、次のフィールドを持つエージェントのリストです:

| 属性                            | 型     | 説明                                          |
|--------------------------------------|----------|------------------------------------------------------|
| `id`                                 | 整数  | エージェントのID                                      |
| `name`                               | 文字列   | エージェントの名前                                    |
| `config_project`                     | オブジェクト   | エージェントが属するプロジェクトを表すオブジェクト |
| `config_project.id`                  | 整数  | プロジェクトのID。                                    |
| `config_project.description`         | 文字列   | プロジェクトの説明。                           |
| `config_project.name`                | 文字列   | プロジェクトの名前。                                  |
| `config_project.name_with_namespace` | 文字列   | プロジェクトのネームスペースを含むフルネーム              |
| `config_project.path`                | 文字列   | プロジェクトへのパス                                  |
| `config_project.path_with_namespace` | 文字列   | プロジェクトへのネームスペースを含むフルパス              |
| `config_project.created_at`          | 文字列   | プロジェクトが作成されたときのISO8601の日時        |
| `created_at`                         | 文字列   | エージェントが作成されたときのISO8601の日時          |
| `created_by_user_id`                 | 整数  | エージェントを作成したユーザーのID                 |

リクエスト例:

```shell
curl \
  --header "Private-Token: <your_access_token>" \
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

## エージェントの詳細を取得 {#get-details-about-an-agent}

単一のエージェントの詳細を取得します。

このエンドポイントを使用するには、デベロッパーロール以上が必要です。

```plaintext
GET /projects/:id/cluster_agents/:agent_id
```

パラメータは以下のとおりです:

| 属性  | 型              | 必須 | 説明                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい      | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |
| `agent_id` | 整数           | はい      | エージェントのID                                                                                                 |

応答:

レスポンスは、次のフィールドを持つ単一のエージェントです:

| 属性                            | 型    | 説明                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | 整数 | エージェントのID                                      |
| `name`                               | 文字列  | エージェントの名前                                    |
| `config_project`                     | オブジェクト  | エージェントが属するプロジェクトを表すオブジェクト |
| `config_project.id`                  | 整数 | プロジェクトのID。                                    |
| `config_project.description`         | 文字列  | プロジェクトの説明。                           |
| `config_project.name`                | 文字列  | プロジェクトの名前。                                  |
| `config_project.name_with_namespace` | 文字列  | プロジェクトのネームスペースを含むフルネーム              |
| `config_project.path`                | 文字列  | プロジェクトへのパス                                  |
| `config_project.path_with_namespace` | 文字列  | プロジェクトへのネームスペースを含むフルパス              |
| `config_project.created_at`          | 文字列  | プロジェクトが作成されたときのISO8601の日時        |
| `created_at`                         | 文字列  | エージェントが作成されたときのISO8601の日時          |
| `created_by_user_id`                 | 整数 | エージェントを作成したユーザーのID                 |

リクエスト例:

```shell
curl \
  --header "Private-Token: <your_access_token>" \
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

## プロジェクトにエージェントを登録 {#register-an-agent-with-a-project}

プロジェクトにエージェントを登録します。

このエンドポイントを使用するには、少なくともメンテナーのロールが必要です。

```plaintext
POST /projects/:id/cluster_agents
```

パラメータは以下のとおりです:

| 属性 | 型              | 必須 | 説明                                                                                                     |
|-----------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい      | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列            | はい      | エージェントの名前。                                                                                              |

応答:

レスポンスは、次のフィールドを持つ新しいエージェントです:

| 属性                            | 型    | 説明                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | 整数 | エージェントのID                                      |
| `name`                               | 文字列  | エージェントの名前                                    |
| `config_project`                     | オブジェクト  | エージェントが属するプロジェクトを表すオブジェクト |
| `config_project.id`                  | 整数 | プロジェクトのID。                                    |
| `config_project.description`         | 文字列  | プロジェクトの説明。                           |
| `config_project.name`                | 文字列  | プロジェクトの名前。                                  |
| `config_project.name_with_namespace` | 文字列  | プロジェクトのネームスペースを含むフルネーム              |
| `config_project.path`                | 文字列  | プロジェクトへのパス                                  |
| `config_project.path_with_namespace` | 文字列  | プロジェクトへのネームスペースを含むフルパス              |
| `config_project.created_at`          | 文字列  | プロジェクトが作成されたときのISO8601の日時        |
| `created_at`                         | 文字列  | エージェントが作成されたときのISO8601の日時          |
| `created_by_user_id`                 | 整数 | エージェントを作成したユーザーのID                 |

リクエスト例:

```shell
curl --request POST \
  --header "Private-Token: <your_access_token>" \
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

## 登録されたエージェントを削除 {#delete-a-registered-agent}

既存のエージェント登録を削除します。

このエンドポイントを使用するには、少なくともメンテナーのロールが必要です。

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id
```

パラメータは以下のとおりです:

| 属性  | 型              | 必須 | 説明                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい      | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |
| `agent_id` | 整数           | はい      | エージェントのID                                                                                                 |

リクエスト例:

```shell
curl --request DELETE \
  --header "Private-Token: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1"
```

## エージェントのトークンをリスト表示 {#list-tokens-for-an-agent}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)されました。

{{< /history >}}

エージェントのアクティブなトークンのリストを返します。

このエンドポイントを使用するには、デベロッパーロール以上が必要です。

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens
```

サポートされている属性は以下のとおりです:

| 属性  | 型              | 必須  | 説明                                                                                                      |
|------------|-------------------|-----------|------------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい       | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |
| `agent_id` | 整数または文字列 | はい       | エージェントのID。                                                                                                 |

応答:

レスポンスは、次のフィールドを持つトークンのリストです:

| 属性            | 型           | 説明                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 整数        | トークンのID。                                                  |
| `name`               | 文字列         | トークンの名前。                                                |
| `description`        | 文字列またはNULL | トークンの説明。                                         |
| `agent_id`           | 整数        | トークンが属するエージェントのID。                             |
| `status`             | 文字列         | トークンのステータス。有効な値は`active`と`revoked`です。 |
| `created_at`         | 文字列         | トークンが作成されたときのISO8601の日時。                      |
| `created_by_user_id` | 文字列         | トークンを作成したユーザーのユーザーID。                        |

リクエスト例:

```shell
curl \
  --header "Private-Token: <your_access_token>" \
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

{{< alert type="note" >}}

トークンの`last_used_at`フィールドは、単一のエージェントトークンを取得するときにのみ返されます。

{{< /alert >}}

## 単一のエージェントトークンを取得 {#get-a-single-agent-token}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)されました。

{{< /history >}}

単一のエージェントトークンを取得します。

このエンドポイントを使用するには、デベロッパーロール以上が必要です。

エージェントトークンが失効された場合、`404`を返します。

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

サポートされている属性は以下のとおりです:

| 属性  | 型              | 必須 | 説明                                                                                                       |
|------------|-------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい      | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。  |
| `agent_id` | 整数           | はい      | エージェントのID。                                                                                                  |
| `token_id` | 整数           | はい      | トークンのID。                                                                                                  |

応答:

レスポンスは、次のフィールドを持つ単一のトークンです:

| 属性            | 型           | 説明                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 整数        | トークンのID。                                                  |
| `name`               | 文字列         | トークンの名前。                                                |
| `description`        | 文字列またはNULL | トークンの説明。                                         |
| `agent_id`           | 整数        | トークンが属するエージェントのID。                             |
| `status`             | 文字列         | トークンのステータス。有効な値は`active`と`revoked`です。 |
| `created_at`         | 文字列         | トークンが作成されたときのISO8601の日時。                      |
| `created_by_user_id` | 文字列         | トークンを作成したユーザーのユーザーID。                        |
| `last_used_at`       | 文字列またはNULL | トークンが最後に使用されたときのISO8601の日時。                    |

リクエスト例:

```shell
curl \
  --header "Private-Token: <your_access_token>" \
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

## エージェントトークンを作成 {#create-an-agent-token}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/347046)されました。
- 2トークン制限は、`cluster_agents_limit_tokens_created`という名前の[フラグ](../administration/feature_flags/_index.md)を使用して、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/361030/)されました。
- 2トークン制限は、GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/412399)されています。機能フラグ`cluster_agents_limit_tokens_created`は削除されました。

{{< /history >}}

エージェントの新しいトークンを作成します。

このエンドポイントを使用するには、少なくともメンテナーのロールが必要です。

1つのエージェントが持つことができるアクティブなトークンは2つだけです。

```plaintext
POST /projects/:id/cluster_agents/:agent_id/tokens
```

サポートされている属性は以下のとおりです:

| 属性     | 型              | 必須 | 説明                                                                                                      |
|---------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |
| `agent_id`    | 整数           | はい      | エージェントのID。                                                                                                 |
| `name`        | 文字列            | はい      | トークンの名前。                                                                                              |
| `description` | 文字列            | いいえ       | トークンの説明。                                                                                       |

応答:

レスポンスは、次のフィールドを持つ新しいトークンです:

| 属性            | 型           | 説明                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | 整数        | トークンのID。                                                  |
| `name`               | 文字列         | トークンの名前。                                                |
| `description`        | 文字列またはNULL | トークンの説明。                                         |
| `agent_id`           | 整数        | トークンが属するエージェントのID。                             |
| `status`             | 文字列         | トークンのステータス。有効な値は`active`と`revoked`です。 |
| `created_at`         | 文字列         | トークンが作成されたときのISO8601の日時。                      |
| `created_by_user_id` | 文字列         | トークンを作成したユーザーのユーザーID。                        |
| `last_used_at`       | 文字列またはNULL | トークンが最後に使用されたときのISO8601の日時。                    |
| `token`              | 文字列         | シークレットトークンの値。                                           |

{{< alert type="note" >}}

`token`は`POST`エンドポイントのレスポンスでのみ返され、後で取得することはできません。

{{< /alert >}}

リクエスト例:

```shell
curl --request POST \
  --header "Private-Token: <your_access_token>" \
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

エージェントのトークンを失効します。

このエンドポイントを使用するには、少なくともメンテナーのロールが必要です。

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

サポートされている属性は以下のとおりです:

| 属性 | タイプ | 必須 | 説明 | |------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------- -| | `id` | 整数または文字列 | はい | が管理する[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)のID。 | | `agent_id` | 整数 | はい | エージェントのID。 | | `token_id` | 整数 | はい | トークンのID。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "Private-Token: <your_access_token>" \
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

### 受容エージェントのURL設定をリスト表示 {#list-url-configurations-for-a-receptive-agent}

エージェントのURL設定のリストを返します。

このエンドポイントを使用するには、デベロッパーロール以上が必要です。

```plaintext
GET /projects/:id/cluster_agents/:agent_id/url_configurations
```

サポートされている属性は以下のとおりです:

| 属性  | 型              | 必須  | 説明                                                                                                           |
|------------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`       | 整数または文字列 | はい       | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |
| `agent_id` | 整数または文字列 | はい       | エージェントのID。                                                                                                      |

応答:

レスポンスは、次のフィールドを持つURL設定のリストです:

| 属性            | 型           | 説明                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 整数        | URL構成のID。                                                |
| `agent_id`           | 整数        | URL設定が属するエージェントのID。                           |
| `url`                | 文字列         | このURL設定のURL。                                             |
| `public_key`         | 文字列         | （オプション）JWT認証が使用されている場合、Base64エンコードされた公開キー。         |
| `client_cert`        | 文字列         | （オプション）mTLS認証が使用されている場合は、PEM形式のクライアント証明書。 |
| `ca_cert`            | 文字列         | （オプション）エージェントのエンドポイントを検証するための、PEM形式のCA証明書。       |
| `tls_host`           | 文字列         | エージェントのエンドポイント証明書のサーバー名を検証するためのTLSホスト名（オプション）。       |

リクエスト例:

```shell
curl \
  --header "Private-Token: <your_access_token>" \
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

{{< alert type="note" >}}

`public_key`または`client_cert`のどちらかが設定されていますが、両方が設定されることはありません。

{{< /alert >}}

### 単一のエージェントのURL設定を取得 {#get-a-single-agent-url-configuration}

単一のエージェントのURL設定を取得します。

このエンドポイントを使用するには、デベロッパーロール以上が必要です。

```plaintext
GET /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id
```

サポートされている属性は以下のとおりです:

| 属性              | 型              | 必須 | 説明                                                                                                            |
|------------------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------------|
| `id`                   | 整数または文字列 | はい      | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。  |
| `agent_id`             | 整数           | はい      | エージェントのID。                                                                                                       |
| `url_configuration_id` | 整数           | はい      | URL構成のID。                                                                                           |

応答:

レスポンスは、次のフィールドを持つ単一のURL設定です:

| 属性            | 型           | 説明                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 整数        | URL構成のID。                                                |
| `agent_id`           | 整数        | URL設定が属するエージェントのID。                           |
| `url`                | 文字列         | このURL設定のエージェントURL。                                             |
| `public_key`         | 文字列         | （オプション）JWT認証が使用されている場合、Base64エンコードされた公開キー。         |
| `client_cert`        | 文字列         | （オプション）mTLS認証が使用されている場合は、PEM形式のクライアント証明書。 |
| `ca_cert`            | 文字列         | （オプション）エージェントのエンドポイントを検証するための、PEM形式のCA証明書。       |
| `tls_host`           | 文字列         | エージェントのエンドポイント証明書のサーバー名を検証するためのTLSホスト名（オプション）。       |

リクエスト例:

```shell
curl \
  --header "Private-Token: <your_access_token>" \
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

{{< alert type="note" >}}

`public_key`または`client_cert`のどちらかが設定されていますが、両方が設定されることはありません。

{{< /alert >}}

### エージェントのURL設定を作成 {#create-an-agent-url-configuration}

エージェントの新しいURL設定を作成します。

このエンドポイントを使用するには、少なくともメンテナーのロールが必要です。

1つのエージェントが一度に持つことができるURL設定は1つのみです。

```plaintext
POST /projects/:id/cluster_agents/:agent_id/url_configurations
```

サポートされている属性は以下のとおりです:

| 属性     | 型              | 必須 | 説明                                                                                                           |
|---------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |
| `agent_id`    | 整数           | はい      | エージェントのID。                                                                                                      |
| `url`         | 文字列            | はい      | このURL設定のエージェントURL。                                                                                 |
| `client_cert` | 文字列            | いいえ       | mTLS認証を使用する場合、PEM形式のクライアント証明書。`client_key`と共に指定する必要があります。           |
| `client_key`  | 文字列            | いいえ       | mTLS認証を使用する場合、PEM形式のクライアントキー。`client_cert`と共に指定する必要があります。                  |
| `ca_cert`     | 文字列            | いいえ       | エージェントのエンドポイントを検証するための、PEM形式のCA証明書。                                                            |
| `tls_host`    | 文字列            | いいえ       | エージェントのエンドポイント証明書のサーバー名を検証するためのTLSホスト名。                                                            |

応答:

レスポンスは、次のフィールドを持つ新しいURL設定です:

| 属性            | 型           | 説明                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | 整数        | URL構成のID。                                                |
| `agent_id`           | 整数        | URL設定が属するエージェントのID。                           |
| `url`                | 文字列         | このURL設定のエージェントURL。                                             |
| `public_key`         | 文字列         | （オプション）JWT認証が使用されている場合、Base64エンコードされた公開キー。         |
| `client_cert`        | 文字列         | （オプション）mTLS認証が使用されている場合は、PEM形式のクライアント証明書。 |
| `ca_cert`            | 文字列         | （オプション）エージェントのエンドポイントを検証するための、PEM形式のCA証明書。       |
| `tls_host`           | 文字列         | エージェントのエンドポイント証明書のサーバー名を検証するためのTLSホスト名（オプション）。       |

JWTトークンでURL設定を作成するリクエストの例:

```shell
curl --request POST \
  --header "Private-Token: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations" \
  --data '{"url":"grpcs://agent.example.com:4242"}'
```

JWT認証のレスポンス例:

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "public_key": "..."
}
```

ファイル`client.pem`および`client-key.pem`からクライアント証明書とキーペアを使用してmTLS認証を使用するURL設定を作成するリクエストの例:

```shell
curl --request POST \
  --header "Private-Token: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations" \
  --data '{"url":"grpcs://agent.example.com:4242", \
           "client_cert":"'"$(awk -v ORS='\\n' '1' client.pem)"'", \
           "client_key":"'"$(awk -v ORS='\\n' '1' client-key.pem)"'"}'
```

mTLS認証のレスポンスの例:

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "client_cert": "..."
}
```

{{< alert type="note" >}}

`client_cert`と`client_key`が指定されていない場合、プライベート公開キーペアが生成され、mTLS認証の代わりにJWT認証が使用されます。

{{< /alert >}}

### エージェントのURL設定を削除 {#delete-an-agent-url-configuration}

エージェントのURL設定を削除します。

このエンドポイントを使用するには、少なくともメンテナーのロールが必要です。

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id
```

サポートされている属性は以下のとおりです:

| 属性              | 型              | 必須 | 説明                                                                                                           |
|------------------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`                   | 整数または文字列 | はい      | 認証されたユーザーが管理するプロジェクトのID、または[URLエンコードされたプロジェクトのパス](rest/_index.md#namespaced-paths)。 |
| `agent_id`             | 整数           | はい      | エージェントのID。                                                                                                      |
| `url_configuration_id` | 整数           | はい      | URL構成のID。                                                                                          |

リクエスト例:

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations/1
```
