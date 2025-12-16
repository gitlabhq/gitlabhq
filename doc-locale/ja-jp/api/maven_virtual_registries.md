---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maven仮想レジストリAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="flag" >}}

これらのエンドポイントの可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。これらのエンドポイントは[ベータ](../policy/development_stages_support.md#beta)で利用できます。使用する前にドキュメントを注意深くレビューしてください。

{{< /alert >}}

このAPIを使用して以下を行います:

- Maven仮想レジストリの作成と管理。
- アップストリームレジストリの構成。
- キャッシュエントリの管理。
- パッケージのダウンロードとアップロードの処理。

## 仮想レジストリを管理する {#manage-virtual-registries}

次のエンドポイントを使用して、Maven仮想レジストリを作成および管理します。

### すべての仮想レジストリをリスト表示 {#list-all-virtual-registries}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。
- GitLab 18.4で、`downloads_count`および`downloaded_at`が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201790)されました。

{{< /history >}}

グループのすべてのMaven仮想レジストリをリストします。

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/registries
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列/整数 | はい | グループIDまたは完全なグループパス。トップレベルグループである必要があります。 |

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

### 仮想レジストリを作成 {#create-a-virtual-registry}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

グループのMaven仮想レジストリを作成します。

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/registries
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列/整数 | はい | グループIDまたは完全なグループパス。トップレベルグループである必要があります。 |
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

### Maven仮想レジストリを取得 {#get-a-virtual-registry}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

特定のMaven仮想レジストリを取得します。

```plaintext
GET /virtual_registries/packages/maven/registries/:id
```

パラメータは以下のとおりです:

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

### 仮想レジストリを更新 {#update-a-virtual-registry}

{{< history >}}

- GitLab 18.0で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189070)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

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

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161615)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

{{< alert type="warning" >}}

仮想レジストリを削除すると、他の仮想レジストリと共有されていない、関連付けられているすべてのアップストリームレジストリも、それらのキャッシュエントリとともに削除されます。

{{< /alert >}}

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

### 仮想レジストリのキャッシュエントリを削除 {#delete-cache-entries-for-a-virtual-registry}

{{< history >}}

- GitLab 18.2で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538327)されました。デフォルトでは有効になっています。

{{< /history >}}

Maven仮想レジストリのすべての排他的アップストリームレジストリ内の削除対象のすべてのキャッシュエントリをスケジュールします。キャッシュエントリは、他の仮想レジストリに関連付けられているアップストリームレジストリでは削除対象としてスケジュールされません。

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

次のエンドポイントを使用して、アップストリームMavenレジストリを構成および管理します。

### トップレベルグループのすべてのアップストリームレジストリをリスト {#list-all-upstream-registries-for-a-top-level-group}

{{< history >}}

- GitLab 18.3で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/550728)されました。デフォルトでは有効になっています。
- `upstream_name`はGitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/561675)されました。{{< /history >}}

トップレベルグループのすべてのアップストリームレジストリをリストします。

```plaintext
GET /groups/:id/-/virtual_registries/packages/maven/upstreams
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列/整数 | はい | グループIDまたは完全なグループパス。トップレベルグループである必要があります。 |
| `page` | 整数 | いいえ | ページ番号。デフォルトは1です。 |
| `per_page` | 整数 | いいえ | ページあたりのアイテム数。デフォルトは20です。 |
| `upstream_name` | 文字列 | いいえ | 名前であいまい検索フィルタリングを行うためのアップストリームレジストリの名前。 |

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

### アップストリームレジストリを作成する前に接続をテスト {#test-connection-before-creating-an-upstream-registry}

{{< history >}}

- GitLab 18.3で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/535637)されました。デフォルトでは有効になっています。

{{< /history >}}

まだ仮想レジストリに追加されていないMavenアップストリームレジストリへの接続をテストします。このエンドポイントは、アップストリームレジストリを作成する前に、接続と認証情報を検証します。

```plaintext
POST /groups/:id/-/virtual_registries/packages/maven/upstreams/test
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 文字列/整数 | はい | グループIDまたは完全なグループパス。トップレベルグループである必要があります。 |
| `url` | 文字列 | はい | アップストリームレジストリのURL。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |

