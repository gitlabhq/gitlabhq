---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトWiki API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[プロジェクトWiki](../user/project/wiki/_index.md)を管理します。[グループWiki](group_wikis.md)用のAPIも利用できます。

Wikiページへのコメントは`notes`と呼ばれます。それらを操作するには、[notes API](notes.md#project-wikis)を使用します。

## すべてのWikiページを一覧表示する {#list-all-wiki-pages}

指定されたプロジェクトのすべてのWikiページを一覧表示します。

```plaintext
GET /projects/:id/wikis
```

| 属性      | 型           | 必須 | 説明 |
| -------------- | -------------- | -------- | ----------- |
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `with_content` | ブール値        | いいえ       | ページの内容を含めます。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis?with_content=1"
```

レスポンス例: 

```json
[
  {
    "content" : "Here is an instruction how to deploy this project.",
    "format" : "markdown",
    "slug" : "deploy",
    "title" : "deploy",
    "encoding": "UTF-8"
  },
  {
    "content" : "Our development process is described here.",
    "format" : "markdown",
    "slug" : "development",
    "title" : "development",
    "encoding": "UTF-8"
  },
  {
    "content" : "*  [Deploy](deploy)\n*  [Development](development)",
    "format" : "markdown",
    "slug" : "home",
    "title" : "home",
    "encoding": "UTF-8"
  }
]
```

## Wikiページを取得する {#retrieve-a-wiki-page}

指定されたプロジェクトのWikiページを取得します。

```plaintext
GET /projects/:id/wikis/:slug
```

| 属性     | 型           | 必須 | 説明 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `slug`        | 文字列         | はい      | WikiページのURLエンコードされたslug（一意の文字列）。例: `dir%2Fpage_name`。 |
| `render_html` | ブール値        | いいえ       | WikiページのレンダリングされたHTMLを返します。 |
| `version`     | 文字列         | いいえ       | WikiページバージョンSHA。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/home"
```

レスポンス例: 

```json
{
  "content" : "home page",
  "format" : "markdown",
  "slug" : "home",
  "title" : "home",
  "encoding": "UTF-8"
}
```

## Wikiページを作成する {#create-a-wiki-page}

指定されたプロジェクトに、指定されたタイトル、slug、および内容でWikiページを作成します。

```plaintext
POST /projects/:id/wikis
```

| 属性 | 型           | 必須 | 説明 |
| ----------| -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `content` | 文字列         | はい      | Wikiページの内容。 |
| `title`   | 文字列         | はい      | Wikiページのタイトル。 |
| `format`  | 文字列         | いいえ       | Wikiページのフォーマット。利用可能なフォーマットは、`markdown`（デフォルト）、`rdoc`、`asciidoc`、`org`です。 |

```shell
curl --data "format=rdoc&title=Hello&content=Hello world" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis"
```

レスポンス例: 

```json
{
  "content" : "Hello world",
  "format" : "markdown",
  "slug" : "Hello",
  "title" : "Hello",
  "encoding": "UTF-8"
}
```

特殊文字や図を含むMarkdownコンテンツの場合、ファイルの参照とともに`--data-urlencode`を使用して、エンコードを自動的に処理します。

例として、`content.md`という名前のファイルにWikiコンテンツを作成し、以下のコマンドを実行します:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data-urlencode "title=Page with Complex Content" \
  --data-urlencode "content@content.md" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis"
```

`--data-urlencode "content@content.md"`オプションは、Markdownファイルの内容をURLエンコードし、`content`属性に割り当てます。このエンコードにより、特殊文字、改行、および複雑なMarkdownの構文が処理され、それらが原因で発生する可能性のあるエラーを防ぎます。

レスポンス例: 

```json
{
"content": "<contents of content.md>",
"format": "markdown",
"slug": "Page-with-Complex-Content",
"title": "Page with Complex Content",
"encoding": "UTF-8"
}
```

## Wikiページを更新する {#update-a-wiki-page}

指定されたWikiページを更新します。Wikiページを更新するには、少なくとも1つのパラメータが必要です。

```plaintext
PUT /projects/:id/wikis/:slug
```

| 属性 | 型           | 必須                          | 説明 |
| --------- | -------        | --------------------------------- | ----------- |
| `id`      | 整数または文字列 | はい                               | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `content` | 文字列         | はい、`title`が指定されていない場合   | Wikiページの内容。 |
| `title`   | 文字列         | はい、`content`が指定されていない場合 | Wikiページのタイトル。 |
| `format`  | 文字列         | いいえ                                | Wikiページのフォーマット。利用可能なフォーマットは、`markdown`（デフォルト）、`rdoc`、`asciidoc`、`org`です。 |
| `slug`    | 文字列         | はい                               | URL-エンコードされたslug（Wikiページの一意な文字列）。例: `dir%2Fpage_name`。 |

```shell
curl --request PUT \
  --data "format=rdoc&content=documentation&title=Docs" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

レスポンス例: 

```json
{
  "content" : "documentation",
  "format" : "markdown",
  "slug" : "Docs",
  "title" : "Docs",
  "encoding": "UTF-8"
}
```

## Wikiページを削除する {#delete-a-wiki-page}

指定されたWikiページを削除します。

```plaintext
DELETE /projects/:id/wikis/:slug
```

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `slug`    | 文字列         | はい      | URL-エンコードされたslug（Wikiページの一意な文字列）。例: `dir%2Fpage_name`。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

成功した場合、空のボディを持つ`204 No Content` HTTPレスポンスが期待されます。

## Wikiリポジトリに添付ファイルをアップロードする {#upload-an-attachment-to-the-wiki-repository}

Wikiのリポジトリ内の添付フォルダーにファイルをアップロードします。添付フォルダーは`uploads`フォルダーです。

```plaintext
POST /projects/:id/wikis/attachments
```

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `file`    | 文字列         | はい      | アップロードする添付ファイル。 |
| `branch`  | 文字列         | いいえ       | ブランチの名前Wikiリポジトリのデフォルトブランチに設定されます。 |

ファイルシステムからファイルをアップロードするには、`--form`引数を使用します。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@dk.png" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/attachments"
```

レスポンス例: 

```json
{
  "file_name" : "dk.png",
  "file_path" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
  "branch" : "main",
  "link" : {
    "url" : "uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png",
    "markdown" : "![A description of the attachment](uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png)"
  }
}
```
