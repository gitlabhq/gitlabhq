---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトリポジトリストレージの移動API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトリポジトリ（Wikiやデザインリポジトリを含む）は、ストレージ間で移動できます。このAPIは、例えば[Gitalyクラスター (Praefect) へ移行する](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)際に役立ちます。

プロジェクトリポジトリストレージの移動が処理されると、それらは異なる状態を移行します。`state`の値は次のとおりです:

- `initial`: レコードは作成されましたが、バックグラウンドジョブはまだスケジュールされていません。
- `scheduled`: バックグラウンドジョブがスケジュールされました。
- `started`: プロジェクトリポジトリは移行先ストレージにコピーされています。
- `replicated`: プロジェクトが移動されました。
- `failed`: プロジェクトリポジトリのコピーに失敗したか、チェックサムが一致しませんでした。
- `finished`: プロジェクトが移動され、ソースストレージ上のリポジトリは削除されました。
- `cleanup failed`: プロジェクトは移動されましたが、ソースストレージ上のリポジトリは削除できませんでした。

データ整合性を確保するため、移動期間中、プロジェクトは一時的な読み取り専用状態になります。この期間中、ユーザーが新しいコミットをプッシュしようとすると、`The repository is temporarily read-only. Please try again later.`メッセージを受け取ります。

このAPIを使用するには、管理者として[認証する](rest/authentication.md)必要があります。

他のリポジトリの種類については、以下を参照してください:

- [スニペットリポジトリストレージ移動API](snippet_repository_storage_moves.md)。
- [グループリポジトリストレージの移動API](group_repository_storage_moves.md)。

## すべてのプロジェクトリポジトリストレージの移動を一覧表示 {#list-all-project-repository-storage-moves}

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

## プロジェクトのすべてのリポジトリストレージの移動を一覧表示 {#list-all-repository-storage-moves-for-a-project}

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

## プロジェクトリポジトリストレージの移動を取得する {#retrieve-a-project-repository-storage-move}

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

## プロジェクトのリポジトリストレージの移動を取得する {#retrieve-a-repository-storage-move-for-a-project}

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

## プロジェクトのリポジトリストレージの移動を作成する {#create-a-repository-storage-move-for-a-project}

```plaintext
POST /projects/:project_id/repository_storage_moves
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明                                                                                                                                                                                                        |
| --------- | ---- | -------- |--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `project_id` | 整数 | はい | プロジェクトのID                                                                                                                                                                                                  |
| `destination_storage_name` | 文字列 | いいえ | 移行先ストレージのシャードの名前。指定されない場合、ストレージは[ストレージのウェイトに基づいて自動的に](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)選択されます |

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

## ストレージのシャード上のすべてのプロジェクトのリポジトリストレージの移動を作成する {#create-repository-storage-moves-for-all-projects-on-a-storage-shard}

ソースストレージシャードに保存されている各プロジェクトリポジトリに対して、リポジトリストレージの移動を作成します。このエンドポイントは、すべてのプロジェクトを一括で移行します。

```plaintext
POST /project_repository_storage_moves
```

パラメータは以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | 文字列 | はい | ソースストレージのシャードの名前。 |
| `destination_storage_name` | 文字列 | いいえ | 移行先ストレージのシャードの名前。指定されない場合、ストレージは[ストレージのウェイトに基づいて自動的に](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)選択されます。 |

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
