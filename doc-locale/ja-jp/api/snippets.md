---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スニペットAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

スニペットAPIは、[スニペット](../user/snippets.md)を操作します。関連APIは、[プロジェクトスニペット](project_snippets.md)と[ストレージ間でのスニペットの移動](snippet_repository_storage_moves.md)のために存在します。

## スニペットの表示レベル {#snippet-visibility-level}

GitLabのスニペットは、private、internal、publicのいずれかにすることができます。スニペットの`visibility`フィールドで設定できます。

スニペットの表示レベルの有効な値は次のとおりです:

| 表示レベル: | 説明                                         |
|-----------|---------------------------------------------------|
| `private`  | スニペットはスニペットの作成者のみに表示されます。     |
| `internal` | スニペットは、[外部ユーザー](../administration/external_users.md)を除く認証済みユーザーであれば誰でも表示できます。          |
| `public`   | スニペットには認証なしでアクセスできます。 |

## 現在のユーザーのスニペットをすべてリスト表示 {#list-all-snippets-for-current-user}

現在のユーザーのスニペットのリストを取得します。

```plaintext
GET /snippets
```

サポートされている属性は以下のとおりです:

| 属性        | 型     | 必須 | 説明 |
|------------------|----------|----------|-------------|
| `created_after`  | 日時 | いいえ       | 指定された時間以降に作成されたスニペットを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before` | 日時 | いいえ       | 指定された時間より前に作成されたスニペットを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `page`           | 整数  | いいえ       | 取得するページ。 |
| `per_page`       | 整数  | いいえ       | ページごとに返すスニペットの数。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性       | 型    | 説明 |
|-----------------|---------|-------------|
| `author`        | オブジェクト  | スニペットの作成者を表すユーザーオブジェクト。 |
| `created_at`    | 文字列  | スニペットが作成された日時。 |
| `description`   | 文字列  | スニペットの説明。 |
| `file_name`     | 文字列  | スニペットファイルの名前。 |
| `id`            | 整数 | スニペットのID。 |
| `imported`      | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from` | 文字列  | インポート元。 |
| `project_id`    | 整数 | 関連付けられたプロジェクトのID。パーソナルスニペットの場合、`null`。 |
| `raw_url`       | 文字列  | rawスニペットコンテンツへのURL。 |
| `title`         | 文字列  | スニペットのタイトル。 |
| `updated_at`    | 文字列  | スニペットが最後に更新された日時。 |
| `visibility`    | 文字列  | スニペットの表示レベル。 |
| `web_url`       | 文字列  | GitLab UIのスニペットへのURL。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets"
```

レスポンス例:

```json
[
    {
        "id": 42,
        "title": "Voluptatem iure ut qui aut et consequatur quaerat.",
        "file_name": "mclaughlin.rb",
        "description": null,
        "visibility": "internal",
        "imported": false,
        "imported_from": "none",
        "author": {
            "id": 22,
            "name": "User 0",
            "username": "user0",
            "state": "active",
            "avatar_url": "https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80&d=identicon",
            "web_url": "http://example.com/user0"
        },
        "updated_at": "2018-09-18T01:12:26.383Z",
        "created_at": "2018-09-18T01:12:26.383Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/42",
        "raw_url": "http://example.com/snippets/42/raw"
    },
    {
        "id": 41,
        "title": "Ut praesentium non et atque.",
        "file_name": "ondrickaemard.rb",
        "description": null,
        "visibility": "internal",
        "imported": false,
        "imported_from": "none",
        "author": {
            "id": 22,
            "name": "User 0",
            "username": "user0",
            "state": "active",
            "avatar_url": "https://www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80&d=identicon",
            "web_url": "http://example.com/user0"
        },
        "updated_at": "2018-09-18T01:12:26.360Z",
        "created_at": "2018-09-18T01:12:26.360Z",
        "project_id": 1,
        "web_url": "http://example.com/gitlab-org/gitlab-test/snippets/41",
        "raw_url": "http://example.com/gitlab-org/gitlab-test/snippets/41/raw"
    }
]
```

## 単一のスニペットを取得 {#get-a-single-snippet}

単一のスニペットを取得します。

```plaintext
GET /snippets/:id
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明                |
|-----------|---------|----------|----------------------------|
| `id`      | 整数 | はい      | 取得するスニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性          | 型    | 説明 |
|--------------------|---------|-------------|
| `author`           | オブジェクト  | スニペットの作成者を表すユーザーオブジェクト。 |
| `created_at`       | 文字列  | スニペットが作成された日時。 |
| `description`      | 文字列  | スニペットの説明。 |
| `expires_at`       | 文字列  | スニペットの有効期限が切れる日時。 |
| `file_name`        | 文字列  | スニペットファイルの名前。 |
| `http_url_to_repo` | 文字列  | スニペットリポジトリのHTTP URL。 |
| `id`               | 整数 | スニペットのID。 |
| `imported`         | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from`    | 文字列  | インポート元。 |
| `project_id`       | 整数 | 関連付けられたプロジェクトのID。パーソナルスニペットの場合、`null`。 |
| `raw_url`          | 文字列  | rawスニペットコンテンツへのURL。 |
| `ssh_url_to_repo`  | 文字列  | スニペットリポジトリのSSH URL。 |
| `title`            | 文字列  | スニペットのタイトル。 |
| `updated_at`       | 文字列  | スニペットが最後に更新された日時。 |
| `visibility`       | 文字列  | スニペットの表示レベル。 |
| `web_url`          | 文字列  | GitLab UIのスニペットへのURL。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1"
```

