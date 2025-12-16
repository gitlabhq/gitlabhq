---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部ステータスチェックAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[external status checks](../user/project/merge_requests/status_checks.md)を管理します。

## プロジェクトの外部ステータスチェックサービスを取得 {#get-project-external-status-check-services}

次のエンドポイントを使用すると、プロジェクトの外部ステータスチェックサービスに関する情報をリクエストできます:

```plaintext
GET /projects/:id/external_status_checks
```

**パラメータ**:

| 属性           | 型    | 必須 | 説明         |
|---------------------|---------|----------|---------------------|
| `id`                | 整数 | はい      | プロジェクトのID     |

```json
[
  {
    "id": 1,
    "name": "Compliance Tool",
    "project_id": 6,
    "external_url": "https://gitlab.com/example/compliance-tool",
    "hmac": true,
    "protected_branches": [
      {
        "id": 14,
        "project_id": 6,
        "name": "main",
        "created_at": "2020-10-12T14:04:50.787Z",
        "updated_at": "2020-10-12T14:04:50.787Z",
        "code_owner_approval_required": false
      }
    ]
  }
]
```

## 外部ステータスチェックサービスを作成 {#create-external-status-check-service}

次のエンドポイントを使用すると、プロジェクトの新しい外部ステータスチェックサービスを作成できます:

```plaintext
POST /projects/:id/external_status_checks
```

{{< alert type="warning" >}}

外部ステータスチェックは、該当するすべてのマージリクエストに関する情報を、定義された外部サービスに送信します。これには、機密のマージリクエストが含まれます。

{{< /alert >}}

| 属性              | 型             | 必須 | 説明                                    |
|------------------------|------------------|----------|------------------------------------------------|
| `id`                   | 整数          | はい      | プロジェクトのID                                |
| `name`                 | 文字列           | はい      | 外部ステータスチェックサービスの表示名  |
| `external_url`         | 文字列           | はい      | 外部ステータスチェックサービスのURL           |
| `shared_secret`        | 文字列           | いいえ       | 外部ステータスチェックのHMACシークレット          |
| `protected_branch_ids` | `array<Integer>` | いいえ       | ルールをスコープする保護ブランチのID |

## 外部ステータスチェックサービスを更新 {#update-external-status-check-service}

次のエンドポイントを使用すると、プロジェクトの既存の外部ステータスチェックを更新できます:

```plaintext
PUT /projects/:id/external_status_checks/:check_id
```

| 属性              | 型             | 必須 | 説明                                    |
|------------------------|------------------|----------|------------------------------------------------|
| `id`                   | 整数          | はい      | プロジェクトのID                                |
| `check_id`             | 整数          | はい      | 外部ステータスチェックサービスのID         |
| `name`                 | 文字列           | いいえ       | 外部ステータスチェックサービスの表示名  |
| `external_url`         | 文字列           | いいえ       | 外部ステータスチェックサービスのURL           |
| `shared_secret`        | 文字列           | いいえ       | 外部ステータスチェックのHMACシークレット          |
| `protected_branch_ids` | `array<Integer>` | いいえ       | ルールをスコープする保護ブランチのID |

## 外部ステータスチェックサービスを削除 {#delete-external-status-check-service}

次のエンドポイントを使用すると、プロジェクトの外部ステータスチェックサービスを削除できます:

```plaintext
DELETE /projects/:id/external_status_checks/:check_id
```

| 属性              | 型           | 必須 | 説明                            |
|------------------------|----------------|----------|----------------------------------------|
| `check_id`             | 整数        | はい      | 外部ステータスチェックサービスのID |
| `id`                   | 整数        | はい      | プロジェクトのID                        |

## マージリクエストのステータスチェックをリスト表示 {#list-status-checks-for-a-merge-request}

