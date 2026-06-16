---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: データ管理API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で`geo_primary_verification_view`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/537707)されました。デフォルトでは無効になっています。これは[実験的機能](../../policy/development_stages_support.md)です。
- フラグはGitLab 18.8でデフォルトで有効になっています。

{{< /history >}}

インスタンスのデータを管理するには、データ管理APIを使用します。

前提条件: 

- 管理者である必要があります。

## モデル情報を取得する {#retrieve-model-information}

インスタンスのデータモデルに関する情報を取得します。この操作は[実験](../../policy/development_stages_support.md)であり、予告なしに変更または削除される可能性があります。

```plaintext
GET /admin/data_management/:model_name
```

`:model_name`パラメータは次のいずれかである必要があります:

- `ci_job_artifacts`
- `ci_pipeline_artifacts`
- `ci_secure_files`
- `container_repositories`
- `dependency_proxy_blobs`
- `dependency_proxy_manifests`
- `design_management_repositories`
- `group_wiki_repositories`
- `lfs_objects`
- `merge_request_diffs`
- `packages_debian_project_component_files`
- `packages_nuget_symbols`
- `packages_package_files`
- `pages_deployments`
- `projects`
- `projects_wiki_repositories`
- `snippet_repositories`
- `supply_chain_attestations`
- `terraform_state_versions`
- `uploads`

サポートされている属性は以下のとおりです: 

| 属性        | 型   | 必須 | 説明                                                                                                                 |
|------------------|--------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `model_name`     | 文字列 | はい      | リクエストされたモデルの複数形名。上記の`:model_name`リストに属している必要があります。                                    |
| `checksum_state` | 文字列 | いいえ       | チェックサムステータスで検索します。許可される値: pending、started、succeeded、失敗、disabled。                                   |
| `identifiers`    | 配列  | いいえ       | リクエストされたモデルの固有識別子の配列で結果をフィルタリングします。これは、整数またはbase64でエンコードされた文字列のいずれかです。 |

