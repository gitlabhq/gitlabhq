---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトのインポート/エクスポートAPI
description: "REST APIを使用してプロジェクトをインポートおよびエクスポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用してプロジェクトを[移行する](../user/project/settings/import_export.md)ことができます。まず[グループインポートおよびエクスポートAPI](group_import_export.md)で親グループ構造を移行すると、プロジェクトのイシューとグループのエピック間の接続など、グループレベルのリレーションシップを維持できます。

このAPIを使用した後、プロジェクトのCI/CD変数を保持するために、[プロジェクトレベルのCI/CD変数API](project_level_variables.md)を使用することをお勧めします。

Dockerのプルとプッシュを繰り返して、[コンテナレジストリ](../user/packages/container_registry/_index.md)を移行する必要があります。CI/CDパイプラインを再実行して、ビルドアーティファクトを取得することができます。

前提条件: 

- プロジェクトのエクスポートについては、[プロジェクトとそのデータをエクスポート](../user/project/settings/import_export.md#export-a-project-and-its-data)を参照してください。
- プロジェクトのインポートについては、[プロジェクトとそのデータをインポート](../user/project/settings/import_export.md#import-a-project-and-its-data)を参照してください。

## プロジェクトをエクスポート {#export-a-project}

指定したプロジェクトをエクスポートする。

`upload`ハッシュパラメータを使用して、エクスポートされたプロジェクトをウェブサーバーまたはS3互換のプラットフォームにアップロードします。エクスポートの場合、GitLabは次のとおりです:

- バイナリデータファイルのアップロードのみを最終サーバーにサポートします。
- アップロードリクエストとともに`Content-Type: application/gzip`ヘッダーを送信します。署名の一部として、事前署名されたURLにこれを含めるようにしてください。
- プロジェクトのエクスポートプロセスが完了するまでに時間がかかる場合があります。アップロードURLの有効期限が短すぎず、エクスポートプロセス全体で利用可能であることを確認してください。
- 管理者は、最大エクスポートファイルサイズを変更できます。デフォルトでは、最大値は無制限（`0`）です。これを変更するには、次のいずれかを使用して`max_export_size`を編集します:
  - [GitLab UI](../administration/settings/import_and_export_settings.md)。
  - [アプリケーション設定API](settings.md#update-application-settings)
- GitLab.comでの最大インポートファイルサイズに固定の制限があります。詳細については、[アカウントと制限設定](../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

`upload`パラメータが存在する場合、`upload[url]`パラメータが必要です。

Amazon S3へのアップロードについては、`upload[url]`を生成するための[オブジェクトアップロード用の署名済みURL生成](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)ドキュメントスクリプトを参照してください。[既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/430277)のため、最大ファイルサイズ5 GBまでのファイルのみをAmazon S3にアップロードできます。

```plaintext
POST /projects/:id/export
```

| 属性             | タイプ              | 必須 | 説明 |
|-----------------------|-------------------|----------|-------------|
| `id`                  | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `upload[url]`         | 文字列            | はい      | プロジェクトをアップロードするURL。 |
| `description`         | 文字列            | いいえ       | プロジェクトの説明をオーバーライドします。 |
| `upload`              | ハッシュ              | いいえ       | エクスポートされたプロジェクトをウェブサーバーにアップロードするための情報を含むハッシュ。 |
| `upload[http_method]` | 文字列            | いいえ       | エクスポートされたプロジェクトをアップロードするためのHTTPメソッド。`PUT`および`POST`メソッドのみが許可されます。デフォルトは`PUT`です。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export" \
  --data "upload[http_method]=PUT" \
  --data-urlencode "upload[url]=https://example-bucket.s3.eu-west-3.amazonaws.com/backup?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=<your_access_token>%2F20180312%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20180312T110328Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=8413facb20ff33a49a147a0b4abcff4c8487cc33ee1f7e450c46e8f695569dbd"
```

```json
{
  "message": "202 Accepted"
}
```

## プロジェクトのエクスポートステータスを取得する {#retrieve-the-status-of-a-project-export}

指定したプロジェクトの最新のエクスポートステータスを取得する。

```plaintext
GET /projects/:id/export
```

| 属性 | タイプ              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export"
```

ステータスは次のいずれかです:

- `none`: キューに入れられたエクスポート、開始されたエクスポート、完了したエクスポート、または再生成中のエクスポートはありません。
- `queued`: エクスポートのリクエストが受信され、処理のためにキューに入っています。
- `started`: エクスポートプロセスが開始され、進行中です。これには以下が含まれます:
  - エクスポートのプロセス。
  - 結果ファイルに対して実行されるアクション。メールでユーザーにファイルをダウンロードするよう通知したり、エクスポートされたファイルをウェブサーバーにアップロードしたりする場合など。
- `finished`: エクスポートプロセスが完了し、ユーザーに通知された後。
- `regeneration_in_progress`: エクスポートファイルがダウンロード可能になり、新しいエクスポートを生成するリクエストが処理中です。

`_links`は、エクスポートが完了した場合にのみ存在します。

`created_at`は、プロジェクト作成のタイムスタンプであり、エクスポート開始時間ではありません。

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "export_status": "finished",
  "_links": {
    "api_url": "https://gitlab.example.com/api/v4/projects/1/export/download",
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/download_export"
  }
}
```

## プロジェクトエクスポートをダウンロード {#download-a-project-export}

指定したプロジェクトの最新のエクスポートをダウンロードします。

```plaintext
GET /projects/:id/export/download
```

| 属性 | タイプ              | 必須 | 説明                              |
| --------- | ----------------- | -------- | ---------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/projects/5/export/download"
```

```shell
ls *export.tar.gz
2017-12-05_22-11-148_namespace_project_export.tar.gz
```

## ローカルアーカイブからプロジェクトをインポート {#import-a-project-from-a-local-archive}

{{< history >}}

- GitLab 16.0で、デベロッパーロールの代わりにメンテナーロールが必要になりました。
- `namespace_id`および`namespace_path`属性がGitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/511053)されました。

{{< /history >}}

ローカルアーカイブからプロジェクトをインポートします。

```plaintext
POST /projects/import
```

| 属性         | タイプ              | 必須 | 説明 |
|-------------------|-------------------|----------|-------------|
| `file`            | 文字列            | はい      | アップロードするファイル。 |
| `path`            | 文字列            | はい      | 新しいプロジェクトの名前とパス。 |
| `name`            | 文字列            | いいえ       | インポートするプロジェクトの名前。指定しない場合、プロジェクトのパスにデフォルト設定されます。 |
| `namespace`       | 整数または文字列 | いいえ       | （非推奨）プロジェクトをインポートするネームスペースのIDまたはパス。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。代わりに、`namespace_id`または`namespace_path`を使用してください。 |
| `namespace_id`    | 整数           | いいえ       | プロジェクトをインポートするネームスペースのID。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。 |
| `namespace_path`  | 文字列            | いいえ       | プロジェクトをインポートするネームスペースのパス。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。 |
| `override_params` | ハッシュ              | いいえ       | [プロジェクトAPI](projects.md)で定義されているすべてのフィールドをサポートします。 |
| `overwrite`       | ブール値           | いいえ       | 同じパスのプロジェクトが存在する場合、インポートはそれを上書きするします。`false`がデフォルトです。 |

渡されたオーバーライドパラメータは、エクスポートファイル内で定義されたすべての値よりも優先されます。

ファイルシステムからファイルをアップロードするには、`--form`引数を使用します。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "path=api-project" \
  --form "file=@/path/to/file" \
  --url "https://gitlab.example.com/api/v4/projects/import"
```

cURLは、リモートサーバーからのファイル投稿をサポートしていません。この例では、Pythonの`open`メソッドを使用してプロジェクトをインポートします:

```python
import requests

url =  'https://gitlab.example.com/api/v4/projects/import'
files = { "file": open("project_export.tar.gz", "rb") }
data = {
    "path": "example-project",
    "namespace_path": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "api-project",
  "name_with_namespace": "Administrator / api-project",
  "path": "api-project",
  "path_with_namespace": "root/api-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": []
}
```

> [!note]
> 最大インポートファイルサイズは管理者が設定できます。`0`（無制限）にデフォルト設定されます。管理者は、最大インポートファイルサイズを変更できます。そのためには、[アプリケーション設定API](settings.md#update-application-settings)または[**管理者**エリア](../administration/settings/account_and_limit_settings.md)で`max_import_size`オプションを使用します。

## リモートアーカイブからプロジェクトをインポート {#import-a-project-from-a-remote-archive}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- `namespace_id`および`namespace_path`属性がGitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/511053)されました。

{{< /history >}}

> [!flag] 
> GitLab Self-Managedでは、この機能はデフォルトで利用可能です。この機能を非表示にするために、管理者は`import_project_from_remote_file`という名前の[機能フラグを無効](../administration/feature_flags/_index.md)にできます。GitLab.comおよびGitLab Dedicatedでは、この機能を使用できます。

リモートアーカイブからプロジェクトをインポートします。

```plaintext
POST /projects/remote-import
```

| 属性         | タイプ              | 必須 | 説明                              |
| ----------------- | ----------------- | -------- | ---------------------------------------- |
| `path`            | 文字列            | はい      | 新しいプロジェクトの名前とパス。 |
| `url`             | 文字列            | はい      | インポートするファイルのURL。 |
| `name`            | 文字列            | いいえ       | インポートするプロジェクトの名前。指定しない場合、プロジェクトのパスにデフォルト設定されます。 |
| `namespace`       | 整数または文字列 | いいえ       | （非推奨）プロジェクトをインポートするネームスペースのIDまたはパス。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。代わりに、`namespace_id`または`namespace_path`を使用してください。 |
| `namespace_id`    | 整数           | いいえ       | プロジェクトをインポートするネームスペースのID。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。 |
| `namespace_path`  | 文字列            | いいえ       | プロジェクトをインポートするネームスペースのパス。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。 |
| `overwrite`       | ブール値           | いいえ       | インポート時に同じパスを持つプロジェクトを上書きするかどうか。`false`がデフォルトです。 |
| `override_params` | ハッシュ              | いいえ       | [プロジェクトAPI](projects.md)で定義されているすべてのフィールドをサポートします。 |

渡されたオーバーライドパラメータは、エクスポートファイル内で定義されたすべての値よりも優先されます。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/remote-import" \
  --data '{"url":"https://remoteobject/file?token=123123","path":"remote-project"}'
```

```json
{
  "id": 1,
  "description": null,
  "name": "remote-project",
  "name_with_namespace": "Administrator / remote-project",
  "path": "remote-project",
  "path_with_namespace": "root/remote-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [],
  "import_error": null
}
```

`Content-Length`ヘッダーは有効な数値を返す必要があります。最大ファイルサイズは10 GBです。`Content-Type`ヘッダーは`application/gzip`である必要があります。

## AWS S3バケットからプロジェクトをインポート {#import-a-project-from-an-aws-s3-bucket}

{{< history >}}

- `namespace_id`および`namespace_path`属性がGitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/511053)されました。

{{< /history >}}

指定されたAWS S3バケットに保存されているアーカイブからプロジェクトをインポートします。

```plaintext
POST /projects/remote-import-s3
```

| 属性           | タイプ              | 必須 | 説明 |
| ------------------- | ----------------- | -------- | ----------- |
| `access_key_id`     | 文字列            | はい      | [AWS S3アクセスキーID](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)。 |
| `bucket_name`       | 文字列            | はい      | ファイルが保存されている[AWS S3バケット名](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)。 |
| `file_key`          | 文字列            | はい      | ファイルを識別するための[AWS S3ファイルキー](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingObjects.html)。 |
| `path`              | 文字列            | はい      | 新しいプロジェクトのフルパス。 |
| `region`            | 文字列            | はい      | ファイルが保存されている[AWS S3リージョン名](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html#Regions)。 |
| `secret_access_key` | 文字列            | はい      | [AWS S3シークレットアクセスキー](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys)。 |
| `name`              | 文字列            | いいえ       | インポートするプロジェクトの名前。指定しない場合、プロジェクトのパスにデフォルト設定されます。 |
| `namespace`         | 整数または文字列 | いいえ       | （非推奨）プロジェクトをインポートするネームスペースのIDまたはパス。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。代わりに、`namespace_id`または`namespace_path`を使用してください。 |
| `namespace_id`      | 整数           | いいえ       | プロジェクトをインポートするネームスペースのID。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。 |
| `namespace_path`    | 文字列            | いいえ       | プロジェクトをインポートするネームスペースのパス。現在のユーザーのネームスペースにデフォルト設定されます。<br/><br/> 宛先グループでメンテナーまたはオーナーのロールが必要です。 |

渡されたオーバーライドパラメータは、エクスポートファイル内で定義されたすべての値よりも優先されます。

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/projects/remote-import-s3" \
  --header "PRIVATE-TOKEN: <your gitlab access key>" \
  --header 'Content-Type: application/json' \
  --data '{
  "name": "Sample Project",
  "path": "sample-project",
  "region": "<Your S3 region name>",
  "bucket_name": "<Your S3 bucket name>",
  "file_key": "<Your S3 file key>",
  "access_key_id": "<Your AWS access key id>",
  "secret_access_key": "<Your AWS secret access key>"
}'
```

この例では、Amazon S3に接続するモジュールを使用して、Amazon S3バケットからインポートします:

```python
import requests
from io import BytesIO

s3_file = requests.get(presigned_url)

url =  'https://gitlab.example.com/api/v4/projects/import'
files = {'file': ('file.tar.gz', BytesIO(s3_file.content))}
data = {
    "path": "example-project",
    "namespace_path": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "Sample project",
  "name_with_namespace": "Administrator / sample-project",
  "path": "sample-project",
  "path_with_namespace": "root/sample-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [],
  "import_error": null
}
```

## プロジェクトインポートのステータスを取得する {#retrieve-the-status-of-a-project-import}

指定したプロジェクトの最新のインポートステータスを取得する。

```plaintext
GET /projects/:id/import
```

| 属性 | タイプ           | 必須 | 説明                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/import"
```

ステータスは次のいずれかです:

- `none`
- `scheduled`
- `failed`
- `started`
- `finished`

ステータスが`failed`の場合、`import_error`の下にインポートエラーメッセージが含まれます。ステータスが`failed`、`started`、または`finished`の場合、`failed_relations`配列には、次のいずれかの理由でインポートに失敗したリレーションの発生が含まれる可能性があります:

- 回復不可能なエラー。
- リトライが上限に達しました。典型的な例：クエリタイムアウト。

> [!note] 
> `failed_relations`内の要素の`id`フィールドは、リレーションではなく、失敗レコードを参照します。また、`failed_relations`配列は100項目に制限されています。

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started",
  "import_type": "github",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests",
      "line_number": 0
    }
  ]
}
```

GitHubからインポートする場合、`stats`フィールドには、GitHubからすでにフェッチされたオブジェクトの数と、すでにインポートされたオブジェクトの数がリストされます:

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started",
  "import_type": "github",
  "correlation_id": "mezklWso3Za",
  "failed_relations": [
    {
      "id": 42,
      "created_at": "2020-04-02T14:48:59.526Z",
      "exception_class": "RuntimeError",
      "exception_message": "A failure occurred",
      "source": "custom error context",
      "relation_name": "merge_requests",
      "line_number": 0
    }
  ],
  "stats": {
    "fetched": {
      "diff_note": 19,
      "issue": 3,
      "label": 1,
      "note": 3,
      "pull_request": 2,
      "pull_request_merged_by": 1,
      "pull_request_review": 16
    },
    "imported": {
      "diff_note": 19,
      "issue": 3,
      "label": 1,
      "note": 3,
      "pull_request": 2,
      "pull_request_merged_by": 1,
      "pull_request_review": 16
    }
  }
}
```

