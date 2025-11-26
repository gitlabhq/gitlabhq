---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトWebhook API
description: "REST APIを使用して、プロジェクトのWebhookを設定および管理します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[project webhooks](../user/project/integrations/webhooks.md)を管理します。プロジェクトのWebhookは、インスタンス全体に影響を与える[system hooks](system_hooks.md) 、およびグループ内のすべてのプロジェクトとサブグループに影響を与える[group webhooks](group_webhooks.md)とは異なります。

前提要件: 

- 管理者であるか、プロジェクトのメンテナーロールを持っている必要があります。

## プロジェクトのWebhookを一覧表示します {#list-webhooks-for-a-project}

プロジェクトのWebhookのリストを取得します。

```plaintext
GET /projects/:id/hooks
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

## プロジェクトのWebhookを取得します {#get-a-project-webhook}

プロジェクトの特定のWebhookを取得します。

```plaintext
GET /projects/:id/hooks/:hook_id
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

レスポンス例:

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "project_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "releases_events": true,
  "milestone_events": true,
  "feature_flag_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "custom_headers": [
    {
      "key": "Authorization"
    }
  ]
}
```

## プロジェクトのWebhookイベントのリストを取得します {#get-a-list-of-project-webhook-events}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048)されました。

{{< /history >}}

特定のプロジェクトのWebhookの過去7日間のイベントのリストを開始日から取得します。

```plaintext
GET /projects/:id/hooks/:hook_id/events
```

サポートされている属性は以下のとおりです:

| 属性  | 型              | 必須 | 説明 |
|:-----------|:------------------|:---------|:------------|
| `hook_id`  | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`       | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `status`   | 整数または文字列 | いいえ       | イベントのレスポンスステータスコード。例：`200`または`500`。ステータスカテゴリで検索できます: `successful`（200～299）、`client_failure`（400～499）、および`server_failure`（500～599）。 |
| `page`     | 整数           | いいえ       | 取得するページ。`1`がデフォルトです。 |
| `per_page` | 整数           | いいえ       | ページごとに返すレコード数。`20`がデフォルトです。 |

レスポンス例:

```json
[
  {
    "id": 1,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "3a427872-00df-429c-9bc9-a9475de2efe4",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "3c5c0404-c866-44bc-a5f6-452bb1bfc76e",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "9cebe914-4827-408f-b014-cfa23a47a35f",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "before": "468abc807a2b2572f43e72c743b76cee6db24025",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:17 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0906479999999874,
    "response_status": "200"
  },
  {
    "id": 2,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "7c6e0583-49f2-4dc5-a50b-4c0bcf3c1b27",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "a753eedb-1d72-4549-9ca7-eac8ea8e50dd",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "842d7c3e-3114-4396-8a95-66c084d53cb1",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "before": "468abc807a2b2572f43e72c743b76cee6db24025",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:19 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0716120000000728,
    "response_status": "200"
  }
]
```

## プロジェクトのWebhookイベントを再送信する {#resend-a-project-webhook-event}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130)されました。

{{< /history >}}

特定のプロジェクトのWebhookイベントを再送信します。

このエンドポイントには、プロジェクトのWebhookおよび認証済みユーザーごとに、1分あたり5つのリクエストのレート制限があります。GitLab Self-ManagedおよびGitLab Dedicatedでこの制限を無効にするには、管理者が[機能フラグを無効にする](../administration/feature_flags/_index.md)ことができます。`web_hook_event_resend_api_endpoint_rate_limit`という名前です。

```plaintext
POST /projects/:id/hooks/:hook_id/events/:hook_event_id/resend
```

サポートされている属性は以下のとおりです:

| 属性       | 型    | 必須 | 説明 |
|:----------------|:--------|:---------|:------------|
| `hook_event_id` | 整数 | はい      | プロジェクトのWebhookイベントのID。 |
| `hook_id`       | 整数 | はい      | プロジェクトのWebhookのID。 |

レスポンス例:

```json
{
  "response_status": 200
}
```

## プロジェクトにWebhookを追加する {#add-a-webhook-to-a-project}

{{< history >}}

- `name`および`description`の属性は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)されました。

{{< /history >}}

指定されたプロジェクトにWebhookを追加します。

```plaintext
POST /projects/:id/hooks
```

サポートされている属性は以下のとおりです:

