---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブアーティファクトAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[ジョブアーティファクト](../ci/jobs/job_artifacts.md)をダウンロード、保持、削除します。

## CI/CDジョブトークンで認証する {#authenticate-with-a-cicd-job-token}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

CI/CDジョブで[ジョブアーティファクト](../ci/jobs/ci_job_token.md)をダウンロードする際に、マルチプロジェクトパイプラインの[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を使用して認証できます。これは、`.gitlab-ci.yml`ファイルで定義されたCI/CDジョブでのみ使用してください。

`$CI_JOB_TOKEN`に関連付けられているジョブは、このトークンの使用時に実行されている必要があります。

以下のいずれかを使用します。

- `CI_JOB_TOKEN`定義済み変数による`job_token`パラメータ。
- `CI_JOB_TOKEN`定義済み変数による`JOB-TOKEN`ヘッダー。

詳細については、[REST API authentication](rest/authentication.md)を参照してください。

## ジョブIDでジョブアーティファクトをダウンロードする {#download-job-artifacts-by-job-id}

ジョブIDを使用して、ジョブのアーティファクトアーカイブをダウンロードします。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメータを使用します。

```plaintext
GET /projects/:id/jobs/:job_id/artifacts
```

サポートされている属性は以下のとおりです。

| 属性   | 型           | 必須 | 説明 |
| ----------- | -------------- | -------- | ----------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`    | 整数        | はい      | ジョブのID。 |
| `job_token` | 文字列         | いいえ       | マルチプロジェクトパイプライン用のCI/CDジョブトークン。PremiumおよびUltimateのみです。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)を返し、アーティファクトファイルを提供します。

リクエスト例:

```shell
curl --location --output artifacts.zip \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"
```

CI/CDジョブトークンを使用したリクエストの例:

```yaml
# Uses the job_token parameter
artifact_download:
  stage: test
  script:
    - 'curl --location --output artifacts.zip \
         --url "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN"'
```

## 参照名でジョブアーティファクトをダウンロードする {#download-job-artifacts-by-reference-name}

参照名を使用して、最新の成功したパイプラインでジョブのアーティファクトのアーカイブをダウンロードします。

最新の成功したパイプラインは、作成時刻に基づいて決定します。個々のジョブの開始時刻または終了時刻は、どのパイプラインが最新のパイプラインになるかに影響しません。

[親パイプラインと子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)の場合、アーティファクトは親から子への階層順に検索されます。親パイプラインと子のパイプラインの両方に同じ名前のジョブがある場合、親パイプラインのアーティファクトが返されます。

前提要件:

- `success`ステータスで完了したパイプラインが必要です。
- パイプラインに手動ジョブが含まれている場合は、これらのジョブが次のいずれかである必要があります。
  - 正常に完了している。
  - `allow_failure: true`が設定されている。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメータを使用します。

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

サポートされている属性は以下のとおりです。

| 属性   | 型           | 必須 | 説明 |
| ----------- | -------------- | -------- | ----------- |
| `id`        | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job`       | 文字列         | はい      | ジョブの名前。 |
| `ref_name`  | 文字列         | はい      | リポジトリ内のブランチ名またはタグ名。参照またはSHA参照はサポートされていません。マージリクエストパイプラインの場合は、ソースブランチ名の代わりに`ref/merge-requests/:iid/head`を使用します。 |
| `job_token` | 文字列         | いいえ       | マルチプロジェクトパイプライン用のCI/CDジョブトークン。PremiumおよびUltimateのみです。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)を返し、アーティファクトファイルを提供します。

リクエスト例:

```shell
curl --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test"
```

CI/CDジョブトークンを使用したリクエストの例:

```yaml
# Uses the job_token parameter
artifact_download:
  stage: test
  script:
    - 'curl --location --output artifacts.zip \
         --url "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"'
```

## ジョブIDで1つのアーティファクトファイルをダウンロードする {#download-a-single-artifact-file-by-job-id}

ジョブIDを使用してジョブのアーティファクトから1つのファイルをダウンロードします。ファイルはアーカイブから抽出され、クライアントにストリーミングされます。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメータを使用します。

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

サポートされている属性は以下のとおりです。

