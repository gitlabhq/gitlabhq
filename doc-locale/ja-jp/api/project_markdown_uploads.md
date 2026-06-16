---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: MarkdownアップロードAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、イシュー、マージリクエスト、スニペット、またはWikiページでMarkdownテキストで参照できる[Markdownアップロード](../security/user_file_uploads.md)を管理します。

## アップロードを作成する {#create-an-upload}

{{< history >}}

- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112450)になりました。機能フラグ`enforce_max_attachment_size_upload_api`は削除されました。
- `full_path`レスポンスの属性パターンがGitLab 17.1で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150939)されました。
- `id`属性がGitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161160)されました。

{{< /history >}}

指定されたプロジェクトにファイルをアップロードし、イシューまたはマージリクエストの説明、あるいはコメントで使用します。

```plaintext
POST /projects/:id/uploads
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `file`    | 文字列            | はい      | アップロードするファイル。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

ファイルシステムからファイルをアップロードするには、`--form`引数を使用します。これにより、cURLは`Content-Type: multipart/form-data`ヘッダーを使用してデータを投稿します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "file=@dk.png" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

レスポンス例: 

```json
{
  "id": 5,
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "full_path": "/-/project/1234/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

レスポンスでは、以下が含まれます:

- `full_path`はファイルの絶対パスです。
- `url`はMarkdownコンテキストで使用できます。`markdown`でのフォーマットが使用されると、リンクが展開されます。

## アップロードを一覧表示する {#list-uploads}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)。

{{< /history >}}

プロジェクトのすべてのアップロードを`created_at`で降順に一覧表示します。

前提条件: 

- メンテナーまたはオーナーロール。

```plaintext
GET /projects/:id/uploads
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "size": 1024,
    "filename": "image.png",
    "created_at":"2024-06-20T15:53:03.067Z",
    "uploaded_by": {
      "id": 18,
      "name" : "Alexandra Bashirian",
      "username" : "eileen.lowe"
    }
  },
  {
    "id": 2,
    "size": 512,
    "filename": "other-image.png",
    "created_at":"2024-06-19T15:53:03.067Z",
    "uploaded_by": null
  }
]
```

## IDでアップロードされたファイルをダウンロードする {#download-an-uploaded-file-by-id}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)。

{{< /history >}}

IDでアップロードされたファイルをダウンロードします。

前提条件: 

- メンテナーまたはオーナーロール。

```plaintext
GET /projects/:id/uploads/:upload_id
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|:------------|:------------------|:---------|:------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `upload_id` | 整数           | はい      | アップロードのID。 |

成功すると、[`200`](rest/troubleshooting.md#status-codes)とアップロードされたファイルがレスポンスボディで返されます。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## シークレットとファイル名でアップロードされたファイルをダウンロードする {#download-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441)されました。

{{< /history >}}

シークレットとファイル名でアップロードされたファイルをダウンロードします。

前提条件: 

- ゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロール。

```plaintext
GET /projects/:id/uploads/:secret/:filename
```

サポートされている属性は以下のとおりです: 

| 属性  | 型              | 必須 | 説明 |
|:-----------|:------------------|:---------|:------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `secret`   | 文字列            | はい      | アップロードの32文字のシークレット。 |
| `filename` | 文字列            | はい      | アップロードのファイル名。 |

成功すると、[`200`](rest/troubleshooting.md#status-codes)とアップロードされたファイルがレスポンスボディで返されます。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

## IDでアップロードされたファイルを削除する {#delete-an-uploaded-file-by-id}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)。

{{< /history >}}

IDでアップロードされたファイルを削除します。

前提条件: 

- メンテナーまたはオーナーロール。

```plaintext
DELETE /projects/:id/uploads/:upload_id
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|:------------|:------------------|:---------|:------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `upload_id` | 整数           | はい      | アップロードのID。 |

成功すると、レスポンスボディなしで[`204`](rest/troubleshooting.md#status-codes)ステータスコードが返されます。

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## シークレットとファイル名でアップロードされたファイルを削除する {#delete-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441)されました。

{{< /history >}}

シークレットとファイル名でアップロードされたファイルを削除します。

前提条件: 

- メンテナーまたはオーナーロール。

```plaintext
DELETE /projects/:id/uploads/:secret/:filename
```

サポートされている属性は以下のとおりです: 

| 属性  | 型              | 必須 | 説明 |
|:-----------|:------------------|:---------|:------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `secret`   | 文字列            | はい      | アップロードの32文字のシークレット。 |
| `filename` | 文字列            | はい      | アップロードのファイル名。 |

成功すると、レスポンスボディなしで[`204`](rest/troubleshooting.md#status-codes)ステータスコードが返されます。

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```