| 属性                      | 型              | 必須 | 説明 |
|:-------------------------------|:------------------|:---------|:------------|
| `id`                           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `url`                          | 文字列            | はい      | プロジェクトのWebhook URL。 |
| `branch_filter_strategy`       | 文字列            | いいえ       | ブランチでプッシュイベントをフィルタリングします。使用可能な値は、`wildcard`（デフォルト）、`regex`、および`all_branches`です。 |
| `confidential_issues_events`   | ブール値           | いいえ       | 機密のイシューイベントでプロジェクトのWebhookをトリガーします。 |
| `confidential_note_events`     | ブール値           | いいえ       | 機密のメモイベントでプロジェクトのWebhookをトリガーします。 |
| `custom_headers`               | 配列             | いいえ       | プロジェクトのWebhookのカスタムヘッダー。 |
| `custom_webhook_template`      | 文字列            | いいえ       | プロジェクトのWebhookのカスタムWebhookテンプレート。 |
| `deployment_events`            | ブール値           | いいえ       | デプロイイベントでプロジェクトのWebhookをトリガーします。 |
| `description`                  | 文字列            | いいえ       | Webhookの説明。 |
| `enable_ssl_verification`      | ブール値           | いいえ       | Webhookをトリガーするときに、SSL検証を実行します。 |
| `feature_flag_events`          | ブール値           | いいえ       | 機能フラグイベントでプロジェクトのWebhookをトリガーします。 |
| `issues_events`                | ブール値           | いいえ       | イシューイベントでプロジェクトのWebhookをトリガーします。 |
| `job_events`                   | ブール値           | いいえ       | ジョブイベントでプロジェクトのWebhookをトリガーします。 |
| `merge_requests_events`        | ブール値           | いいえ       | マージリクエストイベントでプロジェクトのWebhookをトリガーします。 |
| `milestone_events`             | ブール値           | いいえ       | マイルストーンイベントでプロジェクトのWebhookをトリガーします。 |
| `name`                         | 文字列            | いいえ       | プロジェクトのWebhookの名前。 |
| `note_events`                  | ブール値           | いいえ       | メモイベントでプロジェクトのWebhookをトリガーします。 |
| `pipeline_events`              | ブール値           | いいえ       | パイプラインイベントでプロジェクトのWebhookをトリガーします。 |
| `push_events`                  | ブール値           | いいえ       | プッシュイベントでプロジェクトのWebhookをトリガーします。 |
| `push_events_branch_filter`    | 文字列            | いいえ       | 一致するブランチのみのプッシュイベントでプロジェクトのWebhookをトリガーします。 |
| `releases_events`              | ブール値           | いいえ       | リリースイベントでプロジェクトのWebhookをトリガーします。 |
| `resource_access_token_events` | ブール値           | いいえ       | プロジェクトアクセストークンの有効期限イベントでプロジェクトのWebhookをトリガーします。 |
| `tag_push_events`              | ブール値           | いいえ       | タグ付けイベントでプロジェクトのWebhookをトリガーします。 |
| `token`                        | 文字列            | いいえ       | 受信したペイロードを検証するためのシークレットトークン。トークンはレスポンスで返されません。 |
| `wiki_page_events`             | ブール値           | いいえ       | WikiイベントでプロジェクトのWebhookをトリガーします。 |

## プロジェクトのWebhookを編集する {#edit-a-project-webhook}

{{< history >}}

- `name`および`description`の属性は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)されました。

{{< /history >}}

指定されたプロジェクトのプロジェクトWebhookを編集します。

```plaintext
PUT /projects/:id/hooks/:hook_id
```

サポートされている属性は以下のとおりです:

| 属性                      | 型              | 必須 | 説明 |
|:-------------------------------|:------------------|:---------|:------------|
| `hook_id`                      | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`                           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `url`                          | 文字列            | はい      | プロジェクトのWebhook URL。 |
| `branch_filter_strategy`       | 文字列            | いいえ       | ブランチでプッシュイベントをフィルタリングします。使用可能な値は、`wildcard`（デフォルト）、`regex`、および`all_branches`です。 |
| `custom_headers`               | 配列             | いいえ       | プロジェクトのWebhookのカスタムヘッダー。 |
| `custom_webhook_template`      | 文字列            | いいえ       | プロジェクトのWebhookのカスタムWebhookテンプレート。 |
| `description`                  | 文字列            | いいえ       | プロジェクトWebhookの説明。 |
| `confidential_issues_events`   | ブール値           | いいえ       | 機密のイシューイベントでプロジェクトのWebhookをトリガーします。 |
| `confidential_note_events`     | ブール値           | いいえ       | 機密のメモイベントでプロジェクトのWebhookをトリガーします。 |
| `deployment_events`            | ブール値           | いいえ       | デプロイイベントでプロジェクトのWebhookをトリガーします。 |
| `enable_ssl_verification`      | ブール値           | いいえ       | フックをトリガーするときに、SSL検証を実行します。 |
| `feature_flag_events`          | ブール値           | いいえ       | 機能フラグイベントでプロジェクトのWebhookをトリガーします。 |
| `issues_events`                | ブール値           | いいえ       | イシューイベントでプロジェクトのWebhookをトリガーします。 |
| `job_events`                   | ブール値           | いいえ       | ジョブイベントでプロジェクトのWebhookをトリガーします。 |
| `merge_requests_events`        | ブール値           | いいえ       | マージリクエストイベントでプロジェクトのWebhookをトリガーします。 |
| `milestone_events`             | ブール値           | いいえ       | マイルストーンイベントでプロジェクトのWebhookをトリガーします。 |
| `name`                         | 文字列            | いいえ       | プロジェクトのWebhookの名前。 |
| `note_events`                  | ブール値           | いいえ       | メモイベントでプロジェクトのWebhookをトリガーします。 |
| `pipeline_events`              | ブール値           | いいえ       | パイプラインイベントでプロジェクトのWebhookをトリガーします。 |
| `push_events`                  | ブール値           | いいえ       | プッシュイベントでプロジェクトのWebhookをトリガーします。 |
| `push_events_branch_filter`    | 文字列            | いいえ       | 一致するブランチのみのプッシュイベントでプロジェクトのWebhookをトリガーします。 |
| `releases_events`              | ブール値           | いいえ       | リリースイベントでプロジェクトのWebhookをトリガーします。 |
| `resource_access_token_events` | ブール値           | いいえ       | プロジェクトアクセストークンの有効期限イベントでプロジェクトのWebhookをトリガーします。 |
| `tag_push_events`              | ブール値           | いいえ       | タグ付けイベントでプロジェクトのWebhookをトリガーします。 |
| `token`                        | 文字列            | いいえ       | 受信したペイロードを検証するためのシークレットトークン。レスポンスで返されません。Webhook URLを変更すると、シークレットトークンはリセットされ、保持されません。 |
| `wiki_page_events`             | ブール値           | いいえ       | WikiページイベントでプロジェクトのWebhookをトリガーします。 |

## プロジェクトのWebhookを削除する {#delete-project-webhook}

プロジェクトからWebhookを削除します。このメソッドは冪等であり、複数回呼び出すことができます。プロジェクトのWebhookは利用可能であるか、そうでないかのどちらかです。

```plaintext
DELETE /projects/:id/hooks/:hook_id
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

