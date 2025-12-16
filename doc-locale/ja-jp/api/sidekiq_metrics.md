---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: SidekiqメトリクスAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIエンドポイントを使用すると、Sidekiqの現在の状態、ジョブ、キュー、およびプロセスに関する情報を取得できます。

## 現在のキューメトリクスを取得 {#get-the-current-queue-metrics}

登録されているすべてのキュー、そのバックログ、およびそのレイテンシーに関する情報を一覧表示します。

```plaintext
GET /sidekiq/queue_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/queue_metrics"
```

レスポンス例:

```json
{
  "queues": {
    "default": {
      "backlog": 0,
      "latency": 0
    }
  }
}
```

## 現在のプロセスメトリクスを取得 {#get-the-current-process-metrics}

キューの処理のために登録されているすべてのSidekiqワーカーに関する情報を一覧表示します。

```plaintext
GET /sidekiq/process_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/process_metrics"
```

レスポンス例:

```json
{
  "processes": [
    {
      "hostname": "gitlab.example.com",
      "pid": 5649,
      "tag": "gitlab",
      "started_at": "2016-06-14T10:45:07.159-05:00",
      "queues": [
        "post_receive",
        "mailers",
        "archive_repo",
        "system_hook",
        "project_web_hook",
        "gitlab_shell",
        "incoming_email",
        "runner",
        "common",
        "default"
      ],
      "labels": [],
      "concurrency": 25,
      "busy": 0
    }
  ]
}
```

## 現在のジョブ統計を取得 {#get-the-current-job-statistics}

Sidekiqが実行したジョブに関する情報を一覧表示します。

```plaintext
GET /sidekiq/job_stats
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/job_stats"
```

レスポンス例:

```json
{
  "jobs": {
    "processed": 2,
    "failed": 0,
    "enqueued": 0,
    "dead": 0
  }
}
```

## 以前に言及したすべてのメトリクスの複合応答を取得する {#get-a-compound-response-of-all-the-previously-mentioned-metrics}

Sidekiqに関する現在利用可能なすべての情報を一覧表示します。

```plaintext
GET /sidekiq/compound_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/compound_metrics"
```

レスポンス例:

```json
{
  "queues": {
    "default": {
      "backlog": 0,
      "latency": 0
    }
  },
  "processes": [
    {
      "hostname": "gitlab.example.com",
      "pid": 5649,
      "tag": "gitlab",
      "started_at": "2016-06-14T10:45:07.159-05:00",
      "queues": [
        "post_receive",
        "mailers",
        "archive_repo",
        "system_hook",
        "project_web_hook",
        "gitlab_shell",
        "incoming_email",
        "runner",
        "common",
        "default"
      ],
      "labels": [],
      "concurrency": 25,
      "busy": 0
    }
  ],
  "jobs": {
    "processed": 2,
    "failed": 0,
    "enqueued": 0,
    "dead": 0
  }
}
```
