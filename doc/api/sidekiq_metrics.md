---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Sidekiq Metrics API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This API endpoint allows you to retrieve some information about the current state
of Sidekiq, its jobs, queues, and processes.

## List all job queue metrics

Lists details about all Sidekiq job queues, including backlog size and latency.

```plaintext
GET /sidekiq/queue_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/queue_metrics"
```

Example response:

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

## List all Sidekiq processes

Lists details about all registered Sidekiq worker processes, including hostname, process ID, queues, and concurrency settings.

```plaintext
GET /sidekiq/process_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/process_metrics"
```

Example response:

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

## Retrieve job completion metrics

Retrieves statistics on the completion status of all Sidekiq jobs.

```plaintext
GET /sidekiq/job_stats
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/job_stats"
```

Example response:

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

## List all Sidekiq metrics

Lists all Sidekiq metrics in a single response, including queue, process, and job completion metrics.

```plaintext
GET /sidekiq/compound_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/compound_metrics"
```

Example response:

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