{{< alert type="note" >}}

リクエストに`username`と`password`の両方を含めるか、どちらも含めないでください。設定されていない場合、パブリック（匿名）リクエストが接続のテストに使用されます。

{{< /alert >}}

#### テストワークフロー {#test-workflow}

`test`エンドポイントは、接続と認証を検証するために、テストパスを使用して、指定されたアップストリームURLにHEADリクエストを送信します。HEADリクエストから受信した応答は、次のように解釈されます:

| アップストリーム応答 | 説明 | 結果 |
|:------------------|:--------|:-------|
| 2XX | 成功 - アップストリームアクセス可能 | `{ "success": true }` |
| 404 | 成功 - アップストリームはアクセス可能ですが、テストアーティファクトが見つかりません | `{ "success": true }` |
| 401 | 認証に失敗しました | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | アクセスが禁止されています | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | アップストリームサーバーエラー | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| ネットワークエラー | 接続/ タイムアウトの問題 | `{ "success": false, "result": "Error: Connection timeout" }` |

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

### 仮想レジストリのすべてのアップストリームレジストリをリスト {#list-all-upstream-registries-for-a-virtual-registry}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

Maven仮想レジストリのすべてのアップストリームレジストリをリストします。

```plaintext
GET /virtual_registries/packages/maven/registries/:id/upstreams
```

サポートされている属性は以下のとおりです:

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

### アップストリームレジストリを作成 {#create-an-upstream-registry}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。
- `metadata_cache_validity_hours`はGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556138)されました。

{{< /history >}}

アップストリームレジストリをMaven仮想レジストリに追加します。

```plaintext
POST /virtual_registries/packages/maven/registries/:id/upstreams
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | Maven仮想レジストリのID。 |
| `url` | 文字列 | はい | アップストリームレジストリのURL。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |
| `name` | 文字列 | いいえ | アップストリームレジストリの名前。 |
| `description` | 文字列 | いいえ | アップストリームレジストリの説明。 |
| `cache_validity_hours` | 整数 | いいえ | キャッシュの有効期間。デフォルトは24時間です。 |
| `metadata_cache_validity_hours` | 整数 | いいえ | メタデータキャッシュの有効期間。デフォルトは24時間です。 |

{{< alert type="note" >}}

リクエストに`username`と`password`の両方を含めるか、まったく含めないでください。設定されていない場合、パブリック（匿名）リクエストはアップストリームへのアクセスに使用されます。

同じURLと認証情報（`username`と`password`）を持つ2つのアップストリームを同じトップレベルグループに追加することはできません。代わりに、次のいずれかを実行できます:

- 同じURLを持つ各アップストリームに異なる認証情報を設定します。
- 複数の仮想レジストリと[アップストリームを関連付けます](#associate-an-upstream-with-a-registry)。{{< /alert >}}

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

### アップストリームレジストリを取得 {#get-an-upstream-registry}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

Maven仮想レジストリの特定のアップストリームレジストリを取得します。

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id
```

パラメータは以下のとおりです:

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

### アップストリームレジストリを更新 {#update-an-upstream-registry}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。
- `metadata_cache_validity_hours`はGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556138)されました。

{{< /history >}}

Maven仮想レジストリの特定のアップストリームレジストリを更新します。

```plaintext
PATCH /virtual_registries/packages/maven/upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `url` | 文字列 | いいえ | アップストリームレジストリのURL。 |
| `name` | 文字列 | いいえ | アップストリームレジストリの名前。 |
| `description` | 文字列 | いいえ | アップストリームレジストリの説明。 |
| `username` | 文字列 | いいえ | アップストリームレジストリのユーザー名。 |
| `password` | 文字列 | いいえ | アップストリームレジストリのパスワード。 |
| `cache_validity_hours` | 整数 | いいえ | キャッシュの有効期間。デフォルトは24時間です。 |
| `metadata_cache_validity_hours` | 整数 | いいえ | メタデータキャッシュの有効期間。デフォルトは24時間です。 |

{{< alert type="note" >}}

リクエストでオプションのパラメータの少なくとも1つを指定する必要があります。

`username`と`password`は、一緒に指定するか、まったく指定しないでください。設定されていない場合、パブリック（匿名）リクエストはアップストリームへのアクセスに使用されます。

{{< /alert >}}

リクエスト例:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"cache_validity_hours": 72}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/upstreams/1"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリの位置を更新 {#update-an-upstream-registry-position}

{{< history >}}

- GitLab 18.0で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186890)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

Maven仮想レジストリの順序付けられたリストでアップストリームレジストリの位置を更新します。

```plaintext
PATCH /virtual_registries/packages/maven/registry_upstreams/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `position` | 整数 | はい | アップストリームレジストリの位置。1～20。 |

