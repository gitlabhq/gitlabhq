---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Sidekiq 메트릭 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API 엔드포인트를 사용하면 Sidekiq의 현재 상태, 작업, 큐 및 프로세스에 대한 정보를 검색할 수 있습니다.

## 모든 작업 큐 메트릭 나열 {#list-all-job-queue-metrics}

백로그 크기 및 레이턴시를 포함한 모든 Sidekiq 작업 큐에 대한 세부 정보를 나열합니다.

```plaintext
GET /sidekiq/queue_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/queue_metrics"
```

응답 예시:

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

## 모든 Sidekiq 프로세스 나열 {#list-all-sidekiq-processes}

호스트명, 프로세스 ID, 큐 및 동시성 설정을 포함한 모든 등록된 Sidekiq 워커 프로세스에 대한 세부 정보를 나열합니다.

```plaintext
GET /sidekiq/process_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/process_metrics"
```

응답 예시:

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

## 작업 완료 메트릭 검색 {#retrieve-job-completion-metrics}

모든 Sidekiq 작업의 완료 상태에 대한 통계를 검색합니다.

```plaintext
GET /sidekiq/job_stats
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/job_stats"
```

응답 예시:

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

## 모든 Sidekiq 메트릭 나열 {#list-all-sidekiq-metrics}

큐, 프로세스 및 작업 완료 메트릭을 포함한 모든 Sidekiq 메트릭을 단일 응답으로 나열합니다.

```plaintext
GET /sidekiq/compound_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/compound_metrics"
```

응답 예시:

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
