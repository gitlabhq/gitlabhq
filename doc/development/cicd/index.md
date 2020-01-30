# CI/CD development documentation

Development guides that are specific to CI/CD are listed here.

## Job scheduling

When a Pipeline is created all its jobs are created at once for all stages, with an initial state of `created`. This makes it possible to visualize the full content of a pipeline.

A job with the `created` state won't be seen by the Runner yet. To make it possible to assign a job to a Runner, the job must transition first into the `pending` state, which can happen if:

1. The job is created in the very first stage of the pipeline.
1. The job required a manual start and it has been triggered.
1. All jobs from the previous stage have completed successfully. In this case we transition all jobs from the next stage to `pending`.
1. The job specifies DAG dependencies using `needs:` and all the dependent jobs are completed.

When the Runner is connected, it requests the next `pending` job to run by polling the server continuously.

NOTE: **Note:** API endpoints used by the Runner to interact with GitLab are defined in [`lib/api/runner.rb`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/api/runner.rb)

After the server receives the request it selects a `pending` job based on the [`Ci::RegisterJobService` algorithm](#ciregisterjobservice), then assigns and sends the job to the Runner.

Once all jobs are completed for the current stage, the server "unlocks" all the jobs from the next stage by changing their state to `pending`. These can now be picked by the scheduling algorithm when the Runner requests new jobs, and continues like this until all stages are completed.

### Communication between Runner and GitLab server

Once the Runner is [registered](../../ci/runners/README.md#registering-a-shared-runner) using the registration token, the server knows what type of jobs it can execute. This depends on:

- The type of runner it is registered as:
  - a shared runner
  - a group runner
  - a project specific runner
- Any associated tags.

The Runner initiates the communication by requesting jobs to execute with `POST /api/v4/jobs/request`. Although this polling generally happens every few seconds we leverage caching via HTTP headers to reduce the server-side work load if the job queue doesn't change.

This API endpoint runs [`Ci::RegisterJobService`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/services/ci/register_job_service.rb), which:

1. Picks the next job to run from the pool of `pending` jobs
1. Assigns it to the Runner
1. Presents it to the Runner via the API response

### `Ci::RegisterJobService`

There are 3 top level queries that this service uses to gather the majority of the jobs and they are selected based on the level where the Runner is registered to:

- Select jobs for shared Runner (instance level)
- Select jobs for group level Runner
- Select jobs for project Runner

This list of jobs is then filtered further by matching tags between job and Runner tags.

NOTE: **Note:** If a job contains tags, the Runner will not pick the job if it does not match **all** the tags.
The Runner may have more tags than defined for the job, but not vice-versa.

Finally if the Runner can only pick jobs that are tagged, all untagged jobs are filtered out.

At this point we loop through remaining `pending` jobs and we try to assign the first job that the Runner "can pick" based on additional policies. For example, Runners marked as `protected` can only pick jobs that run against protected branches (such as production deployments).

As we increase the number of Runners in the pool we also increase the chances of conflicts which would arise if assigning the same job to different Runners. To prevent that we gracefully rescue conflict errors and assign the next job in the list.
