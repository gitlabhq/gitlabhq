---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for Git tags in GitLab.
title: タグAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## プロジェクトリポジトリタグをリストする

{{< history >}}

- `order_by`属性の`version`値は、GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95150)されました。
- `created_at`応答属性は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451011)されました。

{{< /history >}}

更新日時で降順にソートされた、リポジトリタグのリストをプロジェクトから取得します。

{{< alert type="note" >}}

リポジトリが公開されている場合、認証（`--header "PRIVATE-TOKEN: <your_access_token>"`）は必要ありません。

{{< /alert >}}

```plaintext
GET /projects/:id/repository/tags
```

パラメーター:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `order_by` | 文字列            | いいえ       | `name`、`updated`、または`version`で順序づけられたタグを返します。デフォルトは`updated`です。 |
| `sort`     | 文字列            | いいえ       | `asc`または`desc`の順にソートされたタグを返します。デフォルトは`desc`です。 |
| `search`   | 文字列            | いいえ       | 検索条件に一致するタグのリストを返します。`^term`と`term$`を使用して、それぞれ先頭と末尾が`term`のタグを検索できます。他の正規表現はサポートされていません。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/repository/tags"
```

応答の例:

```json
[
  {
    "commit": {
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "short_id": "2695effb",
      "title": "Initial commit",
      "created_at": "2017-07-26T11:08:53.000+02:00",
      "parent_ids": [
        "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
      ],
      "message": "Initial commit",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2012-05-28T04:42:42-07:00",
      "committer_name": "Jack Smith",
      "committer_email": "jack@example.com",
      "committed_date": "2012-05-28T04:42:42-07:00"
    },
    "release": {
      "tag_name": "1.0.0",
      "description": "Amazing release. Wow"
    },
    "name": "v1.0.0",
    "target": "2695effb5807a22ff3d138d593fd856244e155e7",
    "message": null,
    "protected": true,
    "created_at": "2017-07-26T11:08:53.000+02:00"
  }
]
```

## 単一のリポジトリタグを取得する

{{< history >}}

- `created_at`応答属性は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451011)されました。

{{< /history >}}

名前で特定される特定のリポジトリタグを取得します。リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /projects/:id/repository/tags/:tag_name
```

パラメーター:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tag_name` | 文字列            | はい      | タグの名前。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags/v1.0.0"
```

応答の例:

```json
{
  "name": "v5.0.0",
  "message": null,
  "target": "60a8ff033665e1207714d6670fcd7b65304ec02f",
  "commit": {
    "id": "60a8ff033665e1207714d6670fcd7b65304ec02f",
    "short_id": "60a8ff03",
    "title": "Initial commit",
    "created_at": "2017-07-26T11:08:53.000+02:00",
    "parent_ids": [
      "f61c062ff8bcbdb00e0a1b3317a91aed6ceee06b"
    ],
    "message": "v5.0.0\n",
    "author_name": "Arthur Verschaeve",
    "author_email": "contact@arthurverschaeve.be",
    "authored_date": "2015-02-01T21:56:31.000+01:00",
    "committer_name": "Arthur Verschaeve",
    "committer_email": "contact@arthurverschaeve.be",
    "committed_date": "2015-02-01T21:56:31.000+01:00"
  },
  "release": null,
  "protected": false,
  "created_at": "2017-07-26T11:08:53.000+02:00"
}
```

## 新しいタグを作成する

{{< history >}}

- `created_at`応答属性は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451011)されました。

{{< /history >}}

指定されたrefを指す新しいタグをリポジトリに作成します。

```plaintext
POST /projects/:id/repository/tags
```

パラメーター:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tag_name` | 文字列            | はい      | タグの名前。 |
| `ref`      | 文字列            | はい      | コミットSHA、別のタグ名、またはブランチ名からタグを作成します。 |
| `message`  | 文字列            | いいえ       | 注釈付きタグを作成します。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags?tag_name=test&ref=main"
```

応答の例:

```json
{
  "commit": {
    "id": "2695effb5807a22ff3d138d593fd856244e155e7",
    "short_id": "2695effb",
    "title": "Initial commit",
    "created_at": "2017-07-26T11:08:53.000+02:00",
    "parent_ids": [
      "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
    ],
    "message": "Initial commit",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-05-28T04:42:42-07:00",
    "committer_name": "Jack Smith",
    "committer_email": "jack@example.com",
    "committed_date": "2012-05-28T04:42:42-07:00"
  },
  "release": null,
  "name": "v1.0.0",
  "target": "2695effb5807a22ff3d138d593fd856244e155e7",
  "message": null,
  "protected": false,
  "created_at": null
}
```

作成されたタグのタイプによって、`created_at`、`target`、および`message`の内容が決まります。

- 注釈付きタグの場合:
  - `created_at`には、タグ作成のタイムスタンプが含まれています。
  - `message`には、注釈が含まれています。
  - `target`には、タグオブジェクトのIDが含まれています。
- 軽量タグの場合:
  - `created_at`はnullです。
  - `message`はnullです。
  - `target`には、コミットIDが含まれています。

エラーは、ステータスコード`405`と説明的なエラーメッセージを返します。

## タグを削除する

指定された名前のリポジトリのタグを削除します。

```plaintext
DELETE /projects/:id/repository/tags/:tag_name
```

パラメーター:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tag_name` | 文字列            | はい      | タグの名前。 |

## タグのX.509署名を取得する

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106578)されました。

{{< /history >}}

タグが署名されている場合は、[タグからX.509署名](../user/project/repository/signed_commits/x509.md)を取得します。署名されていないタグは、`404 Not Found`応答を返します。

```plaintext
GET /projects/:id/repository/tags/:tag_name/signature
```

パラメーター:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tag_name` | 文字列            | はい      | タグの名前。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/tags/v1.1.1/signature"
```

タグにX.509署名がある場合の応答の例:

```json
{
  "signature_type": "X509",
  "verification_status": "unverified",
  "x509_certificate": {
    "id": 1,
    "subject": "CN=gitlab@example.org,OU=Example,O=World",
    "subject_key_identifier": "BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC",
    "email": "gitlab@example.org",
    "serial_number": 278969561018901340486471282831158785578,
    "certificate_status": "good",
    "x509_issuer": {
      "id": 1,
      "subject": "CN=PKI,OU=Example,O=World",
      "subject_key_identifier": "AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB",
      "crl_url": "http://example.com/pki.crl"
    }
  }
}
```

タグが署名されていない場合の応答の例:

```json
{
  "message": "404 GPG Signature Not Found"
}
```
