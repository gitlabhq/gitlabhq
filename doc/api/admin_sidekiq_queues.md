---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sidekiq queues administration API **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25998) in GitLab 12.9

Delete jobs from a Sidekiq queue that match the given
[metadata](../development/logging.md#logging-context-metadata-through-rails-or-grape-requests).

The response has three fields:

1. `deleted_jobs` - the number of jobs deleted by the request.
1. `queue_size` - the remaining size of the queue after processing the
   request.
1. `completed` - whether or not the request was able to process the
   entire queue in time. If not, retrying with the same parameters may
   delete further jobs (including those added after the first request
   was issued).

This API endpoint is only available to administrators.

```plaintext
DELETE /admin/sidekiq/queues/:queue_name
```

| Attribute           | Type           | Required | Description                                                                                                                                  |
| ---------           | -------------- | -------- | -----------                                                                                                                                  |
| `queue_name`        | string         | yes      | The name of the queue to delete jobs from                                                                                                    |
| `user`              | string         | no       | The username of the user who scheduled the jobs                                                                                              |
| `project`           | string         | no       | The full path of the project where the jobs were scheduled from                                                                              |
| `root_namespace`    | string         | no       | The root namespace of the project                                                                                                            |
| `subscription_plan` | string         | no       | The subscription plan of the root namespace (GitLab.com only)                                                                                |
| `caller_id`         | string         | no       | The endpoint or background job that schedule the job (for example: `ProjectsController#create`, `/api/:version/projects/:id`, `PostReceive`) |
| `feature_category`  | string         | no       | The feature category of the background job (for example: `issue_tracking` or `code_review`)                                                  |

At least one attribute, other than `queue_name`, is required.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/admin/sidekiq/queues/authorized_projects?user=root"
```

Example response:

```json
{
  "completed": true,
  "deleted_jobs": 7,
  "queue_size": 14
}
```
