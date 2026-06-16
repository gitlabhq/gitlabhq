---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ジョブアーティファクトAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[ジョブアーティファクト](../ci/jobs/job_artifacts.md)をダウンロード、保持、削除します。

## ジョブIDでジョブアーティファクトをダウンロードする {#download-job-artifacts-by-job-id}

ジョブIDを使用して、ジョブのアーティファクトアーカイブをダウンロードします。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメータを使用します。

```plaintext
GET /projects/:id/jobs/:job_id/artifacts
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`    | 整数           | はい      | ジョブのID。 |
| `job_token` | 文字列            | いいえ       | マルチプロジェクトパイプライン用のCI/CDジョブトークン。PremiumおよびUltimateのみです。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)を返し、アーティファクトファイルを提供します。

リクエスト例: 

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts" \
  --output artifacts.zip
```

CI/CDジョブトークンを使用したリクエストの例:

```yaml
# Uses the job_token parameter
artifact_download:
  stage: test
  script:
    - 'curl --request GET \
         --location \
         --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN" \
         --output artifacts.zip'
```

## 参照名でジョブアーティファクトをダウンロードする {#download-job-artifacts-by-reference-name}

{{< history >}}

- `search_recent_successful_pipelines`属性は、GitLab 18.7で[フラグ](../administration/feature_flags/_index.md) `ci_search_recent_successful_pipelines`として[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/515864)されました。デフォルトでは無効になっています。
- 機能フラグ`ci_search_recent_successful_pipelines`はGitLab 18.10で削除されました。

{{< /history >}}

最新の正常なパイプラインから、参照名を使用してジョブのアーティファクトアーカイブをダウンロードします。`search_recent_successful_pipelines=true`の場合、検索には指定された参照の最新の正常なパイプラインが最大100件含まれます。

最新の成功したパイプラインは、作成時刻に基づいて決定します。個々のジョブの開始時刻または終了時刻は、どのパイプラインが最新のパイプラインになるかに影響しません。

[親パイプラインと子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)の場合、アーティファクトは親から子への階層順に検索されます。親パイプラインと子のパイプラインの両方に同じ名前のジョブがある場合、親パイプラインのアーティファクトが返されます。

前提条件: 

- `success`ステータスで完了したパイプラインが必要です。
- パイプラインに手動ジョブが含まれている場合は、これらのジョブが次のいずれかである必要があります。
  - 正常に完了している。
  - `allow_failure: true`が設定されている。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメータを使用します。

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job`       | 文字列            | はい      | ジョブの名前。 |
| `ref_name`  | 文字列            | はい      | リポジトリ内のブランチ名またはタグ名。参照またはSHA参照はサポートされていません。マージリクエストパイプラインの場合は、ソースブランチ名の代わりに`refs/merge-requests/:iid/head`を使用します。 |
| `job_token` | 文字列            | いいえ       | マルチプロジェクトパイプライン用のCI/CDジョブトークン。PremiumおよびUltimateのみです。 |
| `search_recent_successful_pipelines` | ブール値 | いいえ | 最新のパイプラインだけでなく、最近の正常なパイプライン全体を検索します。`false`がデフォルトです。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)を返し、アーティファクトファイルを提供します。