レスポンス例:

```json
{
  "id": 1,
  "title": "test",
  "file_name": "add.rb",
  "description": "Ruby test snippet",
  "visibility": "private",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw"
}
```

## 単一スニペットコンテンツ {#single-snippet-contents}

単一スニペットのrawコンテンツを取得します。

```plaintext
GET /snippets/:id/raw
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明                |
|-----------|---------|----------|----------------------------|
| `id`      | 整数 | はい      | 取得するスニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)とスニペットのrawコンテンツを返します。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/raw"
```

レスポンス例:

```plaintext
Hello World snippet
```

## スニペットリポジトリファイルコンテンツ {#snippet-repository-file-content}

rawファイルコンテンツをプレーンテキストとして返します。

```plaintext
GET /snippets/:id/files/:ref/:file_path/raw
```

サポートされている属性は以下のとおりです:

| 属性   | 型    | 必須 | 説明 |
|-------------|---------|----------|-------------|
| `file_path` | 文字列  | はい      | ファイルへのURLエンコードされたパス。 |
| `id`        | 整数 | はい      | 取得するスニペットのID。 |
| `ref`       | 文字列  | はい      | タグ、ブランチ、またはコミットへの参照。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)とrawファイルコンテンツを返します。

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/files/main/snippet%2Erb/raw"
```

レスポンス例:

```plaintext
Hello World snippet
```

## 新しいスニペットを作成する {#create-new-snippet}

新しいスニペットを作成します。

{{< alert type="note" >}}

ユーザーは、新しいスニペットを作成する権限を持っている必要があります。

{{< /alert >}}

```plaintext
POST /snippets
```

サポートされている属性は以下のとおりです:

| 属性         | 型            | 必須 | 説明 |
|-------------------|-----------------|----------|-------------|
| `files:content`   | 文字列          | はい      | スニペットファイルのコンテンツ。 |
| `files:file_path` | 文字列          | はい      | スニペットファイルのファイルパス。 |
| `title`           | 文字列          | はい      | スニペットのタイトル。 |
| `content`         | 文字列          | いいえ       | 非推奨: 代わりに`files`を使用してください。スニペットのコンテンツ。 |
| `description`     | 文字列          | いいえ       | スニペットの説明。 |
| `file_name`       | 文字列          | いいえ       | 非推奨: 代わりに`files`を使用してください。スニペットファイルの名前。 |
| `files`           | ハッシュの配列 | いいえ       | スニペットファイルの配列。 |
| `visibility`      | 文字列          | いいえ       | スニペットの[表示レベル](#snippet-visibility-level)。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性          | 型    | 説明 |
|--------------------|---------|-------------|
| `author`           | オブジェクト  | スニペットの作成者を表すユーザーオブジェクト。 |
| `created_at`       | 文字列  | スニペットが作成された日時。 |
| `description`      | 文字列  | スニペットの説明。 |
| `expires_at`       | 文字列  | スニペットの有効期限が切れる日時。 |
| `file_name`        | 文字列  | スニペットファイルの名前。 |
| `files`            | 配列   | スニペットファイルの配列。 |
| `http_url_to_repo` | 文字列  | スニペットリポジトリのHTTP URL。 |
| `id`               | 整数 | スニペットのID。 |
| `imported`         | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from`    | 文字列  | インポート元。 |
| `project_id`       | 整数 | 関連付けられたプロジェクトのID。パーソナルスニペットの場合、`null`。 |
| `raw_url`          | 文字列  | rawスニペットコンテンツへのURL。 |
| `ssh_url_to_repo`  | 文字列  | スニペットリポジトリのSSH URL。 |
| `title`            | 文字列  | スニペットのタイトル。 |
| `updated_at`       | 文字列  | スニペットが最後に更新された日時。 |
| `visibility`       | 文字列  | スニペットの表示レベル。 |
| `web_url`          | 文字列  | GitLab UIのスニペットへのURL。 |

