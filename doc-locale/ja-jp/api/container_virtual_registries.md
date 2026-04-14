---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コンテナ仮想レジストリAPI
description: コンテナレジストリの仮想レジストリを作成および管理し、アップストリームコンテナレジストリを構成します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.5で`container_virtual_registries`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/548794)されました。デフォルトでは無効になっています。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631)：GitLab 18.9で実験からベータに変わりました。

{{< /history >}}

> [!flag] 
> これらのエンドポイントの利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

このAPIを使用して、以下を行います:

- コンテナレジストリの仮想レジストリを作成および管理します。
- アップストリームコンテナレジストリを構成します。
- キャッシュされたコンテナイメージとマニフェストを管理します。

仮想レジストリを介したコンテナイメージのプルに関する情報は、[コンテナ仮想レジストリ](../user/packages/virtual_registry/container/_index.md)を参照してください。

> [!note]
> クラウドプロバイダーレジストリはサポートされていませんが、[issue 20919](https://gitlab.com/groups/gitlab-org/-/work_items/20919)でこの動作を変更することが提案されています。

## 仮想レジストリを管理する {#manage-virtual-registries}

次のエンドポイントを使用して、コンテナレジストリの仮想レジストリを作成および管理します。

### すべての仮想レジストリをリストする {#list-all-virtual-registries}

グループのすべてのコンテナ仮想レジストリを一覧表示します。

```plaintext
GET /groups/:id/-/virtual_registries/container/registries
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列または整数 | はい | グループIDまたはグループのフルパス。トップレベルグループである必要があります。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/registries"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "group_id": 5,
    "name": "my-container-virtual-registry",
    "description": "My container virtual registry",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### 仮想レジストリを作成する {#create-a-virtual-registry}

グループのコンテナ仮想レジストリを作成します。

```plaintext
POST /groups/:id/-/virtual_registries/container/registries
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列または整数 | はい | グループIDまたはグループのフルパス。トップレベルグループである必要があります。 |
| `name` | 文字列 | はい | 仮想レジストリの名前。 |
| `description` | 文字列 | いいえ | 仮想レジストリの説明。 |

> [!note]
> グループごとに最大5つの仮想レジストリを作成できます。

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"name": "my-container-virtual-registry", "description": "My container virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/registries"
```

レスポンス例: 

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-container-virtual-registry",
  "description": "My container virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 仮想レジストリを取得する {#retrieve-a-virtual-registry}

指定されたコンテナ仮想レジストリを取得します。

```plaintext
GET /virtual_registries/container/registries/:id
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | コンテナ仮想レジストリのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-container-virtual-registry",
  "description": "My container virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstreams": [
    {
      "id": 2,
      "position": 1,
      "upstream_id": 2
    }
  ]
}
```

### 仮想レジストリを更新する {#update-a-virtual-registry}

指定されたコンテナ仮想レジストリを更新します。

```plaintext
PATCH /virtual_registries/container/registries/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | コンテナ仮想レジストリのID。 |
| `description` | 文字列 | いいえ | 仮想レジストリの説明。 |
| `name` | 文字列 | いいえ | 仮想レジストリの名前。 |

> [!note]
> リクエストには、オプションのパラメータ（`name`または`description`）の少なくとも1つを指定する必要があります。

リクエスト例: 

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"name": "my-container-virtual-registry", "description": "My container virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### 仮想レジストリを削除する {#delete-a-virtual-registry}

> [!warning]
> 仮想レジストリを削除すると、他の仮想レジストリと共有されていない、関連付けられているすべてのアップストリームレジストリと、キャッシュされたコンテナイメージとマニフェストも削除されます。

指定されたコンテナ仮想レジストリを削除します。

```plaintext
DELETE /virtual_registries/container/registries/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | コンテナ仮想レジストリのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### 仮想レジストリのキャッシュエントリを削除する {#delete-cache-entries-for-a-virtual-registry}

{{< history >}}

- GitLab 18.7で`container_virtual_registries`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538327)されました。デフォルトでは無効になっています。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631)：GitLab 18.9で実験からベータに変わりました。

{{< /history >}}

コンテナ仮想レジストリのすべての排他的なアップストリームレジストリのすべてのキャッシュエントリを削除するようにスケジュールします。キャッシュエントリは、他の仮想レジストリに関連付けられているアップストリームレジストリに対して削除するようにスケジュールされていません。

```plaintext
DELETE /virtual_registries/container/registries/:id/cache
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | コンテナ仮想レジストリのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/cache"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

## アップストリームレジストリを管理する {#manage-upstream-registries}

次のエンドポイントを使用して、アップストリームコンテナレジストリを設定および管理します。

### トップレベルグループのすべてのアップストリームレジストリをリストする {#list-all-upstream-registries-for-a-top-level-group}

