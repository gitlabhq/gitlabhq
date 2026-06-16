---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiqキューの管理API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## Sidekiqキューからジョブを削除 {#delete-jobs-from-a-sidekiq-queue}

指定されたメタデータに一致するジョブをSidekiqキューから削除します。

レスポンスには3つのフィールドがあります:

1. `deleted_jobs` - リクエストによって削除されたジョブの数。
1. `queue_size` - リクエストの処理後に残ったキューのサイズ。
1. `completed` - リクエストがキュー全体を時間内に処理できたかどうか。時間内に処理できなかった場合、同じパラメータで再試行すると、さらにジョブが削除される可能性があります（最初のリクエストが発行された後に加えられたジョブを含む）。

このAPIエンドポイントは管理者のみが利用できます。

```plaintext
DELETE /admin/sidekiq/queues/:queue_name
```

| 属性           | 型   | 必須 | 説明 |
|---------------------|--------|----------|-------------|
| `queue_name`        | 文字列 | はい      | ジョブを削除するキューの名前 |
| `user`              | 文字列 | いいえ       | ジョブをスケジュールしたユーザー名 |
| `project`           | 文字列 | いいえ       | ジョブがスケジュールされたプロジェクトのフルパス |
| `root_namespace`    | 文字列 | いいえ       | プロジェクトのルートネームスペース |
| `subscription_plan` | 文字列 | いいえ       | ルートネームスペースのサブスクリプションプラン (GitLab.comのみ) |
| `caller_id`         | 文字列 | いいえ       | ジョブをスケジュールしたエンドポイントまたはバックグラウンドジョブ（例: `ProjectsController#create`、`/api/:version/projects/:id`、`PostReceive`） |
| `feature_category`  | 文字列 | いいえ       | バックグラウンドジョブの機能カテゴリ（例: `team_planning`または`code_review`） |
| `worker_class`      | 文字列 | いいえ       | バックグラウンドジョブワーカーのクラス（例: `PostReceive`または`MergeWorker`） |

`queue_name`以外の属性が少なくとも1つ必要です。

リクエスト例: 

```shell
curl --request DELETE \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/admin/sidekiq/queues/:queue_name"
```

レスポンス例: 

```json
{
  "completed": true,
  "deleted_jobs": 7,
  "queue_size": 14
}
```
