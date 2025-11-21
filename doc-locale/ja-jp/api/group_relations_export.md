---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループリレーションエクスポートAPI
description: "REST APIを使用して、グループ関係をエクスポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループ関係エクスポートAPIは、グループの構造を、最上位の各関係（たとえば、マイルストーン、ボード、ラベル）ごとに個別のファイルとして部分的にエクスポートします。

グループ関係エクスポートAPIは、主に[直接転送によるグループ移行](../user/group/import/_index.md)で使用され、GitLabインスタンスが[特定の前提条件](../user/group/import/direct_transfer_migrations.md#prerequisites)を満たしている必要があります。

このAPIは、[グループインポートおよびエクスポートAPI](group_import_export.md)では使用できません。

## 新しいエクスポートをスケジュール {#schedule-new-export}

新しいグループ関係エクスポートを開始します:

```plaintext
POST /groups/:id/export_relations
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|------------ |
| `id`      | 整数または文字列 | はい      | グループのID。 |
| `batched` | ブール値           | いいえ       | バッチでエクスポートするかどうか。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/export_relations"
```

```json
{
  "message": "202 Accepted"
}
```

## エクスポートステータス {#export-status}

関係エクスポートのステータスを表示します:

```plaintext
GET /groups/:id/export_relations/status
```

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|------------ |
| `id`       | 整数または文字列 | はい      | グループのID。 |
| `relation` | 文字列            | いいえ       | 表示するプロジェクトの最上位関係の名前。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/export_relations/status"
```

ステータスは、次のいずれかになります:

- `0`: `started`
- `1`: `finished`
- `-1`: `failed`

```json
[
  {
    "relation": "badges",
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

完了した関係エクスポートをダウンロードします:

```plaintext
GET /groups/:id/export_relations/download
```

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|------------ |
| `id`           | 整数または文字列 | はい      | グループのID。 |
| `relation`     | 文字列            | はい      | ダウンロードするグループの最上位関係の名前。 |
| `batched`      | ブール値           | いいえ       | エクスポートがバッチ処理されているかどうか。 |
| `batch_number` | 整数           | いいえ       | ダウンロードするエクスポートバッチの番号。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name "https://gitlab.example.com/api/v4/groups/1/export_relations/download?relation=labels"
```

```shell
ls labels.ndjson.gz
labels.ndjson.gz
```

## 関連トピック {#related-topics}

- [プロジェクトリレーションエクスポートAPI](project_relations_export.md)