| 属性       | 型           | 必須 | 説明 |
| --------------- | -------------- | -------- | ----------- |
| `artifact_path` | 文字列         | はい      | アーティファクトアーカイブ内のファイルのパス。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`        | 整数        | はい      | 一意のジョブ識別子。 |
| `job_token`     | 文字列         | いいえ       | マルチプロジェクトパイプライン用のCI/CDジョブトークン。PremiumおよびUltimateのみです。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)を返し、単一のアーティファクトファイルを送信します。

リクエスト例:

```shell
curl --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

## 参照名で単一のアーティファクトファイルをダウンロードする {#download-a-single-artifact-file-by-reference-name}

参照名を使用して、最新の成功したパイプラインでジョブのアーティファクトから1つのファイルをダウンロードします。ファイルはアーカイブから抽出され、`plain/text`コンテンツタイプでクライアントにストリーミングされます。

[親パイプラインと子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)の場合、アーティファクトは親から子への階層順に検索されます。親パイプラインと子のパイプラインの両方に同じ名前のジョブがある場合、親パイプラインのアーティファクトが返されます。

アーティファクトファイルは、[CSVエクスポート](../user/application_security/vulnerability_report/_index.md#exporting)の場合よりも詳細な情報を提供します。

前提要件:

- `success`ステータスで完了したパイプラインが必要です。
- パイプラインに手動ジョブが含まれている場合は、これらのジョブが次のいずれかである必要があります。
  - 正常に完了している。
  - `allow_failure: true`が設定されている。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメータを使用します。

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name
```

サポートされている属性は以下のとおりです。

| 属性       | 型           | 必須 | 説明 |
| --------------- | -------------- | -------- | ----------- |
| `artifact_path` | 文字列         | はい      | アーティファクトアーカイブ内のファイルのパス。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job`           | 文字列         | はい      | ジョブの名前。 |
| `ref_name`      | 文字列         | はい      | リポジトリ内のブランチ名またはタグ名。`HEAD`参照と`SHA`参照はサポートされていません。マージリクエストパイプラインの場合は、ソースブランチ名の代わりに`ref/merge-requests/:iid/head`を使用します。 |
| `job_token`     | 文字列         | いいえ       | マルチプロジェクトパイプライン用のCI/CDジョブトークン。PremiumおよびUltimateのみです。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)を返し、単一のアーティファクトファイルを送信します。

リクエスト例:

```shell
curl --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf"
```

## ジョブのアーティファクトを保持する {#keep-job-artifacts}

ジョブのアーティファクトが有効期限に達したときに自動的に削除されないようにします。

```plaintext
POST /projects/:id/jobs/:job_id/artifacts/keep
```

サポートされている属性は以下のとおりです。

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |

成功した場合は、[`200`](rest/troubleshooting.md#status-codes)とジョブの詳細を返します。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts/keep"
```

応答の例:

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

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

```plaintext
DELETE /projects/:id/jobs/:job_id/artifacts
```

サポートされている属性は以下のとおりです。

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

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

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

```plaintext
DELETE /projects/:id/artifacts
```

サポートされている属性は以下のとおりです。

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

成功すると、[`202 Accepted`](rest/troubleshooting.md#status-codes)を返します。

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

マージリクエストパイプラインのジョブアーティファクトをダウンロードするには、ブランチ名の代わりに`ref_name`として`ref/merge-requests/:iid/head`を使用します。`:iid`はマージリクエストIDです。

たとえば、マージリクエスト`!123`の場合は以下のようになります。

```shell
curl --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/ref/merge-requests/123/head/raw/file.txt?job=test"
```

### `artifacts:reports`ファイルのダウンロード {#downloading-artifactsreports-files}

ジョブアーティファクトAPIを使用してレポートをダウンロードしようとすると、`404 Not Found`エラーが発生する場合があります。

この問題は、デフォルトでは[レポート](../ci/yaml/_index.md#artifactsreports)をダウンロードできないために発生します。

レポートをダウンロードできるようにするには、そのファイル名または`gl-*-report.json`を[`artifacts:paths`](../ci/yaml/_index.md#artifactspaths)に追加します。
