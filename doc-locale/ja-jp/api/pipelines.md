---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[CI/CDパイプライン](../ci/pipelines/_index.md)を操作します。

## プロジェクトパイプラインのリストを取得する {#list-project-pipelines}

{{< history >}}

- 応答の`name`は、GitLab 15.11で`pipeline_name_in_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310)されました。デフォルトでは無効になっています。
- リクエストの`name`は、GitLab 15.11で`pipeline_name_search`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310)されました。デフォルトでは無効になっています。
- 応答の`name`は、GitLab 16.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)になりました。機能フラグ`pipeline_name_in_api`は削除されました。
- リクエストの`name`は、GitLab 16.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/385864)になりました。機能フラグ`pipeline_name_search`は削除されました。
- `source`が`parent_pipeline`に設定された子パイプラインを返す機能のサポートは、GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)されました。

{{< /history >}}

プロジェクト内のパイプラインのリストを取得します。

デフォルトでは、[子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)は結果に含まれません。子パイプラインを返すには、`source`を`parent_pipeline`に設定します。

```plaintext
GET /projects/:id/pipelines
```

結果のページネーションを制御するには、`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性        | 型           | 必須 | 説明 |
|------------------|----------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`           | 文字列         | いいえ       | 指定された名前のパイプラインを返します。 |
| `order_by`       | 文字列         | いいえ       | パイプラインを、`id`、`status`、`ref`、`updated_at`、または`user_id`で並べ替えます（デフォルト: `id`）。 |
| `ref`            | 文字列         | いいえ       | パイプラインのref |
| `scope`          | 文字列         | いいえ       | パイプラインのスコープ。`running`、`pending`、`finished`、`branches`、`tags`のいずれか。 |
| `sha`            | 文字列         | いいえ       | パイプラインのSHA |
| `sort`           | 文字列         | いいえ       | パイプラインを`asc`または`desc`の順にソートします（デフォルト: `desc`）。 |
| `source`         | 文字列         | いいえ       | [パイプラインソース](../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable)。 |
| `status`         | 文字列         | いいえ       | パイプラインのステータス。`created`、`waiting_for_resource`、`preparing`、`pending`、`running`、`success`、`failed`、`canceled`、`skipped`、`manual`、`scheduled`のいずれか。 |
| `updated_after`  | 日時       | いいえ       | 指定された日付より後に更新されたパイプラインを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `updated_before` | 日時       | いいえ       | 指定された日付より前に更新されたパイプラインを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_after`  | 日時       | いいえ       | 指定された日付より後に作成されたパイプラインを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before` | 日時       | いいえ       | 指定された日付より前に作成されたパイプラインを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `username`       | 文字列         | いいえ       | パイプラインをトリガーしたユーザーのユーザー名 |
| `yaml_errors`    | ブール値        | いいえ       | 無効な設定のパイプラインを返します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines"
```

応答の例

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 1,
    "status": "pending",
    "source": "push",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 1,
    "status": "pending",
    "source": "web",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "name": "Build pipeline",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## 単一のパイプラインを取得する {#get-a-single-pipeline}

{{< history >}}

- 応答の`name`は、GitLab 15.11で`pipeline_name_in_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310)されました。デフォルトでは無効になっています。
- 応答の`name`は、GitLab 16.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)になりました。機能フラグ`pipeline_name_in_api`は削除されました。

{{< /history >}}

プロジェクトから1つのパイプラインを取得します。

単一の[子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)を取得することもできます。

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

結果のページネーションを制御するには、`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

応答の例

```json
{
  "id": 287,
  "iid": 144,
  "project_id": 21,
  "name": "Build pipeline",
  "sha": "50f0acb76a40e34a4ff304f7347dcc6587da8a14",
  "ref": "main",
  "status": "success",
  "source": "push",
  "created_at": "2022-09-21T01:05:07.200Z",
  "updated_at": "2022-09-21T01:05:50.185Z",
  "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/287",
  "before_sha": "8a24fb3c5877a6d0b611ca41fc86edc174593e2b",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "username": "root",
    "name": "Administrator",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://127.0.0.1:3000/root"
  },
  "started_at": "2022-09-21T01:05:14.197Z",
  "finished_at": "2022-09-21T01:05:50.175Z",
  "committed_at": null,
  "duration": 34,
  "queued_duration": 6,
  "coverage": null,
  "detailed_status": {
    "icon": "status_success",
    "text": "passed",
    "label": "passed",
    "group": "success",
    "tooltip": "passed",
    "has_details": false,
    "details_path": "/test-group/test-project/-/pipelines/287",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
  }
}
```

