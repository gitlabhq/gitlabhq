---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブアーティファクトAPI
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ジョブアーティファクトAPIを使用して、ジョブアーティファクトをダウンロードまたは削除します。

PremiumおよびUltimateプランでは[CI/CDジョブトークン](../ci/jobs/job_artifacts.md#with-a-cicd-job-token)による認証を利用できます。

## ジョブアーティファクトを取得する

{{< history >}}

- アーティファクトダウンロードAPIでの`CI_JOB_TOKEN`の使用は、[GitLab Premium](https://about.gitlab.com/pricing/) 9.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/2346)されました。

{{< /history >}}

プロジェクトからジョブのアーティファクトのzipアーカイブを取得します。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメーターを使用します。

```plaintext
GET /projects/:id/jobs/:job_id/artifacts
```

| 属性                     | 型           | 必須 | 説明 |
|-------------------------------|----------------|----------|-------------|
| `id`                          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`                      | 整数        | はい      | ジョブのID。 |
| `job_token`                   | 文字列         | いいえ       | マルチプロジェクトパイプラインの[トリガー](../ci/jobs/job_artifacts.md#with-a-cicd-job-token)で使用します。これは、`.gitlab-ci.yml`ファイルで定義されたCI/CDジョブでのみ実行する必要があります。値は常に`$CI_JOB_TOKEN`です。`$CI_JOB_TOKEN`に関連付けられているジョブは、このトークンの使用時に実行されている必要があります。PremiumおよびUltimateのみ。 |

`PRIVATE-TOKEN`ヘッダーを使用したリクエストの例:

```shell
curl --location --output artifacts.zip --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"
```

PremiumおよびUltimateプランでは、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を使用してCI/CDジョブでこのエンドポイントで認証できます。

次のいずれかを使用します。

- GitLabが提供する定義済みの`CI_JOB_TOKEN`変数が指定された`job_token`属性。たとえば、次のジョブはIDが`42`のジョブのアーティファクトをダウンロードします。

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN"'
  ```

- GitLabが提供する定義済みの`CI_JOB_TOKEN`変数が指定された`JOB-TOKEN`ヘッダー。たとえば、次のジョブはIDが`42`のジョブのアーティファクトをダウンロードします。コマンドにコロン（`:`）が含まれているため、このコマンドは単一引用符で囲まれています。

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"'
  ```

返される可能性がある応答ステータスコードは次のとおりです。

| ステータス | 説明 |
|--------|-------------|
| 200    | アーティファクトファイルを提供します。 |
| 404    | ビルドが見つからないか、アーティファクトがないか、またはすべてのアーティファクトがレポートです。 |

## アーティファクトアーカイブをダウンロードする

{{< history >}}

- アーティファクトダウンロードAPIでの`CI_JOB_TOKEN`の使用は、[GitLab Premium](https://about.gitlab.com/pricing/) 9.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/2346)されました。

{{< /history >}}

参照名を使用して、最新の**成功**したパイプラインでジョブのアーティファクトのzipアーカイブをダウンロードします。このエンドポイントは[ジョブのアーティファクトの取得](#get-job-artifacts)と同じですが、ジョブのIDの代わりに名前を使用します。

最新の成功したパイプラインは、作成時刻に基づいて決定します。個々のジョブの開始時刻または終了時刻は、どのパイプラインが最新のパイプラインになるかに影響しません。

[親パイプラインと子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)の場合、アーティファクトは親から子への階層順に検索されます。親パイプラインと子のパイプラインの両方に同じ名前のジョブがある場合、親パイプラインのアーティファクトが返されます。

前提要件:

- `success`ステータスで完了したパイプラインが必要です。
- パイプラインに手動ジョブが含まれている場合は、これらのジョブが次のいずれかである必要があります。
  - 正常に完了している。
  - `allow_failure: true`が設定されている。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメーターを使用します。

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

パラメーター

| 属性                     | 型           | 必須 | 説明 |
|-------------------------------|----------------|----------|-------------|
| `id`                          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job`                         | 文字列         | はい      | ジョブの名前。 |
| `ref_name`                    | 文字列         | はい      | リポジトリ内のブランチ名またはタグ名。HEAD参照またはSHA参照はサポートされていません。 |
| `job_token`                   | 文字列         | いいえ       | マルチプロジェクトパイプラインの[トリガー](../ci/jobs/job_artifacts.md#with-a-cicd-job-token)で使用します。これは、`.gitlab-ci.yml`ファイルで定義されたCI/CDジョブでのみ実行する必要があります。値は常に`$CI_JOB_TOKEN`です。`$CI_JOB_TOKEN`に関連付けられているジョブは、このトークンの使用時に実行されている必要があります。PremiumおよびUltimateのみ。 |

`PRIVATE-TOKEN`ヘッダーを使用したリクエストの例:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test"
```

PremiumおよびUltimateプランでは、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を使用してCI/CDジョブでこのエンドポイントで認証できます。

次のいずれかを使用します。

- GitLabが提供する定義済みの`CI_JOB_TOKEN`変数が指定された`job_token`属性。たとえば、次のジョブは`main`ブランチの`test`ジョブのアーティファクトをダウンロードします。

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"'
  ```

- GitLabが提供する定義済みの`CI_JOB_TOKEN`変数が指定された`JOB-TOKEN`ヘッダー。たとえば、次のジョブは`main`ブランチの`test`ジョブのアーティファクトをダウンロードします。コマンドにコロン（`:`）が含まれているため、このコマンドは単一引用符で囲まれています。

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test"'
  ```

返される可能性がある応答ステータスコードは次のとおりです。

| ステータス | 説明 |
|--------|-------------|
| 200    | アーティファクトファイルを提供します。 |
| 404    | ビルドが見つからないか、アーティファクトがないか、またはすべてのアーティファクトがレポートです。 |

## ジョブIDで1つのアーティファクトファイルをダウンロードする

ジョブIDを使用してジョブのzip圧縮アーティファクトから1つのファイルをダウンロードします。ファイルはアーカイブから抽出され、クライアントにストリーミングされます。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメーターを使用します。

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

パラメーター

| 属性                     | 型           | 必須 | 説明 |
|-------------------------------|----------------|----------|-------------|
| `artifact_path`               | 文字列         | はい      | アーティファクトアーカイブ内のファイルのパス。 |
| `id`                          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`                      | 整数        | はい      | 一意のジョブ識別子。 |
| `job_token`                   | 文字列         | いいえ       | マルチプロジェクトパイプラインの[トリガー](../ci/jobs/job_artifacts.md#with-a-cicd-job-token)で使用します。これは、`.gitlab-ci.yml`ファイルで定義されたCI/CDジョブでのみ実行する必要があります。値は常に`$CI_JOB_TOKEN`です。`$CI_JOB_TOKEN`に関連付けられているジョブは、このトークンの使用時に実行されている必要があります。PremiumおよびUltimateのみ。 |

リクエストの例:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

PremiumおよびUltimateプランでは、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を使用してCI/CDジョブでこのエンドポイントで認証できます。

返される可能性がある応答ステータスコードは次のとおりです。

| ステータス | 説明 |
|--------|-------------|
| 200    | 1つのアーティファクトファイルを送信します。 |
| 400    | 無効なパスが指定されました。 |
| 404    | ビルドが見つからないか、アーティファクトがないか、またはすべてのアーティファクトがレポートです。 |

## 特定のタグまたはブランチから1つのアーティファクトファイルをダウンロードする

参照名を使用して、最新の**成功**したパイプラインでジョブのアーティファクトから1つのファイルをダウンロードします。ファイルはアーカイブから抽出され、`plain/text`コンテンツタイプでクライアントにストリーミングされます。

[親パイプラインと子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)の場合、アーティファクトは親から子への階層順に検索されます。親パイプラインと子のパイプラインの両方に同じ名前のジョブがある場合、親パイプラインのアーティファクトが返されます。

アーティファクトファイルは、[CSVエクスポート](../user/application_security/vulnerability_report/_index.md#export-vulnerability-details)の場合よりも詳細な情報を提供します。

前提要件:

- `success`ステータスで完了したパイプラインが必要です。
- パイプラインに手動ジョブが含まれている場合は、これらのジョブが次のいずれかである必要があります。
  - 正常に完了している。
  - `allow_failure: true`が設定されている。

cURLを使用してGitLab.comからアーティファクトをダウンロードする場合は、リクエストがCDNを介してリダイレクトされる可能性があるため、`--location`パラメーターを使用します。

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name
```

パラメーター:

| 属性                     | 型           | 必須 | 説明 |
|-------------------------------|----------------|----------|-------------|
| `artifact_path`               | 文字列         | はい      | アーティファクトアーカイブ内のファイルのパス。 |
| `id`                          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job`                         | 文字列         | はい      | ジョブの名前。 |
| `ref_name`                    | 文字列         | はい      | リポジトリ内のブランチ名またはタグ名。`HEAD`参照と`SHA`参照はサポートされていません。 |
| `job_token`                   | 文字列         | いいえ       | マルチプロジェクトパイプラインの[トリガー](../ci/jobs/job_artifacts.md#with-a-cicd-job-token)で使用します。これは、`.gitlab-ci.yml`ファイルで定義されたCI/CDジョブでのみ実行する必要があります。値は常に`$CI_JOB_TOKEN`です。`$CI_JOB_TOKEN`に関連付けられているジョブは、このトークンの使用時に実行されている必要があります。PremiumおよびUltimateのみ。 |

リクエストの例:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf"
```

PremiumおよびUltimateプランでは、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)を使用してCI/CDジョブでこのエンドポイントで認証できます。

返される可能性がある応答ステータスコードは次のとおりです。

| ステータス | 説明 |
|--------|-------------|
| 200    | 1つのアーティファクトファイルを送信します。 |
| 400    | 無効なパスが指定されました。 |
| 404    | ビルドが見つからないか、アーティファクトがないか、またはすべてのアーティファクトがレポートです。 |

## アーティファクトを保持する

有効期限が設定されている場合に、アーティファクトが削除されないようにします。

```plaintext
POST /projects/:id/jobs/:job_id/artifacts/keep
```

パラメーター

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |

リクエストの例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts/keep"
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

## ジョブアーティファクトを削除する

ジョブのアーティファクトを削除します。

前提要件:

- プロジェクトのメンテナー以上のロールが必要です。

```plaintext
DELETE /projects/:id/jobs/:job_id/artifacts
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |

リクエストの例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts"
```

{{< alert type="note" >}}

アーティファクトを削除するには、メンテナー以上のロールが必要です。

{{< /alert >}}

アーティファクトが正常に削除された場合は、ステータス`204 No Content`の応答が返されます。

## プロジェクト内のすべてのジョブアーティファクトを削除する

プロジェクト内で削除可能なすべてのジョブアーティファクトを削除します。デフォルトでは、[各refの最新の成功したパイプライン](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)のアーティファクトは削除されません。

このエンドポイントへのリクエストは、削除できるすべてのジョブアーティファクトの有効期限を現在時刻に設定します。その後、期限切れのジョブアーティファクトの定期的なクリーンアップの一部として、ファイルがシステムから削除されます。ジョブログが削除されることはありません。

定期的なクリーンアップはスケジュールに従って非同期的に行われるため、アーティファクトが削除されるまでに多少の遅延が生じる場合があります。

前提要件:

- プロジェクトのメンテナー以上のロールが必要です。

```plaintext
DELETE /projects/:id/artifacts
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/artifacts"
```

ステータス`202 Accepted`の応答が返されます。

## トラブルシューティング

### `artifacts:reports`ファイルのダウンロード

ジョブアーティファクトAPIを使用してレポートをダウンロードしようとすると、`404 Not Found`エラーが発生する場合があります。

この問題は、デフォルトでは[レポート](../ci/yaml/_index.md#artifactsreports)をダウンロードできないために発生します。

レポートをダウンロード可能にするには、そのファイル名または`gl-*-report.json`を[`artifacts:paths`](../ci/yaml/_index.md#artifactspaths)に追加します。