単一のマージリクエストについて、それに適用される外部ステータスチェックサービスとそのステータスをリスト表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/status_checks
```

**パラメータ**:

| 属性                | 型    | 必須 | 説明                |
| ------------------------ | ------- | -------- | -------------------------- |
| `id`                     | 整数 | はい      | プロジェクトのID            |
| `merge_request_iid`      | 整数 | はい      | マージリクエストのIID     |

```json
[
    {
        "id": 2,
        "name": "Service 1",
        "external_url": "https://gitlab.com/test-endpoint",
        "status": "passed"
    },
    {
        "id": 1,
        "name": "Service 2",
        "external_url": "https://gitlab.com/test-endpoint-2",
        "status": "pending"
    }
]
```

## 外部ステータスチェックのステータスを設定 {#set-status-of-an-external-status-check}

{{< history >}}

- `failed`と`passed`のサポートは、GitLab 15.0で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/353836)
- GitLab 16.5の`pending`のサポートは、GitLab 16.5で[デフォルトで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/413723)

{{< /history >}}

単一のマージリクエストの場合、APIを使用して、外部サービスによるチェックにマージリクエストが合格したことをGitLabに通知します。外部チェックのステータスを設定するには、使用するパーソナルアクセストークンが、マージリクエストのターゲットプロジェクトに対する少なくともデベロッパーロールを持つユーザーに属している必要があります。

このAPIコールは、マージリクエスト自体を承認する権限を持つ任意のユーザーとして実行します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_check_responses
```

**パラメータ**:

| 属性                  | 型    | 必須 | 説明                                                                                       |
| -------------------------- | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                       | 整数 | はい      | プロジェクトのID                                                                                   |
| `merge_request_iid`        | 整数 | はい      | マージリクエストのIID                                                                            |
| `sha`                      | 文字列  | はい      | ソースブランチの`HEAD`のSHA                                                                |
| `external_status_check_id` | 整数 | はい      | 外部ステータスチェックのID                                                                    |
| `status`                   | 文字列  | いいえ       | チェックを保留中としてマークするには`pending`、チェックに合格するには`passed`、失敗させるには`failed`に設定します |

{{< alert type="note" >}}

`sha`は、マージリクエストのソースブランチの`HEAD`にあるSHAである必要があります。

{{< /alert >}}

## マージリクエストの失敗したステータスチェックを再試行 {#retry-failed-status-check-for-a-merge-request}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383200)されました。

{{< /history >}}

