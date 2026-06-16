---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabグループ内のリポジトリストレージを移動するためのREST APIに関するドキュメント。
title: グループリポジトリストレージ移動API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[グループリポジトリストレージの移動](../administration/operations/moving_repositories.md)を管理します。このAPIは、例えば、[Gitaly Cluster (Praefect)へ移行する](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect) 、または[グループWiki](../user/project/wiki/group.md)を移行するのに役立ちます。このAPIは、グループ内のプロジェクトリポジトリストレージを管理しません。プロジェクトの移動をスケジュールするには、[プロジェクトリポジトリストレージ移動API](project_repository_storage_moves.md)を使用します。

GitLabがグループリポジトリストレージの移動を処理する際に、さまざまな状態を移行します。`state`の値は次のとおりです:

- `initial`: レコードは作成されましたが、バックグラウンドジョブはまだスケジュールされていません。
- `scheduled`: バックグラウンドジョブがスケジュールされました。
- `started`: グループリポジトリストレージがターゲットストレージにコピーされています。
- `replicated`: グループが移動されました。
- `failed`: グループリポジトリストレージのコピーに失敗したか、チェックサムが一致しませんでした。
- `finished`: グループは移動され、ソーストレージ上のリポジトリストレージは削除されました。
- `cleanup failed`: グループは移動されましたが、ソーストレージ上のリポジトリストレージを削除できませんでした。

データの一貫性を確保するため、GitLabは移動期間中、グループを一時的な読み取り専用状態にします。この間、ユーザーが新しいコミットをプッシュすると、このメッセージが表示されます:

```plaintext
The repository is temporarily read-only. Please try again later.
```

このAPIを使用するには、管理者として[認証する](rest/authentication.md)必要があります。

他の種類のリポジトリストレージを移動するためのAPIも利用できます:

- [プロジェクトリポジトリストレージ移動API](project_repository_storage_moves.md)。
- [スニペットリポジトリストレージ移動API](snippet_repository_storage_moves.md)。

## すべてのグループリポジトリストレージ移動を一覧表示 {#list-all-group-repository-storage-moves}

インスタンスのすべてのグループリポジトリストレージ移動を一覧表示します。

```plaintext
GET /group_repository_storage_moves
```

デフォルトでは、`GET`リクエストは一度に20件の結果を返します。これは、APIの結果が[ページ分割されている](rest/_index.md#pagination)ためです。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/group_repository_storage_moves"
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
    "group": {
      "id": 283,
      "web_url": "https://gitlab.example.com/groups/testgroup",
      "name": "testgroup"
    }
  }
]
```

## グループのすべてのリポジトリストレージ移動を一覧表示 {#list-all-repository-storage-moves-for-a-group}

指定されたグループのすべてのリポジトリストレージ移動を一覧表示します。

```plaintext
GET /groups/:group_id/repository_storage_moves
```

デフォルトでは、`GET`リクエストは一度に20件の結果を返します。これは、APIの結果が[ページ分割されている](rest/_index.md#pagination)ためです。

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `group_id` | 整数 | はい | グループのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
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
    "group": {
      "id": 283,
      "web_url": "https://gitlab.example.com/groups/testgroup",
      "name": "testgroup"
    }
  }
]
```

## グループリポジトリストレージ移動を取得する {#retrieve-a-group-repository-storage-move}

指定されたグループリポジトリストレージ移動を取得します。

```plaintext
GET /group_repository_storage_moves/:repository_storage_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | 整数 | はい | グループリポジトリストレージ移動のID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/group_repository_storage_moves/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## グループのリポジトリストレージ移動を取得する {#retrieve-a-repository-storage-move-for-a-group}

グループの指定されたリポジトリストレージ移動を取得します。

```plaintext
GET /groups/:group_id/repository_storage_moves/:repository_storage_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `group_id` | 整数 | はい | グループのID。 |
| `repository_storage_id` | 整数 | はい | グループリポジトリストレージ移動のID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## グループリポジトリストレージ移動を作成 {#create-a-group-repository-storage-move}

指定されたグループのグループリポジトリストレージ移動を作成します。このエンドポイントは、次のように動作します。

- グループWikiリポジトリストレージのみを移動します。
- グループ内のプロジェクトのリポジトリストレージは移動しません。プロジェクトの移動をスケジュールするには、[プロジェクトリポジトリストレージ移動](project_repository_storage_moves.md) APIを使用します。

```plaintext
POST /groups/:group_id/repository_storage_moves
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `group_id` | 整数 | はい | グループのID。 |
| `destination_storage_name` | 文字列 | いいえ | ターゲットストレージシャードの名前。指定がない場合、[ストレージウェイトに基づいて](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)ストレージが選択されます。 |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"destination_storage_name":"storage2"}' \
     --url "https://gitlab.example.com/api/v4/groups/1/repository_storage_moves"
```

レスポンス例: 

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "group": {
    "id": 283,
    "web_url": "https://gitlab.example.com/groups/testgroup",
    "name": "testgroup"
  }
}
```

## ストレージシャードのグループリポジトリストレージ移動を作成 {#create-group-repository-storage-moves-for-a-storage-shard}

指定されたストレージシャード上のすべてのグループのリポジトリストレージ移動を作成します。

```plaintext
POST /group_repository_storage_moves
```

サポートされている属性は以下のとおりです: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | 文字列 | はい | ソーストレージシャードの名前。 |
| `destination_storage_name` | 文字列 | いいえ | ターゲットストレージシャードの名前。指定がない場合、[ストレージウェイトに基づいて](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)ストレージが選択されます。 |

リクエスト例: 

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"source_storage_name":"default"}' \
     --url "https://gitlab.example.com/api/v4/group_repository_storage_moves"
```

レスポンス例: 

```json
{
  "message": "202 Accepted"
}
```

## 関連トピック {#related-topics}

- [GitLabで管理されるリポジトリストレージの移動](../administration/operations/moving_repositories.md)
