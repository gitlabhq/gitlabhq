---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven仮想レジストリAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615)されました。デフォルトでは無効になっています。
- 機能フラグがGitLab 18.1で`maven_virtual_registry`に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。デフォルトでは無効になっています。機能フラグ`virtual_registry_maven`は削除されました。
- GitLab 18.1で実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2の[GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)で有効になりました。

{{< /history >}}

> [!flag] これらのエンドポイントの可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

このAPIを使用して、以下を行います:

- Maven仮想レジストリを作成および管理します。
- アップストリームレジストリを設定します。
- キャッシュエントリを管理します。
- パッケージのダウンロードとアップロードを処理します。

## 仮想レジストリを管理する {#manage-virtual-registries}

Maven仮想レジストリを作成および管理するには、次のエンドポイントを使用します。

### すべての仮想レジストリをリストする {#list-all-virtual-registries}

{{< history >}}

- `downloads_count`および`downloaded_at`がGitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201790)されました。

{{< /history >}}

グループのすべてのMaven仮想レジストリをリストします。

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/registries
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列/整数 | はい | グループIDまたはグループのフルパス。トップレベルグループである必要があります。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/registries"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "name": "my-virtual-registry",
    "description": "My virtual registry",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### 仮想レジストリを作成する {#create-a-virtual-registry}

グループのMaven仮想レジストリを作成します。

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/registries
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列/整数 | はい | グループIDまたはグループのフルパス。トップレベルグループである必要があります。 |
| `name` | 文字列 | はい | 仮想レジストリの名前。 |
| `description` | 文字列 | いいえ | 仮想レジストリの説明。 |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"name": "my-virtual-registry", "description": "My virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/registries"
```

レスポンス例:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-virtual-registry",
  "description": "My virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 仮想レジストリを取得する {#get-a-virtual-registry}

特定のMaven仮想レジストリを取得します。

```plaintext
GET /virtual_registries/packages/maven/registries/:id
```

パラメータは以下のとおりです。

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | Maven仮想レジストリのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

レスポンス例:

```json
{
  "id": 1,
  "group_id": 5,
  "name": "my-virtual-registry",
  "description": "My virtual registry",
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### 仮想レジストリを更新する {#update-a-virtual-registry}

特定のMaven仮想レジストリを更新します。

```plaintext
PATCH /virtual_registries/packages/maven/registries/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | Maven仮想レジストリのID。 |
| `name` | 文字列 | はい | 仮想レジストリの名前。 |
| `description` | 文字列 | いいえ | 仮想レジストリの説明。 |

リクエスト例: 

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"name": "my-virtual-registry", "description": "My virtual registry"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### 仮想レジストリを削除する {#delete-a-virtual-registry}

> [!warning]仮想レジストリを削除すると、他の仮想レジストリと共有されていない関連付けられたすべてのアップストリームレジストリとそのキャッシュエントリも削除されます。

特定のMaven仮想レジストリを削除します。

```plaintext
DELETE /virtual_registries/packages/maven/registries/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | Maven仮想レジストリのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### 仮想レジストリのキャッシュエントリを削除する {#delete-cache-entries-for-a-virtual-registry}

{{< history >}}

- GitLab 18.2で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538327)されました。デフォルトでは有効になっています。

{{< /history >}}

Maven仮想レジストリのすべての排他的なアップストリームレジストリのすべてのキャッシュエントリを削除するようにスケジュールします。キャッシュエントリは、他の仮想レジストリに関連付けられているアップストリームレジストリに対して削除するようにスケジュールされていません。

```plaintext
DELETE /virtual_registries/packages/maven/registries/:id/cache
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | Maven仮想レジストリのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/cache"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

## アップストリームレジストリを管理する {#manage-upstream-registries}

次のエンドポイントを使用して、アップストリームMavenレジストリを設定および管理します。

### トップレベルグループのすべてのアップストリームレジストリをリストする {#list-all-upstream-registries-for-a-top-level-group}

{{< history >}}

- GitLab 18.3で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/550728)されました。デフォルトでは有効になっています。
- `upstream_name`がGitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/561675)されました。{{< /history >}}

トップレベルグループのすべてのアップストリームレジストリをリストします。

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/upstreams
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列/整数 | はい | グループIDまたはグループのフルパス。トップレベルグループである必要があります。 |
| `page` | 整数 | いいえ | ページ番号。デフォルトは1です。 |
| `per_page` | 整数 | いいえ | ページあたりのアイテム数。デフォルトは20です。 |
| `upstream_name` | 文字列 | いいえ | 名前でファジー検索フィルタリングを行うためのアップストリームレジストリの名前。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/upstreams"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://repo.maven.apache.org/maven2",
    "name": "Maven Central",
    "description": "Maven Central repository",
    "cache_validity_hours": 24,
    "metadata_cache_validity_hours": 24,
    "username": "user",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z"
  }
]
```