このエンドポイントは、モデルのプライマリキーで、昇順または降順のソートとともに、[キーセットページネーション](../rest/_index.md#keyset-based-pagination)をサポートします。キーセットページネーションを使用するには、`pagination=keyset`パラメータをリクエストに追加します。デフォルトでは、キーセットページネーションは1ページあたり20レコードを昇順で読み込みます。クエリパラメータ`sort`と、値`asc`または`desc`を使用して、ソート順序を変更できます。ページあたりのレコード数を選択するには、パラメータ`per_page`を使用します。

成功した場合、[`200`](../rest/troubleshooting.md#status-codes)とモデルに関する情報を返します。以下のレスポンス属性が含まれます:

| 属性              | 型              | 説明                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | Geo固有のチェックサム情報（利用可能な場合）。                               |
| `created_at`           | タイムスタンプ         | 作成タイムスタンプ（利用可能な場合）。                                              |
| `file_size`            | 整数           | オブジェクトのサイズ（利用可能な場合）。                                              |
| `model_class`          | 文字列            | モデルのクラス名。                                                       |
| `record_identifier`    | 文字列または整数 | レコードの固有識別子。整数またはbase64でエンコードされた文字列のいずれかです。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects?pagination=keyset"
```

レスポンス例: 

```json
[
  {
    "record_identifier": 1,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:10.173Z",
    "file_size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.643Z",
      "checksum_state": "succeeded",
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  },
  {
    "record_identifier": 2,
    "model_class": "Project",
    "created_at": "2025-02-05T11:27:14.402Z",
    "file_size": null,
    "checksum_information": {
      "checksum": "<object checksum>",
      "last_checksum": "2025-07-24T14:22:18.214Z",
      "checksum_state": "succeeded",
      "checksum_retry_count": 0,
      "checksum_retry_at": null,
      "checksum_failure": null
    }
  }
]
```

## モデルレコードのチェックサムを再計算する {#recalculate-checksums-for-model-records}

指定されたモデルの選択されたレコードについて、提供された`checksum_state`と`identifiers`パラメータでフィルタリングして、チェックサムを再計算します。そのリクエストは、再計算を実行するためのバックグラウンドジョブをキューに追加します。

```plaintext
PUT /admin/data_management/:model_name/checksum
```

| 属性          | 型    | 必須 | 説明                                                                                                                 |
|--------------------|---------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `model_name`       | 文字列  | はい      | リクエストされたモデルの複数形名。上記の`:model_name`リストに属している必要があります。                                    |
| `checksum_state`   | 文字列  | いいえ       | チェックサムステータスでフィルタリングします。許可される値: pending、started、succeeded、失敗、disabled。                                   |
| `identifiers`      | 配列   | いいえ       | リクエストされたモデルの固有識別子の配列でレコードをフィルタリングします。これは、整数またはbase64でエンコードされた文字列のいずれかです。 |

成功した場合、[`200`](../rest/troubleshooting.md#status-codes)と次の情報を含むJSONレスポンスを返します:

| 属性 | 型   | 説明                                       |
|-----------|--------|---------------------------------------------------|
| `message` | 文字列 | 成功またはエラーに関する情報メッセージ。 |
| `status`  | 文字列 | 「success」または「error」のいずれかです。                      |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/checksum"
```

レスポンス例: 

```json
{
  "status": "success",
  "message": "Batch update job has been successfully enqueued."
}
```

## モデルレコードの情報を取得する {#retrieve-information-about-a-model-record}

指定されたモデルレコードに関する情報を取得します。

```plaintext
GET /admin/data_management/:model_name/:id
```

| 属性           | 型              | 必須 | 説明                                                                                 |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------|
| `model_name`        | 文字列            | はい      | リクエストされたモデルの複数形名。上記の`:model_name`リストに属している必要があります。    |
| `record_identifier` | 文字列または整数 | はい      | リクエストされたモデルの固有識別子。整数またはbase64でエンコードされた文字列のいずれかです。 |

成功した場合、[`200`](../rest/troubleshooting.md#status-codes)と特定のモデルレコードに関する情報を返します。以下のレスポンス属性が含まれます:

| 属性              | 型              | 説明                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | Geo固有のチェックサム情報（利用可能な場合）。                               |
| `created_at`           | タイムスタンプ         | 作成タイムスタンプ（利用可能な場合）。                                              |
| `file_size`            | 整数           | オブジェクトのサイズ（利用可能な場合）。                                              |
| `model_class`          | 文字列            | モデルのクラス名。                                                       |
| `record_identifier`    | 文字列または整数 | レコードの固有識別子。整数またはbase64でエンコードされた文字列のいずれかです。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/1"
```

レスポンス例: 

```json
{
  "record_identifier": 1,
  "model_class": "Project",
  "created_at": "2025-02-05T11:27:10.173Z",
  "file_size": null,
  "checksum_information": {
    "checksum": "<object checksum>",
    "last_checksum": "2025-07-24T14:22:18.643Z",
    "checksum_state": "succeeded",
    "checksum_retry_count": 0,
    "checksum_retry_at": null,
    "checksum_failure": null
  }
}
```

## モデルレコードのチェックサムを再計算する {#recalculate-the-checksum-of-a-model-record}

指定されたモデルレコードのチェックサムを再計算します。チェックサム値は、md5またはsha256アルゴリズムでハッシュ化されたクエリ済みモデルの表現です。

```plaintext
PUT /admin/data_management/:model_name/:record_identifier/checksum
```

| 属性           | 型              | 必須 | 説明                                                                                                               |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `model_name`        | 文字列            | はい      | リクエストされたモデルの複数形名。上記の`:model_name`リストに属している必要があります。                                  |
| `record_identifier` | 文字列または整数 | はい      | レコードの固有識別子。整数またはbase64でエンコードされた文字列（GETクエリのレスポンスから取得）のいずれかです。 |

成功した場合、[`200`](../rest/troubleshooting.md#status-codes)と特定のモデルレコードに関する情報を返します。

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/projects/1/checksum"
```

レスポンス例: 

```json
{
  "record_identifier": 1,
  "model_class": "Project",
  "created_at": "2025-02-05T11:27:10.173Z",
  "file_size": null,
  "checksum_information": {
    "checksum": "<sha256 or md5 string>",
    "last_checksum": "2025-07-24T14:22:18.643Z",
    "checksum_state": "succeeded",
    "checksum_retry_count": 0,
    "checksum_retry_at": null,
    "checksum_failure": null
  }
}
```
