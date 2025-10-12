---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのGitタグのためのREST APIに関するドキュメント
title: タグAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

タグAPIを使用して、Gitタグを作成、管理、削除します。このAPIは、署名付きタグのX.509署名情報も返します。

## プロジェクトリポジトリタグをリストする {#list-project-repository-tags}

{{< history >}}

- `created_at`応答属性は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451011)されました。

{{< /history >}}

プロジェクトから、更新日時で降順にソートされたリポジトリタグの一覧を取得します。

{{< alert type="note" >}}

リポジトリが公開されている場合、認証（`--header "PRIVATE-TOKEN: <your_access_token>"`）は必要ありません。

{{< /alert >}}

```plaintext
GET /projects/:id/repository/tags
```

サポートされている属性:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `order_by` | 文字列            | いいえ       | `name`、`updated`、`version`のいずれかで並べ替えられたタグを返します。デフォルトは`updated`です。 |
| `search`   | 文字列            | いいえ       | 検索条件に一致するタグの一覧を返します。`^term`と`term$`を使用して、`term`で始まるタグと終わるタグを検索できます。他の正規表現はサポートされていません。 |
| `sort`     | 文字列            | いいえ       | `asc`または`desc`の順にソートされたタグを返します。デフォルトは`desc`です。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                | 型    | 説明 |
|--------------------------|---------|-------------|
| `commit`                 | オブジェクト  | タグに関連付けられたコミット情報。 |
| `commit.author_email`    | 文字列  | コミット作成者のメールアドレス。 |
| `commit.author_name`     | 文字列  | コミット作成者の名前。 |
| `commit.authored_date`   | 文字列  | コミットがISO 8601形式で作成された日付。 |
| `commit.committed_date`  | 文字列  | コミットがISO 8601形式でコミットされた日付。 |
| `commit.committer_email` | 文字列  | コミッターのメールアドレス。 |
| `commit.committer_name`  | 文字列  | コミッターの名前。 |
| `commit.created_at`      | 文字列  | コミットがISO 8601形式で作成された日付。 |
| `commit.id`              | 文字列  | コミットの完全なSHA。 |
| `commit.message`         | 文字列  | コミットメッセージ。 |
| `commit.parent_ids`      | 配列   | 親コミットSHAの配列。 |
| `commit.short_id`        | 文字列  | コミットの短いSHA。 |
| `commit.title`           | 文字列  | コミットのタイトル。 |
| `created_at`             | 文字列  | タグがISO 8601形式で作成された日付。 |
| `message`                | 文字列  | タグメッセージ。 |
| `name`                   | 文字列  | タグの名前。 |
| `protected`              | ブール値 | `true`の場合、タグは保護されます。 |
| `release`                | オブジェクト  | タグに関連付けられたリリース情報。 |
| `release.description`    | 文字列  | リリースに関する説明。 |
| `release.tag_name`       | 文字列  | リリースのタグ名。 |
| `target`                 | 文字列  | タグが指すSHA。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/repository/tags"
```

応答例:

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

## 単一リポジトリタグを取得する {#get-a-single-repository-tag}

{{< history >}}

- `created_at`応答属性は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451011)されました。

{{< /history >}}

名前で指定された特定のリポジトリタグを取得します。リポジトリが公開されている場合、このエンドポイントは認証なしでアクセスできます。

```plaintext
GET /projects/:id/repository/tags/:tag_name
```

サポートされている属性:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tag_name` | 文字列            | はい      | タグの名前。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                | 型    | 説明 |
|--------------------------|---------|-------------|
| `commit`                 | オブジェクト  | タグに関連付けられたコミット情報。 |
| `commit.author_email`    | 文字列  | コミット作成者のメールアドレス。 |
| `commit.author_name`     | 文字列  | コミット作成者の名前。 |
| `commit.authored_date`   | 文字列  | コミットがISO 8601形式で作成された日付。 |
| `commit.committed_date`  | 文字列  | コミットがISO 8601形式でコミットされた日付。 |
| `commit.committer_email` | 文字列  | コミッターのメールアドレス。 |
| `commit.committer_name`  | 文字列  | コミッターの名前。 |
| `commit.created_at`      | 文字列  | コミットがISO 8601形式で作成された日付。 |
| `commit.id`              | 文字列  | コミットの完全なSHA。 |
| `commit.message`         | 文字列  | コミットメッセージ。 |
| `commit.parent_ids`      | 配列   | 親コミットSHAの配列。 |
| `commit.short_id`        | 文字列  | コミットの短いSHA。 |
| `commit.title`           | 文字列  | コミットのタイトル。 |
| `created_at`             | 文字列  | タグがISO 8601形式で作成された日付。 |
| `message`                | 文字列  | タグメッセージ。 |
| `name`                   | 文字列  | タグの名前。 |
| `protected`              | ブール値 | `true`の場合、タグは保護されます。 |
| `release`                | オブジェクト  | タグに関連付けられたリリース情報。 |
| `target`                 | 文字列  | タグが指すSHA。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags/v1.0.0"
```

応答例:

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

## 新しいタグを作成する {#create-a-new-tag}

{{< history >}}

- `created_at`応答属性は、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451011)されました。

{{< /history >}}

指定された参照を指す、新しいタグをリポジトリに作成します。

```plaintext
POST /projects/:id/repository/tags
```

サポートされている属性:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `ref`      | 文字列            | はい      | コミットSHA、別のタグ名、またはブランチ名からタグを作成します。 |
| `tag_name` | 文字列            | はい      | タグの名前。 |
| `message`  | 文字列            | いいえ       | 注釈付きタグを作成します。 |

成功した場合は、[`201 Created`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                | 型    | 説明 |
|--------------------------|---------|-------------|
| `commit`                 | オブジェクト  | タグに関連付けられたコミット情報。 |
| `commit.author_email`    | 文字列  | コミット作成者のメールアドレス。 |
| `commit.author_name`     | 文字列  | コミット作成者の名前。 |
| `commit.authored_date`   | 文字列  | コミットがISO 8601形式で作成された日付。 |
| `commit.committed_date`  | 文字列  | コミットがISO 8601形式でコミットされた日付。 |
| `commit.committer_email` | 文字列  | コミッターのメールアドレス。 |
| `commit.committer_name`  | 文字列  | コミッターの名前。 |
| `commit.created_at`      | 文字列  | コミットがISO 8601形式で作成された日付。 |
| `commit.id`              | 文字列  | コミットの完全なSHA。 |
| `commit.message`         | 文字列  | コミットメッセージ。 |
| `commit.parent_ids`      | 配列   | 親コミットSHAの配列。 |
| `commit.short_id`        | 文字列  | コミットの短いSHA。 |
| `commit.title`           | 文字列  | コミットのタイトル。 |
| `created_at`             | 文字列  | タグがISO 8601形式で作成された日付。 |
| `message`                | 文字列  | タグメッセージ。 |
| `name`                   | 文字列  | タグの名前。 |
| `protected`              | ブール値 | `true`の場合、タグは保護されます。 |
| `release`                | オブジェクト  | タグに関連付けられたリリース情報。 |
| `target`                 | 文字列  | タグが指すSHA。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags?tag_name=test&ref=main"
```

