---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループWebhook API
description: "グループのWebhookをREST APIで設定し、管理します。"
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して[グループのWebhook](../user/project/integrations/webhooks.md#group-webhooks)を管理します。グループのWebhookは、インスタンス全体に影響を与える[システムフック](system_hooks.md)や、単一のプロジェクトに限定される[プロジェクトWebhook](project_webhooks.md)とは異なります。

前提条件: 

- 管理者であるか、グループのオーナーロールを持っている必要があります。

## すべてのグループフックをリスト表示 {#list-all-group-hooks}

指定されたグループのすべてのグループフックをリスト表示します。

```plaintext
GET /groups/:id/hooks
```

サポートされている属性は以下のとおりです: 

| 属性 | 型            | 必須 | 説明 |
| --------- | --------------- | -------- | ----------- |
| `id`      | 整数または文字列  | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "url": "http://example.com/hook",
    "name": "Test group hook",
    "description": "This is a test group hook.",
    "created_at": "2024-09-01T09:10:54.854Z",
    "push_events": true,
    "tag_push_events": false,
    "merge_requests_events": false,
    "repository_update_events": false,
    "enable_ssl_verification": true,
    "alert_status": "executable",
    "disabled_until": null,
    "url_variables": [],
    "push_events_branch_filter": null,
    "branch_filter_strategy": "all_branches",
    "group_id": 99,
    "issues_events": false,
    "confidential_issues_events": false,
    "note_events": false,
    "confidential_note_events": false,
    "pipeline_events": false,
    "wiki_page_events": false,
    "job_events": false,
    "deployment_events": false,
    "feature_flag_events": false,
    "releases_events": false,
    "milestone_events": false,
    "subgroup_events": false,
    "emoji_events": false,
    "resource_access_token_events": false,
    "member_events": false,
    "project_events": false,
    "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
    "custom_headers": [
      {
        "key": "Authorization"
      }
    ],
    "token_present": false,
    "signing_token_present": false
  }
]
```

## グループフックを取得する {#retrieve-a-group-hook}

{{< history >}}

- `name`および`description`属性はGitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)。
- `token_present`および`signing_token_present`属性はGitLab 19.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325)。

{{< /history >}}

指定されたグループフックを取得します。

```plaintext
GET /groups/:id/hooks/:hook_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `hook_id` | 整数        | はい      | グループフックのID。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
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
  "feature_flag_events": false,
  "releases_events": true,
  "milestone_events": false,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
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
  ],
  "token_present": false,
  "signing_token_present": false
}
```

## すべてのグループフックイベントをリスト表示 {#list-all-group-hook-events}

{{< history >}}

- GitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048)されました。

{{< /history >}}

指定されたグループフックの、開始日から過去7日間のすべてのイベントをリスト表示します。

```plaintext
GET /groups/:id/hooks/:hook_id/events
```

サポートされている属性は以下のとおりです: 

| 属性  | 型                 | 必須 | 説明 |
|----------- |--------------------- |--------- |------------ |
| `hook_id`  | 整数              | はい      | プロジェクトフックのID。 |
| `id`       | 整数または文字列    | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `page`     | 整数              | いいえ       | 取得するページ。`1`がデフォルトです。 |
| `per_page` | 整数              | いいえ       | ページごとに返すレコード数。`20`がデフォルトです。 |
| `status`   | 整数または文字列    | いいえ       | イベントのレスポンスステータスコード。例: `200`または`500`。ステータスカテゴリで検索できます: `successful` (200-299)、`client_failure` (400-499)、および`server_failure` (500-599)。 |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/events"
```

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
      "Idempotency-Key": "a5461c4d-9c7f-4af9-add6-cddebe3c426f",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "3c5c0404-c866-44bc-a5f6-452bb1bfc76e",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "9cebe914-4827-408f-b014-cfa23a47a35f",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
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
      "Idempotency-Key": "1f0a54f0-0529-408d-a5b8-a2a98ff5f94a",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "a753eedb-1d72-4549-9ca7-eac8ea8e50dd",
      "X-Gitlab-Instance": "https://gitlab.example.com:3000",
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

### グループフックイベントを再送 {#resend-group-hook-event}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130)されました。

{{< /history >}}

特定のフックイベントを再送します。

このエンドポイントには、フックと認証済みユーザーごとに1分あたり5リクエストのレート制限があります。GitLab Self-ManagedおよびGitLab Dedicatedでこの制限を無効にするには、管理者が`web_hook_event_resend_api_endpoint_rate_limit`という名前の[機能フラグを無効にできます](../administration/feature_flags/_index.md)。

