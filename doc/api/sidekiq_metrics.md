# Sidekiq Metrics API

>**Note:** This endpoint is only available on GitLab 8.9 and above.

This API endpoint allows you to retrieve some information about the current state
of Sidekiq, its jobs, queues, and processes.

## Get the current Queue Metrics

List information about all the registered queues, their backlog and their
latency.

```
GET /sidekiq/queue_metrics
```

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/sidekiq/queue_metrics
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

## Get the current Process Metrics

List information about all the Sidekiq workers registered to process your queues.

```
GET /sidekiq/process_metrics
```

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/sidekiq/process_metrics
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

## Get the current Job Statistics

List information about the jobs that Sidekiq has performed.

```
GET /sidekiq/job_stats
```

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/sidekiq/job_stats
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

## Get a compound response of all the previously mentioned metrics

List all the currently available information about Sidekiq.

```
GET /sidekiq/compound_metrics
```

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/sidekiq/compound_metrics
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
