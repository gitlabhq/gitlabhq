---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのGitブランチ用REST APIのドキュメント。
title: ブランチAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ブランチAPIを使用すると、プロジェクトのGitブランチをプログラムで管理できます。

プロジェクト用に設定されたブランチ保護を変更するには、[保護ブランチAPI](protected_branches.md)を使用します。

## リポジトリブランチをリストする {#list-repository-branches}

プロジェクトから、名前でアルファベット順にソートされたリポジトリブランチのリストを取得します。名前で検索するか、正規表現を使用して特定のブランチパターンを検索します。保護ステータス、マージステータス、コミットの詳細など、ブランチに関する詳細な情報を返します。

{{< alert type="note" >}}

リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

{{< /alert >}}

```plaintext
GET /projects/:id/repository/branches
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `regex`   | 文字列            | いいえ       | [re2](https://github.com/google/re2/wiki/Syntax)正規表現に一致する名前のブランチのリストを返します。`search`と一緒に使用することはできません。 |
| `search`  | 文字列            | いいえ       | 検索文字列を含むブランチのリストを返します。`term`で始まるブランチを検索するには`^term`を使用し、`term`で終わるブランチを検索するには`term$`を使用します。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                  | 型                | 説明 |
|----------------------------|---------------------|-------------|
| `can_push`                 | ブール値             | `true`の場合、認証済みユーザーは、このブランチにプッシュできます。 |
| `commit`                   | オブジェクト              | ブランチ上の最新のコミットに関する詳細。 |
| `commit.author_email`      | 文字列              | 変更を作成者したユーザーのメールアドレス。 |
| `commit.author_name`       | 文字列              | 変更を作成者したユーザーの名前。 |
| `commit.authored_date`     | 日時（ISO 8601） | コミットが作成された日時。 |
| `commit.committed_date`    | 日時（ISO 8601） | コミットがコミットされた日時。 |
| `commit.committer_email`   | 文字列              | 変更をコミットしたユーザーのメールアドレス。 |
| `commit.committer_name`    | 文字列              | 変更をコミットしたユーザーの名前。 |
| `commit.created_at`        | 日時（ISO 8601） | コミットが作成された日時。 |
| `commit.extended_trailers` | オブジェクト              | コミットメッセージから解析された拡張Gitトレーラー。 |
| `commit.id`                | 文字列              | コミットの完全なSHA。 |
| `commit.message`           | 文字列              | 完全なコミットメッセージ。 |
| `commit.parent_ids`        | 配列               | 親コミットSHAの配列。 |
| `commit.short_id`          | 文字列              | コミットの省略されたSHA。 |
| `commit.title`             | 文字列              | コミットメッセージのタイトル。 |
| `commit.trailers`          | オブジェクト              | コミットメッセージから解析されたGitトレーラー。 |
| `commit.web_url`           | 文字列              | GitLab UIでコミットを表示するためのURL。 |
| `default`                  | ブール値             | `true`の場合、ブランチはプロジェクトのデフォルトブランチです。 |
| `developers_can_merge`     | ブール値             | `true`の場合、少なくともデベロッパーロールを持つユーザーは、このブランチにマージできます。 |
| `developers_can_push`      | ブール値             | `true`の場合、少なくともデベロッパーロールを持つユーザーは、このブランチにプッシュできます。 |
| `merged`                   | ブール値             | `true`の場合、ブランチはデフォルトブランチにマージされています。 |
| `name`                     | 文字列              | ブランチの名前。 |
| `protected`                | ブール値             | `true`の場合、ブランチは強制プッシュと削除から保護されています。 |
| `web_url`                  | 文字列              | GitLab UIでブランチを表示するためのURL。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches"
```

レスポンス例:

```json
[
  {
    "name": "main",
    "merged": false,
    "protected": true,
    "default": true,
    "developers_can_push": false,
    "developers_can_merge": false,
    "can_push": true,
    "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
    "commit": {
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "short_id": "7b5c3cc",
      "created_at": "2024-06-28T03:44:20-07:00",
      "parent_ids": [
        "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      ],
      "title": "add projects API",
      "message": "add projects API",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2024-06-27T05:51:39-07:00",
      "committer_name": "John Smith",
      "committer_email": "john@example.com",
      "committed_date": "2024-06-28T03:44:20-07:00",
      "trailers": {},
      "extended_trailers": {},
      "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
    }
  },
  ...
]
```

