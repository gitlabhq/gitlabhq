---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: パイプラインスケジュールAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[パイプラインスケジュール](../ci/pipelines/schedules.md)を操作します。

## すべてのパイプラインスケジュールを一覧表示する {#list-all-pipeline-schedules}

プロジェクトのすべてのパイプラインスケジュールを一覧表示します。

```plaintext
GET /projects/:id/pipeline_schedules
```

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `scope`   | 文字列            | いいえ       | パイプラインスケジュールのスコープ。次のいずれかである必要があります: `active`, `inactive`。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules"
```

```json
[
    {
        "id": 13,
        "description": "Test schedule pipeline",
        "ref": "refs/heads/main",
        "cron": "* * * * *",
        "cron_timezone": "Asia/Tokyo",
        "next_run_at": "2017-05-19T13:41:00.000Z",
        "active": true,
        "created_at": "2017-05-19T13:31:08.849Z",
        "updated_at": "2017-05-19T13:40:17.727Z",
        "owner": {
            "name": "Administrator",
            "username": "root",
            "id": 1,
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
            "web_url": "https://gitlab.example.com/root"
        },
        "inputs": [
            {
                "name": "deploy_strategy",
                "value": "blue-green"
            },
            {
                "name": "feature_flags",
                "value": ["flag1", "flag2"]
            }
        ]
    }
]
```

> [!note]
> `inputs`フィールドは、メンテナーまたはオーナーロールを持つユーザー、またはスケジュールオーナーの応答にのみ含まれます。

## パイプラインスケジュールを取得する {#retrieve-a-pipeline-schedule}

プロジェクトのパイプラインスケジュールを取得します。

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "* * * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T13:41:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:40:17.727Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    },
    "variables": [
        {
            "key": "TEST_VARIABLE_1",
            "variable_type": "env_var",
            "value": "TEST_1",
            "raw": false
        }
    ],
    "inputs": [
        {
            "name": "deploy_strategy",
            "value": "blue-green"
        },
        {
            "name": "feature_flags",
            "value": ["flag1", "flag2"]
        }
    ]
}
```

> [!note]
> `inputs`および`variables`フィールドは、メンテナーまたはオーナーロールを持つユーザー、またはスケジュールオーナーの応答にのみ含まれます。

## パイプラインスケジュールによってトリガーされたすべてのパイプラインを一覧表示する {#list-all-pipelines-triggered-by-a-pipeline-schedule}

プロジェクト内のパイプラインスケジュールによってトリガーされたすべてのパイプラインを一覧表示します。

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id/pipelines
```

サポートされている属性は以下のとおりです: 

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |
| `scope`                | 文字列            | いいえ       | パイプラインのスコープ。次のいずれか: `running`, `pending`, `finished`, `branches`, `tags`。 |
| `sort`                 | 文字列            | いいえ       | パイプラインを`asc`または`desc`の順にソートします。デフォルトは`asc`です。 |
| `status`               | 文字列            | いいえ       | パイプラインのステータス。次のいずれか: `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual`, `scheduled`。 |
| `updated_after`        | 日時          | いいえ       | 指定された日付より後に更新されたパイプラインを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `updated_before`       | 日時          | いいえ       | 指定された日付より前に更新されたパイプラインを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_after`        | 日時          | いいえ       | 指定された日付より後に作成されたパイプラインを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before`       | 日時          | いいえ       | 指定された日付より前に作成されたパイプラインを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/pipelines"
```

レスポンス例: 

```json
[
  {
    "id": 47,
    "iid": 12,
    "project_id": 29,
    "status": "pending",
    "source": "scheduled",
    "ref": "new-pipeline",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "web_url": "https://example.com/foo/bar/pipelines/47",
    "created_at": "2016-08-11T11:28:34.085Z",
    "updated_at": "2016-08-11T11:32:35.169Z"
  },
  {
    "id": 48,
    "iid": 13,
    "project_id": 29,
    "status": "pending",
    "source": "scheduled",
    "ref": "new-pipeline",
    "sha": "eb94b618fb5865b26e80fdd8ae531b7a63ad851a",
    "web_url": "https://example.com/foo/bar/pipelines/48",
    "created_at": "2016-08-12T10:06:04.561Z",
    "updated_at": "2016-08-12T10:09:56.223Z"
  }
]
```

## 新しいパイプラインスケジュールを作成する {#create-a-new-pipeline-schedule}

{{< history >}}

