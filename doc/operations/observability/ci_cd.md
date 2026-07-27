---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Monitor application performance and troubleshoot performance issues.
ignore_in_report: true
title: Show CI/CD pipeline telemetry for Observability
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

When enabled, GitLab Observability automatically instruments your CI/CD pipelines,
providing visibility into pipeline performance, job durations, and execution flow without any code changes.

- Visibility into which jobs are slowing down your pipelines.
- How pipeline performance changes over time.
- Bottlenecks in your deployment process.

## Enable pipeline instrumentation

To enable automatic pipeline instrumentation, add the `GITLAB_OBSERVABILITY_EXPORT` CI/CD variable to your project or group:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Variables**.
1. Select **Add variable**.
1. Configure the variable:
   - **Key**: `GITLAB_OBSERVABILITY_EXPORT`
   - **Value**: One or more of `traces`, `metrics`, `logs` (comma-separated for multiple values)
   - **Type**: Variable
   - **Environment scope**: All (or specific environments)
1. Select **Add variable**.

## Instrumentation types

The `GITLAB_OBSERVABILITY_EXPORT` variable accepts the following values:

- `traces`: Exports distributed traces showing pipeline execution flow, job dependencies, and timing
- `metrics`: Exports metrics about pipeline duration, job success rates, and resource usage
- `logs`: Exports structured logs from pipeline execution

You can enable multiple types by separating them with commas:

```plaintext
traces,metrics,logs
```

## Exported data