トップレベルグループのすべてのアップストリームコンテナレジストリをリストします。

```plaintext
GET /groups/:id/-/virtual_registries/container/upstreams
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列または整数 | はい | グループIDまたはグループのフルパス。トップレベルグループである必要があります。 |
| `page` | 整数 | いいえ | ページ番号。デフォルトは1です。 |
| `per_page` | 整数 | いいえ | ページあたりのアイテム数。デフォルトは20です。 |
| `upstream_name` | 文字列 | いいえ | 名前によるあいまい検索フィルタリングを行うためのアップストリームレジストリの名前。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/upstreams"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://registry-1.docker.io",
    "name": "Docker Hub",
    "description": "Docker Hub registry",
    "cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### アップストリームレジストリを作成する前に接続をテストする {#test-connection-before-creating-an-upstream-registry}

{{< history >}}

- GitLab 18.9で`container_virtual_registries`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578679)されました。デフォルトでは無効になっています。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631)：GitLab 18.9で実験からベータに変わりました。

{{< /history >}}

まだ仮想レジストリに追加されていないコンテナアップストリームレジストリへの接続をテストします。このエンドポイントは、アップストリームレジストリを作成する前に、接続と認証情報を検証します。

```plaintext
POST /groups/:id/-/virtual_registries/container/upstreams/test
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列または整数 | はい | グループIDまたはグループのフルパス。トップレベルグループである必要があります。 |
| `url` | 文字列 | はい | アップストリームレジストリのURL。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |

> [!note] 
> `username`と`password`の両方をリクエストに含めるか、どちらも含めない必要があります。設定されていない場合、パブリック（匿名）リクエストを使用してアップストリームにアクセスします。

#### テストワークフロー {#test-workflow}

`test`エンドポイントは、接続と認証を検証するために、テストパスを使用して、指定されたアップストリームURLにHEADリクエストを送信します。HEADリクエストから受信したレスポンスは、次のように解釈されます:

| アップストリームレスポンス | 説明 | 結果 |
|:------------------|:--------|:-------|
| 2XX | 成功。アップストリームアクセス可能 | `{ "success": true }` |
| 404 | 成功。アップストリームはアクセス可能ですが、テストアーティファクトが見つかりません | `{ "success": true }` |
| 401 | 認証に失敗しました | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | アクセスが禁止されました | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | アップストリームサーバーエラー | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| ネットワークエラー | 接続/タイムアウトの問題 | `{ "success": false, "result": "Error: Connection timeout" }` |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/container/upstreams/test"
     --data '{"url": "https://registry-1.docker.io", "username": "<your_username>", "password": "<your_password>"}' \
```

レスポンス例: 

```json
{
  "success": true
}
```

> [!note]
> アップストリームレジストリからの`2XX`（検出）および`404 Not Found` HTTPステータスコードは、アップストリームに到達可能で、適切に構成されていることを示すため、成功した応答と見なされます。

### 仮想レジストリのすべてのアップストリームレジストリを一覧表示 {#list-all-upstream-registries-for-a-virtual-registry}

コンテナ仮想レジストリのすべてのアップストリームレジストリをリストします。

```plaintext
GET /virtual_registries/container/registries/:id/upstreams
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 整数 | はい | コンテナ仮想レジストリのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/upstreams"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://registry-1.docker.io",
    "name": "Docker Hub",
    "description": "Docker Hub registry",
    "cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "registry_upstream": {
      "id": 1,
      "registry_id": 1,
      "position": 1
    }
  }
]
```

### アップストリームレジストリを作成する {#create-an-upstream-registry}

指定されたコンテナ仮想レジストリのアップストリームコンテナレジストリを作成します。

```plaintext
POST /virtual_registries/container/registries/:id/upstreams
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | コンテナ仮想レジストリのID。 |
| `url` | 文字列 | はい | アップストリームコンテナレジストリのURL。 |
| `name` | 文字列 | はい | アップストリームレジストリの名前。 |
| `cache_validity_hours` | 整数 | いいえ | コンテナイメージのキャッシュの有効期間。デフォルトは24時間です。 |
| `description` | 文字列 | いいえ | アップストリームレジストリの説明。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |

> [!note] 
> `username`と`password`の両方をリクエストに含めるか、まったく含めないかのいずれかにする必要があります。設定されていない場合、パブリック（匿名）リクエストを使用してアップストリームにアクセスします。

同じURLと認証情報（`username`と`password`）を持つ2つのアップストリームを同じトップレベルグループに追加することはできません。代わりに、次のいずれかを実行できます。

- 同じURLを持つ各アップストリームに異なる認証情報を設定します。
- 複数の仮想レジストリとアップストリームを関連付けます。