- `inputs`属性は、GitLab 17.11で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/525504)、[フラグ](../administration/feature_flags/_index.md)`ci_inputs_for_pipelines`で有効化されました。デフォルトでは有効になっています。
- `inputs`属性は、GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/536548)になりました。機能フラグ`ci_inputs_for_pipelines`は削除されました。

{{< /history >}}

プロジェクトの新しいパイプラインスケジュールを作成します。

```plaintext
POST /projects/:id/pipeline_schedules
```

| 属性       | 型              | 必須 | 説明 |
| --------------- | ----------------- | -------- | ----------- |
| `cron`          | 文字列            | はい      | Cronスケジュール。例: `0 1 * * *`。 |
| `description`   | 文字列            | はい      | パイプラインスケジュールの説明。 |
| `id`            | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `ref`           | 文字列            | はい      | パイプラインをトリガーするブランチまたはタグ名。短いrefs (`main`) または完全なrefs (`refs/heads/main`または`refs/tags/main`) のいずれかを受け入れます。値がブランチまたはタグのいずれかに一致しない限り、短いrefsは自動的に完全なrefsに展開されます。 |
| `active`        | ブール値           | いいえ       | パイプラインスケジュールを有効にします。falseが設定されている場合、パイプラインスケジュールは初期状態では非アクティブになります (デフォルト: `true`)。 |
| `cron_timezone` | 文字列            | いいえ       | `ActiveSupport::TimeZone`がサポートするタイムゾーン。例: `Pacific Time (US & Canada)` (デフォルト: `UTC`)。 |
| `inputs`        | ハッシュ              | いいえ       | パイプラインスケジュールに渡す[入力](../ci/inputs/_index.md#for-a-pipeline)の配列。各入力には`name`と`value`が含まれます。値には文字列、配列、数値、ブール値を使用できます。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules" \
  --form "description=Build packages" \
  --form "ref=main" \
  --form "cron=0 1 * * 5" \
  --form "cron_timezone=UTC" \
  --form "active=true"
```

レスポンス例: 

```json
{
    "id": 14,
    "description": "Build packages",
    "ref": "refs/heads/main",
    "cron": "0 1 * * 5",
    "cron_timezone": "UTC",
    "next_run_at": "2017-05-26T01:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:43:08.169Z",
    "updated_at": "2017-05-19T13:43:08.169Z",
    "last_pipeline": null,
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    }
}
```

`inputs`を含むリクエストの例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules" \
  --form "description=Build packages" \
  --form "ref=main" \
  --form "cron=0 1 * * 5" \
  --form "cron_timezone=UTC" \
  --form "active=true" \
  --form "inputs[][name]=deploy_strategy" \
  --form "inputs[][value]=blue-green"
```

## パイプラインスケジュールを更新する {#update-a-pipeline-schedule}

プロジェクトのパイプラインスケジュールを更新します。更新が完了すると、自動的に再スケジュールされます。

```plaintext
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |
| `active`               | ブール値           | いいえ       | パイプラインスケジュールを有効にします。falseが設定されている場合、パイプラインスケジュールは初期状態では非アクティブになります。 |
| `cron_timezone`        | 文字列            | いいえ       | `ActiveSupport::TimeZone` (例: `Pacific Time (US & Canada)`) または`TZInfo::Timezone` (例: `America/Los_Angeles`) でサポートされているタイムゾーン。 |
| `cron`                 | 文字列            | いいえ       | Cronスケジュール。例: `0 1 * * *`。 |
| `description`          | 文字列            | いいえ       | パイプラインスケジュールの説明。 |
| `ref`                  | 文字列            | いいえ       | パイプラインをトリガーするブランチまたはタグ名。短いrefs (`main`) または完全なrefs (`refs/heads/main`または`refs/tags/main`) のいずれかを受け入れます。値がブランチまたはタグのいずれかに一致しない限り、短いrefsは自動的に完全なrefsに展開されます。 |
| `inputs`               | ハッシュ              | いいえ       | パイプラインスケジュールに渡す[入力](../ci/inputs/_index.md)の配列。各入力には`name`と`value`が含まれます。既存の入力を削除するには、`name`フィールドを含め、`destroy`を`true`に設定します。値には文字列、配列、数値、ブール値を使用できます。 |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13" \
  --form "cron=0 2 * * *"
```

レスポンス例: 

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:44:16.135Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/root"
    }
}
```

`inputs`を含むリクエストの例:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13" \
  --form "cron=0 2 * * *" \
  --form "inputs[][name]=deploy_strategy" \
  --form "inputs[][value]=rolling" \
  --form "inputs[][name]=existing_input" \
  --form "inputs[][destroy]=true"
```