### アップストリームレジストリを作成する前に接続をテストする {#test-connection-before-creating-an-upstream-registry}

{{< history >}}

- GitLab 18.3で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/535637)されました。デフォルトでは有効になっています。

{{< /history >}}

仮想レジストリに追加されていないMavenアップストリームレジストリへの接続をテストします。このエンドポイントは、アップストリームレジストリを作成する前に、接続と認証情報を検証します。

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/upstreams/test
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列/整数 | はい | グループIDまたはグループのフルパス。トップレベルグループである必要があります。 |
| `url` | 文字列 | はい | アップストリームレジストリのURL。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |

> [!note] `username`と`password`の両方をリクエストに含めるか、どちらも含めない必要があります。設定されていない場合、パブリック（匿名）リクエストを使用して接続をテストします。

#### テストワークフロー {#test-workflow}

`test`エンドポイントは、接続と認証を検証するために、テストパスを使用して、指定されたアップストリームURLにHEADリクエストを送信します。HEADリクエストから受信したレスポンスは、次のように解釈されます:

| アップストリームレスポンス | 説明 | 結果 |
|:------------------|:--------|:-------|
| 2XX | 成功 - アップストリームアクセス可能 | `{ "success": true }` |
| 404 | 成功 - アップストリームはアクセス可能ですが、テストアーティファクトが見つかりません | `{ "success": true }` |
| 401 | 認証に失敗しました | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | アクセスが禁止されました | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | アップストリームサーバーエラー | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| ネットワークエラー | 接続またはタイムアウトの問題 | `{ "success": false, "result": "Error: Connection timeout" }` |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/packages/maven/upstreams/test" \
     --data '{"url": "https://repo.maven.apache.org/maven2"}'
```

レスポンス例:

```json
{
  "success": true
}
```

### 仮想レジストリのすべてのアップストリームレジストリをリストする {#list-all-upstream-registries-for-a-virtual-registry}

Maven仮想レジストリのすべてのアップストリームレジストリをリストします。

```plaintext
GET /virtual_registries/packages/maven/registries/:id/upstreams
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 整数 | はい | Maven仮想レジストリのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/upstreams"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "group_id": 5,
    "url": "https://repo.maven.apache.org/maven2",
    "name": "Maven Central",
    "description": "Maven Central repository",
    "cache_validity_hours": 24,
    "metadata_cache_validity_hours": 24,
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

{{< history >}}

- `metadata_cache_validity_hours`がGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556138)されました。

{{< /history >}}

アップストリームレジストリをMaven仮想レジストリに追加します。

```plaintext
POST /virtual_registries/packages/maven/registries/:id/upstreams
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | Maven仮想レジストリのID。 |
| `url` | 文字列 | はい | アップストリームレジストリのURL。 |
| `cache_validity_hours` | 整数 | いいえ | キャッシュの有効期間。デフォルトは24時間です。 |
| `description` | 文字列 | いいえ | アップストリームレジストリの説明。 |
| `metadata_cache_validity_hours` | 整数 | いいえ | メタデータキャッシュの有効期間。デフォルトは24時間です。 |
| `name` | 文字列 | いいえ | アップストリームレジストリの名前。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |

{{< alert type="note" >}}

`username`と`password`の両方をリクエストに含めるか、まったく含めない必要があります。設定されていない場合、パブリック（匿名）リクエストを使用してアップストリームにアクセスします。

同じURLと認証情報（`username`と`password`）を持つ2つのアップストリームを同じトップレベルグループに追加することはできません。代わりに、次のいずれかを実行できます。

- 同じURLを持つ各アップストリームに異なる認証情報を設定します。
- 複数の仮想レジストリと[関連付けるアップストリーム](#associate-an-upstream-with-a-registry)。{{< /alert >}}

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "https://repo.maven.apache.org/maven2", "name": "Maven Central", "description": "Maven Central repository", "username": <your_username>, "password": <your_password>, "cache_validity_hours": 48, "metadata_cache_validity_hours": 1}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registries/1/upstreams"
```