応答例:

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

作成されたタグの種類によって、`created_at`、`target`、および`message`の内容が決まります。

- 注釈付きタグの場合:
  - `created_at`には、タグ作成時のタイムスタンプが含まれています。
  - `message`には、注釈が含まれています。
  - `target`には、タグオブジェクトのIDが含まれています。
- 軽量タグの場合:
  - `created_at`はnullです。
  - `message`はnullです。
  - `target`には、コミットIDが含まれています。

エラーが発生した場合、ステータスコード`405`と説明的なエラーメッセージが返されます。

## タグを削除する {#delete-a-tag}

指定された名前のリポジトリのタグを削除します。

```plaintext
DELETE /projects/:id/repository/tags/:tag_name
```

サポートされている属性:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tag_name` | 文字列            | はい      | タグの名前。 |

## タグのX.509署名を取得する {#get-x509-signature-of-a-tag}

タグが署名されている場合に[タグからX.509署名](../user/project/repository/signed_commits/x509.md)を取得します。署名されていないタグは、`404 Not Found`応答を返します。

```plaintext
GET /projects/:id/repository/tags/:tag_name/signature
```

サポートされている属性:

| 属性  | 型              | 必須 | 説明 |
|------------|-------------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `tag_name` | 文字列            | はい      | タグの名前。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                                             | 型    | 説明 |
|-------------------------------------------------------|---------|-------------|
| `signature_type`                                      | 文字列  | 署名のタイプ（`X509`）。 |
| `verification_status`                                 | 文字列  | 署名の検証ステータス。 |
| `x509_certificate`                                    | オブジェクト  | X.509証明書情報。 |
| `x509_certificate.certificate_status`                 | 文字列  | 証明書のステータス。 |
| `x509_certificate.email`                              | 文字列  | 証明書からのメールアドレス。 |
| `x509_certificate.id`                                 | 整数 | 証明書のID。 |
| `x509_certificate.serial_number`                      | 整数 | 証明書のシリアル番号。 |
| `x509_certificate.subject`                            | 文字列  | 証明書のサブジェクト。 |
| `x509_certificate.subject_key_identifier`             | 文字列  | 証明書のサブジェクトキー識別子。 |
| `x509_certificate.x509_issuer`                        | オブジェクト  | 証明書の発行者情報。 |
| `x509_certificate.x509_issuer.crl_url`                | 文字列  | 証明書失効リストのURL。 |
| `x509_certificate.x509_issuer.id`                     | 整数 | 発行者のID。 |
| `x509_certificate.x509_issuer.subject`                | 文字列  | 発行者のサブジェクト。 |
| `x509_certificate.x509_issuer.subject_key_identifier` | 文字列  | 発行者のサブジェクトキー識別子。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/tags/v1.1.1/signature"
```

タグがX.509署名されている場合の応答例:

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

タグが署名されていない場合の応答例:

```json
{
  "message": "404 GPG Signature Not Found"
}
```