リクエスト例:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"position": 5}' \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/registry_upstreams/1"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

### アップストリームレジストリを削除 {#delete-an-upstream-registry}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162019)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

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

### アップストリームをレジストリに関連付けます {#associate-an-upstream-with-a-registry}

{{< history >}}

- GitLab 18.1で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。デフォルトでは無効になっています。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

既存のアップストリームレジストリをMaven仮想レジストリに関連付けます。

```plaintext
POST /virtual_registries/packages/maven/registry_upstreams
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `registry_id` | 整数 | はい | Maven仮想レジストリのID。 |
| `upstream_id` | 整数 | はい | MavenアップストリームレジストリのグローバルID。 |

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

### レジストリからアップストリームの関連付けを解除 {#disassociate-an-upstream-from-a-registry}

{{< history >}}

- GitLab 18.1で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。デフォルトでは無効になっています。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

アップストリームレジストリとMaven仮想レジストリ間の関連付けを削除します。

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

### アップストリームレジストリのキャッシュエントリを削除 {#delete-cache-entries-for-an-upstream-registry}

{{< history >}}

- GitLab 18.2で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538327)されました。デフォルトでは有効になっています。

{{< /history >}}

Maven仮想レジストリ内の特定のアップストリームレジストリの削除対象のすべてのキャッシュエントリをスケジュールします。

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

### アップストリームレジストリへの接続をテスト {#test-connection-to-an-upstream-registry}

{{< history >}}

- GitLab 18.3で`maven_virtual_registry`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/535637)されました。デフォルトでは有効になっています。

{{< /history >}}

既存のMavenアップストリームレジストリへの接続をテストします。

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/test
```

#### テストの仕組み {#how-the-test-works}

このエンドポイントは、接続と認証を検証するために、テストパスを使用してアップストリームURLへのHEADリクエストを実行します。アップストリームにキャッシュされたアーティファクトがある場合、その相対パスはテストに使用されます。それ以外の場合は、ダミーパスが使用されます。HEADリクエストから受信した応答は、次のように解釈されます:

| アップストリーム応答 | 意味 | 結果 |
|:------------------|:--------|:-------|
| 2XX | 成功 - アップストリームアクセス可能 | `{ "success": true }` |
| 404 | 成功 - アップストリームはアクセス可能ですが、テストアーティファクトが見つかりません | `{ "success": true }` |
| 401 | 認証に失敗しました | `{ "success": false, "result": "Error: 401 - Unauthorized" }` |
| 403 | アクセスが禁止されています | `{ "success": false, "result": "Error: 403 - Forbidden" }` |
| 5XX | アップストリームサーバーエラー | `{ "success": false, "result": "Error: 5XX - Server Error" }` |
| ネットワークエラー | 接続/ タイムアウトの問題 | `{ "success": false, "result": "Error: Connection timeout" }` |

{{< alert type="note" >}}

`2XX`（検出）と`404`（見つかりません）の両方の応答は、アップストリームレジストリへの接続と認証が成功したことを示します。このテストでは、GitLabがアップストリームに到達して認証できることを検証しますが、特定のアーティファクトが存在するかどうかは検証しません。

{{< /alert >}}

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

## キャッシュエントリの管理 {#manage-cache-entries}

次のエンドポイントを使用して、Maven仮想レジストリのキャッシュエントリを管理します。

### アップストリームレジストリのキャッシュエントリをリスト {#list-upstream-registry-cache-entries}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162614)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

