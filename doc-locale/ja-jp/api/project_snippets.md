---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトスニペット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[プロジェクトスニペット](../user/snippets.md)を管理します。関連するAPIは、[個人スニペット](snippets.md)および[ストレージ間のスニペット移動](snippet_repository_storage_moves.md)に存在します。

## プロジェクトのすべてのスニペットを一覧表示 {#list-all-snippets-for-a-project}

指定されたプロジェクトのすべてのスニペットを一覧表示します。

```plaintext
GET /projects/:id/snippets
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `author.created_at` | 文字列  | 作成者アカウントが作成された日付と時刻。 |
| `author.email`      | 文字列  | スニペット作成者のメールアドレス。 |
| `author.id`         | 整数 | スニペット作成者のID。 |
| `author.name`       | 文字列  | スニペット作成者の表示名。 |
| `author.state`      | 文字列  | 作成者アカウントの状態。 |
| `author.username`   | 文字列  | スニペット作成者のユーザー名。 |
| `created_at`        | 文字列  | スニペットがISO 8601形式で作成された日付と時刻。 |
| `description`       | 文字列  | スニペットの説明。 |
| `file_name`         | 文字列  | スニペットファイルの名前。 |
| `id`                | 整数 | スニペットのID。 |
| `imported`          | ブール値 | `true`の場合、スニペットがインポートされました。 |
| `imported_from`     | 文字列  | スニペットがインポートされた場合のインポート元。 |
| `project_id`        | 整数 | スニペットを含むプロジェクトのID。 |
| `raw_url`           | 文字列  | rawスニペットコンテンツへの直接URL。 |
| `title`             | 文字列  | スニペットのタイトル。 |
| `updated_at`        | 文字列  | スニペットがISO 8601形式で最後に更新された日付と時刻。 |
| `web_url`           | 文字列  | GitLabウェブインターフェースでスニペットを表示するためのURL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "title": "test",
    "file_name": "add.rb",
    "description": "Ruby test snippet",
    "author": {
      "id": 1,
      "username": "john_smith",
      "email": "john@example.com",
      "name": "John Smith",
      "state": "active",
      "created_at": "2012-05-23T08:00:58Z"
    },
    "updated_at": "2012-06-28T10:52:04Z",
    "created_at": "2012-06-28T10:52:04Z",
    "imported": false,
    "imported_from": "none",
    "project_id": 1,
    "web_url": "http://example.com/example/example/snippets/1",
    "raw_url": "http://example.com/example/example/snippets/1/raw"
  },
  {
    "id": 3,
    "title": "Configuration helper",
    "file_name": "config.yml",
    "description": "YAML configuration snippet",
    "author": {
      "id": 2,
      "username": "jane_doe",
      "email": "jane@example.com",
      "name": "Jane Doe",
      "state": "active",
      "created_at": "2013-02-15T10:30:20Z"
    },
    "updated_at": "2013-03-10T14:15:30Z",
    "created_at": "2013-03-01T09:45:12Z",
    "imported": false,
    "imported_from": "none",
    "project_id": 1,
    "web_url": "http://example.com/example/example/snippets/3",
    "raw_url": "http://example.com/example/example/snippets/3/raw"
  }
]
```

## スニペットを取得する {#retrieve-a-snippet}

指定されたプロジェクトスニペットを取得する。

