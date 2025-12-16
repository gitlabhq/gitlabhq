---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sidekiqキュー管理 
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

指定されたメタデータに一致するSidekiqキューからジョブを削除します。

レスポンスには3つのフィールドがあります:

1. `deleted_jobs` - リクエストによって削除されたジョブの数。
1. `queue_size` - リクエストの処理後、キューに残っているサイズ。
1. `completed` - リクエストが時間内にキュー全体を処理できたかどうか。そうでない場合、同じパラメータで再試行すると、さらにジョブが削除される可能性があります（最初のリクエストの発行後に追加されたものも含む）。

このAPIエンドポイントは、管理者のみが使用できます。

```plaintext
DELETE /admin/sidekiq/queues/:queue_name
```

| 属性           | 型   | 必須 | 説明 |
|---------------------|--------|----------|-------------|
| `queue_name`        | 文字列 | はい      | 削除するジョブの送信元キューの名前。 |
| `user`              | 文字列 | いいえ       | ジョブのスケジュールを設定したユーザー名 |
| `project`           | 文字列 | いいえ       | ジョブのスケジュール元となったプロジェクトのフルパス |
| `root_namespace`    | 文字列 | いいえ       | プロジェクトのルートネームスペース |
| `subscription_plan` | 文字列 | いいえ       | ルートネームスペースのサブスクリプションプラン（GitLab.comのみ） |
| `caller_id`         | 文字列 | いいえ       | ジョブのスケジュールを設定するエンドポイントまたはバックグラウンドジョブ（例：`ProjectsController#create`、`/api/:version/projects/:id`、`PostReceive`） |
| `feature_category`  | 文字列 | いいえ       | バックグラウンドジョブの機能カテゴリー（例：`team_planning`または`code_review`） |
| `worker_class`      | 文字列 | いいえ       | バックグラウンドジョブワーカーのクラス（例：`PostReceive`または`MergeWorker`） |

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
