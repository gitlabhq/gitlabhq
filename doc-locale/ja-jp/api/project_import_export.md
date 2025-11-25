---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトのインポート/エクスポートAPI
description: "REST APIを使用してプロジェクトをインポートおよびエクスポートします。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して[プロジェクトを移行する](../user/project/settings/import_export.md)。最初に[グループのインポート/エクスポートAPI](group_import_export.md)で親グループ構造を移行すると、プロジェクトイシューとグループエピック間の接続など、グループレベルの関係を維持できます。

このAPIの使用後、プロジェクトのCI/CD変数を保持するために、[プロジェクトレベルのCI/CD変数API](project_level_variables.md)を使用することもできます。

一連のDockerのプルとプッシュを介して、[コンテナレジストリ](../user/packages/container_registry/_index.md)を移行する必要があります。ビルドアーティファクトを取得するために、CI/CDパイプラインを再実行します。

## 前提要件 {#prerequisites}

プロジェクトのインポート/エクスポートAPIの前提条件については、以下を参照してください:

- [プロジェクトのエクスポート](../user/project/settings/import_export.md#export-a-project-and-its-data)の前提条件。
- [プロジェクトのインポート](../user/project/settings/import_export.md#import-a-project-and-its-data)の前提条件。

## エクスポートをスケジュールする {#schedule-an-export}

新しいエクスポートを開始します。

このエンドポイントは、`upload`ハッシュパラメータも受け入れます。これには、エクスポートされたプロジェクトをWebサーバーまたはS3互換プラットフォームにアップロードするために必要なすべての情報が含まれています。エクスポートの場合、GitLab:

- 最終サーバーへのバイナリデータファイルアップロードのみをサポートします。
- アップロードリクエストで`Content-Type: application/gzip`ヘッダーを送信します。事前署名付きURLに、署名の一部としてこれが含まれていることを確認してください。
- プロジェクトのエクスポートプロセスを完了するのに時間がかかる場合があります。アップロードURLの有効期限が短くなく、エクスポートプロセス全体で使用できることを確認してください。
- 管理者は、最大エクスポートファイルサイズを変更できます。デフォルトでは、最大値は無制限です（`0`）。これを変更するには、次のいずれかを使用して`max_export_size`を編集します:
  - [GitLab UI](../administration/settings/import_and_export_settings.md)。
  - [Application settings API](settings.md#update-application-settings)を使用します。
- GitLab.comの最大インポートファイルサイズの固定制限があります。詳細については、[アカウントと制限設定](../user/gitlab_com/_index.md#account-and-limit-settings)を参照してください。

`upload`パラメータが存在する場合、`upload[url]`パラメータは必須です。

Amazon S3へのアップロードについては、`upload[url]`を生成するための[オブジェクトアップロード用の事前署名付きURLの生成](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)ドキュメントスクリプトを参照してください。[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/430277)により、Amazon S3に最大ファイルサイズ5GBのファイルしかアップロードできません。

```plaintext
POST /projects/:id/export
```

| 属性             | 型              | 必須 | 説明 |
|-----------------------|-------------------|----------|-------------|
| `id`                  | 整数または文字列 | はい      | プロジェクトの[IDまたはURLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `upload[url]`         | 文字列            | はい      | プロジェクトをアップロードするURL。 |
| `description`         | 文字列            | いいえ       | プロジェクトの説明をオーバーライドします。 |
| `upload`              | ハッシュ              | いいえ       | エクスポートされたプロジェクトをWebサーバーにアップロードするための情報を含むハッシュ。 |
| `upload[http_method]` | 文字列            | いいえ       | エクスポートされたプロジェクトをアップロードするHTTPメソッド。`PUT`メソッドと`POST`メソッドのみが許可されています。デフォルトは`PUT`です。 |

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

## エクスポートステータス {#export-status}

エクスポートのステータスを取得する。

```plaintext
GET /projects/:id/export
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/export"
```

ステータスは次のいずれかになります:

- `none`: エクスポートは、キューに入れられず、開始、終了、または再生成されていません。
- `queued`: エクスポートのリクエストが受信され、処理されるキューに入っています。
- `started`: エクスポートプロセスが開始され、進行中です。これには以下が含まれます:
  - エクスポートのプロセス。
  - 結果ファイルに対して実行されるアクション。たとえば、ユーザーにファイルをダウンロードするように通知するメールを送信したり、エクスポートされたファイルをWebサーバーにアップロードしたりします。
- `finished`: エクスポートプロセスが完了し、ユーザーに通知された後。
- `regeneration_in_progress`: エクスポートファイルをダウンロードでき、新しいエクスポートを生成するリクエストが処理中です。

エクスポートが完了すると、`_links`のみが表示されます。

`created_at`は、プロジェクトの作成タイムスタンプであり、エクスポートの開始時刻ではありません。

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

## エクスポートのダウンロード {#export-download}

完了したエクスポートをダウンロードします。

```plaintext
GET /projects/:id/export/download
```

| 属性 | 型              | 必須 | 説明                              |
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

## ファイルをインポートする {#import-a-file}

{{< history >}}

- デベロッパーロールの代わりにメンテナーロールの要件がGitLab 16.0で導入されました。

{{< /history >}}

```plaintext
POST /projects/import
```

| 属性         | 型              | 必須 | 説明 |
|-------------------|-------------------|----------|-------------|
| `file`            | 文字列            | はい      | アップロードするファイル。 |
| `path`            | 文字列            | はい      | 新しいプロジェクトの名前とパス。 |
| `name`            | 文字列            | いいえ       | インポートされるプロジェクトの名前。指定されていない場合、プロジェクトのパスがデフォルトになります。 |
| `namespace`       | 整数または文字列 | いいえ       | プロジェクトのインポート先のネームスペースのIDまたはパス。デフォルトでは、現在のユーザーのネームスペースになります。<br/><br/> インポートするには、宛先グループのメンテナーロールが少なくとも必要です。 |
| `override_params` | ハッシュ              | いいえ       | [Project API](projects.md)で定義されているすべてのファイルをサポートします。 |
| `overwrite`       | ブール値           | いいえ       | 同じパスのプロジェクトがある場合、インポートはそれを上書きします。`false`がデフォルトです。 |

渡されたオーバーライドパラメータは、エクスポートファイル内で定義されたすべての値よりも優先されます。

ファイルシステムからアップロードするには、`--form`引数を使用します。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "path=api-project" \
  --form "file=@/path/to/file" \
  --url "https://gitlab.example.com/api/v4/projects/import"
```

cURLは、リモートサーバーからのファイルの投稿をサポートしていません。この例では、Pythonの`open`メソッドを使用してプロジェクトをインポートします:

```python
import requests

url =  'https://gitlab.example.com/api/v4/projects/import'
files = { "file": open("project_export.tar.gz", "rb") }
data = {
    "path": "example-project",
    "namespace": "example-group"
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

{{< alert type="note" >}}

最大インポートファイルサイズは、管理者が設定できます。デフォルトでは、`0`（無制限）に設定されています。管理者は、最大インポートファイルサイズを変更できます。これを行うには、[Application設定API](settings.md#update-application-settings)または[**管理者**エリア](../administration/settings/account_and_limit_settings.md)の`max_import_size`オプションを使用します。

{{< /alert >}}

## リモートオブジェクトストレージからファイルをインポートする {#import-a-file-from-a-remote-object-storage}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能を利用できます。機能を非表示にするには、管理者は`import_project_from_remote_file`という名前の[機能フラグを無効に](../administration/feature_flags/_index.md)できます。GitLab.comおよびGitLab Dedicatedでは、この機能を使用できます。

{{< /alert >}}

```plaintext
POST /projects/remote-import
```

| 属性         | 型              | 必須 | 説明                              |
| ----------------- | ----------------- | -------- | ---------------------------------------- |
| `path`            | 文字列            | はい      | 新しいプロジェクトの名前とパス。 |
| `url`             | 文字列            | はい      | インポートするファイルのURL。 |
| `name`            | 文字列            | いいえ       | インポートするプロジェクトの名前。指定されていない場合、プロジェクトのパスがデフォルトになります。 |
| `namespace`       | 整数または文字列 | いいえ       | プロジェクトのインポート先のネームスペースのIDまたはパス。デフォルトでは、現在のユーザーのネームスペースになります。 |
| `overwrite`       | ブール値           | いいえ       | インポート時に同じパスを持つプロジェクトを上書きするかどうか。`false`がデフォルトです。 |
| `override_params` | ハッシュ              | いいえ       | [Project API](projects.md)で定義されているすべてのファイルをサポートします。 |

渡されたオーバーライドパラメータは、エクスポートファイルで定義されたすべての値よりも優先されます。

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

`Content-Length`ヘッダーは、有効な数値を返す必要があります。最大ファイルサイズは10GBです。`Content-Type`ヘッダーは`application/gzip`である必要があります。

## 単一の関係をインポートする {#import-a-single-relation}

{{< history >}}

- `single_relation_import`という[フラグ](../administration/feature_flags/_index.md)を使用して、GitLab 16.11で[ベータ](../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)されました。デフォルトでは無効になっています。
- GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/455889)になりました。機能フラグ`single_relation_import`は削除されました。

{{< /history >}}

このエンドポイントは、プロジェクトエクスポートアーカイブと名前付きの関係（イシュー、マージリクエスト、パイプライン、またはマイルストーン）を受け入れ、その関係を再度インポートし、すでにインポートされているアイテムをスキップします。

必要なプロジェクトのエクスポートファイルは、[ファイルをインポートする](#import-a-file)で説明されているのと同じ構造とサイズの要件に準拠しています。

- 抽出されたファイルは、GitLabプロジェクトのエクスポートの構造に準拠している必要があります。
- アーカイブは、管理者が構成した最大インポートファイルサイズを超えてはなりません。

```plaintext
POST /projects/import-relation
```

| 属性  | 型   | 必須 | 説明                                                                                                    |
|------------|--------|----------|----------------------------------------------------------------------------------------------------------------|
| `file`     | 文字列 | はい      | アップロードするファイル。                                                                                       |
| `path`     | 文字列 | はい      | 新しいプロジェクトの名前とパス。                                                                                 |
| `relation` | 文字列 | はい      | インポートする関係の名前。`issues`、`milestones`、`ci_pipelines`、または`merge_requests`のいずれかである必要があります。 |

ファイルシステムからファイルをアップロードするには、`--form`オプションを使用します。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを投稿します。`file=`パラメータは、ファイルシステムのファイルを指しており、先頭に`@`を付ける必要があります。例: 

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

## 関係インポートステータスを確認する {#check-relation-import-statuses}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)されました。

{{< /history >}}

このエンドポイントは、プロジェクトに関連付けられている関係インポートのステータスをフェッチします。一度にスケジュールできる関係インポートは1つだけであるため、このエンドポイントを使用して、以前のインポートが正常に完了したかどうかを確認できます。

```plaintext
GET /projects/:id/relation-imports
```

| 属性 | 型               | 必須 | 説明                                                                          |
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

ステータスは次のいずれかになります:

- `created`: インポートがスケジュールされましたが、開始されていません。
- `started`: インポートが処理されています。
- `finished`: インポートが完了しました。
- `failed`: インポートを完了できませんでした。

## AWS S3からファイルをインポートする {#import-a-file-from-aws-s3}

{{< history >}}

- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/350571)になりました。機能フラグ`import_project_from_remote_file_s3`は削除されました。

{{< /history >}}

```plaintext
POST /projects/remote-import-s3
```

| 属性           | 型              | 必須 | 説明 |
| ------------------- | ----------------- | -------- | ----------- |
| `access_key_id`     | 文字列            | はい      | [AWS S3アクセスキーID](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)。 |
| `bucket_name`       | 文字列            | はい      | [ファイルが格納されているAWS S3バケット名](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)。 |
| `file_key`          | 文字列            | はい      | [ファイルを識別するためのAWS S3ファイルキー](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingObjects.html)。 |
| `path`              | 文字列            | はい      | 新しいプロジェクトのフルパス。 |
| `region`            | 文字列            | はい      | [ファイルが格納されているAWS S3リージョン名](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html#Regions)。 |
| `secret_access_key` | 文字列            | はい      | [AWS S3シークレットアクセスキー](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys)。 |
| `name`              | 文字列            | いいえ       | インポートするプロジェクトの名前。指定されていない場合、プロジェクトのパスがデフォルトになります。 |
| `namespace`         | 整数または文字列 | いいえ       | プロジェクトのインポート先のネームスペースのIDまたはパス。デフォルトでは、現在のユーザーのネームスペースになります。 |

渡されたオーバーライドパラメータは、エクスポートファイルで定義されたすべての値よりも優先されます。

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
    "namespace": "example-group"
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

## インポートステータス {#import-status}

インポートのステータスを取得。

```plaintext
GET /projects/:id/import
```

| 属性 | 型           | 必須 | 説明                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/import"
```

ステータスは次のいずれかになります:

- `none`
- `scheduled`
- `failed`
- `started`
- `finished`

ステータスが`failed`の場合、`import_error`の下にインポートエラーメッセージが含まれます。ステータスが`failed`、`started`、または`finished`の場合、次のいずれかの理由でインポートに失敗した関係の発生が`failed_relations`配列に入力される可能性があります:

- 回復不能なエラー。
- 再試行がなくなりました。一般的な例：クエリのタイムアウト。

{{< alert type="note" >}}

`failed_relations`の要素の`id`フィールドは、関係ではなく、失敗レコードを参照します。

{{< /alert >}}

{{< alert type="note" >}}

`failed_relations`配列は100アイテムに制限されています。{{< /alert >}}

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

## 関連トピック {#related-topics}

- [ファイルエクスポートを使用したプロジェクトの移行](../user/project/settings/import_export.md)。
- [プロジェクトのインポートとエクスポートのRakeタスク](../administration/raketasks/project_import_export.md)。
- [グループのインポート/エクスポートAPI](group_import_export.md)
