---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループリレーションエクスポートAPI
description: "REST APIを使用してグループリレーションをエクスポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIは、[直接転送によるグループ移行](../user/group/import/_index.md)中に、宛先インスタンスによってグループ構造を移行するために使用されます。通常、このAPIを自分で使用する必要はありません。

このコンテキストでは、{{< glossary-tooltip text="relation" >}}はエピックのようなエクスポート可能な項目です。エクスポートされると、リレーションにはラベルなど、リレーションに関連する項目が含まれます。

このAPIを使用するには、GitLabインスタンスが特定の[前提条件](../user/group/import/direct_transfer_migrations.md#prerequisites)を満たしている必要があります。

> [!note]
> このAPIは、ファイルベースの移行用である[グループインポートおよびエクスポートAPI](group_import_export.md)では使用できません。

## グループの新しいエクスポートをスケジュールする {#schedule-a-new-export-for-a-group}

指定されたグループのリレーションエクスポートをスケジュールします。

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

## エクスポートのステータスを取得する {#retrieve-the-status-of-an-export}

リレーションエクスポートのステータスを取得します。

```plaintext
GET /groups/:id/export_relations/status
```

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|------------ |
| `id`       | 整数または文字列 | はい      | グループのID。 |
| `relation` | 文字列            | いいえ       | 表示するグループトップレベルリレーションの名前。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/export_relations/status"
```

ステータスは次のいずれかになります:

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

## エクスポートをダウンロードする {#download-an-export}

完了したリレーションエクスポートをダウンロードします。

```plaintext
GET /groups/:id/export_relations/download
```

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|------------ |
| `id`           | 整数または文字列 | はい      | グループのID。 |
| `relation`     | 文字列            | はい      | ダウンロードするグループトップレベルリレーションの名前。 |
| `batched`      | ブール値           | いいえ       | エクスポートがバッチ処理されているかどうか。 |
| `batch_number` | 整数           | いいえ       | ダウンロードするエクスポートバッチの数。 |

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