> [!note]
> 各仮想レジストリには最大5つのアップストリームレジストリを追加できます。

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io", "name": "Docker Hub", "description": "Docker Hub registry", "username": "<your_username>", "password": "<your_password>", "cache_validity_hours": 48}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registries/1/upstreams"
```

レスポンス例: 

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://registry-1.docker.io",
  "name": "Docker Hub",
  "description": "Docker Hub registry",
  "cache_validity_hours": 48,
  "username": "user",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstream": {
    "id": 1,
    "registry_id": 1,
    "position": 1
  }
}
```

### アップストリームレジストリを取得する {#retrieve-an-upstream-registry}

指定されたアップストリームコンテナレジストリを取得します。

```plaintext
GET /virtual_registries/container/upstreams/:id
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://registry-1.docker.io",
  "name": "Docker Hub",
  "description": "Docker Hub registry",
  "cache_validity_hours": 24,
  "username": "user",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z",
  "registry_upstreams": [
    {
      "id": 1,
      "registry_id": 1,
      "position": 1
    }
  ]
}
```

### アップストリームレジストリを更新する {#update-an-upstream-registry}

指定されたアップストリームコンテナレジストリを更新します。

```plaintext
PATCH /virtual_registries/container/upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `cache_validity_hours` | 整数 | いいえ | コンテナイメージのキャッシュの有効期間。デフォルトは24時間です。 |
| `description` | 文字列 | いいえ | アップストリームレジストリの説明。 |
| `name` | 文字列 | いいえ | アップストリームレジストリの名前。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |
| `url` | 文字列 | いいえ | アップストリームレジストリのURL。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |

> [!note] 
> リクエストにオプションのパラメータを少なくとも1つ指定する必要があります。
>
> `username`と`password`は、一緒に指定するか、まったく指定しない必要があります。設定されていない場合、パブリック（匿名）リクエストを使用してアップストリームにアクセスします。

リクエスト例: 

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリの位置を更新する {#update-an-upstream-registry-position}

コンテナ仮想レジストリの順序付けられたリストで、アップストリームコンテナレジストリの位置を更新します。

```plaintext
PATCH /virtual_registries/container/registry_upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリの関連付けのID。 |
| `position` | 整数 | はい | アップストリームレジストリの位置。1～20の間。 |

リクエスト例: 

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams/1"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリを削除する {#delete-an-upstream-registry}

指定されたアップストリームコンテナレジストリを削除します。

```plaintext
DELETE /virtual_registries/container/upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### レジストリとアップストリームを関連付ける {#associate-an-upstream-with-a-registry}

指定されたアップストリームコンテナレジストリを、指定されたコンテナ仮想レジストリに関連付けます。

```plaintext
POST /virtual_registries/container/registry_upstreams
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `registry_id` | 整数 | はい | コンテナ仮想レジストリのID。 |
| `upstream_id` | 整数 | はい | コンテナアップストリームレジストリのID。 |

> [!note]
> 各仮想レジストリには最大5つのアップストリームレジストリを関連付けることができます。

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"registry_id": 1, "upstream_id": 2}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams"
```

レスポンス例: 

```json
{
  "id": 5,
  "registry_id": 1,
  "upstream_id": 2,
  "position": 2
}
```

### レジストリからアップストリームの関連付けを解除する {#disassociate-an-upstream-from-a-registry}

指定されたアップストリームコンテナレジストリと指定されたコンテナ仮想レジストリの間の関連付けを削除します。

```plaintext
DELETE /virtual_registries/container/registry_upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリの関連付けのID。 |

リクエスト例: 

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/registry_upstreams/1"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリのキャッシュエントリを削除する {#delete-cache-entries-for-an-upstream-registry}

{{< history >}}

- GitLab 18.7で`container_virtual_registries`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538327)されました。デフォルトでは無効になっています。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631)：GitLab 18.9で実験からベータに変わりました。

{{< /history >}}

指定されたアップストリームレジストリの削除対象のすべてのキャッシュエントリをスケジュールします。

```plaintext
DELETE /virtual_registries/container/upstreams/:id/cache
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/cache"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### オーバーライドパラメータを使用してアップストリームレジストリへの接続をテストする {#test-connection-to-an-upstream-registry-with-override-parameters}

{{< history >}}

- GitLab 18.9で`container_virtual_registries`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/578679)されました。デフォルトでは無効になっています。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/work_items/589631)：GitLab 18.9で実験からベータに変わりました。

{{< /history >}}

オプションのパラメータオーバーライドを使用して、既存のコンテナアップストリームレジストリへの接続をテストします。

これにより、アップストリームレジストリの設定を更新する前に、URL、ユーザー名、またはパスワードへの変更をテストできます。

```plaintext
POST /virtual_registries/container/upstreams/:id/test
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `password` | 文字列 | いいえ | テスト用のオーバーライドパスワード。 |
| `url` | 文字列 | いいえ | テスト用のオーバーライドURL。指定された場合、アップストリームの設定されたURLの代わりに、このURLへの接続をテストします。 |
| `username` | 文字列 | いいえ | テスト用のオーバーライドユーザー名。 |

