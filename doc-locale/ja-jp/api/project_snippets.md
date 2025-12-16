---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトスニペット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトスニペットAPIを使用して、スニペットを作成、管理、および削除します。

## スニペットの表示レベル {#snippet-visibility-level}

GitLabの[スニペット](project_snippets.md)は、非公開、内部、または公開にすることができます。スニペットの`visibility`フィールドで設定できます。

スニペットの表示レベルの定数は次のとおりです:

- **プライベート**: スニペットはプロジェクトメンバーのみに表示されます。
- **内部**: スニペットは、[外部ユーザー](../administration/external_users.md)を除くすべての認証済みユーザーに表示されます。
- **公開**: スニペットには、認証なしでアクセスできます。

{{< alert type="note" >}}

2019年7月以降、`Internal`の表示レベル設定は、GitLab.comの新しいプロジェクト、グループ、およびスニペットに対しては無効になっています。`Internal`表示レベル設定を使用している既存のプロジェクト、グループ、スニペットは、この設定を維持します。変更の詳細については、[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/12388)を参照してください。

{{< /alert >}}

## スニペットの一覧表示 {#list-snippets}

プロジェクトスニペットのリストを取得します。

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
| `author.created_at` | 文字列  | 作成者アカウントが作成された日時。 |
| `author.email`      | 文字列  | スニペットの作成者のメールアドレス。 |
| `author.id`         | 整数 | スニペットの作成者のID。 |
| `author.name`       | 文字列  | スニペットの作成者の表示名。 |
| `author.state`      | 文字列  | 作成者アカウントの状態。 |
| `author.username`   | 文字列  | スニペットの作成者のユーザー名。 |
| `created_at`        | 文字列  | スニペットがISO 8601形式で作成された日時。 |
| `description`       | 文字列  | スニペットの説明。 |
| `file_name`         | 文字列  | スニペットファイルのファイル名。 |
| `id`                | 整数 | スニペットのID。 |
| `imported`          | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from`     | 文字列  | スニペットがインポートされた場合のインポート元。 |
| `project_id`        | 整数 | スニペットを含むプロジェクトのID。 |
| `raw_url`           | 文字列  | rawスニペットコンテンツへの直接URL。 |
| `title`             | 文字列  | スニペットのタイトル。 |
| `updated_at`        | 文字列  | スニペットが最後に更新された日時（ISO 8601形式）。 |
| `web_url`           | 文字列  | GitLabのWebインターフェースでスニペットを表示するURL。 |

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

## 単一のスニペットを取得 {#get-single-snippet}

単一のプロジェクトスニペットを取得します。

```plaintext
GET /projects/:id/snippets/:snippet_id
```

サポートされている属性は以下のとおりです:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | プロジェクトのスニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `author.created_at` | 文字列  | 作成者アカウントが作成された日時。 |
| `author.email`      | 文字列  | スニペットの作成者のメールアドレス。 |
| `author.id`         | 整数 | スニペットの作成者のID。 |
| `author.name`       | 文字列  | スニペットの作成者の表示名。 |
| `author.state`      | 文字列  | 作成者アカウントの状態。 |
| `author.username`   | 文字列  | スニペットの作成者のユーザー名。 |
| `created_at`        | 文字列  | スニペットがISO 8601形式で作成された日時。 |
| `description`       | 文字列  | スニペットの説明。 |
| `file_name`         | 文字列  | スニペットファイルのファイル名。 |
| `id`                | 整数 | スニペットのID。 |
| `imported`          | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from`     | 文字列  | スニペットがインポートされた場合のインポート元。 |
| `project_id`        | 整数 | スニペットを含むプロジェクトのID。 |
| `raw_url`           | 文字列  | rawスニペットコンテンツへの直接URL。 |
| `title`             | 文字列  | スニペットのタイトル。 |
| `updated_at`        | 文字列  | スニペットが最後に更新された日時（ISO 8601形式）。 |
| `web_url`           | 文字列  | GitLabのWebインターフェースでスニペットを表示するURL。 |

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

## 新しいスニペットを作成 {#create-new-snippet}

新しいプロジェクトスニペットを作成します。ユーザーには、新しいスニペットを作成する権限が必要です。

```plaintext
POST /projects/:id/snippets
```

サポートされている属性は以下のとおりです:

