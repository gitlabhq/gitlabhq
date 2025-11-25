---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトレベルセキュアファイルAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/350748)になりました。機能フラグ`ci_secure_files`は削除されました。

{{< /history >}}

このAPIを使用して、プロジェクトの[セキュアファイル](../ci/secure_files/_index.md)を管理します。

## プロジェクトのセキュアファイルの一覧表示 {#list-project-secure-files}

プロジェクト内のセキュアファイルのリストを取得します。

```plaintext
GET /projects/:project_id/secure_files
```

サポートされている属性は以下のとおりです:

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `project_id` | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files"
```

レスポンス例:

```json
[
    {
        "id": 1,
        "name": "myfile.jks",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
        "checksum_algorithm": "sha256",
        "created_at": "2022-02-22T22:22:22.222Z",
        "expires_at": null,
        "metadata": null
    },
    {
        "id": 2,
        "name": "myfile.cer",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aa2",
        "checksum_algorithm": "sha256",
        "created_at": "2022-02-22T22:22:22.222Z",
        "expires_at": "2023-09-21T14:55:59.000Z",
        "metadata": {
            "id":"75949910542696343243264405377658443914",
            "issuer": {
                "C":"US",
                "O":"Apple Inc.",
                "CN":"Apple Worldwide Developer Relations Certification Authority",
                "OU":"G3"
            },
            "subject": {
                "C":"US",
                "O":"Organization Name",
                "CN":"Apple Distribution: Organization Name (ABC123XYZ)",
                "OU":"ABC123XYZ",
                "UID":"ABC123XYZ"
            },
            "expires_at":"2023-09-21T14:55:59.000Z"
        }
    }
]
```

## セキュアファイルの詳細を表示 {#show-secure-file-details}

プロジェクト内の特定のセキュアファイルの詳細を取得します。

```plaintext
GET /projects/:project_id/secure_files/:id
```

サポートされている属性は以下のとおりです:

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数        | はい      | セキュアファイルのID。 |
| `project_id` | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```

レスポンス例:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## セキュアファイルを作成 {#create-secure-file}

新しいセキュアファイルを作成します。

```plaintext
POST /projects/:project_id/secure_files
```

サポートされている属性は以下のとおりです:

| 属性       | 型           | 必須 | 説明 |
|-----------------|----------------|----------|-------------|
| `file`          | ファイル           | はい      | アップロードされるファイル（5 MBの制限）。 |
| `name`          | 文字列         | はい      | アップロードされるファイルの名前。ファイル名はプロジェクト内で一意である必要があります。 |
| `project_id`    | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files" \
  --form "name=myfile.jks" \
  --form "file=@/path/to/file/myfile.jks"
```

レスポンス例:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## セキュアファイルをダウンロード {#download-secure-file}

プロジェクトのセキュアファイルの内容をダウンロードします。

```plaintext
GET /projects/:project_id/secure_files/:id/download
```

サポートされている属性は以下のとおりです:

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数        | はい      | セキュアファイルのID。 |
| `project_id` | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1/download" \
  --output myfile.jks
```

## セキュアファイルを削除 {#remove-secure-file}

プロジェクトのセキュアファイルを削除します。

```plaintext
DELETE /projects/:project_id/secure_files/:id
```

サポートされている属性は以下のとおりです:

| 属性    | 型           | 必須 | 説明 |
|--------------|----------------|----------|-------------|
| `id`         | 整数        | はい      | セキュアファイルのID。 |
| `project_id` | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```