## 1つのリポジトリブランチを取得する {#get-single-repository-branch}

1つのプロジェクトリポジトリブランチを取得します。

{{< alert type="note" >}}

リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

{{< /alert >}}

```plaintext
GET /projects/:id/repository/branches/:branch
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `branch`  | 文字列            | はい      | ブランチの[URLエンコードされた名前](rest/_index.md#namespaced-paths)。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                | 型    | 説明 |
|--------------------------|---------|-------------|
| `can_push`               | ブール値 | 認証済みユーザーがこのブランチにプッシュできるかどうか。 |
| `commit`                 | オブジェクト  | ブランチ上の最新コミットの詳細。 |
| `commit.author_email`    | 文字列  | コミットの作成者のメールアドレス。 |
| `commit.author_name`     | 文字列  | コミットの作成者名。 |
| `commit.authored_date`   | 文字列  | コミットがISO 8601形式で作成された日時。 |
| `commit.committer_email` | 文字列  | 変更をコミットしたユーザーのメールアドレス。 |
| `commit.committer_name`  | 文字列  | 変更をコミットしたユーザーの名前。 |
| `commit.committed_date`  | 文字列  | コミットがISO 8601形式でコミットされた日時。 |
| `commit.created_at`      | 文字列  | コミットがISO 8601形式で作成された日時。 |
| `commit.extended_trailers` | オブジェクト  | コミットメッセージから解析された拡張Gitトレーラー。 |
| `commit.id`              | 文字列  | コミットの完全なSHA。 |
| `commit.message`         | 文字列  | 完全なコミットメッセージ。 |
| `commit.parent_ids`      | 配列   | 親コミットSHAの配列。 |
| `commit.short_id`        | 文字列  | コミットの省略されたSHA。 |
| `commit.title`           | 文字列  | コミットメッセージのタイトル。 |
| `commit.trailers`        | オブジェクト  | コミットメッセージから解析されたGitトレーラー。 |
| `commit.web_url`         | 文字列  | GitLab UIでコミットを表示するためのURL。 |
| `default`                | ブール値 | これがプロジェクトのデフォルトブランチであるかどうか。 |
| `developers_can_merge`   | ブール値 | デベロッパーロールを持つユーザーがこのブランチにマージできるかどうか。 |
| `developers_can_push`    | ブール値 | デベロッパーロールを持つユーザーがこのブランチにプッシュできるかどうか。 |
| `merged`                 | ブール値 | ブランチがデフォルトブランチにマージされたかどうか。 |
| `name`                   | 文字列  | ブランチの名前。 |
| `protected`              | ブール値 | ブランチが強制プッシュと削除から保護されているかどうか。 |
| `web_url`                | 文字列  | GitLab UIでブランチを表示するためのURL。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/main"
```

レスポンス例:

```json
{
  "name": "main",
  "merged": false,
  "protected": true,
  "default": true,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  }
}
```

## リポジトリブランチを保護する {#protect-repository-branch}