#### テストの仕組み {#how-the-test-works}

このエンドポイントは、テストパスを使用してアップストリームURLへのHEADリクエストを実行し、接続と認証を検証します。アップストリームにキャッシュされたアーティファクトがある場合、アップストリームの相対パスがテストに使用されます。それ以外の場合は、プレースホルダパスが使用されます。

テストの動作は、指定されたパラメータによって異なります:

- パラメータなし: アップストリームを現在の設定（既存のURL、ユーザー名、パスワード）でテストします
- URLオーバーライド: 新しいURLへの接続をテストします（ユーザー名とパスワードは一緒に指定するか、まったく指定しないかのいずれかにする必要があります）。
- 認証情報オーバーライド: 新しい認証情報で既存のURLをテストします

HEADリクエストから受信したレスポンスは、次のように解釈されます:

| アップストリームレスポンス | 意味 | 結果 |
|:------------------|:--------|:-------|
| 2XX | 成功。アップストリームアクセス可能 | `{ "success": true }` |
| 404 | 成功。アップストリームはアクセス可能ですが、テストアーティファクトが見つかりません | `{ "success": true }` |
| 401 | 認証に失敗しました | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | アクセスが禁止されました | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | アップストリームサーバーエラー | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| ネットワークエラー | 接続またはタイムアウトの問題 | `{ "success": false, "result": "Error: Connection timeout" }` |

> [!note] 
> `2XX`（検出）および`404 Not Found`の応答は両方とも、アップストリームレジストリへの接続と認証が成功したことを示します。このテストでは、特定のアーティファクトが存在するかどうかは検証されません。

リクエスト例（既存の設定のテスト）:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

リクエスト例（URLオーバーライドがあり、認証情報がないテスト）:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

リクエスト例（URLと認証情報オーバーライドがあるテスト）:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://registry-1.docker.io", "username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

リクエスト例（認証情報オーバーライドがあるテスト）:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/test"
```

レスポンス例: 

```json
{
  "success": true
}
```

## キャッシュエントリを管理する {#manage-cache-entries}

次のエンドポイントを使用して、コンテナ仮想レジストリのキャッシュされたコンテナイメージとマニフェストを管理します。

### アップストリームレジストリキャッシュエントリをリストする {#list-upstream-registry-cache-entries}

アップストリームレジストリのキャッシュされたコンテナイメージとマニフェストをリストします。

```plaintext
GET /virtual_registries/container/upstreams/:id/cache_entries
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `page` | 整数 | いいえ | ページ番号。デフォルトは1です。 |
| `per_page` | 整数 | いいえ | ページあたりのアイテム数。デフォルトは20です。 |
| `search` | 文字列 | いいえ | コンテナイメージの相対パスの検索クエリ（例: `library/nginx`）。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/upstreams/1/cache_entries?search=library/nginx"
```

レスポンス例: 

```json
[
  {
    "id": "MTUgbGlicmFyeS9uZ2lueC9tYW5pZmVzdC9zaGEyNTY6YWJjZGVmZ2hpams=",
    "group_id": 5,
    "upstream_id": 1,
    "upstream_checked_at": "2024-05-30T12:28:27.855Z",
    "file_md5": "44f21d5190b5a6df8089f54799628d7e",
    "file_sha1": "74d101856d26f2db17b39bd22d3204021eb0bf7d",
    "size": 2048,
    "relative_path": "library/nginx/manifests/latest",
    "content_type": "application/vnd.docker.distribution.manifest.v2+json",
    "upstream_etag": "\"686897696a7c876b7e\"",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "downloads_count": 5,
    "downloaded_at": "2024-06-05T14:58:32.855Z"
  }
]
```

### アップストリームレジストリキャッシュエントリを削除する {#delete-an-upstream-registry-cache-entry}

アップストリームレジストリの指定されたキャッシュされたコンテナイメージまたはマニフェストを削除します。

```plaintext
DELETE /virtual_registries/container/cache_entries/*id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列 | はい | キャッシュエントリID。これは、キャッシュエントリのBase64エンコードされたアップストリームIDと相対パスです（例: 'bGlicmFyeS9uZ2lueC9tYW5pZmVzdHMvbGF0ZXN0'）。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/container/cache_entries/bGlicmFyeS9uZ2lueC9tYW5pZmVzdHMvbGF0ZXN0"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。
