---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スニペットリポジトリストレージ移動API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

スニペットリポジトリは、ストレージ間で移動できます。たとえば、このAPIは、[Gitalyクラスター（Praefect）への移行](../administration/gitaly/praefect/_index.md#migrate-to-gitaly-cluster-praefect)時に役立ちます。

スニペットリポジトリストレージの移動が処理されると、さまざまな状態に移行します。`state`の値は次のとおりです:

- `initial`: レコードは作成されましたが、バックグラウンドジョブはまだスケジュールされていません。
- `scheduled`: バックグラウンドジョブがスケジュールされました。
- `started`: スニペットリポジトリが、宛先ストレージにコピーされています。
- `replicated`: スニペットが移動されました。
- `failed`: スニペットリポジトリのコピーに失敗したか、チェックサムが一致しませんでした。
- `finished`: スニペットが移動され、ソースストレージ上のリポジトリが削除されました。
- `cleanup failed`: スニペットは移動されましたが、ソースストレージ上のリポジトリを削除できませんでした。

データの整合性を確保するため、移動中はスニペットが一時的な読み取り専用状態になります。この間、新しいコミットをプッシュしようとすると、`The repository is temporarily read-only. Please try again later.`というメッセージが表示されます。

このAPIを使用するには、[管理者として認証する](rest/authentication.md)必要があります。

他のリポジトリタイプについては、以下を参照してください:

- [プロジェクトリポジトリのストレージ移動API](project_repository_storage_moves.md)。
- [グループリポジトリストレージ移動API](group_repository_storage_moves.md)。

## すべてのスニペットリポジトリストレージの移動を取得します {#retrieve-all-snippet-repository-storage-moves}

```plaintext
GET /snippet_repository_storage_moves
```

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
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
    "snippet": {
      "id": 65,
      "title": "Test Snippet",
      "description": null,
      "visibility": "internal",
      "updated_at": "2020-12-01T11:15:50.385Z",
      "created_at": "2020-12-01T11:15:50.385Z",
      "project_id": null,
      "web_url": "https://gitlab.example.com/-/snippets/65",
      "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
      "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
      "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
    }
  }
]
```

## スニペットのすべてのリポジトリストレージの移動を取得します {#retrieve-all-repository-storage-moves-for-a-snippet}

```plaintext
GET /snippets/:snippet_id/repository_storage_moves
```

APIの結果は[ページネーション](rest/_index.md#pagination)されるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | 整数 | はい | スニペットのID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
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
    "snippet": {
      "id": 65,
      "title": "Test Snippet",
      "description": null,
      "visibility": "internal",
      "updated_at": "2020-12-01T11:15:50.385Z",
      "created_at": "2020-12-01T11:15:50.385Z",
      "project_id": null,
      "web_url": "https://gitlab.example.com/-/snippets/65",
      "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
      "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
      "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
    }
  }
]
```

## 単一のスニペットリポジトリストレージの移動を取得します {#get-a-single-snippet-repository-storage-move}

```plaintext
GET /snippet_repository_storage_moves/:repository_storage_id
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `repository_storage_id` | 整数 | はい | スニペットリポジトリストレージ移動のID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves/1"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## スニペットの単一リポジトリストレージ移動を取得します {#get-a-single-repository-storage-move-for-a-snippet}

```plaintext
GET /snippets/:snippet_id/repository_storage_moves/:repository_storage_id
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | 整数 | はい | スニペットのID。 |
| `repository_storage_id` | 整数 | はい | スニペットリポジトリストレージ移動のID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves/1"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## スニペットのリポジトリストレージ移動をスケジュールします {#schedule-a-repository-storage-move-for-a-snippet}

```plaintext
POST /snippets/:snippet_id/repository_storage_moves
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `snippet_id` | 整数 | はい | スニペットのID。 |
| `destination_storage_name` | 文字列 | いいえ | 宛先ストレージシャードの名前。ストレージが指定されていない場合、[ストレージウェイトに基づいて自動的に](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)選択されます。 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"destination_storage_name":"storage2"}' \
     --url "https://gitlab.example.com/api/v4/snippets/1/repository_storage_moves"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2020-05-07T04:27:17.234Z",
  "state": "scheduled",
  "source_storage_name": "default",
  "destination_storage_name": "storage2",
  "snippet": {
    "id": 65,
    "title": "Test Snippet",
    "description": null,
    "visibility": "internal",
    "updated_at": "2020-12-01T11:15:50.385Z",
    "created_at": "2020-12-01T11:15:50.385Z",
    "project_id": null,
    "web_url": "https://gitlab.example.com/-/snippets/65",
    "raw_url": "https://gitlab.example.com/-/snippets/65/raw",
    "ssh_url_to_repo": "ssh://user@gitlab.example.com/snippets/65.git",
    "http_url_to_repo": "https://gitlab.example.com/snippets/65.git"
  }
}
```

## ストレージシャード上のすべてのスニペットについて、リポジトリストレージの移動をスケジュールします {#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard}

ソースストレージシャードに保存されている各スニペットリポジトリについて、リポジトリストレージの移動をスケジュールします。このエンドポイントは、すべてのスニペットを一度に移行します。

```plaintext
POST /snippet_repository_storage_moves
```

サポートされている属性は以下のとおりです:

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `source_storage_name` | 文字列 | はい | ソースストレージシャードの名前。 |
| `destination_storage_name` | 文字列 | いいえ | 宛先ストレージシャードの名前。ストレージが指定されていない場合、[ストレージウェイトに基づいて自動的に](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)選択されます。 |

リクエスト例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"source_storage_name":"default"}' \
     --url "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
```

レスポンス例:

```json
{
  "message": "202 Accepted"
}
```

## 関連トピック {#related-topics}

- [GitLabで管理されているリポジトリの移動](../administration/operations/moving_repositories.md)