レスポンス例:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://repo.maven.apache.org/maven2",
  "name": "Maven Central",
  "description": "Maven Central repository",
  "cache_validity_hours": 48,
  "metadata_cache_validity_hours": 1,
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

### アップストリームレジストリを取得する {#get-an-upstream-registry}

Maven仮想レジストリの特定のアップストリームレジストリを取得します。

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id
```

パラメータは以下のとおりです。

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

レスポンス例:

```json
{
  "id": 1,
  "group_id": 5,
  "url": "https://repo.maven.apache.org/maven2",
  "name": "Maven Central",
  "description": "Maven Central repository",
  "cache_validity_hours": 24,
  "metadata_cache_validity_hours": 24,
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

{{< history >}}

- `metadata_cache_validity_hours`がGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556138)されました。

{{< /history >}}

Maven仮想レジストリの特定のアップストリームレジストリを更新します。

```plaintext
PATCH /virtual_registries/packages/maven/upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `cache_validity_hours` | 整数 | いいえ | キャッシュの有効期間。デフォルトは24時間です。 |
| `description` | 文字列 | いいえ | アップストリームレジストリの説明。 |
| `metadata_cache_validity_hours` | 整数 | いいえ | メタデータキャッシュの有効期間。デフォルトは24時間です。 |
| `name` | 文字列 | いいえ | アップストリームレジストリの名前。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |
| `url` | 文字列 | いいえ | アップストリームレジストリのURL。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |

> [!note]リクエストにオプションのパラメータを少なくとも1つ指定する必要があります。
>
> `username`と`password`は、一緒に指定するか、まったく指定しないでください。設定されていない場合、パブリック（匿名）リクエストを使用してアップストリームにアクセスします。

リクエスト例: 

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリの位置を更新する {#update-an-upstream-registry-position}

Maven仮想レジストリの順序付けられたリストで、アップストリームレジストリの位置を更新します。

```plaintext
PATCH /virtual_registries/packages/maven/registry_upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `position` | 整数 | はい | アップストリームレジストリの位置。1～20の間。 |

リクエスト例: 

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリを削除する {#delete-an-upstream-registry}

Maven仮想レジストリの特定のアップストリームレジストリを削除します。

```plaintext
DELETE /virtual_registries/packages/maven/upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### レジストリとアップストリームを関連付ける {#associate-an-upstream-with-a-registry}

{{< history >}}

- GitLab 18.1で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。デフォルトでは無効になっています。
- GitLab 18.2の[GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)で有効になりました。

{{< /history >}}

既存のアップストリームレジストリをMaven仮想レジストリに関連付けます。

```plaintext
POST /virtual_registries/packages/maven/registry_upstreams
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `registry_id` | 整数 | はい | Maven仮想レジストリのID。 |
| `upstream_id` | 整数 | はい | MavenアップストリームレジストリのID。 |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"registry_id": 1, "upstream_id": 2}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams"
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

{{< history >}}

- GitLab 18.1で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。デフォルトでは無効になっています。
- GitLab 18.2の[GitLab.com、GitLab Self-Managed、GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)で有効になりました。

{{< /history >}}

アップストリームレジストリとMaven仮想レジストリの間の関連付けを削除します。

```plaintext
DELETE /virtual_registries/packages/maven/registry_upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | レジストリアップストリームの関連付けのID。 |

リクエスト例: 

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリのキャッシュエントリを削除する {#delete-cache-entries-for-an-upstream-registry}

{{< history >}}

- GitLab 18.2で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538327)されました。デフォルトでは有効になっています。

{{< /history >}}

Maven仮想レジストリ内の特定のアップストリームレジストリの削除のためにすべてのキャッシュエントリをスケジュールします。

```plaintext
DELETE /virtual_registries/packages/maven/upstreams/:id/cache
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/cache"
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリへの接続をテストする {#test-connection-to-an-upstream-registry}

{{< history >}}

- GitLab 18.3で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/535637)されました。デフォルトでは有効になっています。

{{< /history >}}

