# CI/CD development documentation

Development guides that are specific to CI/CD are listed here.

## CI Architecture overview

The following is a simplified diagram of the CI architecture. Some details are left out in order to focus on
the main components.

![CI software architecture](img/ci_architecture.png)
<!-- Editable diagram available at https://app.diagrams.net/#G1LFl-KW4fgpBPzz8VIH9rsOlAH4t0xwKj -->

On the left side we have the events that can trigger a pipeline based on various events (trigged by a user or automation):

- A `git push` is the most common event that triggers a pipeline.
- The [Web API](../../api/pipelines.md#create-a-new-pipeline).
- A user clicking the "Run Pipeline" button in the UI.
- When a [merge request is created or updated](../../ci/merge_request_pipelines/index.md#pipelines-for-merge-requests).
- When an MR is added to a [Merge Train](../../ci/merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md#merge-trains-premium).
- A [scheduled pipeline](../../ci/pipelines/schedules.md#pipeline-schedules).
- When project is [subscribed to an upstream project](../../ci/multi_project_pipelines.md#trigger-a-pipeline-when-an-upstream-project-is-rebuilt).
- When [Auto DevOps](../../topics/autodevops/index.md) is enabled.
- When GitHub integration is used with [external pull requests](../../ci/ci_cd_for_external_repos/index.md#pipelines-for-external-pull-requests).
- When an upstream pipeline contains a [bridge job](../../ci/yaml/README.md#trigger) which triggers a downstream pipeline.

Triggering any of these events will invoke the [`CreatePipelineService`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/ci/create_pipeline_service.rb)
which takes as input event data and the user triggering it, then will attempt to create a pipeline.

The `CreatePipelineService` relies heavily on the [`YAML Processor`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/yaml_processor.rb)
component, which is responsible for taking in a YAML blob as input and returns the abstract data structure of a
pipeline (including stages and all jobs). This component also validates the structure of the YAML while
processing it, and returns any syntax or semantic errors. The `YAML Processor` component is where we define
[all the keywords](../../ci/yaml/README.md) available to structure a pipeline.

The `CreatePipelineService` receives the abstract data structure returned by the `YAML Processor`,
which then converts it to persisted models (pipeline, stages, jobs, etc.). After that, the pipeline is ready
to be processed. Processing a pipeline means running the jobs in order of execution (stage or DAG)
until either one of the following:

- All expected jobs have been executed.
- Failures interrupt the pipeline execution.

The component that processes a pipeline is [`ProcessPipelineService`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/ci/process_pipeline_service.rb),
which is responsible for moving all the pipeline's jobs to a completed state. When a pipeline is created, all its
jobs are initially in `created` state. This services looks at what jobs in `created` stage are eligible
to be processed based on the pipeline structure. Then it moves them into the `pending` state, which means
they can now [be picked up by a Runner](#job-scheduling). After a job has been executed it can complete
successfully or fail. Each status transition for job within a pipeline triggers this service again, which
looks for the next jobs to be transitioned towards completion. While doing that, `ProcessPipelineService`
updates the status of jobs, stages and the overall pipeline.

On the right side of the diagram we have a list of [Runners](../../ci/runners/README.md#configuring-gitlab-runners)
connected to the GitLab instance. These can be Shared Runners, Group Runners or Project-specific Runners.
The communication between Runners and the Rails server occurs through a set of API endpoints, grouped as
the `Runner API Gateway`.

We can register, delete and verify Runners, which also causes read/write queries to the database. After a Runner is connected,
it keeps asking for the next job to execute. This invokes the [`RegisterJobService`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/services/ci/register_job_service.rb)
which will pick the next job and assign it to the Runner. At this point the job will transition to a
`running` state, which again triggers `ProcessPipelineService` due to the status change.
For more details read [Job scheduling](#job-scheduling)).

While a job is being executed, the Runner sends logs back to the server as well any possible artifacts
that need to be stored. Also, a job may depend on artifacts from previous jobs in order to run. In this
case the Runner will download them using a dedicated API endpoint.

Artifacts are stored in object storage, while metadata is kept in the database. An important example of artifacts
is reports (JUnit, SAST, DAST, etc.) which are parsed and rendered in the merge request.

Job status transitions are not all automated. A user may run [manual jobs](../../ci/yaml/README.md#whenmanual), cancel a pipeline, retry
specific failed jobs or the entire pipeline. Anything that
causes a job to change status will trigger `ProcessPipelineService`, as it's responsible for
tracking the status of the entire pipeline.

A special type of job is the [bridge job](../../ci/yaml/README.md#trigger) which is executed server-side
when transitioning to the `pending` state. This job is responsible for creating a downstream pipeline, such as
a multi-project or child pipeline. The workflow loop starts again
from the `CreatePipelineService` every time a downstream pipeline is triggered.

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
