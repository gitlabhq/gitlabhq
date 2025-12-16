---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabグループ内のリポジトリのストレージを移動するためのREST APIのドキュメント。
title: グループリポジトリストレージ移動API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

グループウィキリポジトリは、ストレージ間で移動できます。たとえば、このAPIを使用すると、[Gitalyクラスタリング (Praefect) に移行する](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)か、[グループWiki](../user/project/wiki/group.md)を移行できます。このAPIは、グループ内のプロジェクトリポジトリを管理しません。プロジェクトの移動をスケジュールするには、[プロジェクトリポジトリストレージ移動API](project_repository_storage_moves.md)を使用します。

GitLabがグループリポジトリストレージの移動を処理すると、さまざまな状態に移行します。`state`の値は次のとおりです:

- `initial`: レコードは作成されましたが、バックグラウンドジョブはまだスケジュールされていません。
- `scheduled`: バックグラウンドジョブがスケジュールされました。
- `started`: グループリポジトリは、宛先ストレージにコピーされています。
- `replicated`: グループが移動されました。
- `failed`: グループリポジトリのコピーに失敗したか、チェックサムが一致しませんでした。
- `finished`: グループが移動され、ソースストレージ上のリポジトリが削除されました。
- `cleanup failed`: グループは移動されましたが、ソースストレージ上のリポジトリを削除できませんでした。

データの整合性を確保するため、GitLabは移動中、グループを一時的な読み取り専用状態にします。この間、新しいコミットをプッシュしようとすると、ユーザーに次のメッセージが表示されます:

```plaintext
The repository is temporarily read-only. Please try again later.
```

このAPIでは、[認証](rest/authentication.md)を管理者として行う必要があります。

他の種類のリポジトリを移動するためのAPIも利用できます:

- [プロジェクトリポジトリストレージ移動API](project_repository_storage_moves.md)。
- [スニペットリポジトリストレージ移動API](snippet_repository_storage_moves.md)

## すべてのグループリポジトリストレージの移動を取得します {#retrieve-all-group-repository-storage-moves}

```plaintext
GET /group_repository_storage_moves
```

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

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

## 単一グループのすべてのリポジトリストレージ移動を取得します {#retrieve-all-repository-storage-moves-for-a-single-group}

単一グループのすべてのリポジトリストレージ移動を取得するには、次のエンドポイントを使用します:

```plaintext
GET /groups/:group_id/repository_storage_moves
```

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

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

## 単一グループリポジトリストレージの移動を取得します {#get-a-single-group-repository-storage-move}

既存のすべてのリポジトリストレージ移動全体で単一のリポジトリストレージ移動を取得するには、次のエンドポイントを使用します:

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

## グループの単一リポジトリストレージ移動を取得します {#get-a-single-repository-storage-move-for-a-group}

グループが指定されている場合、次のエンドポイントを使用して、そのグループの特定のリポジトリストレージ移動を取得できます:

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

## グループのリポジトリストレージ移動をスケジュールします {#schedule-a-repository-storage-move-for-a-group}

グループのリポジトリストレージ移動をスケジュールします。このエンドポイントは、次のように動作します:

- グループウィキリポジトリのみを移動します。
- グループ内のプロジェクトのリポジトリを移動しません。プロジェクトの移動をスケジュールするには、[プロジェクトリポジトリストレージ移動](project_repository_storage_moves.md)APIを使用します。

```plaintext
POST /groups/:group_id/repository_storage_moves
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `group_id` | 整数 | はい | グループのID。 |
| `destination_storage_name` | 文字列 | いいえ | 宛先ストレージシャードの名前。ストレージが指定されていない場合は、[ストレージウェイトに基づいて](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)選択されます。 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
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

## ストレージシャード上のすべてのグループのリポジトリストレージ移動をスケジュールします {#schedule-repository-storage-moves-for-all-groups-on-a-storage-shard}

ソースストレージシャードに格納されているグループリポジトリごとに、リポジトリストレージ移動をスケジュールします。このエンドポイントは、すべてのグループを一度に移行します。

```plaintext
POST /group_repository_storage_moves
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | 文字列 | はい | ソースストレージシャードの名前。 |
| `destination_storage_name` | 文字列 | いいえ | 宛先ストレージシャードの名前。ストレージが指定されていない場合は、[ストレージウェイトに基づいて](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)選択されます。 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
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

- [GitLabで管理されているリポジトリの移動](../administration/operations/moving_repositories.md)