既存のMavenアップストリームレジストリへの接続をテストします。

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/test
```

#### テストの仕組み {#how-the-test-works}

このエンドポイントは、接続と認証を検証するために、テストパスを使用してアップストリームURLにHEADリクエストを実行します。アップストリームにキャッシュされたアーティファクトがある場合、その相対パスはテストに使用されます。それ以外の場合は、ダミーのパスが使用されます。HEADリクエストから受信したレスポンスは、次のように解釈されます:

| アップストリームレスポンス | 意味 | 結果 |
|:------------------|:--------|:-------|
| 2XX | 成功 - アップストリームアクセス可能 | `{ "success": true }` |
| 404 | 成功 - アップストリームはアクセス可能ですが、テストアーティファクトが見つかりません | `{ "success": true }` |
| 401 | 認証に失敗しました | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | アクセスが禁止されました | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | アップストリームサーバーエラー | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| ネットワークエラー | 接続/タイムアウトの問題 | `{ "success": false, "result": "Error: Connection timeout" }` |

> [!note] `2XX`（検出）と`404`（未検出）のレスポンスはどちらも、アップストリームレジストリへの接続と認証が成功したことを示します。このテストでは、GitLabがアップストリームに到達して認証できるかどうかを検証し、特定のアーティファクトが存在するかどうかは検証しません。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

レスポンス例:

```json
{
  "success": true
}
```

### オーバーライドパラメータを使用してアップストリームレジストリへの接続をテストする {#test-connection-to-an-upstream-registry-with-override-parameters}

{{< history >}}

- GitLab 18.7で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/565897)されました。デフォルトでは有効になっています。

{{< /history >}}

オーバーライド可能なパラメータを使用して、既存のMavenアップストリームレジストリへの接続をテストします。

これにより、アップストリームレジストリの設定を更新する前に、URL、ユーザー名、またはパスワードへの変更をテストできます。

```plaintext
POST /virtual_registries/packages/maven/upstreams/:id/test
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `password` | 文字列 | いいえ | テスト用のオーバーライドパスワード。 |
| `url` | 文字列 | いいえ | テスト用のオーバーライドURL。指定された場合、アップストリームの設定されたURLの代わりに、このURLへの接続をテストします。 |
| `username` | 文字列 | いいえ | テスト用のオーバーライドユーザー名。 |

#### テストの仕組み {#how-the-test-works-1}

このエンドポイントは、接続と認証を検証するために、テストパスを使用してアップストリームURLにHEADリクエストを実行します。アップストリームにキャッシュされたアーティファクトがある場合、アップストリームの相対パスがテストに使用されます。それ以外の場合は、プレースホルダパスが使用されます。

テストの動作は、指定されたパラメータによって異なります:

- パラメータなし: アップストリームを現在の設定（既存のURL、ユーザー名、パスワード）でテストします
- URLオーバーライド: 新しいURLへの接続をテストします。ユーザー名とパスワードは、一緒に指定するか、まったく指定しない必要があります
- 認証情報オーバーライド: 新しい認証情報で既存のURLをテストします

HEADリクエストから受信したレスポンスは、次のように解釈されます:

| アップストリームレスポンス | 意味 | 結果 |
|:------------------|:--------|:-------|
| 2XX | 成功。アップストリームアクセス可能 | `{ "success": true }` |
| 404 | 成功。アップストリームアクセス可能ですが、テストアーティファクトが見つかりません | `{ "success": true }` |
| 401 | 認証に失敗しました | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | アクセスが禁止されました | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | アップストリームサーバーエラー | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| ネットワークエラー | 接続またはタイムアウトの問題 | `{ "success": false, "result": "Error: Connection timeout" }` |

> [!note] `2XX`（検出）と`404`（未検出）のレスポンスはどちらも、アップストリームレジストリへの接続と認証が成功したことを示します。このテストでは、特定のアーティファクトが存在するかどうかは検証されません。

リクエスト例（既存の設定のテスト）:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

リクエスト例（URLオーバーライドがあり、認証情報がないテスト）:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "<https://new-repo.example.com/maven2>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

リクエスト例（URLと認証情報オーバーライドがあるテスト）:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"url": "<https://new-repo.example.com/maven2>", "username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