GitLab exports each signal type as OpenTelemetry Protocol (OTLP) data.
Every attribute is emitted
under both a legacy GitLab namespace (`pipeline.*`, `job.*`, `gitlab.*`) and, where one exists, the
equivalent [OpenTelemetry CI/CD semantic convention](https://opentelemetry.io/docs/specs/semconv/registry/attributes/cicd/)
namespace (`cicd.*`, `vcs.*`).

### Traces

Each pipeline is exported as a single resource span containing one pipeline span and one job span
for each job or bridge in the pipeline.

The resource carries the following attributes:

| Attribute | Description |
| --- | --- |
| `service.name` | The configured service name, or the project name if not configured. |
| `service.version` | The static value `1.0.0`. |
| `deployment.environment` | The configured environment, or `production` if not configured. |
| `gitlab.project.id` | The ID of the project that ran the pipeline. |
| `gitlab.project.name` | The name of the project that ran the pipeline. |
| `gitlab.project.path` | The full path of the project, including its namespace. |
| `gitlab.pipeline.id` | The ID of the pipeline. |
| `gitlab.pipeline.ref` | The branch or tag the pipeline ran on. |
| `gitlab.pipeline.source` | The event that triggered the pipeline, for example `push` or `schedule`. |
| `cicd.pipeline.run.id` | The ID of the pipeline, as a string. |
| `cicd.pipeline.run.url.full` | The URL of the pipeline. |
| `cicd.pipeline.name` | The name of the pipeline. |
| `vcs.provider.name` | The static value `gitlab`. |
| `vcs.repository.name` | The name of the project. |
| `vcs.repository.url.full` | The web URL of the project. |
| `vcs.owner.name` | The namespace that owns the project. |
| `vcs.ref.head.name` | The branch or tag the pipeline ran on. |
| `vcs.ref.head.revision` | The commit SHA the pipeline ran against. |
| `vcs.ref.head.type` | Either `tag` or `branch`. |

The pipeline span carries the following attributes:

| Attribute | Description |
| --- | --- |
| `pipeline.id` | The ID of the pipeline. |
| `pipeline.iid` | The project-scoped internal ID of the pipeline, if available. |
| `pipeline.name` | The name of the pipeline. |
| `pipeline.ref` | The branch or tag the pipeline ran on. |
| `pipeline.sha` | The commit SHA the pipeline ran against. |
| `pipeline.status` | The pipeline status, for example `success` or `failed`. |
| `pipeline.detailed_status` | The detailed status text shown in the UI. |
| `pipeline.duration` | The pipeline duration in milliseconds. |
| `pipeline.queued_duration` | The time the pipeline spent queued, in milliseconds. |
| `pipeline.protected_ref` | Whether the pipeline ran on a protected branch or tag. |
| `pipeline.url` | The URL of the pipeline. |
| `pipeline.tag` | Whether the pipeline ran on a tag, if this information is available. |
| `pipeline.before_sha` | The commit SHA before the pipeline ran, if available. |
| `pipeline.stages` | An array of the pipeline's stage names, if available. |
| `gitlab.cicd.pipeline.stages` | An array of the pipeline's stage names, if available. |
| `pipeline.user.id` | The ID of the user who triggered the pipeline, if available. |
| `pipeline.user.username` | The username of the user who triggered the pipeline, if available. |
| `pipeline.commit.id` | The SHA of the commit associated with the pipeline, if available. |
| `pipeline.commit.message` | The message of the commit associated with the pipeline, if available. |
| `pipeline.merge_request.id` | The ID of the associated merge request, if the pipeline ran for one. |
| `pipeline.merge_request.iid` | The internal ID of the associated merge request, if the pipeline ran for one. |
| `pipeline.source_pipeline.pipeline_id` | The ID of the parent pipeline, for child or multi-project pipelines. |
| `cicd.pipeline.name` | The name of the pipeline. |
| `cicd.pipeline.result` | The pipeline result. See [Attribute value mapping](#attribute-value-mapping). |
| `cicd.pipeline.run.state` | The pipeline run state. See [Attribute value mapping](#attribute-value-mapping). |
| `cicd.pipeline.trigger.type` | The trigger type. See [Attribute value mapping](#attribute-value-mapping). |
| `cicd.pipeline.run.queue_duration` | The time the pipeline spent queued, in milliseconds. |
| `gitlab.cicd.pipeline.iid` | The project-scoped internal ID of the pipeline, if available. |
| `vcs.ref.head.protected` | Whether the pipeline ran on a protected branch or tag. |
| `vcs.ref.head.name` | The branch or tag the pipeline ran on, if available. |
| `vcs.ref.head.revision` | The commit SHA the pipeline ran against, if available. |
| `vcs.ref.base.revision` | The commit SHA before the pipeline ran, if available. |
| `vcs.change.id` | The internal ID of the associated merge request, as a string, if the pipeline ran for one. |
| `vcs.change.title` | The title of the associated merge request, if the pipeline ran for one. |
| `vcs.change.state` | The state of the associated merge request. See [Attribute value mapping](#attribute-value-mapping). |
| `vcs.ref.base.name` | The target branch of the associated merge request, if the pipeline ran for one. |

The job span carries the following attributes for each job or bridge:

| Attribute | Description |
| --- | --- |
| `job.id` | The ID of the job. |
| `job.name` | The name of the job. |
| `job.stage` | The stage the job belongs to. |
| `job.status` | The job status, for example `success` or `failed`. |
| `job.duration` | The job duration in milliseconds. |
| `job.queued_duration` | The time the job spent queued, in milliseconds. |
| `job.manual` | Whether the job requires manual action to run. |
| `job.allow_failure` | Whether the job is allowed to fail without affecting the pipeline result. |
| `job.failure_reason` | The reason the job failed, if it failed. |
| `job.type` | The value `bridge` for jobs that trigger downstream pipelines. |
| `job.created_at` | The time the job was created, in Unix nanoseconds. |
| `job.when` | The `rules` or `when` keyword value that determined the job ran, if available. |
| `job.user.id` | The ID of the user associated with the job, if available. |
| `job.user.username` | The username of the user associated with the job, if available. |
| `job.artifacts.filename` | The filename of the job's artifacts archive, if the job produced one. |
| `job.artifacts.size` | The size of the job's artifacts archive in bytes, if the job produced one. |
| `job.runner.id` | The ID of the runner that ran the job, if the job has a runner. |
| `job.runner.description` | The description of the runner that ran the job, if the job has a runner. |
| `job.runner.tags` | The tags of the runner that ran the job, if the job has a runner. |
| `job.runner.type` | The runner type, for example `instance_type` or `project_type`, if available. |
| `job.runner.active` | Whether the runner is active, if available. |
| `job.runner.is_shared` | Whether the runner is shared across projects, if available. |
| `gitlab.cicd.runner.is_shared` | Whether the runner is shared across projects, if available. |
| `job.environment.name` | The name of the environment the job deploys to, if the job has an environment. |
| `job.environment.action` | The deployment action, for example `start` or `stop`, if the job has an environment. |
| `job.environment.deployment_tier` | The deployment tier of the environment, if available. |
| `cicd.pipeline.task.name` | The name of the job. |
| `cicd.pipeline.task.run.id` | The ID of the job, as a string. |
| `cicd.pipeline.task.run.result` | The job result. See [Attribute value mapping](#attribute-value-mapping). |
| `cicd.pipeline.task.run.state` | The job run state. See [Attribute value mapping](#attribute-value-mapping). |
| `cicd.pipeline.task.type` | The task type mapped from the job's stage. See [Attribute value mapping](#attribute-value-mapping). |
| `cicd.pipeline.task.allow_failure` | Whether the job is allowed to fail without affecting the pipeline result. |
| `cicd.pipeline.task.run.failure_reason` | The reason the job failed, if it failed. |
| `cicd.pipeline.task.trigger.type` | Either `manual` or `automatic`, based on whether the job requires manual action. |
| `cicd.pipeline.task.run.queue_duration` | The time the job spent queued, in milliseconds. |
| `cicd.worker.id` | The ID of the runner that ran the job, as a string, if the job has a runner. |
| `cicd.worker.name` | The description of the runner that ran the job, if the job has a runner. |
| `cicd.worker.state` | The runner state. See [Attribute value mapping](#attribute-value-mapping). |
| `cicd.worker.tags` | The tags of the runner that ran the job, if the job has a runner. |
| `cicd.worker.type` | The runner type, for example `instance_type` or `project_type`, if available. |

For child pipelines triggered by a bridge job, GitLab links the child pipeline's trace to the
triggering job's span.
The parent and child pipelines then appear as a single connected trace.

### Metrics

GitLab exports the following metrics for each pipeline:

| Metric | Type | Description |
| --- | --- | --- |
| `pipeline.duration_seconds` | Gauge | The pipeline duration in seconds. Emitted only when the pipeline has a duration. |
| `cicd.pipeline.run.duration` | Histogram | The pipeline run duration in seconds. Emitted only when the pipeline has a duration. |
| `pipeline.status_total` | Counter | The count of pipeline status changes. |
| `cicd.pipeline.run.count` | Counter | The count of pipeline runs. |
| `pipeline.jobs_total` | Gauge | The number of jobs in the pipeline. |
| `cicd.pipeline.task.total` | Gauge | The number of jobs in the pipeline. |
| `job.duration_seconds` | Histogram | The job duration in seconds, grouped by stage. Emitted only when the pipeline has jobs. |
| `cicd.pipeline.task.duration` | Histogram | The job duration in seconds, grouped by stage. Emitted only when the pipeline has jobs. |
| `pipeline.queue_duration_seconds` | Gauge | The time the pipeline spent queued, in seconds. Emitted only when the pipeline was queued. |
| `cicd.pipeline.run.queue_duration` | Gauge | The time the pipeline spent queued, in seconds. Emitted only when the pipeline was queued. |
| `cicd.pipeline.run.errors` | Counter | The count of pipeline errors. Emitted only when the pipeline result is `failure`. |

Metric data points carry attributes such as `pipeline.status`, `pipeline.ref`, `cicd.pipeline.name`,
`cicd.pipeline.result`, `cicd.pipeline.trigger.type`, and `vcs.ref.head.type`.
The `job.duration_seconds` and `cicd.pipeline.task.duration` histograms carry a `job.stage` attribute
for each data point.
The `cicd.pipeline.run.errors` data point carries an `error.type` attribute.

### Logs

GitLab exports one log record for the pipeline and one log record for each job.
Each log record
has the following fields:

| Field | Description |
| --- | --- |
| `severityNumber` and `severityText` | Mapped from the pipeline or job status. See [Attribute value mapping](#attribute-value-mapping). |
| `body` | A human-readable summary, for example `Pipeline success: my-pipeline` or `Job failed: test-job (test)`. |
| `log.level` | The same value as `severityText`. |
| `log.source` | Either `pipeline` or `job`. |
| Remaining attributes | The same attribute families as the trace spans: pipeline or job identity, the `cicd.*` and `vcs.*` semantic convention attributes, and runner, environment, and artifact attributes when available. |

### Attribute value mapping

GitLab maps its internal status and source values to the enum values defined by the OpenTelemetry
CI/CD semantic conventions.

Pipeline and job result (`cicd.pipeline.result`, `cicd.pipeline.task.run.result`):

| GitLab status | OpenTelemetry result |
| --- | --- |
| `success` | `success` |
| `failed` | `failure` |
| `canceled` | `cancellation` |
| `skipped` | `skip` |

Pipeline and job run state (`cicd.pipeline.run.state`, `cicd.pipeline.task.run.state`):

| GitLab status | OpenTelemetry run state |
| --- | --- |
| `pending` | `pending` |
| `waiting_for_resource` | `pending` |
| `preparing` | `pending` |
| `running` | `executing` |

Pipeline trigger type (`cicd.pipeline.trigger.type`):

| GitLab pipeline source | OpenTelemetry trigger type |
| --- | --- |
| `push` | `push` |
| `schedule` | `schedule` |
| `web` | `manual` |
| `trigger` | `manual` |
| `api` | `manual` |
| `merge_request_event` | `merge_request_event` |
| `external_pull_request_event` | `pull_request_event` |
| `pipeline` | `pipeline` |

Runner state (`cicd.worker.state`):

| Runner `active` attribute | OpenTelemetry worker state |
| --- | --- |
| `true` | `available` |
| `false` | `offline` |

## How it works

Once the variable is set, GitLab automatically:

1. Captures pipeline execution data after each pipeline completes
1. Converts the data to OpenTelemetry format based on your configuration
1. Exports the telemetry data to your GitLab Observability instance
1. Makes the data available in your observability dashboards

No changes to your `.gitlab-ci.yml` file are required. The instrumentation happens automatically in the background.

## View pipeline telemetry

After running pipelines with instrumentation enabled:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Observability** > **Services**.
1. Select your `gitlab-ci` service to view traces, metrics, and logs from your pipeline executions.

The CI/CD dashboard template from [GitLab Observability Templates](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/) provides pre-built visualizations for pipeline performance analysis.

## Related topics

- [Troubleshooting Observability](troubleshooting.md)
