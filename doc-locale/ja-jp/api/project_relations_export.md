---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトリレーションエクスポートAPI。
description: "REST APIでプロジェクトリレーションをエクスポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトの構成を移行します。各トップレベルのプロジェクトリレーション（たとえば、マイルストーン、ボード、ラベル）は、個別のファイルとして保存されます。

このAPIは、主に[直接転送によるグループ移行](../user/group/import/_index.md)中に使用されます。このAPIは、[プロジェクトのインポートおよびエクスポートAPI](project_import_export.md)では使用できません。

## 新規エクスポートのスケジュール {#schedule-new-export}

新規プロジェクトリレーションエクスポートを開始します:

```plaintext
POST /projects/:id/export_relations
```

| 属性 | 型              | 必須 | 説明                                        |
|-----------|-------------------|----------|----------------------------------------------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID。                                 |
| `batched` | ブール値           | いいえ       | バッチでエクスポートするかどうか。                      |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations"
```

```json
{
  "message": "202 Accepted"
}
```

## エクスポートステータス {#export-status}

プロジェクトリレーションのエクスポートステータスを表示します:

```plaintext
GET /projects/:id/export_relations/status
```

| 属性  | 型              | 必須 | 説明                                        |
|------------|-------------------|----------|----------------------------------------------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのID。                                 |
| `relation` | 文字列            | いいえ       | 表示するプロジェクトのトップレベルのプロジェクトリレーションの名前。    |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/status"
```

ステータスは、次のいずれかになります:

- `0`: `started`
- `1`: `finished`
- `-1`: `failed`

```json
[
  {
    "relation": "project_badges",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.423Z",
    "batched": true,
    "batches_count": 1,
    "batches": [
      {
        "status": 1,
        "batch_number": 1,
        "objects_count": 1,
        "error": null,
        "updated_at": "2021-05-04T11:25:20.423Z"
      }
    ]
  },
  {
    "relation": "boards",
    "status": 1,
    "error": null,
    "updated_at": "2021-05-04T11:25:20.085Z",
    "batched": false,
    "batches_count": 0
  }
]
```

## エクスポートのダウンロード {#export-download}

完了したプロジェクトリレーションのエクスポートをダウンロードします:

```plaintext
GET /projects/:id/export_relations/download
```

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのID。 |
| `relation`     | 文字列            | はい      | ダウンロードするプロジェクトのトップレベルのプロジェクトリレーションの名前。 |
| `batched`      | ブール値           | いいえ       | エクスポートがバッチ処理されているかどうか。 |
| `batch_number` | 整数           | いいえ       | ダウンロードするエクスポートバッチの数。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```

## 関連トピック {#related-topics}

- [グループリレーション](group_relations_export.md)
