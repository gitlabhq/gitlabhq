---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 依存関係リストのエクスポートAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[依存関係リスト](../user/application_security/dependency_list/_index.md)をエクスポートします。このAPIを呼び出すには、すべて認証が必要です。

## 依存関係リストのエクスポートを作成する {#create-a-dependency-list-export}

{{< history >}}

- GitLab 16.4で`merge_sbom_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/333463)されました。デフォルトでは有効になっています。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/425312)になりました。機能フラグ`merge_sbom_api`は削除されました。

{{< /history >}}

パイプラインで検出されたすべてのプロジェクト依存関係について、新しいCycloneDX JSONエクスポートを作成します。

認証済みユーザーが[read_dependency](../user/custom_roles/abilities.md#vulnerability-management)権限を持っていない場合、このリクエストは`403 Forbidden`ステータスコードを返します。

SBOMのエクスポートは、エクスポートの作成者のみがアクセスできます。

```plaintext
POST /projects/:id/dependency_list_exports
POST /groups/:id/dependency_list_exports
POST /pipelines/:id/dependency_list_exports
```

| 属性           | 型              | 必須   | 説明                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | 整数           | はい        | 認証済みユーザーがアクセスできるプロジェクト、グループ、またはパイプラインのID。 |
| `export_type`       | 文字列            | はい        | エクスポートの形式。承認された値のリストについては、[エクスポートの種類](#export-types)を参照してください。 |
| `send_email`        | ブール値           | いいえ         | `true`に設定すると、エクスポートが完了したときに、エクスポートをリクエストしたユーザーにメール通知が送信されます。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/pipelines/1/dependency_list_exports" \
  --data "export_type=sbom"
```

作成された依存関係リストのエクスポートは、`expires_at`フィールドで指定された時刻に自動的に削除されます。

レスポンス例:

```json
{
  "id": 2,
  "status": "running",
  "has_finished": false,
  "export_type": "sbom",
  "send_email": false,
  "expires_at": "2025-04-06T09:35:38.746Z",
  "self": "http://gitlab.example.com/api/v4/dependency_list_exports/2",
  "download": "http://gitlab.example.com/api/v4/dependency_list_exports/2/download"
}
```

### エクスポートの種類 {#export-types}

エクスポートは、さまざまなファイル形式でリクエストできます。一部の形式は、特定のオブジェクトでのみ使用できます。

| エクスポートの種類 | 説明 | 利用可能 |
| ----------- | ----------- | ------------- |
| `dependency_list` | キー/バリューペアとして依存関係をリストする標準のJSONオブジェクト。 | プロジェクト |
| `sbom` | [CycloneDX](https://cyclonedx.org/) 1.4ソフトウェア部品表 | パイプライン |
| `cyclonedx_1_6_json` | [CycloneDX](https://cyclonedx.org/) 1.6ソフトウェア部品表 | プロジェクト |
| `json_array` | コンポーネントオブジェクトを含むフラットなJSON配列。 | グループ |
| `csv` | コンマ区切り値（CSV）ドキュメント。 | プロジェクト、グループ |

## 単一の依存関係リストのエクスポートを取得 {#get-single-dependency-list-export}

単一の依存関係リストのエクスポートを取得します。

```plaintext
GET /dependency_list_exports/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | 依存関係リストのエクスポートのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/dependency_list_exports/2"
```

ステータスコードは、依存関係リストのエクスポートが生成されている場合は`202 Accepted`、準備ができている場合は`200 OK`です。

レスポンス例:

```json
{
  "id": 4,
  "has_finished": true,
  "self": "http://gitlab.example.com/api/v4/dependency_list_exports/4",
  "download": "http://gitlab.example.com/api/v4/dependency_list_exports/4/download"
}
```

## 依存関係リストのエクスポートをダウンロード {#download-dependency-list-export}

単一の依存関係リストのエクスポートをダウンロードします。

```plaintext
GET /dependency_list_exports/:id/download
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | 依存関係リストのエクスポートのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <private_token>" \
  --url "https://gitlab.example.com/api/v4/dependency_list_exports/2/download"
```

依存関係リストのエクスポートがまだ完了していないか、見つからなかった場合、応答は`404 Not Found`です。

レスポンス例:

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:aec33827-20ae-40d0-ae83-18ee846364d2",
  "version": 1,
  "metadata": {
    "tools": [
      {
        "vendor": "Gitlab",
        "name": "Gemnasium",
        "version": "2.34.0"
      }
    ],
    "authors": [
      {
        "name": "Gitlab",
        "email": "support@gitlab.com"
      }
    ],
    "properties": [
      {
        "name": "gitlab:dependency_scanning:input_file",
        "value": "package-lock.json"
      }
    ]
  },
  "components": [
    {
      "name": "com.fasterxml.jackson.core/jackson-core",
      "purl": "pkg:maven/com.fasterxml.jackson.core/jackson-core@2.9.2",
      "version": "2.9.2",
      "type": "library",
      "licenses": [
        {
          "license": {
            "id": "MIT",
            "url": "https://spdx.org/licenses/MIT.html"
          }
        },
        {
          "license": {
            "id": "BSD-3-Clause",
            "url": "https://spdx.org/licenses/BSD-3-Clause.html"
          }
        }
      ]
    }
  ]
}

```