リクエスト例:

```shell
curl --request POST "https://gitlab.example.com/api/v4/snippets" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

前のサンプルリクエストで使用される`snippet.json`:

```json
{
  "title": "This is a snippet",
  "description": "Hello World snippet",
  "visibility": "internal",
  "files": [
    {
      "content": "Hello world",
      "file_path": "test.txt"
    }
  ]
}
```

レスポンス例:

```json
{
  "id": 1,
  "title": "This is a snippet",
  "description": "Hello World snippet",
  "visibility": "internal",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw",
  "ssh_url_to_repo": "ssh://git@gitlab.example.com:snippets/1.git",
  "http_url_to_repo": "https://gitlab.example.com/snippets/1.git",
  "file_name": "test.txt",
  "files": [
    {
      "path": "text.txt",
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/main/renamed.md"
    }
  ]
}
```

## スニペットの更新 {#update-snippet}

既存のスニペットを更新します。

{{< alert type="note" >}}

ユーザーは、既存のスニペットを変更する権限を持っている必要があります。

{{< /alert >}}

```plaintext
PUT /snippets/:id
```

サポートされている属性は以下のとおりです:

| 属性             | 型            | 必須      | 説明 |
|-----------------------|-----------------|---------------|-------------|
| `id`                  | 整数         | はい           | 更新するスニペットのID。 |
| `files:action`        | 文字列          | はい           | ファイルに対して実行するアクションの種類。次のいずれか: `create`、`update`、`delete`、`move`。 |
| `content`             | 文字列          | いいえ            | 非推奨: 代わりに`files`を使用してください。スニペットのコンテンツ。 |
| `description`         | 文字列          | いいえ            | スニペットの説明。 |
| `file_name`           | 文字列          | いいえ            | 非推奨: 代わりに`files`を使用してください。スニペットファイルの名前。 |
| `files`               | ハッシュの配列 | 条件付き | スニペットファイルの配列。複数のファイルを含むスニペットを更新する場合は必須。 |
| `files:content`       | 文字列          | いいえ            | スニペットファイルのコンテンツ。 |
| `files:file_path`     | 文字列          | いいえ            | スニペットファイルのファイルパス。 |
| `files:previous_path` | 文字列          | いいえ            | スニペットファイルの以前のパス。 |
| `title`               | 文字列          | いいえ            | スニペットのタイトル。 |
| `visibility`          | 文字列          | いいえ            | スニペットの[表示レベル](#snippet-visibility-level)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性          | 型    | 説明 |
|--------------------|---------|-------------|
| `author`           | オブジェクト  | スニペットの作成者を表すユーザーオブジェクト。 |
| `created_at`       | 文字列  | スニペットが作成された日時。 |
| `description`      | 文字列  | スニペットの説明。 |
| `expires_at`       | 文字列  | スニペットの有効期限が切れる日時。 |
| `file_name`        | 文字列  | スニペットファイルの名前。 |
| `files`            | 配列   | スニペットファイルの配列。 |
| `http_url_to_repo` | 文字列  | スニペットリポジトリのHTTP URL。 |
| `id`               | 整数 | スニペットのID。 |
| `imported`         | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from`    | 文字列  | インポート元。 |
| `project_id`       | 整数 | 関連付けられたプロジェクトのID。パーソナルスニペットの場合、`null`。 |
| `raw_url`          | 文字列  | rawスニペットコンテンツへのURL。 |
| `ssh_url_to_repo`  | 文字列  | スニペットリポジトリのSSH URL。 |
| `title`            | 文字列  | スニペットのタイトル。 |
| `updated_at`       | 文字列  | スニペットが最後に更新された日時。 |
| `visibility`       | 文字列  | スニペットの表示レベル。 |
| `web_url`          | 文字列  | GitLab UIのスニペットへのURL。 |

リクエスト例:

```shell
curl --request PUT "https://gitlab.example.com/api/v4/snippets/1" \
     --header 'Content-Type: application/json' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     -d @snippet.json
```

前のサンプルリクエストで使用される`snippet.json`:

```json
{
  "title": "foo",
  "files": [
    {
      "action": "move",
      "previous_path": "test.txt",
      "file_path": "renamed.md"
    }
  ]
}
```

レスポンス例:

