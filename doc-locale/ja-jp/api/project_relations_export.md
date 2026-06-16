---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクト関連エクスポートAPI
description: "REST APIを使用してプロジェクト関連をエクスポートする。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIは、プロジェクト構造を移行するために、[ダイレクト転送によるグループ移行](../user/group/import/_index.md)中に宛先インスタンスによって使用されます。通常、このAPIを自分で使用する必要はありません。

このコンテキストでは、{{< glossary-tooltip text="関係" >}}はマージリクエストなどのエクスポート可能な項目です。関係をエクスポートすると、ラベルなど、その関係に関連するすべての項目が含まれます。

このAPIを使用する場合は、GitLabのインスタンスが特定の[前提条件](../user/group/import/direct_transfer_migrations.md#prerequisites)を満たしている必要があります。

> [!note]
> このAPIは、ファイルベースの移行用の[グループインポートおよびエクスポートAPI](group_import_export.md)では使用できません。

## プロジェクトの新規エクスポートをスケジュールする {#schedule-a-new-export-for-a-project}

指定されたプロジェクトの関連エクスポートをスケジュールします。

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

## エクスポートのステータスを取得する {#retrieve-the-status-of-an-export}

関連エクスポートのステータスを取得する。

```plaintext
GET /projects/:id/export_relations/status
```

| 属性  | 型              | 必須 | 説明                                        |
|------------|-------------------|----------|----------------------------------------------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのID。                                 |
| `relation` | 文字列            | いいえ       | 表示するプロジェクトのトップレベル関連の名前。    |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export_relations/status"
```

ステータスは次のいずれかです:

- `0`: `started` (開始済み)
- `1`: `finished` (開始済み)
- `-1`: `failed` (開始済み)

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

## エクスポートをダウンロード {#download-an-export}

完了した関連エクスポートをダウンロードします。

```plaintext
GET /projects/:id/export_relations/download
```

| 属性      | 型              | 必須 | 説明 |
|----------------|-------------------|----------|-------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのID。 |
| `relation`     | 文字列            | はい      | ダウンロードするプロジェクトのトップレベル関連の名前。 |
| `batched`      | ブール値           | いいえ       | エクスポートがバッチ処理されているかどうか。 |
| `batch_number` | 整数           | いいえ       | ダウンロードするエクスポートバッチの番号。 |

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

- [グループリレーションエクスポートAPI](group_relations_export.md)
