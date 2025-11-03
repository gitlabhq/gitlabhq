---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Sidekiq queues administration API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Delete jobs from a Sidekiq queue that match the given
metadata.

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

| Attribute           | Type   | Required | Description |
|---------------------|--------|----------|-------------|
| `queue_name`        | string | yes      | The name of the queue to delete jobs from |
| `user`              | string | no       | The username of the user who scheduled the jobs |
| `project`           | string | no       | The full path of the project where the jobs were scheduled from |
| `root_namespace`    | string | no       | The root namespace of the project |
| `subscription_plan` | string | no       | The subscription plan of the root namespace (GitLab.com only) |
| `caller_id`         | string | no       | The endpoint or background job that scheduled the job (for example: `ProjectsController#create`, `/api/:version/projects/:id`, `PostReceive`) |
| `feature_category`  | string | no       | The feature category of the background job (for example: `team_planning` or `code_review`) |
| `worker_class`      | string | no       | The class of the background job worker (for example: `PostReceive` or `MergeWorker`) |

At least one attribute, other than `queue_name`, is required.

Example request:

```shell
curl --request DELETE \
--header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/admin/sidekiq/queues/:queue_name"
```

Example response:

```json
{
  "completed": true,
  "deleted_jobs": 7,
  "queue_size": 14
}
```
