---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループMarkdownアップロードAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、エピックまたはWikiページでMarkdownテキストとして参照できる[Markdownアップロード](../security/user_file_uploads.md)を管理します。

## ファイルをグループにアップロードする {#upload-a-file-to-a-group}

{{< history >}}

- GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230537)されました。

{{< /history >}}

指定されたグループにファイルをアップロードします。ファイルへのMarkdown形式のリンクを返します。

このエンドポイントを使用するには、ゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
POST /groups/:id/uploads
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `file`    | ファイル              | はい      | アップロードするファイル。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@/path/to/image.png" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads"
```

レスポンス例: 

```json
{
  "id": 3,
  "alt": "image",
  "url": "/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png",
  "full_path": "/-/group/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png",
  "markdown": "![image](/uploads/648d97c6eef5fc5df8d1004565b3ee5a/image.png)"
}
```

## グループのすべてのアップロードを一覧表示する {#list-all-uploads-for-a-group}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)。

{{< /history >}}

指定されたグループのすべてのアップロードを`created_at`で降順に並べ替えて一覧表示します。

このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

```plaintext
GET /groups/:id/uploads
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads"
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

## IDでアップロード済みファイルをダウンロードする {#download-an-uploaded-file-by-id}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)。

{{< /history >}}

指定されたIDのアップロード済みファイルをダウンロードします。このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

```plaintext
GET /groups/:id/uploads/:upload_id
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `upload_id` | 整数           | はい      | アップロードのID。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/1"
```

成功した場合、[`200`](rest/troubleshooting.md#status-codes)を返し、応答本文にアップロード済みファイルが返されます。

## シークレットとファイル名でアップロード済みファイルをダウンロードする {#download-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441)されました。

{{< /history >}}

指定されたシークレットとファイル名のアップロード済みファイルをダウンロードします。このエンドポイントを使用するには、ゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

```plaintext
GET /groups/:id/uploads/:secret/:filename
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `secret`    | 文字列            | はい      | アップロードの32文字のシークレット。 |
| `filename`  | 文字列            | はい      | アップロードのファイル名。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

成功した場合、[`200`](rest/troubleshooting.md#status-codes)を返し、応答本文にアップロード済みファイルが返されます。

## IDでアップロード済みファイルを削除する {#delete-an-uploaded-file-by-id}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066)。

{{< /history >}}

指定されたIDのアップロード済みファイルを削除します。このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

```plaintext
DELETE /groups/:id/uploads/:upload_id
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `upload_id` | 整数           | はい      | アップロードのID。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/1"
```

成功した場合、応答本文なしで[`204`](rest/troubleshooting.md#status-codes)ステータスcodeを返します。

## シークレットとファイル名でアップロード済みファイルを削除する {#delete-an-uploaded-file-by-secret-and-filename}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164441)されました。

{{< /history >}}

指定されたシークレットとファイル名のアップロード済みファイルを削除します。このエンドポイントを使用するには、メンテナーまたはオーナーロールが必要です。

```plaintext
DELETE /groups/:id/uploads/:secret/:filename
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `secret`    | 文字列            | はい      | アップロードの32文字のシークレット。 |
| `filename`  | 文字列            | はい      | アップロードのファイル名。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/uploads/648d97c6eef5fc5df8d1004565b3ee5a/sample.jpg"
```

成功した場合、応答本文なしで[`204`](rest/troubleshooting.md#status-codes)ステータスcodeを返します。
