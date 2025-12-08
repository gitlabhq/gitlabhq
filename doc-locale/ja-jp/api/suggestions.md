---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 変更提案API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コードをレビューする際、コード提案を使用すると、直接適用できる特定の変更を提案できます。詳細については、[コード提案](../user/project/merge_requests/reviews/suggestions.md)を参照してください。

このAPIを使用すると、マージリクエストのディスカッションでプログラムによってコード提案を作成および適用できます。コード提案に対するすべてのAPIコールは認証される必要があります。

## 提案の作成 {#create-a-suggestion}

APIを介して提案を作成するには、Discussions APIを使用して、[マージリクエスト差分に新しいスレッドを作成](discussions.md#create-new-merge-request-thread)します。提案の形式は次のとおりです:

````markdown
```suggestion:-3+0
example text
```
````

## 提案の適用 {#apply-a-suggestion}

マージリクエストで提案されたパッチを適用します。

前提要件: 

- ユーザーは、少なくともデベロッパーロールを持っている必要があります。

```plaintext
PUT /suggestions/:id/apply
```

サポートされている属性は以下のとおりです:

| 属性        | 型    | 必須 | 説明 |
|------------------|---------|----------|-------------|
| `id`             | 整数 | はい      | 提案のID。 |
| `commit_message` | 文字列  | いいえ       | デフォルトで生成されたメッセージまたはプロジェクトのデフォルトメッセージの代わりに使用するカスタムコミットメッセージ。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性      | 型    | 説明 |
|----------------|---------|-------------|
| `applicable`   | ブール値 | `true`の場合、提案を適用できます。 |
| `applied`      | ブール値 | `true`の場合、提案が適用されています。 |
| `from_content` | 文字列  | 提案前の元のコンテンツ。 |
| `from_line`    | 整数 | 提案の開始行番号。 |
| `id`           | 整数 | 提案のID。 |
| `to_content`   | 文字列  | 元のコンテンツを置き換えるために提案されたコンテンツ。 |
| `to_line`      | 整数 | 提案の終了行番号。 |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/suggestions/5/apply"
```

レスポンス例:

```json
{
  "id": 5,
  "from_line": 10,
  "to_line": 10,
  "applicable": true,
  "applied": false,
  "from_content": "This is an example\n",
  "to_content": "This is an example\n"
}
```

## 複数の提案を適用 {#apply-multiple-suggestions}

マージリクエストで複数の提案されたパッチを適用します。

前提要件: 

- ユーザーは、少なくともデベロッパーロールを持っている必要があります。

```plaintext
PUT /suggestions/batch_apply
```

サポートされている属性は以下のとおりです:

| 属性        | 型          | 必須 | 説明 |
|------------------|---------------|----------|-------------|
| `ids`            | 整数の配列 | はい      | 適用する提案のIDの配列。 |
| `commit_message` | 文字列        | いいえ       | デフォルトで生成されたメッセージまたはプロジェクトのデフォルトメッセージの代わりに使用するカスタムコミットメッセージ。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、次の応答属性を持つ提案オブジェクトの配列を返します:

| 属性      | 型    | 説明 |
|----------------|---------|-------------|
| `applicable`   | ブール値 | `true`の場合、提案を適用できます。 |
| `applied`      | ブール値 | `true`の場合、提案が適用されています。 |
| `from_content` | 文字列  | 提案前の元のコンテンツ。 |
| `from_line`    | 整数 | 提案の開始行番号。 |
| `id`           | 整数 | 提案のID。 |
| `to_content`   | 文字列  | 元のコンテンツを置き換えるために提案されたコンテンツ。 |
| `to_line`      | 整数 | 提案の終了行番号。 |

リクエスト例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"ids": [5, 6]}' \
  --url "https://gitlab.example.com/api/v4/suggestions/batch_apply"
```

レスポンス例:

```json
[
  {
    "id": 5,
    "from_line": 10,
    "to_line": 10,
    "applicable": true,
    "applied": false,
    "from_content": "This is an example\n",
    "to_content": "This is an example\n"
  },
  {
    "id": 6,
    "from_line": 19,
    "to_line": 19,
    "applicable": true,
    "applied": false,
    "from_content": "This is another example\n",
    "to_content": "This is another example\n"
  }
]
```
