---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: API Métriques Sidekiq
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce point de terminaison d'API vous permet de récupérer des informations sur l'état actuel de Sidekiq, ses jobs, ses files d'attente et ses processus.

## Lister toutes les métriques de file d'attente de job {#list-all-job-queue-metrics}

Répertorie les détails de toutes les files d'attente de job Sidekiq, notamment la taille du backlog et la latence.

```plaintext
GET /sidekiq/queue_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/queue_metrics"
```

Exemple de réponse :

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

## Lister tous les processus Sidekiq {#list-all-sidekiq-processes}

Répertorie les détails de tous les processus worker Sidekiq enregistrés, notamment le nom d'hôte, l'ID de processus, les files d'attente et les paramètres de concurrence.

```plaintext
GET /sidekiq/process_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/process_metrics"
```

Exemple de réponse :

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

## Récupérer les métriques d'achèvement des jobs {#retrieve-job-completion-metrics}

Récupère des statistiques sur le statut d'achèvement de tous les jobs Sidekiq.

```plaintext
GET /sidekiq/job_stats
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/job_stats"
```

Exemple de réponse :

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

## Lister toutes les métriques Sidekiq {#list-all-sidekiq-metrics}

Répertorie toutes les métriques Sidekiq dans une seule réponse, notamment les métriques de file d'attente, de processus et d'achèvement des jobs.

```plaintext
GET /sidekiq/compound_metrics
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/sidekiq/compound_metrics"
```

Exemple de réponse :

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
