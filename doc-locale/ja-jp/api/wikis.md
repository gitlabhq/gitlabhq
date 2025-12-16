---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトWiki API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクト[Wiki](../user/project/wiki/_index.md)のAPIは、APIv4でのみ利用可能です。[グループWiki](group_wikis.md)のAPIも利用できます。

## Wikiページの一覧表示 {#list-wiki-pages}

指定されたプロジェクトのすべてのWikiページを取得します。

```plaintext
GET /projects/:id/wikis
```

| 属性      | 型           | 必須 | 説明 |
| -------------- | -------------- | -------- | ----------- |
| `id`           | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `with_content` | ブール値        | いいえ       | ページのコンテンツを含めます。 |

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
  },{
    "content" : "*  [Deploy](deploy)\n*  [Development](development)",
    "format" : "markdown",
    "slug" : "home",
    "title" : "home",
    "encoding": "UTF-8"
  }
]
```

## Wikiページを取得 {#get-a-wiki-page}

指定されたプロジェクトのWikiページを取得します。

```plaintext
GET /projects/:id/wikis/:slug
```

| 属性     | 型           | 必須 | 説明 |
| ------------- | -------------- | -------- | ----------- |
| `id`          | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `slug`        | 文字列         | はい      | `dir%2Fpage_name`などのWikiページのURLエンコードされたslug（一意の文字列）。 |
| `render_html` | ブール値        | いいえ       | WikiページのレンダリングされたHTMLを返します。 |
| `version`     | 文字列         | いいえ       | WikiページのバージョンSHA。 |

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

## 新しいWikiページを作成する {#create-a-new-wiki-page}

指定されたリポジトリに、指定されたタイトル、slug、およびコンテンツを持つ新しいWikiページを作成します。

```plaintext
POST /projects/:id/wikis
```

| 属性 | 型           | 必須 | 説明 |
| ----------| -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `content` | 文字列         | はい      | Wikiページのコンテンツ。 |
| `title`   | 文字列         | はい      | Wikiページのタイトル。 |
| `format`  | 文字列         | いいえ       | Wikiページの形式。利用可能な形式は、`markdown`（デフォルト）、`rdoc`、`asciidoc`、および`org`です。 |

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

## 既存のWikiページを編集 {#edit-an-existing-wiki-page}

既存のWikiページを更新します。Wikiページを更新するには、少なくとも1つのパラメータが必要です。

```plaintext
PUT /projects/:id/wikis/:slug
```

| 属性 | 型           | 必須                          | 説明 |
| --------- | -------        | --------------------------------- | ----------- |
| `id`      | 整数または文字列 | はい                               | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `content` | 文字列         | `title`が指定されていない場合は「はい」   | Wikiページのコンテンツ。 |
| `title`   | 文字列         | `content`が指定されていない場合は「はい」 | Wikiページのタイトル。 |
| `format`  | 文字列         | いいえ                                | Wikiページの形式。利用可能な形式は、`markdown`（デフォルト）、`rdoc`、`asciidoc`、および`org`です。 |
| `slug`    | 文字列         | はい                               | `dir%2Fpage_name`などのWikiページのURLエンコードされたslug（一意の文字列）。 |

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

指定されたslugを持つWikiページを削除します。

```plaintext
DELETE /projects/:id/wikis/:slug
```

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `slug`    | 文字列         | はい      | `dir%2Fpage_name`などのWikiページのURLエンコードされたslug（一意の文字列）。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/wikis/foo"
```

成功した場合、空の本文を持つ`204 No Content` HTTPレスポンスが予期されます。

## Wikiリポジトリに添付ファイルをアップロード {#upload-an-attachment-to-the-wiki-repository}

ファイルをWikiのリポジトリ内の添付ファイルフォルダーにアップロードします。添付ファイルフォルダーは`uploads`フォルダーです。

```plaintext
POST /projects/:id/wikis/attachments
```

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `file`    | 文字列         | はい      | アップロードする添付ファイル。 |
| `branch`  | 文字列         | いいえ       | ブランチの名前Wikiリポジトリのデフォルトのブランチにデフォルト設定されます。 |

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

## Wikiページのコメント {#comments-on-wiki-pages}

Wikiのコメントは`notes`と呼ばれます。[Notes API](notes.md#project-wikis)を使用してそれらを操作できます。