```json
{
  "id": 1,
  "title": "test",
  "description": "description of snippet",
  "visibility": "internal",
  "imported": false,
  "imported_from": "none",
  "author": {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "created_at": "2012-05-23T08:00:58Z"
  },
  "expires_at": null,
  "updated_at": "2012-06-28T10:52:04Z",
  "created_at": "2012-06-28T10:52:04Z",
  "project_id": null,
  "web_url": "http://example.com/snippets/1",
  "raw_url": "http://example.com/snippets/1/raw",
  "ssh_url_to_repo": "ssh://git@gitlab.example.com:snippets/1.git",
  "http_url_to_repo": "https://gitlab.example.com/snippets/1.git",
  "file_name": "renamed.md",
  "files": [
    {
      "path": "renamed.md",
      "raw_url": "https://gitlab.example.com/-/snippets/1/raw/main/renamed.md"
    }
  ]
}
```

## スニペットの削除 {#delete-snippet}

既存のスニペットを削除します。

```plaintext
DELETE /snippets/:id
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明              |
|-----------|---------|----------|--------------------------|
| `id`      | 整数 | はい      | 削除するスニペットのID。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1"
```

考えられる戻り値は次のとおりです:

| コード  | 説明 |
|-------|-------------|
| `204` | 削除に成功しました。データは返されません。 |
| `404` | スニペットが見つかりませんでした。 |

## すべての公開スニペットをリスト表示 {#list-all-public-snippets}

すべての公開スニペットをリスト表示します。

```plaintext
GET /snippets/public
```

サポートされている属性は以下のとおりです:

| 属性        | 型     | 必須 | 説明 |
|------------------|----------|----------|-------------|
| `created_after`  | 日時 | いいえ       | 指定された時間以降に作成されたスニペットを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before` | 日時 | いいえ       | 指定された時間より前に作成されたスニペットを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `page`           | 整数  | いいえ       | 取得するページ。 |
| `per_page`       | 整数  | いいえ       | ページごとに返すスニペットの数。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性     | 型    | 説明 |
|---------------|---------|-------------|
| `author`      | オブジェクト  | スニペットの作成者を表すユーザーオブジェクト。 |
| `created_at`  | 文字列  | スニペットが作成された日時。 |
| `description` | 文字列  | スニペットの説明。 |
| `file_name`   | 文字列  | スニペットファイルの名前。 |
| `id`          | 整数 | スニペットのID。 |
| `project_id`  | 整数 | 関連付けられたプロジェクトのID。パーソナルスニペットの場合、`null`。 |
| `raw_url`     | 文字列  | rawスニペットコンテンツへのURL。 |
| `title`       | 文字列  | スニペットのタイトル。 |
| `updated_at`  | 文字列  | スニペットが最後に更新された日時。 |
| `visibility`  | 文字列  | スニペットの表示レベル。 |
| `web_url`     | 文字列  | GitLab UIのスニペットへのURL。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/public?per_page=2&page=1"
```

レスポンス例:

```json
[
    {
        "author": {
            "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
            "id": 12,
            "name": "Libby Rolfson",
            "state": "active",
            "username": "elton_wehner",
            "web_url": "http://example.com/elton_wehner"
        },
        "created_at": "2016-11-25T16:53:34.504Z",
        "file_name": "oconnerrice.rb",
        "id": 49,
        "title": "Ratione cupiditate et laborum temporibus.",
        "updated_at": "2016-11-25T16:53:34.504Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/49",
        "raw_url": "http://example.com/snippets/49/raw"
    },
    {
        "author": {
            "avatar_url": "http://www.gravatar.com/avatar/36583b28626de71061e6e5a77972c3bd?s=80&d=identicon",
            "id": 16,
            "name": "Llewellyn Flatley",
            "state": "active",
            "username": "adaline",
            "web_url": "http://example.com/adaline"
        },
        "created_at": "2016-11-25T16:53:34.479Z",
        "file_name": "muellershields.rb",
        "id": 48,
        "title": "Minus similique nesciunt vel fugiat qui ullam sunt.",
        "updated_at": "2016-11-25T16:53:34.479Z",
        "project_id": null,
        "web_url": "http://example.com/snippets/48",
        "raw_url": "http://example.com/snippets/49/raw",
        "visibility": "public"
    }
]
```

## すべてのスニペットをリスト表示 {#list-all-snippets}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419640)されました。

{{< /history >}}

現在のユーザーがアクセスできるすべてのスニペットをリスト表示します。管理者または監査担当者のアクセスレベルを持つユーザーは、すべてのスニペット（個人用とプロジェクト用）を表示できます。