## パイプラインスケジュールの所有権を更新する {#update-ownership-of-a-pipeline-schedule}

プロジェクトのパイプラインスケジュールのオーナーを更新します。

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/take_ownership
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/take_ownership"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/maeda"
    }
}
```

## パイプラインスケジュールを削除する {#delete-a-pipeline-schedule}

プロジェクトのパイプラインスケジュールを削除します。

```plaintext
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13"
```

```json
{
    "id": 13,
    "description": "Test schedule pipeline",
    "ref": "refs/heads/main",
    "cron": "0 2 * * *",
    "cron_timezone": "Asia/Tokyo",
    "next_run_at": "2017-05-19T17:00:00.000Z",
    "active": true,
    "created_at": "2017-05-19T13:31:08.849Z",
    "updated_at": "2017-05-19T13:46:37.468Z",
    "last_pipeline": {
        "id": 332,
        "sha": "0e788619d0b5ec17388dffb973ecd505946156db",
        "ref": "refs/heads/main",
        "status": "pending"
    },
    "owner": {
        "name": "shinya",
        "username": "maeda",
        "id": 50,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/8ca0a796a679c292e3a11da50f99e801?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/maeda"
    }
}
```

## パイプラインスケジュールをすぐに実行する {#run-a-pipeline-schedule-immediately}

パイプラインスケジュールをすぐに実行します。このパイプラインの次回のスケジュール実行には影響しません。

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/play
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/pipeline_schedules/1/play"
```

レスポンス例: 

```json
{
  "message": "201 Created"
}
```

## パイプラインスケジュールの変数を作成する {#create-a-variable-for-a-pipeline-schedule}

パイプラインスケジュールの新しい変数を作成します。

```plaintext
POST /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`                  | 文字列            | はい      | 変数のキー。255文字以下である必要があり、`A-Z`、`a-z`、`0-9`、および`_`のみが許可されます。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |
| `value`                | 文字列            | はい      | 変数の値。 |
| `variable_type`        | 文字列            | いいえ       | 変数のタイプ。利用可能なタイプは: `env_var` (デフォルト) と`file`。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "variable_type": "env_var",
    "value": "new value"
}
```

## パイプラインスケジュールの変数を取得する {#retrieve-a-variable-for-a-pipeline-schedule}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386005)されました。

{{< /history >}}

パイプラインスケジュールの変数を取得します。

```plaintext
GET /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`                  | 文字列            | はい      | 変数のキー。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性       | 型   | 説明 |
| --------------- | ------ | ----------- |
| `key`           | 文字列 | その変数のキー。 |
| `value`         | 文字列 | 変数の値。 |
| `variable_type` | 文字列 | 変数の型。`env_var`または`file`のいずれか。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

レスポンス例: 

```json
{
    "key": "NEW_VARIABLE",
    "variable_type": "env_var",
    "value": "new value"
}
```

## パイプラインスケジュールの変数を更新する {#update-a-variable-for-a-pipeline-schedule}

パイプラインスケジュールの変数を更新します。

```plaintext
PUT /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`                  | 文字列            | はい      | 変数のキー。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |
| `value`                | 文字列            | はい      | 変数の値。 |
| `variable_type`        | 文字列            | いいえ       | 変数のタイプ。利用可能なタイプは: `env_var` (デフォルト) と`file`。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var"
}
```

## パイプラインスケジュールの変数を削除する {#delete-a-variable-for-a-pipeline-schedule}

パイプラインスケジュールの変数を削除します。

```plaintext
DELETE /projects/:id/pipeline_schedules/:pipeline_schedule_id/variables/:key
```

| 属性              | 型              | 必須 | 説明 |
| ---------------------- | ----------------- | -------- | ----------- |
| `id`                   | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`                  | 文字列            | はい      | 変数のキー。 |
| `pipeline_schedule_id` | 整数           | はい      | パイプラインスケジュールのID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/29/pipeline_schedules/13/variables/NEW_VARIABLE"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value"
}
```

### あいまいなrefs {#ambiguous-refs}

APIは、短い`ref`を完全な`ref`に自動的に展開できません。次の場合です:

- 短い`ref`と同じ名前のブランチとタグの両方が存在する場合。
- その名前のブランチまたはタグが存在しない場合。

この問題を解決するには、完全な`ref`を指定して、正しいリソースが識別されるようにします。
