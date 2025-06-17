---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for Git branches in GitLab.
title: ブランチAPI
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIは、[リポジトリブランチ](../user/project/repository/branches/_index.md)に対して動作します。

[保護ブランチAPI](protected_branches.md)も参照してください。

## リポジトリブランチをリストする

プロジェクトから、名前でアルファベット順にソートされたリポジトリブランチのリストを取得します。

{{< alert type="note" >}}

リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

{{< /alert >}}

```plaintext
GET /projects/:id/repository/branches
```

パラメーター:

| 属性 | 型           | 必須 | 説明 |
|:----------|:---------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。|
| `search`  | 文字列         | いいえ       | 検索文字列を含むブランチのリストを返します。`term`で始まるブランチを検索するには`^term`を使用し、`term`で終わるブランチを検索するには`term$`を使用します。 |
| `regex`   | 文字列         | いいえ       | [re2](https://github.com/google/re2/wiki/Syntax)正規表現に一致する名前のブランチのリストを返します。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches"
```

応答の例:

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

## 1つのリポジトリブランチを取得する

1つのプロジェクトリポジトリブランチを取得します。

{{< alert type="note" >}}

リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

{{< /alert >}}

```plaintext
GET /projects/:id/repository/branches/:branch
```

パラメーター:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `branch`  | 文字列            | はい      | ブランチの[URLエンコードされた名前](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/main"
```

応答の例:

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
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  }
}
```

## リポジトリブランチを保護する

リポジトリブランチの保護については、[`POST /projects/:id/protected_branches`](protected_branches.md#protect-repository-branches)を参照してください。

## リポジトリブランチの保護を解除する

リポジトリブランチの保護解除については、[`DELETE /projects/:id/protected_branches/:name`](protected_branches.md#unprotect-repository-branches)を参照してください。

## リポジトリブランチを作成する

リポジトリに新しいブランチを作成します。

```plaintext
POST /projects/:id/repository/branches
```

パラメーター:

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `id`      | 整数 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `branch`  | 文字列  | はい      | ブランチの名前。 |
| `ref`     | 文字列  | はい      | ブランチの作成元となるブランチ名またはコミットSHA。 |

リクエストの例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches?branch=newbranch&ref=main"
```

応答の例:

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

## リポジトリブランチを削除する

リポジトリからブランチを削除します。

{{< alert type="note" >}}

エラーが発生した場合、説明メッセージが表示されます。

{{< /alert >}}

```plaintext
DELETE /projects/:id/repository/branches/:branch
```

パラメーター:

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `branch`  | 文字列         | はい      | ブランチの名前。 |

リクエストの例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/newbranch"
```

{{< alert type="note" >}}

ブランチを削除しても、関連するすべてのデータが完全に消去されるわけではありません。プロジェクトの履歴を維持し、リカバリープロセスをサポートするために、一部の情報が保持されます。詳細については、[機密情報を処理する](../topics/git/undo.md#handle-sensitive-information)を参照してください。

{{< /alert >}}

## マージ済みブランチを削除する

プロジェクトのデフォルトブランチにマージされたブランチをすべてを削除します。

{{< alert type="note" >}}

この操作では、[保護ブランチ](../user/project/repository/branches/protected.md)は削除されません。

{{< /alert >}}

```plaintext
DELETE /projects/:id/repository/merged_branches
```

パラメーター:

| 属性 | 型           | 必須 | 説明                                                                                                  |
|:----------|:---------------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merged_branches"
```

## 関連トピック

- [ブランチ](../user/project/repository/branches/_index.md)
- [保護ブランチ](../user/project/repository/branches/protected.md)
- [保護ブランチAPI](protected_branches.md)