リポジトリブランチの保護については、[`POST /projects/:id/protected_branches`](protected_branches.md#protect-repository-branches)を参照してください。

## リポジトリブランチの保護を解除する {#unprotect-repository-branch}

リポジトリブランチの保護の解除については、[`DELETE /projects/:id/protected_branches/:name`](protected_branches.md#unprotect-repository-branches)を参照してください。

## リポジトリブランチを作成する {#create-repository-branch}

リポジトリに新しいブランチを作成します。

```plaintext
POST /projects/:id/repository/branches
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `branch`  | 文字列            | はい      | ブランチの名前。スペースまたは特殊文字（ハイフンとアンダースコアを除く）を含めることはできません。 |
| `ref`     | 文字列            | はい      | ブランチの作成元となるブランチ名またはコミット 。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                  | 型    | 説明 |
|----------------------------|---------|-------------|
| `can_push`                 | ブール値 | `true`の場合、認証済みユーザーは、このブランチにプッシュできます。 |
| `commit`                   | オブジェクト  | ブランチ上の最新コミットの詳細。 |
| `commit.author_email`      | 文字列  | コミットの作成者のメールアドレス。 |
| `commit.author_name`       | 文字列  | コミットの作成者名。 |
| `commit.authored_date`     | 文字列  | コミットが8601形式で作成された日時。 |
| `commit.committed_date`    | 文字列  | コミットが8601形式でコミットされた日時。 |
| `commit.committer_email`   | 文字列  | 変更をコミットしたユーザーのメールアドレス。 |
| `commit.committer_name`    | 文字列  | 変更をコミットしたユーザーの名前。 |
| `commit.created_at`        | 文字列  | コミットが8601形式で作成された日時。 |
| `commit.extended_trailers` | オブジェクト  | コミットメッセージから解析された拡張Gitトレーラー。 |
| `commit.id`                | 文字列  | コミットの完全なSHA。 |
| `commit.message`           | 文字列  | 完全なコミットメッセージ。 |
| `commit.parent_ids`        | 配列   | 親コミットSHAの配列。 |
| `commit.short_id`          | 文字列  | コミットの省略されたSHA。 |
| `commit.title`             | 文字列  | コミットメッセージのタイトル。 |
| `commit.trailers`          | オブジェクト  | コミットメッセージから解析されたGitトレーラー。 |
| `commit.web_url`           | 文字列  | GitLab UIでコミットを表示するためのURL。 |
| `default`                  | ブール値 | `true`の場合、このブランチをプロジェクトのデフォルトブランチとして設定します。 |
| `developers_can_merge`     | ブール値 | `true`の場合、デベロッパーロールを持つユーザーは、このブランチにマージできます。 |
| `developers_can_push`      | ブール値 | `true`の場合、デベロッパーロールを持つユーザーは、このブランチにプッシュできます。 |
| `merged`                   | ブール値 | `true`の場合、ブランチはデフォルトブランチにマージされました。 |
| `name`                     | 文字列  | ブランチの名前。 |
| `protected`                | ブール値 | `true`の場合、ブランチは強制プッシュと削除から保護されています。 |
| `web_url`                  | 文字列  | GitLab UIでブランチを表示するためのURL。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches?branch=newbranch&ref=main"
```

レスポンス例:

```json
{
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  },
  "name": "newbranch",
  "merged": false,
  "protected": false,
  "default": false,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/newbranch"
}
```

## リポジトリブランチを削除する {#delete-repository-branch}

リポジトリからブランチを削除します。

{{< alert type="note" >}}

エラーが発生した場合、説明メッセージが表示されます。

{{< /alert >}}

```plaintext
DELETE /projects/:id/repository/branches/:branch
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `branch`  | 文字列            | はい      | ブランチの[URLエンコードされた名前](rest/_index.md#namespaced-paths)。デフォルトブランチまたは保護ブランチを削除することはできません。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/newbranch"
```

{{< alert type="note" >}}

ブランチを削除しても、関連するすべてのデータが完全に消去されるわけではありません。プロジェクトの履歴を維持し、リカバリープロセスをサポートするために、一部の情報が保持されます。詳細については、[機密情報を処理する](../topics/git/undo.md#handle-sensitive-information)を参照してください。

{{< /alert >}}

## マージ済みブランチを削除する {#delete-merged-branches}

プロジェクトのデフォルトブランチにマージされたブランチをすべてを削除します。

{{< alert type="note" >}}

この操作では、[保護ブランチ](../user/project/repository/branches/protected.md)は削除されません。

{{< /alert >}}

```plaintext
DELETE /projects/:id/repository/merged_branches
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功すると、[`202 Accepted`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merged_branches"
```

## 関連トピック {#related-topics}

- [ブランチ](../user/project/repository/branches/_index.md)
- [保護ブランチ](../user/project/repository/branches/protected.md)
- [保護ブランチAPI](protected_branches.md)
