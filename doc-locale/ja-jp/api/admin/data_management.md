---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: データ管理API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で`geo_primary_verification_view`[フラグ](../../administration/feature_flags/_index.md)が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/537707)されました。デフォルトでは無効になっています。これは[実験的機能](../../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

データ管理APIを使用して、インスタンスのデータを管理します。

前提要件: 

- 管理者である必要があります。

## モデルに関する情報を取得します {#get-information-about-a-model}

このエンドポイントは[実験的機能](../../policy/development_stages_support.md)であり、予告なく変更または削除される可能性があります。

```plaintext
GET /admin/data_management/:model_name
```

`:model_name`パラメータは、次のいずれかである必要があります:

- `ci_job_artifact`
- `ci_pipeline_artifact`
- `ci_secure_file`
- `container_repository`
- `dependency_proxy_blob`
- `dependency_proxy_manifest`
- `design_management_repository`
- `group_wiki_repository`
- `lfs_object`
- `merge_request_diff`
- `packages_package_file`
- `pages_deployment`
- `project`
- `projects_wiki_repository`
- `snippet_repository`
- `terraform_state_version`
- `upload`

サポートされている属性は以下のとおりです:

| 属性         | 型   | 必須 | 説明                                                                                                                 |
|-------------------|--------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `model_name`      | 文字列 | はい      | 要求されたモデルの名前。上記の`:model_name`リストに属している必要があります。                                               |
| `checksum_state`  | 文字列 | いいえ       | チェックサムステータスで検索します。使用できる値: pending、started、succeeded、failed、disabled。                                   |
| `identifiers`     | 配列  | いいえ       | 要求されたモデルの一意な識別子の配列で結果をフィルタリングします。これは、整数またはbase64エンコードされた文字列にすることができます。 |

成功した場合、[`200`](../rest/troubleshooting.md#status-codes)とモデルに関する情報が返されます。これには、次のレスポンス属性が含まれます:

| 属性              | 型              | 説明                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | Geo固有のチェックサム情報（利用可能な場合）。                               |
| `created_at`           | タイムスタンプ         | 作成タイムスタンプ（利用可能な場合）。                                              |
| `file_size`            | 整数           | オブジェクトのサイズ（利用可能な場合）。                                              |
| `model_class`          | 文字列            | モデルのクラス名。                                                       |
| `record_identifier`    | 文字列または整数 | レコードの一意な識別子。整数またはbase64エンコードされた文字列にすることができます。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/project"
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

## すべてのモデルレコードのチェックサムを再計算します {#recalculate-the-checksum-of-all-model-records}

```plaintext
PUT /admin/data_management/:model_name/checksum
```

| 属性           | 型              | 必須 | 説明                                                                                 |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------|
| `model_name`        | 文字列            | はい      | 要求されたモデルの名前。上記の`:model_name`リストに属している必要があります。               |

このエンドポイントは、モデルのすべてのレコードにチェックサムの再計算をマークします。バックグラウンドジョブをエンキューして、これを行います。成功した場合、[`200`](../rest/troubleshooting.md#status-codes)と、次の情報を含むJSONレスポンスが返されます:

| 属性 | 型   | 説明                                       |
|-----------|--------|---------------------------------------------------|
| `message` | 文字列 | 成功またはエラーに関する情報メッセージ。 |
| `status`  | 文字列 | "success"または"error"を指定できます。                      |

```json
{
  "status": "success",
  "message": "Batch update job has been successfully enqueued."
}
```

## 特定のモデルレコードに関する情報を取得します {#get-information-about-a-specific-model-record}

```plaintext
GET /admin/data_management/:model_name/:id
```

| 属性           | 型              | 必須 | 説明                                                                                 |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------|
| `model_name`        | 文字列            | はい      | 要求されたモデルの名前。上記の`:model_name`リストに属している必要があります。               |
| `record_identifier` | 文字列または整数 | はい      | 要求されたモデルの一意な識別子。整数またはbase64エンコードされた文字列にすることができます。 |

成功した場合、[`200`](../rest/troubleshooting.md#status-codes)と特定のモデルレコードに関する情報が返されます。これには、次のレスポンス属性が含まれます:

| 属性              | 型              | 説明                                                                    |
|------------------------|-------------------|--------------------------------------------------------------------------------|
| `checksum_information` | JSON              | Geo固有のチェックサム情報（利用可能な場合）。                               |
| `created_at`           | タイムスタンプ         | 作成タイムスタンプ（利用可能な場合）。                                              |
| `file_size`            | 整数           | オブジェクトのサイズ（利用可能な場合）。                                              |
| `model_class`          | 文字列            | モデルのクラス名。                                                       |
| `record_identifier`    | 文字列または整数 | レコードの一意な識別子。整数またはbase64エンコードされた文字列にすることができます。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/data_management/project/1"
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

## 特定のモデルレコードのチェックサムを再計算します {#recalculate-the-checksum-of-a-specific-model-record}

```plaintext
PUT /admin/data_management/:model_name/:record_identifier/checksum
```

| 属性           | 型              | 必須 | 説明                                                                                                               |
|---------------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `model_name`        | 文字列            | はい      | 要求されたモデルの名前。上記の`:model_name`リストに属している必要があります。                                             |
| `record_identifier` | 文字列または整数 | はい      | レコードの一意な識別子。整数またはbase64エンコードされた文字列にすることができます（GETクエリのレスポンスから取得）。 |

成功した場合、[`200`](../rest/troubleshooting.md#status-codes)と特定のモデルレコードに関する情報が返されます。チェックサム値は、md5またはsha256アルゴリズムでハッシュされたクエリ対象モデルの表現です。

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