単一のマージリクエストについて、指定された失敗した外部ステータスチェックを再試行します。マージリクエストが変更されていなくても、このエンドポイントはマージリクエストの現在の状態を定義済みの外部サービスに再送信します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/status_checks/:external_status_check_id/retry
```

**パラメータ**:

| 属性                  | 型    | 必須 | 説明                           |
| -------------------------- | ------- | -------- | ------------------------------------- |
| `id`                       | 整数 | はい      | プロジェクトのID                       |
| `merge_request_iid`        | 整数 | はい      | マージリクエストのIID                |
| `external_status_check_id` | 整数 | はい      | 失敗した外部ステータスチェックのID |

## レスポンス {#response}

成功した場合、ステータスコードは202です。

```json
{
    "message": "202 Accepted"
}
```

ステータスチェックがすでに合格している場合、ステータスコードは422です

```json
{
    "message": "External status check must be failed"
}
```

## 外部サービスに送信されるペイロード {#example-payload-sent-to-external-service}

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "email": "[REDACTED]"
  },
  "project": {
    "id": 6,
    "name": "Flight",
    "description": "Ipsa minima est consequuntur quisquam.",
    "web_url": "http://example.com/flightjs/Flight",
    "avatar_url": null,
    "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
    "git_http_url": "http://example.com/flightjs/Flight.git",
    "namespace": "Flightjs",
    "visibility_level": 20,
    "path_with_namespace": "flightjs/Flight",
    "default_branch": "main",
    "ci_config_path": null,
    "homepage": "http://example.com/flightjs/Flight",
    "url": "ssh://example.com/flightjs/Flight.git",
    "ssh_url": "ssh://example.com/flightjs/Flight.git",
    "http_url": "http://example.com/flightjs/Flight.git"
  },
  "object_attributes": {
    "assignee_id": null,
    "author_id": 1,
    "created_at": "2022-12-07 07:53:43 UTC",
    "description": "",
    "head_pipeline_id": 558,
    "id": 144,
    "iid": 4,
    "last_edited_at": null,
    "last_edited_by_id": null,
    "merge_commit_sha": null,
    "merge_error": null,
    "merge_params": {
      "force_remove_source_branch": "1"
    },
    "merge_status": "can_be_merged",
    "merge_user_id": null,
    "merge_when_pipeline_succeeds": false,
    "milestone_id": null,
    "source_branch": "root-main-patch-30152",
    "source_project_id": 6,
    "state_id": 1,
    "target_branch": "main",
    "target_project_id": 6,
    "time_estimate": 0,
    "title": "Update README.md",
    "updated_at": "2022-12-07 07:53:43 UTC",
    "updated_by_id": null,
    "url": "http://example.com/flightjs/Flight/-/merge_requests/4",
    "source": {
      "id": 6,
      "name": "Flight",
      "description": "Ipsa minima est consequuntur quisquam.",
      "web_url": "http://example.com/flightjs/Flight",
      "avatar_url": null,
      "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
      "git_http_url": "http://example.com/flightjs/Flight.git",
      "namespace": "Flightjs",
      "visibility_level": 20,
      "path_with_namespace": "flightjs/Flight",
      "default_branch": "main",
      "ci_config_path": null,
      "homepage": "http://example.com/flightjs/Flight",
      "url": "ssh://example.com/flightjs/Flight.git",
      "ssh_url": "ssh://example.com/flightjs/Flight.git",
      "http_url": "http://example.com/flightjs/Flight.git"
    },
    "target": {
      "id": 6,
      "name": "Flight",
      "description": "Ipsa minima est consequuntur quisquam.",
      "web_url": "http://example.com/flightjs/Flight",
      "avatar_url": null,
      "git_ssh_url": "ssh://example.com/flightjs/Flight.git",
      "git_http_url": "http://example.com/flightjs/Flight.git",
      "namespace": "Flightjs",
      "visibility_level": 20,
      "path_with_namespace": "flightjs/Flight",
      "default_branch": "main",
      "ci_config_path": null,
      "homepage": "http://example.com/flightjs/Flight",
      "url": "ssh://example.com/flightjs/Flight.git",
      "ssh_url": "ssh://example.com/flightjs/Flight.git",
      "http_url": "http://example.com/flightjs/Flight.git"
    },
    "last_commit": {
      "id": "141be9714669a4c1ccaa013c6a7f3e462ff2a40f",
      "message": "Update README.md",
      "title": "Update README.md",
      "timestamp": "2022-12-07T07:52:11+00:00",
      "url": "http://example.com/flightjs/Flight/-/commit/141be9714669a4c1ccaa013c6a7f3e462ff2a40f",
      "author": {
        "name": "Administrator",
        "email": "admin@example.com"
      }
    },
    "work_in_progress": false,
    "total_time_spent": 0,
    "time_change": 0,
    "human_total_time_spent": null,
    "human_time_change": null,
    "human_time_estimate": null,
    "assignee_ids": [
    ],
    "reviewer_ids": [
    ],
    "labels": [
    ],
    "state": "opened",
    "blocking_discussions_resolved": true,
    "first_contribution": false,
    "detailed_merge_status": "mergeable"
  },
  "labels": [
  ],
  "changes": {
  },
  "repository": {
    "name": "Flight",
    "url": "ssh://example.com/flightjs/Flight.git",
    "description": "Ipsa minima est consequuntur quisquam.",
    "homepage": "http://example.com/flightjs/Flight"
  },
  "external_approval_rule": {
    "id": 1,
    "name": "QA",
    "external_url": "https://example.com/"
  }
}
```

## 関連トピック {#related-topics}

- [外部ステータスチェック](../user/project/merge_requests/status_checks.md)