```plaintext
POST /groups/:id/hooks/:hook_id/events/:hook_event_id/resend
```

サポートされている属性は以下のとおりです: 

| 属性       | 型              | 必須 | 説明 |
|---------------- |------------------ |--------- |------------ |
| `hook_event_id` | 整数           | はい      | フックイベントのID。 |
| `hook_id`       | 整数           | はい      | グループフックのID。 |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/events/1/resend"
```

レスポンス例: 

```json
{
  "response_status": 200
}
```

## グループフックを作成 {#create-a-group-hook}

{{< history >}}

- `name`および`description`属性はGitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)。
- `signing_token`属性はGitLab 19.0で`webhook_signing_token`という名前の[フラグとともに](../administration/feature_flags/_index.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325)。デフォルトでは有効になっています。
- 機能フラグ`webhook_signing_token`はGitLab 19.1で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)。

{{< /history >}}

指定されたグループのグループフックを作成します。

```plaintext
POST /groups/:id/hooks
```

サポートされている属性は以下のとおりです: 

| 属性                      | 型              | 必須 | 説明 |
|------------------------------- |------------------ |--------- |------------ |
| `id`                           | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `url`                          | 文字列            | はい      | フックのURL。 |
| `branch_filter_strategy`       | 文字列            | いいえ       | ブランチでプッシュイベントをフィルタリングします指定できる値は、`wildcard`（デフォルト）、`regex`、および`all_branches`です。 |
| `confidential_issues_events`   | ブール値           | いいえ       | 機密イシューイベントでフックをトリガーします。 |
| `confidential_note_events`     | ブール値           | いいえ       | 機密ノートイベントでフックをトリガーします。 |
| `custom_headers`               | 配列             | いいえ       | フックのカスタムヘッダー。 |
| `custom_webhook_template`      | 文字列            | いいえ       | フックのカスタムWebhookテンプレート。 |
| `deployment_events`            | ブール値           | いいえ       | デプロイイベントでフックをトリガーします。 |
| `description`                  | 文字列            | いいえ       | フックの説明（GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)）。 |
| `enable_ssl_verification`      | ブール値           | いいえ       | フックをトリガーするときにSSL検証を実行します。 |
| `feature_flag_events`          | ブール値           | いいえ       | 機能フラグイベントでフックをトリガーします。 |
| `issues_events`                | ブール値           | いいえ       | イシューイベントでフックをトリガーします。 |
| `job_events`                   | ブール値           | いいえ       | ジョブイベントでフックをトリガーします。 |
| `member_events`                | ブール値           | いいえ       | メンバーイベントでフックをトリガーします。 |
| `merge_requests_events`        | ブール値           | いいえ       | マージリクエストイベントでフックをトリガーします。 |
| `milestone_events`             | ブール値           | いいえ       | マイルストーンイベントでフックをトリガーします。 |
| `name`                         | 文字列            | いいえ       | フックの名前（GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)）。 |
| `note_events`                  | ブール値           | いいえ       | ノートイベントでフックをトリガーします。 |
| `pipeline_events`              | ブール値           | いいえ       | パイプラインイベントでフックをトリガーします。 |
| `project_events`               | ブール値           | いいえ       | プロジェクトイベントでフックをトリガーします。 |
| `push_events`                  | ブール値           | いいえ       | プッシュイベントでフックをトリガーします。 |
| `push_events_branch_filter`    | 文字列            | いいえ       | 一致するブランチのプッシュイベントでのみフックをトリガーします。 |
| `releases_events`              | ブール値           | いいえ       | リリースイベントでフックをトリガーします。 |
| `resource_access_token_events` | ブール値           | いいえ       | プロジェクトアクセストークンの有効期限イベントでフックをトリガーします。 |
| `signing_token`                | 文字列            | いいえ       | `webhook-signature`ヘッダーをコンピューティングするために使用されるHMAC署名トークン。32バイトのキーをエンコードする`whsec_<base64>`形式である必要があります。レスポンスでは返されません。 |
| `subgroup_events`              | ブール値           | いいえ       | サブグループイベントでフックをトリガーします。 |
| `tag_push_events`              | ブール値           | いいえ       | タグプッシュイベントでフックをトリガーします。 |
| `token`                        | 文字列            | いいえ       | 受信したペイロードを検証するためのシークレットトークン。レスポンスでは返されません。 |
| `wiki_page_events`             | ブール値           | いいえ       | Wikiページイベントでフックをトリガーします。 |

リクエスト例: 

```shell
curl --request POST \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks" \
  --data '{"url": "https://example.com/hook", "name": "My Hook", "description": "Hook description"}'
