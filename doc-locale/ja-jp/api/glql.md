---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GLQL API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209517)されました。

{{< /history >}}

このAPIを使用して、[GitLab Query Language（GLQL）](../user/glql/_index.md)のクエリをプログラムで実行します。GLQLは、プロジェクトやグループを横断して、イシュー、マージリクエスト、エピックなどの[GitLabリソース](../user/glql/_index.md#supported-areas)を検索およびフィルタリングするための、簡素化された言語を提供します。

前提条件: 

- グループまたはプロジェクトは、そのデータへのアクセスを許可する必要があります。
- プライベートグループおよびプロジェクトの場合、適切な権限を持つ[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)を使用する必要があります。

## GLQLクエリを実行する {#execute-a-glql-query}

GitLabリソースを検索およびフィルタリングするために、GLQLクエリを実行します。

```plaintext
POST /glql
```

> [!note]このエンドポイントは、クエリのSHAハッシュに基づいてクエリのレート制限を行います。タイムアウトする同一のクエリは追跡され、実行頻度が高すぎる場合は一時的にブロックされることがあります。

サポートされている属性: 

| 属性   | 型   | 必須 | 説明                                                                                                                           |
|-------------|--------|----------|---------------------------------------------------------------------------------------------------------------------------------------|
| `glql_yaml` | 文字列 | はい      | オプションのYAML設定を含むGLQLクエリ。最大サイズ: 10,000バイト（10 KB）。詳細については、[クエリ形式](#query-formats)を参照してください。 |
| `after`     | 文字列 | いいえ       | ページネーションのカーソル。次の結果ページをフェッチするには、以前のクエリの`data.pageInfo.endCursor`値を使用します。               |

### クエリ形式 {#query-formats}

`glql_yaml`パラメータは、`query`キーを持つYAML形式を受け入れます:

```yaml
fields: id,title,author
group: my-group
limit: 10
sort: created desc
query: state = opened
```

### 設定オプション {#configuration-options}

次の設定オプションは、YAMLに含めることができます:

| オプション    | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `fields`  | 文字列  | いいえ       | 返されるフィールドのカンマ区切りリスト。デフォルトは`title`です。[利用可能なフィールド](#available-fields)を参照してください。 |
| `group`   | 文字列  | いいえ       | クエリのスコープを特定のグループに設定します。`project`では使用できません。クエリで`group`も指定されている場合、クエリ値が優先されます。 |
| `limit`   | 整数 | いいえ       | 返す結果の最大数。1～100の間でなければなりません。デフォルトは`100`です。 |
| `project` | 文字列  | いいえ       | クエリのスコープを特定のプロジェクトに設定します。形式: `group/project`。クエリで`project`も指定されている場合、クエリ値が優先されます。 |
| `sort`    | 文字列  | いいえ       | 結果のソート順。形式: `field direction`（例: `created asc`、`created desc`）。 |

### 利用可能なフィールド {#available-fields}

`fields`設定オプションは、[GLQLの利用可能なフィールド](../user/glql/fields.md)によって定義されます。

### GLQLクエリ構文 {#glql-query-syntax}

クエリの構文は、[GLQL](../user/glql/_index.md#query-syntax)によって定義されます。

### レスポンス属性 {#response-attributes}

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                       | 型    | 説明 |
|---------------------------------|---------|-------------|
| `data`                          | オブジェクト  | クエリの結果が含まれています。 |
| `data.count`                    | 整数 | 一致する結果の合計数。 |
| `data.nodes`                    | 配列   | 要求されたフィールドを持つ、一致するリソースの配列。 |
| `data.pageInfo`                 | オブジェクト  | ページネーション情報。 |
| `data.pageInfo.endCursor`       | 文字列  | 次の結果ページをフェッチするためのカーソル。 |
| `data.pageInfo.hasNextPage`     | ブール値 | 利用可能な結果がさらにあるかどうかを示します。 |
| `data.pageInfo.hasPreviousPage` | ブール値 | 以前の結果が利用可能かどうかを示します。 |
| `data.pageInfo.startCursor`     | 文字列  | 前の結果ページをフェッチするためのカーソル。 |
| `error`                         | 文字列  | クエリが失敗した場合のエラーメッセージ。 |
| `fields`                        | 配列   | フィールド定義の配列。 |
| `fields[].key`                  | 文字列  | 一意のフィールド識別子。 |
| `fields[].label`                | 文字列  | 人間が読めるフィールド名。 |
| `fields[].name`                 | 文字列  | 類似のフィールドを統合する共通のフィールド名。たとえば、`created`キーと`createdAt`キーの名前は`createdAt`です。 |
| `success`                       | ブール値 | クエリが成功したかどうかを示します。 |

### 例: 基本クエリ {#example-basic-query}

グループ内で開かれたイシューを検索します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "query: group = \"my-group\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

レスポンス例:

```json
{
  "data": {
    "count": 1,
    "nodes": [
      {
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    }
  ],
  "success": true
}
```

### 例: フロントマター設定を使用したクエリ {#example-query-with-front-matter-configuration}

カスタムフィールドとソートで検索:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "fields: id,title,author,state\ngroup: my-group\nlimit: 5\nsort: created desc\nquery: state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

レスポンス例:

```json
{
  "data": {
    "count": 2,
    "nodes": [
      {
        "author": {
          "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
          "id": "gid://gitlab/User/123",
          "name": "John Doe",
          "username": "johndoe",
          "webUrl": "https://gitlab.example.com/johndoe"
        },
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      },
      {
        "author": {
          "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
          "id": "gid://gitlab/User/122",
          "name": "Jane Doe",
          "username": "janedoe",
          "webUrl": "https://gitlab.example.com/janedoe"
        },
        "id": "gid://gitlab/Issue/122",
        "iid": "122",
        "reference": "#122",
        "state": "OPEN",
        "title": "HTTP server examples for all programming languages",
        "webUrl": "https://gitlab.example.com/groups/my-group/-/issues/122",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "id",
      "label": "ID",
      "name": "id"
    },
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    },
    {
      "key": "author",
      "label": "Author",
      "name": "author"
    },
    {
      "key": "state",
      "label": "State",
      "name": "state"
    }
  ],
  "success": true
}
```

### 例: プロジェクトスコープを使用したクエリ {#example-query-with-project-scope}

特定のプロジェクトで検索:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "query: project = \"my-group/my-project\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

### 例: `currentUser()`関数を使用したクエリ {#example-query-with-currentuser-function}

現在のユーザーに割り当てられたイシューを検索します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "fields: id,title,assignees\nquery: group = \"my-group\" AND assignee = currentUser()"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

レスポンス例:

```json
{
  "data": {
    "count": 1,
    "nodes": [
      {
        "assignees": {
          "nodes": [
            {
              "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
              "id": "gid://gitlab/User/123",
              "name": "John Doe",
              "username": "johndoe",
              "webUrl": "https://gitlab.example.com/johndoe"
            }
          ]
        },
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "id",
      "label": "ID",
      "name": "id"
    },
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    },
    {
      "key": "assignees",
      "label": "Assignees",
      "name": "assignees"
    }
  ],
  "success": true
}
```

### 例: 制限とページネーションを使用したクエリ {#example-query-with-limit-and-pagination}

限られた数の結果を取得し、それらをページネーションします:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "limit: 2\nquery: group = \"my-group\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

レスポンス例:

```json
{
  "data": {
    "count": 68,
    "nodes": [
      {
        "id": "gid://gitlab/Issue/321",
        "iid": "321",
        "reference": "#321",
        "state": "OPEN",
        "title": "Corrupti consectetur impedit non blanditiis hic vitae minus.",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/321",
        "widgets": null
      },
      {
        "id": "gid://gitlab/WorkItem/322",
        "iid": "322",
        "reference": "#322",
        "state": "OPEN",
        "title": "Ipsa cupiditate corrupti vel maxime quasi at assumenda repellat quod.",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/322",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjIifQ==",
      "hasNextPage": true,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    }
  ],
  "success": true
}
```

次のページをフェッチするには、前のレスポンスの`endCursor`値を使用します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "limit: 2\nquery: group = \"my-group\" AND state = opened",
    "after": "eyJpZCI6IjIifQ=="
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

## レート制限 {#rate-limiting}

GLQL APIは、クエリのSHA-256ハッシュに基づいてレート制限を実装します。タイムアウトするクエリは追跡されます。タイムアウトしている特定のクエリの実行頻度が高すぎる場合、そのクエリは一時的にブロックされます。

レート制限が適用されると、APIはエラーメッセージとともに`429 Too Many Requests`ステータスコードを返します:

```json
{
  "error": "Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope."
}
```

## エラー処理 {#error-handling}

APIは、次のHTTPステータスコードを返します:

| ステータスコード                 | 説明 |
|-----------------------------|-------------|
| `200 Success`               | クエリが正常に実行されました。 |
| `400 Bad Request`           | 無効なクエリ構文、必須パラメータの欠落、または入力がサイズ制限を超えています。 |
| `401 Unauthorized`          | 認証が必要であるか、認証情報が無効です。 |
| `403 Forbidden`             | 権限が不十分であるか、必要なOAuthスコープがありません。 |
| `429 Too Many Requests`     | クエリのレート制限を超えました。 |
| `500 Internal Server Error` | クエリ実行中にサーバーエラーが発生しました。 |

### エラーレスポンスの例 {#error-response-examples}

- 必須パラメータがありません:

  ```json
  {
    "error": "glql_yaml is missing, glql_yaml is empty"
  }
  ```

- 無効なGLQL構文:

  ```json
  {
    "error": "400 Bad request - Error: Unexpected `invalid syntax @@@ ###`, expected operator (one of IN, =, !=, >, or <)"
  }
  ```

- 入力サイズを超えました:

  ```json
  {
    "error": "400 Bad request - Input exceeds maximum size"
  }
  ```

- 存在しないプロジェクト:

  ```json
  {
    "error": "400 Bad request - Error: Project does not exist or you do not have access to it"
  }
  ```

- 存在しないグループ:

  ```json
  {
    "error": "400 Bad request - Error: Group does not exist or you do not have access to it"
  }
  ```

- レート制限を超えました:

  ```json
  {
    "error": "Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope."
  }
  ```

- 無効なフィールド

  ```json
  {
    "error": "Field 'title' doesn't exist on type 'WorkItem' (Did you mean `title`?)"
  }
  ```

> [!note] GraphQL不正リクエストエラーは、該当する場合、`400`エラーコードとともにAPIの`error`フィールドにそのまま渡されます。

## 制限と制約 {#limits-and-constraints}

GLQL APIには、次の制限があります:

- 最大入力サイズ: `glql_yaml`パラメータの場合、10,000バイト（10 KB）。
- クエリの最大制限: リクエストあたり100件の結果。
- デフォルトの制限: 指定されていない場合は100件の結果。
- ページネーション: 以前のレスポンスの`endCursor`値を持つ`after`属性を使用すると、前方ページネーションのみがサポートされます。
- レート制限: クエリは、クエリのSHA-256ハッシュに基づいてレート制限されます。

## 関連トピック {#related-topics}

- [GLQLクエリ言語ドキュメント](../user/glql/_index.md)
- [REST API認証](rest/authentication.md)
- [OAuth 2.0認証](oauth2.md)
