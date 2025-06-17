---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインAPI
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## パイプラインのページネーション

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

## プロジェクトパイプラインをリストする

{{< history >}}

- 応答の`iid`は、GitLab 14.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/342223)されました。
- GitLab 15.11で、応答の`name`が`pipeline_name_in_api`という名前の[フラグ](../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310)されました。デフォルトでは無効になっています。
- 15.11で、リクエストの`name`が`pipeline_name_search`という名前の[フラグ](../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310)されました。デフォルトでは無効になっています。
- GitLab 16.3で応答の`name`が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)になりました。機能フラグ`pipeline_name_in_api`が削除されました。
- GitLab 16.9で、リクエストの`name`が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/385864)になりました。機能フラグ`pipeline_name_search`が削除されました。
- `source`が`parent_pipeline`に設定された子パイプラインを返す操作のサポートは、GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)されました。

{{< /history >}}

プロジェクト内のパイプラインをリストします。

デフォルトでは、[子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)は結果に含まれません。子パイプラインを返すには、`source`を`parent_pipeline`に設定します。

```plaintext
GET /projects/:id/pipelines
```

| 属性        | 型           | 必須 | 説明 |
|------------------|----------------|----------|-------------|
| `id`             | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`           | 文字列         | いいえ       | 指定された名前のパイプラインを返します。 |
| `order_by`       | 文字列         | いいえ       | パイプラインを`id`、`status`、`ref`、`updated_at`、`user_id`で並べ替えます（デフォルトは`id`です） |
| `ref`            | 文字列         | いいえ       | パイプラインのref |
| `scope`          | 文字列         | いいえ       | パイプラインのスコープ。`running`、`pending`、`finished`、`branches`、`tags`のいずれかです。 |
| `sha`            | 文字列         | いいえ       | パイプラインのSHA |
| `sort`           | 文字列         | いいえ       | `asc`または`desc`順にパイプラインを並べ替えます（デフォルトは`desc`です）。 |
| `source`         | 文字列         | いいえ       | [パイプラインソース](../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable)。 |
| `status`         | 文字列         | いいえ       | パイプラインのステータス。`created`、`waiting_for_resource`、`preparing`、`pending`、`running`、`success`、`failed`、`canceled`、`skipped`、`manual`、`scheduled`のいずれかです。 |
| `updated_after`  | 日時       | いいえ       | 指定された日付より後に更新されたパイプラインを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `updated_before` | 日時       | いいえ       | 指定された日付より前に更新されたパイプラインを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `created_after`  | 日時       | いいえ       | 指定された日付より後に作成されたパイプラインを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
| `created_before` | 日時       | いいえ       | 指定された日付より前に作成されたパイプラインを返します。ISO 8601形式で指定します（`2019-03-15T08:00:00Z`）。 |
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

## 1つのパイプラインを取得する

{{< history >}}

- 応答の`iid`は、GitLab 14.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/342223)されました。
- GitLab 15.11で、応答の`name`が`pipeline_name_in_api`という名前の[フラグ](../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310)されました。デフォルトでは無効になっています。
- GitLab 16.3で応答の`name`が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)になりました。機能フラグ`pipeline_name_in_api`が削除されました。

{{< /history >}}

プロジェクトから1つのパイプラインを取得します。

1つの[子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)を取得することもできます。

```plaintext
GET /projects/:id/pipelines/:pipeline_id
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
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

### 最新のパイプラインを取得する

{{< history >}}

- GitLab 15.11で、応答の`name`が`pipeline_name_in_api`という名前の[フラグ](../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115310)されました。デフォルトでは無効になっています。
- GitLab 16.3で応答の`name`が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/398131)になりました。機能フラグ`pipeline_name_in_api`が削除されました。

{{< /history >}}

プロジェクト内の特定のrefでの最新コミットの最新パイプラインを取得します。コミットのパイプラインが存在しない場合、`403`ステータスコードが返されます。

```plaintext
GET /projects/:id/pipelines/latest
```

| 属性 | 型   | 必須 | 説明 |
|-----------|--------|----------|-------------|
| `ref`     | 文字列 | いいえ       | 最新のパイプラインを確認するブランチまたはタグ。指定しない場合、デフォルトはデフォルトブランチです。 |

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

### パイプラインの変数を取得する

