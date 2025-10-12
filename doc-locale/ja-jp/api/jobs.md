---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[CI/CDジョブ](../ci/jobs/_index.md)を操作します。

## プロジェクトジョブのリストを取得する {#list-project-jobs}

プロジェクト内のジョブのリストを取得します。

デフォルトでは、APIの結果は[ページネーション](rest/_index.md#pagination)されるため、このリクエストは一度に20件の結果を返します。

{{< alert type="note" >}}

このエンドポイントは、オフセットベースと[キーセットベース](rest/_index.md#keyset-based-pagination)のページネーションの両方をサポートしていますが、連続する結果ページをリクエストする場合は、キーセットベースのページネーションを使用することを強くお勧めします。

{{< /alert >}}

```plaintext
GET /projects/:id/jobs
```

| 属性  | 型                           | 必須 | 説明 |
| ---------- | ------------------------------ | -------- | ----------- |
| `id`       | 整数または文字列                 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `scope`    | 文字列、または文字列の配列 | いいえ       | 表示するジョブのスコープ。[ジョブステータス値](#job-status-values)の単一指定、または配列指定。`scope`が指定されていない場合、すべてのジョブが返されます。 |
| `order_by` | 文字列                         | いいえ       | `id`の順序でジョブを返します。 |
| `sort`     | 文字列                         | いいえ       | `asc`または`desc`の順にソートされたジョブを返します。デフォルトは`desc`です。 |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs?scope[]=pending&scope[]=running"
```

応答の例:

```json
[
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
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:54:27.895Z",
    "erased_at": null,
    "duration": 0.173,
    "queued_duration": 0.010,
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "artifacts": [
      {"file_type": "archive", "size": 1000, "filename": "artifacts.zip", "file_format": "zip"},
      {"file_type": "metadata", "size": 186, "filename": "metadata.gz", "file_format": "gzip"},
      {"file_type": "trace", "size": 1500, "filename": "job.log", "file_format": "raw"},
      {"file_type": "junit", "size": 750, "filename": "junit.xml.gz", "file_format": "gzip"}
    ],
    "artifacts_expire_at": "2016-01-23T17:54:27.895Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "runner": {
      "id": 32,
      "description": "",
      "ip_address": null,
      "active": true,
      "paused": false,
      "is_shared": true,
      "runner_type": "instance_type",
      "name": null,
      "online": false,
      "status": "offline"
    },
    "runner_manager": {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-05-01T10:12:02.507Z",
      "contacted_at": "2024-05-07T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline"
    },
    "stage": "test",
    "status": "failed",
    "failure_reason": "script_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  },
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
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.727Z",
    "started_at": "2015-12-24T17:54:24.729Z",
    "finished_at": "2015-12-24T17:54:24.921Z",
    "erased_at": null,
    "duration": 0.192,
    "queued_duration": 0.023,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "tag_list": [
      "docker runner", "win10-2004"
    ],
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "artifacts": [],
    "runner": null,
    "runner_manager": null,
    "stage": "test",
    "status": "failed",
    "failure_reason": "stuck_or_timeout_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/6",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  }
]
```

### ジョブステータス値 {#job-status-values}

ジョブの応答の`status`フィールドとジョブのフィルタリング用の`scope`パラメータは、次の値を使用します。

- `canceled`: ジョブは手動でキャンセルされたか、または自動的に中断されました。
- `canceling`: ジョブはキャンセル中ですが、`after_script`が実行されています。
- `created`: ジョブは作成されましたが、まだ処理されていません。
- `failed`: ジョブの実行に失敗しました。
- `manual`: ジョブを開始するには手動操作が必要です。
- `pending`: ジョブはRunnerを待機するキューに入っています。
- `preparing`: Runnerが実行環境を準備中です。
- `running`: ジョブはRunnerで実行中です。
- `scheduled`: ジョブはスケジュールされていますが、実行は開始されていません。
- `skipped`: ジョブは、条件または依存関係のためにスキップされました。
- `success`: ジョブは正常に完了しました。
- `waiting_for_resource`: ジョブは、リソースが利用可能になるのを待機しています。

## パイプラインジョブのリストを取得する {#list-pipeline-jobs}

パイプラインのジョブのリストを取得します。

デフォルトでは、APIの結果は[ページネーション](rest/_index.md#pagination)されるため、このリクエストは一度に20件の結果を返します。

このエンドポイントは、次のように動作します。

- [子パイプライン](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines)を含む[任意のパイプラインのデータを返します](pipelines.md#get-a-single-pipeline)。
- デフォルトでは、再試行されたジョブを応答で返しません。
- ジョブをIDで降順でソートします（新しいIDから）。

```plaintext
GET /projects/:id/pipelines/:pipeline_id/jobs
```

| 属性         | 型                           | 必須 | 説明 |
| ----------------- | ------------------------------ | -------- | ----------- |
| `id`              | 整数または文字列                 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `pipeline_id`     | 整数                        | はい      | パイプラインのID。[事前定義されたCI変数](../ci/variables/predefined_variables.md)`CI_PIPELINE_ID`を使用して、CIジョブ内でも取得できます。 |
| `include_retried` | ブール値                        | いいえ       | 再試行されたジョブを応答に含めます。`false`がデフォルトです。 |
| `scope`           | 文字列**または**文字列の配列 | いいえ       | 表示するジョブのスコープ。[ジョブステータス値](#job-status-values)の単一指定、または配列指定。`scope`が指定されていない場合、すべてのジョブが返されます。 |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/6/jobs?scope[]=pending&scope[]=running"
```

応答の例:

```json
[
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
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.727Z",
    "started_at": "2015-12-24T17:54:24.729Z",
    "finished_at": "2015-12-24T17:54:24.921Z",
    "erased_at": null,
    "duration": 0.192,
    "queued_duration": 0.023,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "artifacts": [],
    "runner": {
      "id": 32,
      "description": "",
      "ip_address": null,
      "active": true,
      "paused": false,
      "is_shared": true,
      "runner_type": "instance_type",
      "name": null,
      "online": false,
      "status": "offline"
    },
    "runner_manager": {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-05-01T10:12:02.507Z",
      "contacted_at": "2024-05-07T06:30:09.355Z",
      "ip_address": "127.0.0.1",
    },
    "stage": "test",
    "status": "failed",
    "failure_reason": "stuck_or_timeout_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/6",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  },
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
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:54:27.895Z",
    "erased_at": null,
    "duration": 0.173,
    "queued_duration": 0.023,
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "artifacts": [
      {"file_type": "archive", "size": 1000, "filename": "artifacts.zip", "file_format": "zip"},
      {"file_type": "metadata", "size": 186, "filename": "metadata.gz", "file_format": "gzip"},
      {"file_type": "trace", "size": 1500, "filename": "job.log", "file_format": "raw"},
      {"file_type": "junit", "size": 750, "filename": "junit.xml.gz", "file_format": "gzip"}
    ],
    "artifacts_expire_at": "2016-01-23T17:54:27.895Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
    "runner": null,
    "runner_manager": null,
    "stage": "test",
    "status": "failed",
    "failure_reason": "script_failure",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    }
  }
]
```

## パイプラインのトリガージョブのリストを取得する {#list-pipeline-trigger-jobs}

パイプラインのトリガージョブのリストを取得します。

```plaintext
GET /projects/:id/pipelines/:pipeline_id/bridges
```

| 属性     | 型                           | 必須 | 説明 |
| ------------- | ------------------------------ | -------- | ----------- |
| `id`          | 整数または文字列                 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `pipeline_id` | 整数                        | はい      | パイプラインのID。 |
| `scope`       | 文字列**または**文字列の配列 | いいえ       | 表示するジョブのスコープ。[ジョブステータス値](#job-status-values)の単一指定、または配列指定。`scope`が指定されていない場合、すべてのジョブが返されます。 |

```shell
curl --globoff \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/pipelines/6/bridges?scope[]=pending&scope[]=running"
```

応答の例:

```json
[
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
    "archived": false,
    "source": "push",
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:58:27.895Z",
    "erased_at": null,
    "duration": 240,
    "queued_duration": 0.123,
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending",
      "created_at": "2015-12-24T15:50:16.123Z",
      "updated_at": "2015-12-24T18:00:44.432Z",
      "web_url": "https://example.com/foo/bar/pipelines/6"
    },
    "ref": "main",
    "stage": "test",
    "status": "pending",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
    "project": {
      "ci_job_token_scope_enabled": false
    },
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "public_email": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    },
    "downstream_pipeline": {
      "id": 5,
      "sha": "f62a4b2fb89754372a346f24659212eb8da13601",
      "ref": "main",
      "status": "pending",
      "created_at": "2015-12-24T17:54:27.722Z",
      "updated_at": "2015-12-24T17:58:27.896Z",
      "web_url": "https://example.com/diaspora/diaspora-client/pipelines/5"
    }
  }
]
```

## ジョブトークンのジョブを取得する {#get-job-tokens-job}

ジョブトークンを生成したジョブを取得します。

```plaintext
GET /job
```

例（[CI/CD](../ci/jobs/_index.md)ジョブの[`script`](../ci/yaml/_index.md#script)セクションの一部として実行する必要があります）:

```shell
# Option 1
curl --header "Authorization: Bearer $CI_JOB_TOKEN" \
  --url "${CI_API_V4_URL}/job"

# Option 2
curl --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --url "${CI_API_V4_URL}/job"

# Option 3
curl --url "${CI_API_V4_URL}/job?job_token=$CI_JOB_TOKEN"
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
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2015-12-24T15:51:21.880Z",
  "started_at": "2015-12-24T17:54:30.733Z",
  "finished_at": "2015-12-24T17:54:31.198Z",
  "erased_at": null,
  "duration": 0.465,
  "queued_duration": 0.123,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "project_id": 1,
    "ref": "main",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "failed",
  "failure_reason": "script_failure",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/8",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.dev/root",
    "created_at": "2015-12-21T13:14:24.077Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": ""
  }
}
```

## Kubernetes向けGitLabエージェントを`CI_JOB_TOKEN`で取得 {#get-gitlab-agent-for-kubernetes-by-ci_job_token}

`CI_JOB_TOKEN`を生成したジョブを、許可された[GitLabエージェント](../user/clusters/agent/_index.md)のリストとともに取得します。

```plaintext
GET /job/allowed_agents
```

サポートされている属性:

| 属性      | 型   | 必須 | 説明 |
|----------------|--------|----------|-------------|
| `CI_JOB_TOKEN` | 文字列 | はい      | GitLabが提供する`CI_JOB_TOKEN`変数に関連付けられているトークンの値。 |

リクエストの例:

```shell
# Option 1
curl --header "JOB-TOKEN: <CI_JOB_TOKEN>" \
  --url "https://gitlab.example.com/api/v4/job/allowed_agents"

# Option 2
curl --url "https://gitlab.example.com/api/v4/job/allowed_agents?job_token=<CI_JOB_TOKEN>"
```

応答の例:

```json
{
  "allowed_agents": [
    {
      "id": 1,
      "config_project": {
        "id": 1,
        "description": null,
        "name": "project1",
        "name_with_namespace": "John Doe2 / project1",
        "path": "project1",
        "path_with_namespace": "namespace1/project1",
        "created_at": "2022-11-16T14:51:50.579Z"
      }
    }
  ],
  "job": {
    "id": 1
  },
  "pipeline": {
    "id": 2
  },
  "project": {
    "id": 1,
    "groups": [
      {
        "id": 1
      },
      {
        "id": 2
      },
      {
        "id": 3
      }
    ]
  },
  "user": {
    "id": 2,
    "name": "John Doe3",
    "username": "user2",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/10fc7f102b",
    "web_url": "http://localhost/user2"
  }
}
```

## 単一のジョブを取得する {#get-a-single-job}

プロジェクトの単一のジョブを取得します。

```plaintext
GET /projects/:id/jobs/:job_id
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/8"
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
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2015-12-24T15:51:21.880Z",
  "started_at": "2015-12-24T17:54:30.733Z",
  "finished_at": "2015-12-24T17:54:31.198Z",
  "erased_at": null,
  "duration": 0.465,
  "queued_duration": 0.010,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "tag_list": [
      "docker runner", "macos-10.15"
    ],
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "project_id": 1,
    "ref": "main",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/8",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.dev/root",
    "created_at": "2015-12-21T13:14:24.077Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": ""
  }
}
```

## ログファイルを取得する {#get-a-log-file}

プロジェクトの特定のジョブのログ（トレース）を取得します。

```plaintext
GET /projects/:id/jobs/:job_id/trace
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |

```shell
curl --location \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/8/trace"
```

返される可能性のある応答のステータスコードは次のとおりです。

| ステータス | 説明 |
|--------|-------------|
| 200    | ログファイルを提供します |
| 404    | ジョブが見つからないか、ログファイルがありません |

## ジョブをキャンセルする {#cancel-a-job}

プロジェクトの単一のジョブをキャンセルします。

```plaintext
POST /projects/:id/jobs/:job_id/cancel
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |
| `force`   | ブール値        | いいえ       | `true`に設定すると、`canceling`状態のジョブを[強制的にキャンセル](../ci/jobs/_index.md#force-cancel-a-job)します。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/cancel"
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
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:14:09.526Z",
  "finished_at": null,
  "erased_at": null,
  "duration": 8,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "canceled",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

## ジョブを再試行する {#retry-a-job}

プロジェクトの単一のジョブを再試行します。

```plaintext
POST /projects/:id/jobs/:job_id/retry
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/retry"
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
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": null,
  "finished_at": null,
  "erased_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "pending",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

{{< alert type="note" >}}

GitLab 17.0より前では、このエンドポイントはトリガージョブをサポートしていません。

{{< /alert >}}

## ジョブを消去する {#erase-a-job}

プロジェクトの単一のジョブを消去します（ジョブアーティファクトとジョブログを削除します）。

```plaintext
POST /projects/:id/jobs/:job_id/erase
```

パラメータ

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`  | 整数        | はい      | ジョブのID。 |

リクエストの例

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/erase"
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
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "download_url": null,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "erased_at": "2016-01-11T11:30:19.914Z",
  "duration": 97.0,
  "queued_duration": 0.010,
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```

{{< alert type="note" >}}

APIを使用してアーカイブ済みジョブを削除することはできませんが、[特定の日付より前に完了したジョブのアーティファクトとログは削除](../administration/cicd/job_artifacts_troubleshooting.md#delete-old-builds-and-artifacts)できます。

{{< /alert >}}

## ジョブを実行する {#run-a-job}

手動状態のジョブに対して、ジョブを開始するアクションをトリガーします。

```plaintext
POST /projects/:id/jobs/:job_id/play
```

| 属性                  | 型            | 必須 | 説明 |
|----------------------------|-----------------|----------|-------------|
| `id`                       | 整数または文字列  | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `job_id`                   | 整数         | はい      | ジョブのID。 |
| `job_variables_attributes` | ハッシュの配列 | いいえ       | ジョブで使用可能なカスタム変数を含む配列。 |

リクエストの例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data @variables.json \
  --url "https://gitlab.example.com/api/v4/projects/1/jobs/1/play"
```

`@variables.json`の構造は次のとおりです。

```json
{
  "job_variables_attributes": [
    {
      "key": "TEST_VAR_1",
      "value": "test1"
    },
    {
      "key": "TEST_VAR_2",
      "value": "test2"
    }
  ]
}
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
  "archived": false,
  "source": "push",
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": null,
  "finished_at": null,
  "erased_at": null,
  "duration": null,
  "queued_duration": 0.010,
  "id": 1,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "runner_manager": null,
  "stage": "test",
  "status": "pending",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/1",
  "project": {
    "ci_job_token_scope_enabled": false
  },
  "user": null
}
```