| 属性         | 型              | 必須 | 説明 |
|-------------------|-------------------|----------|-------------|
| `files`           | ハッシュの配列   | はい      | スニペットファイルの配列。 |
| `files:content`   | 文字列            | はい      | スニペットファイルの内容。 |
| `files:file_path` | 文字列            | はい      | スニペットファイルのファイルパス。 |
| `id`              | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `title`           | 文字列            | はい      | スニペットのタイトル。 |
| `content`         | 文字列            | いいえ       | 非推奨: 代わりに`files`を使用してください。スニペットのコンテンツ。 |
| `description`     | 文字列            | いいえ       | スニペットの説明。 |
| `file_name`       | 文字列            | いいえ       | 非推奨: 代わりに`files`を使用してください。スニペットファイルの名前。 |
| `visibility`      | 文字列            | いいえ       | スニペットの[表示レベル](#snippet-visibility-level)。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `author.created_at` | 文字列  | 作成者アカウントが作成された日時。 |
| `author.email`      | 文字列  | スニペットの作成者のメールアドレス。 |
| `author.id`         | 整数 | スニペットの作成者のID。 |
| `author.name`       | 文字列  | スニペットの作成者の表示名。 |
| `author.state`      | 文字列  | 作成者アカウントの状態。 |
| `author.username`   | 文字列  | スニペットの作成者のユーザー名。 |
| `created_at`        | 文字列  | スニペットがISO 8601形式で作成された日時。 |
| `description`       | 文字列  | スニペットの説明。 |
| `file_name`         | 文字列  | スニペットファイルのファイル名。 |
| `id`                | 整数 | スニペットのID。 |
| `imported`          | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from`     | 文字列  | スニペットがインポートされた場合のインポート元。 |
| `project_id`        | 整数 | スニペットを含むプロジェクトのID。 |
| `raw_url`           | 文字列  | rawスニペットコンテンツへの直接URL。 |
| `title`             | 文字列  | スニペットのタイトル。 |
| `updated_at`        | 文字列  | スニペットが最後に更新された日時（ISO 8601形式）。 |
| `web_url`           | 文字列  | GitLabのWebインターフェースでスニペットを表示するURL。 |

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

## スニペットの更新 {#update-snippet}

既存のプロジェクトスニペットを更新します。ユーザーには、既存のスニペットを変更する権限が必要です。

複数のファイルを含むスニペットへの更新では、`files`属性を使用する必要があります。

```plaintext
PUT /projects/:id/snippets/:snippet_id
```

サポートされている属性は以下のとおりです:

| 属性             | 型              | 必須      | 説明 |
|-----------------------|-------------------|---------------|-------------|
| `id`                  | 整数または文字列 | はい           | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id`          | 整数           | はい           | プロジェクトのスニペットのID。 |
| `files:action`        | 文字列            | 条件付き | ファイルに対して実行するアクションの種類。次のいずれか: `create`、`update`、`delete`、`move`。`files`属性を使用する場合は必須。 |
| `content`             | 文字列            | いいえ            | 非推奨: 代わりに`files`を使用してください。スニペットのコンテンツ。 |
| `description`         | 文字列            | いいえ            | スニペットの説明。 |
| `file_name`           | 文字列            | いいえ            | 非推奨: 代わりに`files`を使用してください。スニペットファイルの名前。 |
| `files`               | ハッシュの配列   | いいえ            | スニペットファイルの配列。 |
| `files:content`       | 文字列            | いいえ            | スニペットファイルの内容。 |
| `files:file_path`     | 文字列            | いいえ            | スニペットファイルのファイルパス。 |
| `files:previous_path` | 文字列            | いいえ            | スニペットファイルの以前のパス。 |
| `title`               | 文字列            | いいえ            | スニペットのタイトル。 |
| `visibility`          | 文字列            | いいえ            | スニペットの[表示レベル](#snippet-visibility-level)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `author.created_at` | 文字列  | 作成者アカウントが作成された日時。 |
| `author.email`      | 文字列  | スニペットの作成者のメールアドレス。 |
| `author.id`         | 整数 | スニペットの作成者のID。 |
| `author.name`       | 文字列  | スニペットの作成者の表示名。 |
| `author.state`      | 文字列  | 作成者アカウントの状態。 |
| `author.username`   | 文字列  | スニペットの作成者のユーザー名。 |
| `created_at`        | 文字列  | スニペットがISO 8601形式で作成された日時。 |
| `description`       | 文字列  | スニペットの説明。 |
| `file_name`         | 文字列  | スニペットファイルのファイル名。 |
| `id`                | 整数 | スニペットのID。 |
| `imported`          | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from`     | 文字列  | スニペットがインポートされた場合のインポート元。 |
| `project_id`        | 整数 | スニペットを含むプロジェクトのID。 |
| `raw_url`           | 文字列  | rawスニペットコンテンツへの直接URL。 |
| `title`             | 文字列  | スニペットのタイトル。 |
| `updated_at`        | 文字列  | スニペットが最後に更新された日時（ISO 8601形式）。 |
| `web_url`           | 文字列  | GitLabのWebインターフェースでスニペットを表示するURL。 |

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

## スニペットの削除 {#delete-snippet}

既存のプロジェクトスニペットを削除します。操作が成功した場合は`204 No Content`ステータスコード、リソースが見つからなかった場合は`404`を返します。

```plaintext
DELETE /projects/:id/snippets/:snippet_id
```

サポートされている属性は以下のとおりです:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | プロジェクトのスニペットのID。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2"
```

## スニペットコンテンツ {#snippet-content}

rawプロジェクトスニペットをプレーンテキストとして返します。

```plaintext
GET /projects/:id/snippets/:snippet_id/raw
```

サポートされている属性は以下のとおりです:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `snippet_id` | 整数           | はい      | プロジェクトのスニペットのID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/raw"
```

## スニペットリポジトリファイルコンテンツ {#snippet-repository-file-content}

rawファイルコンテンツをプレーンテキストとして返します。

```plaintext
GET /projects/:id/snippets/:snippet_id/files/:ref/:file_path/raw
```

サポートされている属性は以下のとおりです:

| 属性    | 型              | 必須 | 説明 |
|--------------|-------------------|----------|-------------|
| `id`         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `file_path`  | 文字列            | はい      | たとえば、`snippet%2Erb`のようなファイルへのURLエンコードされたパス。 |
| `ref`        | 文字列            | はい      | たとえば、`main`のような、ブランチ、タグ、またはコミットの名前。 |
| `snippet_id` | 整数           | はい      | プロジェクトのスニペットのID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/snippets/2/files/master/snippet%2Erb/raw"
```

## ユーザーエージェントの詳細を取得する {#get-user-agent-details}

管理者権限を持つユーザーのみが使用できます。

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
| `user_agent`        | 文字列  | スニペットの作成に使用されたブラウザーのユーザーエージェント文字列。 |

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