パイプラインの変数を取得します。パイプラインスケジュールからの変数は含まれません。詳細については、[イシュー250850](https://gitlab.com/gitlab-org/gitlab/-/issues/250850)を参照してください。

```plaintext
GET /projects/:id/pipelines/:pipeline_id/variables
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
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

### パイプラインのテストレポートを取得する

{{< alert type="note" >}}

このAPIルートは、[ユニットテストレポート](../ci/testing/unit_test_reports.md)機能の一部です。

{{< /alert >}}

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report"
```

応答の例:

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

### パイプラインのテストレポートの概要を取得する

{{< alert type="note" >}}

このAPIルートは、[ユニットテストレポート](../ci/testing/unit_test_reports.md)機能の一部です。

{{< /alert >}}

```plaintext
GET /projects/:id/pipelines/:pipeline_id/test_report_summary
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/test_report_summary"
```

応答の例:

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

## 新しいパイプラインを作成する

{{< history >}}

- 応答の`iid`は、GitLab 14.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/342223)されました。
- GitLab 17.10で、`inputs`属性が`ci_inputs_for_pipelines`という名前の[フラグ](../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519958)されました。デフォルトでは無効になっています。

{{< /history >}}

```plaintext
POST /projects/:id/pipeline
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `ref`       | 文字列         | はい      | パイプラインを実行するブランチまたはタグ。マージリクエストパイプラインの場合は、[マージリクエストエンドポイント](merge_requests.md#create-merge-request-pipeline)を使用します。 |
| `variables` | 配列          | いいえ       | `[{ 'key': 'UPLOAD_TO_S3', 'variable_type': 'file', 'value': 'true' }, {'key': 'TEST', 'value': 'test variable'}]`構造に一致する、パイプラインで使用可能な変数を含む[ハッシュの配列](rest/_index.md#array-of-hashes)。`variable_type`が除外されている場合は、デフォルトで`env_var`になります。 |
| `inputs`    | ハッシュ           | いいえ       | パイプラインの作成時に使用するインプットがキーと値のペアとして含まれている[ハッシュ](rest/_index.md#hash)。 |

基本的な例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipeline?ref=main"
```

[inputs](../ci/yaml/inputs.md)を使用したリクエストの例:

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

## パイプラインのジョブを再試行する

{{< history >}}

- 応答の`iid`は、GitLab 14.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/342223)されました。

{{< /history >}}

パイプラインで失敗またはキャンセルされたジョブを再試行します。失敗またはキャンセルされたジョブがパイプラインにない場合、このエンドポイントを呼び出しても効果はありません。

```plaintext
POST /projects/:id/pipelines/:pipeline_id/retry
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
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

## パイプラインのジョブをキャンセルする

```plaintext
POST /projects/:id/pipelines/:pipeline_id/cancel
```

{{< alert type="note" >}}

このエンドポイントは、パイプラインの状態に関係なく、成功応答`200`を返します。詳細については、[イシュー414963](https://gitlab.com/gitlab-org/gitlab/-/issues/414963)を参照してください。

{{< /alert >}}

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
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

## パイプラインを削除する

パイプラインを削除すると、すべてのパイプラインキャッシュが期限切れになり、ビルド、ログ、アーティファクト、トリガーなど、直接関連するすべてのオブジェクトが削除されます。**この操作は元に戻すことができません。**

パイプラインを削除しても、[子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)が自動的に削除されることはありません。詳細については、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)を参照してください。

```plaintext
DELETE /projects/:id/pipelines/:pipeline_id
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request "DELETE" "https://gitlab.example.com/api/v4/projects/1/pipelines/46"
```

## パイプラインメタデータを更新する

パイプラインのメタデータを更新できます。メタデータには、パイプラインの名前が含まれています。

```plaintext
PUT /projects/:id/pipelines/:pipeline_id/metadata
```

| 属性     | 型           | 必須 | 説明 |
|---------------|----------------|----------|-------------|
| `id`          | 整数/文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `name`        | 文字列         | はい      | パイプラインの新しい名前 |
| `pipeline_id` | 整数        | はい      | パイプラインのID |

リクエストの例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --data "name=Some new pipeline name" "https://gitlab.example.com/api/v4/projects/1/pipelines/46/metadata"
```

応答の例:

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