ジョブまたはアーティファクトが見つからない場合、[`404`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test"
```

CI/CDジョブトークンを使用したリクエストの例:

```yaml
# Uses the job_token parameter
artifact_download:
  stage: test
  script:
    - 'curl --request GET \
         --location \
         --url "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN" \
         --output artifacts.zip'
```

最近のパイプライン検索を使用したリクエストの例:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&search_recent_successful_pipelines=true"
```

## ジョブIDで1つのアーティファクトファイルをダウンロードする {#download-a-single-artifact-file-by-job-id}

ジョブIDを使用して、ジョブのアーティファクトから単一ファイルをダウンロードします。ファイルはアーカイブから抽出され、クライアントにストリーミングされます。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメータを使用します。

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
| --------------- | ----------------- | -------- | ----------- |
| `artifact_path` | 文字列            | はい      | アーティファクトアーカイブ内のファイルのパス。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`        | 整数           | はい      | 一意のジョブ識別子。 |
| `job_token`     | 文字列            | いいえ       | マルチプロジェクトパイプライン用のCI/CDジョブトークン。PremiumおよびUltimateのみです。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)を返し、単一のアーティファクトファイルを送信します。

リクエスト例: 

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

## アーティファクトアーカイブ内のすべてのファイルをリスト表示します {#list-all-files-in-the-artifacts-archive}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/31448)されました。

{{< /history >}}

指定したジョブのアーティファクトアーカイブ内のすべてのファイルとディレクトリをリスト表示します。この操作では、アーカイブ全体を抽出せずにアーティファクトメタデータを読み取るため、大規模なアーカイブの閲覧に効率的です。

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/tree
```

サポートされている属性は以下のとおりです: 

| 属性   | 型              | 必須 | 説明 |
| ----------- | ----------------- | -------- | ----------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`    | 整数           | はい      | ジョブのID。 |
| `path`      | 文字列            | いいえ       | アーティファクトアーカイブ内で参照するパス。ルートディレクトリにデフォルト設定されます。 |
| `recursive` | ブール値           | いいえ       | `true`の場合、すべてのエントリを再帰的に返します。デフォルトは`false`です。 |
| `job_token` | 文字列            | いいえ       | 複数プロジェクトのパイプラインをトリガーするために使用されるCI/CDジョブトークン。PremiumおよびUltimateのみです。 |

このエンドポイントは[ページネーション](rest/_index.md#pagination)をサポートしています。

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型    | 説明 |
|-----------|---------|-------------|
| `name`    | 文字列  | ファイル名またはディレクトリ名。 |
| `path`    | 文字列  | アーティファクトアーカイブ内の完全なパス。ディレクトリには末尾にスラッシュが含まれます。 |
| `type`    | 文字列  | エントリのタイプ。指定可能な値: `file`、`directory`。 |
| `size`    | 整数 | ファイルのバイトサイズ。ファイルの場合にのみ表示されます。 |
| `mode`    | 文字列  | Unixファイルの8進形式モード。例えば、ファイルの場合は`100644`、ディレクトリの場合は`040755`です。 |

ジョブ、アーティファクト、アーティファクトメタデータ、または指定されたパスが見つからない場合、[`404`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree"
```

レスポンス例: 

```json
[
  {
    "name": "ci_build_artifacts.zip",
    "path": "ci_build_artifacts.zip",
    "type": "file",
    "size": 1024,
    "mode": "100644"
  },
  {
    "name": "other_artifacts_0.1.2",
    "path": "other_artifacts_0.1.2/",
    "type": "directory",
    "mode": "040755"
  }
]
```

サブディレクトリを閲覧するためのリクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?path=coverage/reports"
```

再帰的リスト表示のためのリクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?recursive=true"
```

CI/CDジョブトークンを使用したリクエストの例:

```yaml
# Uses the job_token parameter
list_artifacts:
  stage: test
  script:
    - 'curl --request GET \
         --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts/tree?job_token=$CI_JOB_TOKEN"'
```

## 参照名で単一のアーティファクトファイルをダウンロードする {#download-a-single-artifact-file-by-reference-name}

{{< history >}}

- `search_recent_successful_pipelines`属性は、GitLab 18.9で[フラグ](../administration/feature_flags/_index.md) `ci_search_recent_successful_pipelines`として[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/515864)されました。デフォルトでは無効になっています。
- 機能フラグ`ci_search_recent_successful_pipelines`はGitLab 18.10で削除されました。

{{< /history >}}

参照名を使用して、最新の成功したパイプラインでジョブのアーティファクトから1つのファイルをダウンロードします。ファイルはアーカイブから抽出され、`plain/text`コンテンツタイプでクライアントにストリーミングされます。`search_recent_successful_pipelines=true`の場合、検索には指定された参照の最新の正常なパイプラインが最大100件含まれます。

[親パイプラインと子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)の場合、アーティファクトは親から子への階層順に検索されます。親パイプラインと子のパイプラインの両方に同じ名前のジョブがある場合、親パイプラインのアーティファクトが返されます。

アーティファクトファイルは、[CSVエクスポート](../user/application_security/vulnerability_report/_index.md#exporting)の場合よりも詳細な情報を提供します。

前提条件: 

- `success`ステータスで完了したパイプラインが必要です。
- パイプラインに手動ジョブが含まれている場合は、これらのジョブが次のいずれかである必要があります。
  - 正常に完了している。
  - `allow_failure: true`が設定されている。
- 最近の正常なパイプライン全体を検索するには、`ci_search_recent_successful_pipelines`機能フラグをプロジェクトで有効にする必要があります。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメータを使用します。

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
| --------------- | ----------------- | -------- | ----------- |
| `artifact_path` | 文字列            | はい      | アーティファクトアーカイブ内のファイルのパス。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job`           | 文字列            | はい      | ジョブの名前。 |
| `ref_name`      | 文字列            | はい      | リポジトリ内のブランチ名またはタグ名。`HEAD`参照と`SHA`参照はサポートされていません。マージリクエストパイプラインの場合は、ソースブランチ名の代わりに`refs/merge-requests/:iid/head`を使用します。 |
| `job_token`     | 文字列            | いいえ       | マルチプロジェクトパイプライン用のCI/CDジョブトークン。PremiumおよびUltimateのみです。 |
| `search_recent_successful_pipelines` | ブール値 | いいえ | 最新のパイプラインだけでなく、最近の正常なパイプライン全体を検索します。`false`がデフォルトです。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)を返し、単一のアーティファクトファイルを送信します。

ジョブまたはアーティファクトファイルが見つからない場合、[`404`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf"
```

最近のパイプライン検索を使用したリクエストの例:

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf&search_recent_successful_pipelines=true"
```

## ジョブのアーティファクトを保持する {#keep-job-artifacts}

ジョブのアーティファクトが有効期限に達したときに自動的に削除されないようにします。

```plaintext
POST /projects/:id/jobs/:job_id/artifacts/keep
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数           | はい      | ジョブのID。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)とジョブの詳細を返します。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts/keep"
```

レスポンス例: 

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "allow_failure": false,
  "download_url": null,
  "id": 42,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "duration": 97.0,
  "status": "failed",
  "failure_reason": "script_failure",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## ジョブアーティファクトを削除する {#delete-job-artifacts}

特定ジョブに関連付けられているすべてのアーティファクトを削除します。アーティファクトは削除されると復元できません。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

```plaintext
DELETE /projects/:id/jobs/:job_id/artifacts
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数           | はい      | ジョブのID。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts"
```

## プロジェクト内のすべてのジョブアーティファクトを削除する {#delete-all-job-artifacts-in-a-project}

プロジェクト内で削除可能なすべてのジョブアーティファクトを削除します。アーティファクトは削除されると復元できません。

デフォルトでは、[各refの最新の成功したパイプライン](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)のアーティファクトは削除されません。

このエンドポイントへのリクエストは、削除できるすべてのジョブアーティファクトの有効期限を現在時刻に設定します。その後、有効期限切れのジョブアーティファクトの標準クリーンアップの一環として、ファイルがシステムから削除されます。ジョブログが削除されることはありません。

標準クリーンアップはスケジュールに従って非同期的に行われるため、アーティファクトが削除されるまでに少し時間がかかることがあります。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

```plaintext
DELETE /projects/:id/artifacts
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功した場合、[`202 Accepted`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/artifacts"
```

## トラブルシューティング {#troubleshooting}

### マージリクエストパイプラインでブランチ名を使用する {#using-branch-names-with-merge-request-pipelines}

`ref_name`としてブランチ名を使用してjob artifactsをダウンロードしようとすると、`404 Not Found`エラーが発生する可能性があります。

この問題は、マージリクエストパイプラインが、ブランチパイプラインとは異なる参照形式を使用するために発生します。マージリクエストパイプラインは、ソースブランチに直接ではなく、`refs/merge-requests/:iid/head`上で実行されます。

マージリクエストパイプラインのジョブアーティファクトをダウンロードするには、ブランチ名の代わりに`ref_name`として`refs/merge-requests/:iid/head`を使用します。`:iid`はマージリクエストIDです。マージリクエストのパイプラインでは、IDは変数`$CI_MERGE_REQUEST_IID`から、完全な`ref_name`は変数`$CI_MERGE_REQUEST_REF_PATH`から利用できます。

たとえば、マージリクエスト`!123`の場合は以下のようになります。

```shell
curl --request GET \
  --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/refs/merge-requests/123/head/raw/file.txt?job=test"
```

### `artifacts:reports`ファイルのダウンロード {#downloading-artifactsreports-files}

ジョブアーティファクトAPIを使用してレポートをダウンロードしようとすると、`404 Not Found`エラーが発生する場合があります。

この問題は、デフォルトでは[レポート](../ci/yaml/_index.md#artifactsreports)をダウンロードできないために発生します。

レポートをダウンロードできるようにするには、そのファイル名または`gl-*-report.json`を[`artifacts:paths`](../ci/yaml/_index.md#artifactspaths)に追加します。