## 最新のパイプラインを取得する {#get-the-latest-pipeline}

{{< history >}}

- 応答の`name`は、GitLab 15.11で`pipeline_name_in_api`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310)されました。デフォルトでは無効になっています。
- 応答の`name`は、GitLab 16.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)になりました。機能フラグ`pipeline_name_in_api`は削除されました。

{{< /history >}}

プロジェクト内の特定のrefにおける最新のコミット用の最新パイプラインを取得します。コミット用のパイプラインが存在しない場合、`403`ステータスコードが返されます。

```plaintext
GET /projects/:id/pipelines/latest
```

結果のページネーションを制御するには、`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性 | 型   | 必須 | 説明 |
|-----------|--------|----------|-------------|
| `ref`     | 文字列 | いいえ       | 最新のパイプラインを確認するブランチまたはタグ。指定しない場合、デフォルトのブランチがデフォルトになります。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/latest"
```

応答の例

```json
{
    "id": 287,
    "iid": 144,
    "project_id": 21,
    "name": "Build pipeline",
    "sha": "50f0acb76a40e34a4ff304f7347dcc6587da8a14",
    "ref": "main",
    "status": "success",
    "source": "push",
    "created_at": "2022-09-21T01:05:07.200Z",
    "updated_at": "2022-09-21T01:05:50.185Z",
    "web_url": "http://127.0.0.1:3000/test-group/test-project/-/pipelines/287",
    "before_sha": "8a24fb3c5877a6d0b611ca41fc86edc174593e2b",
    "tag": false,
    "yaml_errors": null,
    "user": {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/root"
    },
    "started_at": "2022-09-21T01:05:14.197Z",
    "finished_at": "2022-09-21T01:05:50.175Z",
    "committed_at": null,
    "duration": 34,
    "queued_duration": 6,
    "coverage": null,
    "detailed_status": {
        "icon": "status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "tooltip": "passed",
        "has_details": false,
        "details_path": "/test-group/test-project/-/pipelines/287",
        "illustration": null,
        "favicon": "/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
    }
}
```

## パイプライン用の変数を取得する {#get-variables-for-a-pipeline}

パイプラインの[パイプライン変数](../ci/variables/_index.md#use-pipeline-variables)を取得します。

```plaintext
GET /projects/:id/pipelines/:pipeline_id/variables
```

結果のページネーションを制御するには、`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/variables"
```

応答の例

```json
[
  {
    "key": "RUN_NIGHTLY_BUILD",
    "variable_type": "env_var",
    "value": "true"
  },
  {
    "key": "foo",
    "value": "bar"
  }
]
```

## パイプライン用のテストレポートを取得する {#get-a-test-report-for-a-pipeline}

{{< alert type="note" >}}

このAPIルートは、[単体テストレポート](../ci/testing/unit_test_reports.md)機能の一部です。

{{< /alert >}}

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

結果のページネーションを制御するには、`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

リクエストのサンプル:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report"
```

応答のサンプル:

```json
{
  "total_time": 5,
  "total_count": 1,
  "success_count": 1,
  "failed_count": 0,
  "skipped_count": 0,
  "error_count": 0,
  "test_suites": [
    {
      "name": "Secure",
      "total_time": 5,
      "total_count": 1,
      "success_count": 1,
      "failed_count": 0,
      "skipped_count": 0,
      "error_count": 0,
      "test_cases": [
        {
          "status": "success",
          "name": "Security Reports can create an auto-remediation MR",
          "classname": "vulnerability_management_spec",
          "execution_time": 5,
          "system_output": null,
          "stack_trace": null
        }
      ]
    }
  ]
}
```

## パイプライン用のテストレポート概要を取得する {#get-a-test-report-summary-for-a-pipeline}

{{< alert type="note" >}}

このAPIルートは、[単体テストレポート](../ci/testing/unit_test_reports.md)機能の一部です。

{{< /alert >}}

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report_summary
```

結果のページネーションを制御するには、`page`および`per_page`[ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

リクエストのサンプル:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report_summary"
```

応答のサンプル:

```json
{
    "total": {
        "time": 1904,
        "count": 3363,
        "success": 3351,
        "failed": 0,
        "skipped": 12,
        "error": 0,
        "suite_error": null
    },
    "test_suites": [
        {
            "name": "test",
            "total_time": 1904,
            "total_count": 3363,
            "success_count": 3351,
            "failed_count": 0,
            "skipped_count": 12,
            "error_count": 0,
            "build_ids": [
                66004
            ],
            "suite_error": null
        }
    ]
}
```

## パイプラインを新規作成 {#create-a-new-pipeline}

{{< history >}}

- 応答の`iid`は、GitLab 14.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/342223)されました。
- `inputs`属性は、GitLab 17.10で`ci_inputs_for_pipelines`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519958)されました。デフォルトでは有効になっています。
- `inputs`属性は、GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/536548)になりました。機能フラグ`ci_inputs_for_pipelines`は削除されました。