プロジェクトのWebhookが利用可能かどうかで、JSONレスポンスが異なることに注意してください。プロジェクトのフックがJSONレスポンスで返される前に利用可能な場合、または空のレスポンスが返される場合。

## テストプロジェクトのWebhookをトリガーする {#trigger-a-test-project-webhook}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147656)されました。
- GitLab 17.0で、`web_hook_test_api_endpoint_rate_limit`という名前の[フラグ付き](../administration/feature_flags/_index.md)で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150066)されました。デフォルトでは有効になっています。

{{< /history >}}

指定されたプロジェクトのテストプロジェクトWebhookをトリガーします。

GitLab 17.0以降、このエンドポイントには特別なレート制限があります:

- GitLab 17.0では、レートはプロジェクトのWebhookごとに1分あたり3つのリクエストでした。
- GitLab 17.1では、これはプロジェクトおよび認証済みユーザーごとに1分あたり5つのリクエストに変更されました。

GitLab Self-ManagedおよびGitLab Dedicatedでこの制限を無効にするには、管理者が[機能フラグを無効にする](../administration/feature_flags/_index.md)ことができます。`web_hook_test_api_endpoint_rate_limit`という名前です。

```plaintext
POST /projects/:id/hooks/:hook_id/test/:trigger
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `trigger` | 文字列            | はい      | `push_events`、`tag_push_events`、`issues_events`、`confidential_issues_events`、`note_events`、`merge_requests_events`、`job_events`、`pipeline_events`、`wiki_page_events`、`releases_events`、`milestone_events`、`emoji_events`、または`resource_access_token_events`のいずれか。 |

レスポンス例:

```json
{"message":"201 Created"}
```

## カスタムヘッダーを設定する {#set-a-custom-header}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)されました。

{{< /history >}}

```plaintext
PUT /projects/:id/hooks/:hook_id/custom_headers/:key
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | カスタムヘッダーのキー。 |
| `value`   | 文字列            | はい      | カスタムヘッダーの値。 |

成功すると、このエンドポイントはレスポンスコード`204 No Content`を返します。

## カスタムヘッダーを削除する {#delete-a-custom-header}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)されました。

{{< /history >}}

```plaintext
DELETE /projects/:id/hooks/:hook_id/custom_headers/:key
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | カスタムヘッダーのキー。 |

成功すると、このエンドポイントはレスポンスコード`204 No Content`を返します。

## URL変数を設定する {#set-a-url-variable}

```plaintext
PUT /projects/:id/hooks/:hook_id/url_variables/:key
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | URL変数のキー。 |
| `value`   | 文字列            | はい      | URL変数の値。 |

成功すると、このエンドポイントはレスポンスコード`204 No Content`を返します。

## URL変数を削除する {#delete-a-url-variable}

```plaintext
DELETE /projects/:id/hooks/:hook_id/url_variables/:key
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
|:----------|:------------------|:---------|:------------|
| `hook_id` | 整数           | はい      | プロジェクトのWebhookのID。 |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | URL変数のキー。 |

成功すると、このエンドポイントはレスポンスコード`204 No Content`を返します。
