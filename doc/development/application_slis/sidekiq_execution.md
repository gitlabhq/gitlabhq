---
stage: Platforms
group: Scalability
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Sidekiq execution SLIs (service level indicators)
---

> - [Introduced](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/700) in GitLab 16.0. This version of Sidekiq execution SLIs replaces the old version of the SLI where you can now drill down by workers in the [Application SLI Violations dashboard](https://dashboards.gitlab.net/d/general-application-sli-violations/general-application-sli-violations?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gprd&var-stage=main&var-product_stage=All&var-stage_group=All&var-component=sidekiq_execution) for stage groups.

NOTE:
This SLI is used for service monitoring. But not for [error budgets for stage groups](../stage_group_observability/_index.md#error-budget)
by default.

The Sidekiq execution Apdex measures the duration of successful jobs completion as an indicator for
application performance.

The error rate measures unsuccessful jobs completion when exception occurs as an indicator for
server misbehavior.

- `gitlab_sli_sidekiq_execution_apdex_total`: This counter gets
  incremented for every successful job execution that does not result in an exception. It ensures slow jobs are not
  counted twice, because the job is already counted in the error SLI.

- `gitlab_sli_sidekiq_execution_apdex_success_total`: This counter gets
  incremented for every successful job that performed faster than
  the [defined target duration depending on the job urgency](../sidekiq/worker_attributes.md#job-urgency).

- `gitlab_sli_sidekiq_execution_error_total`: This counter gets
  incremented for every job that encountered an exception.

- `gitlab_sli_sidekiq_execution_total`: This counter gets
  incremented for every job execution.

These counters are labeled with:

- `worker`: The identification of the worker.

- `feature_category`: The feature category specified for that worker.

- `urgency`: The urgency attribute specified for that worker.

- `external_dependencies`: The boolean value `yes` or `no` based on the [external dependencies attribute](../sidekiq/worker_attributes.md#jobs-with-external-dependencies).

- `queue`: The queue in which the job is running.

For more information about these SLIs, see the [Sidekiq SLIs documentation](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/sidekiq/sidekiq-slis.md) in runbooks.

## Adjusting job urgency

Not all workers perform the same type of work, so it is possible to
define different urgency levels for different jobs. A job with a
lower urgency can have a longer execution duration than jobs with high urgency.

For more information on the execution latency requirement and how to set a job's urgency, see the [Sidekiq worker attributes page](../sidekiq/worker_attributes.md#job-urgency).

### Error budget attribution and ownership

This SLI is used for service level monitoring. It feeds into the
[error budget for stage groups](../stage_group_observability/_index.md#error-budget).

The workers for the SLI feed into a group's error budget based on the
[feature category declared on it](../feature_categorization/_index.md).

To know which workers are included for your group, see the
Sidekiq Completion Rate panel on the
[group dashboard for your group](https://dashboards.gitlab.net/dashboards/f/stage-groups/stage-groups).
In the **Budget Attribution** row, the **Sidekiq Execution Apdex** log link shows you
how many jobs are not meeting the 10 second or 300 second target.

## Jobs with external dependencies

Jobs with [external dependencies](../sidekiq/worker_attributes.md#jobs-with-external-dependencies) are excluded from
the Apdex and error ratio calculation.