{{< /history >}}

```plaintext
POST /projects/:id/pipeline
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `ref`       | 文字列         | はい      | パイプラインを実行するブランチまたはタグ。マージリクエストパイプラインの場合は、[マージリクエストエンドポイント](merge_requests.md#create-merge-request-pipeline)を使用します。 |
| `variables` | 配列          | いいえ       | 構造`[{ 'key': 'UPLOAD_TO_S3', 'variable_type': 'file', 'value': 'true' }, {'key': 'TEST', 'value': 'test variable'}]`と一致する、パイプライン使用可能な変数を含む[ハッシュの配列](rest/_index.md#array-of-hashes)。`variable_type`が除外されている場合、デフォルトは`env_var`になります。 |
| `inputs`    | ハッシュ           | いいえ       | パイプラインの作成時に使用するインプットが、キーと値のペアとして含まれている[ハッシュ](rest/_index.md#hash)。 |

基本的な例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

[インプット](../ci/inputs/_index.md)を使用したリクエストの例:

```shell
curl --request POST \
  --header "Content-Type: application/json" \
  --data '{"inputs": {"environment": "environment", "scan_security": false, "level": 3}}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

応答の例

```json
{
  "id": 61,
  "iid": 21,
  "project_id": 1,
  "sha": "384c444e840a515b23f21915ee5766b87068a70d",
  "ref": "main",
  "status": "pending",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-11-04T09:36:13.747Z",
  "updated_at": "2016-11-04T09:36:13.977Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/61"
}
```

## パイプラインでジョブを再試行する {#retry-jobs-in-a-pipeline}

{{< history >}}

- 応答の`iid`は、GitLab 14.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/342223)されました。

{{< /history >}}

失敗した、またはキャンセルされたジョブをパイプラインで再試行します。失敗した、またはキャンセルされたジョブがパイプラインにない場合、このエンドポイントを呼び出しても効果はありません。

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/retry"
```

応答:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "pending",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

## パイプライン用のすべてのジョブをキャンセルする {#cancel-all-jobs-for-a-pipeline}

```plaintext
POST /projects/:id/pipelines/:pipeline_id/cancel
```

{{< alert type="note" >}}

このエンドポイントは、パイプラインの状態に関係なく、成功応答`200`を返します。詳細については、[イシュー414963](https://gitlab.com/gitlab-org/gitlab/-/issues/414963)を参照してください。

{{< /alert >}}

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/cancel"
```

応答:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "canceled",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46"
}
```

## パイプラインを削除する {#delete-a-pipeline}

パイプラインを削除すると、すべてのパイプラインキャッシュが期限切れになり、ビルド、ログ、アーティファクト、トリガーなど、直接関連するすべてのオブジェクトが削除されます。**この操作は元に戻すことができません。**

パイプラインを削除しても、[子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)は自動的に削除されません。詳細については、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)を参照してください。

```plaintext
DELETE /projects/:id/pipelines/:pipeline_id
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request "DELETE" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

## パイプラインのメタデータを更新する {#update-pipeline-metadata}

パイプラインのメタデータを更新できます。メタデータには、パイプラインの名前が含まれています。

```plaintext
PUT /projects/:id/pipelines/:pipeline_id/metadata
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`        | 文字列         | はい      | パイプラインの新しい名前 |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

リクエストのサンプル:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --data "name=Some new pipeline name" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/metadata"
```

応答のサンプル:

```json
{
  "id": 46,
  "iid": 11,
  "project_id": 1,
  "status": "running",
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "before_sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "created_at": "2016-08-11T11:28:34.085Z",
  "updated_at": "2016-08-11T11:32:35.169Z",
  "started_at": null,
  "finished_at": "2016-08-11T11:32:35.145Z",
  "committed_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "coverage": null,
  "web_url": "https://example.com/foo/bar/pipelines/46",
  "name": "Some new pipeline name"
}
```
