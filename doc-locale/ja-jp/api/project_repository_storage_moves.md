---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトリポジトリストレージ移動API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Wikiやデザインリポジトリを含むプロジェクトリポジトリは、ストレージ間で移行できます。このAPIは、たとえば、[Gitaly Cluster (Praefect)への移行](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)に役立ちます。

プロジェクトリポジトリストレージの移行が処理されると、さまざまな状態に移行します。`state`の値は次のとおりです:

- `initial`: レコードは作成されましたが、バックグラウンドジョブはまだスケジュールされていません。
- `scheduled`: バックグラウンドジョブがスケジュールされました。
- `started`: プロジェクトリポジトリは、宛先ストレージにコピーされています。
- `replicated`: プロジェクトが移動されました。
- `failed`: プロジェクトリポジトリのコピーに失敗したか、チェックサムが一致しませんでした。
- `finished`: プロジェクトが移動され、ソースストレージのリポジトリが削除されました。
- `cleanup failed`: プロジェクトは移動されましたが、ソースストレージのリポジトリを削除できませんでした。

データの整合性を確保するために、プロジェクトは移動中、一時的な読み取り専用状態になります。この間、新しいコミットをプッシュしようとすると、`The repository is temporarily read-only. Please try again later.`というメッセージが表示されます。

このAPIを使用するには、[認証する](rest/authentication.md)必要があります（管理者として）。

他のリポジトリタイプについては、以下を参照してください:

- スニペットリポジトリストレージ移動[API](snippet_repository_storage_moves.md)。
- [グループリポジトリストレージ移動API](group_repository_storage_moves.md)

## すべてのプロジェクトリポジトリストレージの移動を取得します {#retrieve-all-project-repository-storage-moves}

```plaintext
GET /project_repository_storage_moves
```

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "project": {
      "id": 1,
      "description": null,
      "name": "project1",
      "name_with_namespace": "John Doe2 / project1",
      "path": "project1",
      "path_with_namespace": "namespace1/project1",
      "created_at": "2020-05-07T04:27:17.016Z"
    }
  }
]
```

## プロジェクトのすべてのリポジトリストレージの移動を取得します {#retrieve-all-repository-storage-moves-for-a-project}

```plaintext
GET /projects/:project_id/repository_storage_moves
```

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `project_id` | 整数 | はい | プロジェクトのID |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "created_at": "2020-05-07T04:27:17.234Z",
    "state": "scheduled",
    "source_storage_name": "default",
    "destination_storage_name": "storage2",
    "project": {
      "id": 1,
      "description": null,
      "name": "project1",
      "name_with_namespace": "John Doe2 / project1",
      "path": "project1",
      "path_with_namespace": "namespace1/project1",
      "created_at": "2020-05-07T04:27:17.016Z"
    }
  }
]
```

## 単一のプロジェクトリポジトリストレージの移動を取得します {#get-a-single-project-repository-storage-move}

```plaintext
GET /project_repository_storage_moves/:repository_storage_id
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | 整数 | はい | プロジェクトリポジトリストレージの移動のID |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves/1"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## プロジェクトの単一のリポジトリストレージの移動を取得します {#get-a-single-repository-storage-move-for-a-project}

```plaintext
GET /projects/:project_id/repository_storage_moves/:repository_storage_id
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `project_id` | 整数 | はい | プロジェクトのID |
| `repository_storage_id` | 整数 | はい | プロジェクトリポジトリストレージの移動のID |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves/1"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## プロジェクトのリポジトリストレージの移動をスケジュールします {#schedule-a-repository-storage-move-for-a-project}

```plaintext
POST /projects/:project_id/repository_storage_moves
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明                                                                                                                                                                                                        |
| --------- | ---- | -------- |--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `project_id` | 整数 | はい | プロジェクトのID                                                                                                                                                                                                  |
| `destination_storage_name` | 文字列 | いいえ | 宛先ストレージシャードの名前。ストレージが指定されていない場合、[ストレージウェイトに基づいて自動的に選択](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)されます |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"destination_storage_name":"storage2"}' \
  --url "https://gitlab.example.com/api/v4/projects/1/repository_storage_moves"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2020-05-07T04:27:17.016Z"
  }
}
```

## ストレージシャード上のすべてのプロジェクトのリポジトリストレージの移動をスケジュールします {#schedule-repository-storage-moves-for-all-projects-on-a-storage-shard}

ソースストレージシャードに保存されている各プロジェクトリポジトリのリポジトリストレージの移動をスケジュールします。このエンドポイントは、すべてのプロジェクトを一度に移行します。

```plaintext
POST /project_repository_storage_moves
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | 文字列 | はい | ソースストレージシャードの名前。 |
| `destination_storage_name` | 文字列 | いいえ | 宛先ストレージシャードの名前。ストレージが指定されていない場合、[ストレージウェイトに基づいて自動的に選択](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)されます。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"source_storage_name":"default"}' \
  --url "https://gitlab.example.com/api/v4/project_repository_storage_moves"
```

レスポンス例:

```json
{
  "message": "202 Accepted"
}
```

## 関連トピック {#related-topics}

- [GitLabで管理されているリポジトリの移動](../administration/operations/moving_repositories.md)