```plaintext
GET /projects/:id/snippets/:snippet_id
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | プロジェクトスニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `author.created_at` | 文字列  | 作成者アカウントが作成された日付と時刻。 |
| `author.email`      | 文字列  | スニペット作成者のメールアドレス。 |
| `author.id`         | 整数 | スニペット作成者のID。 |
| `author.name`       | 文字列  | スニペット作成者の表示名。 |
| `author.state`      | 文字列  | 作成者アカウントの状態。 |
| `author.username`   | 文字列  | スニペット作成者のユーザー名。 |
| `created_at`        | 文字列  | スニペットがISO 8601形式で作成された日付と時刻。 |
| `description`       | 文字列  | スニペットの説明。 |
| `file_name`         | 文字列  | スニペットファイルの名前。 |
| `id`                | 整数 | スニペットのID。 |
| `imported`          | ブール値 | `true`の場合、スニペットがインポートされました。 |
| `imported_from`     | 文字列  | スニペットがインポートされた場合のインポート元。 |
| `project_id`        | 整数 | スニペットを含むプロジェクトのID。 |
| `raw_url`           | 文字列  | rawスニペットコンテンツへの直接URL。 |
| `title`             | 文字列  | スニペットのタイトル。 |
| `updated_at`        | 文字列  | スニペットがISO 8601形式で最後に更新された日付と時刻。 |
| `web_url`           | 文字列  | GitLabウェブインターフェースでスニペットを表示するためのURL。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

レスポンス例: 

```json
{
  "id": 2,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/2",
  "raw_url": "http://example.com/example/example/snippets/2/raw"
}
```

## スニペットを作成する {#create-a-snippet}

プロジェクトスニペットを作成します。ユーザーはスニペットを作成する権限を持っている必要があります。

```plaintext
POST /projects/:id/snippets
```

サポートされている属性は以下のとおりです: 

| 属性         | 型              | 必須 | 説明 |
|-------------------|-------------------|----------|-------------|
| `files`           | ハッシュの配列   | はい      | スニペットファイルの配列。 |
| `files:content`   | 文字列            | はい      | スニペットファイルの内容。 |
| `files:file_path` | 文字列            | はい      | スニペットファイルのパス。 |
| `id`              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `title`           | 文字列            | はい      | スニペットのタイトル。 |
| `content`         | 文字列            | いいえ       | 非推奨: 代わりに`files`を使用してください。スニペットの内容。 |
| `description`     | 文字列            | いいえ       | スニペットの説明。 |
| `file_name`       | 文字列            | いいえ       | 非推奨: 代わりに`files`を使用してください。スニペットファイルの名前。 |
| `visibility`      | 文字列            | いいえ       | スニペットの表示レベル。設定可能な値: `public`、`private`、および`internal`。GitLab.comでは、`internal`の値は利用できません。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `author.created_at` | 文字列  | 作成者アカウントが作成された日付と時刻。 |
| `author.email`      | 文字列  | スニペット作成者のメールアドレス。 |
| `author.id`         | 整数 | スニペット作成者のID。 |
| `author.name`       | 文字列  | スニペット作成者の表示名。 |
| `author.state`      | 文字列  | 作成者アカウントの状態。 |
| `author.username`   | 文字列  | スニペット作成者のユーザー名。 |
| `created_at`        | 文字列  | スニペットがISO 8601形式で作成された日付と時刻。 |
| `description`       | 文字列  | スニペットの説明。 |
| `file_name`         | 文字列  | スニペットファイルの名前。 |
| `id`                | 整数 | スニペットのID。 |
| `imported`          | ブール値 | `true`の場合、スニペットがインポートされました。 |
| `imported_from`     | 文字列  | スニペットがインポートされた場合のインポート元。 |
| `project_id`        | 整数 | スニペットを含むプロジェクトのID。 |
| `raw_url`           | 文字列  | rawスニペットコンテンツへの直接URL。 |
| `title`             | 文字列  | スニペットのタイトル。 |
| `updated_at`        | 文字列  | スニペットがISO 8601形式で最後に更新された日付と時刻。 |
| `web_url`           | 文字列  | GitLabウェブインターフェースでスニペットを表示するためのURL。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"title": "Example Snippet Title", "description": "More verbose snippet description", "visibility": "private", "files": [{"file_path": "example.txt", "content": "source code \n with multiple lines\n"}]}' \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets"
```

レスポンス例: 

```json
{
  "id": 1,
  "title": "Example Snippet Title",
  "file_name": "example.txt",
  "description": "More verbose snippet description",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/1",
  "raw_url": "http://example.com/example/example/snippets/1/raw"
}
```

## スニペットを更新 {#update-a-snippet}

指定されたプロジェクトスニペットを更新します。ユーザーは既存のスニペットを変更する権限を持っている必要があります。

複数のファイルを持つスニペットの更新では、`files`属性を使用する必要があります。

```plaintext
PUT /projects/:id/snippets/:snippet_id
```

サポートされている属性は以下のとおりです: 