```

レスポンス例: 

```json
{
  "id": 42,
  "url": "https://example.com/hook",
  "name": "My Hook",
  "description": "Hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
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
  "feature_flag_events": true,
  "releases_events": true,
  "milestone_events": true,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "token_present": false,
  "signing_token_present": false
}
```

## グループフックを更新 {#update-a-group-hook}

{{< history >}}

- `name`および`description`属性はGitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/460887)。
- `signing_token`属性はGitLab 19.0で`webhook_signing_token`という名前の[フラグとともに](../administration/feature_flags/_index.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325)。デフォルトでは有効になっています。
- 機能フラグ`webhook_signing_token`はGitLab 19.1で[削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/596374)。

{{< /history >}}

指定されたグループのグループフックを更新します。

```plaintext
PUT /groups/:id/hooks/:hook_id
```

サポートされている属性は以下のとおりです: 

| 属性                                   | 型              | 必須 | 説明 |
|-------------------------------------------- |------------------ |--------- |------------ |
| `hook_id`                                   | 整数           | はい      | グループフックのID。 |
| `id`                                        | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `url`                                       | 文字列            | はい      | フックのURL。 |
| `branch_filter_strategy`                    | 文字列            | いいえ       | ブランチでプッシュイベントをフィルタリングします指定できる値は、`wildcard`（デフォルト）、`regex`、および`all_branches`です。 |
| `confidential_issues_events`                | ブール値           | いいえ       | 機密イシューイベントでフックをトリガーします。 |
| `confidential_note_events`                  | ブール値           | いいえ       | 機密ノートイベントでフックをトリガーします。 |
| `custom_headers`                            | 配列             | いいえ       | フックのカスタムヘッダー。 |
| `custom_webhook_template`                   | 文字列            | いいえ       | フックのカスタムWebhookテンプレート。 |
| `deployment_events`                         | ブール値           | いいえ       | デプロイイベントでフックをトリガーします。 |
| `description`                               | 文字列            | いいえ       | フックの説明。 |
| `enable_ssl_verification`                   | ブール値           | いいえ       | フックをトリガーするときにSSL検証を実行します。 |
| `feature_flag_events`                       | ブール値           | いいえ       | 機能フラグイベントでフックをトリガーします。 |
| `issues_events`                             | ブール値           | いいえ       | イシューイベントでフックをトリガーします。 |
| `job_events`                                | ブール値           | いいえ       | ジョブイベントでフックをトリガーします。 |
| `member_events`                             | ブール値           | いいえ       | メンバーイベントでフックをトリガーします。 |
| `merge_requests_events`                     | ブール値           | いいえ       | マージリクエストイベントでフックをトリガーします。 |
| `milestone_events`                          | ブール値           | いいえ       | マイルストーンイベントでフックをトリガーします。 |
| `name`                                      | 文字列            | いいえ       | フックの名前。 |
| `note_events`                               | ブール値           | いいえ       | ノートイベントでフックをトリガーします。 |
| `pipeline_events`                           | ブール値           | いいえ       | パイプラインイベントでフックをトリガーします。 |
| `project_events`                            | ブール値           | いいえ       | プロジェクトイベントでフックをトリガーします。 |
| `push_events`                               | ブール値           | いいえ       | プッシュイベントでフックをトリガーします。 |
| `push_events_branch_filter`                 | 文字列            | いいえ       | 一致するブランチのプッシュイベントでのみフックをトリガーします。 |
| `releases_events`                           | ブール値           | いいえ       | リリースイベントでフックをトリガーします。 |
| `resource_access_token_events`              | ブール値           | いいえ       | プロジェクトアクセストークンの有効期限イベントでフックをトリガーします。 |
| `service_access_tokens_expiration_enforced` | ブール値           | いいえ       | サービスアカウントのアクセストークンに有効期限日を設定する必要があります。 |
| `signing_token`                             | 文字列            | いいえ       | `webhook-signature`ヘッダーをコンピューティングするために使用されるHMAC署名トークン。32バイトのキーをエンコードする`whsec_<base64>`形式である必要があります。レスポンスでは返されません。 |
| `subgroup_events`                           | ブール値           | いいえ       | サブグループイベントでフックをトリガーします。 |
| `tag_push_events`                           | ブール値           | いいえ       | タグプッシュイベントでフックをトリガーします。 |
| `token`                                     | 文字列            | いいえ       | 受信したペイロードを検証するためのシークレットトークン。レスポンスでは返されません。Webhook URLを変更すると、シークレットトークンはリセットされ、保持されません。 |
| `wiki_page_events`                          | ブール値           | いいえ       | Wikiページイベントでフックをトリガーします。 |

リクエスト例: 

```shell
curl --request POST \
  --header "content-type: application/json" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1" \
  --data '{"url": "https://example.com/hook", "name": "New hook name", "description": "Changed hook description"}'