リクエスト例（認証情報オーバーライドがあるテスト）:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"username": "<newuser>", "password": "<newpass>"}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/test"
```

レスポンス例:

```json
{
  "success": true
}
```

## キャッシュエントリの管理 {#manage-cache-entries}

Maven仮想レジストリのキャッシュエントリを管理するには、次のエンドポイントを使用します。

### アップストリームレジストリキャッシュエントリのリスト {#list-upstream-registry-cache-entries}

Mavenアップストリームレジストリのキャッシュエントリをリストします。

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/cache_entries
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `page` | 整数 | いいえ | ページ番号。デフォルトは1です。 |
| `per_page` | 整数 | いいえ | ページあたりのアイテム数。デフォルトは20です。 |
| `search` | 文字列 | いいえ | パッケージの相対パスの検索クエリ（例：`foo/bar/mypkg`）。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1/cache_entries?search=foo/bar"
```

レスポンス例:

```json
[
  {
    "id": "MTUgZm9vL2Jhci9teXBrZy8xLjAtU05BUFNIT1QvbXlwa2ctMS4wLVNOQVBTSE9ULmphcg==",
    "group_id": 5,
    "upstream_id": 1,
    "upstream_checked_at": "2024-05-30T12:28:27.855Z",
    "file_md5": "44f21d5190b5a6df8089f54799628d7e",
    "file_sha1": "74d101856d26f2db17b39bd22d3204021eb0bf7d",
    "size": 2048,
    "relative_path": "foo/bar/package-1.0.0.pom",
    "content_type": "application/xml",
    "upstream_etag": "\"686897696a7c876b7e\"",
    "created_at": "2024-05-30T12:28:27.855Z",
    "updated_at": "2024-05-30T12:28:27.855Z",
    "downloads_count": 6,
    "downloaded_at": "2024-06-05T14:58:32.855Z"
  }
]
```

### アップストリームレジストリキャッシュエントリの削除 {#delete-an-upstream-registry-cache-entry}

Mavenアップストリームレジストリの特定のキャッシュエントリを削除します。

```plaintext
DELETE /virtual_registries/packages/maven/cache_entries/*id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列 | はい | キャッシュエントリのbase64エンコードされたアップストリームIDと相対パス（例：'Zm9vL2Jhci9teXBrZy5wb20='）。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/cache_entries/Zm9vL2Jhci9teXBrZy5wb20="
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

## パッケージ操作の管理 {#manage-package-operations}

Maven仮想レジストリのパッケージ操作を管理するには、次のエンドポイントを使用します。

> [!warning]これらのエンドポイントは、GitLabの内部使用を目的としており、通常は手動での使用を目的としていません。

これらのエンドポイントは、[REST API認証方式](rest/authentication.md)に準拠していません。サポートされているヘッダーとトークンの種類の詳細については、[Maven仮想レジストリ](../user/packages/virtual_registry/maven/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

### パッケージをダウンロードする {#download-a-package}

Maven仮想レジストリからパッケージをダウンロードします。このリソースにアクセスするには、[レジストリで認証する](../user/packages/package_registry/supported_functionality.md#authenticate-with-the-registry)必要があります。

```plaintext
GET /virtual_registries/packages/maven/:id/*path
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 整数 | はい | Maven仮想レジストリのID。 |
| `path` | 文字列 | はい | パッケージのフルパス（例：`foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`）。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/1/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" \
     --output mypkg-1.0-SNAPSHOT.jar
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、次のレスポンスヘッダーを返します:

- `x-checksum-sha1`: ファイルのSHA1チェックサム
- `x-checksum-md5`: ファイルのMD5チェックサム
- `Content-Type`: ファイルのMIMEタイプ
- `Content-Length`: ファイルサイズ（バイト単位）

### パッケージのアップロード {#upload-a-package}

Maven仮想レジストリにパッケージをアップロードします。このエンドポイントは、[GitLab Workhorse](../development/workhorse/_index.md)でのみアクセスできます。

```plaintext
POST /virtual_registries/packages/maven/:id/*path/upload
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | Maven仮想レジストリのID。 |
| `file` | ファイル | はい | アップロードされるファイル。 |
| `path` | 文字列 | はい | パッケージのフルパス（例：`foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`）。 |

リクエストヘッダー:

- `Etag`: ファイルのエンティティタグ
- `GitLab-Workhorse-Send-Dependency-Content-Type`: ファイルコンテンツタイプ
- `Upstream-GID`: ターゲットアップストリームのグローバルID

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。