| 属性             | 型              | 必須      | 説明 |
| --------------------- | ----------------- | ------------- | ----------- |
| `id`                  | 整数または文字列 | はい           | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id`          | 整数           | はい           | プロジェクトスニペットのID。 |
| `files:action`        | 文字列            | 条件付き | ファイルに対して実行するアクションのタイプ。次のいずれか: `create`、`update`、`delete`、`move`。`files`属性を使用する場合に必須です。 |
| `content`             | 文字列            | いいえ            | 非推奨: 代わりに`files`を使用してください。スニペットの内容。 |
| `description`         | 文字列            | いいえ            | スニペットの説明。 |
| `file_name`           | 文字列            | いいえ            | 非推奨: 代わりに`files`を使用してください。スニペットファイルの名前。 |
| `files`               | ハッシュの配列   | いいえ            | スニペットファイルの配列。 |
| `files:content`       | 文字列            | いいえ            | スニペットファイルの内容。 |
| `files:file_path`     | 文字列            | いいえ            | スニペットファイルのパス。 |
| `files:previous_path` | 文字列            | いいえ            | スニペットファイルの以前のパス。 |
| `title`               | 文字列            | いいえ            | スニペットのタイトル。 |
| `visibility`      | 文字列            | いいえ       | スニペットの表示レベル。設定可能な値: `public`、`private`、および`internal`。GitLab.comでは、`internal`の値は利用できません。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `author.created_at` | 文字列  | 作成者アカウントが作成された日付と時刻。 |
| `author.email`      | 文字列  | スニペット作成者のメールアドレス。 |
| `author.id`         | 整数 | スニペット作成者のID。 |
| `author.name`       | 文字列  | スニペット作成者の表示名。 |
| `author.state`      | 文字列  | 作成者アカウントの状態。 |
| `author.username`   | 文字列  | スニペット作成者のユーザー名。 |
| `created_at`        | 文字列  | スニペットがISO 8601形式で作成された日付と時刻。 |
| `description`       | 文字列  | スニペットの説明。 |
| `file_name`         | 文字列  | スニペットファイルの名前。 |
| `id`                | 整数 | スニペットのID。 |
| `imported`          | ブール値 | `true`の場合、スニペットがインポートされました。 |
| `imported_from`     | 文字列  | スニペットがインポートされた場合のインポート元。 |
| `project_id`        | 整数 | スニペットを含むプロジェクトのID。 |
| `raw_url`           | 文字列  | rawスニペットコンテンツへの直接URL。 |
| `title`             | 文字列  | スニペットのタイトル。 |
| `updated_at`        | 文字列  | スニペットがISO 8601形式で最後に更新された日付と時刻。 |
| `web_url`           | 文字列  | GitLabウェブインターフェースでスニペットを表示するためのURL。 |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"title": "Updated Snippet Title", "description": "More verbose snippet description", "visibility": "private", "files": [{"action": "update", "file_path": "example.txt", "content": "updated source code \n with multiple lines\n"}]}' \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

レスポンス例: 

```json
{
  "id": 2,
  "title": "Updated Snippet Title",
  "file_name": "example.txt",
  "description": "More verbose snippet description",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "imported": false,
  "imported_from": "none",
  "project_id": 1,
  "web_url": "http://example.com/example/example/snippets/2",
  "raw_url": "http://example.com/example/example/snippets/2/raw"
}
```

## スニペットを削除 {#delete-a-snippet}

指定されたプロジェクトスニペットを削除します。操作が成功した場合は`204 No Content`ステータスコード、リソースが見つからなかった場合は`404`を返します。

```plaintext
DELETE /projects/:id/snippets/:snippet_id
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | プロジェクトスニペットのID。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

## スニペットコンテンツを取得する {#retrieve-snippet-content}

rawプロジェクトスニペットをプレーンテキストとして取得する。

```plaintext
GET /projects/:id/snippets/:snippet_id/raw
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | プロジェクトスニペットのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/raw"
```

## スニペットリポジトリファイルコンテンツを取得する {#retrieve-snippet-repository-file-content}

rawファイルコンテンツをプレーンテキストとして取得する。

```plaintext
GET /projects/:id/snippets/:snippet_id/files/:ref/:file_path/raw
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `file_path`  | 文字列            | はい      | URLエンコードされたファイルへのパス (例: `snippet%2Erb`)。 |
| `ref`        | 文字列            | はい      | ブランチ、タグ、またはコミットの名前 (例: `main`)。 |
| `snippet_id` | 整数           | はい      | プロジェクトスニペットのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/files/master/snippet%2Erb/raw"
```

## User agentの詳細を取得する {#retrieve-user-agent-details}

指定されたスニペットのUser agentの詳細を取得する。管理者アクセスを持つユーザーのみ利用可能です。

```plaintext
GET /projects/:id/snippets/:snippet_id/user_agent_detail
```

サポートされている属性は以下のとおりです: 

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | スニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `akismet_submitted` | ブール値 | `true`の場合、スニペットはスパム検出のためにAkismetに送信されました。 |
| `ip_address`        | 文字列  | スニペットを作成したユーザーのIPアドレス。 |
| `user_agent`        | 文字列  | スニペットを作成するために使用されたブラウザのUser agent文字列。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/user_agent_detail"
```

レスポンス例: 

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```