## プロジェクトリソースをインポート {#import-project-resources}

{{< history >}}

- GitLab 16.11で[ベータ](../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)され、`single_relation_import`という名前の[フラグ](../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/455889)になりました。機能フラグ`single_relation_import`は削除されました。

{{< /history >}}

プロジェクトアーカイブに含まれる[プロジェクトリソース](../user/project/settings/import_export.md#project-items-that-are-exported)をインポートします。インポートするアイテムのタイプは、`relation`属性によって制御されます。以前にインポートされたアイテムをスキップします。

必要なプロジェクトエクスポートファイルは、[ローカルアーカイブからプロジェクトをインポート](#import-a-project-from-a-local-archive)で説明されているのと同じ構造とサイズ要件に準拠しています。

- 抽出されたファイルは、GitLabプロジェクトのエクスポートの構造に準拠している必要があります。
- アーカイブは、管理者によって設定された最大インポートファイルサイズを超えてはなりません。

```plaintext
POST /projects/import-relation
```

| 属性  | タイプ   | 必須 | 説明                                                                                                    |
|------------|--------|----------|----------------------------------------------------------------------------------------------------------------|
| `file`     | 文字列 | はい      | アップロードするファイル。                                                                                       |
| `path`     | 文字列 | はい      | 新しいプロジェクトの名前とパス。                                                                                 |
| `relation` | 文字列 | はい      | インポートするリレーションの名前。`issues`、`milestones`、`ci_pipelines`、または`merge_requests`のいずれかである必要があります。 |

ファイルシステムからファイルをアップロードするには、`--form`オプションを使用します。これにより、cURLは`Content-Type: multipart/form-data`ヘッダーを使用してデータを投稿します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "path=api-project" \
  --form "file=@/path/to/file" \
  --form "relation=issues" \
  --url "https://gitlab.example.com/api/v4/projects/import-relation"
```

```json
{
  "id": 9,
  "project_path": "namespace1/project1",
  "relation": "issues",
  "status": "finished"
}
```

## プロジェクトリソースインポートのステータスを取得する {#retrieve-the-status-of-a-project-resource-import}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)されました。

{{< /history >}}

指定したプロジェクトの最新のリレーションインポートのステータスを取得する。一度にスケジュールできるリレーションインポートは1つだけなので、このエンドポイントを使用して、以前のインポートが正常に完了したかどうかを確認できます。

```plaintext
GET /projects/:id/relation-imports
```

| 属性 | タイプ               | 必須 | 説明                                                                          |
| --------- |--------------------| -------- |--------------------------------------------------------------------------------------|
| `id`      | 整数または文字列  | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/18/relation-imports"
```

```json
[
  {
    "id": 1,
    "project_path": "namespace1/project1",
    "relation": "issues",
    "status": "created",
    "created_at": "2024-03-25T11:03:48.074Z",
    "updated_at": "2024-03-25T11:03:48.074Z"
  }
]
```

ステータスは次のいずれかです:

- `created`: インポートがスケジュールされましたが、まだ開始されていません。
- `started`: インポートが処理中です。
- `finished`: インポートが完了しました。
- `failed`: インポートを完了できませんでした。