```

レスポンス例: 

```json
{
  "id": 1,
  "url": "https://example.com/hook",
  "name": "New hook name",
  "description": "Changed hook description",
  "group_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "branch_filter_strategy": "wildcard",
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
  "feature_flag_events": true,
  "releases_events": true,
  "milestone_events": true,
  "subgroup_events": true,
  "member_events": true,
  "project_events": true,
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
  ],
  "token_present": false,
  "signing_token_present": false
}
```

## グループフックを削除 {#delete-a-group-hook}

指定されたグループフックを削除します。これは冪等なメソッドであり、複数回呼び出すことができます。フックが利用可能であるかどうか。

```plaintext
DELETE /groups/:id/hooks/:hook_id
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `hook_id` | 整数           | はい      | グループフックのID。 |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1"
```

成功した場合、メッセージは返されません。

## テスト用のグループフックをトリガー {#trigger-a-test-group-hook}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/455589)されました。
- 特別なレート制限がGitLab 17.1で`web_hook_test_api_endpoint_rate_limit`という名前の[フラグとともに](../administration/feature_flags/_index.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150486)。デフォルトでは有効になっています。

{{< /history >}}

指定されたグループのテストフックをトリガーします。

このエンドポイントには、グループと認証済みユーザーごとに1分あたり5リクエストのレート制限があります。GitLab Self-ManagedおよびGitLab Dedicatedでこの制限を無効にするには、管理者が`web_hook_test_api_endpoint_rate_limit`という名前の[機能フラグを無効にできます](../administration/feature_flags/_index.md)。

```plaintext
POST /groups/:id/hooks/:hook_id/test/:trigger
```

| 属性 | 型              | 必須 | 説明 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 整数           | はい      | グループフックのID。 |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `trigger` | 文字列            | はい      | `push_events`、`tag_push_events`、`issues_events`、`confidential_issues_events`、`note_events`、`merge_requests_events`、`job_events`、`pipeline_events`、`wiki_page_events`、`releases_events`、`milestone_events`、`emoji_events`、または`resource_access_token_events`のいずれか。 |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/test/push_events"
```

レスポンス例: 

```json
{"message":"201 Created"}
```

## カスタムヘッダーを更新 {#update-a-custom-header}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)されました。

{{< /history >}}

指定されたグループフックのカスタムヘッダーを更新します。

```plaintext
PUT /groups/:id/hooks/:hook_id/custom_headers/:key
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 整数           | はい      | グループフックのID。 |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | カスタムヘッダーのキー。 |
| `value`   | 文字列            | はい      | カスタムヘッダーの値。 |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/custom_headers/header_key?value='header_value'"
```

成功した場合、メッセージは返されません。

## カスタムヘッダーを削除 {#delete-a-custom-header}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)されました。

{{< /history >}}

カスタムヘッダーを削除します。

```plaintext
DELETE /groups/:id/hooks/:hook_id/custom_headers/:key
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 整数           | はい      | グループフックのID。 |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | カスタムヘッダーのキー。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/custom_headers/header_key"
```

成功した場合、メッセージは返されません。

## URL変数を更新 {#update-a-url-variable}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90310)されました。

{{< /history >}}

指定されたグループフックのURL変数を更新します。

```plaintext
PUT /groups/:id/hooks/:hook_id/url_variables/:key
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 整数           | はい      | グループフックのID。 |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | URL変数のキー。 |
| `value`   | 文字列            | はい      | URL変数の値。 |

リクエスト例: 

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/url_variables/my_key?value='my_key_value'"
```

成功した場合、メッセージは返されません。

## URL変数を削除 {#delete-a-url-variable}

指定されたグループフックのURL変数を削除します。

```plaintext
DELETE /groups/:id/hooks/:hook_id/url_variables/:key
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|---------- |------------------ |--------- |------------ |
| `hook_id` | 整数           | はい      | グループフックのID。 |
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `key`     | 文字列            | はい      | URL変数のキー。 |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/hooks/1/url_variables/my_key"
```

成功した場合、メッセージは返されません。