```plaintext
GET /snippets/all
```

サポートされている属性は以下のとおりです:

| 属性            | 型     | 必須 | 説明 |
|----------------------|----------|----------|-------------|
| `created_after`      | 日時 | いいえ       | 指定された時間以降に作成されたスニペットを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before`     | 日時 | いいえ       | 指定された時間より前に作成されたスニペットを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `page`               | 整数  | いいえ       | 取得するページ。 |
| `per_page`           | 整数  | いいえ       | ページごとに返すスニペットの数。 |
| `repository_storage` | 文字列   | いいえ       | スニペットが使用するリポジトリストレージでフィルタリングします_（管理者のみ）_。GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419640)されました。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性            | 型    | 説明 |
|----------------------|---------|-------------|
| `author`             | オブジェクト  | スニペットの作成者を表すユーザーオブジェクト。 |
| `created_at`         | 文字列  | スニペットが作成された日時。 |
| `description`        | 文字列  | スニペットの説明。 |
| `file_name`          | 文字列  | スニペットファイルの名前。 |
| `files`              | 配列   | スニペットファイルの配列。 |
| `id`                 | 整数 | スニペットのID。 |
| `imported`           | ブール値 | `true`の場合、スニペットはインポートされました。 |
| `imported_from`      | 文字列  | インポート元。 |
| `project_id`         | 整数 | 関連付けられたプロジェクトのID。パーソナルスニペットの場合、`null`。 |
| `raw_url`            | 文字列  | rawスニペットコンテンツへのURL。 |
| `repository_storage` | 文字列  | スニペットで使用されるリポジトリストレージ。 |
| `title`              | 文字列  | スニペットのタイトル。 |
| `updated_at`         | 文字列  | スニペットが最後に更新された日時。 |
| `visibility`         | 文字列  | スニペットの表示レベル。 |
| `web_url`            | 文字列  | GitLab UIのスニペットへのURL。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/all?per_page=2&page=1"
```

レスポンス例:

```json
[
  {
    "id": 113,
    "title": "Internal Project Snippet",
    "description": null,
    "visibility": "internal",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 17,
      "username": "tim_kreiger",
      "name": "Tim Kreiger",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/tim_kreiger"
    },
    "created_at": "2023-08-03T10:21:02.480Z",
    "updated_at": "2023-08-03T10:21:02.480Z",
    "project_id": 35,
    "web_url": "http://example.com/tim_kreiger/internal_project/-/snippets/113",
    "raw_url": "http://example.com/tim_kreiger/internal_project/-/snippets/113/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  },
  {
    "id": 112,
    "title": "Private Personal Snippet",
    "description": null,
    "visibility": "private",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/root"
    },
    "created_at": "2023-08-03T10:20:59.994Z",
    "updated_at": "2023-08-03T10:20:59.994Z",
    "project_id": null,
    "web_url": "http://example.com/-/snippets/112",
    "raw_url": "http://example.com/-/snippets/112/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  },
  {
    "id": 111,
    "title": "Public Personal Snippet",
    "description": null,
    "visibility": "public",
    "imported": false,
    "imported_from": "none",
    "author": {
      "id": 17,
      "username": "tim_kreiger",
      "name": "Tim Kreiger",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/edaf55a9e363ea263e3b981d09e0f7f7?s=80&d=identicon",
      "web_url": "http://example.com/tim_kreiger"
    },
    "created_at": "2023-08-03T10:21:01.312Z",
    "updated_at": "2023-08-03T10:21:01.312Z",
    "project_id": null,
    "web_url": "http://example.com/-/snippets/111",
    "raw_url": "http://example.com/-/snippets/111/raw",
    "file_name": "",
    "files": [],
    "repository_storage": "default"
  }
]
```

## ユーザーエージェントの詳細を取得する {#get-user-agent-details}

{{< alert type="note" >}}

管理者のみが利用できます。

{{< /alert >}}

```plaintext
GET /snippets/:id/user_agent_detail
```

サポートされている属性は以下のとおりです:

| 属性 | 型    | 必須 | 説明    |
|-----------|---------|----------|----------------|
| `id`      | 整数 | はい      | スニペットのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性           | 型    | 説明 |
|---------------------|---------|-------------|
| `akismet_submitted` | ブール値 | `true`の場合、詳細はAkismetに送信されました。 |
| `ip_address`        | 文字列  | スニペットの作成に使用されたIPアドレス。 |
| `user_agent`        | 文字列  | スニペットの作成に使用されたユーザーエージェント文字列。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/snippets/1/user_agent_detail"
```

レスポンス例:

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```