Mavenアップストリームレジストリのキャッシュエントリをリストします。

```plaintext
GET /virtual_registries/packages/maven/upstreams/:id/cache_entries
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 整数 | はい | アップストリームレジストリのID。 |
| `search` | 文字列 | いいえ | パッケージの相対パスの検索クエリ（たとえば、`foo/bar/mypkg`）。 |
| `page` | 整数 | いいえ | ページ番号。デフォルトは1です。 |
| `per_page` | 整数 | いいえ | ページあたりのアイテム数。デフォルトは20です。 |

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

### アップストリームレジストリのキャッシュエントリを削除 {#delete-an-upstream-registry-cache-entry}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162614)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

Mavenアップストリームレジストリの特定のキャッシュエントリを削除します。

```plaintext
DELETE /virtual_registries/packages/maven/cache_entries/*id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 文字列 | はい | キャッシュエントリのbase64エンコードされたアップストリームIDと相対パス（たとえば、「Zm9vL2Jhci9teXBrZy5wb20=」）。 |

リクエスト例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/cache_entries/Zm9vL2Jhci9teXBrZy5wb20="
```

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)ステータスコードを返します。

## パッケージ操作の管理 {#manage-package-operations}

次のエンドポイントを使用して、Maven仮想レジストリのパッケージ操作を管理します。

{{< alert type="warning" >}}

これらのエンドポイントは、GitLabによる内部使用を目的としており、通常は手動で使用することを意図していません。

{{< /alert >}}

{{< alert type="note" >}}

これらのエンドポイントは、[REST API認証方式](rest/authentication.md)に準拠していません。サポートされているヘッダーとトークンの種類の詳細については、[Maven仮想レジストリ](../user/packages/virtual_registry/maven/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

### パッケージをダウンロードする {#download-a-package}

{{< history >}}

- GitLab 17.3で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160891)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

Maven仮想レジストリからパッケージをダウンロードします。このリソースにアクセスするには、[レジストリで認証する](../user/packages/package_registry/supported_functionality.md#authenticate-with-the-registry)必要があります。

```plaintext
GET /virtual_registries/packages/maven/:id/*path
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
|:----------|:-----|:---------|:------------|
| `id` | 整数 | はい | Maven仮想レジストリのID。 |
| `path` | 文字列 | はい | 完全なパッケージパス（たとえば、`foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`）。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/virtual_registries/packages/maven/1/foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar" \
     --output mypkg-1.0-SNAPSHOT.jar
```

成功した場合、[`200 OK`を返し](rest/troubleshooting.md#status-codes)、次のヘッダー応答を返します:

- `x-checksum-sha1`: ファイルのSHA1チェックサム
- `x-checksum-md5`: ファイルのMD5チェックサム
- `Content-Type`: ファイルのMIMEタイプ
- `Content-Length`: サイズ - ファイルサイズ（バイト単位）

### パッケージをアップロード {#upload-a-package}

{{< history >}}

- GitLab 17.4で`virtual_registry_maven`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163641)されました。デフォルトでは無効になっています。
- 機能フラグはGitLab 18.1で`maven_virtual_registry`に[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)。
- GitLab 18.1で、実験からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/540276)されました。
- GitLab 18.2で、[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197432)になりました。

{{< /history >}}

パッケージをMaven仮想レジストリにアップロードします。このエンドポイントは、[GitLab Workhorse](../development/workhorse/_index.md)でのみアクセスできます。

```plaintext
POST /virtual_registries/packages/maven/:id/*path/upload
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | Maven仮想レジストリのID。 |
| `path` | 文字列 | はい | 完全なパッケージパス（たとえば、`foo/bar/mypkg/1.0-SNAPSHOT/mypkg-1.0-SNAPSHOT.jar`）。 |
| `file` | ファイル | はい | アップロードされているファイル。 |

リクエストヘッダー:

- `Etag`: ファイルのエンティティタグ付け
- `GitLab-Workhorse-Send-Dependency-Content-Type`: ファイルのコンテンツタイプ
- `Upstream-GID`: ターゲットアップストリームのグローバルID

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)ステータスコードを返します。
